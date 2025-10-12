import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * DashboardProgressUITests.swift
 * 
 * PURPOSE: Infrastructure testing for dashboard and progress tracking system
 * 
 * ARCHITECTURE DECISION: Infrastructure-focused testing approach
 * WHY: Eliminates complex mock dependencies and focuses on core data flow validation
 * 
 * TESTING STRATEGY:
 * - Container creation and schema validation
 * - Profile and session data management
 * - Progress tracking infrastructure
 * - Proven pattern from successful test migrations
 */

final class DashboardProgressUITests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Infrastructure Tests
    
    func testContainerInitialization() throws {
        // Test that container initializes with correct schema
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
        
        // Verify schema contains required models
        let schema = testContainer.schema
        let modelNames = schema.entities.map { $0.name }
        
        XCTAssertTrue(modelNames.contains("UserProfile"))
        XCTAssertTrue(modelNames.contains("StudySession"))
        XCTAssertTrue(modelNames.contains("BeltLevel"))
        XCTAssertTrue(modelNames.contains("TerminologyEntry"))
    }
    
    func testDashboardDataLoading() throws {
        // Test basic dashboard data can be loaded
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        // Verify core data exists
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        
        XCTAssertGreaterThan(beltLevels.count, 0)
        
        // Create a test profile if none exists
        if profiles.isEmpty {
            let testBelt = beltLevels.first!
            let profile = UserProfile(
                name: "Dashboard User",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            
            testContext.insert(profile)
            try testContext.save()
        }
        
        let updatedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertGreaterThan(updatedProfiles.count, 0)
    }
    
    func testProgressTrackingInfrastructure() throws {
        // Test progress tracking data structures
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create test profile
        let profile = UserProfile(
            name: "Progress Tracker",
            avatar: .student2,
            colorTheme: .green,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create study sessions for progress tracking
        let session1 = StudySession(userProfile: profile, sessionType: .flashcards)
        session1.complete(itemsStudied: 15, correctAnswers: 12, focusAreas: ["7th Keup"])
        
        let session2 = StudySession(userProfile: profile, sessionType: .patterns)
        session2.complete(itemsStudied: 8, correctAnswers: 6, focusAreas: ["Forms"])
        
        testContext.insert(session1)
        testContext.insert(session2)
        try testContext.save()
        
        // Verify sessions were created
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 2)
        
        // Verify session data
        let flashcardSession = sessions.first { $0.sessionType == .flashcards }
        let patternSession = sessions.first { $0.sessionType == .patterns }
        
        XCTAssertNotNil(flashcardSession)
        XCTAssertNotNil(patternSession)
        XCTAssertEqual(flashcardSession?.itemsStudied, 15)
        XCTAssertEqual(patternSession?.itemsStudied, 8)
    }
    
    func testMultipleProfileDashboard() throws {
        // Test dashboard supports multiple profiles
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create multiple profiles
        let profile1 = UserProfile(
            name: "User One",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let profile2 = UserProfile(
            name: "User Two",
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile1)
        testContext.insert(profile2)
        try testContext.save()
        
        // Create sessions for each profile
        let session1 = StudySession(userProfile: profile1, sessionType: .flashcards)
        session1.complete(itemsStudied: 10, correctAnswers: 8, focusAreas: ["Techniques"])
        
        let session2 = StudySession(userProfile: profile2, sessionType: .patterns)
        session2.complete(itemsStudied: 5, correctAnswers: 4, focusAreas: ["Forms"])
        
        testContext.insert(session1)
        testContext.insert(session2)
        try testContext.save()
        
        // Verify separate tracking
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(allSessions.count, 2)
        
        let profile1Sessions = allSessions.filter { $0.userProfile.id == profile1.id }
        let profile2Sessions = allSessions.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Sessions.count, 1)
        XCTAssertEqual(profile2Sessions.count, 1)
    }
    
    func testStudySessionTypes() throws {
        // Test different study session types for dashboard
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Session Tester",
            avatar: .ninja,
            colorTheme: .purple,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create sessions of different types
        let flashcardSession = StudySession(userProfile: profile, sessionType: .flashcards)
        flashcardSession.complete(itemsStudied: 20, correctAnswers: 16, focusAreas: ["Terminology"])
        
        let patternSession = StudySession(userProfile: profile, sessionType: .patterns)
        patternSession.complete(itemsStudied: 3, correctAnswers: 3, focusAreas: ["Taeguk"])
        
        let stepSparringSession = StudySession(userProfile: profile, sessionType: .step_sparring)
        stepSparringSession.complete(itemsStudied: 6, correctAnswers: 5, focusAreas: ["Step Sparring"])
        
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
    }
    
    func testProgressCalculation() throws {
        // Test progress calculation infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Progress Calculator",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        
        // Record activity
        profile.recordActivity(studyTime: 600) // 10 minutes
        profile.totalFlashcardsSeen += 25
        
        try testContext.save()
        
        // Verify tracking data
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let savedProfile = savedProfiles.first!
        
        XCTAssertEqual(savedProfile.totalFlashcardsSeen, 25)
        XCTAssertGreaterThan(savedProfile.totalStudyTime, 0)
        XCTAssertNotNil(savedProfile.lastActiveAt)
    }
    
    func testDashboardPerformanceData() throws {
        // Test performance tracking for dashboard
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Performance Tester",
            avatar: .student2,
            colorTheme: .green,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create multiple sessions for performance tracking
        for i in 1...5 {
            let session = StudySession(userProfile: profile, sessionType: .flashcards)
            session.complete(
                itemsStudied: i * 5,
                correctAnswers: i * 4,
                focusAreas: ["Session \(i)"]
            )
            testContext.insert(session)
        }
        
        try testContext.save()
        
        // Verify performance data
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 5)
        
        let totalItemsStudied = sessions.reduce(0) { $0 + $1.itemsStudied }
        let totalCorrectAnswers = sessions.reduce(0) { $0 + $1.correctAnswers }
        
        XCTAssertEqual(totalItemsStudied, 75) // 5+10+15+20+25
        XCTAssertEqual(totalCorrectAnswers, 60) // 4+8+12+16+20
        
        // Calculate accuracy
        let accuracy = Double(totalCorrectAnswers) / Double(totalItemsStudied)
        XCTAssertEqual(accuracy, 0.8, accuracy: 0.01) // 80% accuracy
    }
    
    func testActivityStreakTracking() throws {
        // Test activity streak infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Streak Tracker",
            avatar: .ninja,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        
        // Record activity (simulates daily activity)
        profile.recordActivity(studyTime: 300)
        profile.streakDays = 5
        
        try testContext.save()
        
        // Verify streak data
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let savedProfile = savedProfiles.first!
        
        XCTAssertEqual(savedProfile.streakDays, 5)
        XCTAssertNotNil(savedProfile.lastActiveAt)
    }
    
    func testDashboardDataConsistency() throws {
        // Test data consistency for dashboard display
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let categories = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        
        // Verify data integrity
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        XCTAssertGreaterThan(categories.count, 0)
        
        // Verify relationships
        let firstTerm = terminology.first!
        XCTAssertNotNil(firstTerm.beltLevel)
        XCTAssertNotNil(firstTerm.category)
        
        // Verify belt level exists in belt levels array
        let termBeltExists = beltLevels.contains { belt in
            belt.id == firstTerm.beltLevel.id
        }
        XCTAssertTrue(termBeltExists)
        
        // Verify category exists in categories array
        let termCategoryExists = categories.contains { category in
            category.id == firstTerm.category.id
        }
        XCTAssertTrue(termCategoryExists)
    }
    
    func testDashboardQuickActions() throws {
        // Test quick action data availability
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        
        // Verify data needed for quick actions
        let testBelt = beltLevels.first!
        XCTAssertFalse(testBelt.name.isEmpty)
        XCTAssertFalse(testBelt.shortName.isEmpty)
        
        let testTerm = terminology.first!
        XCTAssertFalse(testTerm.englishTerm.isEmpty)
        XCTAssertFalse(testTerm.koreanHangul.isEmpty)
    }
}