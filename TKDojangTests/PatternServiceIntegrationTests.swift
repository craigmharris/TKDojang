import XCTest
import SwiftData
@testable import TKDojang

/**
 * PatternServiceIntegrationTests.swift
 *
 * PURPOSE: Service orchestration tests for pattern feature integration
 *
 * ARCHITECTURAL APPROACH (Phase 2 Breakthrough):
 * Tests service layer integration, NOT view rendering. In SwiftUI MVVM-C,
 * integration happens at the SERVICE layer where multiple services coordinate.
 *
 * INTEGRATION LAYERS TESTED:
 * 1. PatternDataService → Pattern/PatternMove persistence
 * 2. Pattern selection → Belt level filtering orchestration
 * 3. Practice session recording → UserPatternProgress updates
 * 4. Mastery level progression → Review date calculation
 * 5. Multi-profile data isolation
 * 6. Statistics aggregation across patterns
 *
 * WHY SERVICE ORCHESTRATION:
 * - Pattern bugs occur in service coordination, not SwiftUI view rendering
 * - Testing pattern selection, progress tracking, and mastery progression validates core logic
 * - Service tests are faster, more reliable, and easier to debug than ViewInspector
 * - Property-based approach ensures correctness across randomized states
 *
 * Test coverage: 6 integration tests validating pattern service orchestration
 */

