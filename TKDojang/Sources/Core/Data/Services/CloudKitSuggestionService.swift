import Foundation
import CloudKit

/**
 * CloudKitSuggestionService.swift
 *
 * PURPOSE: Service layer for user-submitted feature suggestions
 *
 * RESPONSIBILITIES:
 * - Submit user feature suggestions to CloudKit
 * - Fetch community suggestions for browsing
 * - Handle upvoting of suggestions
 * - Track user's suggestion submission history
 * - Notify when developer promotes suggestion to roadmap
 *
 * DESIGN DECISIONS:
 * - Separate from roadmap voting (user-submitted vs developer-curated)
 * - Anonymous submissions via CloudKit user IDs
 * - Community upvoting to surface popular ideas
 * - Developer can promote suggestions to official roadmap
 * - Status workflow: Pending → UnderReview → AddedToRoadmap/Declined
 *
 * CLOUDKIT SCHEMA:
 * Record Type: FeatureSuggestion
 * - suggestionID: String (indexed)
 * - title: String
 * - description: String
 * - submittedBy: Reference (CloudKit user - anonymous)
 * - submittedAt: Date (indexed)
 * - status: String ("Pending", "UnderReview", "AddedToRoadmap", "Declined")
 * - upvoteCount: Int
 * - developerNotes: String? (internal, not shown to users)
 * - promotedToRoadmapID: String? (if added to roadmap)
 *
 * Record Type: SuggestionUpvote
 * - upvoteID: String (indexed)
 * - suggestionID: Reference (to FeatureSuggestion)
 * - userRecordID: Reference (CloudKit user - anonymous)
 * - upvotedAt: Date
 */

@Observable
@MainActor
class CloudKitSuggestionService {
    // MARK: - Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let suggestionRecordType = "FeatureSuggestion"
    private let upvoteRecordType = "SuggestionUpvote"

    // Cached suggestions (for offline support)
    var communitySuggestions: [FeatureSuggestion] = []
    var userSuggestions: [FeatureSuggestion] = []
    var userUpvotedSuggestionIDs: Set<String> = []

    // MARK: - Initialization

    init(containerIdentifier: String = "iCloud.com.craigmatthewharris.TKDojang") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Submit Suggestion

    /**
     * Submits a new feature suggestion
     *
     * WHY: Users can suggest features not in the official roadmap
     */
    func submitSuggestion(title: String, description: String) async throws -> String {
        let suggestionID = UUID().uuidString
        let record = CKRecord(recordType: suggestionRecordType)

        record["suggestionID"] = suggestionID as CKRecordValue
        record["title"] = title as CKRecordValue
        record["description"] = description as CKRecordValue
        record["submittedAt"] = Date() as CKRecordValue
        record["status"] = "Pending" as CKRecordValue
        record["upvoteCount"] = 0 as CKRecordValue

        _ = try await publicDatabase.save(record)

        // Add to local cache
        let suggestion = FeatureSuggestion(
            id: suggestionID,
            recordID: record.recordID,
            title: title,
            description: description,
            submittedAt: Date(),
            status: .pending,
            upvoteCount: 0,
            promotedToRoadmapID: nil,
            isSubmittedByUser: true
        )
        userSuggestions.append(suggestion)

        return suggestionID
    }

    // MARK: - Fetch Suggestions

    /**
     * Fetches all community suggestions sorted by upvote count
     *
     * WHY: Users can browse and upvote popular suggestions
     */
    func fetchCommunitySuggestions() async throws {
        // Fetch suggestions with status Pending or UnderReview (not Declined)
        let predicate = NSPredicate(
            format: "status == %@ OR status == %@",
            "Pending", "UnderReview"
        )
        let query = CKQuery(recordType: suggestionRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "upvoteCount", ascending: false)]

        let results = try await publicDatabase.records(matching: query)

        var suggestions: [FeatureSuggestion] = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                let suggestion = parseSuggestionRecord(record, isSubmittedByUser: false)
                suggestions.append(suggestion)

