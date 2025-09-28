import Foundation
import SwiftData

/**
 * StepSparringDataService.swift
 * 
 * PURPOSE: Service layer for step sparring data management
 * 
 * FEATURES:
 * - Load and filter step sparring sequences by belt level and type
 * - Manage user progress tracking for sequences
 * - Handle content loading from JSON files
 * - Progress analytics and mastery tracking
 */

@Observable
final class StepSparringDataService {
    let modelContext: ModelContext
    private var sequences: [StepSparringSequence] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Sequence Loading and Management
    
    /**
     * Loads all step sparring sequences from the database - WITH RELATIONSHIP LOADING
     */
    func loadAllSequences() -> [StepSparringSequence] {
        var descriptor = FetchDescriptor<StepSparringSequence>()
        descriptor.relationshipKeyPathsForPrefetching = [\.beltLevels]
        
        do {
            let allSequences = try modelContext.fetch(descriptor)
            
            // Skip relationship loading to avoid crashes
            
            sequences = allSequences.sorted { lhs, rhs in
                if lhs.type.rawValue != rhs.type.rawValue {
                    return lhs.type.rawValue < rhs.type.rawValue
                }
                return lhs.sequenceNumber < rhs.sequenceNumber
            }
            print("📚 DEBUG: loadAllSequences() found \(sequences.count) step sparring sequences in database")
            return sequences
        } catch {
            print("❌ Failed to load step sparring sequences: \(error)")
            return []
        }
    }
    
    /**
     * Gets sequences appropriate for a user's current belt level
     */
    func getSequencesForUser(userProfile: UserProfile) -> [StepSparringSequence] {
        let allSequences = loadAllSequences()
        return allSequences.filter { sequence in
            // Use manual belt check instead of relationship access
            manualBeltLevelCheck(for: sequence, userBelt: userProfile.currentBeltLevel)
        }
    }
    
    /**
     * Gets sequences filtered by type and belt level - BYPASS RELATIONSHIP LOADING
     */
    func getSequences(
        for type: StepSparringType, 
        userProfile: UserProfile
    ) -> [StepSparringSequence] {
        // Simple fetch without relationship prefetching
        let descriptor = FetchDescriptor<StepSparringSequence>()
        
        do {
            let allSequences = try modelContext.fetch(descriptor)
            
            // Filter programmatically with manual belt checking
            let filteredSequences = allSequences.filter { sequence in
                // First filter by type
                guard sequence.type == type else { return false }
                
                // Manual belt level checking - BYPASS the relationship entirely
                let isAvailable = manualBeltLevelCheck(for: sequence, userBelt: userProfile.currentBeltLevel)
                
                print("🔍 FILTER DEBUG: Sequence #\(sequence.sequenceNumber) '\(sequence.name)':")
                print("   Manual belt check result: \(isAvailable)")
                print("   User belt: \(userProfile.currentBeltLevel.shortName)(\(userProfile.currentBeltLevel.sortOrder))")
                print("   Available: \(isAvailable)")
                
                return isAvailable
            }
            
            let sortedSequences = filteredSequences.sorted { $0.sequenceNumber < $1.sequenceNumber }
            print("✅ Found \(sortedSequences.count) \(type.displayName) sequences")
            return sortedSequences
        } catch {
            print("❌ Failed to fetch sequences: \(error)")
            return []
        }
    }
    
