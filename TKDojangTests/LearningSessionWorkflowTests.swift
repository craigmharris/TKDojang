import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * LearningSessionWorkflowTests.swift
 * 
 * PURPOSE: Infrastructure testing for learning session workflows
 * 
 * ARCHITECTURE DECISION: Infrastructure-focused testing approach
 * WHY: Eliminates complex mock dependencies and focuses on core data flow validation
 * 
 * TESTING STRATEGY:
 * - Container creation and schema validation
 * - Learning session data structures
 * - Profile and progress tracking infrastructure
 * - Proven pattern from successful test migrations
 */

final class LearningSessionWorkflowTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create test container using centralized factory
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Learning Session Infrastructure Tests
    
    func testContainerInitialization() throws {
        // Test that container initializes with learning session schema
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
        
        // Verify schema contains required models for learning sessions
        let schema = testContainer.schema
        let modelNames = schema.entities.map { $0.name }
        
        XCTAssertTrue(modelNames.contains("UserProfile"))
        XCTAssertTrue(modelNames.contains("StudySession"))
        XCTAssertTrue(modelNames.contains("TerminologyEntry"))
        XCTAssertTrue(modelNames.contains("UserTerminologyProgress"))
        XCTAssertTrue(modelNames.contains("BeltLevel"))
    }
    
    func testLearningSessionDataStructures() throws {
        // Test basic data structures needed for learning sessions
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        
        // Create test profile for learning sessions
        let testBelt = beltLevels.first!
        let profile = UserProfile(
            name: "Learning Session Tester",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Verify profile creation
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 1)
        XCTAssertEqual(savedProfiles.first?.name, "Learning Session Tester")
    }
    
    func testFlashcardSessionWorkflow() throws {
        // Test flashcard session data workflow
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        _ = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let testBelt = beltLevels.first!
        
        // Create profile for flashcard session
        let profile = UserProfile(
            name: "Flashcard Session User",
            avatar: .student2,
            colorTheme: .green,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create flashcard study session
        let session = StudySession(userProfile: profile, sessionType: .flashcards)
        session.complete(itemsStudied: 20, correctAnswers: 16, focusAreas: ["Korean Terms"])
        
        testContext.insert(session)
        try testContext.save()
        
        // Verify session creation
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 1)
        
        let flashcardSession = sessions.first!
        XCTAssertEqual(flashcardSession.sessionType, .flashcards)
        XCTAssertEqual(flashcardSession.itemsStudied, 20)
        XCTAssertEqual(flashcardSession.correctAnswers, 16)
        XCTAssertNotNil(flashcardSession.endTime)
        
        // Test accuracy calculation
        let accuracy = Double(flashcardSession.correctAnswers) / Double(flashcardSession.itemsStudied)
        XCTAssertEqual(accuracy, 0.8, accuracy: 0.01) // 80% accuracy
    }
    
    func testProgressTrackingWorkflow() throws {
        // Test progress tracking infrastructure
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        let testTerm = terminology.first!
        
        // Create profile for progress tracking
        let profile = UserProfile(
            name: "Progress Tracker",
            avatar: .ninja,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create progress tracking entry
        let progress = UserTerminologyProgress(
            terminologyEntry: testTerm,
            userProfile: profile
        )
        
        testContext.insert(progress)
        try testContext.save()
        
        // Verify progress tracking
        let savedProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        XCTAssertEqual(savedProgress.count, 1)
        
        let progressEntry = savedProgress.first!
        XCTAssertEqual(progressEntry.currentBox, 1)
        XCTAssertEqual(progressEntry.masteryLevel, .learning)
        XCTAssertEqual(progressEntry.correctCount, 0)
        XCTAssertEqual(progressEntry.incorrectCount, 0)
    }
    
    func testPatternSessionWorkflow() throws {
        // Test pattern learning session infrastructure
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profile for pattern learning
        let profile = UserProfile(
            name: "Pattern Learner",
            avatar: .student1,
            colorTheme: .purple,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create pattern study session
        let session = StudySession(userProfile: profile, sessionType: .patterns)
        session.complete(itemsStudied: 8, correctAnswers: 7, focusAreas: ["Taeguk Forms"])
        
        testContext.insert(session)
        try testContext.save()
        
        // Verify pattern session
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 1)
        
        let patternSession = sessions.first!
        XCTAssertEqual(patternSession.sessionType, .patterns)
        XCTAssertEqual(patternSession.itemsStudied, 8)
        XCTAssertEqual(patternSession.correctAnswers, 7)
        XCTAssertNotNil(patternSession.endTime)
    }
    
    func testMultipleSessionTypes() throws {
        // Test multiple session types for comprehensive learning
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profile for multiple session types
        let profile = UserProfile(
            name: "Multi Session User",
            avatar: .student2,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create sessions of different types
        let flashcardSession = StudySession(userProfile: profile, sessionType: .flashcards)
        flashcardSession.complete(itemsStudied: 15, correctAnswers: 12, focusAreas: ["Terminology"])
        
        let patternSession = StudySession(userProfile: profile, sessionType: .patterns)
        patternSession.complete(itemsStudied: 5, correctAnswers: 4, focusAreas: ["Forms"])
        
        let stepSparringSession = StudySession(userProfile: profile, sessionType: .step_sparring)
        stepSparringSession.complete(itemsStudied: 10, correctAnswers: 8, focusAreas: ["Step Sparring"])
        
        testContext.insert(flashcardSession)
        testContext.insert(patternSession)
        testContext.insert(stepSparringSession)
        try testContext.save()
        
        // Verify all session types
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 3)
        
        let sessionTypes = Set(sessions.map { $0.sessionType })
        XCTAssertTrue(sessionTypes.contains(.flashcards))
        XCTAssertTrue(sessionTypes.contains(.patterns))
        XCTAssertTrue(sessionTypes.contains(.step_sparring))
        
        // Verify session filtering
        let flashcardSessions = sessions.filter { $0.sessionType == .flashcards }
        XCTAssertEqual(flashcardSessions.count, 1)
        XCTAssertEqual(flashcardSessions.first?.itemsStudied, 15)
    }
    
    func testLearningModeWorkflows() throws {
        // Test different learning mode workflows
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create mastery mode profile
        let masteryProfile = UserProfile(
            name: "Mastery Mode User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        // Create progression mode profile
        let progressionProfile = UserProfile(
            name: "Progression Mode User",
            avatar: .student2,
            colorTheme: .green,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(masteryProfile)
        testContext.insert(progressionProfile)
        try testContext.save()
        
        // Verify learning modes
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(profiles.count, 2)
        
        let masteryModeProfile = profiles.first { $0.learningMode == .mastery }
        let progressionModeProfile = profiles.first { $0.learningMode == .progression }
        
        XCTAssertNotNil(masteryModeProfile)
        XCTAssertNotNil(progressionModeProfile)
        XCTAssertEqual(masteryModeProfile?.name, "Mastery Mode User")
        XCTAssertEqual(progressionModeProfile?.name, "Progression Mode User")
    }
    
    func testSessionPerformanceTracking() throws {
        // Test session performance tracking infrastructure
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profile for performance tracking
        let profile = UserProfile(
            name: "Performance Tracker",
            avatar: .ninja,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create multiple sessions for performance analysis
        let sessionData = [
            (itemsStudied: 10, correctAnswers: 8),   // 80%
            (itemsStudied: 15, correctAnswers: 13),  // 87%
            (itemsStudied: 20, correctAnswers: 16),  // 80%
            (itemsStudied: 12, correctAnswers: 11),  // 92%
            (itemsStudied: 18, correctAnswers: 15)   // 83%
        ]
        
        for (index, data) in sessionData.enumerated() {
            let session = StudySession(userProfile: profile, sessionType: .flashcards)
            session.complete(
                itemsStudied: data.itemsStudied,
                correctAnswers: data.correctAnswers,
                focusAreas: ["Session \(index + 1)"]
            )
            testContext.insert(session)
        }
        
        try testContext.save()
        
        // Verify performance data
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 5)
        
        let totalItemsStudied = sessions.reduce(0) { $0 + $1.itemsStudied }
        let totalCorrectAnswers = sessions.reduce(0) { $0 + $1.correctAnswers }
        
        XCTAssertEqual(totalItemsStudied, 75) // 10+15+20+12+18
        XCTAssertEqual(totalCorrectAnswers, 63) // 8+13+16+11+15
        
        // Calculate overall accuracy
        let overallAccuracy = Double(totalCorrectAnswers) / Double(totalItemsStudied)
        XCTAssertEqual(overallAccuracy, 0.84, accuracy: 0.01) // 84% accuracy
    }
    
    func testSessionDataConsistency() throws {
        // Test data consistency across learning sessions
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let categories = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        
        // Verify data availability for learning sessions
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        XCTAssertGreaterThan(categories.count, 0)
        
        // Verify data relationships
        let firstTerm = terminology.first!
        XCTAssertNotNil(firstTerm.beltLevel)
        XCTAssertNotNil(firstTerm.category)
        
        // Verify belt level exists
        let termBeltExists = beltLevels.contains { belt in
            belt.id == firstTerm.beltLevel.id
        }
        XCTAssertTrue(termBeltExists)
        
        // Verify category exists
        let termCategoryExists = categories.contains { category in
            category.id == firstTerm.category.id
        }
        XCTAssertTrue(termCategoryExists)
    }
    
    func testLearningSessionErrorHandling() throws {
        // Test error handling in learning session infrastructure
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profile for error testing
        let profile = UserProfile(
            name: "Error Test User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Test session with edge case data
        let session = StudySession(userProfile: profile, sessionType: .flashcards)
        session.complete(itemsStudied: 0, correctAnswers: 0, focusAreas: [])
        
        testContext.insert(session)
        try testContext.save()
        
        // Verify edge case handling
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 1)
        
        let edgeSession = sessions.first!
        XCTAssertEqual(edgeSession.itemsStudied, 0)
        XCTAssertEqual(edgeSession.correctAnswers, 0)
        XCTAssertNotNil(edgeSession.endTime)
    }
}