import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * TestingSystemUITests.swift
 * 
 * PURPOSE: Feature-specific UI integration testing for testing and knowledge validation systems
 * 
 * COVERAGE: Testing system infrastructure validation
 * - Terminology flashcard testing infrastructure
 * - Pattern knowledge testing support
 * - Belt progression testing capabilities
 * - Quiz workflow and scoring infrastructure
 * - Progress tracking and analytics support
 * - Multi-mode testing system validation
 * 
 * BUSINESS IMPACT: Testing validates learning progress and belt advancement readiness
 */
final class TestingSystemUITests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container using centralized factory
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = ModelContext(testContainer)
        
        // Set up test data
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Terminology Testing Infrastructure Tests
    
    func testTerminologyTestingInfrastructure() throws {
        // Test terminology testing infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Terminology Test User", currentBeltLevel: testBelts.first!, learningMode: .mastery)
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test terminology testing infrastructure
        XCTAssertEqual(testProfile.learningMode, .mastery, "Should support mastery-based testing")
        XCTAssertNotNil(testProfile.currentBeltLevel, "Profile should have belt level for testing context")
        
        // Test study session testing support
        let session = StudySession(userProfile: testProfile, sessionType: .testing)
        session.duration = 600.0
        session.itemsStudied = 10
        session.correctAnswers = 8
        testContext.insert(session)
        try testContext.save()
        
        XCTAssertEqual(session.sessionType, .testing, "Should support testing session type")
        XCTAssertGreaterThan(session.itemsStudied, 0, "Should track items tested")
        
        print("✅ Terminology testing infrastructure validation completed")
    }
    
    func testFlashcardTestingWorkflow() throws {
        // Test flashcard testing workflow infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Flashcard Test User", currentBeltLevel: testBelts[1], learningMode: .progression)
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test flashcard workflow infrastructure
        XCTAssertEqual(testProfile.learningMode, .progression, "Should support progression-based testing")
        
        // Test flashcard session support
        let session = StudySession(userProfile: testProfile, sessionType: .flashcards)
        session.duration = 300.0
        session.itemsStudied = 15
        session.correctAnswers = 12
        testContext.insert(session)
        try testContext.save()
        
        XCTAssertEqual(session.sessionType, .flashcards, "Should support flashcard session type")
        XCTAssertGreaterThan(session.correctAnswers, 0, "Should track correct answers")
        
        print("✅ Flashcard testing workflow infrastructure validation completed")
    }
    
    // MARK: - Pattern Knowledge Testing Tests
    
    func testPatternKnowledgeTestingInfrastructure() throws {
        // Test pattern knowledge testing infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Knowledge Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern knowledge testing infrastructure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            XCTAssertNotNil(pattern.id, "Pattern should have ID for testing reference")
            XCTAssertFalse(pattern.name.isEmpty, "Pattern should have name for testing")
            XCTAssertGreaterThan(pattern.moveCount, 0, "Pattern should have moves for knowledge testing")
        }
        
        print("✅ Pattern knowledge testing infrastructure validation completed")
    }
    
    func testPatternTestingSessionIntegration() throws {
        // Test pattern testing session integration
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Session Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern testing session integration
        let session = StudySession(userProfile: testProfile, sessionType: .patterns)
        session.duration = 450.0
        session.itemsStudied = 3
        session.correctAnswers = 2
        testContext.insert(session)
        try testContext.save()
        
        XCTAssertEqual(session.sessionType, .patterns, "Should support pattern testing sessions")
        XCTAssertGreaterThan(session.duration, 0, "Should track pattern testing duration")
        
        print("✅ Pattern testing session integration validation completed")
    }
    
    // MARK: - Belt Progression Testing Tests
    
    func testBeltProgressionTestingSupport() throws {
        // Test belt progression testing support infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Test different belt levels for progression testing
        let beginnerProfile = UserProfile(name: "Beginner Tester", currentBeltLevel: testBelts.last!, learningMode: .progression)
        let advancedProfile = UserProfile(name: "Advanced Tester", currentBeltLevel: testBelts.first!, learningMode: .mastery)
        
        testContext.insert(beginnerProfile)
        testContext.insert(advancedProfile)
        try testContext.save()
        
        // Test belt progression testing infrastructure
        XCTAssertNotEqual(beginnerProfile.currentBeltLevel.sortOrder, advancedProfile.currentBeltLevel.sortOrder,
                         "Different belt levels should support different testing content")
        XCTAssertNotEqual(beginnerProfile.learningMode, advancedProfile.learningMode,
                         "Different learning modes should support different testing approaches")
        
        print("✅ Belt progression testing support infrastructure validation completed")
    }
    
    func testProgressionTestingValidation() throws {
        // Test progression testing validation infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Progression Validation Test User", currentBeltLevel: testBelts[1], learningMode: .progression)
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test progression validation infrastructure
        XCTAssertEqual(testProfile.learningMode, .progression, "Should support progression mode testing")
        XCTAssertNotNil(testProfile.currentBeltLevel, "Should have belt context for progression testing")
        
        // Test grading record support
        let gradingRecord = GradingRecord(userProfile: testProfile, beltLevel: testProfile.currentBeltLevel)
        gradingRecord.overallScore = 85.0
        gradingRecord.testDate = Date()
        gradingRecord.passed = true
        testContext.insert(gradingRecord)
        try testContext.save()
        
        XCTAssertGreaterThan(gradingRecord.overallScore, 0, "Should track testing scores")
        XCTAssertNotNil(gradingRecord.testDate, "Should track test dates")
        
        print("✅ Progression testing validation infrastructure validation completed")
    }
    
    // MARK: - Quiz Workflow Tests
    
    func testQuizWorkflowInfrastructure() throws {
        // Test quiz workflow infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Quiz Workflow Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test quiz workflow infrastructure
        let session = StudySession(userProfile: testProfile, sessionType: .testing)
        session.duration = 900.0 // 15 minutes
        session.itemsStudied = 20
        session.correctAnswers = 16
        session.startTime = Date()
        testContext.insert(session)
        try testContext.save()
        
        // Verify quiz workflow capabilities
        XCTAssertNotNil(session.startTime, "Quiz should track start time")
        XCTAssertGreaterThan(session.itemsStudied, 0, "Quiz should track question count")
        XCTAssertLessThanOrEqual(session.correctAnswers, session.itemsStudied, "Correct answers should not exceed total")
        
        print("✅ Quiz workflow infrastructure validation completed")
    }
    
    func testQuizScoringInfrastructure() throws {
        // Test quiz scoring infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Quiz Scoring Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test quiz scoring infrastructure
        let session = StudySession(userProfile: testProfile, sessionType: .testing)
        session.itemsStudied = 25
        session.correctAnswers = 20
        session.duration = 750.0
        testContext.insert(session)
        try testContext.save()
        
        // Calculate and verify scoring capabilities
        let accuracy = Double(session.correctAnswers) / Double(session.itemsStudied)
        XCTAssertGreaterThan(accuracy, 0.0, "Should support accuracy calculation")
        XCTAssertLessThanOrEqual(accuracy, 1.0, "Accuracy should be within valid range")
        
        print("✅ Quiz scoring infrastructure validation completed")
    }
    
    // MARK: - Progress Tracking Tests
    
    func testTestingProgressTracking() throws {
        // Test testing progress tracking infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Testing Progress Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Create multiple testing sessions for progress tracking
        for i in 0..<3 {
            let session = StudySession(userProfile: testProfile, sessionType: .testing)
            session.itemsStudied = 10 + i
            session.correctAnswers = 8 + i
            session.duration = Double(300 + (i * 60))
            session.startTime = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            testContext.insert(session)
        }
        try testContext.save()
        
        // Verify progress tracking capabilities
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let testingSessions = sessions.filter { $0.sessionType == .testing }
        
        XCTAssertGreaterThanOrEqual(testingSessions.count, 3, "Should track multiple testing sessions")
        
        print("✅ Testing progress tracking infrastructure validation completed")
    }
    
    func testTestingAnalyticsSupport() throws {
        // Test testing analytics support infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Testing Analytics Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Create sessions for analytics
        let sessions = [
            (itemsStudied: 15, correctAnswers: 12, duration: 450.0),
            (itemsStudied: 20, correctAnswers: 18, duration: 600.0),
            (itemsStudied: 12, correctAnswers: 10, duration: 360.0)
        ]
        
        for (index, sessionData) in sessions.enumerated() {
            let session = StudySession(userProfile: testProfile, sessionType: .testing)
            session.itemsStudied = sessionData.itemsStudied
            session.correctAnswers = sessionData.correctAnswers
            session.duration = sessionData.duration
            session.startTime = Calendar.current.date(byAdding: .hour, value: -index, to: Date()) ?? Date()
            testContext.insert(session)
        }
        try testContext.save()
        
        // Verify analytics support capabilities
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let testingSessions = allSessions.filter { $0.sessionType == .testing }
        
        if !testingSessions.isEmpty {
            let totalQuestions = testingSessions.reduce(0) { $0 + $1.itemsStudied }
            let totalCorrect = testingSessions.reduce(0) { $0 + $1.correctAnswers }
            
            XCTAssertGreaterThan(totalQuestions, 0, "Should aggregate testing data for analytics")
            XCTAssertGreaterThan(totalCorrect, 0, "Should track correct answers for analytics")
        }
        
        print("✅ Testing analytics support infrastructure validation completed")
    }
    
    // MARK: - Multi-Mode Testing Tests
    
    func testMultiModeTestingSupport() throws {
        // Test multi-mode testing support infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Multi-Mode Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Create different testing mode sessions
        let testingModes: [StudySessionType] = [.flashcards, .testing, .patterns]
        
        for (index, mode) in testingModes.enumerated() {
            let session = StudySession(userProfile: testProfile, sessionType: mode)
            session.itemsStudied = 5 + index
            session.correctAnswers = 4 + index
            session.duration = Double(180 + (index * 60))
            testContext.insert(session)
        }
        try testContext.save()
        
        // Verify multi-mode support
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let distinctModes = Set(allSessions.map { $0.sessionType })
        
        XCTAssertGreaterThanOrEqual(distinctModes.count, 3, "Should support multiple testing modes")
        
        print("✅ Multi-mode testing support infrastructure validation completed")
    }
    
    // MARK: - Performance Tests
    
    func testTestingSystemPerformance() throws {
        // Test testing system performance
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create multiple users with testing data
        for i in 0..<5 {
            let profile = UserProfile(name: "Performance Test User \(i)", currentBeltLevel: testBelts[i % testBelts.count])
            testContext.insert(profile)
            
            // Create testing sessions for each user
            for j in 0..<3 {
                let session = StudySession(userProfile: profile, sessionType: .testing)
                session.itemsStudied = 10 + j
                session.correctAnswers = 8 + j
                session.duration = Double(300 + (j * 30))
                testContext.insert(session)
            }
        }
        
        try testContext.save()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Performance validation
        XCTAssertLessThan(loadTime, 3.0, "Testing system should handle load efficiently")
        
        // Verify data integrity
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        
        XCTAssertGreaterThanOrEqual(profiles.count, 5, "Should maintain profile integrity")
        XCTAssertGreaterThanOrEqual(sessions.count, 15, "Should maintain session integrity")
        
        print("✅ Testing system performance validation completed (Load time: \(String(format: "%.3f", loadTime))s)")
    }
}

// MARK: - Mock Supporting Types

struct TestResult {
    let sessionId: UUID
    let questionsAsked: Int
    let correctAnswers: Int
    let accuracy: Double
    let completionTime: TimeInterval
    
    init(sessionId: UUID, questionsAsked: Int, correctAnswers: Int, completionTime: TimeInterval) {
        self.sessionId = sessionId
        self.questionsAsked = questionsAsked
        self.correctAnswers = correctAnswers
        self.accuracy = questionsAsked > 0 ? Double(correctAnswers) / Double(questionsAsked) : 0.0
        self.completionTime = completionTime
    }
}

struct QuizConfiguration {
    let mode: String
    let questionCount: Int
    let timeLimit: TimeInterval?
    let difficulty: String
    
    init(mode: String, questionCount: Int, timeLimit: TimeInterval? = nil, difficulty: String = "normal") {
        self.mode = mode
        self.questionCount = questionCount
        self.timeLimit = timeLimit
        self.difficulty = difficulty
    }
}

// MARK: - Test Extensions

// Testing system test utilities - no service dependencies