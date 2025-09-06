import Foundation
import SwiftData

/**
 * PatternTestModels.swift
 * 
 * PURPOSE: SwiftData models for pattern testing system
 * 
 * FEATURES:
 * - PatternTestResult: Stores overall test results with accuracy breakdown
 * - Profile isolation matching existing patterns
 * - Lightweight storage - no granular move-by-move tracking
 */

// MARK: - Pattern Test Result

/**
 * Stores results from a completed pattern test
 * Matches existing progress tracking patterns with profile isolation
 */
@Model
final class PatternTestResult {
    var id: UUID
    var patternId: UUID
    var overallAccuracy: Double
    var stanceAccuracy: Double
    var techniqueAccuracy: Double
    var movementAccuracy: Double
    var completedAt: Date
    var createdAt: Date
    var updatedAt: Date
    
    // Profile relationship for isolation
    var userProfile: UserProfile?
    
    init(
        patternId: UUID,
        overallAccuracy: Double,
        stanceAccuracy: Double,
        techniqueAccuracy: Double,
        movementAccuracy: Double,
        userProfile: UserProfile
    ) {
        self.id = UUID()
        self.patternId = patternId
        self.overallAccuracy = overallAccuracy
        self.stanceAccuracy = stanceAccuracy
        self.techniqueAccuracy = techniqueAccuracy
        self.movementAccuracy = movementAccuracy
        self.completedAt = Date()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.userProfile = userProfile
    }
}

// MARK: - Test Response Models (Non-SwiftData)

/**
 * Represents user's response to a single test question
 * Transient object - not stored in SwiftData
 */
struct TestResponse {
    let moveNumber: Int
    let selectedStance: String?
    let selectedTechnique: String?
    let selectedMovement: String?
    let correctStance: String
    let correctTechnique: String
    let correctMovement: String
    
    var isStanceCorrect: Bool {
        selectedStance == correctStance
    }
    
    var isTechniqueCorrect: Bool {
        selectedTechnique == correctTechnique
    }
    
    var isMovementCorrect: Bool {
        selectedMovement == correctMovement
    }
    
    var isCompletelyCorrect: Bool {
        isStanceCorrect && isTechniqueCorrect && isMovementCorrect
    }
}

/**
 * Represents a complete pattern test with all user responses
 * Transient object used to calculate results
 */
struct PatternTest {
    let patternId: UUID
    let patternName: String
    let moves: [PatternTestMove]
    let startedAt: Date
    
    init(pattern: Pattern) {
        self.patternId = pattern.id
        self.patternName = pattern.name
        self.moves = pattern.orderedMoves.map { PatternTestMove(from: $0) }
        self.startedAt = Date()
    }
}

/**
 * Represents a single move in the test with correct answers
 * Used for generating test questions and validating responses
 */
struct PatternTestMove {
    let moveNumber: Int
    let correctStance: String
    let correctTechnique: String
    let correctMovement: String
    let direction: String
    let target: String?
    
    init(from patternMove: PatternMove) {
        self.moveNumber = patternMove.moveNumber
        self.correctStance = patternMove.stance
        self.correctTechnique = patternMove.technique
        self.correctMovement = patternMove.movement ?? "-"
        self.direction = patternMove.direction
        self.target = patternMove.target
    }
}

/**
 * Test results calculated from user responses
 * Used to create PatternTestResult for storage
 */
struct TestSubmissionResult {
    let patternId: UUID
    let responses: [TestResponse]
    let overallAccuracy: Double
    let stanceAccuracy: Double
    let techniqueAccuracy: Double
    let movementAccuracy: Double
    let totalMoves: Int
    let completedAt: Date
    
    init(patternId: UUID, responses: [TestResponse]) {
        self.patternId = patternId
        self.responses = responses
        self.totalMoves = responses.count
        self.completedAt = Date()
        
        // Calculate accuracy percentages
        let correctStances = responses.filter { $0.isStanceCorrect }.count
        let correctTechniques = responses.filter { $0.isTechniqueCorrect }.count
        let correctMovements = responses.filter { $0.isMovementCorrect }.count
        let completelyCorrect = responses.filter { $0.isCompletelyCorrect }.count
        
        self.stanceAccuracy = totalMoves > 0 ? Double(correctStances) / Double(totalMoves) : 0.0
        self.techniqueAccuracy = totalMoves > 0 ? Double(correctTechniques) / Double(totalMoves) : 0.0
        self.movementAccuracy = totalMoves > 0 ? Double(correctMovements) / Double(totalMoves) : 0.0
        self.overallAccuracy = totalMoves > 0 ? Double(completelyCorrect) / Double(totalMoves) : 0.0
    }
}

// MARK: - Test Categories

/**
 * Categories for test questions and error tracking
 */
enum TestCategory: String, CaseIterable {
    case stance = "stance"
    case technique = "technique" 
    case movement = "movement"
    
    var displayName: String {
        switch self {
        case .stance: return "Stances"
        case .technique: return "Techniques"
        case .movement: return "Movement"
        }
    }
}