    /**
     * Manual belt level checking using JSON data - bypasses SwiftData relationships entirely
     * Uses the applicable_belt_levels stored from JSON during content loading
     */
    private func manualBeltLevelCheck(for sequence: StepSparringSequence, userBelt: BeltLevel) -> Bool {
        // Use JSON belt level data instead of hardcoded patterns
        let expectedBelts = sequence.applicableBeltLevelIds
        
        DebugLogger.data("🔍 Checking sequence '\(sequence.name)' for user belt '\(userBelt.shortName)'")
        DebugLogger.data("   JSON applicable belts: \(expectedBelts)")
        
        // If no belt levels defined in JSON, sequence is not available
        guard !expectedBelts.isEmpty else {
            DebugLogger.data("❌ No applicable belt levels found for \(sequence.name)")
            return false
        }
        
        // Convert expected belts to normalized names and check against user belt
        for expectedBelt in expectedBelts {
            let normalizedBelt = expectedBelt.replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "keup", with: "Keup")
                .replacingOccurrences(of: "dan", with: "Dan")
            
            DebugLogger.data("   Checking '\(expectedBelt)' -> '\(normalizedBelt)' vs user '\(userBelt.shortName)'")
            
            // Check if user's belt matches any expected belt
            // User can access sequences for their current belt and all previous belts (higher sort order)
            if normalizedBelt == userBelt.shortName || 
               (getBeltSortOrder(for: normalizedBelt) >= userBelt.sortOrder) {
                DebugLogger.data("✅ Belt match found - sequence available")
                return true
            }
        }
        
