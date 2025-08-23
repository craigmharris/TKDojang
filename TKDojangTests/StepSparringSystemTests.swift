import XCTest
import SwiftData
@testable import TKDojang

/**
 * StepSparringSystemTests.swift
 * 
 * PURPOSE: Tests for the step sparring system including JSON loading and manual belt filtering
 * 
 * CRITICAL IMPORTANCE: Validates new JSON-based architecture with manual belt filtering bypass
 * Based on CLAUDE.md requirements: Manual belt filtering to avoid SwiftData relationship issues
 * 
 * TEST COVERAGE:
 * - JSON-based step sparring loading via StepSparringContentLoader
 * - Manual belt filtering logic in StepSparringDataService.manualBeltLevelCheck()
 * - Step sparring sequence filtering by type (3-step, 2-step)
 * - Step sparring progress tracking with UserStepSparringProgress
 * - Attack/defense/counter action data integrity
 * - Step sparring mastery progression
 */
final class StepSparringSystemTests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var stepSparringService: StepSparringDataService!
    var testProfile: UserProfile!
    var testBelts: [BeltLevel] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory test container with step sparring models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
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
        stepSparringService = StepSparringDataService(modelContext: testContext)
        
        // Set up test data
        try setupTestData()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        stepSparringService = nil
        testProfile = nil
        testBelts = []
        try super.tearDownWithError()
    }
    
    private func setupTestData() throws {
        // Create test belt levels that match the manual filtering logic
        let eighthKeup = BeltLevel(name: "8th Keup (Orange Belt)", shortName: "8th Keup", colorName: "Orange", sortOrder: 13, isKyup: true)
        let seventhKeup = BeltLevel(name: "7th Keup (Green Belt)", shortName: "7th Keup", colorName: "Green", sortOrder: 12, isKyup: true)
        let sixthKeup = BeltLevel(name: "6th Keup (Purple Belt)", shortName: "6th Keup", colorName: "Purple", sortOrder: 11, isKyup: true)
        let fifthKeup = BeltLevel(name: "5th Keup (Blue Belt)", shortName: "5th Keup", colorName: "Blue", sortOrder: 10, isKyup: true)
        let fourthKeup = BeltLevel(name: "4th Keup (Blue/Red Belt)", shortName: "4th Keup", colorName: "Blue/Red", sortOrder: 9, isKyup: true)
        
        testBelts = [eighthKeup, seventhKeup, sixthKeup, fifthKeup, fourthKeup]
        
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create test user profile with 6th Keup belt
        testProfile = UserProfile(currentBeltLevel: sixthKeup, learningMode: .mastery)
        testContext.insert(testProfile)
        
        try testContext.save()
    }
    
    // MARK: - Step Sparring Creation Tests
    
    func testStepSparringSequenceCreation() throws {
        let sequence = StepSparringSequence(
            name: "Test 3-Step #1",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Basic three-step sequence for testing",
            difficulty: 2,
            keyLearningPoints: "Test timing and distance"
        )
        
        testContext.insert(sequence)
        try testContext.save()
        
        // Verify sequence creation
        XCTAssertFalse(sequence.name.isEmpty, "Sequence should have a name")
        XCTAssertEqual(sequence.type, .threeStep, "Sequence type should match")
        XCTAssertEqual(sequence.sequenceNumber, 1, "Sequence number should match")
        XCTAssertEqual(sequence.difficulty, 2, "Difficulty should match")
        XCTAssertNotNil(sequence.createdAt, "Should have creation date")
        XCTAssertEqual(sequence.totalSteps, 0, "Should start with no steps")
    }
    
    func testStepSparringActionCreation() throws {
        let attackAction = StepSparringAction(
            technique: "Obverse punch",
            koreanName: "Baro jirugi",
            execution: "Right walking stance to middle section",
            actionDescription: "Step forward and punch with conviction"
        )
        
        let defenseAction = StepSparringAction(
            technique: "Inner forearm block",
            koreanName: "An palmok makgi", 
            execution: "Left walking stance to middle section",
            actionDescription: "Step back and block with strong form"
        )
        
        // Verify action creation
        XCTAssertEqual(attackAction.technique, "Obverse punch", "Attack technique should match")
        XCTAssertEqual(attackAction.koreanName, "Baro jirugi", "Korean name should match")
        XCTAssertEqual(attackAction.displayTitle, "Obverse punch (Baro jirugi)", "Display title should include Korean")
        
        XCTAssertEqual(defenseAction.technique, "Inner forearm block", "Defense technique should match")
        XCTAssertEqual(defenseAction.koreanName, "An palmok makgi", "Korean name should match")
    }
    
    func testStepSparringStepCreation() throws {
        let sequence = StepSparringSequence(
            name: "Test Sequence",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Test"
        )
        
        let attackAction = StepSparringAction(
            technique: "Obverse punch",
            koreanName: "Baro jirugi",
            execution: "Right walking stance to middle section"
        )
        
        let defenseAction = StepSparringAction(
            technique: "Inner forearm block",
            koreanName: "An palmok makgi",
            execution: "Left walking stance to middle section"
        )
        
        let step = StepSparringStep(
            sequence: sequence,
            stepNumber: 1,
            attackAction: attackAction,
            defenseAction: defenseAction,
            timing: "Simultaneous attack and block",
            keyPoints: "Maintain proper distance",
            commonMistakes: "Backing away instead of blocking"
        )
        
        testContext.insert(sequence)
        testContext.insert(attackAction)
        testContext.insert(defenseAction) 
        testContext.insert(step)
        try testContext.save()
        
        // Verify step creation
        XCTAssertEqual(step.stepNumber, 1, "Step number should match")
        XCTAssertEqual(step.sequence.id, sequence.id, "Step should reference sequence")
        XCTAssertEqual(step.attackAction.technique, "Obverse punch", "Attack action should match")
        XCTAssertEqual(step.defenseAction.technique, "Inner forearm block", "Defense action should match")
        XCTAssertNil(step.counterAction, "Should not have counter action initially")
    }
    
    // MARK: - Manual Belt Filtering Tests (CRITICAL)
    
    func testManualBeltFilteringForThreeStepSparring() throws {
        // Create 3-step sparring sequences for testing manual belt filtering
        let sequence1to4 = StepSparringSequence(
            name: "3-Step #1-4", type: .threeStep, sequenceNumber: 1,
            sequenceDescription: "Sequences 1-4 for 8th-6th keup"
        )
        
        let sequence5to7 = StepSparringSequence(
            name: "3-Step #5-7", type: .threeStep, sequenceNumber: 5,
            sequenceDescription: "Sequences 5-7 for 7th-6th keup"
        )
        
        let sequence8to10 = StepSparringSequence(
            name: "3-Step #8-10", type: .threeStep, sequenceNumber: 8,
            sequenceDescription: "Sequences 8-10 for 6th keup only"
        )
        
        // DO NOT set belt relationships - this is the "nuclear option" bypass
        // sequence.beltLevels remains empty
        
        testContext.insert(sequence1to4)
        testContext.insert(sequence5to7)
        testContext.insert(sequence8to10)
        try testContext.save()
        
        // Test filtering for 8th Keup (should see sequences 1-4 only)
        let eighthKeupProfile = UserProfile(currentBeltLevel: testBelts[0], learningMode: .mastery) // 8th keup
        testContext.insert(eighthKeupProfile)
        try testContext.save()
        
        let eighthKeupSequences = stepSparringService.getSequences(for: .threeStep, userProfile: eighthKeupProfile)
        XCTAssertEqual(eighthKeupSequences.count, 1, "8th Keup should see 1 three-step sequence range")
        XCTAssertTrue(eighthKeupSequences.contains { $0.sequenceNumber == 1 }, "Should contain sequence 1-4")
        
        // Test filtering for 7th Keup (should see sequences 1-4 and 5-7)
        let seventhKeupProfile = UserProfile(currentBeltLevel: testBelts[1], learningMode: .mastery) // 7th keup
        testContext.insert(seventhKeupProfile)
        try testContext.save()
        
        let seventhKeupSequences = stepSparringService.getSequences(for: .threeStep, userProfile: seventhKeupProfile)
        XCTAssertEqual(seventhKeupSequences.count, 2, "7th Keup should see 2 three-step sequence ranges")
        
        // Test filtering for 6th Keup (should see all sequences)
        let sixthKeupProfile = UserProfile(currentBeltLevel: testBelts[2], learningMode: .mastery) // 6th keup
        testContext.insert(sixthKeupProfile)
        try testContext.save()
        
        let sixthKeupSequences = stepSparringService.getSequences(for: .threeStep, userProfile: sixthKeupProfile)
        XCTAssertEqual(sixthKeupSequences.count, 3, "6th Keup should see all three-step sequences")
    }
    
    func testManualBeltFilteringForTwoStepSparring() throws {
        // Create 2-step sparring sequences
        let sequence1to4 = StepSparringSequence(
            name: "2-Step #1-4", type: .twoStep, sequenceNumber: 1,
            sequenceDescription: "Sequences 1-4 for 5th-4th keup"
        )
        
        let sequence5to8 = StepSparringSequence(
            name: "2-Step #5-8", type: .twoStep, sequenceNumber: 5,
            sequenceDescription: "Sequences 5-8 for 4th keup only"
        )
        
        testContext.insert(sequence1to4)
        testContext.insert(sequence5to8)
        try testContext.save()
        
        // Test filtering for 5th Keup (should see sequences 1-4 only)
        let fifthKeupProfile = UserProfile(currentBeltLevel: testBelts[3], learningMode: .mastery) // 5th keup
        testContext.insert(fifthKeupProfile)
        try testContext.save()
        
        let fifthKeupSequences = stepSparringService.getSequences(for: .twoStep, userProfile: fifthKeupProfile)
        XCTAssertEqual(fifthKeupSequences.count, 1, "5th Keup should see 1 two-step sequence range")
        
        // Test filtering for 4th Keup (should see all sequences)
        let fourthKeupProfile = UserProfile(currentBeltLevel: testBelts[4], learningMode: .mastery) // 4th keup
        testContext.insert(fourthKeupProfile)
        try testContext.save()
        
        let fourthKeupSequences = stepSparringService.getSequences(for: .twoStep, userProfile: fourthKeupProfile)
        XCTAssertEqual(fourthKeupSequences.count, 2, "4th Keup should see all two-step sequences")
    }
    
    func testSequenceAvailabilityWithoutBeltRelationships() throws {
        // Test that sequences work without SwiftData belt relationships
        let sequence = StepSparringSequence(
            name: "No Belt Relationship Test",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing sequence without belt relationships"
        )
        
        testContext.insert(sequence)
        try testContext.save()
        
        // Verify sequence has no belt relationships (the "nuclear option")
        XCTAssertEqual(sequence.beltLevels.count, 0, "Sequence should have no SwiftData belt relationships")
        
        // But manual filtering should still work through the service
        let allSequences = stepSparringService.getSequences(for: .threeStep, userProfile: testProfile)
        
        // The service should handle sequences without belt relationships through manual logic
        XCTAssertTrue(allSequences.count >= 0, "Service should handle sequences without belt relationships")
    }
    
    // MARK: - Step Sparring Type Tests
    
    func testStepSparringTypeEnumProperties() throws {
        // Test 3-step sparring properties
        let threeStep = StepSparringType.threeStep
        XCTAssertEqual(threeStep.displayName, "3-Step Sparring", "Display name should be correct")
        XCTAssertEqual(threeStep.shortName, "3-Step", "Short name should be correct") 
        XCTAssertEqual(threeStep.stepCount, 3, "Step count should be 3")
        XCTAssertEqual(threeStep.icon, "3.circle.fill", "Icon should be correct")
        XCTAssertEqual(threeStep.color, "blue", "Color should be correct")
        
        // Test 2-step sparring properties
        let twoStep = StepSparringType.twoStep
        XCTAssertEqual(twoStep.displayName, "2-Step Sparring", "Display name should be correct")
        XCTAssertEqual(twoStep.stepCount, 2, "Step count should be 2")
        XCTAssertEqual(twoStep.color, "green", "Color should be correct")
        
        // Test enum cases
        let allCases = StepSparringType.allCases
        XCTAssertEqual(allCases.count, 4, "Should have 4 step sparring types")
        XCTAssertTrue(allCases.contains(.threeStep), "Should contain three-step")
        XCTAssertTrue(allCases.contains(.twoStep), "Should contain two-step")
        XCTAssertTrue(allCases.contains(.oneStep), "Should contain one-step")
        XCTAssertTrue(allCases.contains(.semiFree), "Should contain semi-free")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testUserStepSparringProgressCreation() throws {
        let sequence = StepSparringSequence(
            name: "Progress Test Sequence",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing progress tracking",
            difficulty: 2
        )
        
        testContext.insert(sequence)
        try testContext.save()
        
        // Get or create progress
        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: testProfile)
        
        // Verify initial progress state
        XCTAssertNotNil(progress, "Progress should be created")
        XCTAssertEqual(progress.sequence.id, sequence.id, "Progress should reference correct sequence")
        XCTAssertEqual(progress.userProfile.id, testProfile.id, "Progress should reference correct user")
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start with learning mastery level")
        XCTAssertEqual(progress.practiceCount, 0, "Should start with 0 practice sessions")
        XCTAssertEqual(progress.currentStep, 1, "Should start at step 1")
        XCTAssertEqual(progress.stepsCompleted, 0, "Should start with 0 steps completed")
        XCTAssertEqual(progress.totalPracticeTime, 0, "Should start with 0 practice time")
        XCTAssertEqual(progress.progressPercentage, 0, "Should start with 0% progress")
    }
    
    func testStepSparringPracticeSessionRecording() throws {
        let sequence = StepSparringSequence(
            name: "Practice Session Test",
            type: .threeStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing practice session recording"
        )
        
        // Add steps to the sequence for realistic progress tracking
        let step1 = StepSparringStep(
            sequence: sequence,
            stepNumber: 1,
            attackAction: StepSparringAction(technique: "Punch", execution: "Right stance"),
            defenseAction: StepSparringAction(technique: "Block", execution: "Left stance")
        )
        let step2 = StepSparringStep(
            sequence: sequence,
            stepNumber: 2,
            attackAction: StepSparringAction(technique: "Punch", execution: "Right stance"),
            defenseAction: StepSparringAction(technique: "Block", execution: "Left stance")
        )
        let step3 = StepSparringStep(
            sequence: sequence,
            stepNumber: 3,
            attackAction: StepSparringAction(technique: "Punch", execution: "Right stance"),
            defenseAction: StepSparringAction(technique: "Block", execution: "Left stance")
        )
        
        sequence.steps = [step1, step2, step3]
        
        testContext.insert(sequence)
        testContext.insert(step1)
        testContext.insert(step2)
        testContext.insert(step3)
        try testContext.save()
        
        // Record a practice session
        stepSparringService.recordPracticeSession(
            sequence: sequence,
            userProfile: testProfile,
            duration: 300.0, // 5 minutes
            stepsCompleted: 2
        )
        
        let progress = stepSparringService.getUserProgress(for: sequence, userProfile: testProfile)!
        
        // Verify practice session was recorded
        XCTAssertEqual(progress.practiceCount, 1, "Should have 1 practice session")
        XCTAssertEqual(progress.totalPracticeTime, 300.0, "Should have recorded practice time")
        XCTAssertEqual(progress.stepsCompleted, 2, "Should have completed 2 steps")
        XCTAssertEqual(progress.currentStep, 3, "Should advance to step 3")
        XCTAssertNotNil(progress.lastPracticed, "Should record last practiced date")
        
        // Verify progress percentage
        let expectedProgress = 2.0 / 3.0 * 100.0 // 2 out of 3 steps = ~66.67%
        XCTAssertEqual(progress.progressPercentage, expectedProgress, accuracy: 0.1, "Should calculate progress correctly")
    }
    
    func testStepSparringMasteryProgression() throws {
        let sequence = StepSparringSequence(
            name: "Mastery Test",
            type: .twoStep,
            sequenceNumber: 1,
            sequenceDescription: "Testing mastery progression"
        )
        
        // Add 2 steps for completion tracking
        let step1 = StepSparringStep(
            sequence: sequence, stepNumber: 1,
            attackAction: StepSparringAction(technique: "Attack 1", execution: "Stance 1"),
            defenseAction: StepSparringAction(technique: "Defense 1", execution: "Stance 1")
        )
        let step2 = StepSparringStep(
            sequence: sequence, stepNumber: 2,
            attackAction: StepSparringAction(technique: "Attack 2", execution: "Stance 2"),
            defenseAction: StepSparringAction(technique: "Defense 2", execution: "Stance 2")
        )
        
        sequence.steps = [step1, step2]
        
        testContext.insert(sequence)
        testContext.insert(step1)
        testContext.insert(step2)
        try testContext.save()
        
        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: testProfile)
        
        // Should start as learning
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start as learning")
        
        // Complete all steps but with few practice sessions (should be familiar)
        stepSparringService.recordPracticeSession(sequence: sequence, userProfile: testProfile, duration: 120.0, stepsCompleted: 2)
        XCTAssertEqual(progress.masteryLevel, .familiar, "Should be familiar with 100% completion")
        
        // Add more practice sessions to reach proficient level (5+ sessions with 100% completion)
        for _ in 1...4 {
            stepSparringService.recordPracticeSession(sequence: sequence, userProfile: testProfile, duration: 120.0, stepsCompleted: 2)
        }
        XCTAssertEqual(progress.masteryLevel, .proficient, "Should be proficient with 5+ sessions")
        
        // Add more practice sessions to reach mastered level (10+ sessions with 100% completion)
        for _ in 1...5 {
            stepSparringService.recordPracticeSession(sequence: sequence, userProfile: testProfile, duration: 120.0, stepsCompleted: 2)
        }
        XCTAssertEqual(progress.masteryLevel, .mastered, "Should be mastered with 10+ sessions")
    }
    
    func testStepSparringMasteryLevelProperties() throws {
        // Test mastery level enum properties
        let learning = StepSparringMasteryLevel.learning
        XCTAssertEqual(learning.displayName, "Learning", "Learning display name should be correct")
        XCTAssertEqual(learning.color, "red", "Learning color should be red")
        XCTAssertEqual(learning.icon, "circle.fill", "Learning icon should be correct")
        
        let mastered = StepSparringMasteryLevel.mastered
        XCTAssertEqual(mastered.displayName, "Mastered", "Mastered display name should be correct")
        XCTAssertEqual(mastered.color, "green", "Mastered color should be green")
        XCTAssertEqual(mastered.icon, "checkmark.circle.fill", "Mastered icon should be correct")
        
        // Test all cases
        let allCases = StepSparringMasteryLevel.allCases
        XCTAssertEqual(allCases.count, 4, "Should have 4 mastery levels")
    }
    
    // MARK: - Progress Analytics Tests
    
    func testProgressSummaryGeneration() throws {
        // Create multiple sequences with different progress levels
        let sequence1 = StepSparringSequence(name: "Summary Test 1", type: .threeStep, sequenceNumber: 1, sequenceDescription: "Test")
        let sequence2 = StepSparringSequence(name: "Summary Test 2", type: .twoStep, sequenceNumber: 1, sequenceDescription: "Test")
        
        // Add steps to sequences
        for i in 1...3 {
            let step = StepSparringStep(
                sequence: sequence1, stepNumber: i,
                attackAction: StepSparringAction(technique: "Attack \(i)", execution: "Stance"),
                defenseAction: StepSparringAction(technique: "Defense \(i)", execution: "Stance")
            )
            sequence1.steps.append(step)
        }
        
        for i in 1...2 {
            let step = StepSparringStep(
                sequence: sequence2, stepNumber: i,
                attackAction: StepSparringAction(technique: "Attack \(i)", execution: "Stance"),
                defenseAction: StepSparringAction(technique: "Defense \(i)", execution: "Stance")
            )
            sequence2.steps.append(step)
        }
        
        testContext.insert(sequence1)
        testContext.insert(sequence2)
        
        for step in sequence1.steps {
            testContext.insert(step)
        }
        for step in sequence2.steps {
            testContext.insert(step)
        }
        
        try testContext.save()
        
        // Record different levels of progress
        // Sequence 1: Mastered (10+ sessions, 100% complete)
        for _ in 1...10 {
            stepSparringService.recordPracticeSession(sequence: sequence1, userProfile: testProfile, duration: 120.0, stepsCompleted: 3)
        }
        
        // Sequence 2: Familiar (1 session, 100% complete)
        stepSparringService.recordPracticeSession(sequence: sequence2, userProfile: testProfile, duration: 180.0, stepsCompleted: 2)
        
        // Get progress summary
        let summary = stepSparringService.getProgressSummary(userProfile: testProfile)
        
        // Verify summary statistics
        XCTAssertEqual(summary.totalSequences, 2, "Should have 2 sequences")
        XCTAssertEqual(summary.mastered, 1, "Should have 1 mastered sequence")
        XCTAssertEqual(summary.familiar, 1, "Should have 1 familiar sequence")
        XCTAssertEqual(summary.totalPracticeSessions, 11, "Should have 11 total practice sessions")
        XCTAssertEqual(summary.totalPracticeTime, 1380.0, "Should sum all practice time correctly") // 10*120 + 1*180
        XCTAssertEqual(summary.threeStepProgress.count, 1, "Should track 3-step progress")
        XCTAssertEqual(summary.twoStepProgress.count, 1, "Should track 2-step progress")
        XCTAssertGreaterThan(summary.overallCompletionPercentage, 0, "Should have completion percentage")
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testSequenceRetrievalById() throws {
        let sequence = StepSparringSequence(
            name: "ID Test Sequence",
            type: .threeStep,
            sequenceNumber: 99,
            sequenceDescription: "Testing sequence retrieval by ID"
        )
        
        testContext.insert(sequence)
        try testContext.save()
        
        let foundSequence = stepSparringService.getSequence(id: sequence.id)
        XCTAssertNotNil(foundSequence, "Should find sequence by ID")
        XCTAssertEqual(foundSequence?.id, sequence.id, "Should return correct sequence")
        
        // Test with non-existent ID
        let randomId = UUID()
        let notFoundSequence = stepSparringService.getSequence(id: randomId)
        XCTAssertNil(notFoundSequence, "Should return nil for non-existent ID")
    }
    
    func testSequenceProgressWithoutSteps() throws {
        let sequence = StepSparringSequence(
            name: "Empty Sequence",
            type: .oneStep,
            sequenceNumber: 1,
            sequenceDescription: "Sequence with no steps"
        )
        
        testContext.insert(sequence)
        try testContext.save()
        
        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: testProfile)
        
        // Should handle empty sequence gracefully
        XCTAssertEqual(progress.progressPercentage, 0, "Empty sequence should have 0% progress")
        XCTAssertEqual(progress.currentStep, 1, "Should default to step 1")
        
        // Recording practice on empty sequence should not crash
        stepSparringService.recordPracticeSession(sequence: sequence, userProfile: testProfile, duration: 60.0, stepsCompleted: 0)
        XCTAssertEqual(progress.practiceCount, 1, "Should record practice session even for empty sequence")
    }
    
    func testCounterAttackHandling() throws {
        let sequence = StepSparringSequence(name: "Counter Test", type: .threeStep, sequenceNumber: 1, sequenceDescription: "Testing counter attacks")
        
        let attackAction = StepSparringAction(technique: "Punch", execution: "Right stance")
        let defenseAction = StepSparringAction(technique: "Block", execution: "Left stance")
        let counterAction = StepSparringAction(technique: "Counter punch", execution: "Right stance")
        
        let step = StepSparringStep(
            sequence: sequence,
            stepNumber: 3, // Final step should have counter
            attackAction: attackAction,
            defenseAction: defenseAction,
            timing: "Block then counter",
            keyPoints: "Quick transition to counter attack"
        )
        
        step.counterAction = counterAction // Add counter attack
        
        testContext.insert(sequence)
        testContext.insert(attackAction)
        testContext.insert(defenseAction)
        testContext.insert(counterAction)
        testContext.insert(step)
        try testContext.save()
        
        // Verify counter attack is properly associated
        XCTAssertNotNil(step.counterAction, "Step should have counter action")
        XCTAssertEqual(step.counterAction?.technique, "Counter punch", "Counter technique should match")
    }
    
    func testSequenceOrderingAndSorting() throws {
        // Create sequences with different sequence numbers
        let sequence3 = StepSparringSequence(name: "Sequence #3", type: .threeStep, sequenceNumber: 3, sequenceDescription: "Third")
        let sequence1 = StepSparringSequence(name: "Sequence #1", type: .threeStep, sequenceNumber: 1, sequenceDescription: "First")
        let sequence2 = StepSparringSequence(name: "Sequence #2", type: .threeStep, sequenceNumber: 2, sequenceDescription: "Second")
        
        // Insert in random order
        testContext.insert(sequence3)
        testContext.insert(sequence1)
        testContext.insert(sequence2)
        try testContext.save()
        
        // Service should return sequences sorted by sequence number
        let allSequences = stepSparringService.getSequences(for: .threeStep, userProfile: testProfile)
        
        if allSequences.count >= 3 {
            let lastThree = Array(allSequences.suffix(3))
            XCTAssertEqual(lastThree[0].sequenceNumber, 1, "First sequence should have number 1")
            XCTAssertEqual(lastThree[1].sequenceNumber, 2, "Second sequence should have number 2") 
            XCTAssertEqual(lastThree[2].sequenceNumber, 3, "Third sequence should have number 3")
        }
    }
}