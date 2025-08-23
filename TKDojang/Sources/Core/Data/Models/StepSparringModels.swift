import Foundation
import SwiftData

/**
 * StepSparringModels.swift
 * 
 * PURPOSE: Data models for Taekwondo step sparring system
 * 
 * FEATURES:
 * - Complete step sparring sequences (3-step, 2-step, 1-step, semi-free)
 * - Attack and defense combinations with detailed breakdowns  
 * - Belt-level appropriate content filtering
 * - Progress tracking similar to patterns
 * - Support for imagery and video content
 * - Semi-free sparring instruction differentiation
 */

// MARK: - Step Sparring Sequence Definition

/**
 * Represents a complete step sparring sequence
 * Contains all information needed for learning and practicing step sparring
 */
@Model
final class StepSparringSequence {
    var id: UUID
    var name: String
    var type: StepSparringType
    var sequenceNumber: Int // 1, 2, 3, etc. for ordering within belt level
    var sequenceDescription: String
    var difficulty: Int // 1-5 difficulty rating
    var keyLearningPoints: String // Educational focus areas
    
    // Media URLs (optional - for future expansion)
    var videoURL: String?
    var imageURL: String?
    
    // Relationships
    var beltLevels: [BeltLevel] = []
    var steps: [StepSparringStep] = []
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        type: StepSparringType,
        sequenceNumber: Int,
        sequenceDescription: String,
        difficulty: Int = 1,
        keyLearningPoints: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.sequenceNumber = sequenceNumber
        self.sequenceDescription = sequenceDescription
        self.difficulty = difficulty
        self.keyLearningPoints = keyLearningPoints
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     * Returns belt levels ordered by progression (highest to lowest)
     */
    var orderedBeltLevels: [BeltLevel] {
        return beltLevels.sorted { $0.sortOrder > $1.sortOrder }
    }
    
    /**
     * Checks if this sequence is appropriate for a given belt level
     * A student can practice sequences from their current belt and all previous belts they've earned
     */
    func isAvailableFor(beltLevel: BeltLevel) -> Bool {
        // A sequence is available if any of its required belt levels are at or below the user's current level
        // Lower belt = higher sortOrder, so user can see sequences requiring sortOrder >= their current sortOrder
        return beltLevels.contains { $0.sortOrder >= beltLevel.sortOrder }
    }
    
    /**
     * Gets the total number of steps in this sequence
     */
    var totalSteps: Int {
        return steps.count
    }
}

// MARK: - Individual Step Definition

/**
 * Represents a single step within a sparring sequence
 * Contains the attack and defense for that step
 */
@Model
final class StepSparringStep {
    var id: UUID
    var sequence: StepSparringSequence
    var stepNumber: Int // 1st step, 2nd step, etc.
    var attackAction: StepSparringAction
    var defenseAction: StepSparringAction
    
    // Optional counter-attack for advanced sequences
    var counterAction: StepSparringAction?
    
    // Step-specific guidance
    var timing: String // "Simultaneous", "After block", "Immediate", etc.
    var keyPoints: String // Critical technique points for this step
    var commonMistakes: String // What to watch out for
    
    // Media URLs for this specific step
    var videoURL: String?
    var imageURL: String?
    
    init(
        sequence: StepSparringSequence,
        stepNumber: Int,
        attackAction: StepSparringAction,
        defenseAction: StepSparringAction,
        timing: String = "Simultaneous",
        keyPoints: String = "",
        commonMistakes: String = ""
    ) {
        self.id = UUID()
        self.sequence = sequence
        self.stepNumber = stepNumber
        self.attackAction = attackAction
        self.defenseAction = defenseAction
        self.timing = timing
        self.keyPoints = keyPoints
        self.commonMistakes = commonMistakes
    }
}

// MARK: - Sparring Action Definition

/**
 * Represents a specific martial arts action (attack, defense, or counter)
 * Simplified for better visual display
 */
@Model  
final class StepSparringAction {
    var id: UUID
    var technique: String // "Obverse punch", "Rising block", "Front kick"
    var koreanName: String // Korean terminology
    var execution: String // Combined stance/target/hand: "Right walking stance to middle section"
    var actionDescription: String // Key execution notes
    
    init(
        technique: String,
        koreanName: String = "",
        execution: String, // e.g. "Right walking stance to middle section"
        actionDescription: String = ""
    ) {
        self.id = UUID()
        self.technique = technique
        self.koreanName = koreanName
        self.execution = execution
        self.actionDescription = actionDescription
    }
    
    // Convenience computed properties for UI display
    var displayTitle: String {
        return koreanName.isEmpty ? technique : "\(technique) (\(koreanName))"
    }
}

// MARK: - User Progress Tracking

/**
 * Tracks user progress for step sparring sequences
 * Similar to pattern progress tracking
 */
