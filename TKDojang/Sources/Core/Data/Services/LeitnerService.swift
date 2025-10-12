import Foundation
import SwiftData

/**
 * LeitnerService.swift
 * 
 * PURPOSE: Manages Leitner Box spaced repetition system with feature flag support
 * 
 * ARCHITECTURE DECISION: Feature flag approach to enable/disable Leitner system
 * WHY: Allows users to choose between classic flashcards and advanced spaced repetition
 * Benefits: Gradual rollout, user preference, fallback to simpler system if needed
 */

@MainActor
final class LeitnerService: ObservableObject {
    private let modelContext: ModelContext
    
    // Feature flag for Leitner system
    @Published var isLeitnerModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLeitnerModeEnabled, forKey: "leitnerModeEnabled")
            DebugLogger.data("🎯 LeitnerService: Mode changed to \(isLeitnerModeEnabled ? "Leitner" : "Classic")")
        }
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.isLeitnerModeEnabled = UserDefaults.standard.bool(forKey: "leitnerModeEnabled")
    }
    
    // MARK: - Feature Flag Management
    
    /**
     * Toggles between Leitner and Classic modes
     */
    func toggleLeitnerMode() {
        isLeitnerModeEnabled.toggle()
    }
    
    /**
     * Gets current mode display name for UI
     */
    var currentModeDisplayName: String {
        isLeitnerModeEnabled ? "Leitner Mode" : "Classic Mode"
    }
    
    /**
     * Gets description of current mode
     */
    var currentModeDescription: String {
        if isLeitnerModeEnabled {
            return "Advanced spaced repetition with 5-box scheduling system"
        } else {
            return "Simple flashcards with basic progress tracking"
        }
    }
    
    // MARK: - Terms Scheduling
    
    /**
     * Gets terms ready for review based on current mode
     */
    func getTermsForReview(userProfile: UserProfile, limit: Int = 50) -> [TerminologyEntry] {
        if isLeitnerModeEnabled {
            return getLeitnerTermsForReview(userProfile: userProfile, limit: limit)
        } else {
            return getClassicTermsForReview(userProfile: userProfile, limit: limit)
        }
    }
    
    /**
     * Leitner mode: Returns terms based on spaced repetition schedule
     */
    private func getLeitnerTermsForReview(userProfile: UserProfile, limit: Int) -> [TerminologyEntry] {
        let now = Date()
        let profileId = userProfile.id
        
        var descriptor = FetchDescriptor<UserTerminologyProgress>(
            sortBy: [
                SortDescriptor(\.currentBox, order: .forward),  // Box 1 terms first (need more practice)
                SortDescriptor(\.nextReviewDate, order: .forward) // Earlier dates first
            ]
        )
        descriptor.fetchLimit = limit
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            // Filter in-memory since SwiftData predicates with relationships are problematic
            let dueEntries = progressEntries.filter { progress in
                progress.userProfile.id == profileId && progress.nextReviewDate <= now
            }
            return dueEntries.map { $0.terminologyEntry }
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to fetch Leitner terms: \(error)")
            return []
        }
    }
    
    /**
     * Classic mode: Returns terms in simple rotation
     */
    private func getClassicTermsForReview(userProfile: UserProfile, limit: Int) -> [TerminologyEntry] {
        // Get belt levels up to user's current level
        let userBeltSortOrder = userProfile.currentBeltLevel.sortOrder
        
        let beltDescriptor = FetchDescriptor<BeltLevel>()
        
        do {
            let allBelts = try modelContext.fetch(beltDescriptor)
            let applicableBelts = allBelts.filter { $0.sortOrder >= userBeltSortOrder }
            let beltIds = applicableBelts.map { $0.id }
            
            var termDescriptor = FetchDescriptor<TerminologyEntry>(
                sortBy: [
                    SortDescriptor(\.beltLevel.sortOrder, order: .reverse), // Higher belts first
                    SortDescriptor(\.createdAt, order: .forward)
                ]
            )
            termDescriptor.fetchLimit = limit
            
            let allTerms = try modelContext.fetch(termDescriptor)
            // Filter in-memory to avoid complex predicate issues
            let filteredTerms = allTerms.filter { term in
                beltIds.contains(term.beltLevel.id)
            }
            
            return Array(filteredTerms.prefix(limit))
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to fetch classic terms: \(error)")
            return []
        }
    }
    
    // MARK: - Progress Recording
    
    /**
     * Records user answer with mode-appropriate logic
     */
    func recordAnswer(
        userProfile: UserProfile,
        terminologyEntry: TerminologyEntry,
        isCorrect: Bool,
        responseTime: Double
    ) {
        if isLeitnerModeEnabled {
            recordLeitnerAnswer(
                userProfile: userProfile,
                terminologyEntry: terminologyEntry,
                isCorrect: isCorrect,
                responseTime: responseTime
            )
        } else {
            recordClassicAnswer(
                userProfile: userProfile,
                terminologyEntry: terminologyEntry,
                isCorrect: isCorrect,
                responseTime: responseTime
            )
        }
    }
    
    /**
     * Leitner mode: Advanced spaced repetition with box progression
     */
    private func recordLeitnerAnswer(
        userProfile: UserProfile,
        terminologyEntry: TerminologyEntry,
        isCorrect: Bool,
        responseTime: Double
    ) {
        // Find or create progress entry
        let progress = getOrCreateProgress(userProfile: userProfile, terminologyEntry: terminologyEntry)
        
        // Record answer using Leitner algorithm
        progress.recordAnswer(isCorrect: isCorrect, responseTime: responseTime)
        
        do {
            try modelContext.save()
            DebugLogger.data("📊 LeitnerService: Recorded Leitner answer - Term: \(terminologyEntry.englishTerm), Correct: \(isCorrect), Box: \(progress.currentBox)")
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to save Leitner progress: \(error)")
        }
    }
    
    /**
     * Classic mode: Simple correct/incorrect tracking without scheduling
     */
    private func recordClassicAnswer(
        userProfile: UserProfile,
        terminologyEntry: TerminologyEntry,
        isCorrect: Bool,
        responseTime: Double
    ) {
        // Find or create progress entry
        let progress = getOrCreateProgress(userProfile: userProfile, terminologyEntry: terminologyEntry)
        
        // Simple progress tracking without box progression
        progress.totalReviews += 1
        progress.lastReviewedAt = Date()
        progress.updatedAt = Date()
        
        // Update response time average
        progress.averageResponseTime = (progress.averageResponseTime * Double(progress.totalReviews - 1) + responseTime) / Double(progress.totalReviews)
        
        if isCorrect {
            progress.correctCount += 1
            progress.consecutiveCorrect += 1
        } else {
            progress.incorrectCount += 1
            progress.consecutiveCorrect = 0
        }
        
        // Update mastery level based on performance
        updateClassicMasteryLevel(progress: progress)
        
        // Set next review date to immediate availability (classic mode doesn't use scheduling)
        progress.nextReviewDate = Date()
        
        do {
            try modelContext.save()
            DebugLogger.data("📊 LeitnerService: Recorded classic answer - Term: \(terminologyEntry.englishTerm), Correct: \(isCorrect), Mastery: \(progress.masteryLevel)")
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to save classic progress: \(error)")
        }
    }
    
    /**
     * Updates mastery level for classic mode (without box progression)
     */
    private func updateClassicMasteryLevel(progress: UserTerminologyProgress) {
        let accuracy = progress.totalReviews > 0 ? 
            Double(progress.correctCount) / Double(progress.totalReviews) : 0.0
        
        switch accuracy {
        case 0.0..<0.5:
            progress.masteryLevel = .learning
        case 0.5..<0.75:
            progress.masteryLevel = .familiar
        case 0.75..<0.9:
            progress.masteryLevel = .proficient
        default:
            progress.masteryLevel = .mastered
        }
    }
    
    /**
     * Gets or creates progress entry for a user and term
     */
    private func getOrCreateProgress(userProfile: UserProfile, terminologyEntry: TerminologyEntry) -> UserTerminologyProgress {
        let profileId = userProfile.id
        let termId = terminologyEntry.id
        
        let descriptor = FetchDescriptor<UserTerminologyProgress>()
        
        do {
            let allProgress = try modelContext.fetch(descriptor)
            // Filter in-memory to avoid predicate issues
            if let existingProgress = allProgress.first(where: { progress in
                progress.userProfile.id == profileId && progress.terminologyEntry.id == termId
            }) {
                return existingProgress
            } else {
                // Create new progress entry
                let newProgress = UserTerminologyProgress(terminologyEntry: terminologyEntry, userProfile: userProfile)
                modelContext.insert(newProgress)
                return newProgress
            }
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to fetch/create progress: \(error)")
            // Fallback: create new progress entry
            let newProgress = UserTerminologyProgress(terminologyEntry: terminologyEntry, userProfile: userProfile)
            modelContext.insert(newProgress)
            return newProgress
        }
    }
    
    // MARK: - Statistics
    
    /**
     * Gets Leitner box distribution for user
     */
    func getBoxDistribution(userProfile: UserProfile) -> [Int: Int] {
        guard isLeitnerModeEnabled else { return [:] }
        
        let profileId = userProfile.id
        let descriptor = FetchDescriptor<UserTerminologyProgress>()
        
        do {
            let allProgress = try modelContext.fetch(descriptor)
            // Filter for this user's progress
            let userProgress = allProgress.filter { $0.userProfile.id == profileId }
            
            var distribution: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
            
            for progress in userProgress {
                distribution[progress.currentBox] = (distribution[progress.currentBox] ?? 0) + 1
            }
            
            return distribution
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to get box distribution: \(error)")
            return [:]
        }
    }
    
    /**
     * Gets terms due for review count
     */
    func getTermsDueCount(userProfile: UserProfile) -> Int {
        if isLeitnerModeEnabled {
            let now = Date()
            let profileId = userProfile.id
            let descriptor = FetchDescriptor<UserTerminologyProgress>()
            
            do {
                let allProgress = try modelContext.fetch(descriptor)
                // Filter for this user's due terms
                let dueCount = allProgress.filter { progress in
                    progress.userProfile.id == profileId && progress.nextReviewDate <= now
                }.count
                return dueCount
            } catch {
                DebugLogger.data("❌ LeitnerService: Failed to count due terms: \(error)")
                return 0
            }
        } else {
            // In classic mode, all terms are always available
            return getClassicTermsForReview(userProfile: userProfile, limit: 1000).count
        }
    }
    
    // MARK: - Data Migration
    
    /**
     * Migrates existing progress data to Leitner boxes (called when enabling Leitner mode)
     */
    func migrateToLeitnerMode(userProfile: UserProfile) {
        DebugLogger.data("🔄 LeitnerService: Starting migration to Leitner mode for \(userProfile.name)")
        
        let profileId = userProfile.id
        let descriptor = FetchDescriptor<UserTerminologyProgress>()
        
        do {
            let allProgress = try modelContext.fetch(descriptor)
            // Filter for this user's progress
            let userProgress = allProgress.filter { $0.userProfile.id == profileId }
            
            for progress in userProgress {
                // Migrate to appropriate box based on current mastery level
                switch progress.masteryLevel {
                case .learning:
                    progress.currentBox = 1
                case .familiar:
                    progress.currentBox = 2
                case .proficient:
                    progress.currentBox = 3
                case .mastered:
                    progress.currentBox = 4
                }
                
                // Recalculate next review date based on new box
                progress.nextReviewDate = progress.calculateNextReviewDate()
            }
            
            try modelContext.save()
            DebugLogger.data("✅ LeitnerService: Migrated \(userProgress.count) progress entries to Leitner boxes")
        } catch {
            DebugLogger.data("❌ LeitnerService: Failed to migrate to Leitner mode: \(error)")
        }
    }
}

// MARK: - UserTerminologyProgress Extension

extension UserTerminologyProgress {
    /**
     * Recalculates next review date using configurable intervals
     */
    func calculateNextReviewDate() -> Date {
        let calendar = Calendar.current
        
        // Use configurable intervals instead of hardcoded values
        let days = LeitnerConfigManager.shared.getIntervalDays(forBox: currentBox)
        
        return calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}