            case .failure(let error):
                print("Error fetching suggestion: \(error)")
            }
        }

        self.communitySuggestions = suggestions

        // Fetch user's upvote history
        try await fetchUserUpvotes()
    }

    /**
     * Fetches suggestions submitted by the current user
     *
     * WHY: Users can track their own suggestions and see status updates
     */
    func fetchUserSuggestions() async throws {
        let predicate = NSPredicate(value: true) // CloudKit auto-filters by creator
        let query = CKQuery(recordType: suggestionRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "submittedAt", ascending: false)]

        let results = try await publicDatabase.records(matching: query)

        var suggestions: [FeatureSuggestion] = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                let suggestion = parseSuggestionRecord(record, isSubmittedByUser: true)
                suggestions.append(suggestion)

            case .failure(let error):
                print("Error fetching user suggestion: \(error)")
            }
        }

        self.userSuggestions = suggestions
    }

    /**
     * Parses a CloudKit record into a FeatureSuggestion model
     */
    private func parseSuggestionRecord(_ record: CKRecord, isSubmittedByUser: Bool) -> FeatureSuggestion {
        let id = record["suggestionID"] as? String ?? UUID().uuidString
        let title = record["title"] as? String ?? ""
        let description = record["description"] as? String ?? ""
        let submittedAt = record["submittedAt"] as? Date ?? Date()
        let statusString = record["status"] as? String ?? "Pending"
        let status = SuggestionStatus(rawValue: statusString) ?? .pending
        let upvoteCount = record["upvoteCount"] as? Int ?? 0
        let promotedToRoadmapID = record["promotedToRoadmapID"] as? String

        return FeatureSuggestion(
            id: id,
            recordID: record.recordID,
            title: title,
            description: description,
            submittedAt: submittedAt,
            status: status,
            upvoteCount: upvoteCount,
            promotedToRoadmapID: promotedToRoadmapID,
            isSubmittedByUser: isSubmittedByUser
        )
    }

    // MARK: - Upvoting

    /**
     * Fetches user's upvote history to prevent double-upvoting
     */
    private func fetchUserUpvotes() async throws {
        let predicate = NSPredicate(value: true) // CloudKit auto-filters by creator
        let query = CKQuery(recordType: upvoteRecordType, predicate: predicate)

        let results = try await publicDatabase.records(matching: query)

        var upvotedIDs: Set<String> = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let suggestionRef = record["suggestionID"] as? CKRecord.Reference {
                    upvotedIDs.insert(suggestionRef.recordID.recordName)
                }

            case .failure(let error):
                print("Error fetching upvote record: \(error)")
            }
        }

        self.userUpvotedSuggestionIDs = upvotedIDs
    }

    /**
     * Upvotes a feature suggestion with double-upvote prevention
     *
     * WHY: Users can upvote suggestions to signal community interest
     */
    func upvoteSuggestion(suggestionID: String) async throws {
        guard let suggestion = communitySuggestions.first(where: { $0.id == suggestionID })
                ?? userSuggestions.first(where: { $0.id == suggestionID }) else {
            throw SuggestionError.suggestionNotFound
        }

        // Check if user already upvoted
        if userUpvotedSuggestionIDs.contains(suggestion.recordID.recordName) {
            throw SuggestionError.alreadyUpvoted
        }

        // Create upvote record
        let upvoteRecord = CKRecord(recordType: upvoteRecordType)
        upvoteRecord["upvoteID"] = UUID().uuidString as CKRecordValue
        upvoteRecord["suggestionID"] = CKRecord.Reference(recordID: suggestion.recordID, action: .none)
        upvoteRecord["upvotedAt"] = Date() as CKRecordValue

        _ = try await publicDatabase.save(upvoteRecord)

        // Update upvote count
        let suggestionRecord = try await publicDatabase.record(for: suggestion.recordID)
        let currentUpvoteCount = suggestionRecord["upvoteCount"] as? Int ?? 0
        suggestionRecord["upvoteCount"] = (currentUpvoteCount + 1) as CKRecordValue

        _ = try await publicDatabase.save(suggestionRecord)

        // Update local cache
        if let index = communitySuggestions.firstIndex(where: { $0.id == suggestionID }) {
            communitySuggestions[index].upvoteCount += 1
        }
        if let index = userSuggestions.firstIndex(where: { $0.id == suggestionID }) {
            userSuggestions[index].upvoteCount += 1
        }
        userUpvotedSuggestionIDs.insert(suggestion.recordID.recordName)
    }

    /**
     * Checks if user has upvoted a specific suggestion
     */
    func hasUserUpvoted(suggestionID: String) -> Bool {
        guard let suggestion = communitySuggestions.first(where: { $0.id == suggestionID })
                ?? userSuggestions.first(where: { $0.id == suggestionID }) else {
            return false
        }
        return userUpvotedSuggestionIDs.contains(suggestion.recordID.recordName)
    }

    // MARK: - Filtered Suggestions

    /**
     * Returns top suggestions by upvote count
     */
    func topSuggestions(limit: Int = 10) -> [FeatureSuggestion] {
        Array(communitySuggestions.prefix(limit))
    }

    /**
     * Returns user's suggestions that were promoted to roadmap
     */
    var promotedSuggestions: [FeatureSuggestion] {
        userSuggestions.filter { $0.status == .addedToRoadmap }
    }
}

// MARK: - Data Models

/**
 * Feature suggestion status
 */
enum SuggestionStatus: String, CaseIterable {
    case pending = "Pending"
    case underReview = "UnderReview"
    case addedToRoadmap = "AddedToRoadmap"
    case declined = "Declined"

    var color: String {
        switch self {
        case .pending: return "gray"
        case .underReview: return "blue"
        case .addedToRoadmap: return "green"
        case .declined: return "red"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .underReview: return "magnifyingglass"
        case .addedToRoadmap: return "checkmark.circle.fill"
        case .declined: return "xmark.circle"
        }
    }

    var displayName: String {
        switch self {
        case .pending: return "Pending Review"
        case .underReview: return "Under Review"
        case .addedToRoadmap: return "Added to Roadmap"
        case .declined: return "Declined"
        }
    }
}

/**
 * Feature suggestion model for local caching and UI display
 */
struct FeatureSuggestion: Identifiable {
    let id: String
    let recordID: CKRecord.ID
    let title: String
    let description: String
    let submittedAt: Date
    let status: SuggestionStatus
    var upvoteCount: Int
    let promotedToRoadmapID: String?
    let isSubmittedByUser: Bool

    var hasUserUpvoted: Bool = false

    var isPromoted: Bool {
        status == .addedToRoadmap
    }
}

/**
 * Suggestion service errors
 */
enum SuggestionError: Error, LocalizedError {
    case suggestionNotFound
    case alreadyUpvoted

    var errorDescription: String? {
        switch self {
        case .suggestionNotFound:
            return "Suggestion not found"
        case .alreadyUpvoted:
            return "You've already upvoted this suggestion"
        }
    }
}
