import Foundation
import CloudKit

/**
 * CloudKitFeedbackService.swift
 *
 * PURPOSE: Service layer for CloudKit-based user feedback and developer responses
 *
 * RESPONSIBILITIES:
 * - Submit user feedback to CloudKit Public Database
 * - Subscribe to push notifications for developer responses
 * - Fetch user's feedback history with responses
 * - Anonymous demographic data collection (opt-in)
 * - Device information auto-population for bug tracking
 *
 * DESIGN DECISIONS:
 * - CloudKit Public Database for zero infrastructure cost
 * - Anonymous CloudKit user IDs (no PII storage)
 * - Push notifications for real-time developer response alerts
 * - Opt-in demographic sharing for feature prioritization insights
 * - Automatic subscription creation on feedback submission
 *
 * CLOUDKIT SCHEMA:
 * Record Type: Feedback
 * - feedbackID: String (indexed)
 * - category: String ("Bug", "Feature", "Content", "General")
 * - feedbackText: String
 * - timestamp: Date (indexed)
 * - userRecordID: Reference (CloudKit user - anonymous)
 * - beltLevel: String? (optional)
 * - learningMode: String? (optional)
 * - mostUsedFeature: String? (optional)
 * - totalSessions: Int? (optional)
 * - deviceInfo: String
 * - developerResponse: String? (null until responded)
 * - responseTimestamp: Date? (null until responded)
 * - responseStatus: String ("Pending", "Responded", "Implemented")
 * - targetVersion: String? (e.g., "v1.1")
 */

@Observable
@MainActor
class CloudKitFeedbackService {
    // MARK: - Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let recordType = "Feedback"

    // Cache of user's feedback (for offline support)
    var userFeedbackItems: [FeedbackItem] = []
    var unreadResponseCount: Int = 0

    // MARK: - Initialization

    init(containerIdentifier: String = "iCloud.com.craigmatthewharris.TKDojang") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Feedback Submission

    /**
     * Submits user feedback to CloudKit and creates push notification subscription
     *
     * WHY: One-step submission with automatic response notification setup
     */
    func submitFeedback(
        category: FeedbackCategory,
        text: String,
        demographics: AnonymousDemographics?
    ) async throws -> String {
        // Create feedback record
        let feedbackID = UUID().uuidString
        let record = CKRecord(recordType: recordType)

        record["feedbackID"] = feedbackID as CKRecordValue
        record["category"] = category.rawValue as CKRecordValue
        record["feedbackText"] = text as CKRecordValue
        record["timestamp"] = Date() as CKRecordValue
        record["deviceInfo"] = getDeviceInfo() as CKRecordValue
        record["responseStatus"] = "Pending" as CKRecordValue

        // Optional demographics (user opt-in)
        if let demographics = demographics {
            record["beltLevel"] = demographics.beltLevel as? CKRecordValue
            record["learningMode"] = demographics.learningMode as? CKRecordValue
            record["mostUsedFeature"] = demographics.mostUsedFeature as? CKRecordValue
            record["totalSessions"] = demographics.totalSessions as? CKRecordValue
        }

        // Save to CloudKit
        _ = try await publicDatabase.save(record)

        // Create push notification subscription for developer responses
        try await subscribeToResponse(feedbackID: feedbackID)

        // Add to local cache
        let feedbackItem = FeedbackItem(
            id: feedbackID,
            category: category,
            text: text,
            timestamp: Date(),
            responseStatus: .pending
        )
        userFeedbackItems.append(feedbackItem)

        return feedbackID
    }

    /**
     * Creates a push notification subscription for a specific feedback item
     *
     * WHY: User gets notified when developer responds, without polling
     */
    private func subscribeToResponse(feedbackID: String) async throws {
        // CloudKit doesn't support "!= nil" predicates, so we subscribe to any update
        // and check for response in the notification handler
        let predicate = NSPredicate(
            format: "feedbackID == %@",
            feedbackID
        )

        let subscription = CKQuerySubscription(
            recordType: recordType,
            predicate: predicate,
            subscriptionID: "feedback-\(feedbackID)",
            options: [.firesOnRecordUpdate] // Only fire on updates (not initial creation)
        )

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "Developer responded to your feedback"
        notificationInfo.soundName = "default"
        notificationInfo.shouldBadge = true
        subscription.notificationInfo = notificationInfo

        _ = try await publicDatabase.save(subscription)
    }

