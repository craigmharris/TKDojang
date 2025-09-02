import Foundation
import SwiftData
import SwiftUI

/**
 * TerminologyDataService.swift
 * 
 * PURPOSE: Service layer for managing terminology database operations
 * 
 * RESPONSIBILITIES:
 * - Database initialization and seeding
 * - CRUD operations for terminology content
 * - Learning algorithm implementation
 * - Content filtering by belt level and category
 */

@Observable
@MainActor
class TerminologyDataService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Accessors
    
    /**
     * Provides access to the model context for content loading operations
     */
    var modelContextForLoading: ModelContext {
        return modelContext
    }
    
    // MARK: - Belt Level Operations
    
    
    /**
     * Creates and returns all terminology categories
     */
    func createTerminologyCategories() -> [TerminologyCategory] {
        let categories = [
            TerminologyCategory(name: "basics", displayName: "Basics & Commands", sortOrder: 1),
            TerminologyCategory(name: "numbers", displayName: "Numbers & Counting", sortOrder: 2),
            TerminologyCategory(name: "techniques", displayName: "Techniques & Movements", sortOrder: 3),
            TerminologyCategory(name: "stances", displayName: "Stances & Positions", sortOrder: 4),
            TerminologyCategory(name: "blocks", displayName: "Blocks & Defense", sortOrder: 5),
            TerminologyCategory(name: "strikes", displayName: "Strikes & Attacks", sortOrder: 6),
            TerminologyCategory(name: "kicks", displayName: "Kicks & Leg Techniques", sortOrder: 7),
            TerminologyCategory(name: "patterns", displayName: "Patterns (Tul)", sortOrder: 8),
            TerminologyCategory(name: "titles", displayName: "Titles & Ranks", sortOrder: 9),
            TerminologyCategory(name: "philosophy", displayName: "Philosophy & Tenets", sortOrder: 10)
        ]
        
        categories.forEach { category in
            category.iconName = getIconName(for: category.name)
            modelContext.insert(category) 
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save categories: \\(error)")
        }
        
        return categories
    }
    
    private func getIconName(for categoryName: String) -> String {
        switch categoryName {
        case "basics": return "book.fill"
        case "numbers": return "number.circle.fill"
        case "techniques": return "figure.martial.arts"
        case "stances": return "figure.stand"
        case "blocks": return "shield.fill"
        case "strikes": return "hand.raised.fill"
        case "kicks": return "figure.run"
        case "patterns": return "square.grid.3x3.fill"
        case "titles": return "crown.fill"
        case "philosophy": return "brain.head.profile"
        default: return "book.fill"
        }
    }
    
    // MARK: - Terminology CRUD Operations
    
    /**
     * Adds a new terminology entry to the database
     */
    func addTerminologyEntry(
        englishTerm: String,
        koreanHangul: String,
        romanizedPronunciation: String,
        beltLevel: BeltLevel,
        category: TerminologyCategory,
        difficulty: Int = 1,
        phoneticPronunciation: String? = nil,
        definition: String? = nil,
        notes: String? = nil
    ) -> TerminologyEntry {
        
        let entry = TerminologyEntry(
            englishTerm: englishTerm,
            koreanHangul: koreanHangul,
            romanizedPronunciation: romanizedPronunciation,
            beltLevel: beltLevel,
            category: category,
            difficulty: difficulty
        )
        
        entry.phoneticPronunciation = phoneticPronunciation
        entry.definition = definition
        entry.notes = notes
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save terminology entry: \\(error)")
        }
        
        return entry
    }
    
    /**
     * Fetches terminology entries for a user's learning session
     * 
     * PURPOSE: Returns filtered content based on user's belt level and learning mode
     */
    func getTerminologyForUser(userProfile: UserProfile, limit: Int = 20) -> [TerminologyEntry] {
        let currentBeltSortOrder = userProfile.currentBeltLevel.sortOrder
        // Getting terminology for user's current belt and learning mode
        
        let descriptor: FetchDescriptor<TerminologyEntry>
        
        switch userProfile.learningMode {
        case .progression:
            // Focus on current belt level only
            // Progression mode: focus on mastering current belt
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate { entry in
                    entry.beltLevel.sortOrder == currentBeltSortOrder
                },
                sortBy: [SortDescriptor(\.difficulty), SortDescriptor(\.englishTerm)]
            )
            
        case .mastery:
            // All content up to and including current belt
            // Mastery mode: including all terms up to current belt
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate { entry in
                    entry.beltLevel.sortOrder >= currentBeltSortOrder
                },
                sortBy: [SortDescriptor(\.difficulty), SortDescriptor(\.englishTerm)]
            )
        }
        
        do {
            let entries = try modelContext.fetch(descriptor)
            // Found terminology entries for practice
            
            return Array(entries.prefix(limit))
        } catch {
            print("Failed to fetch terminology: \(error)")
            return []
        }
    }
    
    /**
     * Gets terminology entries that are due for review (spaced repetition)
     */
    func getTerminologyDueForReview(userProfile: UserProfile) -> [TerminologyEntry] {
        let now = Date()
        let profileId = userProfile.id
        
        let descriptor = FetchDescriptor<UserTerminologyProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && progress.nextReviewDate <= now
            }
        )
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            return progressEntries.map { $0.terminologyEntry }
        } catch {
            print("Failed to fetch due reviews: \\(error)")
            return []
        }
    }
    
    
    // MARK: - Progress Tracking
    
    /**
     * Records a user's answer and updates their progress
     */
    func recordUserAnswer(
        userProfile: UserProfile,
        terminologyEntry: TerminologyEntry,
        isCorrect: Bool,
        responseTime: Double
    ) {
        
        // Find existing progress or create new one
        let profileId = userProfile.id
        let entryId = terminologyEntry.id
        
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && 
                progress.terminologyEntry.id == entryId
            }
        )
        
        do {
            let existingProgress = try modelContext.fetch(progressDescriptor).first
            let progress = existingProgress ?? UserTerminologyProgress(
                terminologyEntry: terminologyEntry, 
                userProfile: userProfile
            )
            
            if existingProgress == nil {
                modelContext.insert(progress)
            }
            
            progress.recordAnswer(isCorrect: isCorrect, responseTime: responseTime)
            
            try modelContext.save()
            
        } catch {
            print("Failed to record user answer: \\(error)")
        }
    }
    
    // MARK: - Statistics and Analytics
    
    /**
     * Gets user's learning statistics
     */
    func getUserStatistics(userProfile: UserProfile) -> UserStatistics {
        let profileId = userProfile.id
        
        let descriptor = FetchDescriptor<UserTerminologyProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId
            }
        )
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            
            let totalTerms = progressEntries.count
            let masteredTerms = progressEntries.filter { $0.masteryLevel == .mastered }.count
            let totalCorrect = progressEntries.reduce(0) { $0 + $1.correctCount }
            let totalIncorrect = progressEntries.reduce(0) { $0 + $1.incorrectCount }
            let totalReviews = totalCorrect + totalIncorrect
            
            let accuracyRate = totalReviews > 0 ? Double(totalCorrect) / Double(totalReviews) : 0.0
            let masteryRate = totalTerms > 0 ? Double(masteredTerms) / Double(totalTerms) : 0.0
            
            return UserStatistics(
                totalTermsStudied: totalTerms,
                masteredTerms: masteredTerms,
                totalReviews: totalReviews,
                accuracyRate: accuracyRate,
                masteryRate: masteryRate,
                currentStreak: calculateCurrentStreak(progressEntries)
            )
            
        } catch {
            print("Failed to fetch user statistics: \\(error)")
            return UserStatistics()
        }
    }
    
    private func calculateCurrentStreak(_ progressEntries: [UserTerminologyProgress]) -> Int {
        // Calculate the current streak of consecutive correct answers across all terms
        // This is a simplified version - you might want a more sophisticated streak calculation
        return progressEntries.map { $0.consecutiveCorrect }.max() ?? 0
    }
    
    /**
     * Adds a terminology entry to the user's review queue
     * Used when user gets a question wrong in tests
     */
    func addToReviewQueue(_ terminologyEntry: TerminologyEntry) throws {
        guard let userProfile = getDefaultUserProfile() else {
            throw DataServiceError.noUserProfile
        }
        
        // Get or create progress for this term
        let progress = getOrCreateProgress(for: terminologyEntry, userProfile: userProfile)
        
        // Reset to first box for immediate review
        progress.currentBox = 1
        progress.nextReviewDate = Date() // Available for review immediately
        progress.lastReviewedAt = Date()
        
        try modelContext.save()
    }
    
    private func getDefaultUserProfile() -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to fetch default user profile: \\(error)")
            return nil
        }
    }
    
    private func getOrCreateProgress(for terminologyEntry: TerminologyEntry, userProfile: UserProfile) -> UserTerminologyProgress {
        let profileId = userProfile.id
        let entryId = terminologyEntry.id
        
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && 
                progress.terminologyEntry.id == entryId
            }
        )
        
        do {
            if let existingProgress = try modelContext.fetch(progressDescriptor).first {
                return existingProgress
            } else {
                let newProgress = UserTerminologyProgress(
                    terminologyEntry: terminologyEntry,
                    userProfile: userProfile
                )
                modelContext.insert(newProgress)
                return newProgress
            }
        } catch {
            print("Failed to fetch existing progress, creating new: \\(error)")
            let newProgress = UserTerminologyProgress(
                terminologyEntry: terminologyEntry,
                userProfile: userProfile
            )
            modelContext.insert(newProgress)
            return newProgress
        }
    }
}

// MARK: - Error Types

enum DataServiceError: Error {
    case noUserProfile
    case invalidTerminology
    case saveFailed
}

// MARK: - Supporting Data Structures

/**
 * User learning statistics for display in UI
 */
struct UserStatistics {
    let totalTermsStudied: Int
    let masteredTerms: Int
    let totalReviews: Int
    let accuracyRate: Double // 0.0 to 1.0
    let masteryRate: Double  // 0.0 to 1.0
    let currentStreak: Int
    
    init(totalTermsStudied: Int = 0, masteredTerms: Int = 0, totalReviews: Int = 0, 
         accuracyRate: Double = 0.0, masteryRate: Double = 0.0, currentStreak: Int = 0) {
        self.totalTermsStudied = totalTermsStudied
        self.masteredTerms = masteredTerms
        self.totalReviews = totalReviews
        self.accuracyRate = accuracyRate
        self.masteryRate = masteryRate
        self.currentStreak = currentStreak
    }
}