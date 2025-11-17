import Foundation
import CloudKit

/**
 * CloudKitRoadmapService.swift
 *
 * PURPOSE: Service layer for CloudKit-based roadmap voting and feature prioritization
 *
 * RESPONSIBILITIES:
 * - Fetch roadmap items from CloudKit Public Database
 * - Handle user voting with double-vote prevention
 * - Update vote counts in real-time
 * - Track user's voting history
 * - Sort items by developer priority order
 *
 * DESIGN DECISIONS:
 * - Roadmap items are developer-curated (Developer-Only Write)
 * - Voting is anonymous via CloudKit user IDs
 * - Double-vote prevention via CloudKit query (check existing RoadmapVote record)
 * - Vote counts aggregated in RoadmapItem record for performance
 * - 9 priority items maintained in specified order
 *
 * CLOUDKIT SCHEMA:
 * Record Type: RoadmapItem
 * - itemID: String (indexed)
 * - title: String
 * - description: String
 * - priority: Int (1-9 for ordering)
 * - estimatedRelease: String ("v1.1 - January 2026")
 * - status: String ("Planned", "InProgress", "Released")
 * - voteCount: Int
 * - category: String ("Content", "Feature", "UX")
 * - completionPercentage: Double? (0.0-1.0 for InProgress)
 * - releaseDate: Date? (actual release date when Released)
 *
 * Record Type: RoadmapVote
 * - voteID: String (indexed)
 * - roadmapItemID: Reference (to RoadmapItem)
 * - userRecordID: Reference (CloudKit user - anonymous)
 * - votedAt: Date
 */

@Observable
@MainActor
class CloudKitRoadmapService {
    // MARK: - Properties

    private let container: CKContainer
    private let publicDatabase: CKDatabase
    private let itemRecordType = "RoadmapItem"
    private let voteRecordType = "RoadmapVote"

    // Cached roadmap items (for offline support)
    var roadmapItems: [RoadmapItem] = []
    var userVotedItemIDs: Set<String> = []

    // MARK: - Initialization

