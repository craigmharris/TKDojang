import Foundation
import SwiftData

/**
 * TerminologyModels.swift
 * 
 * PURPOSE: SwiftData models for Korean terminology learning system
 * 
 * ARCHITECTURE DECISION: Using SwiftData (iOS 17+) instead of Core Data
 * WHY: Simpler syntax, better SwiftUI integration, modern approach
 * More declarative model definitions with @Model macro
 */

// MARK: - Belt Level Definition

/**
 * Represents a Taekwondo belt level in the TAGB system
 * 
 * PURPOSE: Hierarchical organization of content by skill level
 * USAGE: Filter terminology by belt requirements, track user progression
 */
@Model
final class BeltLevel {
    var id: UUID
    var name: String              // e.g., "10th Keup (White Belt)"
    var shortName: String         // e.g., "10th Keup"
    var colorName: String         // e.g., "White"
    var sortOrder: Int            // 1 = highest (1st Dan), 15 = lowest (10th Keup)
    var isKyup: Bool              // true for colored belts, false for Dan grades
    var requirements: String?     // Optional grading requirements description
    
    // Visual styling properties
    var primaryColor: String?     // Hex color for main belt color
    var secondaryColor: String?   // Hex color for secondary/tag color
    var textColor: String?        // Hex color for text on this belt
    var borderColor: String?      // Hex color for border/accent
    
    @Relationship(deleteRule: .cascade) 
    var terminologyEntries: [TerminologyEntry] = []
    
    init(name: String, shortName: String, colorName: String, sortOrder: Int, isKyup: Bool) {
        self.id = UUID()
        self.name = name
        self.shortName = shortName
        self.colorName = colorName
        self.sortOrder = sortOrder
        self.isKyup = isKyup
    }
}

// MARK: - Content Category Definition

/**
 * Categorizes terminology by type (techniques, commands, etc.)
 * 
 * PURPOSE: Allows users to focus on specific types of vocabulary
 * EXAMPLES: "Techniques", "Commands", "Numbers", "Stances", "Titles"
 */
@Model
final class TerminologyCategory {
    var id: UUID
    var name: String              // e.g., "Techniques"
    var displayName: String       // e.g., "Techniques & Movements"
    var categoryDescription: String?      // Optional category description
    var sortOrder: Int            // Display order in app
    var iconName: String?         // SF Symbol name for UI
    
    @Relationship(deleteRule: .cascade)
    var terminologyEntries: [TerminologyEntry] = []
    
    init(name: String, displayName: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.displayName = displayName
        self.sortOrder = sortOrder
    }
}

// MARK: - Terminology Entry

/**
 * Core terminology entry with all language variations
 * 
 * PURPOSE: Stores complete terminology data for flashcard learning
 * SUPPORTS: Multiple learning modes, spaced repetition, various test formats
 */
@Model
final class TerminologyEntry {
    var id: UUID
    var englishTerm: String           // e.g., "Front kick"
    var koreanHangul: String          // e.g., "앞차기"
    var romanizedPronunciation: String // e.g., "ap chagi"
    var phoneticPronunciation: String? // IPA or simplified phonetic
    var audioFileName: String?        // Future: audio file reference
    var imageFileName: String?        // Optional technique illustration
    var definition: String?           // Extended explanation if needed
    var notes: String?               // Additional learning notes
    var difficulty: Int              // 1-5 scale for content complexity
    var createdAt: Date
    var updatedAt: Date
    
    // Relationships
    @Relationship var beltLevel: BeltLevel
    @Relationship var category: TerminologyCategory
    @Relationship(deleteRule: .cascade) 
    var userProgress: [UserTerminologyProgress] = []
    
    init(englishTerm: String, koreanHangul: String, romanizedPronunciation: String, 
         beltLevel: BeltLevel, category: TerminologyCategory, difficulty: Int = 1) {
        self.id = UUID()
        self.englishTerm = englishTerm
        self.koreanHangul = koreanHangul
        self.romanizedPronunciation = romanizedPronunciation
        self.beltLevel = beltLevel
        self.category = category
        self.difficulty = difficulty
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}


/**
 * Learning mode enumeration
 */
enum LearningMode: String, CaseIterable, Codable {
    case progression = "progression"  // Focus on next belt material
    case mastery = "mastery"         // Review all material up to current belt
    
    var displayName: String {
        switch self {
        case .progression: return "Progression Focus"
        case .mastery: return "Mastery Focus"
        }
    }
    
    var description: String {
        switch self {
        case .progression: return "Learn material for your next belt level"
        case .mastery: return "Master all content up to your current level"
        }
    }
}

// MARK: - User Progress Tracking

/**
 * Tracks individual user progress on specific terminology entries
 * 
 * PURPOSE: Implements Leitner spaced repetition system
 * TRACKS: Correct/incorrect attempts, current box level, next review date
 */
@Model
final class UserTerminologyProgress {
    var id: UUID
    var terminologyEntry: TerminologyEntry
    var userProfile: UserProfile
    
    // Leitner Box System (1-5)
    var currentBox: Int = 1           // Current spaced repetition box
    var correctCount: Int = 0         // Total correct answers
    var incorrectCount: Int = 0       // Total incorrect answers
    var consecutiveCorrect: Int = 0   // Current streak of correct answers
    
    // Scheduling
    var lastReviewedAt: Date?
    var nextReviewDate: Date
    var totalReviews: Int = 0
    
    // Performance Metrics
    var averageResponseTime: Double = 0.0  // Seconds to answer
    var masteryLevel: MasteryLevel
    
    var createdAt: Date
    var updatedAt: Date
    
    init(terminologyEntry: TerminologyEntry, userProfile: UserProfile) {
        self.id = UUID()
        self.terminologyEntry = terminologyEntry
        self.userProfile = userProfile
        self.nextReviewDate = Date()  // Available immediately
        self.masteryLevel = .learning
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     * Updates progress based on user's answer correctness
     * Implements Leitner spaced repetition algorithm
     */
    func recordAnswer(isCorrect: Bool, responseTime: Double) {
        totalReviews += 1
        lastReviewedAt = Date()
        updatedAt = Date()
        
        // Update response time average
        averageResponseTime = (averageResponseTime * Double(totalReviews - 1) + responseTime) / Double(totalReviews)
        
        if isCorrect {
            correctCount += 1
            consecutiveCorrect += 1
            
            // Move to next box (max 5)
            if currentBox < 5 {
                currentBox += 1
            }
            
            // Update mastery level
            updateMasteryLevel()
            
        } else {
            incorrectCount += 1
            consecutiveCorrect = 0
            
            // Return to box 1
            currentBox = 1
            masteryLevel = .learning
        }
        
        // Calculate next review date based on current box
        nextReviewDate = calculateNextReviewDate()
    }
    
    private func updateMasteryLevel() {
        switch consecutiveCorrect {
        case 0...2: masteryLevel = .learning
        case 3...5: masteryLevel = .familiar
        case 6...9: masteryLevel = .proficient
        default: masteryLevel = .mastered
        }
    }
    
}

/**
 * Mastery level enumeration for user feedback
 */
enum MasteryLevel: String, CaseIterable, Codable {
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
}