import Foundation
import SwiftData

/**
 * PatternModels.swift
 * 
 * PURPOSE: Data models for Taekwondo patterns (Tul) system
 * 
 * FEATURES:
 * - Complete pattern definitions with educational content
 * - Individual move breakdowns with technique details
 * - Media support (video URLs for patterns, image URLs for moves)
 * - Integration with existing belt system and terminology
 * - Flexible structure for future content expansion
 */

// MARK: - Pattern Definition

/**
 * Represents a complete Taekwondo pattern (Tul)
 * Contains all information needed for learning and practicing a pattern
 */
@Model
final class Pattern {
    var id: UUID
    var name: String
    var hangul: String
    var englishMeaning: String
    var significance: String
    var moveCount: Int
    var diagramDescription: String
    var startingStance: String
    
    // Media URLs (optional - will be dummy URLs initially)
    var videoURL: String?
    var diagramImageURL: String?
    
    // Relationships
    var beltLevels: [BeltLevel] = []
    var moves: [PatternMove] = []
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        hangul: String,
        englishMeaning: String,
        significance: String,
        moveCount: Int,
        diagramDescription: String,
        startingStance: String,
        videoURL: String? = nil,
        diagramImageURL: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.hangul = hangul
        self.englishMeaning = englishMeaning
        self.significance = significance
        self.moveCount = moveCount
        self.diagramDescription = diagramDescription
        self.startingStance = startingStance
        self.videoURL = videoURL
        self.diagramImageURL = diagramImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Pattern Move

/**
 * Represents an individual move within a pattern
 * Contains detailed breakdown of technique, stance, and execution
 */
@Model
final class PatternMove {
    var id: UUID
    var moveNumber: Int
    var stance: String
    var technique: String
    var direction: String
    var target: String?
    var keyPoints: String
    var commonMistakes: String?
    var executionNotes: String?
    
    // Media URL (optional - will be dummy URL initially)
    var imageURL: String?
    
    // Relationships
    var pattern: Pattern?
    var relatedTechniquesString: String = "" // References to technique IDs for future linking
    