        DebugLogger.data("❌ No belt match found - sequence not available")
        return false
    }
    
    /**
     * Helper to get sort order for belt names
     */
    private func getBeltSortOrder(for beltName: String) -> Int {
        let descriptor = FetchDescriptor<BeltLevel>(
            predicate: #Predicate { belt in belt.shortName == beltName }
        )
        
        do {
            if let belt = try modelContext.fetch(descriptor).first {
                return belt.sortOrder
            }
        } catch {
            print("❌ Failed to get sort order for \(beltName): \(error)")
        }
        
        return Int.max // Default to inaccessible if belt not found
    }
    
    /**
     * Gets a specific sequence by ID
     */
    func getSequence(id: UUID) -> StepSparringSequence? {
        let descriptor = FetchDescriptor<StepSparringSequence>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("❌ Failed to fetch sequence \(id): \(error)")
            return nil
        }
    }
    
    // MARK: - Progress Tracking
    
    /**
     * Gets user's progress for a specific sequence
     */
    func getUserProgress(
        for sequence: StepSparringSequence, 
        userProfile: UserProfile
    ) -> UserStepSparringProgress? {
        // Use IDs instead of object references to avoid invalidated object issues
        let sequenceId = sequence.id
        let profileId = userProfile.id
        
        let descriptor = FetchDescriptor<UserStepSparringProgress>()
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first { progress in
                progress.userProfile.id == profileId &&
                progress.sequence.id == sequenceId
            }
        } catch {
            print("❌ Failed to fetch step sparring progress: \(error)")
            return nil
        }
    }
    
    /**
     * Gets or creates progress record for a sequence
     */
    func getOrCreateProgress(
        for sequence: StepSparringSequence,
        userProfile: UserProfile
    ) -> UserStepSparringProgress {
        if let existing = getUserProgress(for: sequence, userProfile: userProfile) {
            return existing
        }
        
        let newProgress = UserStepSparringProgress(
            userProfile: userProfile,
            sequence: sequence
        )
        
        modelContext.insert(newProgress)
        
        do {
            try modelContext.save()
            print("✅ Created step sparring progress for \(sequence.name)")
        } catch {
            print("❌ Failed to save step sparring progress: \(error)")
        }
        
        return newProgress
    }
    
    /**
     * Records a practice session for a sequence
     */
    func recordPracticeSession(
        sequence: StepSparringSequence,
        userProfile: UserProfile,
        duration: TimeInterval,
        stepsCompleted: Int
    ) {
        let progress = getOrCreateProgress(for: sequence, userProfile: userProfile)
        progress.recordPractice(duration: duration, stepsCompleted: stepsCompleted)
        
        do {
            try modelContext.save()
            print("✅ Recorded practice session for \(sequence.name)")
        } catch {
            print("❌ Failed to save practice session: \(error)")
        }
    }
    
    /**
     * Gets all progress records for a user
     */
    func getAllUserProgress(userProfile: UserProfile) -> [UserStepSparringProgress] {
        // Use simple predicate instead of relationship navigation
        let profileId = userProfile.id
        let predicate = #Predicate<UserStepSparringProgress> { progress in
            progress.userProfile.id == profileId
        }
        
        let descriptor = FetchDescriptor<UserStepSparringProgress>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt)]
        )
        
        do {
            let allProgress = try modelContext.fetch(descriptor)
            // Return without additional sorting to avoid relationship access
            return allProgress
        } catch {
            print("❌ Failed to fetch user step sparring progress: \(error)")
            return []
        }
    }
    
    // MARK: - Progress Analytics
    
    /**
     * Gets summary statistics for a user's step sparring progress
     */
    func getProgressSummary(userProfile: UserProfile) -> StepSparringProgressSummary {
        let allProgress = getAllUserProgress(userProfile: userProfile)
        
        var summary = StepSparringProgressSummary()
        
        for progress in allProgress {
            summary.totalSequences += 1
            summary.totalPracticeSessions += progress.practiceCount
            summary.totalPracticeTime += progress.totalPracticeTime
            
            switch progress.masteryLevel {
            case .learning:
                summary.learning += 1
            case .familiar:
                summary.familiar += 1
            case .proficient:
                summary.proficient += 1
            case .mastered:
                summary.mastered += 1
            }
            
            // Track by type - defensive approach to avoid relationship crashes
            // For now, just categorize all progress as threeStep to avoid the relationship access
            // This is a temporary fix until we can resolve the SwiftData relationship issues
            summary.threeStepProgress.append(progress)
        }
        
        // Calculate overall completion percentage - ensure no NaN
        if summary.totalSequences > 0 {
            let percentage = Double(summary.mastered) / Double(summary.totalSequences) * 100.0
            summary.overallCompletionPercentage = percentage.isNaN || percentage.isInfinite ? 0.0 : percentage
        } else {
            summary.overallCompletionPercentage = 0.0
        }
        
        return summary
    }
    
    // MARK: - Content Management
    
    /**
     * Clears existing step sparring sequences and reloads from JSON
     */
    func clearAndReloadStepSparring() {
        print("🔄 Clearing and reloading step sparring sequences from JSON...")
        
        // Clear existing sequences and progress
        do {
            let sequenceDescriptor = FetchDescriptor<StepSparringSequence>()
            let existingSequences = try modelContext.fetch(sequenceDescriptor)
            
            let progressDescriptor = FetchDescriptor<UserStepSparringProgress>()
            let existingProgress = try modelContext.fetch(progressDescriptor)
            
            for sequence in existingSequences {
                modelContext.delete(sequence)
            }
            
            for progress in existingProgress {
                modelContext.delete(progress)
            }
            
            try modelContext.save()
            print("🗑️ Cleared \(existingSequences.count) sequences and \(existingProgress.count) progress records")
        } catch {
            print("❌ Failed to clear existing step sparring data: \(error)")
        }
        
        // Reload from JSON
        let loader = StepSparringContentLoader(stepSparringService: self)
        loader.loadAllContent()
        
        print("✅ Step sparring sequences reloaded from JSON")
    }
    
    
}

// MARK: - Progress Summary Model

/**
 * Summary statistics for user's step sparring progress
 */
struct StepSparringProgressSummary {
    var totalSequences: Int = 0
    var totalPracticeSessions: Int = 0
    var totalPracticeTime: TimeInterval = 0
    var overallCompletionPercentage: Double = 0.0
    
    // Progress by mastery level
    var learning: Int = 0
    var familiar: Int = 0
    var proficient: Int = 0
    var mastered: Int = 0
    
    // Progress by sparring type
    var threeStepProgress: [UserStepSparringProgress] = []
    var twoStepProgress: [UserStepSparringProgress] = []
    var oneStepProgress: [UserStepSparringProgress] = []
    var semiFreeProgress: [UserStepSparringProgress] = []
}