    init(containerIdentifier: String = "iCloud.com.craigmatthewharris.TKDojang") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = container.publicCloudDatabase
    }

    // MARK: - Fetch Roadmap Items

    /**
     * Fetches all roadmap items from CloudKit
     *
     * WHY: Displays current roadmap with vote counts and status
     */
    func fetchRoadmapItems() async throws {
        let predicate = NSPredicate(value: true) // Fetch all items
        let query = CKQuery(recordType: itemRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true)]

        // Explicitly specify which fields to fetch (avoids system field issues)
        let desiredKeys = ["itemID", "title", "description", "priority", "estimatedRelease",
                          "status", "voteCount", "category", "completionPercentage", "releaseDate", "isNew"]

        let results = try await publicDatabase.records(matching: query, desiredKeys: desiredKeys)

        var items: [RoadmapItem] = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                let item = parseRoadmapItemRecord(record)
                items.append(item)

            case .failure(let error):
                print("Error fetching roadmap item: \(error)")
            }
        }

        self.roadmapItems = items

        // Fetch user's voting history
        try await fetchUserVotes()
    }

    /**
     * Parses a CloudKit record into a RoadmapItem model
     */
    private func parseRoadmapItemRecord(_ record: CKRecord) -> RoadmapItem {
        let itemID = record["itemID"] as? String ?? UUID().uuidString
        let title = record["title"] as? String ?? ""
        let description = record["description"] as? String ?? ""
        let priority = record["priority"] as? Int ?? 99
        let estimatedRelease = record["estimatedRelease"] as? String ?? ""
        let statusString = record["status"] as? String ?? "Planned"
        let status = RoadmapStatus(rawValue: statusString) ?? .planned
        let voteCount = record["voteCount"] as? Int ?? 0
        let categoryString = record["category"] as? String ?? "Feature"
        let category = RoadmapCategory(rawValue: categoryString) ?? .feature
        let completionPercentage = record["completionPercentage"] as? Double
        let releaseDate = record["releaseDate"] as? Date

        return RoadmapItem(
            id: itemID,
            recordID: record.recordID,
            title: title,
            description: description,
            priority: priority,
            estimatedRelease: estimatedRelease,
            status: status,
            voteCount: voteCount,
            category: category,
            completionPercentage: completionPercentage,
            releaseDate: releaseDate
        )
    }

    // MARK: - Voting

    /**
     * Fetches user's voting history to prevent double-voting
     *
     * WHY: Users can only vote once per roadmap item
     */
    private func fetchUserVotes() async throws {
        let predicate = NSPredicate(value: true) // CloudKit auto-filters by creator
        let query = CKQuery(recordType: voteRecordType, predicate: predicate)

        let results = try await publicDatabase.records(matching: query)

        var votedIDs: Set<String> = []

        for (_, result) in results.matchResults {
            switch result {
            case .success(let record):
                if let roadmapItemRef = record["roadmapItemID"] as? CKRecord.Reference {
                    // Extract the itemID from the record if it's stored there
                    // For now, use recordID as a proxy
                    votedIDs.insert(roadmapItemRef.recordID.recordName)
                }

            case .failure(let error):
                print("Error fetching vote record: \(error)")
            }
        }

        self.userVotedItemIDs = votedIDs
    }

    /**
     * Submits a vote for a roadmap item with double-vote prevention
     *
     * WHY: Users vote to prioritize features, one vote per item
     */
    func voteForItem(itemID: String) async throws {
        // Check if user already voted
        guard let roadmapItem = roadmapItems.first(where: { $0.id == itemID }) else {
            throw RoadmapError.itemNotFound
        }

        // Check local cache first (fast path)
        if userVotedItemIDs.contains(roadmapItem.recordID.recordName) {
            throw RoadmapError.alreadyVoted
        }

        // Create vote record
        let voteRecord = CKRecord(recordType: voteRecordType)
        voteRecord["voteID"] = UUID().uuidString as CKRecordValue
        voteRecord["roadmapItemID"] = CKRecord.Reference(recordID: roadmapItem.recordID, action: .none)
        voteRecord["votedAt"] = Date() as CKRecordValue

        // Save vote
        _ = try await publicDatabase.save(voteRecord)

        // Update vote count in RoadmapItem record
        let itemRecord = try await publicDatabase.record(for: roadmapItem.recordID)
        let currentVoteCount = itemRecord["voteCount"] as? Int ?? 0
        itemRecord["voteCount"] = (currentVoteCount + 1) as CKRecordValue

        _ = try await publicDatabase.save(itemRecord)

        // Update local cache
        if let index = roadmapItems.firstIndex(where: { $0.id == itemID }) {
            roadmapItems[index].voteCount += 1
        }
        userVotedItemIDs.insert(roadmapItem.recordID.recordName)
    }

    /**
     * Checks if user has voted for a specific item
     */
    func hasUserVoted(itemID: String) -> Bool {
        guard let roadmapItem = roadmapItems.first(where: { $0.id == itemID }) else {
            return false
        }
        return userVotedItemIDs.contains(roadmapItem.recordID.recordName)
    }

    // MARK: - Filtered Items

    /**
     * Returns roadmap items filtered by status
     */
    func items(withStatus status: RoadmapStatus) -> [RoadmapItem] {
        roadmapItems.filter { $0.status == status }
    }

    /**
     * Returns roadmap items sorted by priority
     */
    var itemsByPriority: [RoadmapItem] {
        roadmapItems.sorted { $0.priority < $1.priority }
    }

    /**
     * Returns planned items (for voting UI)
     */
    var plannedItems: [RoadmapItem] {
        items(withStatus: .planned)
    }

    /**
     * Returns in-progress items
     */
    var inProgressItems: [RoadmapItem] {
        items(withStatus: .inProgress)
    }

    /**
     * Returns recently released items (last 3)
     */
    var recentlyReleasedItems: [RoadmapItem] {
        let releasedItems = items(withStatus: .released)
            .sorted { ($0.releaseDate ?? Date.distantPast) > ($1.releaseDate ?? Date.distantPast) }
        return Array(releasedItems.prefix(3))
    }
}

// MARK: - Data Models

/**
 * Roadmap item status
 */
enum RoadmapStatus: String, CaseIterable {
    case planned = "Planned"
    case inProgress = "InProgress"
    case released = "Released"

    var color: String {
        switch self {
        case .planned: return "blue"
        case .inProgress: return "orange"
        case .released: return "green"
        }
    }

    var icon: String {
        switch self {
        case .planned: return "calendar"
        case .inProgress: return "hammer"
        case .released: return "checkmark.circle.fill"
        }
    }
}

/**
 * Roadmap item category
 */
enum RoadmapCategory: String, CaseIterable {
    case content = "Content"
    case feature = "Feature"
    case ux = "UX"

    var icon: String {
        switch self {
        case .content: return "photo.on.rectangle"
        case .feature: return "star"
        case .ux: return "paintbrush"
        }
    }
}

/**
 * Roadmap item model for local caching and UI display
 */
struct RoadmapItem: Identifiable {
    let id: String
    let recordID: CKRecord.ID
    let title: String
    let description: String
    let priority: Int
    let estimatedRelease: String
    let status: RoadmapStatus
    var voteCount: Int
    let category: RoadmapCategory
    let completionPercentage: Double?
    let releaseDate: Date?

    var hasUserVoted: Bool = false

    var isNew: Bool {
        if let releaseDate = releaseDate {
            // Consider "new" if released within last 30 days
            return Date().timeIntervalSince(releaseDate) < 30 * 24 * 60 * 60
        }
        return false
    }
}

/**
 * Roadmap service errors
 */
enum RoadmapError: Error, LocalizedError {
    case itemNotFound
    case alreadyVoted

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Roadmap item not found"
        case .alreadyVoted:
            return "You've already voted for this item"
        }
    }
}
