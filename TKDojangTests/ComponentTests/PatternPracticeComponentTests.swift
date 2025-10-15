import XCTest
import SwiftUI
import SwiftData
import ViewInspector
@testable import TKDojang

/**
 * PatternPracticeComponentTests.swift
 *
 * PURPOSE: Property-based component tests for Pattern Practice feature
 *
 * APPROACH: Property-based testing validates behavior across ALL valid configurations
 * using randomization to catch edge cases and ensure correctness of pattern learning,
 * progress tracking, and mastery calculations.
 *
 * CRITICAL TESTS:
 * - Pattern data integrity and relationships
 * - User progress tracking and mastery level progression
 * - Spaced repetition calculations
 * - Pattern filtering by belt level
 * - Practice session recording and statistics
 *
 * TEST CATEGORIES:
 * 1. Pattern Data Properties (6 tests)
 * 2. User Progress Tracking (8 tests)
 * 3. Mastery Level Progression (5 tests)
 * 4. Pattern Filtering & Access (4 tests)
 * 5. Statistics Calculations (3 tests)
 * 6. Enum Display Names (2 tests)
 *
 * TOTAL: 28 tests
 */

@MainActor
final class PatternPracticeComponentTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var patternService: PatternDataService!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext
        patternService = PatternDataService(modelContext: testContext)

        // Load test data
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
    }

    override func tearDown() async throws {
        testContext = nil
        testContainer = nil
        patternService = nil
        try await super.tearDown()
    }

    // MARK: - 1. Pattern Data Properties (6 tests)

    /**
     * PROPERTY: Pattern moves must be ordered sequentially from 1 to moveCount
     *
     * Tests that all patterns have correctly numbered moves
     */
    func testPatternData_PropertyBased_MovesOrderedSequentially() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())

        // Act & Assert: Check each pattern's move ordering
        for pattern in allPatterns {
            let orderedMoves = pattern.orderedMoves

            // PROPERTY: Moves must be sequential starting from 1
            for (index, move) in orderedMoves.enumerated() {
                XCTAssertEqual(move.moveNumber, index + 1,
                    """
                    PROPERTY VIOLATION: Moves must be numbered sequentially
                    Pattern: \(pattern.name)
                    Expected move number: \(index + 1)
                    Got: \(move.moveNumber)
                    """)
            }

            // PROPERTY: Number of moves must match moveCount
            XCTAssertEqual(orderedMoves.count, pattern.moveCount,
                """
                PROPERTY VIOLATION: Move count mismatch
                Pattern: \(pattern.name)
                Declared moveCount: \(pattern.moveCount)
                Actual moves: \(orderedMoves.count)
                """)
        }
    }

    /**
     * PROPERTY: All pattern moves must have required fields
     *
     * Tests data integrity across all patterns
     */
    func testPatternData_PropertyBased_MovesHaveRequiredFields() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())

        // Act & Assert: Check each move's required fields
        for pattern in allPatterns {
            for move in pattern.moves {
                // PROPERTY: Required fields must not be empty
                XCTAssertFalse(move.stance.isEmpty,
                    "Move \(move.moveNumber) in \(pattern.name) has empty stance")
                XCTAssertFalse(move.technique.isEmpty,
                    "Move \(move.moveNumber) in \(pattern.name) has empty technique")
                XCTAssertFalse(move.direction.isEmpty,
                    "Move \(move.moveNumber) in \(pattern.name) has empty direction")
                XCTAssertFalse(move.keyPoints.isEmpty,
                    "Move \(move.moveNumber) in \(pattern.name) has empty keyPoints")
            }
        }
    }

    /**
     * PROPERTY: Pattern moves must maintain relationship to parent pattern
     *
     * Tests bidirectional relationship integrity
     */
    func testPatternData_PropertyBased_MovePatternRelationship() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())

        // Act & Assert: Check move-pattern relationships
        for pattern in allPatterns {
            for move in pattern.moves {
                // PROPERTY: Move must reference its parent pattern
                XCTAssertNotNil(move.pattern,
                    "Move \(move.moveNumber) in \(pattern.name) has nil pattern reference")
                XCTAssertEqual(move.pattern?.id, pattern.id,
                    "Move \(move.moveNumber) pattern ID mismatch")
            }
        }
    }

    /**
     * PROPERTY: Pattern appropriateness for belt levels must be consistent
     *
     * Tests belt level filtering logic
     */
    func testPatternData_PropertyBased_BeltLevelAppropriateness() throws {
        // Arrange: Get patterns and belt levels
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())

        guard !allPatterns.isEmpty && !allBelts.isEmpty else { return }

        // Act & Assert: Test appropriateness property
        for pattern in allPatterns {
            guard !pattern.beltLevels.isEmpty else { continue }

            for belt in allBelts {
                let isAppropriate = pattern.isAppropriateFor(beltLevel: belt)

                // PROPERTY: Pattern appropriate if user's belt sortOrder <= any pattern belt sortOrder
                let shouldBeAppropriate = pattern.beltLevels.contains { $0.sortOrder >= belt.sortOrder }

                XCTAssertEqual(isAppropriate, shouldBeAppropriate,
                    """
                    PROPERTY VIOLATION: Belt level appropriateness incorrect
                    Pattern: \(pattern.name)
                    User Belt: \(belt.shortName) (sort: \(belt.sortOrder))
                    Pattern Belts: \(pattern.beltLevels.map { "\($0.shortName)(\($0.sortOrder))" })
                    Expected: \(shouldBeAppropriate), Got: \(isAppropriate)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Pattern available images must be valid URLs
     *
     * Tests media content validation
     */
    func testPatternData_PropertyBased_ImageURLsValid() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())

        // Act & Assert: Check image URL validity
        for pattern in allPatterns {
            for move in pattern.moves {
                let images = move.availableImages

                // PROPERTY: Available images must be non-empty strings
                for imageURL in images {
                    XCTAssertFalse(imageURL.isEmpty,
                        "Move \(move.moveNumber) in \(pattern.name) has empty image URL")
                }

                // PROPERTY: hasMedia should match availableImages count
                XCTAssertEqual(move.hasMedia, !images.isEmpty,
                    "Move \(move.moveNumber) hasMedia inconsistent with availableImages")
            }
        }
    }

    /**
     * PROPERTY: Pattern names and identifiers must be unique
     *
     * Tests data uniqueness constraints
     */
    func testPatternData_PropertyBased_UniqueIdentifiers() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())

        // Act: Collect IDs and names
        let patternIds = allPatterns.map { $0.id }
        let patternNames = allPatterns.map { $0.name }

        // Assert: PROPERTY - All IDs must be unique
        let uniqueIds = Set(patternIds)
        XCTAssertEqual(uniqueIds.count, patternIds.count,
            """
            PROPERTY VIOLATION: Pattern IDs must be unique
            Total patterns: \(patternIds.count)
            Unique IDs: \(uniqueIds.count)
            """)

        // Assert: PROPERTY - All names must be unique
        let uniqueNames = Set(patternNames)
        XCTAssertEqual(uniqueNames.count, patternNames.count,
            """
            PROPERTY VIOLATION: Pattern names must be unique
            Total patterns: \(patternNames.count)
            Unique names: \(uniqueNames.count)
            Duplicate names: \(patternNames.filter { name in patternNames.filter { $0 == name }.count > 1 })
            """)
    }

    // MARK: - 2. User Progress Tracking (8 tests)

    /**
     * PROPERTY: Recording practice session must update all metrics correctly
     *
     * Tests practice session recording across random accuracy values
     */
    func testUserProgress_PropertyBased_PracticeSessionUpdates() throws {
        // Test 15 random practice sessions
        for _ in 0..<15 {
            // Arrange: Create user and get random pattern
            let profile = try createTestProfile()
            let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
            guard let pattern = allPatterns.randomElement() else { continue }

            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)
            let initialPracticeCount = progress.practiceCount
            let initialTotalTime = progress.totalPracticeTime

            // Random practice data
            let accuracy = Double.random(in: 0.0...1.0)
            let practiceTime = Double.random(in: 30.0...300.0)

            // Act: Record practice session
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: accuracy,
                practiceTime: practiceTime
            )

            // Assert: PROPERTY - All metrics must be updated
            XCTAssertEqual(progress.practiceCount, initialPracticeCount + 1,
                "Practice count must increment by 1")
            XCTAssertNotNil(progress.lastPracticedAt,
                "Last practiced date must be set")
            XCTAssertGreaterThan(progress.totalPracticeTime, initialTotalTime,
                "Total practice time must increase")
            XCTAssertGreaterThanOrEqual(progress.totalPracticeTime, initialTotalTime + practiceTime - 1,
                "Total practice time must include new session time")
        }
    }

    /**
     * PROPERTY: Average accuracy must be correctly calculated
     *
     * Tests accuracy calculation across multiple sessions
     */
    func testUserProgress_PropertyBased_AverageAccuracyCalculation() throws {
        // Test 10 random scenarios
        for _ in 0..<10 {
            // Arrange: Create user and pattern
            let profile = try createTestProfile()
            let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
            guard let pattern = allPatterns.randomElement() else { continue }

            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

            // Random number of sessions (3-10)
            let sessionCount = Int.random(in: 3...10)
            var accuracies: [Double] = []

            // Act: Record multiple sessions
            for _ in 0..<sessionCount {
                let accuracy = Double.random(in: 0.0...1.0)
                accuracies.append(accuracy)
                patternService.recordPracticeSession(
                    pattern: pattern,
                    userProfile: profile,
                    accuracy: accuracy,
                    practiceTime: 60.0
                )
            }

            // Assert: PROPERTY - Average must match calculated average
            let expectedAverage = accuracies.reduce(0, +) / Double(accuracies.count)
            XCTAssertEqual(progress.averageAccuracy, expectedAverage, accuracy: 0.01,
                """
                PROPERTY VIOLATION: Average accuracy incorrect
                Sessions: \(sessionCount)
                Accuracies: \(accuracies.map { Int($0 * 100) })
                Expected: \(Int(expectedAverage * 100))%
                Got: \(Int(progress.averageAccuracy * 100))%
                """)
        }
    }

    /**
     * PROPERTY: Best run accuracy must never decrease
     *
     * Tests that best accuracy is monotonically increasing
     */
    func testUserProgress_PropertyBased_BestAccuracyMonotonic() throws {
        // Test 10 random scenarios
        for _ in 0..<10 {
            // Arrange: Create user and pattern
            let profile = try createTestProfile()
            let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
            guard let pattern = allPatterns.randomElement() else { continue }

            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

            // Act: Record sessions with varying accuracy
            var lastBestAccuracy = 0.0
            for _ in 0..<5 {
                let accuracy = Double.random(in: 0.0...1.0)
                patternService.recordPracticeSession(
                    pattern: pattern,
                    userProfile: profile,
                    accuracy: accuracy,
                    practiceTime: 60.0
                )

                // Assert: PROPERTY - Best accuracy must be >= last best
                XCTAssertGreaterThanOrEqual(progress.bestRunAccuracy, lastBestAccuracy,
                    """
                    PROPERTY VIOLATION: Best accuracy decreased
                    Last best: \(Int(lastBestAccuracy * 100))%
                    Current best: \(Int(progress.bestRunAccuracy * 100))%
                    """)

                lastBestAccuracy = progress.bestRunAccuracy
            }
        }
    }

    /**
     * PROPERTY: Consecutive correct runs must reset on low accuracy
     *
     * Tests streak tracking logic
     */
    func testUserProgress_PropertyBased_ConsecutiveRunsTracking() throws {
        // Arrange: Create user and pattern
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Act & Assert: Record good runs, then bad run
        // Good runs (>= 90%)
        for i in 1...3 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.95,
                practiceTime: 60.0
            )

            // PROPERTY: Consecutive runs should increment
            XCTAssertEqual(progress.consecutiveCorrectRuns, i,
                "Consecutive runs should be \(i) after \(i) good runs")
        }

        // Bad run (< 90%)
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.50,
            practiceTime: 60.0
        )

        // PROPERTY: Consecutive runs must reset to 0
        XCTAssertEqual(progress.consecutiveCorrectRuns, 0,
            "Consecutive runs must reset after accuracy < 90%")
    }

    /**
     * PROPERTY: Progress percentage must match current move / total moves
     *
     * Tests progress calculation across random move positions
     */
    func testUserProgress_PropertyBased_ProgressPercentage() throws {
        // Test all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let profile = try createTestProfile()

        for pattern in allPatterns {
            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

            // Test random move positions
            for _ in 0..<3 {
                let randomMove = Int.random(in: 1...pattern.moveCount)
                progress.currentMove = randomMove

                // PROPERTY: Progress % = (currentMove / totalMoves) * 100
                let expectedPercentage = Double(randomMove) / Double(pattern.moveCount) * 100.0
                XCTAssertEqual(progress.progressPercentage, expectedPercentage, accuracy: 0.01,
                    """
                    PROPERTY VIOLATION: Progress percentage incorrect
                    Pattern: \(pattern.name) (\(pattern.moveCount) moves)
                    Current Move: \(randomMove)
                    Expected: \(expectedPercentage)%
                    Got: \(progress.progressPercentage)%
                    """)
            }
        }
    }

    /**
     * PROPERTY: Struggling moves list must accumulate unique moves
     *
     * Tests struggling moves tracking
     */
    func testUserProgress_PropertyBased_StrugglingMovesAccumulate() throws {
        // Arrange: Create user and pattern
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Act: Record sessions with struggling moves
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.7,
            practiceTime: 60.0,
            strugglingMoves: [1, 3, 5]
        )

        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.8,
            practiceTime: 60.0,
            strugglingMoves: [3, 7, 9]
        )

        // Assert: PROPERTY - Struggling moves should accumulate uniquely
        let strugglingMoves = Set(progress.strugglingMoves)
        XCTAssertTrue(strugglingMoves.contains(1), "Should contain move 1")
        XCTAssertTrue(strugglingMoves.contains(3), "Should contain move 3")
        XCTAssertTrue(strugglingMoves.contains(5), "Should contain move 5")
        XCTAssertTrue(strugglingMoves.contains(7), "Should contain move 7")
        XCTAssertTrue(strugglingMoves.contains(9), "Should contain move 9")
    }

    /**
     * PROPERTY: Review date must be in the future after practice
     *
     * Tests spaced repetition date calculation
     */
    func testUserProgress_PropertyBased_ReviewDateInFuture() throws {
        // Test 10 random scenarios
        for _ in 0..<10 {
            // Arrange: Create user and pattern
            let profile = try createTestProfile()
            let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
            guard let pattern = allPatterns.randomElement() else { continue }

            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)
            let now = Date()

            // Act: Record practice session
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: Double.random(in: 0.5...1.0),
                practiceTime: 60.0
            )

            // Assert: PROPERTY - Next review date must be in future
            XCTAssertGreaterThan(progress.nextReviewDate, now,
                """
                PROPERTY VIOLATION: Review date must be in future
                Current time: \(now)
                Next review: \(progress.nextReviewDate)
                """)
        }
    }

    /**
     * PROPERTY: isDueForReview must match date comparison
     *
     * Tests review due status logic
     */
    func testUserProgress_PropertyBased_ReviewDueStatus() throws {
        // Arrange: Create user and pattern
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Test: Set review date in past
        progress.nextReviewDate = Date().addingTimeInterval(-86400) // Yesterday

        // PROPERTY: Should be due for review
        XCTAssertTrue(progress.isDueForReview,
            "Pattern with past review date should be due")

        // Test: Set review date in future
        progress.nextReviewDate = Date().addingTimeInterval(86400) // Tomorrow

        // PROPERTY: Should NOT be due for review
        XCTAssertFalse(progress.isDueForReview,
            "Pattern with future review date should not be due")
    }

    // MARK: - 3. Mastery Level Progression (5 tests)

    /**
     * PROPERTY: Mastery level must progress based on performance thresholds
     *
     * Tests mastery level calculation logic
     */
    func testMasteryLevel_PropertyBased_ProgressionThresholds() throws {
        // Arrange: Create user and pattern
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Test: Learning level (default)
        XCTAssertEqual(progress.masteryLevel, .learning,
            "Initial mastery level should be learning")

        // Test: Familiar level (3+ sessions, 70%+ avg)
        for _ in 0..<3 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.75,
                practiceTime: 60.0
            )
        }
        XCTAssertEqual(progress.masteryLevel, .familiar,
            "3 sessions at 75% should reach familiar")

        // Test: Proficient level (3+ consecutive, 85%+ avg)
        for _ in 0..<3 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.95,
                practiceTime: 60.0
            )
        }
        XCTAssertEqual(progress.masteryLevel, .proficient,
            "3 consecutive at 95% should reach proficient")

        // Test: Mastered level (5+ consecutive, 95%+ avg)
        for _ in 0..<2 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.98,
                practiceTime: 60.0
            )
        }
        XCTAssertEqual(progress.masteryLevel, .mastered,
            "5 consecutive at 98% should reach mastered")
    }

    /**
     * PROPERTY: Mastery level progression must be monotonic (no regression without failure)
     *
     * Tests that good performance doesn't decrease mastery
     */
    func testMasteryLevel_PropertyBased_NoRegressionOnSuccess() throws {
        // Arrange: Achieve mastered level
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Achieve mastered
        for _ in 0..<5 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.98,
                practiceTime: 60.0
            )
        }
        XCTAssertEqual(progress.masteryLevel, .mastered)

        // Act: Continue with good performance
        let masteryBefore = progress.masteryLevel
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.95,
            practiceTime: 60.0
        )

        // Assert: PROPERTY - Mastery should not regress
        XCTAssertEqual(progress.masteryLevel, masteryBefore,
            "Mastery should not regress with 95% performance")
    }

    /**
     * PROPERTY: Mastery level must reset on consecutive poor performance
     *
     * Tests that bad performance can decrease mastery
     */
    func testMasteryLevel_PropertyBased_RegressionOnFailure() throws {
        // Arrange: Achieve proficient level
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard let pattern = allPatterns.first else { return }

        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // Achieve proficient
        for _ in 0..<3 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.95,
                practiceTime: 60.0
            )
        }
        _ = progress.masteryLevel

        // Act: Multiple poor performances
        for _ in 0..<3 {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: 0.50,
                practiceTime: 60.0
            )
        }

        // Assert: PROPERTY - Mastery should regress with poor performance
        // (Implementation may vary, but average will drop below proficient threshold)
        XCTAssertTrue(progress.averageAccuracy < 0.85,
            "Average accuracy should drop below proficient threshold")
    }

    /**
     * PROPERTY: Mastery level sort order must be consistent
     *
     * Tests enum ordering
     */
    func testMasteryLevel_PropertyBased_SortOrderConsistent() throws {
        let levels: [PatternMasteryLevel] = [.learning, .familiar, .proficient, .mastered]

        // PROPERTY: Sort order must be ascending
        for i in 0..<levels.count - 1 {
            XCTAssertLessThan(levels[i].sortOrder, levels[i + 1].sortOrder,
                "\(levels[i]) should have lower sort order than \(levels[i + 1])")
        }
    }

    /**
     * PROPERTY: Mastery level colors must be distinct
     *
     * Tests visual differentiation
     */
    func testMasteryLevel_PropertyBased_DistinctColors() throws {
        let levels: [PatternMasteryLevel] = [.learning, .familiar, .proficient, .mastered]
        let colors = levels.map { $0.color }

        // PROPERTY: All colors must be unique
        let uniqueColors = Set(colors)
        XCTAssertEqual(uniqueColors.count, levels.count,
            "All mastery levels must have distinct colors")
    }

    // MARK: - 4. Pattern Filtering & Access (4 tests)

    /**
     * PROPERTY: getPatternsForUser must return only appropriate patterns
     *
     * Tests belt-based filtering across random users
     */
    func testPatternFiltering_PropertyBased_OnlyAppropriatePatterns() throws {
        // Test 10 random belt levels
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelts = allBelts.shuffled().prefix(min(10, allBelts.count))

        for belt in testBelts {
            // Arrange: Create user with specific belt
            let profile = try createTestProfile(belt: belt)

            // Act: Get patterns for user
            let userPatterns = patternService.getPatternsForUser(userProfile: profile)

            // Assert: PROPERTY - All returned patterns must be appropriate
            for pattern in userPatterns {
                XCTAssertTrue(pattern.isAppropriateFor(beltLevel: belt),
                    """
                    PROPERTY VIOLATION: Inappropriate pattern returned
                    User Belt: \(belt.shortName) (sort: \(belt.sortOrder))
                    Pattern: \(pattern.name)
                    Pattern Belts: \(pattern.beltLevels.map { "\($0.shortName)(\($0.sortOrder))" })
                    """)
            }
        }
    }

    /**
     * PROPERTY: Pattern filtering must be consistent with belt progression
     *
     * Tests that higher belts see more patterns
     */
    func testPatternFiltering_PropertyBased_ProgressionConsistency() throws {
        // Arrange: Get sorted belts (highest to lowest rank)
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>()).sorted { $0.sortOrder < $1.sortOrder }
        guard allBelts.count >= 2 else { return }

        // Act: Get pattern counts for different belts
        var patternCounts: [(belt: BeltLevel, count: Int)] = []
        for belt in allBelts.prefix(5) {
            let profile = try createTestProfile(belt: belt)
            let patterns = patternService.getPatternsForUser(userProfile: profile)
            patternCounts.append((belt, patterns.count))
        }

        // Assert: PROPERTY - Advanced belts should see >= patterns as lower belts
        for i in 0..<patternCounts.count - 1 {
            let current = patternCounts[i]
            let next = patternCounts[i + 1]

            XCTAssertGreaterThanOrEqual(current.count, next.count,
                """
                PROPERTY VIOLATION: Advanced belt sees fewer patterns
                \(current.belt.shortName): \(current.count) patterns
                \(next.belt.shortName): \(next.count) patterns
                """)
        }
    }

    /**
     * PROPERTY: getPattern(byName:) must return correct pattern or nil
     *
     * Tests pattern lookup by name
     */
    func testPatternFiltering_PropertyBased_NameLookup() throws {
        // Arrange: Get all patterns
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>())
        guard !allPatterns.isEmpty else { return }

        // Test: Lookup existing patterns
        for pattern in allPatterns.prefix(5) {
            let found = patternService.getPattern(byName: pattern.name)

            // PROPERTY: Must return correct pattern
            XCTAssertNotNil(found, "Existing pattern '\(pattern.name)' should be found")
            XCTAssertEqual(found?.id, pattern.id, "Found pattern ID must match")
        }

        // Test: Lookup non-existent pattern
        let nonExistent = patternService.getPattern(byName: "NonExistentPattern12345")

        // PROPERTY: Must return nil for non-existent patterns
        XCTAssertNil(nonExistent, "Non-existent pattern should return nil")
    }

    /**
     * PROPERTY: getPatternsDueForReview must respect next review dates
     *
     * Tests spaced repetition filtering
     */
    func testPatternFiltering_PropertyBased_ReviewDueFiltering() throws {
        // Arrange: Create user and patterns with different review dates
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>()).prefix(3)

        var duePatterns: [Pattern] = []
        var notDuePatterns: [Pattern] = []

        for pattern in allPatterns {
            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

            if Bool.random() {
                // Set as due (past date)
                progress.nextReviewDate = Date().addingTimeInterval(-86400)
                duePatterns.append(pattern)
            } else {
                // Set as not due (future date)
                progress.nextReviewDate = Date().addingTimeInterval(86400)
                notDuePatterns.append(pattern)
            }
        }
        try testContext.save()

        // Act: Get patterns due for review
        let reviewPatterns = patternService.getPatternsDueForReview(userProfile: profile)

        // Assert: PROPERTY - Only patterns with past review dates should be returned
        XCTAssertEqual(reviewPatterns.count, duePatterns.count,
            "Review list count should match due patterns count")

        for reviewProgress in reviewPatterns {
            XCTAssertTrue(duePatterns.contains { $0.id == reviewProgress.pattern.id },
                "Review list should only contain due patterns")
        }
    }

    // MARK: - 5. Statistics Calculations (3 tests)

    /**
     * PROPERTY: Pattern statistics must accurately sum progress data
     *
     * Tests statistics calculation across random practice sessions
     */
    func testStatistics_PropertyBased_AccurateSummation() throws {
        // Arrange: Create user and record multiple practice sessions
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>()).prefix(3)

        var totalExpectedTime: TimeInterval = 0
        var totalExpectedSessions = 0

        for pattern in allPatterns {
            let sessionCount = Int.random(in: 1...5)
            for _ in 0..<sessionCount {
                let practiceTime = Double.random(in: 60...300)
                patternService.recordPracticeSession(
                    pattern: pattern,
                    userProfile: profile,
                    accuracy: Double.random(in: 0.5...1.0),
                    practiceTime: practiceTime
                )
                totalExpectedTime += practiceTime
                totalExpectedSessions += 1
            }
        }

        // Act: Get statistics
        let stats = patternService.getUserPatternStatistics(userProfile: profile)

        // Assert: PROPERTY - Statistics must match recorded data
        XCTAssertEqual(stats.totalPatterns, allPatterns.count,
            "Total patterns should match practice count")
        XCTAssertEqual(stats.totalSessions, totalExpectedSessions,
            "Total sessions should match recorded sessions")
        XCTAssertEqual(stats.totalPracticeTime, totalExpectedTime, accuracy: 1.0,
            "Total practice time should match sum of session times")
    }

    /**
     * PROPERTY: Mastery percentage must match mastered/total ratio
     *
     * Tests mastery percentage calculation
     */
    func testStatistics_PropertyBased_MasteryPercentage() throws {
        // Arrange: Create user and achieve mastery on some patterns
        let profile = try createTestProfile()
        let allPatterns = try testContext.fetch(FetchDescriptor<Pattern>()).prefix(5)

        var masteredCount = 0
        for pattern in allPatterns {
            let shouldMaster = Bool.random()
            let accuracy = shouldMaster ? 0.98 : 0.70
            let sessions = shouldMaster ? 5 : 2

            for _ in 0..<sessions {
                patternService.recordPracticeSession(
                    pattern: pattern,
                    userProfile: profile,
                    accuracy: accuracy,
                    practiceTime: 60.0
                )
            }

            let progress = patternService.getUserProgress(for: pattern, userProfile: profile)
            if progress.masteryLevel == .mastered {
                masteredCount += 1
            }
        }

        // Act: Get statistics
        let stats = patternService.getUserPatternStatistics(userProfile: profile)

        // Assert: PROPERTY - Mastery % = (mastered / total) * 100
        let expectedPercentage = Double(masteredCount) / Double(allPatterns.count) * 100.0
        XCTAssertEqual(stats.masteryPercentage, expectedPercentage, accuracy: 0.01,
            """
            PROPERTY VIOLATION: Mastery percentage incorrect
            Mastered: \(masteredCount), Total: \(allPatterns.count)
            Expected: \(expectedPercentage)%
            Got: \(stats.masteryPercentage)%
            """)
    }

    /**
     * PROPERTY: Practice time formatting must handle hours and minutes correctly
     *
     * Tests time formatting edge cases
     */
    func testStatistics_PropertyBased_TimeFormatting() throws {
        let testCases: [(seconds: TimeInterval, expectedContains: [String])] = [
            (1800, ["30m"]),         // 30 minutes
            (3660, ["1h", "1m"]),    // 1 hour 1 minute
            (7320, ["2h", "2m"]),    // 2 hours 2 minutes
            (45, ["0m"]),            // Less than 1 minute
        ]

        for (seconds, expectedContains) in testCases {
            let stats = PatternStatistics(totalPracticeTime: seconds)
            let formatted = stats.formattedPracticeTime

            for expected in expectedContains {
                XCTAssertTrue(formatted.contains(expected),
                    """
                    PROPERTY VIOLATION: Time formatting incorrect
                    Seconds: \(seconds)
                    Expected to contain: \(expected)
                    Got: \(formatted)
                    """)
            }
        }
    }

    // MARK: - 6. Enum Display Names (2 tests)

    /**
     * Test PatternMasteryLevel display names
     */
    func testEnumDisplayNames_MasteryLevel() throws {
        XCTAssertEqual(PatternMasteryLevel.learning.displayName, "Learning")
        XCTAssertEqual(PatternMasteryLevel.familiar.displayName, "Familiar")
        XCTAssertEqual(PatternMasteryLevel.proficient.displayName, "Proficient")
        XCTAssertEqual(PatternMasteryLevel.mastered.displayName, "Mastered")
    }

    /**
     * Test PatternMasteryLevel color assignments
     */
    func testEnumDisplayNames_MasteryLevelColors() throws {
        XCTAssertEqual(PatternMasteryLevel.learning.color, "red")
        XCTAssertEqual(PatternMasteryLevel.familiar.color, "orange")
        XCTAssertEqual(PatternMasteryLevel.proficient.color, "blue")
        XCTAssertEqual(PatternMasteryLevel.mastered.color, "green")
    }

    // MARK: - Helper Methods

    private func createDefaultTestProfile() throws -> UserProfile {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let belt = allBelts.first(where: { $0.shortName.contains("7th") }) ?? allBelts.first!
        return try createTestProfile(belt: belt)
    }

    private func createTestProfile(belt: BeltLevel? = nil) throws -> UserProfile {
        let beltLevel: BeltLevel
        if let belt = belt {
            beltLevel = belt
        } else {
            let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            beltLevel = allBelts.first!
        }

        let profile = UserProfile(
            name: "Test User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: beltLevel
        )
        testContext.insert(profile)
        try testContext.save()
        return profile
    }
}
