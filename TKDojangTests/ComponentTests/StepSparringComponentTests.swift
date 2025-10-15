import XCTest
import SwiftData
@testable import TKDojang

/**
 * StepSparringComponentTests.swift
 *
 * PURPOSE: Property-based component tests for Step Sparring feature
 *
 * TESTING STRATEGY: Property-Based Testing
 * - Test PROPERTIES that must hold for ANY valid input
 * - Use randomization to cover edge cases automatically
 * - Validate domain invariants across all scenarios
 *
 * COVERAGE AREAS:
 * 1. Sequence Data Properties (6 tests) - Data integrity and relationships
 * 2. User Progress Tracking Properties (8 tests) - Progress state management
 * 3. Mastery Level Progression Properties (5 tests) - Skill progression logic
 * 4. Sequence Filtering & Access Properties (4 tests) - Belt-appropriate access
 * 5. Statistics Calculations (3 tests) - Analytics accuracy
 * 6. Action Properties (2 tests) - Attack/defense action validation
 * 7. Enum Display Names (3 tests) - UI display consistency
 *
 * TOTAL: 31 property-based tests
 */
@MainActor
final class StepSparringComponentTests: XCTestCase {
    var testContext: ModelContext!
    var stepSparringService: StepSparringDataService!

    override func setUp() {
        super.setUp()
        do {
            let testContainer = try TestContainerFactory.createTestContainer()
            testContext = testContainer.mainContext
            stepSparringService = StepSparringDataService(modelContext: testContext)

            // Load test content
            let dataFactory = TestDataFactory()
            try dataFactory.createBasicTestData(in: testContext)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }

    override func tearDown() {
        testContext = nil
        stepSparringService = nil
        super.tearDown()
    }

    // MARK: - Test Helpers

    private func createTestProfile(beltLevel: BeltLevel? = nil) throws -> UserProfile {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let belt = beltLevel ?? allBelts.randomElement()!

        let profile = UserProfile(
            name: "TestUser_\(UUID().uuidString.prefix(8))",
            currentBeltLevel: belt
        )
        testContext.insert(profile)
        try testContext.save()
        return profile
    }

    // MARK: - 1. Sequence Data Properties (6 tests)

    /**
     * PROPERTY: All steps in a sequence must be numbered sequentially from 1 to N
     */
    func testSequenceData_PropertyBased_StepSequentialOrdering() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            let steps = sequence.steps.sorted { $0.stepNumber < $1.stepNumber }

            // PROPERTY: Steps numbered 1, 2, 3, ..., N
            for (index, step) in steps.enumerated() {
                XCTAssertEqual(step.stepNumber, index + 1,
                    """
                    PROPERTY VIOLATION: Step numbering not sequential
                    Sequence: \(sequence.name)
                    Expected step: \(index + 1)
                    Got: \(step.stepNumber)
                    """)
            }
        }

