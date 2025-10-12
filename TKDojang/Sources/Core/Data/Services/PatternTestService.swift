import Foundation
import SwiftData

/**
 * PatternTestService.swift
 * 
 * PURPOSE: Service for pattern testing functionality
 * 
 * FEATURES:
 * - Creates pattern tests from existing pattern data
 * - Generates distractor options for test questions
 * - Calculates and stores test results
 * - Delegates to PatternDataService for pattern data access
 */

@MainActor
final class PatternTestService: ObservableObject {
    
    private let patternDataService: PatternDataService
    
    init(patternDataService: PatternDataService) {
        self.patternDataService = patternDataService
    }
    
    // MARK: - Test Creation
    
    /**
     * Creates a new pattern test from existing pattern data
     * Returns nil if pattern has insufficient data for testing
     */
    func createTest(for pattern: Pattern) -> PatternTest? {
        DebugLogger.ui("🧪 Creating test for pattern: \(pattern.name) with \(pattern.moves.count) moves")
        
        // Validate pattern has required test data
        let isValid = validatePatternForTesting(pattern)
        DebugLogger.ui("🧪 Pattern validation result: \(isValid ? "valid" : "invalid")")
        
        guard isValid else {
            DebugLogger.ui("❌ Pattern \(pattern.name) failed validation - cannot create test")
            return nil
        }
        
        let test = PatternTest(pattern: pattern)
        DebugLogger.ui("🧪 Successfully created test for \(pattern.name) with \(test.moves.count) test moves")
        return test
    }
    
    /**
     * Validates pattern has sufficient data for testing
     */
    private func validatePatternForTesting(_ pattern: Pattern) -> Bool {
        let moves = pattern.orderedMoves
        DebugLogger.ui("🧪 Validating pattern \(pattern.name) with \(moves.count) ordered moves")
        
        // Must have moves
        guard !moves.isEmpty else { 
            DebugLogger.ui("❌ Pattern \(pattern.name) has no moves")
            return false 
        }
        
        // Check for required fields in moves
        var invalidMoves: [String] = []
        for move in moves {
            var issues: [String] = []
            if move.stance.isEmpty { issues.append("empty stance") }
            if move.technique.isEmpty { issues.append("empty technique") }
            if move.movement == nil { issues.append("nil movement") }
            
            if !issues.isEmpty {
                invalidMoves.append("Move \(move.moveNumber): \(issues.joined(separator: ", "))")
            }
        }
        
        if !invalidMoves.isEmpty {
            DebugLogger.ui("❌ Pattern \(pattern.name) has invalid moves:")
            for issue in invalidMoves {
                DebugLogger.ui("   - \(issue)")
            }
            return false
        }
        
        DebugLogger.ui("✅ Pattern \(pattern.name) validation successful")
        return true
    }
    
    // MARK: - Distractor Generation
    
    /**
     * Generates distractor options for a specific move and category
     * Prioritizes same-pattern options, falls back to global options
     */
    func generateDistractors(
        for move: PatternTestMove, 
        category: TestCategory, 
        fromPattern pattern: Pattern,
        count: Int = 3
    ) -> [String] {
        let correctAnswer = getCorrectAnswer(for: move, category: category)
        var distractors: [String] = []
        
        // Get options from same pattern first
        let patternOptions = getOptionsFromPattern(pattern, category: category)
        let validPatternOptions = patternOptions.filter { $0 != correctAnswer }
        
        distractors.append(contentsOf: Array(validPatternOptions.shuffled().prefix(count)))
        
        // Fill remaining slots with global options if needed
        if distractors.count < count {
            let globalOptions = getGlobalOptions(category: category)
            let validGlobalOptions = globalOptions.filter { option in
                option != correctAnswer && !distractors.contains(option)
            }
            
            let needed = count - distractors.count
            distractors.append(contentsOf: Array(validGlobalOptions.shuffled().prefix(needed)))
        }
        
        return Array(distractors.prefix(count))
    }
    
    /**
     * Gets the correct answer for a move and category
     */
    private func getCorrectAnswer(for move: PatternTestMove, category: TestCategory) -> String {
        switch category {
        case .stance: return move.correctStance
        case .technique: return move.correctTechnique
        case .movement: return move.correctMovement
        }
    }
    
