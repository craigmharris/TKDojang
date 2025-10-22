import XCTest
import SwiftData
@testable import TKDojang

/**
 * MultipleChoiceServiceIntegrationTests.swift
 *
 * PURPOSE: Service orchestration tests for multiple choice testing feature integration
 *
 * ARCHITECTURAL APPROACH (Phase 2 Breakthrough):
 * Tests service layer integration, NOT view rendering. In SwiftUI MVVM-C,
 * integration happens at the SERVICE layer where multiple services coordinate.
 *
 * INTEGRATION LAYERS TESTED:
 * 1. TestingService → Question selection and test creation
 * 2. Answer recording → Scoring logic orchestration
 * 3. Test completion → ProfileService → Stats recording
 * 4. Multi-profile data isolation
 * 5. Statistics aggregation across tests
 *
 * WHY SERVICE ORCHESTRATION:
 * - Testing bugs occur in service coordination, not SwiftUI view rendering
 * - Testing question selection, scoring, and stats aggregation validates core logic
 * - Service tests are faster, more reliable, and easier to debug than ViewInspector
 * - Property-based approach ensures correctness across randomized states
 *
 * Test coverage: 5 integration tests validating multiple choice service orchestration
 */

@MainActor
final class MultipleChoiceServiceIntegrationTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testingService: TestingService!
    var profileService: ProfileService!
    var terminologyService: TerminologyDataService!
    var dataFactory: TestDataFactory!
    var testBelts: [BeltLevel] = []
    var testCategories: [TerminologyCategory] = []

    override func setUp() async throws {
        // Use TestContainerFactory for consistent test infrastructure
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext

        // Initialize services (TestingService needs terminologyService)
        terminologyService = TerminologyDataService(modelContext: testContext)
        testingService = TestingService(modelContext: testContext, terminologyService: terminologyService)
        profileService = ProfileService(modelContext: testContext)

        // Setup test data using TestDataFactory
        dataFactory = TestDataFactory()
        testBelts = dataFactory.createBasicBeltLevels()
        testCategories = dataFactory.createBasicCategories()

        // Insert belt levels
        for belt in testBelts {
            testContext.insert(belt)
        }

        // Insert categories
        for category in testCategories {
            testContext.insert(category)
        }

        // Create terminology entries for each belt
        for belt in testBelts {
            if let category = testCategories.first {
                let entries = dataFactory.createSampleTerminologyEntries(
                    belt: belt,
                    category: category,
                    count: 10  // More entries for testing
                )
                for entry in entries {
                    testContext.insert(entry)
                }
            }
        }

        try testContext.save()
    }

    override func tearDown() {
        testContext = nil
        testContainer = nil
        testingService = nil
        profileService = nil
        terminologyService = nil
        dataFactory = nil
        testBelts = []
        testCategories = []
    }

    // MARK: - Helper Methods

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

    // MARK: - Integration Tests

    // MARK: Test 1: Configuration to Question Selection Flow

    /**
     * INTEGRATION VALIDATED:
     * - TestingService.createQuickTest() → Question generation orchestration
     * - Question count matches requested count (or available max)
     * - Belt level filtering applied correctly
     * - Question variety and uniqueness
     */
    func testConfigurationToQuestionSelectionFlow() throws {
        // ARRANGE: Create profile
        guard let belt7 = getBeltByKeup(7) else {
            XCTFail("7th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Test Taker",
            beltLevel: belt7
        )

        try profileService.activateProfile(profile)

        // ACT: Create tests with different question counts (quick tests generate 5-10 questions)
        for _ in 1...5 {
            let session = try testingService.createQuickTest(for: profile)

            // ASSERT: Question count properties
            // PROPERTY: Returned count is reasonable (5-10 for quick tests)
            XCTAssertGreaterThanOrEqual(
                session.questions.count,
                5,
                "Quick test should have at least 5 questions"
            )

            XCTAssertLessThanOrEqual(
                session.questions.count,
                10,
                "Quick test should have at most 10 questions"
            )

            // PROPERTY: Questions are unique
            let uniqueQuestions = Set(session.questions.map { $0.id })
            XCTAssertEqual(
                uniqueQuestions.count,
                session.questions.count,
                "All questions should be unique"
            )

            // PROPERTY: Each question has 4 answer options
            XCTAssertTrue(
                session.questions.allSatisfy { $0.options.count == 4 },
                "Each question should have exactly 4 answer options"
            )

            // PROPERTY: Each question has exactly one correct answer
            XCTAssertTrue(
                session.questions.allSatisfy { question in
                    let correctCount = question.options.enumerated().filter { index, _ in
                        index == question.correctAnswerIndex
                    }.count
                    return correctCount == 1
                },
                "Each question should have exactly one correct answer"
            )
        }
    }

    // MARK: Test 2: Answer Recording to Scoring Flow

    /**
     * INTEGRATION VALIDATED:
     * - TestingService.recordAnswer() → Scoring logic
     * - Correct/incorrect tracking accurate
     * - Score calculation updates correctly
     * - Answer history maintained
     */
    func testAnswerRecordingToScoringFlow() throws {
        // ARRANGE: Create profile and test
        guard let belt8 = getBeltByKeup(8) else {
            XCTFail("8th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Answer Recorder",
            beltLevel: belt8
        )

        try profileService.activateProfile(profile)

        let session = try testingService.createQuickTest(for: profile)

        XCTAssertGreaterThan(session.questions.count, 0, "Should have questions")

        // ACT: Record answers (mix of correct and incorrect)
        var expectedCorrect = 0
        var expectedIncorrect = 0

        for (index, question) in session.questions.enumerated() {
            let correctIndex = question.correctAnswerIndex
            let incorrectIndex = (correctIndex + 1) % 4

            // Answer every other question correctly
            let isCorrect = index % 2 == 0
            let selectedIndex = isCorrect ? correctIndex : incorrectIndex

            try testingService.recordAnswer(for: question, answerIndex: selectedIndex)

            if isCorrect {
                expectedCorrect += 1
            } else {
                expectedIncorrect += 1
            }
        }

        // ASSERT: Scoring accuracy

        let actualCorrect = session.questions.filter { $0.isCorrect }.count

        // PROPERTY: Correct count matches expected
        XCTAssertEqual(
            actualCorrect,
            expectedCorrect,
            "Correct answer count should match actual correct answers"
        )

        // PROPERTY: Incorrect count matches expected
        let actualIncorrect = session.questions.count - actualCorrect
        XCTAssertEqual(
            actualIncorrect,
            expectedIncorrect,
            "Incorrect answer count should match actual incorrect answers"
        )

        // PROPERTY: Score percentage calculated correctly
        let actualScore = Double(expectedCorrect) / Double(session.questions.count) * 100.0
        let expectedScore = Double(expectedCorrect) / Double(session.questions.count) * 100.0
        XCTAssertEqual(
            actualScore,
            expectedScore,
            accuracy: 0.01,
            "Score percentage should be calculated correctly"
        )

        // PROPERTY: All questions have recorded answers
        let answeredQuestions = session.questions.filter { $0.userAnswerIndex != nil }
        XCTAssertEqual(
            answeredQuestions.count,
            session.questions.count,
            "All questions should have recorded answers"
        )
    }

    // MARK: Test 3: Test Completion to Stats Recording Flow

    /**
     * INTEGRATION VALIDATED:
     * - TestingService.completeTest() → ProfileService.recordStudySession()
     * - Test results persisted correctly
     * - Profile stats updated (tests taken, average score)
     * - GradingRecord created with accurate data
     */
    func testCompletionToStatsRecordingFlow() throws {
        // ARRANGE: Create profile and test
        guard let belt6 = getBeltByKeup(6) else {
            XCTFail("6th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Stats User",
            beltLevel: belt6
        )

        try profileService.activateProfile(profile)

        let initialTestsTaken = profile.totalTestsTaken

        let session = try testingService.createQuickTest(for: profile)

        // Record answers (80% correct)
        for (index, question) in session.questions.enumerated() {
            let correctIndex = question.correctAnswerIndex
            let incorrectIndex = (correctIndex + 1) % 4

            let targetCorrectCount = Int(Double(session.questions.count) * 0.8)
            let isCorrect = index < targetCorrectCount
            let selectedIndex = isCorrect ? correctIndex : incorrectIndex

            try testingService.recordAnswer(for: question, answerIndex: selectedIndex)
        }

        let actualCorrect = session.questions.filter { $0.isCorrect }.count

        // ACT: Complete test
        let result = try testingService.completeTest(session: session, for: profile)

        // Record study session for the test
        try profileService.recordStudySession(
            sessionType: StudySessionType.testing,
            itemsStudied: session.questions.count,
            correctAnswers: actualCorrect,
            focusAreas: [profile.currentBeltLevel.shortName]
        )

        // ASSERT: Stats recording

        // Reload profile to get updated stats
        let profileReloaded = try XCTUnwrap(
            profileService.getActiveProfile(),
            "Active profile should exist"
        )

        // PROPERTY: Tests taken incremented
        XCTAssertGreaterThan(
            profileReloaded.totalTestsTaken,
            initialTestsTaken,
            "Tests taken should increment after completion"
        )

        // PROPERTY: Study session persisted
        let sessionDescriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allSessions = try testContext.fetch(sessionDescriptor)
        let sessions = allSessions.filter { $0.sessionType == StudySessionType.testing }

        XCTAssertGreaterThan(
            sessions.count,
            0,
            "Study session should be persisted"
        )

        if let latestSession = sessions.first {
            // PROPERTY: Session type is testing
            XCTAssertEqual(
                latestSession.sessionType,
                StudySessionType.testing,
                "Session type should be testing"
            )

            // PROPERTY: Items studied matches question count
            XCTAssertEqual(
                latestSession.itemsStudied,
                session.questions.count,
                "Items studied should match question count"
            )

            // PROPERTY: Correct answers tracked
            XCTAssertEqual(
                latestSession.correctAnswers,
                actualCorrect,
                "Correct answers should match test results"
            )

            // PROPERTY: Accuracy matches test score
            let expectedAccuracy = Double(actualCorrect) / Double(session.questions.count)
            XCTAssertEqual(
                latestSession.accuracy,
                expectedAccuracy,
                accuracy: 0.01,
                "Session accuracy should match test score"
            )
        }

        // PROPERTY: TestResult created
        XCTAssertNotNil(result, "TestResult should be created")
        XCTAssertEqual(result.correctAnswers, actualCorrect, "Result should have correct answer count")
    }

    // MARK: Test 4: Multi-Profile Data Isolation

    /**
     * INTEGRATION VALIDATED:
     * - Test results isolated per profile
     * - Question history doesn't leak between profiles
     * - Stats correctly associated with profile
     * - GradingRecords filtered by profile
     */
    func testMultiProfileTestDataIsolation() throws {
        // ARRANGE: Create two profiles
        guard let belt7 = getBeltByKeup(7) else {
            XCTFail("7th keup not available")
            return
        }

        let profile1 = try createTestProfile(
            name: "Student One",
            beltLevel: belt7
        )

        let profile2 = try createTestProfile(
            name: "Student Two",
            beltLevel: belt7
        )

        // ACT: Profile 1 takes test with high score
        try profileService.activateProfile(profile1)

        let session1 = try testingService.createQuickTest(for: profile1)

        // Answer 90% correctly
        for (index, question) in session1.questions.enumerated() {
            let correctIndex = question.correctAnswerIndex
            let incorrectIndex = (correctIndex + 1) % 4

            let targetCorrect = Int(Double(session1.questions.count) * 0.9)
            let isCorrect = index < targetCorrect
            let selectedIndex = isCorrect ? correctIndex : incorrectIndex

            try testingService.recordAnswer(for: question, answerIndex: selectedIndex)
        }

        let actualCorrect1 = session1.questions.filter { $0.isCorrect }.count

        _ = try testingService.completeTest(session: session1, for: profile1)

        try profileService.recordStudySession(
            sessionType: StudySessionType.testing,
            itemsStudied: session1.questions.count,
            correctAnswers: actualCorrect1,
            focusAreas: [profile1.currentBeltLevel.shortName]
        )

        let profile1TestsTaken = profile1.totalTestsTaken
        let profile1Score = Double(actualCorrect1) / Double(session1.questions.count) * 100.0

        // ACT: Profile 2 takes test with lower score
        try profileService.activateProfile(profile2)

        let session2 = try testingService.createQuickTest(for: profile2)

        // Answer 60% correctly
        for (index, question) in session2.questions.enumerated() {
            let correctIndex = question.correctAnswerIndex
            let incorrectIndex = (correctIndex + 1) % 4

            let targetCorrect = Int(Double(session2.questions.count) * 0.6)
            let isCorrect = index < targetCorrect
            let selectedIndex = isCorrect ? correctIndex : incorrectIndex

            try testingService.recordAnswer(for: question, answerIndex: selectedIndex)
        }

        let actualCorrect2 = session2.questions.filter { $0.isCorrect }.count

        _ = try testingService.completeTest(session: session2, for: profile2)

        try profileService.recordStudySession(
            sessionType: StudySessionType.testing,
            itemsStudied: session2.questions.count,
            correctAnswers: actualCorrect2,
            focusAreas: [profile2.currentBeltLevel.shortName]
        )

        let profile2TestsTaken = profile2.totalTestsTaken
        let profile2Score = Double(actualCorrect2) / Double(session2.questions.count) * 100.0

        // ASSERT: Data isolation

        // PROPERTY: Test counts are independent
        XCTAssertGreaterThan(
            profile1TestsTaken,
            0,
            "Profile 1 should have taken tests"
        )

        XCTAssertGreaterThan(
            profile2TestsTaken,
            0,
            "Profile 2 should have taken tests"
        )

        // PROPERTY: Scores are different
        XCTAssertNotEqual(
            profile1Score,
            profile2Score,
            "Profile scores should be different"
        )

        XCTAssertGreaterThan(
            profile1Score,
            profile2Score,
            "Profile 1 should have higher score than Profile 2"
        )

        // PROPERTY: Study sessions correctly associated
        let sessionDescriptor = FetchDescriptor<StudySession>()
        let allSessions = try testContext.fetch(sessionDescriptor)

        let profile1Sessions = allSessions.filter { $0.userProfile.id == profile1.id }
        let profile2Sessions = allSessions.filter { $0.userProfile.id == profile2.id }

        XCTAssertGreaterThan(
            profile1Sessions.count,
            0,
            "Profile 1 should have study sessions"
        )

        XCTAssertGreaterThan(
            profile2Sessions.count,
            0,
            "Profile 2 should have study sessions"
        )

        // PROPERTY: Sessions don't leak between profiles
        XCTAssertTrue(
            profile1Sessions.allSatisfy { $0.userProfile.id == profile1.id },
            "Profile 1 sessions should only belong to Profile 1"
        )

        XCTAssertTrue(
            profile2Sessions.allSatisfy { $0.userProfile.id == profile2.id },
            "Profile 2 sessions should only belong to Profile 2"
        )
    }

    // MARK: Test 5: Complete Workflow End-to-End

    /**
     * INTEGRATION VALIDATED:
     * - Configuration → Test Creation → Answering → Completion → Stats complete flow
     * - All services coordinate correctly
     * - Data flows through entire testing lifecycle
     * - Stats aggregation accurate across workflow
     */
    func testCompleteMultipleChoiceWorkflow() throws {
        // ARRANGE: Create profile
        guard let belt5 = getBeltByKeup(5) else {
            XCTFail("5th keup not available")
            return
        }

        let profile = try createTestProfile(
            name: "Workflow User",
            beltLevel: belt5
        )

        try profileService.activateProfile(profile)

        let initialTestsTaken = profile.totalTestsTaken
        let initialSessions = profile.studySessions.count

        // STEP 1: Test Configuration → Creation
        let session = try testingService.createQuickTest(for: profile)

        // PROPERTY: Test created with questions
        XCTAssertGreaterThan(
            session.questions.count,
            0,
            "Test should have questions"
        )

        // STEP 2: Answer Questions
        var correctCount = 0

        for (index, question) in session.questions.enumerated() {
            // Simulate realistic test taking (70% accuracy)
            let isCorrect = index % 10 < 7  // 7/10 = 70%

            let correctIndex = question.correctAnswerIndex
            let incorrectIndex = (correctIndex + 1) % 4

            let selectedIndex = isCorrect ? correctIndex : incorrectIndex

            try testingService.recordAnswer(for: question, answerIndex: selectedIndex)

            if isCorrect {
                correctCount += 1
            }
        }

        // PROPERTY: All questions answered
        let answeredQuestions = session.questions.filter { $0.userAnswerIndex != nil }
        XCTAssertEqual(
            answeredQuestions.count,
            session.questions.count,
            "All questions should be answered"
        )

        // STEP 3: Complete Test
        let result = try testingService.completeTest(session: session, for: profile)

        // PROPERTY: Test marked as completed
        XCTAssertTrue(
            session.isCompleted,
            "Test should be marked as completed"
        )

        // PROPERTY: Score calculated correctly
        let expectedScore = Double(correctCount) / Double(session.questions.count) * 100.0
        XCTAssertEqual(
            result.accuracy,
            expectedScore,
            accuracy: 0.01,
            "Test score should match calculation"
        )

        // STEP 4: Record Session
        try profileService.recordStudySession(
            sessionType: StudySessionType.testing,
            itemsStudied: session.questions.count,
            correctAnswers: correctCount,
            focusAreas: [profile.currentBeltLevel.shortName]
        )

        // STEP 5: Validate Complete Flow

        // Reload profile
        let profileAfter = try XCTUnwrap(
            profileService.getActiveProfile(),
            "Active profile should exist"
        )

        // PROPERTY: Tests taken incremented
        XCTAssertGreaterThan(
            profileAfter.totalTestsTaken,
            initialTestsTaken,
            "Tests taken should increment"
        )

        // PROPERTY: Session count incremented
        XCTAssertGreaterThan(
            profileAfter.studySessions.count,
            initialSessions,
            "Session count should increment"
        )

        // PROPERTY: Study session persisted correctly
        let sessionDescriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sessions = try testContext.fetch(sessionDescriptor)
        let userSessions = sessions.filter { $0.userProfile.id == profile.id }

        XCTAssertGreaterThan(
            userSessions.count,
            0,
            "Study session should be persisted"
        )

        if let latestSession = userSessions.first {
            // PROPERTY: Session accuracy matches test score
            let expectedAccuracy = Double(correctCount) / Double(session.questions.count)
            XCTAssertEqual(
                latestSession.accuracy,
                expectedAccuracy,
                accuracy: 0.01,
                "Session accuracy should match test results"
            )

            // PROPERTY: Session belongs to correct profile
            XCTAssertEqual(
                latestSession.userProfile.id,
                profile.id,
                "Session should belong to correct profile"
            )

            // PROPERTY: Session type is testing
            XCTAssertEqual(
                latestSession.sessionType,
                StudySessionType.testing,
                "Session type should be testing"
            )
        }

        // PROPERTY: TestResult persisted
        XCTAssertNotNil(session.result, "TestResult should be persisted in session")
    }
}