@Model
final class UserStepSparringProgress {
    var id: UUID
    var userProfile: UserProfile
    var sequence: StepSparringSequence
    var masteryLevel: StepSparringMasteryLevel
    var practiceCount: Int
    var lastPracticed: Date?
    var currentStep: Int // Which step they're currently working on
    var stepsCompleted: Int // How many steps they've mastered
    var totalPracticeTime: TimeInterval
    var notes: String // Personal notes or instructor feedback
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    
    init(userProfile: UserProfile, sequence: StepSparringSequence) {
        self.id = UUID()
        self.userProfile = userProfile
        self.sequence = sequence
        self.masteryLevel = .learning
        self.practiceCount = 0
        self.currentStep = 1
        self.stepsCompleted = 0
        self.totalPracticeTime = 0
        self.notes = ""
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     * Records practice session for this sequence
     */
    func recordPractice(duration: TimeInterval = 0, stepsCompleted: Int? = nil) {
        self.practiceCount += 1
        self.lastPracticed = Date()
        self.totalPracticeTime += duration
        self.updatedAt = Date()
        
        if let completed = stepsCompleted {
            self.stepsCompleted = max(self.stepsCompleted, completed)
            
            // Update current step (next uncompleted step)
            if completed < sequence.totalSteps {
                self.currentStep = completed + 1
            }
            
            // Update mastery level based on completion
            updateMasteryLevel()
        }
    }
    
    /**
     * Calculates progress percentage (0-100)
     */
    var progressPercentage: Double {
        guard sequence.totalSteps > 0 else { return 0 }
        return Double(stepsCompleted) / Double(sequence.totalSteps) * 100.0
    }
    
    /**
     * Updates mastery level based on progress and practice
     */
    private func updateMasteryLevel() {
        let completionRate = progressPercentage / 100.0
        
        switch (completionRate, practiceCount) {
        case (1.0, let count) where count >= 10:
            masteryLevel = .mastered
        case (1.0, let count) where count >= 5:
            masteryLevel = .proficient
        case (let rate, _) where rate >= 0.8:
            masteryLevel = .familiar
        default:
            masteryLevel = .learning
        }
    }
}

// MARK: - Configuration Enums

/**
 * Types of step sparring practice
 */
enum StepSparringType: String, CaseIterable, Codable {
    case threeStep = "three_step"
    case twoStep = "two_step" 
    case oneStep = "one_step"
    case semiFree = "semi_free"
    
    var displayName: String {
        switch self {
        case .threeStep: return "3-Step Sparring"
        case .twoStep: return "2-Step Sparring"
        case .oneStep: return "1-Step Sparring"
        case .semiFree: return "Semi-Free Sparring"
        }
    }
    
    var shortName: String {
        switch self {
        case .threeStep: return "3-Step"
        case .twoStep: return "2-Step"
        case .oneStep: return "1-Step"
        case .semiFree: return "Semi-Free"
        }
    }
    
    var description: String {
        switch self {
        case .threeStep: return "Three predetermined attacks followed by defense and counter"
        case .twoStep: return "Two predetermined attacks with defense and counter combinations"
        case .oneStep: return "Single attack with immediate defense and counter"
        case .semiFree: return "Guided sparring with flexible attack and defense patterns"
        }
    }
    
    var stepCount: Int {
        switch self {
        case .threeStep: return 3
        case .twoStep: return 2
        case .oneStep: return 1
        case .semiFree: return 1 // Variable, but default to 1 for UI purposes
        }
    }
    
    var icon: String {
        switch self {
        case .threeStep: return "3.circle.fill"
        case .twoStep: return "2.circle.fill"
        case .oneStep: return "1.circle.fill"
        case .semiFree: return "figure.2.arms.open"
        }
    }
    
    var color: String {
        switch self {
        case .threeStep: return "blue"
        case .twoStep: return "green"
        case .oneStep: return "orange"
        case .semiFree: return "purple"
        }
    }
}

/**
 * Mastery levels for step sparring progress
 */
enum StepSparringMasteryLevel: String, CaseIterable, Codable {
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
    
    var icon: String {
        switch self {
        case .learning: return "circle.fill"
        case .familiar: return "circle.lefthalf.filled"
        case .proficient: return "checkmark.circle"
        case .mastered: return "checkmark.circle.fill"
        }
    }
}

/**
 * Session types for step sparring practice
 */
enum StepSparringSessionType: String, CaseIterable, Codable {
    case individual = "individual"
    case partner = "partner"
    case review = "review"
    case assessment = "assessment"
    
    var displayName: String {
        switch self {
        case .individual: return "Individual Practice"
        case .partner: return "Partner Practice"
        case .review: return "Review Session"
        case .assessment: return "Skills Assessment"
        }
    }
}