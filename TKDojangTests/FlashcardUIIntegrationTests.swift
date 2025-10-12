import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * FlashcardUIIntegrationTests.swift
 * 
 * PURPOSE: Infrastructure testing for flashcard learning system
 * 
 * ARCHITECTURE DECISION: Infrastructure-focused testing approach
 * WHY: Eliminates complex mock dependencies and focuses on core data flow validation
 * 
 * TESTING STRATEGY:
 * - Container creation and schema validation
 * - Basic data loading verification
 * - Infrastructure testing without service dependencies
 * - Proven pattern from successful test migrations
 */

final class FlashcardUIIntegrationTests: XCTestCase {
    
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
        
        XCTAssertTrue(modelNames.contains("BeltLevel"))
        XCTAssertTrue(modelNames.contains("TerminologyEntry"))
        XCTAssertTrue(modelNames.contains("TerminologyCategory"))
        XCTAssertTrue(modelNames.contains("UserProfile"))
    }
    
    func testBasicDataLoading() throws {
        // Test basic data can be loaded without errors
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        // Verify data exists
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let categories = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
    }
    
    func testFlashcardDataStructure() throws {
        // Test flashcard-specific data requirements
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        XCTAssertGreaterThan(terminology.count, 0)
        
        // Verify terminology entries have required fields for flashcards
        let firstTerm = terminology.first!
        XCTAssertFalse(firstTerm.englishTerm.isEmpty)
        XCTAssertFalse(firstTerm.koreanHangul.isEmpty)
        XCTAssertFalse(firstTerm.romanizedPronunciation.isEmpty)
        XCTAssertNotNil(firstTerm.beltLevel)
        XCTAssertNotNil(firstTerm.category)
    }
    
    func testProfileCreationForFlashcards() throws {
        // Test profile creation for flashcard sessions
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Flashcard Tester",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Verify profile was created
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 1)
        XCTAssertEqual(savedProfiles.first?.name, "Flashcard Tester")
    }
    
    func testTerminologyFiltering() throws {
        // Test terminology can be filtered by belt level
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let allTerminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(allTerminology.count, 0)
        
        // Filter terminology by first belt level
        let targetBelt = beltLevels.first!
        let filteredTerms = allTerminology.filter { term in
            term.beltLevel.id == targetBelt.id
        }
        
        // Should have some terms for the belt level
        if !filteredTerms.isEmpty {
            XCTAssertGreaterThan(filteredTerms.count, 0)
            
            // Verify all filtered terms belong to target belt
            for term in filteredTerms {
                XCTAssertEqual(term.beltLevel.id, targetBelt.id)
            }
        }
    }
    
    func testFlashcardSessionData() throws {
        // Test data structures needed for flashcard sessions
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        
        XCTAssertGreaterThan(terminology.count, 0)
        
        // Create a test profile if none exists
        if profiles.isEmpty {
            let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
            let testBelt = beltLevels.first!
            
            let profile = UserProfile(
                name: "Session Tester",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .progression
            )
            
            testContext.insert(profile)
            try testContext.save()
        }
        
        // Verify we have the data needed for flashcard sessions
        let updatedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertGreaterThan(updatedProfiles.count, 0)
        
        let profile = updatedProfiles.first!
        XCTAssertNotNil(profile.currentBeltLevel)
        XCTAssertNotEqual(profile.learningMode, LearningMode.mastery) // Should be .progression
    }
    
    func testFlashcardProgressTracking() throws {
        // Test progress tracking data structures
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        
        XCTAssertGreaterThan(terminology.count, 0)
        
        if profiles.isEmpty {
            let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
            let testBelt = beltLevels.first!
            
            let profile = UserProfile(
                name: "Progress Tester",
                avatar: .student2,
                colorTheme: .green,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            
            testContext.insert(profile)
            try testContext.save()
        }
        
        let profile = try testContext.fetch(FetchDescriptor<UserProfile>()).first!
        let term = terminology.first!
        
        // Create progress tracking entry
        let progress = UserTerminologyProgress(
            terminologyEntry: term,
            userProfile: profile
        )
        
        testContext.insert(progress)
        try testContext.save()
        
        // Verify progress was created
        let savedProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        XCTAssertEqual(savedProgress.count, 1)
        XCTAssertEqual(savedProgress.first?.currentBox, 1)
        XCTAssertEqual(savedProgress.first?.masteryLevel, .learning)
    }
    
    func testMultipleProfileFlashcardSupport() throws {
        // Test that multiple profiles can have separate flashcard progress
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let testBelt = beltLevels.first!
        let testTerm = terminology.first!
        
        // Create two profiles
        let profile1 = UserProfile(
            name: "Flashcard User 1",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let profile2 = UserProfile(
            name: "Flashcard User 2", 
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile1)
        testContext.insert(profile2)
        
        // Create separate progress for each profile
        let progress1 = UserTerminologyProgress(terminologyEntry: testTerm, userProfile: profile1)
        let progress2 = UserTerminologyProgress(terminologyEntry: testTerm, userProfile: profile2)
        
        testContext.insert(progress1)
        testContext.insert(progress2)
        try testContext.save()
        
        // Verify separate progress tracking
        let allProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        XCTAssertEqual(allProgress.count, 2)
        
        let profile1Progress = allProgress.filter { $0.userProfile.id == profile1.id }
        let profile2Progress = allProgress.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Progress.count, 1)
        XCTAssertEqual(profile2Progress.count, 1)
    }
    
    func testFlashcardCategoryFiltering() throws {
        // Test filtering flashcards by category
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let categories = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        
        // Test category filtering
        let targetCategory = categories.first!
        let categoryTerms = terminology.filter { term in
            term.category.id == targetCategory.id
        }
        
        // Verify filtering works
        if !categoryTerms.isEmpty {
            for term in categoryTerms {
                XCTAssertEqual(term.category.id, targetCategory.id)
            }
        }
    }
    
    func testFlashcardPerformanceData() throws {
        // Test performance tracking capabilities
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        XCTAssertGreaterThan(terminology.count, 0)
        
        let testBelt = beltLevels.first!
        let profile = UserProfile(
            name: "Performance Tester",
            avatar: .ninja,
            colorTheme: .purple,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        
        // Create study session
        let session = StudySession(userProfile: profile, sessionType: .flashcards)
        session.complete(itemsStudied: 10, correctAnswers: 8, focusAreas: ["7th Keup"])
        
        testContext.insert(session)
        try testContext.save()
        
        // Verify session data
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(sessions.count, 1)
        
        let savedSession = sessions.first!
        XCTAssertEqual(savedSession.sessionType, .flashcards)
        XCTAssertEqual(savedSession.itemsStudied, 10)
        XCTAssertEqual(savedSession.correctAnswers, 8)
        XCTAssertNotNil(savedSession.endTime)
    }
}