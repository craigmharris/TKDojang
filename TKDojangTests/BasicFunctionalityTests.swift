import XCTest
import SwiftData
@testable import TKDojang

/**
 * BasicFunctionalityTests.swift
 * 
 * PURPOSE: Basic tests that work with the current TKDojang codebase
 * 
 * These tests validate core functionality without making assumptions about
 * APIs that may not exist yet.
 */
final class BasicFunctionalityTests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create minimal test container with known models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self
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
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Framework Tests
    
    func testXCTestFrameworkWorks() throws {
        XCTAssertTrue(true, "XCTest framework should be working")
    }
    
    func testSwiftDataContainerCreation() throws {
        XCTAssertNotNil(testContainer, "Test container should be created")
        XCTAssertNotNil(testContext, "Test context should be available")
    }
    
    // MARK: - Model Creation Tests
    
    func testBeltLevelCreation() throws {
        let belt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup", 
            colorName: "White",
            sortOrder: 15,
            isKyup: true
        )
        
        testContext.insert(belt)
        try testContext.save()
        
        // Verify creation
        XCTAssertFalse(belt.name.isEmpty, "Belt should have a name")
        XCTAssertFalse(belt.shortName.isEmpty, "Belt should have a short name")
        XCTAssertFalse(belt.colorName.isEmpty, "Belt should have a color name")
        XCTAssertGreaterThan(belt.sortOrder, 0, "Belt should have valid sort order")
        XCTAssertTrue(belt.isKyup, "This should be a kyup grade")
    }
    
    func testTerminologyCategoryCreation() throws {
        let category = TerminologyCategory(
            name: "techniques",
            displayName: "Basic Techniques",
            sortOrder: 1
        )
        
        testContext.insert(category)
        try testContext.save()
        
        // Verify creation
        XCTAssertFalse(category.name.isEmpty, "Category should have a name")
        XCTAssertFalse(category.displayName.isEmpty, "Category should have a display name")
        XCTAssertGreaterThan(category.sortOrder, 0, "Category should have valid sort order")
    }
    
    func testTerminologyEntryCreation() throws {
        // Create dependencies first
        let belt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup",
            colorName: "White", 
            sortOrder: 15,
            isKyup: true
        )
        testContext.insert(belt)
        
        let category = TerminologyCategory(
            name: "techniques",
            displayName: "Basic Techniques",
            sortOrder: 1
        )
        testContext.insert(category)
        
        // Create terminology entry
        let entry = TerminologyEntry(
            englishTerm: "Front Kick",
            koreanHangul: "앞차기", 
            romanizedPronunciation: "ap chagi",
            beltLevel: belt,
            category: category,
            difficulty: 2
        )
        testContext.insert(entry)
        try testContext.save()
        
        // Verify creation
        XCTAssertFalse(entry.englishTerm.isEmpty, "Entry should have English term")
        XCTAssertFalse(entry.koreanHangul.isEmpty, "Entry should have Korean hangul")
        XCTAssertFalse(entry.romanizedPronunciation.isEmpty, "Entry should have romanized pronunciation")
        XCTAssertEqual(entry.beltLevel.id, belt.id, "Entry should reference correct belt")
        XCTAssertEqual(entry.category.id, category.id, "Entry should reference correct category")
        XCTAssertGreaterThan(entry.difficulty, 0, "Entry should have valid difficulty")
    }
    
    func testUserProfileCreation() throws {
        // Create belt level first
        let belt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup",
            colorName: "White",
            sortOrder: 15, 
            isKyup: true
        )
        testContext.insert(belt)
        
        // Create user profile
        let profile = UserProfile(
            currentBeltLevel: belt,
            learningMode: .mastery
        )
        testContext.insert(profile)
        try testContext.save()
        
        // Verify creation
        XCTAssertNotNil(profile.id, "Profile should have an ID")
        XCTAssertEqual(profile.currentBeltLevel.id, belt.id, "Profile should reference correct belt")
        XCTAssertEqual(profile.learningMode, .mastery, "Profile should have correct learning mode")
        XCTAssertGreaterThan(profile.dailyStudyGoal, 0, "Profile should have positive study goal")
    }
    
    // MARK: - Basic Query Tests
    
    func testBasicDatabaseQueries() throws {
        // Create test data
        let belt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup",
            colorName: "White",
            sortOrder: 15,
            isKyup: true
        )
        testContext.insert(belt)
        try testContext.save()
        
        // Test fetch
        let beltDescriptor = FetchDescriptor<BeltLevel>()
        let fetchedBelts = try testContext.fetch(beltDescriptor)
        
        XCTAssertEqual(fetchedBelts.count, 1, "Should fetch one belt level")
        XCTAssertEqual(fetchedBelts.first?.shortName, "10th Keup", "Should fetch correct belt")
    }
    
    // MARK: - DataManager Integration Test
    
    func testDataManagerExists() throws {
        // Test that DataManager can be accessed (without initializing to avoid conflicts)
        let dataManagerType = DataManager.self
        XCTAssertNotNil(dataManagerType, "DataManager class should exist")
    }
}