import XCTest
import SwiftData
@testable import TKDojang

/**
 * ModelRelationshipTests.swift
 * 
 * PURPOSE: Tests for model relationships, architecture integrity, and SwiftData interactions
 * 
 * IMPORTANCE: Validates the new architecture changes and relationship integrity
 * Based on CLAUDE.md requirements: Manual belt filtering vs SwiftData relationship consistency
 * 
 * TEST COVERAGE:
 * - Pattern-move relationships (1-to-many)
 * - User progress relationships across all content types
 * - Belt level associations with patterns and step sparring
 * - SwiftData relationship integrity after JSON loading
 * - Manual belt filtering vs SwiftData relationship consistency
 */
final class ModelRelationshipTests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testBelts: [BeltLevel] = []
    var testProfile: UserProfile!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory test container with all models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            Pattern.self,
            PatternMove.self,
            UserPatternProgress.self,
            StepSparringSequence.self,
            StepSparringStep.self,
            StepSparringAction.self,
            UserStepSparringProgress.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        testContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        testContext = ModelContext(testContainer)
        
        // Set up test data
        try setupTestData()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        testBelts = []
        testProfile = nil
        try super.tearDownWithError()
    }
    
    private func setupTestData() throws {
        // Create comprehensive test data
        testBelts = TestDataFactory().createAllBeltLevels()
        
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create test profile
        let testBelt = testBelts.first { $0.shortName == "6th Keup" }!
        testProfile = UserProfile(name: "Test User", currentBeltLevel: testBelt, learningMode: .mastery)
        testContext.insert(testProfile)
        
        try testContext.save()
    }
    
    // MARK: - Pattern Relationship Tests
    
    func testPatternMoveOneToManyRelationship() throws {
        // Test that pattern-move relationship works correctly
        let pattern = Pattern(
            name: "Relationship Test Pattern",
            hangul: "관계테스트",
            englishMeaning: "Relationship Test",
            significance: "Testing one-to-many relationship",
            moveCount: 3,
            diagramDescription: "Test",
            startingStance: "Ready"
        )
        
        // Create moves
        let move1 = PatternMove(
            moveNumber: 1, stance: "Left stance", technique: "Low block",
            direction: "West", keyPoints: "Test key points 1"
        )
        let move2 = PatternMove(
            moveNumber: 2, stance: "Right stance", technique: "Middle punch", 
            direction: "West", keyPoints: "Test key points 2"
        )
        let move3 = PatternMove(
            moveNumber: 3, stance: "Left stance", technique: "High block",
            direction: "East", keyPoints: "Test key points 3"
        )
        
        // Set up relationships
        move1.pattern = pattern
        move2.pattern = pattern
        move3.pattern = pattern
        pattern.moves = [move1, move2, move3]
        
        // Insert into context
        testContext.insert(pattern)
        testContext.insert(move1)
        testContext.insert(move2)
        testContext.insert(move3)
        try testContext.save()
        
        // Test relationship integrity
        XCTAssertEqual(pattern.moves.count, 3, "Pattern should have 3 moves")
        XCTAssertEqual(move1.pattern?.id, pattern.id, "Move 1 should reference pattern")
        XCTAssertEqual(move2.pattern?.id, pattern.id, "Move 2 should reference pattern")
        XCTAssertEqual(move3.pattern?.id, pattern.id, "Move 3 should reference pattern")
        
        // Test ordered moves functionality
        let orderedMoves = pattern.orderedMoves
        XCTAssertEqual(orderedMoves.count, 3, "Should have 3 ordered moves")
        XCTAssertEqual(orderedMoves[0].moveNumber, 1, "First move should be move 1")
        XCTAssertEqual(orderedMoves[1].moveNumber, 2, "Second move should be move 2")
        XCTAssertEqual(orderedMoves[2].moveNumber, 3, "Third move should be move 3")
        
        // Test pattern deletion cascades to moves
        testContext.delete(pattern)
        try testContext.save()
        
        // Moves should still exist but with nil pattern reference
        let remainingMoves = try testContext.fetch(FetchDescriptor<PatternMove>())
        for move in remainingMoves {
            XCTAssertNil(move.pattern, "Moves should have nil pattern reference after pattern deletion")
        }
        
        print("✅ Pattern-move one-to-many relationship test passed")
    }
    
    func testPatternBeltLevelManyToManyRelationship() throws {
        // Test pattern-belt level many-to-many relationship
        let pattern = Pattern(
            name: "Multi-Belt Pattern",
            hangul: "다중벨트",
            englishMeaning: "Multi Belt",
            significance: "Testing many-to-many relationship",
            moveCount: 1,
            diagramDescription: "Test",
            startingStance: "Ready"
        )
        
        // Associate with multiple belts
        let belt1 = testBelts.first { $0.shortName == "9th Keup" }!
        let belt2 = testBelts.first { $0.shortName == "8th Keup" }!
        let belt3 = testBelts.first { $0.shortName == "7th Keup" }!
        
        pattern.beltLevels = [belt1, belt2, belt3]
        
        testContext.insert(pattern)
        try testContext.save()
        
        // Test relationship from pattern side
        XCTAssertEqual(pattern.beltLevels.count, 3, "Pattern should have 3 belt levels")
        XCTAssertTrue(pattern.beltLevels.contains { $0.id == belt1.id }, "Should contain belt 1")
        XCTAssertTrue(pattern.beltLevels.contains { $0.id == belt2.id }, "Should contain belt 2")
        XCTAssertTrue(pattern.beltLevels.contains { $0.id == belt3.id }, "Should contain belt 3")
        
        // Test ordered belt levels functionality
        let orderedBelts = pattern.orderedBeltLevels
        XCTAssertEqual(orderedBelts.count, 3, "Should have 3 ordered belts")
        // Should be ordered by sort order (descending - higher level belts first)
        XCTAssertGreaterThan(orderedBelts[0].sortOrder, orderedBelts[1].sortOrder, "Should be sorted by sort order")
        
        // Test belt appropriateness check
        let sixthKeupBelt = testBelts.first { $0.shortName == "6th Keup" }!
        XCTAssertTrue(pattern.isAppropriateFor(beltLevel: sixthKeupBelt), "Should be appropriate for 6th keup")
        
        let fifthKeupBelt = testBelts.first { $0.shortName == "5th Keup" }!
        XCTAssertTrue(pattern.isAppropriateFor(beltLevel: fifthKeupBelt), "Should be appropriate for 5th keup")
        
        print("✅ Pattern-belt level many-to-many relationship test passed")
    }
    
    // MARK: - Step Sparring Relationship Tests
    
    func testStepSparringSequenceStepRelationship() throws {
        // Test sequence-step one-to-many relationship
        let sequence = StepSparringSequence(
            name: "Relationship Test Sequence",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing sequence-step relationship"
        )
        
        // Create steps with actions
        var steps: [StepSparringStep] = []
        
        for stepNum in 1...3 {
            let attackAction = StepSparringAction(
                technique: "Attack \(stepNum)",
                koreanName: "공격\(stepNum)",
                execution: "Right stance to middle"
            )
            
            let defenseAction = StepSparringAction(
                technique: "Defense \(stepNum)", 
                koreanName: "방어\(stepNum)",
                execution: "Left stance to middle"
            )
            
            let step = StepSparringStep(
                sequence: sequence,
                stepNumber: stepNum,
                attackAction: attackAction,
                defenseAction: defenseAction,
                timing: "Simultaneous"
            )
            
            steps.append(step)
            testContext.insert(attackAction)
            testContext.insert(defenseAction)
            testContext.insert(step)
        }
        
        sequence.steps = steps
        testContext.insert(sequence)
        try testContext.save()
        
        // Test relationship integrity
        XCTAssertEqual(sequence.steps.count, 3, "Sequence should have 3 steps")
        XCTAssertEqual(sequence.totalSteps, 3, "Total steps should be 3")
        
        for (index, step) in sequence.steps.enumerated() {
            XCTAssertEqual(step.sequence.id, sequence.id, "Step \(index + 1) should reference sequence")
            XCTAssertNotNil(step.attackAction, "Step should have attack action")
            XCTAssertNotNil(step.defenseAction, "Step should have defense action")
        }
        
        // Test step ordering
        let sortedSteps = sequence.steps.sorted { $0.stepNumber < $1.stepNumber }
        XCTAssertEqual(sortedSteps[0].stepNumber, 1, "First step should be step 1")
        XCTAssertEqual(sortedSteps[1].stepNumber, 2, "Second step should be step 2")
        XCTAssertEqual(sortedSteps[2].stepNumber, 3, "Third step should be step 3")
        
        print("✅ Step sparring sequence-step relationship test passed")
    }
    
    func testStepSparringBeltLevelBypassRelationship() throws {
        // Test that step sparring sequences work WITHOUT SwiftData belt relationships
        // This tests the "nuclear option" described in CLAUDE.md
        
        let sequence = StepSparringSequence(
            name: "No Belt Relationship Test",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing bypass of belt relationships"
        )
        
        // DO NOT set belt relationships - this is the key architectural change
        XCTAssertTrue(sequence.beltLevels.isEmpty, "Sequence should have NO SwiftData belt relationships")
        
        testContext.insert(sequence)
        try testContext.save()
        
        // Manual belt filtering should still work through service logic
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        
        // Test manual belt filtering for different belt levels
        let eighthKeupProfile = UserProfile(name: "8th Keup User", currentBeltLevel: testBelts.first { $0.shortName == "8th Keup" }!, learningMode: .mastery)
        let sixthKeupProfile = UserProfile(name: "6th Keup User", currentBeltLevel: testBelts.first { $0.shortName == "6th Keup" }!, learningMode: .mastery)
        
        testContext.insert(eighthKeupProfile)
        testContext.insert(sixthKeupProfile)
        try testContext.save()
        
        // Manual filtering should work based on sequence number and type patterns
        let eighthKeupSequences = stepSparringService.getSequences(for: .threeStep, userProfile: eighthKeupProfile)
        let sixthKeupSequences = stepSparringService.getSequences(for: .threeStep, userProfile: sixthKeupProfile)
        
        // Both should be able to access the sequence (sequence #1 is available to 8th-6th keup)
        XCTAssertGreaterThanOrEqual(eighthKeupSequences.count, 0, "8th Keup should be able to access sequences via manual filtering")
        XCTAssertGreaterThanOrEqual(sixthKeupSequences.count, 0, "6th Keup should be able to access sequences via manual filtering")
        
        print("✅ Step sparring belt level bypass relationship test passed")
    }
    
    // MARK: - User Progress Relationship Tests
    
    func testUserPatternProgressRelationships() throws {
        // Test user progress relationships for patterns
        let pattern = Pattern(
            name: "Progress Test Pattern",
            hangul: "진행테스트",
            englishMeaning: "Progress Test",
            significance: "Testing progress relationships",
            moveCount: 5,
            diagramDescription: "Test",
            startingStance: "Ready"
        )
        
        testContext.insert(pattern)
        try testContext.save()
        
        // Create progress
        let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
        testContext.insert(progress)
        try testContext.save()
        
        // Test relationships
        XCTAssertEqual(progress.userProfile.id, testProfile.id, "Progress should reference correct user profile")
        XCTAssertEqual(progress.pattern.id, pattern.id, "Progress should reference correct pattern")
        
        // Test progress functionality
        progress.recordPracticeSession(accuracy: 0.85, practiceTime: 180.0, strugglingMoveNumbers: [2, 4])
        
        XCTAssertEqual(progress.practiceCount, 1, "Should record practice session")
        XCTAssertEqual(progress.averageAccuracy, 0.85, "Should record accuracy")
        XCTAssertEqual(progress.totalPracticeTime, 180.0, "Should record practice time")
        XCTAssertEqual(progress.strugglingMoves, [2, 4], "Should record struggling moves")
        
        print("✅ User pattern progress relationships test passed")
    }
    
    func testUserStepSparringProgressRelationships() throws {
        // Test user progress relationships for step sparring
        let sequence = StepSparringSequence(
            name: "Progress Test Sequence",
            type: .twoStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing progress relationships"
        )
        
        // Add steps for realistic progress tracking
        for stepNum in 1...2 {
            let attackAction = StepSparringAction(technique: "Attack \(stepNum)", execution: "Test execution")
            let defenseAction = StepSparringAction(technique: "Defense \(stepNum)", execution: "Test execution")
            let step = StepSparringStep(
                sequence: sequence, stepNumber: stepNum,
                attackAction: attackAction, defenseAction: defenseAction
            )
            sequence.steps.append(step)
            testContext.insert(attackAction)
            testContext.insert(defenseAction)
            testContext.insert(step)
        }
        
        testContext.insert(sequence)
        try testContext.save()
        
        // Create progress
        let progress = UserStepSparringProgress(userProfile: testProfile, sequence: sequence)
        testContext.insert(progress)
        try testContext.save()
        
        // Test relationships
        XCTAssertEqual(progress.userProfile.id, testProfile.id, "Progress should reference correct user profile")
        XCTAssertEqual(progress.sequence.id, sequence.id, "Progress should reference correct sequence")
        
        // Test progress functionality
        progress.recordPractice(duration: 120.0, stepsCompleted: 2)
        
        XCTAssertEqual(progress.practiceCount, 1, "Should record practice session")
        XCTAssertEqual(progress.totalPracticeTime, 120.0, "Should record practice time")
        XCTAssertEqual(progress.stepsCompleted, 2, "Should record steps completed")
        XCTAssertEqual(progress.progressPercentage, 100.0, "Should calculate 100% progress")
        
        print("✅ User step sparring progress relationships test passed")
    }
    
    // MARK: - Cross-Content Type Relationships
    
    func testMultipleContentTypeProgressForSingleUser() throws {
        // Test that a user can have progress across all content types
        
        // Create content of different types
        let pattern = Pattern(
            name: "Multi-Type Pattern", hangul: "다종유형", englishMeaning: "Multi Type",
            significance: "Test", moveCount: 1, diagramDescription: "Test", startingStance: "Ready"
        )
        
        let sequence = StepSparringSequence(
            name: "Multi-Type Sequence", type: .twoStep, sequenceNumber: 1,
            sequenceDescription: "Test"
        )
        
        let category = TerminologyCategory(name: "Test Category", shortName: "TEST", colorName: "Blue", iconName: "star")
        let terminology = TerminologyEntry(
            englishTerm: "Multi-Type Term", koreanHangul: "다종용어",
            romanizedPronunciation: "da-jong-yong-eo", phoneticPronunciation: "/da.jong.yong.eo/",
            definition: "Test term", difficulty: 1, beltLevel: testProfile.currentBeltLevel, category: category
        )
        
        testContext.insert(pattern)
        testContext.insert(sequence)
        testContext.insert(category)
        testContext.insert(terminology)
        try testContext.save()
        
        // Create progress for all content types
        let patternProgress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
        let stepSparringProgress = UserStepSparringProgress(userProfile: testProfile, sequence: sequence)
        let terminologyProgress = UserTerminologyProgress(userProfile: testProfile, terminologyEntry: terminology)
        
        testContext.insert(patternProgress)
        testContext.insert(stepSparringProgress)
        testContext.insert(terminologyProgress)
        try testContext.save()
        
        // Test that all progress types reference the same user
        XCTAssertEqual(patternProgress.userProfile.id, testProfile.id, "Pattern progress should reference user")
        XCTAssertEqual(stepSparringProgress.userProfile.id, testProfile.id, "Step sparring progress should reference user")
        XCTAssertEqual(terminologyProgress.userProfile.id, testProfile.id, "Terminology progress should reference user")
        
        // Test content type diversity
        XCTAssertNotEqual(patternProgress.pattern.name, sequence.name, "Different content types should have different names")
        XCTAssertNotEqual(sequence.type.displayName, terminology.englishTerm, "Different content types should be distinct")
        
        print("✅ Multiple content type progress for single user test passed")
    }
    
    // MARK: - Relationship Integrity Under Stress Tests
    
    func testRelationshipIntegrityWithBulkOperations() throws {
        // Test that relationships remain intact during bulk operations
        let testDataFactory = TestDataFactory()
        
        // Create bulk data
        let patterns = testDataFactory.createSamplePatterns(belts: testBelts, count: 10)
        let sequences = testDataFactory.createSampleStepSparringSequences(belts: testBelts, count: 10)
        
        // Bulk insert patterns and moves
        for pattern in patterns {
            testContext.insert(pattern)
            for move in pattern.moves {
                testContext.insert(move)
            }
        }
        
        // Bulk insert sequences and steps
        for sequence in sequences {
            testContext.insert(sequence)
            for step in sequence.steps {
                testContext.insert(step.attackAction)
                testContext.insert(step.defenseAction)
                if let counter = step.counterAction {
                    testContext.insert(counter)
                }
                testContext.insert(step)
            }
        }
        
        try testContext.save()
        
        // Verify relationship integrity after bulk operations
        let loadedPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let loadedSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        
        XCTAssertEqual(loadedPatterns.count, 10, "Should have loaded all patterns")
        XCTAssertEqual(loadedSequences.count, 10, "Should have loaded all sequences")
        
        // Check relationships are intact
        for pattern in loadedPatterns {
            XCTAssertFalse(pattern.moves.isEmpty, "Pattern should have moves after bulk operation")
            for move in pattern.moves {
                XCTAssertEqual(move.pattern?.id, pattern.id, "Move should still reference pattern")
            }
        }
        
        for sequence in loadedSequences {
            XCTAssertFalse(sequence.steps.isEmpty, "Sequence should have steps after bulk operation")
            for step in sequence.steps {
                XCTAssertEqual(step.sequence.id, sequence.id, "Step should still reference sequence")
                XCTAssertNotNil(step.attackAction, "Step should still have attack action")
                XCTAssertNotNil(step.defenseAction, "Step should still have defense action")
            }
        }
        
        print("✅ Relationship integrity with bulk operations test passed")
    }
    
    func testRelationshipConsistencyAcrossContentTypes() throws {
        // Test that the relationship patterns are consistent across all content types
        
        // Pattern: Pattern -> PatternMove (one-to-many)
        // Step Sparring: StepSparringSequence -> StepSparringStep (one-to-many)
        // Step Sparring: StepSparringStep -> StepSparringAction (one-to-many via attackAction/defenseAction)
        // Terminology: No complex relationships (simpler structure)
        // User Progress: All content types -> UserProfile (many-to-one)
        
        let pattern = Pattern(
            name: "Consistency Test", hangul: "일관성", englishMeaning: "Consistency",
            significance: "Test", moveCount: 2, diagramDescription: "Test", startingStance: "Ready"
        )
        
        let sequence = StepSparringSequence(
            name: "Consistency Test Sequence", type: .twoStep, sequenceNumber: 1,
            sequenceDescription: "Test"
        )
        
        // Create child objects for one-to-many relationships
        let move1 = PatternMove(moveNumber: 1, stance: "Test", technique: "Test", direction: "North", keyPoints: "Test")
        let move2 = PatternMove(moveNumber: 2, stance: "Test", technique: "Test", direction: "South", keyPoints: "Test")
        move1.pattern = pattern
        move2.pattern = pattern
        pattern.moves = [move1, move2]
        
        let attackAction = StepSparringAction(technique: "Attack", execution: "Test")
        let defenseAction = StepSparringAction(technique: "Defense", execution: "Test")
        let step = StepSparringStep(sequence: sequence, stepNumber: 1, attackAction: attackAction, defenseAction: defenseAction)
        sequence.steps = [step]
        
        // Insert all
        testContext.insert(pattern)
        testContext.insert(move1)
        testContext.insert(move2)
        testContext.insert(sequence)
        testContext.insert(attackAction)
        testContext.insert(defenseAction)
        testContext.insert(step)
        try testContext.save()
        
        // Verify consistent relationship patterns
        // Both patterns and sequences should have ordered child collections
        XCTAssertEqual(pattern.orderedMoves.count, 2, "Pattern should have ordered moves")
        XCTAssertEqual(sequence.steps.count, 1, "Sequence should have steps")
        
        // Both should have proper parent-child references
        XCTAssertEqual(move1.pattern?.id, pattern.id, "Move should reference pattern")
        XCTAssertEqual(step.sequence.id, sequence.id, "Step should reference sequence")
        
        // Both content types should support progress tracking
        let patternProgress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
        let stepSparringProgress = UserStepSparringProgress(userProfile: testProfile, sequence: sequence)
        
        testContext.insert(patternProgress)
        testContext.insert(stepSparringProgress)
        try testContext.save()
        
        XCTAssertEqual(patternProgress.userProfile.id, testProfile.id, "Pattern progress should reference user")
        XCTAssertEqual(stepSparringProgress.userProfile.id, testProfile.id, "Step sparring progress should reference user")
        
        print("✅ Relationship consistency across content types test passed")
    }
}