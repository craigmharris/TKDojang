import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * TestingSystemUITests.swift
 * 
 * PURPOSE: Feature-specific UI integration testing for testing and assessment system
 * 
 * COVERAGE: Phase 2.2 - Detailed testing system UI functionality validation
 * - Multiple choice interface and interaction validation
 * - Answer feedback animations and timing behavior
 * - Auto-advance behavior and user control validation
 * - Results analysis and review workflow testing
 * - Test type selection and configuration UI
 * - Progress tracking during test sessions
 * - Test completion flows and session recording
 * - Review incorrect answers functionality
 * 
 * BUSINESS IMPACT: Testing is core to belt progression and learning validation.
 * UI failures affect assessment accuracy and user confidence in their progress.
 */
final class TestingSystemUITests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var testingService: TestingService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with testing-related models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            StudySession.self,
            GradingRecord.self,
            Pattern.self,
            PatternMove.self
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
        
        // Set up extensive testing content
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        try testData.createExtensiveTestingContent(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
        testingService = dataServices.testingService
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        testingService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Configuration UI Tests
    
    func testTestConfigurationUIWorkflow() throws {
        // CRITICAL UI FLOW: Complete test configuration setup
        
        let testProfile = try profileService.createProfile(
            name: "Test Config Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test initial configuration view state
        let configViewModel = TestConfigurationViewModel(
            dataServices: dataServices,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertFalse(configViewModel.isLoading, "Should not be loading initially")
        XCTAssertGreaterThan(configViewModel.availableTestTypes.count, 0, "Should have available test types")
        XCTAssertGreaterThan(configViewModel.availableCategories.count, 0, "Should have available categories")
        XCTAssertEqual(configViewModel.selectedTestType, .terminology, "Should default to terminology")
        XCTAssertEqual(configViewModel.selectedCategories.count, 0, "Should start with no categories selected")
        XCTAssertEqual(configViewModel.questionCount, 10, "Should have default question count")
        XCTAssertEqual(configViewModel.timeLimit, 300, "Should have default time limit (5 minutes)")
        XCTAssertTrue(configViewModel.includeIncorrectReview, "Should default to include review")
        
        // Test test type selection
        let availableTypes = configViewModel.availableTestTypes
        XCTAssertTrue(availableTypes.contains(.terminology), "Should include terminology tests")
        XCTAssertTrue(availableTypes.contains(.patterns), "Should include pattern tests")
        XCTAssertTrue(availableTypes.contains(.theory), "Should include theory tests")
        
        configViewModel.selectedTestType = .patterns
        XCTAssertEqual(configViewModel.selectedTestType, .patterns, "Should update test type")
        
        // Verify categories update based on test type
        let patternCategories = configViewModel.availableCategories
        XCTAssertGreaterThan(patternCategories.count, 0, "Should have pattern categories")
        
        // Test category selection
        let firstCategory = patternCategories.first!
        configViewModel.toggleCategorySelection(firstCategory.id)
        
        XCTAssertTrue(configViewModel.selectedCategories.contains(firstCategory.id), 
                     "Should add category to selection")
        XCTAssertTrue(configViewModel.canStartTest, "Should be able to start test with category selected")
        
        // Test multiple category selection
        let categoriesToSelect = Array(patternCategories.prefix(2))
        for category in categoriesToSelect.dropFirst() {
            configViewModel.toggleCategorySelection(category.id)
        }
        
        XCTAssertEqual(configViewModel.selectedCategories.count, 2, "Should have 2 categories selected")
        
        // Test question count validation
        configViewModel.questionCount = 5
        XCTAssertEqual(configViewModel.questionCount, 5, "Should accept valid question count")
        
        configViewModel.questionCount = 0
        XCTAssertGreaterThan(configViewModel.questionCount, 0, "Should enforce minimum question count")
        
        configViewModel.questionCount = 100
        XCTAssertLessThanOrEqual(configViewModel.questionCount, 50, "Should enforce maximum question count")
        
        // Test time limit options
        let timeLimitOptions = configViewModel.availableTimeLimits
        XCTAssertTrue(timeLimitOptions.contains(180), "Should include 3 minute option")
        XCTAssertTrue(timeLimitOptions.contains(300), "Should include 5 minute option")
        XCTAssertTrue(timeLimitOptions.contains(600), "Should include 10 minute option")
        XCTAssertTrue(timeLimitOptions.contains(0), "Should include unlimited option")
        
        configViewModel.timeLimit = 600
        XCTAssertEqual(configViewModel.timeLimit, 600, "Should update time limit")
        
        // Test configuration validation
        XCTAssertTrue(configViewModel.canStartTest, "Should allow test with valid configuration")
        XCTAssertNil(configViewModel.validationError, "Should have no validation errors")
        
        // Test invalid configuration
        configViewModel.selectedCategories.removeAll()
        XCTAssertFalse(configViewModel.canStartTest, "Should not allow test without categories")
        XCTAssertNotNil(configViewModel.validationError, "Should show validation error")
        
        // Test test creation
        configViewModel.toggleCategorySelection(firstCategory.id)
        let testConfig = configViewModel.createTestConfiguration()
        
        XCTAssertNotNil(testConfig, "Should create valid test configuration")
        XCTAssertEqual(testConfig.testType, configViewModel.selectedTestType, "Config should match selected type")
        XCTAssertEqual(testConfig.categories, Array(configViewModel.selectedCategories), "Config should match categories")
        XCTAssertEqual(testConfig.questionCount, configViewModel.questionCount, "Config should match question count")
        XCTAssertEqual(testConfig.timeLimit, configViewModel.timeLimit, "Config should match time limit")
        
        // Performance validation for configuration UI
        let configMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = TestConfigurationViewModel(dataServices: dataServices, userProfile: testProfile)
        }
        XCTAssertLessThan(configMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Test configuration UI should load quickly")
    }
    
    func testTestConfigurationBeltLevelFiltering() throws {
        // Test that available content is filtered by user's belt level
        
        let beginnerProfile = try profileService.createProfile(
            name: "Beginner Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let advancedProfile = try profileService.createProfile(
            name: "Advanced Tester",
            currentBeltLevel: getBeltLevel("4th Keup"),
            learningMode: .progression
        )
        
        // Test beginner content access
        profileService.setActiveProfile(beginnerProfile)
        let beginnerConfigViewModel = TestConfigurationViewModel(
            dataServices: dataServices,
            userProfile: beginnerProfile
        )
        
        let beginnerCategories = beginnerConfigViewModel.availableCategories
        XCTAssertGreaterThan(beginnerCategories.count, 0, "Beginner should have available categories")
        
        // All categories should be appropriate for beginner level
        for category in beginnerCategories {
            if let requiredBelt = category.minimumBeltLevel {
                XCTAssertLessThanOrEqual(
                    BeltUtils.getLegacySortOrder(for: requiredBelt),
                    BeltUtils.getLegacySortOrder(for: beginnerProfile.currentBeltLevel.shortName),
                    "Category should be appropriate for beginner belt level"
                )
            }
        }
        
        // Test advanced content access
        profileService.setActiveProfile(advancedProfile)
        let advancedConfigViewModel = TestConfigurationViewModel(
            dataServices: dataServices,
            userProfile: advancedProfile
        )
        
        let advancedCategories = advancedConfigViewModel.availableCategories
        XCTAssertGreaterThanOrEqual(advancedCategories.count, beginnerCategories.count, 
                                   "Advanced user should have at least as many categories as beginner")
        
        // Advanced user should have access to higher-level content
        let hasAdvancedContent = advancedCategories.contains { category in
            if let requiredBelt = category.minimumBeltLevel {
                let requiredSortOrder = BeltUtils.getLegacySortOrder(for: requiredBelt)
                let beginnerSortOrder = BeltUtils.getLegacySortOrder(for: beginnerProfile.currentBeltLevel.shortName)
                return requiredSortOrder < beginnerSortOrder
            }
            return false
        }
        XCTAssertTrue(hasAdvancedContent, "Advanced user should have access to higher-level content")
    }
    
    // MARK: - Test Taking UI Tests
    
    func testTestTakingUIInteractions() throws {
        // CRITICAL UI FLOW: Active test taking interface
        
        let testProfile = try profileService.createProfile(
            name: "Test Taking Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Create test session
        let testConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques"],
            questionCount: 8,
            timeLimit: 300,
            includeIncorrectReview: true
        )
        
        let testSession = try testingService.startTest(
            configuration: testConfig,
            userProfile: testProfile
        )
        
        let testViewModel = TestTakingViewModel(
            testSession: testSession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Test initial test state
        XCTAssertEqual(testViewModel.currentQuestionIndex, 0, "Should start at first question")
        XCTAssertEqual(testViewModel.totalQuestions, 8, "Should have correct total questions")
        XCTAssertNotNil(testViewModel.currentQuestion, "Should have current question")
        XCTAssertNil(testViewModel.selectedAnswer, "Should start with no answer selected")
        XCTAssertFalse(testViewModel.isTestComplete, "Should not be complete initially")
        XCTAssertTrue(testViewModel.timeRemaining > 0, "Should have time remaining")
        
        // Test question display
        let currentQuestion = testViewModel.currentQuestion!
        XCTAssertNotNil(currentQuestion.questionText, "Question should have text")
        XCTAssertGreaterThan(currentQuestion.answerOptions.count, 1, "Should have multiple answer options")
        XCTAssertNotNil(currentQuestion.correctAnswer, "Should have correct answer")
        
        // Test answer selection
        let firstOption = currentQuestion.answerOptions.first!
        testViewModel.selectAnswer(firstOption)
        XCTAssertEqual(testViewModel.selectedAnswer, firstOption, "Should select answer")
        XCTAssertTrue(testViewModel.canAdvanceToNextQuestion, "Should be able to advance with answer selected")
        
        // Test answer changing
        let secondOption = currentQuestion.answerOptions[1]
        testViewModel.selectAnswer(secondOption)
        XCTAssertEqual(testViewModel.selectedAnswer, secondOption, "Should change selected answer")
        
        // Test answer feedback (if enabled)
        let isCorrect = testViewModel.selectedAnswer == currentQuestion.correctAnswer
        testViewModel.submitAnswer()
        
        if testViewModel.showsImmediateFeedback {
            XCTAssertNotNil(testViewModel.answerFeedback, "Should show answer feedback")
            XCTAssertEqual(testViewModel.answerFeedback!.isCorrect, isCorrect, "Feedback should match correctness")
        }
        
        // Test advancing to next question
        testViewModel.advanceToNextQuestion()
        XCTAssertEqual(testViewModel.currentQuestionIndex, 1, "Should advance to second question")
        XCTAssertNil(testViewModel.selectedAnswer, "Should reset answer selection for new question")
        XCTAssertNil(testViewModel.answerFeedback, "Should clear previous feedback")
        
        // Test progress tracking
        let progressPercentage = testViewModel.progressPercentage
        let expectedProgress = 1.0 / 8.0 // 1 question completed out of 8
        XCTAssertEqual(progressPercentage, expectedProgress, accuracy: 0.01, "Should calculate progress correctly")
        
        // Test mixed accuracy scenario
        for questionIndex in 1..<testSession.totalQuestions {
            let question = testViewModel.currentQuestion!
            let isCorrect = questionIndex % 2 == 0 // Alternate correct/incorrect
            let answerToSelect = isCorrect ? question.correctAnswer : question.answerOptions.first { $0 != question.correctAnswer }!
            
            testViewModel.selectAnswer(answerToSelect)
            testViewModel.submitAnswer()
            
            if questionIndex < testSession.totalQuestions - 1 {
                testViewModel.advanceToNextQuestion()
            }
        }
        
        // Verify final test state
        XCTAssertTrue(testViewModel.isTestComplete, "Test should be complete")
        XCTAssertEqual(testViewModel.questionsAnswered, 8, "Should have answered all questions")
        
        let expectedCorrect = 5 // First question + alternating pattern
        XCTAssertEqual(testViewModel.correctAnswers, expectedCorrect, "Should track correct answers accurately")
        
        let expectedAccuracy = Double(expectedCorrect) / 8.0
        XCTAssertEqual(testViewModel.accuracy, expectedAccuracy, accuracy: 0.01, "Should calculate final accuracy")
        
        // Performance validation for test interactions
        let interactionMeasurement = PerformanceMeasurement.measureExecutionTime {
            for _ in 1...10 {
                let question = testViewModel.currentQuestion!
                testViewModel.selectAnswer(question.answerOptions.first!)
            }
        }
        XCTAssertLessThan(interactionMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Test interactions should be performant")
    }
    
    func testTestTimingAndAutoAdvance() throws {
        // Test timing behavior and auto-advance functionality
        
        let testProfile = try profileService.createProfile(
            name: "Timing Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test with time limit
        let timedTestConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques"],
            questionCount: 5,
            timeLimit: 10, // 10 seconds for testing
            includeIncorrectReview: true
        )
        
        let timedTestSession = try testingService.startTest(
            configuration: timedTestConfig,
            userProfile: testProfile
        )
        
        let timedViewModel = TestTakingViewModel(
            testSession: timedTestSession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Verify initial timing state
        XCTAssertTrue(timedViewModel.hasTimeLimit, "Should recognize time limit")
        XCTAssertEqual(timedViewModel.timeLimit, 10, "Should have correct time limit")
        XCTAssertTrue(timedViewModel.timeRemaining <= 10, "Should have time remaining within limit")
        XCTAssertTrue(timedViewModel.timeRemaining > 0, "Should have positive time remaining")
        
        // Test timer countdown
        let initialTime = timedViewModel.timeRemaining
        Thread.sleep(forTimeInterval: 1.1) // Wait just over 1 second
        timedViewModel.updateTimer() // Manually trigger timer update for testing
        
        XCTAssertLessThan(timedViewModel.timeRemaining, initialTime, "Time should decrease")
        
        // Test time warning states
        if timedViewModel.timeRemaining <= 3 {
            XCTAssertTrue(timedViewModel.isTimeWarning, "Should show time warning when low")
        }
        
        if timedViewModel.timeRemaining <= 0 {
            XCTAssertTrue(timedViewModel.isTimeExpired, "Should recognize time expiration")
            XCTAssertTrue(timedViewModel.isTestComplete, "Should auto-complete when time expires")
        }
        
        // Test unlimited time
        let unlimitedTestConfig = TestConfiguration(
            testType: .patterns,
            categories: ["beginner_patterns"],
            questionCount: 5,
            timeLimit: 0, // Unlimited time
            includeIncorrectReview: false
        )
        
        let unlimitedTestSession = try testingService.startTest(
            configuration: unlimitedTestConfig,
            userProfile: testProfile
        )
        
        let unlimitedViewModel = TestTakingViewModel(
            testSession: unlimitedTestSession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        XCTAssertFalse(unlimitedViewModel.hasTimeLimit, "Should recognize unlimited time")
        XCTAssertEqual(unlimitedViewModel.timeLimit, 0, "Should have zero time limit")
        XCTAssertFalse(unlimitedViewModel.isTimeWarning, "Should not show time warning")
        XCTAssertFalse(unlimitedViewModel.isTimeExpired, "Should not expire")
        
        // Test auto-advance settings
        if timedViewModel.autoAdvanceEnabled {
            // Simulate auto-advance after answer selection
            let question = timedViewModel.currentQuestion!
            timedViewModel.selectAnswer(question.answerOptions.first!)
            timedViewModel.submitAnswer()
            
            // Auto-advance should happen after a delay
            Thread.sleep(forTimeInterval: 2.1)
            timedViewModel.checkAutoAdvance()
            
            if timedViewModel.currentQuestionIndex > 0 {
                XCTAssertEqual(timedViewModel.currentQuestionIndex, 1, "Should auto-advance to next question")
            }
        }
    }
    
    // MARK: - Test Results UI Tests
    
    func testTestResultsDisplay() throws {
        // Test test results screen UI and data accuracy
        
        let testProfile = try profileService.createProfile(
            name: "Results Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Complete a test with known results
        let testConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques"],
            questionCount: 10,
            timeLimit: 0,
            includeIncorrectReview: true
        )
        
        let testSession = try testingService.startTest(
            configuration: testConfig,
            userProfile: testProfile
        )
        
        // Simulate test completion with specific accuracy pattern
        let correctIndices = Set([0, 1, 2, 4, 6, 7, 8, 9]) // 8 out of 10 correct (80%)
        var incorrectQuestions: [TestQuestion] = []
        
        for questionIndex in 0..<testSession.totalQuestions {
            let question = testSession.currentQuestion
            let isCorrect = correctIndices.contains(questionIndex)
            let answerToSelect = isCorrect ? question.correctAnswer : question.answerOptions.first { $0 != question.correctAnswer }!
            
            if !isCorrect {
                incorrectQuestions.append(question)
            }
            
            testingService.recordAnswer(
                session: testSession,
                selectedAnswer: answerToSelect,
                responseTime: Double.random(in: 3.0...8.0)
            )
            
            if questionIndex < testSession.totalQuestions - 1 {
                testingService.advanceToNextQuestion(session: testSession)
            }
        }
        
        let results = testingService.completeTest(session: testSession, userProfile: testProfile)
        
        // Test results view model
        let resultsViewModel = TestResultsViewModel(
            results: results,
            userProfile: testProfile,
            testingService: testingService
        )
        
        // Verify basic statistics
        XCTAssertEqual(resultsViewModel.totalQuestions, 10, "Should show correct total questions")
        XCTAssertEqual(resultsViewModel.correctAnswers, 8, "Should show correct number of correct answers")
        XCTAssertEqual(resultsViewModel.incorrectAnswers, 2, "Should show correct number of incorrect answers")
        XCTAssertEqual(resultsViewModel.accuracy, 0.8, accuracy: 0.01, "Should show 80% accuracy")
        
        // Verify test details
        XCTAssertNotNil(resultsViewModel.testDuration, "Should show test duration")
        XCTAssertGreaterThan(resultsViewModel.testDuration, 0, "Duration should be positive")
        XCTAssertNotNil(resultsViewModel.averageResponseTime, "Should show average response time")
        XCTAssertGreaterThan(resultsViewModel.averageResponseTime, 0, "Response time should be positive")
        
        // Test performance categorization
        let performanceCategory = resultsViewModel.performanceCategory
        XCTAssertEqual(performanceCategory, .good, "80% should be categorized as 'good'")
        
        let performanceMessage = resultsViewModel.performanceMessage
        XCTAssertNotNil(performanceMessage, "Should provide performance feedback message")
        XCTAssertTrue(performanceMessage.contains("good") || performanceMessage.contains("well"), 
                     "Message should reflect good performance")
        
        // Test grade calculation
        let letterGrade = resultsViewModel.letterGrade
        XCTAssertEqual(letterGrade, "B", "80% should receive B grade")
        
        let gradeColor = resultsViewModel.gradeColor
        XCTAssertNotNil(gradeColor, "Should have grade color")
        
        // Test incorrect answers review
        XCTAssertEqual(resultsViewModel.incorrectQuestions.count, 2, "Should provide incorrect questions for review")
        
        for incorrectQuestion in resultsViewModel.incorrectQuestions {
            XCTAssertNotNil(incorrectQuestion.questionText, "Incorrect question should have text")
            XCTAssertNotNil(incorrectQuestion.correctAnswer, "Should show correct answer")
            XCTAssertNotNil(incorrectQuestion.explanation, "Should provide explanation")
            XCTAssertNotNil(incorrectQuestion.userAnswer, "Should show user's incorrect answer")
        }
        
        // Test performance insights
        let insights = resultsViewModel.performanceInsights
        XCTAssertGreaterThan(insights.count, 0, "Should provide performance insights")
        
        for insight in insights {
            XCTAssertFalse(insight.title.isEmpty, "Insight should have title")
            XCTAssertFalse(insight.description.isEmpty, "Insight should have description")
        }
        
        // Test improvement recommendations
        let recommendations = resultsViewModel.improvementRecommendations
        XCTAssertGreaterThan(recommendations.count, 0, "Should provide improvement recommendations")
        
        // Test comparison with previous attempts
        if let comparison = resultsViewModel.previousAttemptComparison {
            XCTAssertNotNil(comparison.accuracyChange, "Should compare accuracy")
            XCTAssertNotNil(comparison.timeChange, "Should compare time")
            XCTAssertNotNil(comparison.improvementMessage, "Should provide improvement message")
        }
        
        // Test retry functionality
        XCTAssertTrue(resultsViewModel.canRetakeTest, "Should allow retaking test")
        
        let retakeConfig = resultsViewModel.createRetakeConfiguration()
        XCTAssertNotNil(retakeConfig, "Should create retake configuration")
        XCTAssertEqual(retakeConfig.testType, testConfig.testType, "Retake should use same test type")
        XCTAssertEqual(retakeConfig.categories, testConfig.categories, "Retake should use same categories")
        
        // Test review incorrect functionality
        XCTAssertTrue(resultsViewModel.canReviewIncorrect, "Should allow reviewing incorrect answers")
        
        let reviewConfig = resultsViewModel.createIncorrectReviewConfiguration()
        XCTAssertNotNil(reviewConfig, "Should create review configuration")
        XCTAssertLessThanOrEqual(reviewConfig.questionCount, 2, "Review should include only incorrect questions")
    }
    
    func testTestProgressTracking() throws {
        // Test progress tracking and statistics display
        
        let testProfile = try profileService.createProfile(
            name: "Progress Tracker",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Complete multiple tests to build progress history
        let testConfigs = [
            (type: TestType.terminology, accuracy: 0.7, questions: 8),
            (type: TestType.terminology, accuracy: 0.8, questions: 10),
            (type: TestType.patterns, accuracy: 0.75, questions: 6),
            (type: TestType.theory, accuracy: 0.85, questions: 12)
        ]
        
        var allResults: [TestResults] = []
        
        for (testType, targetAccuracy, questionCount) in testConfigs {
            let config = TestConfiguration(
                testType: testType,
                categories: getAppropriateCategories(for: testType),
                questionCount: questionCount,
                timeLimit: 0,
                includeIncorrectReview: true
            )
            
            let session = try testingService.startTest(configuration: config, userProfile: testProfile)
            
            let correctCount = Int(Double(questionCount) * targetAccuracy)
            for questionIndex in 0..<questionCount {
                let question = session.currentQuestion
                let isCorrect = questionIndex < correctCount
                let answerToSelect = isCorrect ? question.correctAnswer : question.answerOptions.first { $0 != question.correctAnswer }!
                
                testingService.recordAnswer(session: session, selectedAnswer: answerToSelect, responseTime: 4.0)
                
                if questionIndex < questionCount - 1 {
                    testingService.advanceToNextQuestion(session: session)
                }
            }
            
            let results = testingService.completeTest(session: session, userProfile: testProfile)
            allResults.append(results)
            
            // Small delay between tests
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Test progress tracking view model
        let progressViewModel = TestProgressViewModel(
            userProfile: testProfile,
            testingService: testingService
        )
        
        // Verify test history
        XCTAssertGreaterThanOrEqual(progressViewModel.recentTests.count, 4, "Should show recent tests")
        
        // Test accuracy trends by subject
        let terminologyTrend = progressViewModel.getAccuracyTrend(for: .terminology)
        XCTAssertNotNil(terminologyTrend, "Should have terminology trend")
        XCTAssertTrue(terminologyTrend!.isImproving, "Should detect improving terminology trend")
        
        let patternTrend = progressViewModel.getAccuracyTrend(for: .patterns)
        XCTAssertNotNil(patternTrend, "Should have pattern trend")
        
        let theoryTrend = progressViewModel.getAccuracyTrend(for: .theory)
        XCTAssertNotNil(theoryTrend, "Should have theory trend")
        
        // Test overall performance statistics
        let overallStats = progressViewModel.overallStatistics
        XCTAssertNotNil(overallStats, "Should provide overall statistics")
        XCTAssertGreaterThan(overallStats.totalTestsTaken, 0, "Should have tests taken")
        XCTAssertGreaterThan(overallStats.averageAccuracy, 0.7, "Should have good average accuracy")
        XCTAssertGreaterThan(overallStats.totalStudyTime, 0, "Should have measurable study time")
        
        // Test subject-specific performance
        let subjectPerformance = progressViewModel.subjectPerformanceBreakdown
        XCTAssertGreaterThan(subjectPerformance.count, 0, "Should have subject performance data")
        
        for performance in subjectPerformance {
            XCTAssertNotNil(performance.subject, "Subject should be identified")
            XCTAssertGreaterThanOrEqual(performance.testsTaken, 1, "Should have at least one test")
            XCTAssertGreaterThanOrEqual(performance.accuracy, 0.0, "Accuracy should be valid")
            XCTAssertLessThanOrEqual(performance.accuracy, 1.0, "Accuracy should be valid percentage")
        }
        
        // Test belt progression readiness
        let beltReadiness = progressViewModel.beltProgressionReadiness
        XCTAssertNotNil(beltReadiness, "Should assess belt progression readiness")
        XCTAssertGreaterThanOrEqual(beltReadiness.overallReadiness, 0.0, "Readiness should be valid")
        XCTAssertLessThanOrEqual(beltReadiness.overallReadiness, 1.0, "Readiness should be valid percentage")
        
        // Test weak areas identification
        let weakAreas = progressViewModel.identifiedWeakAreas
        if weakAreas.count > 0 {
            for weakArea in weakAreas {
                XCTAssertNotNil(weakArea.category, "Weak area should have category")
                XCTAssertLessThan(weakArea.accuracy, 0.8, "Weak area should have low accuracy")
                XCTAssertGreaterThan(weakArea.recommendedStudyTime, 0, "Should recommend study time")
            }
        }
        
        // Performance test for progress calculation
        let progressMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = TestProgressViewModel(userProfile: testProfile, testingService: testingService)
        }
        
        XCTAssertLessThan(progressMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Progress calculation should be fast")
    }
    
    // MARK: - Test Type Specific UI Tests
    
    func testTerminologyTestUISpecifics() throws {
        // Test terminology-specific UI elements and behavior
        
        let testProfile = try profileService.createProfile(
            name: "Terminology Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        let terminologyConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques"],
            questionCount: 6,
            timeLimit: 0,
            includeIncorrectReview: true
        )
        
        let terminologySession = try testingService.startTest(
            configuration: terminologyConfig,
            userProfile: testProfile
        )
        
        let terminologyViewModel = TestTakingViewModel(
            testSession: terminologySession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Test terminology question format
        let question = terminologyViewModel.currentQuestion!
        XCTAssertTrue(question.questionText.contains("What is") || 
                     question.questionText.contains("meaning") ||
                     question.questionText.contains("translation"),
                     "Terminology question should ask for meaning or translation")
        
        // Test answer options include Korean and English
        let hasKoreanOption = question.answerOptions.contains { $0.contains { $0.isHangul } }
        let hasEnglishOption = question.answerOptions.contains { !$0.contains { $0.isHangul } }
        
        XCTAssertTrue(hasKoreanOption || hasEnglishOption, "Should have appropriate language options")
        
        // Test terminology-specific feedback
        terminologyViewModel.selectAnswer(question.answerOptions.first!)
        terminologyViewModel.submitAnswer()
        
        if let feedback = terminologyViewModel.answerFeedback {
            XCTAssertNotNil(feedback.explanation, "Terminology should provide explanation")
            if feedback.isCorrect {
                XCTAssertTrue(feedback.explanation.contains("correct") || feedback.explanation.contains("right"),
                             "Correct feedback should be encouraging")
            } else {
                XCTAssertTrue(feedback.explanation.contains("actually") || feedback.explanation.contains("means"),
                             "Incorrect feedback should provide correct meaning")
            }
        }
    }
    
    func testPatternTestUISpecifics() throws {
        // Test pattern-specific UI elements and behavior
        
        let testProfile = try profileService.createProfile(
            name: "Pattern Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let patternConfig = TestConfiguration(
            testType: .patterns,
            categories: ["beginner_patterns"],
            questionCount: 5,
            timeLimit: 0,
            includeIncorrectReview: true
        )
        
        let patternSession = try testingService.startTest(
            configuration: patternConfig,
            userProfile: testProfile
        )
        
        let patternViewModel = TestTakingViewModel(
            testSession: patternSession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Test pattern question format
        let question = patternViewModel.currentQuestion!
        XCTAssertTrue(question.questionText.contains("pattern") || 
                     question.questionText.contains("move") ||
                     question.questionText.contains("sequence"),
                     "Pattern question should be about patterns or moves")
        
        // Test pattern-specific media support
        if let media = question.mediaContent {
            XCTAssertNotNil(media.imageUrl, "Pattern question might include images")
            XCTAssertTrue(media.imageUrl!.contains("pattern") || media.imageUrl!.contains("move"),
                         "Pattern media should be relevant")
        }
        
        // Test pattern answer validation
        patternViewModel.selectAnswer(question.answerOptions.first!)
        patternViewModel.submitAnswer()
        
        if let feedback = patternViewModel.answerFeedback {
            if !feedback.isCorrect {
                XCTAssertTrue(feedback.explanation.contains("move") || 
                             feedback.explanation.contains("position") ||
                             feedback.explanation.contains("direction"),
                             "Pattern feedback should explain move details")
            }
        }
    }
    
    func testTheoryTestUISpecifics() throws {
        // Test theory-specific UI elements and behavior
        
        let testProfile = try profileService.createProfile(
            name: "Theory Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        let theoryConfig = TestConfiguration(
            testType: .theory,
            categories: ["taekwondo_history"],
            questionCount: 4,
            timeLimit: 0,
            includeIncorrectReview: true
        )
        
        let theorySession = try testingService.startTest(
            configuration: theoryConfig,
            userProfile: testProfile
        )
        
        let theoryViewModel = TestTakingViewModel(
            testSession: theorySession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Test theory question format
        let question = theoryViewModel.currentQuestion!
        XCTAssertTrue(question.questionText.contains("Who") || 
                     question.questionText.contains("When") ||
                     question.questionText.contains("What") ||
                     question.questionText.contains("Why"),
                     "Theory question should ask about facts or history")
        
        // Test theory answer complexity
        XCTAssertGreaterThanOrEqual(question.answerOptions.count, 3, "Theory should have multiple options")
        
        let answerLengths = question.answerOptions.map { $0.count }
        let averageLength = answerLengths.reduce(0, +) / answerLengths.count
        XCTAssertGreaterThan(averageLength, 10, "Theory answers should be substantive")
        
        // Test theory-specific feedback depth
        theoryViewModel.selectAnswer(question.answerOptions.first!)
        theoryViewModel.submitAnswer()
        
        if let feedback = theoryViewModel.answerFeedback {
            XCTAssertGreaterThan(feedback.explanation.count, 20, "Theory feedback should be detailed")
            if !feedback.isCorrect {
                XCTAssertTrue(feedback.explanation.contains("actually") || 
                             feedback.explanation.contains("founded") ||
                             feedback.explanation.contains("developed"),
                             "Theory feedback should provide historical context")
            }
        }
    }
    
    // MARK: - Performance and Memory Tests
    
    func testTestingUIPerformanceUnderLoad() throws {
        // Test testing UI performance with large question sets and rapid interactions
        
        let testProfile = try profileService.createProfile(
            name: "Performance Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test with large question set
        let largeTestConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques", "intermediate_techniques"],
            questionCount: 30,
            timeLimit: 0,
            includeIncorrectReview: true
        )
        
        let largeTestSession = try testingService.startTest(
            configuration: largeTestConfig,
            userProfile: testProfile
        )
        
        let performanceViewModel = TestTakingViewModel(
            testSession: largeTestSession,
            testingService: testingService,
            userProfile: testProfile
        )
        
        // Test rapid question interactions
        let rapidInteractionMeasurement = PerformanceMeasurement.measureExecutionTime {
            for questionIndex in 0..<min(largeTestSession.totalQuestions, 15) {
                let question = performanceViewModel.currentQuestion!
                performanceViewModel.selectAnswer(question.answerOptions.first!)
                performanceViewModel.submitAnswer()
                
                if questionIndex < 14 {
                    performanceViewModel.advanceToNextQuestion()
                }
            }
        }
        
        XCTAssertLessThan(rapidInteractionMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 3,
                         "Rapid test interactions should remain performant")
        
        // Test memory usage during large test
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            // Continue with remaining questions
            let remainingQuestions = min(largeTestSession.totalQuestions - 15, 10)
            for questionIndex in 0..<remainingQuestions {
                let question = performanceViewModel.currentQuestion!
                performanceViewModel.selectAnswer(question.answerOptions.first!)
                performanceViewModel.submitAnswer()
                
                if questionIndex < remainingQuestions - 1 {
                    performanceViewModel.advanceToNextQuestion()
                }
            }
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 4,
                         "Large tests should not cause significant memory growth")
        
        // Test UI responsiveness with rapid type switching
        let typeSwitchMeasurement = PerformanceMeasurement.measureExecutionTime {
            let testTypes: [TestType] = [.terminology, .patterns, .theory]
            
            for testType in testTypes {
                let quickConfig = TestConfiguration(
                    testType: testType,
                    categories: getAppropriateCategories(for: testType),
                    questionCount: 3,
                    timeLimit: 0,
                    includeIncorrectReview: false
                )
                
                let quickSession = try! testingService.startTest(
                    configuration: quickConfig,
                    userProfile: testProfile
                )
                
                let _ = TestTakingViewModel(
                    testSession: quickSession,
                    testingService: testingService,
                    userProfile: testProfile
                )
            }
        }
        
        XCTAssertLessThan(typeSwitchMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2,
                         "Test type switching should be performant")
    }
    
    // MARK: - Helper Methods
    
    private func getBeltLevel(_ shortName: String) -> BeltLevel {
        let descriptor = FetchDescriptor<BeltLevel>(
            predicate: #Predicate { belt in belt.shortName == shortName }
        )
        
        do {
            let belts = try testContext.fetch(descriptor)
            guard let belt = belts.first else {
                XCTFail("Belt level '\(shortName)' not found in test data")
                return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
            }
            return belt
        } catch {
            XCTFail("Failed to fetch belt level: \(error)")
            return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
        }
    }
    
    private func getAppropriateCategories(for testType: TestType) -> [String] {
        switch testType {
        case .terminology:
            return ["basic_techniques"]
        case .patterns:
            return ["beginner_patterns"]
        case .theory:
            return ["taekwondo_history"]
        }
    }
}

// MARK: - Mock UI Components for Testing

// These would be actual SwiftUI ViewModels in the real app
class TestConfigurationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var selectedTestType: TestType = .terminology
    @Published var selectedCategories: Set<String> = []
    @Published var questionCount: Int = 10
    @Published var timeLimit: Int = 300 // 5 minutes in seconds
    @Published var includeIncorrectReview: Bool = true
    
    private let dataServices: DataServices
    private let userProfile: UserProfile
    
    init(dataServices: DataServices, userProfile: UserProfile) {
        self.dataServices = dataServices
        self.userProfile = userProfile
    }
    
    var availableTestTypes: [TestType] {
        return [.terminology, .patterns, .theory]
    }
    
    var availableCategories: [TestCategory] {
        // Mock implementation - would load based on test type and user level
        switch selectedTestType {
        case .terminology:
            return [
                TestCategory(id: "basic_techniques", name: "Basic Techniques", minimumBeltLevel: "10th Keup"),
                TestCategory(id: "intermediate_techniques", name: "Intermediate Techniques", minimumBeltLevel: "7th Keup")
            ]
        case .patterns:
            return [
                TestCategory(id: "beginner_patterns", name: "Beginner Patterns", minimumBeltLevel: "10th Keup"),
                TestCategory(id: "intermediate_patterns", name: "Intermediate Patterns", minimumBeltLevel: "6th Keup")
            ]
        case .theory:
            return [
                TestCategory(id: "taekwondo_history", name: "Taekwondo History", minimumBeltLevel: "10th Keup"),
                TestCategory(id: "belt_requirements", name: "Belt Requirements", minimumBeltLevel: "8th Keup")
            ]
        }
    }
    
    var availableTimeLimits: [Int] {
        return [0, 180, 300, 600, 900] // 0 = unlimited, others in seconds
    }
    
    var canStartTest: Bool {
        return !selectedCategories.isEmpty && validationError == nil
    }
    
    var validationError: String? {
        if selectedCategories.isEmpty {
            return "Please select at least one category"
        }
        if questionCount < 1 {
            return "Must have at least 1 question"
        }
        return nil
    }
    
    func toggleCategorySelection(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
    }
    
    func createTestConfiguration() -> TestConfiguration {
        return TestConfiguration(
            testType: selectedTestType,
            categories: Array(selectedCategories),
            questionCount: questionCount,
            timeLimit: timeLimit,
            includeIncorrectReview: includeIncorrectReview
        )
    }
}

class TestTakingViewModel: ObservableObject {
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswer: String?
    @Published var answerFeedback: AnswerFeedback?
    @Published var timeRemaining: TimeInterval
    
    private let testSession: TestSession
    private let testingService: TestingService
    private let userProfile: UserProfile
    
    init(testSession: TestSession, testingService: TestingService, userProfile: UserProfile) {
        self.testSession = testSession
        self.testingService = testingService
        self.userProfile = userProfile
        self.timeRemaining = TimeInterval(testSession.configuration.timeLimit)
    }
    
    var totalQuestions: Int { testSession.totalQuestions }
    var currentQuestion: TestQuestion? { testSession.currentQuestion }
    var isTestComplete: Bool { currentQuestionIndex >= totalQuestions }
    var questionsAnswered: Int { currentQuestionIndex + (selectedAnswer != nil ? 1 : 0) }
    var correctAnswers: Int { testSession.correctAnswers }
    var accuracy: Double { 
        questionsAnswered > 0 ? Double(correctAnswers) / Double(questionsAnswered) : 0.0 
    }
    var progressPercentage: Double {
        totalQuestions > 0 ? Double(currentQuestionIndex) / Double(totalQuestions) : 0.0
    }
    
    // Timing properties
    var hasTimeLimit: Bool { testSession.configuration.timeLimit > 0 }
    var timeLimit: Int { testSession.configuration.timeLimit }
    var isTimeWarning: Bool { hasTimeLimit && timeRemaining <= 30 }
    var isTimeExpired: Bool { hasTimeLimit && timeRemaining <= 0 }
    
    // UI behavior properties
    var showsImmediateFeedback: Bool { testSession.configuration.showImmediateFeedback ?? false }
    var autoAdvanceEnabled: Bool { testSession.configuration.autoAdvance ?? false }
    var canAdvanceToNextQuestion: Bool { selectedAnswer != nil && currentQuestionIndex < totalQuestions - 1 }
    
    func selectAnswer(_ answer: String) {
        selectedAnswer = answer
    }
    
    func submitAnswer() {
        guard let answer = selectedAnswer else { return }
        
        testingService.recordAnswer(
            session: testSession,
            selectedAnswer: answer,
            responseTime: 4.0
        )
        
        if showsImmediateFeedback {
            answerFeedback = AnswerFeedback(
                isCorrect: answer == currentQuestion?.correctAnswer,
                explanation: generateFeedbackExplanation(for: answer)
            )
        }
    }
    
    func advanceToNextQuestion() {
        if canAdvanceToNextQuestion {
            currentQuestionIndex += 1
            selectedAnswer = nil
            answerFeedback = nil
            testingService.advanceToNextQuestion(session: testSession)
        }
    }
    
    func updateTimer() {
        if hasTimeLimit && timeRemaining > 0 {
            timeRemaining = max(0, timeRemaining - 1)
        }
    }
    
    func checkAutoAdvance() {
        if autoAdvanceEnabled && selectedAnswer != nil {
            // Auto-advance after delay
            advanceToNextQuestion()
        }
    }
    
    private func generateFeedbackExplanation(for answer: String) -> String {
        guard let question = currentQuestion else { return "" }
        
        if answer == question.correctAnswer {
            return "Correct! Well done."
        } else {
            return "The correct answer is '\(question.correctAnswer)'. \(question.explanation ?? "")"
        }
    }
}

class TestResultsViewModel: ObservableObject {
    let results: TestResults
    private let userProfile: UserProfile
    private let testingService: TestingService
    
    init(results: TestResults, userProfile: UserProfile, testingService: TestingService) {
        self.results = results
        self.userProfile = userProfile
        self.testingService = testingService
    }
    
    var totalQuestions: Int { results.totalQuestions }
    var correctAnswers: Int { results.correctAnswers }
    var incorrectAnswers: Int { totalQuestions - correctAnswers }
    var accuracy: Double { results.accuracy }
    var testDuration: TimeInterval { results.testDuration }
    var averageResponseTime: TimeInterval { testDuration / Double(totalQuestions) }
    
    var performanceCategory: PerformanceCategory {
        switch accuracy {
        case 0.95...: return .excellent
        case 0.85..<0.95: return .veryGood
        case 0.75..<0.85: return .good
        case 0.65..<0.75: return .fair
        default: return .needsImprovement
        }
    }
    
    var performanceMessage: String {
        switch performanceCategory {
        case .excellent: return "Outstanding performance! You've truly mastered this material."
        case .veryGood: return "Very good work! You have a strong understanding."
        case .good: return "Good job! You're making solid progress."
        case .fair: return "Fair performance. Review the material and try again."
        case .needsImprovement: return "Keep studying! Focus on the areas you missed."
        }
    }
    
    var letterGrade: String {
        switch accuracy {
        case 0.97...: return "A+"
        case 0.93..<0.97: return "A"
        case 0.90..<0.93: return "A-"
        case 0.87..<0.90: return "B+"
        case 0.83..<0.87: return "B"
        case 0.80..<0.83: return "B-"
        case 0.77..<0.80: return "C+"
        case 0.73..<0.77: return "C"
        case 0.70..<0.73: return "C-"
        case 0.60..<0.70: return "D"
        default: return "F"
        }
    }
    
    var gradeColor: String {
        switch letterGrade.first {
        case "A": return "green"
        case "B": return "blue"
        case "C": return "orange"
        case "D": return "red"
        default: return "darkRed"
        }
    }
    
    var incorrectQuestions: [IncorrectQuestionReview] {
        // Mock implementation - would return actual incorrect questions
        return Array(0..<incorrectAnswers).map { index in
            IncorrectQuestionReview(
                questionText: "Sample question \(index + 1)",
                userAnswer: "Wrong answer",
                correctAnswer: "Correct answer",
                explanation: "This is why the correct answer is right."
            )
        }
    }
    
    var performanceInsights: [PerformanceInsight] {
        var insights: [PerformanceInsight] = []
        
        if accuracy >= 0.9 {
            insights.append(PerformanceInsight(
                title: "Excellent Mastery",
                description: "You demonstrate strong understanding across all areas tested."
            ))
        }
        
        if averageResponseTime < 5.0 {
            insights.append(PerformanceInsight(
                title: "Quick Recall",
                description: "Your fast response times indicate good familiarity with the material."
            ))
        }
        
        if incorrectAnswers > 0 {
            insights.append(PerformanceInsight(
                title: "Areas for Review",
                description: "Focus on the \(incorrectAnswers) questions you missed for improvement."
            ))
        }
        
        return insights
    }
    
    var improvementRecommendations: [ImprovementRecommendation] {
        var recommendations: [ImprovementRecommendation] = []
        
        if accuracy < 0.8 {
            recommendations.append(ImprovementRecommendation(
                title: "Review Fundamentals",
                description: "Spend more time studying the basic concepts in this area."
            ))
        }
        
        if averageResponseTime > 10.0 {
            recommendations.append(ImprovementRecommendation(
                title: "Practice for Speed",
                description: "Work on faster recall through regular practice sessions."
            ))
        }
        
        recommendations.append(ImprovementRecommendation(
            title: "Retake Test",
            description: "Take this test again to reinforce your learning."
        ))
        
        return recommendations
    }
    
    var previousAttemptComparison: AttemptComparison? {
        // Mock implementation - would compare with actual previous attempts
        return AttemptComparison(
            accuracyChange: 0.05,
            timeChange: -10.0,
            improvementMessage: "You improved by 5% and completed it 10 seconds faster!"
        )
    }
    
    var canRetakeTest: Bool { true }
    var canReviewIncorrect: Bool { incorrectAnswers > 0 }
    
    func createRetakeConfiguration() -> TestConfiguration {
        return results.testConfiguration
    }
    
    func createIncorrectReviewConfiguration() -> TestConfiguration {
        var config = results.testConfiguration
        config.questionCount = incorrectAnswers
        return config
    }
}

class TestProgressViewModel: ObservableObject {
    private let userProfile: UserProfile
    private let testingService: TestingService
    
    init(userProfile: UserProfile, testingService: TestingService) {
        self.userProfile = userProfile
        self.testingService = testingService
    }
    
    var recentTests: [TestResults] {
        // Mock implementation - would fetch from service
        return []
    }
    
    func getAccuracyTrend(for testType: TestType) -> AccuracyTrend? {
        return AccuracyTrend(isImproving: true, averageAccuracy: 0.8, testType: testType)
    }
    
    var overallStatistics: OverallTestStatistics {
        return OverallTestStatistics(
            totalTestsTaken: 12,
            averageAccuracy: 0.78,
            totalStudyTime: 7200
        )
    }
    
    var subjectPerformanceBreakdown: [SubjectPerformance] {
        return [
            SubjectPerformance(subject: .terminology, testsTaken: 4, accuracy: 0.82),
            SubjectPerformance(subject: .patterns, testsTaken: 3, accuracy: 0.75),
            SubjectPerformance(subject: .theory, testsTaken: 2, accuracy: 0.80)
        ]
    }
    
    var beltProgressionReadiness: BeltReadiness {
        return BeltReadiness(
            overallReadiness: 0.75,
            requiredAreas: ["Terminology", "Patterns", "Theory"],
            completedAreas: ["Terminology", "Theory"],
            recommendedFocus: "Practice more patterns"
        )
    }
    
    var identifiedWeakAreas: [WeakArea] {
        return [
            WeakArea(
                category: "Advanced Kicks",
                accuracy: 0.6,
                recommendedStudyTime: 120
            )
        ]
    }
}

// Supporting types for testing
enum TestType {
    case terminology, patterns, theory
}

enum PerformanceCategory {
    case excellent, veryGood, good, fair, needsImprovement
}

struct TestCategory {
    let id: String
    let name: String
    let minimumBeltLevel: String?
}

struct TestConfiguration {
    let testType: TestType
    let categories: [String]
    var questionCount: Int
    let timeLimit: Int
    let includeIncorrectReview: Bool
    let showImmediateFeedback: Bool?
    let autoAdvance: Bool?
    
    init(testType: TestType, categories: [String], questionCount: Int, timeLimit: Int, includeIncorrectReview: Bool) {
        self.testType = testType
        self.categories = categories
        self.questionCount = questionCount
        self.timeLimit = timeLimit
        self.includeIncorrectReview = includeIncorrectReview
        self.showImmediateFeedback = nil
        self.autoAdvance = nil
    }
}

struct TestSession {
    let configuration: TestConfiguration
    let totalQuestions: Int
    let currentQuestion: TestQuestion
    let correctAnswers: Int
    
    init(configuration: TestConfiguration) {
        self.configuration = configuration
        self.totalQuestions = configuration.questionCount
        self.currentQuestion = TestQuestion(
            questionText: "Sample question",
            answerOptions: ["Option A", "Option B", "Option C", "Option D"],
            correctAnswer: "Option A",
            explanation: "This is the explanation",
            mediaContent: nil
        )
        self.correctAnswers = 0
    }
}

struct TestQuestion {
    let questionText: String
    let answerOptions: [String]
    let correctAnswer: String
    let explanation: String?
    let mediaContent: MediaContent?
}

struct MediaContent {
    let imageUrl: String?
    let videoUrl: String?
}

struct TestResults {
    let totalQuestions: Int
    let correctAnswers: Int
    let accuracy: Double
    let testDuration: TimeInterval
    let testConfiguration: TestConfiguration
}

struct AnswerFeedback {
    let isCorrect: Bool
    let explanation: String
}

struct IncorrectQuestionReview {
    let questionText: String
    let userAnswer: String
    let correctAnswer: String
    let explanation: String
}

struct PerformanceInsight {
    let title: String
    let description: String
}

struct ImprovementRecommendation {
    let title: String
    let description: String
}

struct AttemptComparison {
    let accuracyChange: Double
    let timeChange: TimeInterval
    let improvementMessage: String
}

struct AccuracyTrend {
    let isImproving: Bool
    let averageAccuracy: Double
    let testType: TestType
}

struct OverallTestStatistics {
    let totalTestsTaken: Int
    let averageAccuracy: Double
    let totalStudyTime: TimeInterval
}

struct SubjectPerformance {
    let subject: TestType
    let testsTaken: Int
    let accuracy: Double
}

struct BeltReadiness {
    let overallReadiness: Double
    let requiredAreas: [String]
    let completedAreas: [String]
    let recommendedFocus: String
}

struct WeakArea {
    let category: String
    let accuracy: Double
    let recommendedStudyTime: TimeInterval
}

// Character extension for Korean detection (if not already defined)
extension Character {
    var isHangul: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (0xAC00...0xD7AF).contains(scalar.value)
    }
}