    // MARK: - Fetch User Feedback

    /**
     * Fetches all feedback submitted by the current user
     *
     * WHY: Users can track their feedback history and see developer responses
     */
    func fetchUserFeedback() async throws {
        let predicate = NSPredicate(value: true) // Fetch all (CloudKit auto-filters by creator)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        let results = try await publicDatabase.records(matching: query)

        var items: [FeedbackItem] = []
        var unreadCount = 0

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                let item = parseFeedbackRecord(record)
                items.append(item)

                // Count unread responses
                if item.responseStatus == .responded, item.developerResponse != nil {
                    // In production, track read/unread state separately
                    unreadCount += 1
                }

            case .failure(let error):
                print("Error fetching feedback record: \(error)")
            }
        }

        self.userFeedbackItems = items
        self.unreadResponseCount = unreadCount
    }

    /**
     * Parses a CloudKit record into a FeedbackItem model
     */
    private func parseFeedbackRecord(_ record: CKRecord) -> FeedbackItem {
        let id = record["feedbackID"] as? String ?? UUID().uuidString
        let categoryString = record["category"] as? String ?? "General"
        let category = FeedbackCategory(rawValue: categoryString) ?? .general
        let text = record["feedbackText"] as? String ?? ""
        let timestamp = record["timestamp"] as? Date ?? Date()
        let statusString = record["responseStatus"] as? String ?? "Pending"
        let status = ResponseStatus(rawValue: statusString) ?? .pending
        let response = record["developerResponse"] as? String
        let responseTimestamp = record["responseTimestamp"] as? Date
        let targetVersion = record["targetVersion"] as? String

        return FeedbackItem(
            id: id,
            category: category,
            text: text,
            timestamp: timestamp,
            responseStatus: status,
            developerResponse: response,
            responseTimestamp: responseTimestamp,
            targetVersion: targetVersion
        )
    }

    // MARK: - Device Information

    /**
     * Collects device information for bug tracking
     *
     * WHY: Helps developer debug issues specific to iOS versions or device models
     */
    private func getDeviceInfo() -> String {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        let iosVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = getDeviceModel()

        return """
        App Version: \(appVersion) (\(buildNumber))
        iOS Version: \(iosVersion)
        Device Model: \(deviceModel)
        """
    }

    /**
     * Returns device model identifier (e.g., iPhone14,3 for iPhone 13 Pro Max)
     */
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    // MARK: - Mark Response as Read

    /**
     * Marks a developer response as read (for badge count management)
     */
    func markResponseAsRead(feedbackID: String) {
        if let index = userFeedbackItems.firstIndex(where: { $0.id == feedbackID }) {
            // In production, update local state or CloudKit field for read tracking
            unreadResponseCount = max(0, unreadResponseCount - 1)
        }
    }
}

// MARK: - Data Models

/**
 * Feedback category types
 */
enum FeedbackCategory: String, CaseIterable {
    case bug = "Bug"
    case feature = "Feature"
    case content = "Content"
    case general = "General"

    var icon: String {
        switch self {
        case .bug: return "ladybug"
        case .feature: return "lightbulb"
        case .content: return "book"
        case .general: return "message"
        }
    }
}

/**
 * Response status for feedback items
 */
enum ResponseStatus: String {
    case pending = "Pending"
    case responded = "Responded"
    case implemented = "Implemented"

    var color: String {
        switch self {
        case .pending: return "orange"
        case .responded: return "blue"
        case .implemented: return "green"
        }
    }
}

/**
 * Optional anonymous demographics (user opt-in)
 */
struct AnonymousDemographics {
    let beltLevel: String?
    let learningMode: String?
    let mostUsedFeature: String?
    let totalSessions: Int?
}

/**
 * Feedback item model for local caching and UI display
 */
struct FeedbackItem: Identifiable {
    let id: String
    let category: FeedbackCategory
    let text: String
    let timestamp: Date
    let responseStatus: ResponseStatus
    var developerResponse: String?
    var responseTimestamp: Date?
    var targetVersion: String?

    var isResponded: Bool {
        developerResponse != nil
    }
}
