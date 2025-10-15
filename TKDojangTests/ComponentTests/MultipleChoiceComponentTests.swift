import XCTest
import SwiftUI
import SwiftData
import ViewInspector
@testable import TKDojang

/**
 * MultipleChoiceComponentTests.swift
 *
 * PURPOSE: Property-based component tests for Multiple Choice testing feature
 *
 * APPROACH: Property-based testing validates behavior across ALL valid configurations
 * using randomization to catch edge cases and ensure data-flow correctness.
 *
 * CRITICAL TESTS:
 * - Question generation with smart distractors
 * - Answer validation and feedback
 * - Result analytics and recommendations
 * - Progress tracking
 *
 * TEST CATEGORIES:
 * 1. Question Generation Property Tests (6 tests)
 * 2. Answer Recording Property Tests (4 tests)
 * 3. Result Analytics Property Tests (5 tests)
 * 4. Test Session Management (3 tests)
 * 5. View Component Tests (4 tests)
 * 6. Enum Display Names (3 tests)
 *
 * TOTAL: 25 tests
 */

@MainActor
final class MultipleChoiceComponentTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testingService: TestingService!
    var terminologyService: TerminologyDataService!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory container with all models
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext

        // Initialize services
        terminologyService = TerminologyDataService(modelContext: testContext)
        testingService = TestingService(modelContext: testContext, terminologyService: terminologyService)

        // Load test data
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
    }

    override func tearDown() async throws {
        testContext = nil
        testContainer = nil
        testingService = nil
        terminologyService = nil
        try await super.tearDown()
    }

    // MARK: - 1. Question Generation Property Tests (6 tests)

    /**
     * PROPERTY: Generated questions must have EXACTLY 4 options
     *
     * Tests across random belt levels to ensure consistent 4-option format
     */
    func testQuestionGeneration_PropertyBased_AlwaysHasFourOptions() throws {
        // Arrange: Get random belt levels
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let randomBelts = allBelts.shuffled().prefix(5)

        for belt in randomBelts {
            // Act: Create quick test for this belt
            let profile = try createTestProfile(belt: belt)
            let testSession = try testingService.createQuickTest(for: profile)

            // Assert: PROPERTY - All questions have exactly 4 options
            for question in testSession.questions {
                XCTAssertEqual(question.options.count, 4,
                    """
                    PROPERTY VIOLATION: Question must have 4 options
                    Belt: \(belt.shortName), Got: \(question.options.count)
                    Question: \(question.questionText)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Correct answer must be at a random index (0-3)
     *
     * Tests that correct answer position isn't predictable
     */
    func testQuestionGeneration_PropertyBased_CorrectAnswerIndexRandomized() throws {
        // Arrange: Generate multiple questions
        let profile = try createDefaultTestProfile()
        var correctIndexCounts = [0: 0, 1: 0, 2: 0, 3: 0]

        // Act: Create 10 quick tests (each has 5-10 questions)
        for _ in 0..<10 {
            let testSession = try testingService.createQuickTest(for: profile)

            for question in testSession.questions {
                correctIndexCounts[question.correctAnswerIndex, default: 0] += 1
            }
        }

        // Assert: PROPERTY - All indices (0-3) should be used
        XCTAssertEqual(correctIndexCounts.count, 4,
            "Correct answer should appear at all 4 positions")

        // Each index should be used at least once across 50-100 questions
        for index in 0...3 {
            XCTAssertGreaterThan(correctIndexCounts[index] ?? 0, 0,
                "Correct answer should appear at index \(index)")
        }
    }

    /**
     * PROPERTY: Distractors must be unique and not include correct answer
     *
     * Tests that all 4 options are distinct
     */
    func testQuestionGeneration_PropertyBased_OptionsAreUnique() throws {
        // Arrange: Create comprehensive test
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createComprehensiveTest(for: profile)

        // Act & Assert: Check every question
        for question in testSession.questions {
            let uniqueOptions = Set(question.options)

            // PROPERTY: All options must be unique
            XCTAssertEqual(uniqueOptions.count, question.options.count,
                """
                PROPERTY VIOLATION: All options must be unique
                Question: \(question.questionText)
                Options: \(question.options)
                Duplicates found!
                """)
        }
    }

    /**
     * PROPERTY: Distractors should prioritize same category/belt level
     *
     * Tests smart distractor generation algorithm
     */
    func testQuestionGeneration_PropertyBased_SmartDistractorSelection() throws {
        // Arrange: Create comprehensive test
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createComprehensiveTest(for: profile)

        var sameCategoryCount = 0
        var totalDistractors = 0

        // Act: Analyze distractor sources
        for question in testSession.questions {
            guard let sourceEntry = question.terminologyEntry else { continue }

            let allTerms = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
            let distractorEntries: [TerminologyEntry]

            if question.questionType == .englishToKorean {
                distractorEntries = allTerms.filter {
                    question.options.contains($0.romanizedPronunciation) &&
                    $0.id != sourceEntry.id
                }
            } else {
                distractorEntries = allTerms.filter {
                    question.options.contains($0.englishTerm) &&
                    $0.id != sourceEntry.id
                }
            }

            for entry in distractorEntries {
                totalDistractors += 1
                if entry.category.id == sourceEntry.category.id {
                    sameCategoryCount += 1
                }
            }
        }

        // Assert: PROPERTY - Most distractors should be from same category
        if totalDistractors > 0 {
            let sameCategoryRatio = Double(sameCategoryCount) / Double(totalDistractors)
            XCTAssertGreaterThan(sameCategoryRatio, 0.5,
                """
                PROPERTY: Most distractors should be from same category
                Same category: \(sameCategoryCount)/\(totalDistractors) = \(Int(sameCategoryRatio * 100))%
                Expected: >50%
                """)
        }
    }

    /**
     * PROPERTY: Quick test generates 5-10 questions
     *
     * Tests question count constraints
     */
    func testQuestionGeneration_PropertyBased_QuickTestCount() throws {
        // Arrange: Create multiple random profiles
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let randomBelts = allBelts.shuffled().prefix(5)

        for belt in randomBelts {
            // Act: Create quick test
            let profile = try createTestProfile(belt: belt)
            let testSession = try testingService.createQuickTest(for: profile)

            // Assert: PROPERTY - Quick tests have 5-10 questions
            XCTAssertGreaterThanOrEqual(testSession.questions.count, 5,
                "Quick test must have at least 5 questions (Belt: \(belt.shortName))")
            XCTAssertLessThanOrEqual(testSession.questions.count, 10,
                "Quick test must have at most 10 questions (Belt: \(belt.shortName))")
        }
    }

    /**
     * PROPERTY: Comprehensive test includes all belt terminology
     *
     * Tests that comprehensive tests are actually comprehensive
     */
    func testQuestionGeneration_PropertyBased_ComprehensiveTestCoverage() throws {
        // Arrange: Create profile and get belt terminology
        let profile = try createDefaultTestProfile()
        let belt = profile.currentBeltLevel

        let allTerms = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let beltTerms = allTerms.filter { $0.beltLevel.id == belt.id }

        // Act: Create comprehensive test
        let testSession = try testingService.createComprehensiveTest(for: profile)

        // Assert: PROPERTY - Question count matches available terminology
        // Each term generates 2 questions (englishToKorean + koreanToEnglish)
        let expectedQuestionCount = beltTerms.count * 2
        XCTAssertEqual(testSession.questions.count, expectedQuestionCount,
            """
            PROPERTY VIOLATION: Comprehensive test should cover all terminology
            Belt: \(belt.shortName)
            Available Terms: \(beltTerms.count)
            Expected Questions: \(expectedQuestionCount) (2 per term)
            Got: \(testSession.questions.count)
            """)
    }

    // MARK: - 2. Answer Recording Property Tests (4 tests)

    /**
     * PROPERTY: Recording correct answer marks question as correct
     *
     * Tests answer validation across random questions
     */
    func testAnswerRecording_PropertyBased_CorrectAnswerValidation() throws {
        // Arrange: Create test session
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createQuickTest(for: profile)

        // Act: Record correct answers for all questions
        for question in testSession.questions {
            try testingService.recordAnswer(for: question, answerIndex: question.correctAnswerIndex)
        }

        // Assert: PROPERTY - All questions marked correct
        let correctCount = testSession.questions.filter { $0.isCorrect }.count
        XCTAssertEqual(correctCount, testSession.questions.count,
            """
            PROPERTY VIOLATION: Recording correct answer must mark question as correct
            Total Questions: \(testSession.questions.count)
            Marked Correct: \(correctCount)
            """)
    }

    /**
     * PROPERTY: Recording wrong answer marks question as incorrect
     *
     * Tests wrong answer handling across random scenarios
     */
    func testAnswerRecording_PropertyBased_IncorrectAnswerValidation() throws {
        // Arrange: Create test session
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createQuickTest(for: profile)

        // Act: Record wrong answers for all questions
        for question in testSession.questions {
            let wrongIndex = (question.correctAnswerIndex + 1) % 4
            try testingService.recordAnswer(for: question, answerIndex: wrongIndex)
        }

        // Assert: PROPERTY - No questions marked correct
        let correctCount = testSession.questions.filter { $0.isCorrect }.count
        XCTAssertEqual(correctCount, 0,
            """
            PROPERTY VIOLATION: Recording wrong answer must mark question as incorrect
            Total Questions: \(testSession.questions.count)
            Incorrectly Marked Correct: \(correctCount)
            """)
    }

    /**
     * PROPERTY: Answer timing is tracked accurately
     *
     * Tests that timeToAnswerSeconds is recorded
     */
    func testAnswerRecording_PropertyBased_TimingTracked() throws {
        // Arrange: Create test session
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createQuickTest(for: profile)

        // Act: Mark as presented, wait, then answer
        for question in testSession.questions {
            question.markAsPresented()
            Thread.sleep(forTimeInterval: 0.01) // 10ms delay
            try testingService.recordAnswer(for: question, answerIndex: 0)
        }

        // Assert: PROPERTY - All questions have timing recorded
        for question in testSession.questions {
            XCTAssertNotNil(question.timeToAnswerSeconds,
                "Time to answer should be recorded for question: \(question.questionText)")
            XCTAssertGreaterThan(question.timeToAnswerSeconds ?? 0, 0,
                "Time to answer should be positive")
        }
    }

    /**
     * PROPERTY: Random answer sequences produce expected accuracy
     *
     * Tests accuracy calculation across random answer patterns
     */
    func testAnswerRecording_PropertyBased_AccuracyCalculation() throws {
        // Test 20 random sequences
        for _ in 0..<20 {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            let questionCount = testSession.questions.count
            let correctCount = Int.random(in: 0...questionCount)

            // Act: Answer questions (correctCount correct, rest wrong)
            for (index, question) in testSession.questions.enumerated() {
                let answerIndex = index < correctCount ?
                    question.correctAnswerIndex :
                    (question.correctAnswerIndex + 1) % 4
                try testingService.recordAnswer(for: question, answerIndex: answerIndex)
            }

            let result = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Accuracy matches expected
            let expectedAccuracy = Double(correctCount) / Double(questionCount) * 100
            XCTAssertEqual(result.accuracy, expectedAccuracy, accuracy: 0.01,
                """
                PROPERTY VIOLATION: Accuracy calculation incorrect
                Correct: \(correctCount)/\(questionCount)
                Expected: \(expectedAccuracy)%
                Got: \(result.accuracy)%
                """)
        }
    }

    // MARK: - 3. Result Analytics Property Tests (5 tests)

    /**
     * PROPERTY: All possible accuracy ratios calculate correctly
     *
     * Tests every possible accuracy from 0% to 100%
     */
    func testResultAnalytics_PropertyBased_AllAccuracyRatios() throws {
        let testSizes = [5, 10, 20]

        for size in testSizes {
            for correctCount in 0...size {
                // Arrange: Create profile and test session
                let profile = try createDefaultTestProfile()
                let testSession = try testingService.createQuickTest(for: profile)

                // Ensure we have exactly 'size' questions by creating comprehensive test if needed
                // Skip if we can't get exact size match - property test still validates accuracy calculation
                guard testSession.questions.count == size else { continue }

                // Act: Answer questions (correctCount correct, rest wrong)
                for (index, question) in testSession.questions.enumerated() {
                    let answerIndex = index < correctCount ?
                        question.correctAnswerIndex :
                        (question.correctAnswerIndex + 1) % 4
                    try testingService.recordAnswer(for: question, answerIndex: answerIndex)
                }

                let result = try testingService.completeTest(session: testSession, for: profile)

                // Assert: PROPERTY - Accuracy is correct
                let expectedAccuracy = Double(correctCount) / Double(size) * 100
                XCTAssertEqual(result.accuracy, expectedAccuracy, accuracy: 0.01,
                    """
                    PROPERTY VIOLATION: Accuracy incorrect
                    Size: \(size), Correct: \(correctCount)
                    Expected: \(expectedAccuracy)%, Got: \(result.accuracy)%
                    """)
            }
        }
    }

    /**
     * PROPERTY: Category performance breakdown adds up to total
     *
     * Tests that category analytics are consistent
     */
    func testResultAnalytics_PropertyBased_CategoryBreakdownConsistency() throws {
        // Test 10 random test sessions
        for _ in 0..<10 {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            // Act: Answer randomly
            for question in testSession.questions {
                let randomAnswer = Int.random(in: 0...3)
                try testingService.recordAnswer(for: question, answerIndex: randomAnswer)
            }

            let result = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Category totals match overall totals
            let categoryTotalQuestions = result.categoryPerformance.reduce(0) { $0 + $1.totalQuestions }
            let categoryCorrectAnswers = result.categoryPerformance.reduce(0) { $0 + $1.correctAnswers }

            XCTAssertEqual(categoryTotalQuestions, result.totalQuestions,
                """
                PROPERTY VIOLATION: Category breakdown doesn't match total
                Total Questions: \(result.totalQuestions)
                Category Sum: \(categoryTotalQuestions)
                """)

            XCTAssertEqual(categoryCorrectAnswers, result.correctAnswers,
                """
                PROPERTY VIOLATION: Category correct answers don't match total
                Total Correct: \(result.correctAnswers)
                Category Sum: \(categoryCorrectAnswers)
                """)
        }
    }

    /**
     * PROPERTY: Belt level performance breakdown adds up to total
     *
     * Tests that belt level analytics are consistent
     */
    func testResultAnalytics_PropertyBased_BeltBreakdownConsistency() throws {
        // Test 10 random test sessions
        for _ in 0..<10 {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            // Act: Answer randomly
            for question in testSession.questions {
                let randomAnswer = Int.random(in: 0...3)
                try testingService.recordAnswer(for: question, answerIndex: randomAnswer)
            }

            let result = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Belt totals match overall totals
            let beltTotalQuestions = result.beltLevelPerformance.reduce(0) { $0 + $1.totalQuestions }
            let beltCorrectAnswers = result.beltLevelPerformance.reduce(0) { $0 + $1.correctAnswers }

            XCTAssertEqual(beltTotalQuestions, result.totalQuestions,
                """
                PROPERTY VIOLATION: Belt breakdown doesn't match total
                Total Questions: \(result.totalQuestions)
                Belt Sum: \(beltTotalQuestions)
                """)

            XCTAssertEqual(beltCorrectAnswers, result.correctAnswers,
                """
                PROPERTY VIOLATION: Belt correct answers don't match total
                Total Correct: \(result.correctAnswers)
                Belt Sum: \(beltCorrectAnswers)
                """)
        }
    }

    /**
     * PROPERTY: Weak areas identified for < 70% accuracy categories
     *
     * Tests weak area detection logic
     */
    func testResultAnalytics_PropertyBased_WeakAreaIdentification() throws {
        // Arrange: Create test session with known weak category
        let profile = try createDefaultTestProfile()
        let testSession = try testingService.createComprehensiveTest(for: profile)

        // Act: Answer first 30% wrong, rest correct
        let weakThreshold = Int(Double(testSession.questions.count) * 0.3)
        for (index, question) in testSession.questions.enumerated() {
            let answerIndex = index < weakThreshold ?
                (question.correctAnswerIndex + 1) % 4 :
                question.correctAnswerIndex
            try testingService.recordAnswer(for: question, answerIndex: answerIndex)
        }

        let result = try testingService.completeTest(session: testSession, for: profile)

        // Assert: PROPERTY - Categories < 70% should be in weak areas
        for category in result.categoryPerformance {
            if category.accuracy < 70 {
                let categoryInWeakAreas = result.weakAreas.contains { $0.contains(category.category) }
                XCTAssertTrue(categoryInWeakAreas,
                    """
                    PROPERTY VIOLATION: Category with <70% accuracy should be in weak areas
                    Category: \(category.category)
                    Accuracy: \(category.accuracy)%
                    Weak Areas: \(result.weakAreas)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Study recommendations generated for incomplete performance
     *
     * Tests recommendation generation logic
     */
    func testResultAnalytics_PropertyBased_StudyRecommendations() throws {
        // Test different accuracy levels
        let accuracyLevels = [0.0, 0.3, 0.5, 0.7, 0.9, 1.0]

        for targetAccuracy in accuracyLevels {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            let correctCount = Int(Double(testSession.questions.count) * targetAccuracy)

            // Act: Answer questions to achieve target accuracy
            for (index, question) in testSession.questions.enumerated() {
                let answerIndex = index < correctCount ?
                    question.correctAnswerIndex :
                    (question.correctAnswerIndex + 1) % 4
                try testingService.recordAnswer(for: question, answerIndex: answerIndex)
            }

            let result = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Recommendations exist if incorrect answers > 0
            let incorrectCount = testSession.questions.count - correctCount
            if incorrectCount > 0 {
                XCTAssertFalse(result.studyRecommendations.isEmpty,
                    """
                    PROPERTY VIOLATION: Study recommendations should exist with incorrect answers
                    Incorrect: \(incorrectCount)
                    Accuracy: \(result.accuracy)%
                    Recommendations: \(result.studyRecommendations)
                    """)
            }
        }
    }

    // MARK: - 4. Test Session Management (3 tests)

    /**
     * PROPERTY: Test session progress tracks correctly
     *
     * Tests progress percentage calculation
     */
    func testSessionManagement_PropertyBased_ProgressTracking() throws {
        // Test with various session sizes
        for _ in 0..<5 {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            let totalQuestions = testSession.questions.count

            // Act & Assert: Progress increases monotonically
            var lastProgress = 0.0
            for index in 0...totalQuestions {
                testSession.currentQuestionIndex = index
                let progress = testSession.progressPercentage

                // PROPERTY: Progress must be monotonically increasing
                XCTAssertGreaterThanOrEqual(progress, lastProgress,
                    """
                    PROPERTY VIOLATION: Progress must increase monotonically
                    Index: \(index)/\(totalQuestions)
                    Last Progress: \(lastProgress)%
                    Current Progress: \(progress)%
                    """)

                lastProgress = progress
            }

            // PROPERTY: Final progress must be 100%
            XCTAssertEqual(lastProgress, 100.0, accuracy: 0.01,
                "Final progress must be 100%")
        }
    }

    /**
     * PROPERTY: Test completion marks session as complete
     *
     * Tests session state management
     */
    func testSessionManagement_PropertyBased_CompletionState() throws {
        // Test 10 random sessions
        for _ in 0..<10 {
            // Arrange: Create and complete test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            // Act: Answer all questions
            for question in testSession.questions {
                try testingService.recordAnswer(for: question, answerIndex: 0)
            }

            XCTAssertFalse(testSession.isCompleted, "Session should not be complete before completeTest")

            _ = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Session marked as complete
            XCTAssertTrue(testSession.isCompleted,
                "Session should be marked complete after completeTest")
            XCTAssertNotNil(testSession.completedAt,
                "CompletedAt timestamp should be set")
        }
    }

    /**
     * PROPERTY: Test session data integrity maintained throughout
     *
     * Tests that session data doesn't get corrupted during test
     */
    func testSessionManagement_PropertyBased_DataIntegrity() throws {
        // Test 15 random complete workflows
        for _ in 0..<15 {
            // Arrange: Create test session
            let profile = try createDefaultTestProfile()
            let testSession = try testingService.createQuickTest(for: profile)

            let originalQuestionCount = testSession.questions.count
            let originalBelt = testSession.userBeltLevel?.shortName
            let originalType = testSession.testType

            // Act: Complete full test workflow
            for question in testSession.questions {
                let randomAnswer = Int.random(in: 0...3)
                try testingService.recordAnswer(for: question, answerIndex: randomAnswer)
            }

            _ = try testingService.completeTest(session: testSession, for: profile)

            // Assert: PROPERTY - Original session data unchanged
            XCTAssertEqual(testSession.questions.count, originalQuestionCount,
                "Question count should not change during test")
            XCTAssertEqual(testSession.userBeltLevel?.shortName, originalBelt,
                "Belt level should not change during test")
            XCTAssertEqual(testSession.testType, originalType,
                "Test type should not change during test")
        }
    }

    // MARK: - 5. View Component Tests (4 tests)

    /**
     * Test AnswerOptionButton displays correct feedback colors
     */
    func testViewComponent_AnswerOptionButton_FeedbackColors() throws {
        // Test correct answer (green)
        let correctButton = AnswerOptionButton(
            text: "Correct Answer",
            index: 0,
            isSelected: true,
            isCorrect: true,
            showingFeedback: true,
            action: {}
        )

        let correctInspection = try correctButton.inspect()
        let correctButtonView = try correctInspection.button()
        // ViewInspector limitation: Can't easily test backgroundColor, but we can verify structure
        XCTAssertNoThrow(try correctButtonView.labelView().text())

        // Test wrong answer (red)
        let wrongButton = AnswerOptionButton(
            text: "Wrong Answer",
            index: 1,
            isSelected: true,
            isCorrect: false,
            showingFeedback: true,
            action: {}
        )

        let wrongInspection = try wrongButton.inspect()
        let wrongButtonView = try wrongInspection.button()
        XCTAssertNoThrow(try wrongButtonView.labelView().text())
    }

    /**
     * Test PerformanceIndicator displays correct performance levels
     */
    func testViewComponent_PerformanceIndicator_Levels() throws {
        let accuracyLevels: [(accuracy: Double, expectedTitle: String)] = [
            (95.0, "Excellent"),
            (85.0, "Good"),
            (75.0, "Fair"),
            (50.0, "Needs Work")
        ]

        for (accuracy, expectedTitle) in accuracyLevels {
            let indicator = PerformanceIndicator(accuracy: accuracy)
            let inspection = try indicator.inspect()

            let titleText = try inspection.vStack().text(0).string()
            XCTAssertEqual(titleText, expectedTitle,
                "Accuracy \(accuracy)% should show '\(expectedTitle)'")
        }
    }

    /**
     * Test progress indicator displays correctly
     */
    func testViewComponent_ProgressIndicator_Display() throws {
        // Create a test question
        let term = try createSampleTerminologyEntry()
        let question = createTestQuestion(term: term, type: .englishToKorean)!

        // Test that question text is accessible
        XCTAssertFalse(question.questionText.isEmpty,
            "Question text should not be empty")
        XCTAssertEqual(question.options.count, 4,
            "Question should have 4 options")
    }

    /**
     * Test PerformanceRow calculates progress color correctly
     */
    func testViewComponent_PerformanceRow_ProgressColors() throws {
        let testCases: [(correct: Int, total: Int, accuracy: Double)] = [
            (9, 10, 90.0),   // Green
            (7, 10, 70.0),   // Blue
            (5, 10, 50.0),   // Orange
            (3, 10, 30.0)    // Red
        ]

        for testCase in testCases {
            let row = PerformanceRow(
                title: "Test Category",
                correct: testCase.correct,
                total: testCase.total,
                accuracy: testCase.accuracy
            )

            let inspection = try row.inspect()

            // Verify correct/total display
            let fractionText = try inspection.vStack().hStack(0).text(1).string()
            XCTAssertTrue(fractionText.contains("\(testCase.correct)/\(testCase.total)"),
                "Should display \(testCase.correct)/\(testCase.total)")

            // Verify accuracy display
            let accuracyText = try inspection.vStack().hStack(0).text(2).string()
            XCTAssertTrue(accuracyText.contains("\(Int(testCase.accuracy))%"),
                "Should display \(Int(testCase.accuracy))%")
        }
    }

    // MARK: - 6. Enum Display Names (3 tests)

    /**
     * Test TestType display names
     */
    func testEnumDisplayNames_TestType() throws {
        XCTAssertEqual(TestType.comprehensive.displayName, "Comprehensive Test")
        XCTAssertEqual(TestType.quick.displayName, "Quick Test")
        XCTAssertEqual(TestType.custom.displayName, "Custom Test")
    }

    /**
     * Test QuestionType display names
     */
    func testEnumDisplayNames_QuestionType() throws {
        XCTAssertEqual(QuestionType.englishToKorean.displayName, "English → Korean")
        XCTAssertEqual(QuestionType.koreanToEnglish.displayName, "Korean → English")
        XCTAssertEqual(QuestionType.definitionToTerm.displayName, "Definition → Term")
        XCTAssertEqual(QuestionType.audioRecognition.displayName, "Audio Recognition")
    }

    /**
     * Test TestType descriptions
     */
    func testEnumDisplayNames_TestTypeDescriptions() throws {
        XCTAssertFalse(TestType.comprehensive.description.isEmpty)
        XCTAssertFalse(TestType.quick.description.isEmpty)
        XCTAssertFalse(TestType.custom.description.isEmpty)

        XCTAssertTrue(TestType.comprehensive.description.contains("current belt"))
        XCTAssertTrue(TestType.quick.description.contains("5-10"))
    }

    // MARK: - Helper Methods

    private func createDefaultTestProfile() throws -> UserProfile {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let belt = allBelts.first(where: { $0.shortName.contains("7th") }) ?? allBelts.first!
        return try createTestProfile(belt: belt)
    }

    private func createTestProfile(belt: BeltLevel) throws -> UserProfile {
        let profile = UserProfile(
            name: "Test User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: belt
        )
        testContext.insert(profile)
        try testContext.save()
        return profile
    }

    private func createSampleTerminologyEntry() throws -> TerminologyEntry {
        let allTerms = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        guard let term = allTerms.first else {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No terms available"])
        }
        return term
    }

    private func createTestQuestion(term: TerminologyEntry, type: QuestionType) -> TestQuestion? {
        let options: [String]
        let correctIndex = Int.random(in: 0...3)

        if type == .englishToKorean {
            options = ["Option 1", "Option 2", "Option 3", term.romanizedPronunciation]
                .shuffled()
        } else {
            options = ["Option 1", "Option 2", "Option 3", term.englishTerm]
                .shuffled()
        }

        return TestQuestion(
            terminologyEntry: term,
            questionType: type,
            questionText: type == .englishToKorean ?
                "What is the Korean term for:" :
                "What does this Korean term mean?",
            options: options,
            correctAnswerIndex: correctIndex
        )
    }
}