    /**
     * Extracts unique options of a category from the pattern's moves
     */
    private func getOptionsFromPattern(_ pattern: Pattern, category: TestCategory) -> [String] {
        let moves = pattern.orderedMoves
        var options: Set<String> = []
        
        switch category {
        case .stance:
            options = Set(moves.map { $0.stance }.filter { !$0.isEmpty })
        case .technique:
            options = Set(moves.map { $0.technique }.filter { !$0.isEmpty })
        case .movement:
            options = Set(moves.compactMap { $0.movement }.filter { !$0.isEmpty })
        }
        
        return Array(options)
    }
    
    /**
     * Provides fallback options when pattern-specific options are insufficient
     */
    private func getGlobalOptions(category: TestCategory) -> [String] {
        switch category {
        case .stance:
            return [
                "Left walking stance", "Right walking stance",
                "Left L-stance", "Right L-stance", 
                "Parallel ready stance", "Left front stance", "Right front stance",
                "Horse riding stance", "Left back stance", "Right back stance"
            ]
        case .technique:
            return [
                "Low block", "Middle block", "High block",
                "Low punch", "Middle punch", "High punch",
                "Knife hand block", "Twin knife hand block", "Inner forearm block",
                "Front kick", "Side kick", "Turning kick",
                "X-block", "Twin forearm block"
            ]
        case .movement:
            return [
                "Forward", "-", 
                "Left 45°", "Left 90°", "Left 135°", "Left 180°", "Left 270°",
                "Right 45°", "Right 90°", "Right 135°", "Right 180°", "Right 270°"
            ]
        }
    }
    
    // MARK: - Test Submission
    
    /**
     * Processes test submission and stores results
     */
    func submitTest(
        responses: [TestResponse], 
        for pattern: Pattern, 
        userProfile: UserProfile
    ) -> TestSubmissionResult {
        let result = TestSubmissionResult(
            patternId: pattern.id,
            responses: responses
        )
        
        // Store test result using PatternDataService
        patternDataService.recordPracticeSession(
            pattern: pattern,
            userProfile: userProfile,
            accuracy: result.overallAccuracy,
            practiceTime: 0  // Test time tracking could be added in future
        )
        
        DebugLogger.ui("📊 Test completed with \(Int(result.overallAccuracy * 100))% accuracy")
        
        return result
    }
    
    // MARK: - Test History
    
    /**
     * Retrieves test/practice history for a pattern and user
     * Leverages PatternDataService for data access
     */
    func getTestHistory(
        for pattern: Pattern, 
        userProfile: UserProfile, 
        limit: Int = 10
    ) -> [PatternTestResult] {
        // Get pattern progress which includes practice session data
        _ = patternDataService.getUserProgress(for: pattern, userProfile: userProfile)
        
        // Convert practice sessions to test results
        // NOTE: This is a simplified implementation - in a full implementation,
        // we would store detailed test results with question-by-question data
        return []  // Placeholder until full test result storage is implemented
    }
    
    /**
     * Gets the most recent test/practice result for a pattern
     */
    func getLatestTestResult(
        for pattern: Pattern,
        userProfile: UserProfile
    ) -> PatternTestResult? {
        // Get pattern progress to determine if there are any test results
        let progress = patternDataService.getUserProgress(for: pattern, userProfile: userProfile)
        
        // Convert most recent practice data to a test result representation
        // NOTE: This is a simplified implementation - converts practice data to test result format
        // In a full implementation, PatternTestResult objects would be stored directly in the database
        
        if progress.practiceCount > 0 {
            // Create a test result based on the most recent practice session data
            let syntheticResult = PatternTestResult(
                patternId: pattern.id,
                overallAccuracy: progress.averageAccuracy,
                stanceAccuracy: progress.bestRunAccuracy * 0.95, // Estimate stance accuracy as slightly lower than best run
                techniqueAccuracy: progress.bestRunAccuracy, // Use best run accuracy for technique
                movementAccuracy: progress.averageAccuracy * 0.90, // Estimate movement accuracy as slightly lower than average
                userProfile: userProfile
            )
            
            return syntheticResult
        }
        
        return nil
    }
}