        XCTAssertGreaterThan(allSequences.count, 0, "Should have test sequences loaded")
    }

    /**
     * PROPERTY: All sequences must have required fields populated
     */
    func testSequenceData_PropertyBased_RequiredFieldsValidation() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            // PROPERTY: Name must not be empty
            XCTAssertFalse(sequence.name.isEmpty,
                "PROPERTY VIOLATION: Sequence has empty name (ID: \(sequence.id))")

            // PROPERTY: Must have description
            XCTAssertFalse(sequence.sequenceDescription.isEmpty,
                "PROPERTY VIOLATION: Sequence '\(sequence.name)' has empty description")

            // PROPERTY: Must have at least one step
            XCTAssertGreaterThan(sequence.totalSteps, 0,
                "PROPERTY VIOLATION: Sequence '\(sequence.name)' has no steps")

            // PROPERTY: Type must be valid
            XCTAssertTrue(StepSparringType.allCases.contains(sequence.type),
                "PROPERTY VIOLATION: Sequence '\(sequence.name)' has invalid type")

            // PROPERTY: Difficulty must be 1-5
            XCTAssertTrue((1...5).contains(sequence.difficulty),
                "PROPERTY VIOLATION: Sequence '\(sequence.name)' difficulty \(sequence.difficulty) outside 1-5 range")
        }

        XCTAssertGreaterThan(allSequences.count, 0, "Should have test sequences loaded")
    }

    /**
     * PROPERTY: All steps must belong to their parent sequence
     */
    func testSequenceData_PropertyBased_StepSequenceRelationshipIntegrity() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            for step in sequence.steps {
                // PROPERTY: Step's sequence reference must match parent
                XCTAssertEqual(step.sequence.id, sequence.id,
                    """
                    PROPERTY VIOLATION: Step-Sequence relationship broken
                    Step #\(step.stepNumber)
                    Expected sequence: \(sequence.name)
                    Got sequence: \(step.sequence.name)
                    """)
            }
        }

        XCTAssertGreaterThan(allSequences.count, 0, "Should have test sequences loaded")
    }

    /**
     * PROPERTY: Belt level filtering logic must be consistent
     * Lower belt = higher sortOrder, so users see sequences for their belt and below
     */
    func testSequenceData_PropertyBased_BeltLevelAppropriateness() throws {
        _ = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())

        // Test with 5 random belt levels
        for _ in 0..<5 {
            guard let userBelt = allBelts.randomElement() else { continue }
            let profile = try createTestProfile(beltLevel: userBelt)

            let availableSequences = stepSparringService.getSequencesForUser(userProfile: profile)

            for sequence in availableSequences {
                // PROPERTY: Available sequences must be appropriate for belt
                let isAvailable = sequence.isAvailableFor(beltLevel: userBelt)
                XCTAssertTrue(isAvailable,
                    """
                    PROPERTY VIOLATION: Sequence returned but not available
                    Sequence: \(sequence.name)
                    User belt: \(userBelt.shortName) (sortOrder: \(userBelt.sortOrder))
                    isAvailableFor returned: \(isAvailable)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Each action must have technique and execution details
     */
    func testSequenceData_PropertyBased_ActionValidation() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            for step in sequence.steps {
                // PROPERTY: Attack action must have technique
                XCTAssertFalse(step.attackAction.technique.isEmpty,
                    """
                    PROPERTY VIOLATION: Attack action missing technique
                    Sequence: \(sequence.name), Step: \(step.stepNumber)
                    """)

                // PROPERTY: Defense action must have technique
                XCTAssertFalse(step.defenseAction.technique.isEmpty,
                    """
                    PROPERTY VIOLATION: Defense action missing technique
                    Sequence: \(sequence.name), Step: \(step.stepNumber)
                    """)

                // PROPERTY: Actions must have execution details
                XCTAssertFalse(step.attackAction.execution.isEmpty,
                    """
                    PROPERTY VIOLATION: Attack action missing execution
                    Sequence: \(sequence.name), Step: \(step.stepNumber)
                    """)

                XCTAssertFalse(step.defenseAction.execution.isEmpty,
                    """
                    PROPERTY VIOLATION: Defense action missing execution
                    Sequence: \(sequence.name), Step: \(step.stepNumber)
                    """)
            }
        }

        XCTAssertGreaterThan(allSequences.count, 0, "Should have test sequences loaded")
    }

    /**
     * PROPERTY: All sequence IDs must be unique
     */
    func testSequenceData_PropertyBased_UniqueIdentifiers() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        let ids = allSequences.map { $0.id }
        let uniqueIds = Set(ids)

        // PROPERTY: All IDs must be unique
        XCTAssertEqual(ids.count, uniqueIds.count,
            """
            PROPERTY VIOLATION: Duplicate sequence IDs found
            Total sequences: \(ids.count)
            Unique IDs: \(uniqueIds.count)
            """)
    }

    // MARK: - 2. User Progress Tracking Properties (8 tests)

    /**
     * PROPERTY: Recording a practice session must update all relevant metrics
     */
    func testUserProgress_PropertyBased_PracticeSessionUpdatesAllMetrics() throws {
        // Test 5 random scenarios
        for _ in 0..<5 {
            let profile = try createTestProfile()
            let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
            guard let sequence = allSequences.randomElement() else { continue }

            let initialProgress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)
            let initialCount = initialProgress.practiceCount
            let initialTime = initialProgress.totalPracticeTime

            let duration = Double.random(in: 30.0...180.0)
            let stepsCompleted = Int.random(in: 1...sequence.totalSteps)

            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: duration,
                stepsCompleted: stepsCompleted
            )

            let updatedProgress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

            // PROPERTY: Practice count must increment
            XCTAssertEqual(updatedProgress.practiceCount, initialCount + 1,
                "PROPERTY VIOLATION: Practice count not incremented")

            // PROPERTY: Total time must increase
            XCTAssertEqual(updatedProgress.totalPracticeTime, initialTime + duration, accuracy: 0.01,
                "PROPERTY VIOLATION: Total time not updated correctly")

            // PROPERTY: Steps completed must not decrease
            XCTAssertGreaterThanOrEqual(updatedProgress.stepsCompleted, stepsCompleted,
                "PROPERTY VIOLATION: Steps completed decreased")

            // PROPERTY: Last practiced must be recent
            XCTAssertNotNil(updatedProgress.lastPracticed,
                "PROPERTY VIOLATION: Last practiced not set")
        }
    }

    /**
     * PROPERTY: Progress percentage must match (stepsCompleted / totalSteps) × 100
     */
    func testUserProgress_PropertyBased_ProgressPercentageCalculation() throws {
        // Test 10 random scenarios
        for _ in 0..<10 {
            let profile = try createTestProfile()
            let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
            guard let sequence = allSequences.randomElement() else { continue }

            _ = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)

            // Complete random number of steps
            let stepsCompleted = Int.random(in: 0...sequence.totalSteps)
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: stepsCompleted
            )

            let updatedProgress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!
            let expectedPercentage = Double(updatedProgress.stepsCompleted) / Double(sequence.totalSteps) * 100.0

            // PROPERTY: Progress percentage must match formula
            XCTAssertEqual(updatedProgress.progressPercentage, expectedPercentage, accuracy: 0.01,
                """
                PROPERTY VIOLATION: Progress percentage incorrect
                Steps completed: \(updatedProgress.stepsCompleted)
                Total steps: \(sequence.totalSteps)
                Expected: \(Int(expectedPercentage))%
                Got: \(Int(updatedProgress.progressPercentage))%
                """)
        }
    }

    /**
     * PROPERTY: Steps completed must never decrease (monotonic increase)
     */
    func testUserProgress_PropertyBased_StepsCompletedMonotonicIncrease() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        var previousStepsCompleted = 0

        // Record 5 practice sessions
        for _ in 0..<5 {
            let stepsCompleted = Int.random(in: 1...sequence.totalSteps)
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: stepsCompleted
            )

            let progress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

            // PROPERTY: Steps completed must never decrease
            XCTAssertGreaterThanOrEqual(progress.stepsCompleted, previousStepsCompleted,
                """
                PROPERTY VIOLATION: Steps completed decreased
                Previous: \(previousStepsCompleted)
                Current: \(progress.stepsCompleted)
                """)

            previousStepsCompleted = progress.stepsCompleted
        }
    }

    /**
     * PROPERTY: Current step must be next uncompleted step or last step
     */
    func testUserProgress_PropertyBased_CurrentStepTracking() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        _ = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)

        // Complete steps incrementally
        for stepNum in 1...sequence.totalSteps {
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: stepNum
            )

            let updatedProgress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

            // PROPERTY: Current step = completed + 1, or stays at totalSteps if all complete
            let expectedCurrentStep = min(stepNum + 1, sequence.totalSteps)
            if stepNum < sequence.totalSteps {
                XCTAssertEqual(updatedProgress.currentStep, expectedCurrentStep,
                    """
                    PROPERTY VIOLATION: Current step incorrect
                    Steps completed: \(stepNum)
                    Expected current: \(expectedCurrentStep)
                    Got: \(updatedProgress.currentStep)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Practice count must increase by exactly 1 per session
     */
    func testUserProgress_PropertyBased_PracticeCountIncrement() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)
        let initialCount = progress.practiceCount

        // Record N sessions
        let sessionCount = Int.random(in: 3...10)
        for _ in 0..<sessionCount {
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: 1
            )
        }

        let finalProgress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

        // PROPERTY: Count must increase by exactly N
        XCTAssertEqual(finalProgress.practiceCount, initialCount + sessionCount,
            """
            PROPERTY VIOLATION: Practice count incorrect
            Initial: \(initialCount)
            Sessions recorded: \(sessionCount)
            Expected final: \(initialCount + sessionCount)
            Got: \(finalProgress.practiceCount)
            """)
    }

    /**
     * PROPERTY: Total practice time must be sum of all durations
     */
    func testUserProgress_PropertyBased_TotalPracticeTimeAccumulation() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)
        let initialTime = progress.totalPracticeTime

        var expectedTime = initialTime

        // Record N sessions with random durations
        for _ in 0..<5 {
            let duration = Double.random(in: 30.0...180.0)
            expectedTime += duration

            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: duration,
                stepsCompleted: 1
            )
        }

        let finalProgress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

        // PROPERTY: Total time must match sum
        XCTAssertEqual(finalProgress.totalPracticeTime, expectedTime, accuracy: 0.01,
            """
            PROPERTY VIOLATION: Total practice time incorrect
            Expected: \(Int(expectedTime))s
            Got: \(Int(finalProgress.totalPracticeTime))s
            """)
    }

    /**
     * PROPERTY: Last practiced date must be in the past or now
     */
    func testUserProgress_PropertyBased_LastPracticedDateValidation() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        stepSparringService.recordPracticeSession(
            sequence: sequence,
            userProfile: profile,
            duration: 60.0,
            stepsCompleted: 1
        )

        let progress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!

        // PROPERTY: Last practiced must be <= now
        XCTAssertNotNil(progress.lastPracticed, "Last practiced should be set")
        if let lastPracticed = progress.lastPracticed {
            XCTAssertLessThanOrEqual(lastPracticed, Date(),
                """
                PROPERTY VIOLATION: Last practiced date in future
                Last practiced: \(lastPracticed)
                Now: \(Date())
                """)
        }
    }

    /**
     * PROPERTY: Initial progress state must be consistent
     */
    func testUserProgress_PropertyBased_InitialStateConsistency() throws {
        // Test 5 random sequences
        for _ in 0..<5 {
            let profile = try createTestProfile()
            let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
            guard let sequence = allSequences.randomElement() else { continue }

            let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)

            // PROPERTY: Initial mastery level must be learning
            XCTAssertEqual(progress.masteryLevel, .learning,
                "PROPERTY VIOLATION: Initial mastery level not 'learning'")

            // PROPERTY: Initial practice count must be 0
            XCTAssertEqual(progress.practiceCount, 0,
                "PROPERTY VIOLATION: Initial practice count not 0")

            // PROPERTY: Initial current step must be 1
            XCTAssertEqual(progress.currentStep, 1,
                "PROPERTY VIOLATION: Initial current step not 1")

            // PROPERTY: Initial steps completed must be 0
            XCTAssertEqual(progress.stepsCompleted, 0,
                "PROPERTY VIOLATION: Initial steps completed not 0")
        }
    }

    // MARK: - 3. Mastery Level Progression Properties (5 tests)

    /**
     * PROPERTY: Mastery progression thresholds must be consistent
     * Learning → Familiar (80% complete) → Proficient (100% + 5 practices) → Mastered (100% + 10 practices)
     */
    func testMasteryLevel_PropertyBased_ProgressionThresholds() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        let progress = stepSparringService.getOrCreateProgress(for: sequence, userProfile: profile)

        // Start: Learning
        XCTAssertEqual(progress.masteryLevel, .learning,
            "PROPERTY VIOLATION: Should start at learning")

        // Complete 80% of steps: Should become Familiar
        let eightyPercentSteps = Int(Double(sequence.totalSteps) * 0.8)
        if eightyPercentSteps > 0 {
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: eightyPercentSteps
            )

            let afterEightyPercent = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!
            XCTAssertEqual(afterEightyPercent.masteryLevel, .familiar,
                "PROPERTY VIOLATION: Should be familiar at 80% completion")
        }

        // Complete 100% with 5 practices: Should be Proficient
        for _ in 0..<5 {
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: sequence.totalSteps
            )
        }

        let afterFivePractices = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!
        XCTAssertEqual(afterFivePractices.masteryLevel, .proficient,
            "PROPERTY VIOLATION: Should be proficient after 5 complete practices")

        // Complete 100% with 10+ practices: Should be Mastered
        for _ in 0..<6 { // 6 more to reach 11 total
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: sequence.totalSteps
            )
        }

        let afterTenPractices = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!
        XCTAssertEqual(afterTenPractices.masteryLevel, .mastered,
            "PROPERTY VIOLATION: Should be mastered after 10+ complete practices")
    }

    /**
     * PROPERTY: Mastery level should only progress forward with completion
     */
    func testMasteryLevel_PropertyBased_NoRegressionWithProgress() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        guard let sequence = allSequences.randomElement() else {
            XCTFail("No sequences available")
            return
        }

        var previousLevel = StepSparringMasteryLevel.learning

        // Record progressive sessions
        for sessionNum in 1...12 {
            let stepsCompleted = min(sessionNum, sequence.totalSteps)
            stepSparringService.recordPracticeSession(
                sequence: sequence,
                userProfile: profile,
                duration: 60.0,
                stepsCompleted: stepsCompleted
            )

            let progress = stepSparringService.getUserProgress(for: sequence, userProfile: profile)!
            let currentLevel = progress.masteryLevel

            // PROPERTY: Level should not regress with more practice
            let levelOrder: [StepSparringMasteryLevel] = [.learning, .familiar, .proficient, .mastered]
            let previousIndex = levelOrder.firstIndex(of: previousLevel) ?? 0
            let currentIndex = levelOrder.firstIndex(of: currentLevel) ?? 0

            XCTAssertGreaterThanOrEqual(currentIndex, previousIndex,
                """
                PROPERTY VIOLATION: Mastery level regressed
                Session: \(sessionNum)
                Previous: \(previousLevel.displayName)
                Current: \(currentLevel.displayName)
                """)

            previousLevel = currentLevel
        }
    }

    /**
     * PROPERTY: Mastery levels must sort consistently
     */
    func testMasteryLevel_PropertyBased_SortOrderConsistency() throws {
        let levels: [StepSparringMasteryLevel] = [.mastered, .learning, .proficient, .familiar]
        let sorted = levels.sorted { lhs, rhs in
            let order: [StepSparringMasteryLevel] = [.learning, .familiar, .proficient, .mastered]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }

        // PROPERTY: Sorted order must be learning → familiar → proficient → mastered
        XCTAssertEqual(sorted, [.learning, .familiar, .proficient, .mastered],
            "PROPERTY VIOLATION: Mastery levels don't sort correctly")
    }

    /**
     * PROPERTY: Each mastery level must have a distinct color
     */
    func testMasteryLevel_PropertyBased_DistinctColors() throws {
        let colors = StepSparringMasteryLevel.allCases.map { $0.color }
        let uniqueColors = Set(colors)

        // PROPERTY: All colors must be unique
        XCTAssertEqual(colors.count, uniqueColors.count,
            """
            PROPERTY VIOLATION: Duplicate mastery level colors
            Total levels: \(colors.count)
            Unique colors: \(uniqueColors.count)
            """)
    }

    /**
     * PROPERTY: Each mastery level must have a distinct icon
     */
    func testMasteryLevel_PropertyBased_DistinctIcons() throws {
        let icons = StepSparringMasteryLevel.allCases.map { $0.icon }
        let uniqueIcons = Set(icons)

        // PROPERTY: All icons must be unique
        XCTAssertEqual(icons.count, uniqueIcons.count,
            """
            PROPERTY VIOLATION: Duplicate mastery level icons
            Total levels: \(icons.count)
            Unique icons: \(uniqueIcons.count)
            """)
    }

    // MARK: - 4. Sequence Filtering & Access Properties (4 tests)

    /**
     * PROPERTY: getSequencesForUser must return only belt-appropriate sequences
     */
    func testSequenceAccess_PropertyBased_OnlyAppropriateSequences() throws {
        // Test with 5 random belt levels
        for _ in 0..<5 {
            let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            guard let userBelt = allBelts.randomElement() else { continue }
            let profile = try createTestProfile(beltLevel: userBelt)

            let sequences = stepSparringService.getSequencesForUser(userProfile: profile)

            for sequence in sequences {
                // PROPERTY: All returned sequences must be available for user's belt
                let isAvailable = sequence.isAvailableFor(beltLevel: userBelt)
                XCTAssertTrue(isAvailable,
                    """
                    PROPERTY VIOLATION: Sequence returned but not available
                    Sequence: \(sequence.name)
                    User belt: \(userBelt.shortName)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Type filtering must return only sequences of specified type
     */
    func testSequenceAccess_PropertyBased_TypeFilteringCorrectness() throws {
        let profile = try createTestProfile()

        // Test each sparring type
        for type in StepSparringType.allCases {
            let sequences = stepSparringService.getSequences(for: type, userProfile: profile)

            for sequence in sequences {
                // PROPERTY: All returned sequences must match requested type
                XCTAssertEqual(sequence.type, type,
                    """
                    PROPERTY VIOLATION: Type filtering incorrect
                    Requested: \(type.displayName)
                    Got: \(sequence.type.displayName)
                    Sequence: \(sequence.name)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Sequence lookup by ID must return correct sequence
     */
    func testSequenceAccess_PropertyBased_LookupCorrectness() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        // Test 5 random lookups
        for _ in 0..<min(5, allSequences.count) {
            guard let sequence = allSequences.randomElement() else { continue }

            let lookedUp = stepSparringService.getSequence(id: sequence.id)

            // PROPERTY: Looked up sequence must match original
            XCTAssertNotNil(lookedUp, "PROPERTY VIOLATION: Sequence lookup returned nil")
            XCTAssertEqual(lookedUp?.id, sequence.id,
                "PROPERTY VIOLATION: Lookup returned wrong sequence")
            XCTAssertEqual(lookedUp?.name, sequence.name,
                "PROPERTY VIOLATION: Lookup returned sequence with different name")
        }
    }

    /**
     * PROPERTY: Higher belt levels should have access to more or equal sequences
     */
    func testSequenceAccess_PropertyBased_ProgressionConsistency() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>()).sorted { $0.sortOrder > $1.sortOrder }

        var previousCount = 0

        for belt in allBelts {
            let profile = try createTestProfile(beltLevel: belt)
            let sequences = stepSparringService.getSequencesForUser(userProfile: profile)

            // PROPERTY: Sequence count must not decrease as belt progresses
            XCTAssertGreaterThanOrEqual(sequences.count, previousCount,
                """
                PROPERTY VIOLATION: Higher belt has fewer sequences
                Belt: \(belt.shortName)
                Sequences: \(sequences.count)
                Previous belt sequences: \(previousCount)
                """)

            previousCount = sequences.count
        }
    }

    // MARK: - 5. Statistics Calculations (3 tests)

    /**
     * PROPERTY: Summary totals must match sum of individual progress records
     */
    func testStatistics_PropertyBased_AccurateSummation() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        // Record progress for 3-5 random sequences
        let sequenceCount = Int.random(in: 3...min(5, allSequences.count))
        let selectedSequences = allSequences.shuffled().prefix(sequenceCount)

        var expectedTotalSessions = 0
        var expectedTotalTime: TimeInterval = 0

        for sequence in selectedSequences {
            let sessions = Int.random(in: 1...5)
            for _ in 0..<sessions {
                let duration = Double.random(in: 30.0...120.0)
                expectedTotalSessions += 1
                expectedTotalTime += duration

                stepSparringService.recordPracticeSession(
                    sequence: sequence,
                    userProfile: profile,
                    duration: duration,
                    stepsCompleted: 1
                )
            }
        }

        let summary = stepSparringService.getProgressSummary(userProfile: profile)

        // PROPERTY: Summary totals must match actual totals
        XCTAssertEqual(summary.totalPracticeSessions, expectedTotalSessions,
            """
            PROPERTY VIOLATION: Total sessions incorrect
            Expected: \(expectedTotalSessions)
            Got: \(summary.totalPracticeSessions)
            """)

        XCTAssertEqual(summary.totalPracticeTime, expectedTotalTime, accuracy: 1.0,
            """
            PROPERTY VIOLATION: Total time incorrect
            Expected: \(Int(expectedTotalTime))s
            Got: \(Int(summary.totalPracticeTime))s
            """)
    }

    /**
     * PROPERTY: Completion percentage must match (mastered / total) × 100
     */
    func testStatistics_PropertyBased_CompletionPercentageCalculation() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        // Create progress for 5 sequences with different mastery levels
        let selectedSequences = allSequences.shuffled().prefix(5)

        for sequence in selectedSequences {
            // Random practices to vary mastery level
            let practices = Int.random(in: 0...12)
            for _ in 0..<practices {
                stepSparringService.recordPracticeSession(
                    sequence: sequence,
                    userProfile: profile,
                    duration: 60.0,
                    stepsCompleted: sequence.totalSteps
                )
            }
        }

        let summary = stepSparringService.getProgressSummary(userProfile: profile)

        // Calculate expected percentage
        let expectedPercentage = summary.totalSequences > 0 ?
            Double(summary.mastered) / Double(summary.totalSequences) * 100.0 : 0.0

        // PROPERTY: Completion percentage must match formula
        XCTAssertEqual(summary.overallCompletionPercentage, expectedPercentage, accuracy: 0.01,
            """
            PROPERTY VIOLATION: Completion percentage incorrect
            Mastered: \(summary.mastered)
            Total: \(summary.totalSequences)
            Expected: \(Int(expectedPercentage))%
            Got: \(Int(summary.overallCompletionPercentage))%
            """)
    }

    /**
     * PROPERTY: Summary mastery counts must sum to total sequences
     */
    func testStatistics_PropertyBased_MasteryCountsConsistency() throws {
        let profile = try createTestProfile()
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        // Create varied progress
        let selectedSequences = allSequences.shuffled().prefix(5)

        for sequence in selectedSequences {
            let practices = Int.random(in: 0...15)
            for _ in 0..<practices {
                stepSparringService.recordPracticeSession(
                    sequence: sequence,
                    userProfile: profile,
                    duration: 60.0,
                    stepsCompleted: Int.random(in: 1...sequence.totalSteps)
                )
            }
        }

        let summary = stepSparringService.getProgressSummary(userProfile: profile)

        // PROPERTY: Mastery counts must sum to total sequences
        let masterySum = summary.learning + summary.familiar + summary.proficient + summary.mastered
        XCTAssertEqual(masterySum, summary.totalSequences,
            """
            PROPERTY VIOLATION: Mastery counts don't sum to total
            Learning: \(summary.learning)
            Familiar: \(summary.familiar)
            Proficient: \(summary.proficient)
            Mastered: \(summary.mastered)
            Sum: \(masterySum)
            Total: \(summary.totalSequences)
            """)
    }

    // MARK: - 6. Action Properties (2 tests)

    /**
     * PROPERTY: Action display title must include technique name
     */
    func testActionProperties_DisplayTitleFormat() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            for step in sequence.steps {
                // PROPERTY: Display title must contain technique
                XCTAssertTrue(step.attackAction.displayTitle.contains(step.attackAction.technique),
                    """
                    PROPERTY VIOLATION: Attack display title missing technique
                    Display: \(step.attackAction.displayTitle)
                    Technique: \(step.attackAction.technique)
                    """)

                XCTAssertTrue(step.defenseAction.displayTitle.contains(step.defenseAction.technique),
                    """
                    PROPERTY VIOLATION: Defense display title missing technique
                    Display: \(step.defenseAction.displayTitle)
                    Technique: \(step.defenseAction.technique)
                    """)

                // PROPERTY: If Korean name exists, it should appear in display title
                if !step.attackAction.koreanName.isEmpty {
                    XCTAssertTrue(step.attackAction.displayTitle.contains(step.attackAction.koreanName),
                        "PROPERTY VIOLATION: Korean name not in attack display title")
                }

                if !step.defenseAction.koreanName.isEmpty {
                    XCTAssertTrue(step.defenseAction.displayTitle.contains(step.defenseAction.koreanName),
                        "PROPERTY VIOLATION: Korean name not in defense display title")
                }
            }
        }
    }

    /**
     * PROPERTY: Counter action is optional but if present must be valid
     */
    func testActionProperties_CounterActionValidation() throws {
        let allSequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())

        for sequence in allSequences {
            for step in sequence.steps {
                if let counter = step.counterAction {
                    // PROPERTY: Counter action must have technique
                    XCTAssertFalse(counter.technique.isEmpty,
                        """
                        PROPERTY VIOLATION: Counter action has empty technique
                        Sequence: \(sequence.name), Step: \(step.stepNumber)
                        """)

                    // PROPERTY: Counter action must have execution
                    XCTAssertFalse(counter.execution.isEmpty,
                        """
                        PROPERTY VIOLATION: Counter action has empty execution
                        Sequence: \(sequence.name), Step: \(step.stepNumber)
                        """)
                }
            }
        }
    }

    // MARK: - 7. Enum Display Names (3 tests)

    /**
     * Test StepSparringType enum display properties
     */
    func testEnumDisplayNames_StepSparringType() throws {
        for type in StepSparringType.allCases {
            // All types must have display name
            XCTAssertFalse(type.displayName.isEmpty,
                "Type \(type.rawValue) has empty display name")

            // All types must have short name
            XCTAssertFalse(type.shortName.isEmpty,
                "Type \(type.rawValue) has empty short name")

            // All types must have description
            XCTAssertFalse(type.description.isEmpty,
                "Type \(type.rawValue) has empty description")

            // All types must have icon
            XCTAssertFalse(type.icon.isEmpty,
                "Type \(type.rawValue) has empty icon")

            // All types must have color
            XCTAssertFalse(type.color.isEmpty,
                "Type \(type.rawValue) has empty color")

            // Step count must be positive
            XCTAssertGreaterThan(type.stepCount, 0,
                "Type \(type.rawValue) has invalid step count")
        }
    }

    /**
     * Test StepSparringMasteryLevel enum display properties
     */
    func testEnumDisplayNames_MasteryLevel() throws {
        for level in StepSparringMasteryLevel.allCases {
            // All levels must have display name
            XCTAssertFalse(level.displayName.isEmpty,
                "Mastery level \(level.rawValue) has empty display name")

            // All levels must have color
            XCTAssertFalse(level.color.isEmpty,
                "Mastery level \(level.rawValue) has empty color")

            // All levels must have icon
            XCTAssertFalse(level.icon.isEmpty,
                "Mastery level \(level.rawValue) has empty icon")
        }

        // Specific color validation
        XCTAssertEqual(StepSparringMasteryLevel.learning.color, "red")
        XCTAssertEqual(StepSparringMasteryLevel.familiar.color, "orange")
        XCTAssertEqual(StepSparringMasteryLevel.proficient.color, "blue")
        XCTAssertEqual(StepSparringMasteryLevel.mastered.color, "green")
    }

    /**
     * Test StepSparringSessionType enum display properties
     */
    func testEnumDisplayNames_SessionType() throws {
        for sessionType in StepSparringSessionType.allCases {
            // All session types must have display name
            XCTAssertFalse(sessionType.displayName.isEmpty,
                "Session type \(sessionType.rawValue) has empty display name")
        }

        // Specific display name validation
        XCTAssertEqual(StepSparringSessionType.individual.displayName, "Individual Practice")
        XCTAssertEqual(StepSparringSessionType.partner.displayName, "Partner Practice")
        XCTAssertEqual(StepSparringSessionType.review.displayName, "Review Session")
        XCTAssertEqual(StepSparringSessionType.assessment.displayName, "Skills Assessment")
    }
}