    // Computed property for convenience
    var relatedTechniques: [String] {
        get {
            relatedTechniquesString.isEmpty ? [] : relatedTechniquesString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            relatedTechniquesString = newValue.joined(separator: ",")
        }
    }
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        moveNumber: Int,
        stance: String,
        technique: String,
        direction: String,
        target: String? = nil,
        keyPoints: String,
        commonMistakes: String? = nil,
        executionNotes: String? = nil,
        imageURL: String? = nil
    ) {
        self.id = UUID()
        self.moveNumber = moveNumber
        self.stance = stance
        self.technique = technique
        self.direction = direction
        self.target = target
        self.keyPoints = keyPoints
        self.commonMistakes = commonMistakes
        self.executionNotes = executionNotes
        self.imageURL = imageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - User Pattern Progress

/**
 * Tracks user's progress through learning a specific pattern
 * Implements spaced repetition and mastery tracking for patterns
 */
@Model
final class UserPatternProgress {
    var id: UUID
    var userProfile: UserProfile
    var pattern: Pattern
    
    // Progress tracking
    var currentMove: Int // Which move they're currently learning (1-based)
    var masteryLevel: PatternMasteryLevel
    var practiceCount: Int
    var lastPracticedAt: Date?
    var nextReviewDate: Date
    
    // Performance metrics
    var averageAccuracy: Double // 0.0 to 1.0
    var bestRunAccuracy: Double // Best single run through the pattern
    var totalPracticeTime: TimeInterval // In seconds
    var consecutiveCorrectRuns: Int
    
    // Learning analytics (stored as strings for SwiftData compatibility)
    var strugglingMovesString: String = "" // Move numbers that need extra practice
    var masteredMovesString: String = "" // Move numbers that are fully learned
    
    // Computed properties for convenience
    var strugglingMoves: [Int] {
        get {
            strugglingMovesString.isEmpty ? [] : strugglingMovesString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            strugglingMovesString = newValue.map { String($0) }.joined(separator: ",")
        }
    }
    
    var masteredMoves: [Int] {
        get {
            masteredMovesString.isEmpty ? [] : masteredMovesString.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        }
        set {
            masteredMovesString = newValue.map { String($0) }.joined(separator: ",")
        }
    }
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(userProfile: UserProfile, pattern: Pattern) {
        self.id = UUID()
        self.userProfile = userProfile
        self.pattern = pattern
        self.currentMove = 1
        self.masteryLevel = .learning
        self.practiceCount = 0
        self.nextReviewDate = Date()
        self.averageAccuracy = 0.0
        self.bestRunAccuracy = 0.0
        self.totalPracticeTime = 0
        self.consecutiveCorrectRuns = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     * Records a practice session for this pattern
     */
    func recordPracticeSession(accuracy: Double, practiceTime: TimeInterval, strugglingMoveNumbers: [Int] = []) {
        practiceCount += 1
        lastPracticedAt = Date()
        totalPracticeTime += practiceTime
        
        // Update accuracy metrics
        averageAccuracy = ((averageAccuracy * Double(practiceCount - 1)) + accuracy) / Double(practiceCount)
        bestRunAccuracy = max(bestRunAccuracy, accuracy)
        
        // Update consecutive runs
        if accuracy >= 0.9 { // 90% or better
            consecutiveCorrectRuns += 1
        } else {
            consecutiveCorrectRuns = 0
        }
        
        // Update struggling moves
        strugglingMoves = Array(Set(strugglingMoves + strugglingMoveNumbers))
        
        // Update mastery level based on performance
        updateMasteryLevel()
        
        // Calculate next review date using spaced repetition
        updateNextReviewDate()
        
        updatedAt = Date()
    }
    
    private func updateMasteryLevel() {
        if consecutiveCorrectRuns >= 5 && averageAccuracy >= 0.95 {
            masteryLevel = .mastered
        } else if consecutiveCorrectRuns >= 3 && averageAccuracy >= 0.85 {
            masteryLevel = .proficient
        } else if practiceCount >= 3 && averageAccuracy >= 0.70 {
            masteryLevel = .familiar
        } else {
            masteryLevel = .learning
        }
    }
    
    private func updateNextReviewDate() {
        let baseInterval: TimeInterval
        
        switch masteryLevel {
        case .learning:
            baseInterval = 86400 // 1 day
        case .familiar:
            baseInterval = 259200 // 3 days
        case .proficient:
            baseInterval = 604800 // 1 week
        case .mastered:
            baseInterval = 2592000 // 1 month
        }
        
        // Adjust based on recent performance
        let performanceMultiplier = min(2.0, max(0.5, averageAccuracy * 1.5))
        let adjustedInterval = baseInterval * performanceMultiplier
        
        nextReviewDate = Date().addingTimeInterval(adjustedInterval)
    }
}

// MARK: - Enums

/**
 * Mastery levels for pattern learning progression
 */
enum PatternMasteryLevel: String, CaseIterable, Codable {
    case learning = "learning"
    case familiar = "familiar"
    case proficient = "proficient"
    case mastered = "mastered"
    
    var displayName: String {
        switch self {
        case .learning: return "Learning"
        case .familiar: return "Familiar"
        case .proficient: return "Proficient"
        case .mastered: return "Mastered"
        }
    }
    
    var color: String {
        switch self {
        case .learning: return "red"
        case .familiar: return "orange"
        case .proficient: return "blue"
        case .mastered: return "green"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .learning: return 1
        case .familiar: return 2
        case .proficient: return 3
        case .mastered: return 4
        }
    }
}

// MARK: - Extensions

extension Pattern {
    /**
     * Returns moves ordered by move number
     */
    var orderedMoves: [PatternMove] {
        return moves.sorted { $0.moveNumber < $1.moveNumber }
    }
    
    /**
     * Returns belt levels ordered by sort order
     */
    var orderedBeltLevels: [BeltLevel] {
        return beltLevels.sorted { $0.sortOrder > $1.sortOrder }
    }
    
    /**
     * Checks if this pattern is appropriate for a given belt level
     * User should see patterns for their current belt and below (higher sort_order numbers)
     * E.g., 8th Keup (sort=13) can see patterns for 9th Keup (sort=14) and 8th Keup (sort=13)
     */
    func isAppropriateFor(beltLevel: BeltLevel) -> Bool {
        return beltLevels.contains { $0.sortOrder >= beltLevel.sortOrder }
    }
    
    /**
     * Returns the primary belt level this pattern is taught at
     */
    var primaryBeltLevel: BeltLevel? {
        return beltLevels.min { $0.sortOrder > $1.sortOrder }
    }
}

extension PatternMove {
    /**
     * Formatted display of the move for UI
     */
    var displayTitle: String {
        return "\(moveNumber). \(technique)"
    }
    
    /**
     * Full description including stance and direction
     */
    var fullDescription: String {
        var description = "\(stance) - \(technique)"
        if let target = target, !target.isEmpty {
            description += " to \(target)"
        }
        description += " (\(direction))"
        return description
    }
    
    /**
     * Returns true if this move has media content available
     */
    var hasMedia: Bool {
        return imageURL != nil && !(imageURL?.isEmpty ?? true)
    }
}

extension UserPatternProgress {
    /**
     * Returns progress percentage through the pattern
     */
    var progressPercentage: Double {
        guard pattern.moveCount > 0 else { return 0.0 }
        return Double(currentMove) / Double(pattern.moveCount) * 100.0
    }
    
    /**
     * Returns true if this pattern is due for review
     */
    var isDueForReview: Bool {
        return Date() >= nextReviewDate
    }
    
    /**
     * Returns user-friendly practice statistics
     */
    var practiceStats: String {
        let accuracy = Int(averageAccuracy * 100)
        let hours = Int(totalPracticeTime / 3600)
        let minutes = Int((totalPracticeTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(practiceCount) sessions • \(accuracy)% avg • \(hours)h \(minutes)m"
        } else {
            return "\(practiceCount) sessions • \(accuracy)% avg • \(minutes)m"
        }
    }
}