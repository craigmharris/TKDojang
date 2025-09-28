import XCTest
import SwiftData
@testable import TKDojang

/**
 * FlashcardSystemTests_Simple.swift
 * 
 * PURPOSE: Simplified tests for the flashcard system that work with the actual codebase
 * 
 * FOCUSES ON:
 * - Core UserTerminologyProgress functionality
 * - Leitner box system mechanics
 * - Mastery level progression
 * - Basic spaced repetition logic
 */
final class FlashcardSystemTests_Simple: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testProfile: UserProfile!
    var testBelt: BeltLevel!
    var testCategory: TerminologyCategory!
    var testEntry: TerminologyEntry!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory test container with only working models
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
        
        // Set up test data
        setupTestData()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        testProfile = nil
        testBelt = nil
        testCategory = nil
        testEntry = nil
        try super.tearDownWithError()
    }
    
    private func setupTestData() {
        // Create test belt level
        testBelt = BeltLevel(name: "10th Keup (White Belt)", shortName: "10th Keup", colorName: "White", sortOrder: 15, isKyup: true)
        testContext.insert(testBelt)
        
        // Create test category
        testCategory = TerminologyCategory(name: "Techniques", displayName: "Basic Techniques", sortOrder: 1)
        testContext.insert(testCategory)
        
        // Create test terminology entry
        testEntry = TerminologyEntry(
            englishTerm: "Front Kick",
            koreanHangul: "앞차기",
            romanizedPronunciation: "ap chagi",
            beltLevel: testBelt,
            category: testCategory,
            difficulty: 2
        )
        testContext.insert(testEntry)
        
        // Create test user profile
        testProfile = UserProfile(name: "Test User", currentBeltLevel: testBelt, learningMode: .mastery)
        testContext.insert(testProfile)
        
        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to save test data: \(error)")
        }
    }
    
    // MARK: - Basic Progress Tests
    
    func testProgressCreation() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        try testContext.save()
        
        // Verify initial state
        XCTAssertEqual(progress.currentBox, 1, "Should start in box 1")
        XCTAssertEqual(progress.correctCount, 0, "Should start with 0 correct answers")
        XCTAssertEqual(progress.incorrectCount, 0, "Should start with 0 incorrect answers")
        XCTAssertEqual(progress.consecutiveCorrect, 0, "Should start with 0 consecutive correct")
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start with learning mastery level")
        XCTAssertNotNil(progress.nextReviewDate, "Should have initial review date")
        XCTAssertEqual(progress.totalReviews, 0, "Should start with 0 total reviews")
    }
    
    func testCorrectAnswerProgression() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        try testContext.save()
        
        // Record correct answer
        progress.recordAnswer(isCorrect: true, responseTime: 2.5)
        
        // Verify progression
        XCTAssertEqual(progress.currentBox, 2, "Should advance to box 2 after correct answer")
        XCTAssertEqual(progress.correctCount, 1, "Should increment correct count")
        XCTAssertEqual(progress.consecutiveCorrect, 1, "Should track consecutive correct")
        XCTAssertEqual(progress.totalReviews, 1, "Should increment total reviews")
        XCTAssertNotNil(progress.lastReviewedAt, "Should record review time")
    }
    
    func testIncorrectAnswerRegression() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        
        // Advance to box 3 first
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        
        let beforeBox = progress.currentBox
        XCTAssertEqual(beforeBox, 4, "Should be in box 4 before incorrect answer")
        
        // Record incorrect answer
        progress.recordAnswer(isCorrect: false, responseTime: 5.0)
        
        // Verify regression
        XCTAssertEqual(progress.currentBox, 1, "Should return to box 1 after incorrect answer")
        XCTAssertEqual(progress.incorrectCount, 1, "Should increment incorrect count")
        XCTAssertEqual(progress.consecutiveCorrect, 0, "Should reset consecutive correct")
        XCTAssertEqual(progress.masteryLevel, .learning, "Should return to learning level")
        XCTAssertEqual(progress.totalReviews, 4, "Should have 4 total reviews")
    }
    
    func testMasteryLevelProgression() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        
        // Test mastery progression
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start as learning")
        
        // Get to familiar (3 consecutive correct)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        XCTAssertEqual(progress.masteryLevel, .familiar, "Should be familiar with 3 consecutive correct")
        
        // Get to proficient (6 consecutive correct)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        XCTAssertEqual(progress.masteryLevel, .proficient, "Should be proficient with 6 consecutive correct")
        
        // Get to mastered (10 consecutive correct)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        XCTAssertEqual(progress.masteryLevel, .mastered, "Should be mastered with 10 consecutive correct")
    }
    
    func testBoxProgression() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        
        // Test box progression limits
        for expectedBox in 2...5 {
            progress.recordAnswer(isCorrect: true, responseTime: 2.0)
            XCTAssertEqual(progress.currentBox, expectedBox, "Should be in box \(expectedBox)")
        }
        
        // Additional correct answer shouldn't go beyond box 5
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        XCTAssertEqual(progress.currentBox, 5, "Should stay at maximum box 5")
    }
    
    func testResponseTimeTracking() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        
        // Record answer with specific response time
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        XCTAssertEqual(progress.averageResponseTime, 2.0, "Should track first response time")
        
        progress.recordAnswer(isCorrect: true, responseTime: 4.0)
        XCTAssertEqual(progress.averageResponseTime, 3.0, "Should calculate average response time")
        
        progress.recordAnswer(isCorrect: true, responseTime: 3.0)
        XCTAssertEqual(progress.averageResponseTime, 3.0, "Should maintain accurate average")
    }
    
    // MARK: - Database Query Tests
    
    func testProgressQuery() throws {
        // Create progress entry
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        try testContext.save()
        
        // Query for progress
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
        let fetchedProgress = try testContext.fetch(progressDescriptor)
        
        XCTAssertEqual(fetchedProgress.count, 1, "Should find one progress entry")
        XCTAssertEqual(fetchedProgress.first?.terminologyEntry.id, testEntry.id, "Should find correct progress entry")
    }
    
    func testProgressPersistence() throws {
        let progress = UserTerminologyProgress(terminologyEntry: testEntry, userProfile: testProfile)
        testContext.insert(progress)
        
        // Record several answers
        progress.recordAnswer(isCorrect: true, responseTime: 2.0)
        progress.recordAnswer(isCorrect: false, responseTime: 4.0)
        progress.recordAnswer(isCorrect: true, responseTime: 2.5)
        
        try testContext.save()
        
        // Re-fetch from database
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
        let fetchedProgress = try testContext.fetch(progressDescriptor)
        
        XCTAssertEqual(fetchedProgress.count, 1, "Should persist progress")
        let persisted = fetchedProgress.first!
        XCTAssertEqual(persisted.totalReviews, 3, "Should persist review count")
        XCTAssertEqual(persisted.correctCount, 2, "Should persist correct count")
        XCTAssertEqual(persisted.incorrectCount, 1, "Should persist incorrect count")
    }
    
    // MARK: - Performance Tests
    
    func testMultipleProgressEntries() throws {
        // Create multiple progress entries
        var progressEntries: [UserTerminologyProgress] = []
        
        for i in 1...10 {
            let entry = TerminologyEntry(
                englishTerm: "Test Term \(i)",
                koreanHangul: "테스트 \(i)",
                romanizedPronunciation: "test \(i)",
                beltLevel: testBelt,
                category: testCategory,
                difficulty: 1
            )
            testContext.insert(entry)
            
            let progress = UserTerminologyProgress(terminologyEntry: entry, userProfile: testProfile)
            testContext.insert(progress)
            progressEntries.append(progress)
        }
        
        try testContext.save()
        
        // Verify all entries were created
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
        let fetchedProgress = try testContext.fetch(progressDescriptor)
        XCTAssertEqual(fetchedProgress.count, 10, "Should create 10 progress entries")
    }
}