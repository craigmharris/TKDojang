import Foundation
import SwiftData

/**
 * PatternDataService.swift
 * 
 * PURPOSE: Service layer for managing pattern database operations
 * 
 * RESPONSIBILITIES:
 * - Pattern CRUD operations
 * - User progress tracking for patterns
 * - Pattern content loading and management
 * - Integration with belt system and user profiles
 */

@Observable
@MainActor
class PatternDataService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Pattern Management
    
    /**
     * Creates and saves a new pattern to the database
     */
    func createPattern(
        name: String,
        hangul: String,
        englishMeaning: String,
        significance: String,
        moveCount: Int,
        diagramDescription: String,
        startingStance: String,
        videoURL: String? = nil,
        diagramImageURL: String? = nil,
        beltLevels: [BeltLevel] = [],
        moves: [PatternMove] = []
    ) -> Pattern {
        
        let pattern = Pattern(
            name: name,
            hangul: hangul,
            englishMeaning: englishMeaning,
            significance: significance,
            moveCount: moveCount,
            diagramDescription: diagramDescription,
            startingStance: startingStance,
            videoURL: videoURL,
            diagramImageURL: diagramImageURL
        )
        
        pattern.beltLevels = beltLevels
        pattern.moves = moves
        
        // Set pattern relationship for moves
        moves.forEach { move in
            move.pattern = pattern
        }
        
        modelContext.insert(pattern)
        
        do {
            try modelContext.save()
            DebugLogger.data("✅ Created pattern: \(name) with \(moves.count) moves")
        } catch {
            DebugLogger.data("❌ Failed to save pattern: \(error)")
        }
        
        return pattern
    }
    
    /**
     * Fetches all patterns available to a user based on their belt level
     */
    func getPatternsForUser(userProfile: UserProfile) -> [Pattern] {
        let _ = userProfile.currentBeltLevel.sortOrder
        
        let descriptor = FetchDescriptor<Pattern>()
        
        do {
            let allPatterns = try modelContext.fetch(descriptor)
            
            // Filter patterns appropriate for user's belt level and sort by belt level
            let filteredPatterns = allPatterns.filter { pattern in
                pattern.isAppropriateFor(beltLevel: userProfile.currentBeltLevel)
            }
            
            // Sort by primary belt level (descending sort order = ascending belt progression)
            return filteredPatterns.sorted { pattern1, pattern2 in
                let belt1SortOrder = pattern1.primaryBeltLevel?.sortOrder ?? Int.max
                let belt2SortOrder = pattern2.primaryBeltLevel?.sortOrder ?? Int.max
                return belt1SortOrder > belt2SortOrder // Higher sort order first (9th keup before 8th keup)
            }
        } catch {
            DebugLogger.data("Failed to fetch patterns: \(error)")
            return []
        }
    }
    
    /**
     * Fetches a specific pattern by name
     */
    func getPattern(byName name: String) -> Pattern? {
        let descriptor = FetchDescriptor<Pattern>(
            predicate: #Predicate { pattern in
                pattern.name == name
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            DebugLogger.data("Failed to fetch pattern '\(name)': \(error)")
            return nil
        }
    }
    
    /**
     * Fetches all patterns for a specific belt level
     */
    func getPatterns(forBeltLevel beltLevel: BeltLevel) -> [Pattern] {
        let descriptor = FetchDescriptor<Pattern>(
            sortBy: [SortDescriptor(\Pattern.name)]
        )
        
        do {
            let allPatterns = try modelContext.fetch(descriptor)
            return allPatterns.filter { pattern in
                pattern.beltLevels.contains { $0.id == beltLevel.id }
            }
        } catch {
            DebugLogger.data("Failed to fetch patterns for belt level: \(error)")
            return []
        }
    }
    
    // MARK: - Move Management
    
    /**
     * Adds a move to an existing pattern
     */
    func addMove(
        to pattern: Pattern,
        moveNumber: Int,
        stance: String,
        technique: String,
        direction: String,
        target: String? = nil,
        keyPoints: String,
        commonMistakes: String? = nil,
        executionNotes: String? = nil,
        imageURL: String? = nil
    ) -> PatternMove {
        
        let move = PatternMove(
            moveNumber: moveNumber,
            stance: stance,
            technique: technique,
            direction: direction,
            target: target,
            keyPoints: keyPoints,
            commonMistakes: commonMistakes,
            executionNotes: executionNotes,
            imageURL: imageURL
        )
        
        move.pattern = pattern
        pattern.moves.append(move)
        pattern.updatedAt = Date()
        
        modelContext.insert(move)
        
        do {
            try modelContext.save()
            DebugLogger.data("✅ Added move \(moveNumber) to pattern \(pattern.name)")
        } catch {
            DebugLogger.data("❌ Failed to save move: \(error)")
        }
        
        return move
    }
    
    // MARK: - User Progress Tracking
    
    /**
     * Gets or creates user progress for a specific pattern
     */
    func getUserProgress(for pattern: Pattern, userProfile: UserProfile) -> UserPatternProgress {
        let profileId = userProfile.id
        let patternId = pattern.id
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && progress.pattern.id == patternId
            }
        )
        
        do {
            if let existingProgress = try modelContext.fetch(descriptor).first {
                return existingProgress
            } else {
                let newProgress = UserPatternProgress(userProfile: userProfile, pattern: pattern)
                modelContext.insert(newProgress)
                try modelContext.save()
                return newProgress
            }
        } catch {
            DebugLogger.data("Failed to get user progress: \(error)")
            let newProgress = UserPatternProgress(userProfile: userProfile, pattern: pattern)
            modelContext.insert(newProgress)
            return newProgress
        }
    }
    
    /**
     * Records a practice session for a pattern
     */
    func recordPracticeSession(
        pattern: Pattern,
        userProfile: UserProfile,
        accuracy: Double,
        practiceTime: TimeInterval,
        strugglingMoves: [Int] = []
    ) {
        let progress = getUserProgress(for: pattern, userProfile: userProfile)
        progress.recordPracticeSession(
            accuracy: accuracy,
            practiceTime: practiceTime,
            strugglingMoveNumbers: strugglingMoves
        )
        
        do {
            try modelContext.save()
            DebugLogger.data("✅ Recorded practice session for \(pattern.name): \(Int(accuracy * 100))% accuracy")
        } catch {
            DebugLogger.data("❌ Failed to save practice session: \(error)")
        }
    }
    
    /**
     * Gets all patterns due for review for a user
     */
    func getPatternsDueForReview(userProfile: UserProfile) -> [UserPatternProgress] {
        let profileId = userProfile.id
        let now = Date()
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && progress.nextReviewDate <= now
            },
            sortBy: [SortDescriptor(\UserPatternProgress.nextReviewDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            DebugLogger.data("Failed to fetch patterns due for review: \(error)")
            return []
        }
    }
    
    /**
     * Gets user's pattern learning statistics
     */
    func getUserPatternStatistics(userProfile: UserProfile) -> PatternStatistics {
        let profileId = userProfile.id
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId
            }
        )
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            
            let totalPatterns = progressEntries.count
            let masteredPatterns = progressEntries.filter { $0.masteryLevel == .mastered }.count
            let totalPracticeTime = progressEntries.reduce(0) { $0 + $1.totalPracticeTime }
            let totalSessions = progressEntries.reduce(0) { $0 + $1.practiceCount }
            let averageAccuracy = totalPatterns > 0 ? 
                progressEntries.reduce(0) { $0 + $1.averageAccuracy } / Double(totalPatterns) : 0.0
            
            return PatternStatistics(
                totalPatterns: totalPatterns,
                masteredPatterns: masteredPatterns,
                totalPracticeTime: totalPracticeTime,
                totalSessions: totalSessions,
                averageAccuracy: averageAccuracy
            )
        } catch {
            DebugLogger.data("Failed to fetch pattern statistics: \(error)")
            return PatternStatistics()
        }
    }
    
    // MARK: - Content Loading
    
    /**
     * Development helper: Force reload patterns from JSON (use with caution)
     */
    func forceReloadPatternsFromJSON() {
        DebugLogger.data("⚠️ DEVELOPMENT: Force reloading patterns from JSON files...")
        loadPatternsFromJSON()
    }
    
    /**
     * Seeds the database with initial pattern content from JSON files
     */
    func seedInitialPatterns(beltLevels: [BeltLevel]) {
        // Check if patterns already exist
        let descriptor = FetchDescriptor<Pattern>()
        
        do {
            let existingPatterns = try modelContext.fetch(descriptor)
            if !existingPatterns.isEmpty {
                DebugLogger.data("📚 Patterns already exist, skipping seeding")
                DebugLogger.data("   Found \(existingPatterns.count) existing patterns")
                
                // Debug: Check which patterns have no belt levels (this could be the issue!)
                let patternsWithoutBelts = existingPatterns.filter { $0.beltLevels.isEmpty }
                if !patternsWithoutBelts.isEmpty {
                    DebugLogger.data("⚠️ WARNING: \(patternsWithoutBelts.count) patterns have NO belt levels!")
                    DebugLogger.data("   Patterns without belts: \(patternsWithoutBelts.map { $0.name })")
                }
                
                let patternsWithBelts = existingPatterns.filter { !$0.beltLevels.isEmpty }
                DebugLogger.data("   Patterns with belt levels: \(patternsWithBelts.count)")
                if !patternsWithBelts.isEmpty {
                    DebugLogger.data("   Belt levels: \(Array(Set(patternsWithBelts.compactMap { $0.beltLevels.first?.shortName })).sorted())")
                }
                return
            }
        } catch {
            DebugLogger.data("Failed to check existing patterns: \(error)")
        }
        
        // Load patterns from JSON files
        loadPatternsFromJSON()
        
        DebugLogger.data("✅ Seeded initial patterns from JSON files")
    }
    
    /**
     * Loads all patterns from JSON files using PatternContentLoader
     */
    private func loadPatternsFromJSON() {
        DebugLogger.data("🌱 Loading patterns from JSON files...")
        
        let contentLoader = PatternContentLoader(patternService: self)
        
        // Use Task to handle the @MainActor requirement
        Task { @MainActor in
            contentLoader.loadAllContent()
            DebugLogger.data("✅ Completed loading patterns from JSON files")
        }
    }
    
    /**
     * Inserts a pattern into the model context
     */
    func insertPattern(_ pattern: Pattern) {
        modelContext.insert(pattern)
        
        // Insert all moves separately to ensure proper relationships
        pattern.moves.forEach { move in
            modelContext.insert(move)
        }
    }
    
    /**
     * Saves the model context
     */
    func saveContext() throws {
        try modelContext.save()
    }
    
    /**
     * Clears all patterns and reloads from JSON
     */
    func clearAndReloadPatterns() {
        // Delete all existing patterns
        do {
            try modelContext.delete(model: Pattern.self)
            try modelContext.delete(model: PatternMove.self)
            try modelContext.save()
            DebugLogger.data("🔄 Cleared all patterns from database")
            
            // Reload patterns from JSON
            let loader = PatternContentLoader(patternService: self)
            loader.loadAllContent()
            DebugLogger.data("🔄 Reloaded patterns from JSON")
            
        } catch {
            DebugLogger.data("❌ Failed to clear and reload patterns: \(error)")
        }
    }
    
    /**
     * Gets all belt levels for pattern association
     */
    func getAllBeltLevels() -> [BeltLevel] {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\BeltLevel.sortOrder, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            DebugLogger.data("❌ Failed to fetch belt levels: \(error)")
            return []
        }
    }
    
    // MARK: - Pattern content is now loaded from JSON files via PatternContentLoader
}

// MARK: - Supporting Data Structures

/**
 * User pattern learning statistics for display in UI
 */
struct PatternStatistics {
    let totalPatterns: Int
    let masteredPatterns: Int
    let totalPracticeTime: TimeInterval
    let totalSessions: Int
    let averageAccuracy: Double
    
    init(
        totalPatterns: Int = 0,
        masteredPatterns: Int = 0,
        totalPracticeTime: TimeInterval = 0,
        totalSessions: Int = 0,
        averageAccuracy: Double = 0.0
    ) {
        self.totalPatterns = totalPatterns
        self.masteredPatterns = masteredPatterns
        self.totalPracticeTime = totalPracticeTime
        self.totalSessions = totalSessions
        self.averageAccuracy = averageAccuracy
    }
    
    var masteryPercentage: Double {
        guard totalPatterns > 0 else { return 0.0 }
        return Double(masteredPatterns) / Double(totalPatterns) * 100.0
    }
    
    var averageAccuracyPercentage: Int {
        return Int(averageAccuracy * 100)
    }
    
    var formattedPracticeTime: String {
        let hours = Int(totalPracticeTime / 3600)
        let minutes = Int((totalPracticeTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}