@MainActor
final class PatternServiceIntegrationTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var patternService: PatternDataService!
    var profileService: ProfileService!
    var dataFactory: TestDataFactory!
    var testBelts: [BeltLevel] = []

    override func setUp() async throws {
        // Use TestContainerFactory for consistent test infrastructure
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext

        // Initialize services
        patternService = PatternDataService(modelContext: testContext)
        profileService = ProfileService(modelContext: testContext)

        // Setup test data using TestDataFactory
        dataFactory = TestDataFactory()
        testBelts = dataFactory.createBasicBeltLevels()

        // Insert belt levels
        for belt in testBelts {
            testContext.insert(belt)
        }

        try testContext.save()

        // Load test pattern data
        try await loadTestPatternData()
    }

    override func tearDown() {
        testContext = nil
        testContainer = nil
        patternService = nil
        profileService = nil
        dataFactory = nil
        testBelts = []
    }

    // MARK: - Helper Methods

    private func getBeltByKeup(_ keup: Int) -> BeltLevel? {
        // Match by shortName for reliability (TestDataFactory creates belts with full names like "10th Keup (White Belt)")
        let shortName: String
        if keup == 3 {
            shortName = "3rd Keup"
        } else if keup == 2 {
            shortName = "2nd Keup"
        } else if keup == 1 {
            shortName = "1st Keup"
        } else {
            shortName = "\(keup)th Keup"
        }
        return testBelts.first { $0.shortName == shortName }
    }

    // MARK: - Test Data Loading

    private func loadTestPatternData() async throws {
        // Create test patterns (simplified versions) using dynamic belt references
        guard let belt10 = getBeltByKeup(10),
              let belt9 = getBeltByKeup(9),
              let belt8 = getBeltByKeup(8),
              let belt7 = getBeltByKeup(7),
              let belt6 = getBeltByKeup(6) else {
            XCTFail("Required belt levels not available")
            return
        }

        let chonJi = createTestPattern(
            name: "Chon-Ji",
            hangul: "천지",
            englishMeaning: "Heaven and Earth",
            moveCount: 19,
            beltLevels: [belt10],
            moveNumbers: Array(1...19)
        )

        let danGun = createTestPattern(
            name: "Dan-Gun",
            hangul: "단군",
            englishMeaning: "Holy Dan-Gun",
            moveCount: 21,
            beltLevels: [belt9],
            moveNumbers: Array(1...21)
        )

        let doSan = createTestPattern(
            name: "Do-San",
            hangul: "도산",
            englishMeaning: "Patriot Ahn Chang-Ho",
            moveCount: 24,
            beltLevels: [belt8],
            moveNumbers: Array(1...24)
        )

        let wonHyo = createTestPattern(
            name: "Won-Hyo",
            hangul: "원효",
            englishMeaning: "Monk Won-Hyo",
            moveCount: 28,
            beltLevels: [belt7],
            moveNumbers: Array(1...28)
        )

        let yulGok = createTestPattern(
            name: "Yul-Gok",
            hangul: "율곡",
            englishMeaning: "Scholar Yul-Gok",
            moveCount: 38,
            beltLevels: [belt6],
            moveNumbers: Array(1...38)
        )

        // Insert patterns
        for pattern in [chonJi, danGun, doSan, wonHyo, yulGok] {
            patternService.insertPattern(pattern)
        }

        try patternService.saveContext()
    }

    private func createTestPattern(
        name: String,
        hangul: String,
        englishMeaning: String,
        moveCount: Int,
        beltLevels: [BeltLevel],
        moveNumbers: [Int]
    ) -> Pattern {
        let pattern = Pattern(
            name: name,
            hangul: hangul,
            englishMeaning: englishMeaning,
            significance: "Test pattern for \(name)",
            moveCount: moveCount,
            diagramDescription: "Diagram for \(name)",
            startingStance: "Narani junbi sogi"
        )

        pattern.beltLevels = beltLevels

        // Create moves
        for moveNum in moveNumbers {
            let move = PatternMove(
                moveNumber: moveNum,
                stance: "Walking stance",
                technique: "Middle section punch",
                direction: "Forward",
                keyPoints: "Key points for move \(moveNum)"
            )
            move.pattern = pattern
            pattern.moves.append(move)
        }

        return pattern
    }

    private func createTestProfile(
        name: String,
        beltLevel: BeltLevel
    ) throws -> UserProfile {
        return try profileService.createProfile(
            name: name,
            avatar: .student1,
            colorTheme: .blue,
            beltLevel: beltLevel
        )
    }

    // MARK: - Integration Tests

    // MARK: Test 1: Pattern Selection to Belt Filtering Flow

    /**
     * INTEGRATION VALIDATED:
     * - PatternDataService.getPatternsForUser() filters by belt level
     * - Belt level appropriateness logic (current + prior belts)
     * - Pattern sorting by belt progression
     * - Advanced belts see more patterns than beginners
     */
    func testPatternSelectionToBeltFilteringFlow() throws {
        // ARRANGE: Create profiles at different belt levels
        guard let belt10 = getBeltByKeup(10) else {
            XCTFail("10th keup not available")
            return
        }
        guard let belt8 = getBeltByKeup(8) else {
            XCTFail("8th keup not available")
            return
        }
        guard let belt6 = getBeltByKeup(6) else {
            XCTFail("6th keup not available")
            return
        }

        let beginnerProfile = try createTestProfile(
            name: "Beginner",
            beltLevel: belt10
        )

        let intermediateProfile = try createTestProfile(
            name: "Intermediate",
            beltLevel: belt8
        )

        let advancedProfile = try createTestProfile(
            name: "Advanced",
            beltLevel: belt6
        )

        // ACT: Get patterns for each profile
        let beginnerPatterns = patternService.getPatternsForUser(userProfile: beginnerProfile)
        let intermediatePatterns = patternService.getPatternsForUser(userProfile: intermediateProfile)
        let advancedPatterns = patternService.getPatternsForUser(userProfile: advancedProfile)

        // ASSERT: Pattern count progression
        // PROPERTY: Beginner sees fewest patterns
        XCTAssertGreaterThan(
            beginnerPatterns.count,
            0,
            "Beginner should see at least 1 pattern"
        )

        // PROPERTY: Intermediate sees more than beginner
        XCTAssertGreaterThanOrEqual(
            intermediatePatterns.count,
            beginnerPatterns.count,
            "Intermediate should see same or more patterns than beginner"
        )

        // PROPERTY: Advanced sees most patterns
        XCTAssertGreaterThanOrEqual(
            advancedPatterns.count,
            intermediatePatterns.count,
            "Advanced should see same or more patterns than intermediate"
        )

        // PROPERTY: Advanced sees all 5 test patterns
        XCTAssertEqual(
            advancedPatterns.count,
            5,
            "Advanced (6th keup) should see all 5 test patterns"
        )

        // PROPERTY: Patterns are sorted by belt progression
        let sortedByBelt = advancedPatterns.allSatisfy { pattern in
            if let index = advancedPatterns.firstIndex(where: { $0.id == pattern.id }),
               index < advancedPatterns.count - 1 {
                let current = pattern.primaryBeltLevel?.sortOrder ?? 0
                let next = advancedPatterns[index + 1].primaryBeltLevel?.sortOrder ?? 0
                return current >= next  // Higher sort order first (9th keup before 8th keup)
            }
            return true
        }

        XCTAssertTrue(
            sortedByBelt,
            "Patterns should be sorted by belt progression"
        )

        // PROPERTY: All patterns appropriate for user's belt level
        XCTAssertTrue(
            advancedPatterns.allSatisfy { $0.isAppropriateFor(beltLevel: advancedProfile.currentBeltLevel) },
            "All returned patterns should be appropriate for user's belt level"
        )
    }

    // MARK: Test 2: Practice Session to Progress Tracking Flow

    /**
     * INTEGRATION VALIDATED:
     * - PatternDataService.recordPracticeSession() → UserPatternProgress updates
     * - Progress metrics tracked (accuracy, practice count, time)
     * - Struggling moves accumulated
     * - Review date calculated based on performance
     */
    func testPracticeSessionToProgressTrackingFlow() throws {
        // ARRANGE: Create profile and get pattern
        guard let belt10 = getBeltByKeup(10) else {
            XCTFail("10th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Practitioner",
            beltLevel: belt10
        )

        let patterns = patternService.getPatternsForUser(userProfile: profile)
        XCTAssertGreaterThan(patterns.count, 0, "Should have patterns for testing")

        let pattern = patterns[0]

        // Get initial progress
        let initialProgress = patternService.getUserProgress(for: pattern, userProfile: profile)
        let initialPracticeCount = initialProgress.practiceCount
        let initialTotalTime = initialProgress.totalPracticeTime

        // ACT: Record practice session
        let accuracy1 = 0.75  // 75%
        let practiceTime1 = 300.0  // 5 minutes
        let strugglingMoves1 = [3, 7, 12]

        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: accuracy1,
            practiceTime: practiceTime1,
            strugglingMoves: strugglingMoves1
        )

        // ASSERT: Progress updated
        let progressAfterSession1 = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Practice count incremented
        XCTAssertEqual(
            progressAfterSession1.practiceCount,
            initialPracticeCount + 1,
            "Practice count should increment by 1"
        )

        // PROPERTY: Total practice time accumulated
        XCTAssertEqual(
            progressAfterSession1.totalPracticeTime,
            initialTotalTime + practiceTime1,
            accuracy: 0.1,
            "Total practice time should accumulate"
        )

        // PROPERTY: Average accuracy recorded
        XCTAssertGreaterThan(
            progressAfterSession1.averageAccuracy,
            0.0,
            "Average accuracy should be recorded"
        )

        // PROPERTY: Best run accuracy tracked
        XCTAssertGreaterThanOrEqual(
            progressAfterSession1.bestRunAccuracy,
            accuracy1,
            "Best run accuracy should be at least current accuracy"
        )

        // PROPERTY: Struggling moves accumulated
        XCTAssertFalse(
            progressAfterSession1.strugglingMoves.isEmpty,
            "Struggling moves should be recorded"
        )

        XCTAssertTrue(
            Set(strugglingMoves1).isSubset(of: Set(progressAfterSession1.strugglingMoves)),
            "Struggling moves should include recorded moves"
        )

        // PROPERTY: Last practiced date updated
        XCTAssertNotNil(
            progressAfterSession1.lastPracticedAt,
            "Last practiced date should be set"
        )

        // ACT: Record another practice session with better accuracy
        let accuracy2 = 0.92  // 92%
        let practiceTime2 = 280.0
        let strugglingMoves2 = [7]

        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: accuracy2,
            practiceTime: practiceTime2,
            strugglingMoves: strugglingMoves2
        )

        let progressAfterSession2 = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Best run accuracy increases
        XCTAssertGreaterThanOrEqual(
            progressAfterSession2.bestRunAccuracy,
            accuracy2,
            "Best run should update to higher accuracy"
        )

        // PROPERTY: Consecutive correct runs tracked
        XCTAssertGreaterThan(
            progressAfterSession2.consecutiveCorrectRuns,
            0,
            "Consecutive correct runs should be tracked for high accuracy"
        )
    }

    // MARK: Test 3: Mastery Level Progression Flow

    /**
     * INTEGRATION VALIDATED:
     * - Mastery level progression based on performance
     * - Learning → Familiar → Proficient → Mastered transitions
     * - Review date calculation changes with mastery level
     * - Consecutive runs affect mastery level
     */
    func testMasteryLevelProgressionFlow() throws {
        // ARRANGE: Create profile and pattern
        guard let belt9 = getBeltByKeup(9) else {
            XCTFail("9th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Learner",
            beltLevel: belt9
        )

        let patterns = patternService.getPatternsForUser(userProfile: profile)
        XCTAssertGreaterThan(patterns.count, 0, "Should have patterns")

        let pattern = patterns[0]
        let progress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Initial mastery level is Learning
        XCTAssertEqual(
            progress.masteryLevel,
            PatternMasteryLevel.learning,
            "Initial mastery level should be Learning"
        )

        // ACT: Record practice sessions with increasing accuracy
        // NOTE: To reach "mastered", requires BOTH consecutiveCorrectRuns >= 5 AND averageAccuracy >= 0.95
        // These sessions achieve 95.3% overall average while demonstrating progression

        // Session 1: Initial learning (90% - good start)
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.90,
            practiceTime: 300
        )

        var currentProgress = patternService.getUserProgress(for: pattern, userProfile: profile)
        XCTAssertEqual(
            currentProgress.masteryLevel,
            PatternMasteryLevel.learning,
            "Should still be Learning after initial session"
        )

        // Session 2-3: Improving accuracy (should reach Familiar)
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.92,
            practiceTime: 300
        )

        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: 0.93,
            practiceTime: 300
        )

        currentProgress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Mastery level progresses to Familiar with consistent practice
        XCTAssertGreaterThanOrEqual(
            currentProgress.masteryLevel.sortOrder,
            PatternMasteryLevel.familiar.sortOrder,
            "Should reach Familiar after multiple sessions"
        )

        // Session 4-6: High accuracy (should reach Proficient)
        let proficientAccuracies = [0.95, 0.95, 0.96]
        for accuracy in proficientAccuracies {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: accuracy,
                practiceTime: 280
            )
        }

        currentProgress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Mastery level progresses with consistent high performance
        XCTAssertGreaterThanOrEqual(
            currentProgress.masteryLevel.sortOrder,
            PatternMasteryLevel.proficient.sortOrder,
            "Should reach Proficient with consistent high accuracy"
        )

        // Session 7-11: Excellent sustained accuracy (should reach Mastered)
        // These 5 sessions at 97%+ trigger consecutiveCorrectRuns >= 5
        // Combined with overall average of 95.3%, satisfies mastery requirements
        let masteredAccuracies = [0.97, 0.97, 0.97, 0.98, 0.98]
        for accuracy in masteredAccuracies {
            patternService.recordPracticeSession(
                pattern: pattern,
                userProfile: profile,
                accuracy: accuracy,
                practiceTime: 260
            )
        }

        currentProgress = patternService.getUserProgress(for: pattern, userProfile: profile)

        // PROPERTY: Mastery level reaches maximum with excellent performance
        XCTAssertEqual(
            currentProgress.masteryLevel,
            PatternMasteryLevel.mastered,
            "Should reach Mastered with excellent consecutive accuracy"
        )

        // PROPERTY: Review date is far in future for mastered patterns
        let daysSinceLastPractice = Date().timeIntervalSince(currentProgress.lastPracticedAt ?? Date())
        let daysUntilReview = currentProgress.nextReviewDate.timeIntervalSince(Date())

        XCTAssertGreaterThan(
            daysUntilReview,
            daysSinceLastPractice,
            "Review date should be in the future for mastered patterns"
        )
    }

    // MARK: Test 4: Multi-Profile Pattern Data Isolation

    /**
     * INTEGRATION VALIDATED:
     * - Pattern progress isolated per profile
     * - Practice sessions don't leak between profiles
     * - Mastery levels independent across profiles
     * - Statistics correctly filtered by profile
     */
    func testMultiProfilePatternDataIsolation() throws {
        // ARRANGE: Create two profiles
        guard let belt9 = getBeltByKeup(9) else {
            XCTFail("9th keup not available")
            return
        }

        let profile1 = try createTestProfile(
            name: "Student One",
            beltLevel: belt9
        )

        let profile2 = try createTestProfile(
            name: "Student Two",
            beltLevel: belt9
        )

        // Get same pattern for both profiles
        let patterns = patternService.getPatternsForUser(userProfile: profile1)
        XCTAssertGreaterThan(patterns.count, 0, "Should have patterns")

        let testPattern = patterns[0]

        // ACT: Profile 1 practices with medium performance
        patternService.recordPracticeSession(
            pattern: testPattern,
            userProfile: profile1,
            accuracy: 0.75,
            practiceTime: 300,
            strugglingMoves: [3, 7]
        )

        patternService.recordPracticeSession(
            pattern: testPattern,
            userProfile: profile1,
            accuracy: 0.78,
            practiceTime: 280,
            strugglingMoves: [7]
        )

        // ACT: Profile 2 practices with high performance
        patternService.recordPracticeSession(
            pattern: testPattern,
            userProfile: profile2,
            accuracy: 0.95,
            practiceTime: 250,
            strugglingMoves: []
        )

        patternService.recordPracticeSession(
            pattern: testPattern,
            userProfile: profile2,
            accuracy: 0.97,
            practiceTime: 240,
            strugglingMoves: []
        )

        // ASSERT: Progress data isolation

        let progress1 = patternService.getUserProgress(for: testPattern, userProfile: profile1)
        let progress2 = patternService.getUserProgress(for: testPattern, userProfile: profile2)

        // PROPERTY: Practice counts are independent
        XCTAssertEqual(
            progress1.practiceCount,
            2,
            "Profile 1 should have 2 practice sessions"
        )

        XCTAssertEqual(
            progress2.practiceCount,
            2,
            "Profile 2 should have 2 practice sessions"
        )

        // PROPERTY: Accuracy metrics are independent
        XCTAssertNotEqual(
            progress1.averageAccuracy,
            progress2.averageAccuracy,
            "Profiles should have different average accuracy"
        )

        XCTAssertLessThan(
            progress1.averageAccuracy,
            progress2.averageAccuracy,
            "Profile 1 should have lower accuracy than Profile 2"
        )

        // PROPERTY: Mastery levels are independent
        // Profile 2 has better performance, should have higher mastery
        XCTAssertGreaterThan(
            progress2.consecutiveCorrectRuns,
            progress1.consecutiveCorrectRuns,
            "Profile 2 should have more consecutive correct runs"
        )

        // PROPERTY: Struggling moves are independent
        XCTAssertFalse(
            progress1.strugglingMoves.isEmpty,
            "Profile 1 should have struggling moves"
        )

        XCTAssertTrue(
            progress2.strugglingMoves.isEmpty,
            "Profile 2 should have no struggling moves"
        )

        // PROPERTY: Statistics correctly filtered by profile
        let stats1 = patternService.getUserPatternStatistics(userProfile: profile1)
        let stats2 = patternService.getUserPatternStatistics(userProfile: profile2)

        XCTAssertEqual(
            stats1.totalSessions,
            2,
            "Profile 1 stats should show 2 sessions"
        )

        XCTAssertEqual(
            stats2.totalSessions,
            2,
            "Profile 2 stats should show 2 sessions"
        )

        XCTAssertNotEqual(
            stats1.averageAccuracy,
            stats2.averageAccuracy,
            "Profiles should have different overall accuracy"
        )
    }

    // MARK: Test 5: Statistics Aggregation Flow

    /**
     * INTEGRATION VALIDATED:
     * - PatternDataService.getUserPatternStatistics() aggregates correctly
     * - Total patterns, mastered patterns, sessions, time calculated
     * - Average accuracy computed across all patterns
     * - Mastery percentage reflects progression
     */
    func testStatisticsAggregationFlow() throws {
        // ARRANGE: Create profile
        guard let belt8 = getBeltByKeup(8) else {
            XCTFail("8th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Stats User",
            beltLevel: belt8
        )

        let patterns = patternService.getPatternsForUser(userProfile: profile)
        XCTAssertGreaterThanOrEqual(patterns.count, 2, "Should have at least 2 patterns")

        // Get initial statistics
        let initialStats = patternService.getUserPatternStatistics(userProfile: profile)
        XCTAssertEqual(
            initialStats.totalSessions,
            0,
            "Initial stats should show 0 sessions"
        )

        // ACT: Practice multiple patterns with different performance

        // Pattern 1: High performance (will master)
        let pattern1 = patterns[0]
        for _ in 1...5 {
            patternService.recordPracticeSession(
                pattern: pattern1,
                userProfile: profile,
                accuracy: 0.96,
                practiceTime: 300
            )
        }

        // Pattern 2: Medium performance (won't master)
        if patterns.count > 1 {
            let pattern2 = patterns[1]
            for _ in 1...3 {
                patternService.recordPracticeSession(
                    pattern: pattern2,
                    userProfile: profile,
                    accuracy: 0.75,
                    practiceTime: 350
                )
            }
        }

        // ASSERT: Statistics aggregation

        let finalStats = patternService.getUserPatternStatistics(userProfile: profile)

        // PROPERTY: Total patterns count
        XCTAssertGreaterThan(
            finalStats.totalPatterns,
            0,
            "Should have practiced patterns"
        )

        // PROPERTY: Total sessions count
        let expectedSessions = patterns.count > 1 ? 8 : 5
        XCTAssertEqual(
            finalStats.totalSessions,
            expectedSessions,
            "Total sessions should match practice sessions"
        )

        // PROPERTY: Total practice time aggregated
        XCTAssertGreaterThan(
            finalStats.totalPracticeTime,
            0,
            "Total practice time should be accumulated"
        )

        // Pattern 1 should have higher practice time than initial
        let expectedMinTime = patterns.count > 1 ? 2450.0 : 1500.0  // 5*300 + 3*350 or 5*300
        XCTAssertGreaterThanOrEqual(
            finalStats.totalPracticeTime,
            expectedMinTime,
            "Total time should be at least sum of sessions"
        )

        // PROPERTY: Average accuracy calculated
        XCTAssertGreaterThan(
            finalStats.averageAccuracy,
            0.0,
            "Average accuracy should be calculated"
        )

        // PROPERTY: Mastered patterns count
        XCTAssertGreaterThanOrEqual(
            finalStats.masteredPatterns,
            0,
            "Mastered patterns should be non-negative"
        )

        // PROPERTY: Mastery percentage calculation
        let calculatedMasteryPercentage = finalStats.totalPatterns > 0 ?
            Double(finalStats.masteredPatterns) / Double(finalStats.totalPatterns) * 100.0 : 0.0

        XCTAssertEqual(
            finalStats.masteryPercentage,
            calculatedMasteryPercentage,
            accuracy: 0.01,
            "Mastery percentage should match calculation"
        )

        // PROPERTY: Formatted time string is valid
        XCTAssertFalse(
            finalStats.formattedPracticeTime.isEmpty,
            "Formatted practice time should not be empty"
        )
    }

    // MARK: Test 6: Complete Pattern Practice Workflow

    /**
     * INTEGRATION VALIDATED:
     * - Pattern selection → Practice → Progress → Statistics complete flow
     * - All services coordinate correctly
     * - Data flows through entire pattern lifecycle
     * - Multi-session progression tracked correctly
     */
    func testCompletePatternPracticeWorkflow() throws {
        // ARRANGE: Create profile
        guard let belt9 = getBeltByKeup(9) else {
            XCTFail("9th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Workflow User",
            beltLevel: belt9
        )

        // STEP 1: Pattern Selection
        let availablePatterns = patternService.getPatternsForUser(userProfile: profile)

        XCTAssertGreaterThan(
            availablePatterns.count,
            0,
            "Should have patterns available for user's belt level"
        )

        let selectedPattern = availablePatterns[0]

        // PROPERTY: Selected pattern is appropriate for belt level
        XCTAssertTrue(
            selectedPattern.isAppropriateFor(beltLevel: profile.currentBeltLevel),
            "Selected pattern should be appropriate for user's belt"
        )

        // STEP 2: Initial progress check
        let initialProgress = patternService.getUserProgress(for: selectedPattern, userProfile: profile)

        XCTAssertEqual(
            initialProgress.masteryLevel,
            PatternMasteryLevel.learning,
            "New pattern should start at Learning level"
        )

        XCTAssertEqual(
            initialProgress.practiceCount,
            0,
            "New pattern should have 0 practice sessions"
        )

        // STEP 3: Practice session workflow
        let sessionAccuracies = [0.70, 0.75, 0.82, 0.88, 0.92]
        let sessionTimes = [320.0, 300.0, 285.0, 270.0, 260.0]

        for (index, (accuracy, time)) in zip(sessionAccuracies, sessionTimes).enumerated() {
            // Simulate identifying struggling moves (fewer as skill improves)
            let strugglingMoves = index < 2 ? [3, 7, 12] : (index < 4 ? [7] : [])

            patternService.recordPracticeSession(
                pattern: selectedPattern,
                userProfile: profile,
                accuracy: accuracy,
                practiceTime: time,
                strugglingMoves: strugglingMoves
            )
        }

        // STEP 4: Progress validation
        let finalProgress = patternService.getUserProgress(for: selectedPattern, userProfile: profile)

        // PROPERTY: Practice count matches sessions
        XCTAssertEqual(
            finalProgress.practiceCount,
            sessionAccuracies.count,
            "Practice count should match number of sessions"
        )

        // PROPERTY: Total practice time accumulated correctly
        let expectedTotalTime = sessionTimes.reduce(0, +)
        XCTAssertEqual(
            finalProgress.totalPracticeTime,
            expectedTotalTime,
            accuracy: 1.0,
            "Total practice time should match sum of session times"
        )

        // PROPERTY: Mastery level progressed
        XCTAssertGreaterThan(
            finalProgress.masteryLevel.sortOrder,
            PatternMasteryLevel.learning.sortOrder,
            "Mastery level should progress beyond Learning"
        )

        // PROPERTY: Average accuracy calculated correctly
        let expectedAvgAccuracy = sessionAccuracies.reduce(0, +) / Double(sessionAccuracies.count)
        XCTAssertEqual(
            finalProgress.averageAccuracy,
            expectedAvgAccuracy,
            accuracy: 0.01,
            "Average accuracy should match calculation"
        )

        // PROPERTY: Best run accuracy is maximum
        let expectedBestRun = sessionAccuracies.max() ?? 0.0
        XCTAssertEqual(
            finalProgress.bestRunAccuracy,
            expectedBestRun,
            accuracy: 0.01,
            "Best run should be maximum accuracy achieved"
        )

        // PROPERTY: Struggling moves reflect learning progression
        XCTAssertLessThan(
            finalProgress.strugglingMoves.count,
            3,
            "Struggling moves should decrease as skill improves"
        )

        // STEP 5: Statistics validation
        let stats = patternService.getUserPatternStatistics(userProfile: profile)

        // PROPERTY: Statistics reflect practice sessions
        XCTAssertGreaterThan(
            stats.totalPatterns,
            0,
            "Should have practiced patterns in statistics"
        )

        XCTAssertEqual(
            stats.totalSessions,
            sessionAccuracies.count,
            "Statistics should match session count"
        )

        XCTAssertEqual(
            stats.totalPracticeTime,
            expectedTotalTime,
            accuracy: 1.0,
            "Statistics practice time should match total"
        )

        // PROPERTY: Average accuracy in stats matches pattern progress
        XCTAssertEqual(
            stats.averageAccuracy,
            expectedAvgAccuracy,
            accuracy: 0.01,
            "Statistics average should match pattern average"
        )

        // STEP 6: Profile integration validation
        // Note: Pattern practice doesn't directly increment profile.totalStudySessions
        // That happens through ProfileService.recordStudySession()
        // Here we're validating the pattern service orchestration only

        // PROPERTY: Pattern progress persisted correctly
        let reloadedProgress = patternService.getUserProgress(
            for: selectedPattern,
            userProfile: profile
        )

        XCTAssertEqual(
            reloadedProgress.id,
            finalProgress.id,
            "Reloaded progress should match original"
        )

        XCTAssertEqual(
            reloadedProgress.practiceCount,
            finalProgress.practiceCount,
            "Reloaded progress should persist practice count"
        )
    }
}
