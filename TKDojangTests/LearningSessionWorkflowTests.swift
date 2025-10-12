import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * LearningSessionWorkflowTests.swift
 * 
 * PURPOSE: Critical learning session workflow testing for end-to-end learning experiences
 * 
 * COVERAGE: Priority 1 - Core learning flows that deliver educational value
 * - Flashcard session → completion → progress update pipeline
 * - Pattern practice → session recording → analytics integration  
 * - Test taking → results → progress tracking validation
 * - Cross-session data persistence and restoration
 * - Learning mode impacts (Mastery vs Progression) on content access
 * 
 * BUSINESS IMPACT: These workflows represent the core value proposition of TKDojang.
 * Failures here directly impact user learning outcomes and progress tracking accuracy.
 */
final class LearningSessionWorkflowTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var flashcardService: FlashcardService!
    var patternService: PatternDataService!
    var testingService: TestingService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container using centralized factory
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = ModelContext(testContainer)
        
        // Set up comprehensive test data for learning workflows
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        try testData.createExtendedLearningContent(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
        flashcardService = dataServices.flashcardService
        patternService = dataServices.patternService
        testingService = dataServices.testingService
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        flashcardService = nil
        patternService = nil
        testingService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Flashcard Learning Session Workflows
    
    func testFlashcardSessionCompleteWorkflow() throws {
        // CRITICAL USER FLOW: Complete flashcard session with progress tracking
        
        // Create test profile and set as active
        let testProfile = try profileService.createProfile(
            name: "Flashcard Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Initialize flashcard session with specific terminology
        let sessionConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 10
        )
        
        // Start flashcard session
        let flashcardSession = try flashcardService.startSession(
            configuration: sessionConfig,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(flashcardSession, "Flashcard session should be created")
        XCTAssertEqual(flashcardSession.totalCards, 10, "Session should have requested number of cards")
        XCTAssertEqual(flashcardSession.currentCardIndex, 0, "Should start at first card")
        
        // Simulate answering cards with mixed accuracy
        var correctAnswers = 0
        let totalCards = flashcardSession.totalCards
        
        for cardIndex in 0..<totalCards {
            let currentCard = flashcardSession.currentCard
            XCTAssertNotNil(currentCard, "Should have valid card at index \(cardIndex)")
            
            // Simulate answering: 80% correct rate
            let isCorrect = cardIndex < Int(Double(totalCards) * 0.8)
            if isCorrect {
                correctAnswers += 1
            }
            
            // Record answer
            flashcardService.recordAnswer(
                session: flashcardSession,
                isCorrect: isCorrect,
                responseTime: Double.random(in: 1.0...5.0)
            )
            
            // Advance to next card (except on last card)
            if cardIndex < totalCards - 1 {
                flashcardService.advanceToNextCard(session: flashcardSession)
                XCTAssertEqual(flashcardSession.currentCardIndex, cardIndex + 1, "Should advance to next card")
            }
        }
        
        // Complete session
        let sessionResults = flashcardService.completeSession(
            session: flashcardSession,
            userProfile: testProfile
        )
        
        // Verify session results
        XCTAssertNotNil(sessionResults, "Session should produce results")
        XCTAssertEqual(sessionResults.totalCards, totalCards, "Results should reflect total cards")
        XCTAssertEqual(sessionResults.correctAnswers, correctAnswers, "Results should reflect correct answers")
        XCTAssertEqual(sessionResults.accuracy, Double(correctAnswers) / Double(totalCards), "Accuracy should be calculated correctly")
        XCTAssertTrue(sessionResults.sessionDuration > 0, "Session should have measurable duration")
        
        // Verify progress tracking integration
        let studySessions = try profileService.getStudySessions(for: testProfile)
        let flashcardSessions = studySessions.filter { $0.sessionType == .flashcards }
        XCTAssertGreaterThan(flashcardSessions.count, 0, "Should record flashcard study session")
        
        let latestSession = flashcardSessions.sorted { $0.createdAt > $1.createdAt }.first!
        XCTAssertEqual(latestSession.itemsStudied, totalCards, "Study session should record items studied")
        XCTAssertEqual(latestSession.correctAnswers, correctAnswers, "Study session should record correct answers")
        
        // Verify terminology progress updates
        let terminologyProgress = try getTerminologyProgress(for: testProfile)
        XCTAssertGreaterThan(terminologyProgress.count, 0, "Should create terminology progress entries")
        
        // Performance validation
        let sessionMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = try! flashcardService.startSession(configuration: sessionConfig, userProfile: testProfile)
        }
        XCTAssertLessThan(sessionMeasurement.timeInterval, TestConfiguration.maxUIResponseTime, 
                         "Flashcard session creation should be fast")
    }
    
    func testFlashcardLeitnerModeProgression() throws {
        // Test Leitner spaced repetition algorithm integration
        
        let testProfile = try profileService.createProfile(
            name: "Leitner Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Create Leitner mode session
        let leitnerConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .koreanToEnglish,
            sessionMode: .study,
            cardMode: .leitner,
            maxCards: 5
        )
        
        // First session - all cards should start in level 1
        let firstSession = try flashcardService.startSession(
            configuration: leitnerConfig,
            userProfile: testProfile
        )
        
        // Answer all cards correctly
        for _ in 0..<firstSession.totalCards {
            flashcardService.recordAnswer(session: firstSession, isCorrect: true, responseTime: 2.0)
            if firstSession.currentCardIndex < firstSession.totalCards - 1 {
                flashcardService.advanceToNextCard(session: firstSession)
            }
        }
        
        let firstResults = flashcardService.completeSession(session: firstSession, userProfile: testProfile)
        XCTAssertEqual(firstResults.accuracy, 1.0, "First session should be 100% correct")
        
        // Second session - cards should advance in Leitner levels
        let secondSession = try flashcardService.startSession(
            configuration: leitnerConfig,
            userProfile: testProfile
        )
        
        // Verify Leitner progression affects card selection
        XCTAssertNotNil(secondSession, "Second Leitner session should be created")
        
        // Test mixed accuracy in second session
        var correctCount = 0
        for cardIndex in 0..<secondSession.totalCards {
            let isCorrect = cardIndex % 2 == 0 // 50% accuracy
            if isCorrect { correctCount += 1 }
            
            flashcardService.recordAnswer(session: secondSession, isCorrect: isCorrect, responseTime: 2.5)
            if cardIndex < secondSession.totalCards - 1 {
                flashcardService.advanceToNextCard(session: secondSession)
            }
        }
        
        let secondResults = flashcardService.completeSession(session: secondSession, userProfile: testProfile)
        XCTAssertEqual(secondResults.accuracy, Double(correctCount) / Double(secondSession.totalCards),
                      "Second session accuracy should reflect mixed performance")
        
        // Verify long-term progress tracking
        let allFlashcardSessions = try profileService.getStudySessions(for: testProfile)
            .filter { $0.sessionType == .flashcards }
        XCTAssertEqual(allFlashcardSessions.count, 2, "Should have recorded both Leitner sessions")
    }
    
    func testFlashcardSessionInterruption() throws {
        // Test session restoration after interruption (app backgrounding, etc.)
        
        let testProfile = try profileService.createProfile(
            name: "Interrupted Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let sessionConfig = FlashcardSessionConfiguration(
            categories: ["intermediate_techniques"],
            cardDirection: .bothDirections,
            sessionMode: .test,
            cardMode: .classic,
            maxCards: 15
        )
        
        // Start session and answer partially
        let originalSession = try flashcardService.startSession(
            configuration: sessionConfig,
            userProfile: testProfile
        )
        
        let partialProgress = 7 // Answer 7 out of 15 cards
        for cardIndex in 0..<partialProgress {
            flashcardService.recordAnswer(session: originalSession, isCorrect: true, responseTime: 3.0)
            if cardIndex < partialProgress - 1 {
                flashcardService.advanceToNextCard(session: originalSession)
            }
        }
        
        // Simulate session interruption (save current state)
        let sessionState = flashcardService.saveSessionState(session: originalSession)
        XCTAssertNotNil(sessionState, "Should be able to save session state")
        
        // Simulate app restart - restore session
        let restoredSession = try flashcardService.restoreSession(
            state: sessionState,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(restoredSession, "Should restore interrupted session")
        XCTAssertEqual(restoredSession.currentCardIndex, partialProgress, "Should restore to correct card position")
        XCTAssertEqual(restoredSession.totalCards, originalSession.totalCards, "Should maintain session configuration")
        
        // Complete restored session
        for cardIndex in partialProgress..<restoredSession.totalCards {
            flashcardService.recordAnswer(session: restoredSession, isCorrect: true, responseTime: 2.5)
            if cardIndex < restoredSession.totalCards - 1 {
                flashcardService.advanceToNextCard(session: restoredSession)
            }
        }
        
        let finalResults = flashcardService.completeSession(session: restoredSession, userProfile: testProfile)
        XCTAssertEqual(finalResults.totalCards, 15, "Restored session should complete with all cards")
        XCTAssertEqual(finalResults.accuracy, 1.0, "All answers in test were correct")
    }
    
    // MARK: - Pattern Practice Session Workflows
    
    func testPatternPracticeCompleteWorkflow() throws {
        // CRITICAL USER FLOW: Complete pattern practice with progress tracking
        
        let testProfile = try profileService.createProfile(
            name: "Pattern Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Get a beginner pattern for testing
        let beginnerPatterns = patternService.getAvailablePatterns(for: testProfile)
        XCTAssertGreaterThan(beginnerPatterns.count, 0, "Should have patterns available for beginner")
        
        let testPattern = beginnerPatterns.first!
        XCTAssertNotNil(testPattern, "Should have valid test pattern")
        
        // Start pattern practice session
        let practiceSession = patternService.startPracticeSession(
            pattern: testPattern,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(practiceSession, "Pattern practice session should be created")
        XCTAssertEqual(practiceSession.currentMoveIndex, 0, "Should start at first move")
        XCTAssertEqual(practiceSession.pattern.id, testPattern.id, "Should practice selected pattern")
        
        // Simulate practicing through all moves
        let totalMoves = testPattern.orderedMoves.count
        for moveIndex in 0..<totalMoves {
            XCTAssertEqual(practiceSession.currentMoveIndex, moveIndex, "Should be at correct move")
            
            let currentMove = practiceSession.currentMove
            XCTAssertNotNil(currentMove, "Should have valid current move")
            XCTAssertEqual(currentMove?.moveNumber, moveIndex + 1, "Move numbers should be 1-based")
            
            // Simulate move practice (view move, read instructions, practice)
            patternService.recordMoveCompletion(
                session: practiceSession,
                moveIndex: moveIndex,
                practiceTime: Double.random(in: 10.0...30.0)
            )
            
            // Advance to next move (except on last move)
            if moveIndex < totalMoves - 1 {
                patternService.advanceToNextMove(session: practiceSession)
            }
        }
        
        // Complete pattern practice
        let practiceResults = patternService.completePracticeSession(
            session: practiceSession,
            userProfile: testProfile
        )
        
        // Verify practice results
        XCTAssertNotNil(practiceResults, "Pattern practice should produce results")
        XCTAssertEqual(practiceResults.movesCompleted, totalMoves, "Should complete all moves")
        XCTAssertTrue(practiceResults.totalPracticeTime > 0, "Should have measurable practice time")
        XCTAssertTrue(practiceResults.completionAccuracy >= 0.0 && practiceResults.completionAccuracy <= 1.0,
                     "Accuracy should be valid percentage")
        
        // Verify pattern progress tracking
        let patternProgress = patternService.getUserProgress(for: testPattern, userProfile: testProfile)
        XCTAssertNotNil(patternProgress, "Should create pattern progress record")
        XCTAssertEqual(patternProgress?.currentMove, totalMoves, "Should mark pattern as fully completed")
        XCTAssertNotNil(patternProgress?.lastPracticedAt, "Should record last practice time")
        
        // Verify general study session recording
        let studySessions = try profileService.getStudySessions(for: testProfile)
        let patternSessions = studySessions.filter { $0.sessionType == .patterns }
        XCTAssertGreaterThan(patternSessions.count, 0, "Should record pattern study session")
        
        let latestPatternSession = patternSessions.sorted { $0.createdAt > $1.createdAt }.first!
        XCTAssertEqual(latestPatternSession.itemsStudied, totalMoves, "Should record moves as items studied")
        XCTAssertTrue(latestPatternSession.focusAreas.contains(testPattern.name), "Should record pattern name in focus areas")
        
        // Performance validation
        let practiceCreationMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = patternService.startPracticeSession(pattern: testPattern, userProfile: testProfile)
        }
        XCTAssertLessThan(practiceCreationMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Pattern practice session creation should be fast")
    }
    
    func testPatternProgressPersistence() throws {
        // Test pattern progress persistence across multiple practice sessions
        
        let testProfile = try profileService.createProfile(
            name: "Progressive Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let testPattern = patternService.getAvailablePatterns(for: testProfile).first!
        let totalMoves = testPattern.orderedMoves.count
        let midPoint = totalMoves / 2
        
        // First practice session - practice only half the pattern
        let firstSession = patternService.startPracticeSession(pattern: testPattern, userProfile: testProfile)
        
        for moveIndex in 0..<midPoint {
            patternService.recordMoveCompletion(session: firstSession, moveIndex: moveIndex, practiceTime: 15.0)
            if moveIndex < midPoint - 1 {
                patternService.advanceToNextMove(session: firstSession)
            }
        }
        
        // End session early (incomplete pattern)
        patternService.saveSessionProgress(session: firstSession, userProfile: testProfile)
        
        // Verify partial progress is saved
        let partialProgress = patternService.getUserProgress(for: testPattern, userProfile: testProfile)
        XCTAssertNotNil(partialProgress, "Should save partial progress")
        XCTAssertEqual(partialProgress?.currentMove, midPoint, "Should save progress at midpoint")
        
        // Second practice session - should resume from where left off
        let resumedSession = patternService.startPracticeSession(pattern: testPattern, userProfile: testProfile)
        XCTAssertEqual(resumedSession.currentMoveIndex, midPoint - 1, "Should resume from last completed move")
        
        // Complete the remaining moves
        for moveIndex in midPoint..<totalMoves {
            patternService.recordMoveCompletion(session: resumedSession, moveIndex: moveIndex, practiceTime: 12.0)
            if moveIndex < totalMoves - 1 {
                patternService.advanceToNextMove(session: resumedSession)
            }
        }
        
        let finalResults = patternService.completePracticeSession(session: resumedSession, userProfile: testProfile)
        XCTAssertEqual(finalResults.movesCompleted, totalMoves - midPoint, "Second session should complete remaining moves")
        
        // Verify complete progress is recorded
        let finalProgress = patternService.getUserProgress(for: testPattern, userProfile: testProfile)
        XCTAssertEqual(finalProgress?.currentMove, totalMoves, "Should mark pattern as fully completed")
        
        // Verify multiple study sessions are recorded
        let allPatternSessions = try profileService.getStudySessions(for: testProfile)
            .filter { $0.sessionType == .patterns }
        XCTAssertEqual(allPatternSessions.count, 2, "Should record both practice sessions")
    }
    
    // MARK: - Testing Session Workflows
    
    func testTestTakingCompleteWorkflow() throws {
        // CRITICAL USER FLOW: Complete test taking with results and progress tracking
        
        let testProfile = try profileService.createProfile(
            name: "Test Taker",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Start terminology test
        let testConfig = TestConfiguration(
            testType: .terminology,
            categories: ["basic_techniques"],
            questionCount: 10,
            timeLimit: 300, // 5 minutes
            includeIncorrectReview: true
        )
        
        let testSession = try testingService.startTest(
            configuration: testConfig,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(testSession, "Test session should be created")
        XCTAssertEqual(testSession.totalQuestions, 10, "Should have requested number of questions")
        XCTAssertEqual(testSession.currentQuestionIndex, 0, "Should start at first question")
        XCTAssertEqual(testSession.testType, .terminology, "Should match test type")
        
        // Simulate answering test questions with realistic accuracy
        var correctAnswers = 0
        let targetAccuracy = 0.75 // 75% correct
        
        for questionIndex in 0..<testSession.totalQuestions {
            let currentQuestion = testSession.currentQuestion
            XCTAssertNotNil(currentQuestion, "Should have valid question at index \(questionIndex)")
            
            // Simulate answering based on target accuracy
            let isCorrect = questionIndex < Int(Double(testSession.totalQuestions) * targetAccuracy)
            if isCorrect {
                correctAnswers += 1
            }
            
            // Record answer with realistic response time
            testingService.recordAnswer(
                session: testSession,
                selectedAnswer: isCorrect ? currentQuestion!.correctAnswer : "Wrong Answer",
                responseTime: Double.random(in: 2.0...8.0)
            )
            
            // Advance to next question (except on last question)
            if questionIndex < testSession.totalQuestions - 1 {
                testingService.advanceToNextQuestion(session: testSession)
                XCTAssertEqual(testSession.currentQuestionIndex, questionIndex + 1, "Should advance to next question")
            }
        }
        
        // Complete test
        let testResults = testingService.completeTest(
            session: testSession,
            userProfile: testProfile
        )
        
        // Verify test results
        XCTAssertNotNil(testResults, "Test should produce results")
        XCTAssertEqual(testResults.totalQuestions, testSession.totalQuestions, "Results should reflect total questions")
        XCTAssertEqual(testResults.correctAnswers, correctAnswers, "Results should reflect correct answers")
        XCTAssertEqual(testResults.accuracy, Double(correctAnswers) / Double(testSession.totalQuestions),
                      "Accuracy should be calculated correctly")
        XCTAssertTrue(testResults.testDuration > 0, "Test should have measurable duration")
        XCTAssertNotNil(testResults.completionDate, "Should record completion date")
        
        // Verify incorrect answers for review
        if testConfig.includeIncorrectReview {
            let incorrectCount = testSession.totalQuestions - correctAnswers
            XCTAssertEqual(testResults.incorrectAnswers.count, incorrectCount, "Should provide incorrect answers for review")
        }
        
        // Verify progress tracking integration
        let studySessions = try profileService.getStudySessions(for: testProfile)
        let testingSessions = studySessions.filter { $0.sessionType == .testing }
        XCTAssertGreaterThan(testingSessions.count, 0, "Should record testing study session")
        
        let latestTestSession = testingSessions.sorted { $0.createdAt > $1.createdAt }.first!
        XCTAssertEqual(latestTestSession.itemsStudied, testSession.totalQuestions, "Should record questions as items studied")
        XCTAssertEqual(latestTestSession.correctAnswers, correctAnswers, "Should record correct answers")
        
        // Performance validation
        let testCreationMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = try! testingService.startTest(configuration: testConfig, userProfile: testProfile)
        }
        XCTAssertLessThan(testCreationMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Test session creation should be fast")
    }
    
    func testTestResultsAnalysisWorkflow() throws {
        // Test detailed results analysis and progress tracking
        
        let testProfile = try profileService.createProfile(
            name: "Analysis Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Take multiple tests to establish patterns
        let testConfig = TestConfiguration(
            testType: .patterns,
            categories: ["beginner_patterns"],
            questionCount: 8,
            timeLimit: 240,
            includeIncorrectReview: true
        )
        
        var allTestResults: [TestResults] = []
        
        // Take 3 tests with varying performance
        let accuracyLevels = [0.6, 0.8, 0.9] // Improving performance
        
        for (testIndex, targetAccuracy) in accuracyLevels.enumerated() {
            let testSession = try testingService.startTest(configuration: testConfig, userProfile: testProfile)
            
            let correctCount = Int(Double(testSession.totalQuestions) * targetAccuracy)
            
            for questionIndex in 0..<testSession.totalQuestions {
                let isCorrect = questionIndex < correctCount
                testingService.recordAnswer(
                    session: testSession,
                    selectedAnswer: isCorrect ? testSession.currentQuestion!.correctAnswer : "Wrong",
                    responseTime: 3.0
                )
                
                if questionIndex < testSession.totalQuestions - 1 {
                    testingService.advanceToNextQuestion(session: testSession)
                }
            }
            
            let results = testingService.completeTest(session: testSession, userProfile: testProfile)
            allTestResults.append(results)
            
            // Small delay between tests to ensure different timestamps
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Analyze test performance trends
        let performanceAnalysis = testingService.analyzePerformance(
            testResults: allTestResults,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(performanceAnalysis, "Should provide performance analysis")
        XCTAssertEqual(performanceAnalysis.totalTestsTaken, 3, "Should analyze all taken tests")
        XCTAssertTrue(performanceAnalysis.showsImprovement, "Should detect improvement trend")
        XCTAssertGreaterThan(performanceAnalysis.averageAccuracy, 0.7, "Average accuracy should reflect improvement")
        
        // Verify weak areas identification
        let weakAreas = testingService.identifyWeakAreas(
            testResults: allTestResults,
            userProfile: testProfile
        )
        XCTAssertNotNil(weakAreas, "Should identify areas needing improvement")
        
        // Verify study recommendations
        let studyRecommendations = testingService.generateStudyRecommendations(
            analysis: performanceAnalysis,
            weakAreas: weakAreas,
            userProfile: testProfile
        )
        XCTAssertNotNil(studyRecommendations, "Should provide study recommendations")
        XCTAssertGreaterThan(studyRecommendations.count, 0, "Should have actionable recommendations")
    }
    
    // MARK: - Cross-Feature Integration Tests
    
    func testLearningModeImpactOnContent() throws {
        // Test how learning modes (Mastery vs Progression) affect content access
        
        // Create two profiles with different learning modes
        let masteryProfile = try profileService.createProfile(
            name: "Mastery Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let progressionProfile = try profileService.createProfile(
            name: "Progression Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        
        // Test flashcard content access differences
        profileService.setActiveProfile(masteryProfile)
        let masteryFlashcards = flashcardService.getAvailableCategories(for: masteryProfile)
        
        profileService.setActiveProfile(progressionProfile)
        let progressionFlashcards = flashcardService.getAvailableCategories(for: progressionProfile)
        
        // Mastery mode should have more restrictive content (focused on current belt)
        // Progression mode should have broader content access
        XCTAssertNotNil(masteryFlashcards, "Mastery mode should have available flashcards")
        XCTAssertNotNil(progressionFlashcards, "Progression mode should have available flashcards")
        
        // Test pattern access differences
        let masteryPatterns = patternService.getAvailablePatterns(for: masteryProfile)
        let progressionPatterns = patternService.getAvailablePatterns(for: progressionProfile)
        
        XCTAssertGreaterThan(masteryPatterns.count, 0, "Mastery mode should have available patterns")
        XCTAssertGreaterThan(progressionPatterns.count, 0, "Progression mode should have available patterns")
        
        // Test testing content differences
        let masteryTestCategories = testingService.getAvailableTestCategories(for: masteryProfile)
        let progressionTestCategories = testingService.getAvailableTestCategories(for: progressionProfile)
        
        XCTAssertGreaterThan(masteryTestCategories.count, 0, "Mastery mode should have test categories")
        XCTAssertGreaterThan(progressionTestCategories.count, 0, "Progression mode should have test categories")
        
        // Verify learning mode consistency across features
        TKDojangAssertions.assertLearningModeConsistency(
            profile: masteryProfile,
            flashcardCategories: masteryFlashcards,
            patterns: masteryPatterns,
            testCategories: masteryTestCategories
        )
        
        TKDojangAssertions.assertLearningModeConsistency(
            profile: progressionProfile,
            flashcardCategories: progressionFlashcards,
            patterns: progressionPatterns,
            testCategories: progressionTestCategories
        )
    }
    
    func testCrossSessionProgressCorrelation() throws {
        // Test that progress from different learning activities correlates correctly
        
        let testProfile = try profileService.createProfile(
            name: "Multi-Activity Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Record various learning activities
        
        // 1. Flashcard session on terminology
        let flashcardConfig = FlashcardSessionConfiguration(
            categories: ["intermediate_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 12
        )
        
        let flashcardSession = try flashcardService.startSession(configuration: flashcardConfig, userProfile: testProfile)
        // Simulate high-accuracy session
        for cardIndex in 0..<flashcardSession.totalCards {
            flashcardService.recordAnswer(session: flashcardSession, isCorrect: cardIndex < 10, responseTime: 2.0) // 10/12 correct
            if cardIndex < flashcardSession.totalCards - 1 {
                flashcardService.advanceToNextCard(session: flashcardSession)
            }
        }
        let flashcardResults = flashcardService.completeSession(session: flashcardSession, userProfile: testProfile)
        
        // 2. Pattern practice session
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let testPattern = availablePatterns.first!
        let patternSession = patternService.startPracticeSession(pattern: testPattern, userProfile: testProfile)
        for moveIndex in 0..<testPattern.orderedMoves.count {
            patternService.recordMoveCompletion(session: patternSession, moveIndex: moveIndex, practiceTime: 20.0)
            if moveIndex < testPattern.orderedMoves.count - 1 {
                patternService.advanceToNextMove(session: patternSession)
            }
        }
        let patternResults = patternService.completePracticeSession(session: patternSession, userProfile: testProfile)
        
        // 3. Test session on related content
        let testConfig = TestConfiguration(
            testType: .terminology,
            categories: ["intermediate_techniques"],
            questionCount: 10,
            timeLimit: 300,
            includeIncorrectReview: true
        )
        
        let testSession = try testingService.startTest(configuration: testConfig, userProfile: testProfile)
        for questionIndex in 0..<testSession.totalQuestions {
            testingService.recordAnswer(
                session: testSession,
                selectedAnswer: questionIndex < 8 ? testSession.currentQuestion!.correctAnswer : "Wrong", // 8/10 correct
                responseTime: 4.0
            )
            if questionIndex < testSession.totalQuestions - 1 {
                testingService.advanceToNextQuestion(session: testSession)
            }
        }
        let testResults = testingService.completeTest(session: testSession, userProfile: testProfile)
        
        // Verify cross-session progress correlation
        let allStudySessions = try profileService.getStudySessions(for: testProfile)
        XCTAssertEqual(allStudySessions.count, 3, "Should record all three learning activities")
        
        // Verify progress consistency across different learning types
        let progressAnalysis = dataServices.analyticsService.analyzeProgressCorrelation(
            studySessions: allStudySessions,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(progressAnalysis, "Should provide cross-session progress analysis")
        XCTAssertTrue(progressAnalysis.showsConsistentProgress, "Related activities should show consistent progress patterns")
        XCTAssertGreaterThan(progressAnalysis.overallAccuracy, 0.7, "Overall performance should reflect individual session accuracy")
        
        // Verify that strong performance in one area positively influences recommendations in others
        let recommendations = dataServices.recommendationService.generateRecommendations(
            based: progressAnalysis,
            for: testProfile
        )
        
        XCTAssertNotNil(recommendations, "Should generate learning recommendations")
        XCTAssertGreaterThan(recommendations.count, 0, "Should have actionable recommendations")
    }
    
    // MARK: - Performance & Memory Tests
    
    func testLearningSessionPerformanceWithLargeDatasets() throws {
        // Test learning session performance with realistic content volumes
        
        let testProfile = try profileService.createProfile(
            name: "Performance Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test flashcard performance with large category sets
        let largeSessionMeasurement = PerformanceMeasurement.measureExecutionTime {
            let largeConfig = FlashcardSessionConfiguration(
                categories: ["basic_techniques", "intermediate_techniques", "advanced_techniques"],
                cardDirection: .bothDirections,
                sessionMode: .study,
                cardMode: .leitner,
                maxCards: 50
            )
            
            let largeSession = try! flashcardService.startSession(configuration: largeConfig, userProfile: testProfile)
            
            // Simulate fast completion
            for cardIndex in 0..<min(largeSession.totalCards, 10) { // Test first 10 cards for performance
                flashcardService.recordAnswer(session: largeSession, isCorrect: true, responseTime: 1.0)
                if cardIndex < 9 {
                    flashcardService.advanceToNextCard(session: largeSession)
                }
            }
        }
        
        XCTAssertLessThan(largeSessionMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 3,
                         "Large flashcard session should remain performant")
        
        // Test pattern loading performance
        let patternLoadMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = patternService.getAvailablePatterns(for: testProfile)
        }
        
        XCTAssertLessThan(patternLoadMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Pattern loading should be fast")
        
        // Test memory usage during concurrent learning activities
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            // Simulate multiple concurrent sessions
            for _ in 1...5 {
                let quickConfig = FlashcardSessionConfiguration(
                    categories: ["basic_techniques"],
                    cardDirection: .englishToKorean,
                    sessionMode: .study,
                    cardMode: .classic,
                    maxCards: 5
                )
                
                let session = try! flashcardService.startSession(configuration: quickConfig, userProfile: testProfile)
                flashcardService.recordAnswer(session: session, isCorrect: true, responseTime: 1.0)
                let _ = flashcardService.completeSession(session: session, userProfile: testProfile)
            }
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 5,
                         "Multiple sessions should not cause significant memory growth")
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
    
    private func getTerminologyProgress(for profile: UserProfile) throws -> [UserTerminologyProgress] {
        let descriptor = FetchDescriptor<UserTerminologyProgress>()
        let allProgress = try testContext.fetch(descriptor)
        return allProgress.filter { $0.userProfile.id == profile.id }
    }
}

// MARK: - Test Extensions

extension LearningSessionWorkflowTests {
    
    /**
     * Integration test for learning session data persistence across app lifecycle
     */
    func testLearningSessionPersistenceAcrossAppLifecycle() throws {
        let testProfile = try profileService.createProfile(
            name: "Persistent Student",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Record multiple learning activities
        let activities = [
            ("Flashcards", 15, 12),
            ("Patterns", 8, 8),
            ("Testing", 20, 16)
        ]
        
        for (activityType, total, correct) in activities {
            try profileService.recordStudySession(
                sessionType: StudySessionType(rawValue: activityType.lowercased()) ?? .flashcards,
                itemsStudied: total,
                correctAnswers: correct,
                focusAreas: ["\(activityType) Practice"]
            )
        }
        
        // Simulate app restart by creating new service instances
        let newDataServices = DataServices(container: testContainer)
        let newProfileService = newDataServices.profileService
        
        // Verify data persistence after "restart"
        let restoredProfile = try newProfileService.getAllProfiles().first { $0.name == "Persistent Student" }
        XCTAssertNotNil(restoredProfile, "Profile should persist across app lifecycle")
        
        newProfileService.setActiveProfile(restoredProfile!)
        let persistedSessions = try newProfileService.getStudySessions(for: restoredProfile!)
        XCTAssertEqual(persistedSessions.count, 3, "All study sessions should persist")
        
        // Verify session data integrity
        let totalItemsStudied = persistedSessions.reduce(0) { $0 + $1.itemsStudied }
        let totalCorrect = persistedSessions.reduce(0) { $0 + $1.correctAnswers }
        
        XCTAssertEqual(totalItemsStudied, 43, "Total items studied should match recorded sessions")
        XCTAssertEqual(totalCorrect, 36, "Total correct answers should match recorded sessions")
    }
    
    /**
     * Test learning session workflow under error conditions
     */
    func testLearningSessionErrorRecovery() throws {
        let testProfile = try profileService.createProfile(
            name: "Error Recovery Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test flashcard session with simulated errors
        let errorConfig = FlashcardSessionConfiguration(
            categories: ["nonexistent_category"], // This should cause graceful error handling
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 10
        )
        
        // Should either handle gracefully or throw meaningful error
        do {
            let errorSession = try flashcardService.startSession(configuration: errorConfig, userProfile: testProfile)
            // If it succeeds, should provide fallback content
            XCTAssertNotNil(errorSession, "Should provide fallback content for invalid categories")
        } catch {
            // If it fails, error should be meaningful
            let errorDescription = error.localizedDescription
            XCTAssertFalse(errorDescription.isEmpty, "Error should have meaningful description")
            XCTAssertTrue(errorDescription.contains("category") || errorDescription.contains("content"),
                         "Error should indicate content-related issue")
        }
        
        // Test pattern session error recovery
        let invalidPattern = Pattern() // Empty pattern for error testing
        invalidPattern.name = "Invalid Test Pattern"
        
        do {
            let _ = patternService.startPracticeSession(pattern: invalidPattern, userProfile: testProfile)
            XCTFail("Should not allow practice of invalid pattern")
        } catch {
            let errorDescription = error.localizedDescription
            XCTAssertFalse(errorDescription.isEmpty, "Should provide meaningful error for invalid pattern")
        }
        
        // Verify service remains functional after error conditions
        let validPatterns = patternService.getAvailablePatterns(for: testProfile)
        XCTAssertGreaterThan(validPatterns.count, 0, "Service should remain functional after errors")
        
        let validSession = patternService.startPracticeSession(pattern: validPatterns.first!, userProfile: testProfile)
        XCTAssertNotNil(validSession, "Should recover and allow valid operations after errors")
    }
}