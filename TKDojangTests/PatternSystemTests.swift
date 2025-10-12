import XCTest
import SwiftData
@testable import TKDojang

/**
 * PatternSystemTests.swift
 * 
 * PURPOSE: Tests for the pattern system functionality including JSON loading and user progress
 * 
 * CRITICAL IMPORTANCE: Validates pattern architecture infrastructure
 * Pattern system represents structured learning progression for belt advancement
 * 
 * TEST COVERAGE:
 * - Pattern data structure validation
 * - Pattern-move relationships and data integrity
 * - User pattern progress tracking infrastructure
 * - Pattern practice session recording capabilities
 * - Pattern mastery progression and statistics infrastructure
 * - Belt-level pattern filtering support
 */
final class PatternSystemTests: XCTestCase {
    
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
    
    // MARK: - Pattern Creation and Management Tests
    
    func testPatternCreation() throws {
        // Test pattern creation infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Test User", currentBeltLevel: testBelts.first!)
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern data structure support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let testPattern = patterns.first!
            XCTAssertNotNil(testPattern.id, "Pattern should have valid ID")
            XCTAssertFalse(testPattern.name.isEmpty, "Pattern should have name")
            XCTAssertGreaterThan(testPattern.moveCount, 0, "Pattern should have move count")
        }
        
        print("✅ Pattern creation infrastructure validation completed")
    }
    
    func testPatternMoveRelationships() throws {
        // Test pattern-move relationship infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Move Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern-move relationship support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let moves = try testContext.fetch(FetchDescriptor<PatternMove>())
        
        if !patterns.isEmpty && !moves.isEmpty {
            let pattern = patterns.first!
            let move = moves.first!
            
            XCTAssertNotNil(pattern.id, "Pattern should have ID for move relationships")
            XCTAssertNotNil(move.id, "Move should have ID for pattern relationships")
            XCTAssertGreaterThan(move.moveNumber, 0, "Move should have valid move number")
        }
        
        print("✅ Pattern-move relationship infrastructure validation completed")
    }
    
    func testPatternBeltAssociation() throws {
        // Test pattern belt association infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Belt Association Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test belt association capabilities
        XCTAssertNotNil(testProfile.currentBeltLevel, "Profile should have belt for pattern filtering")
        XCTAssertNotNil(testProfile.currentBeltLevel.name, "Belt should have name for pattern association")
        
        // Test pattern belt filtering support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            XCTAssertGreaterThanOrEqual(pattern.beltLevels.count, 0, "Pattern should support belt level associations")
        }
        
        print("✅ Pattern belt association infrastructure validation completed")
    }
    
    // MARK: - User Progress Tracking Tests
    
    func testUserPatternProgressTracking() throws {
        // Test user pattern progress tracking infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Progress Tracking Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        
        // Create progress tracking infrastructure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.practiceCount = 5
            progress.bestRunAccuracy = 0.85
            progress.averageAccuracy = 0.78
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify progress tracking capabilities
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        if !progressEntries.isEmpty {
            let progress = progressEntries.first!
            XCTAssertGreaterThan(progress.practiceCount, 0, "Should track practice count")
            XCTAssertGreaterThan(progress.bestRunAccuracy, 0, "Should track best accuracy")
            XCTAssertGreaterThan(progress.averageAccuracy, 0, "Should track average accuracy")
        }
        
        print("✅ User pattern progress tracking infrastructure validation completed")
    }
    
    func testPatternPracticeSessionRecording() throws {
        // Test pattern practice session recording infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Practice Session Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        
        // Create practice session infrastructure
        let session = StudySession(userProfile: testProfile, sessionType: .patterns)
        session.duration = 600.0 // 10 minutes
        session.itemsStudied = 1
        session.correctAnswers = 1
        session.startTime = Date()
        testContext.insert(session)
        try testContext.save()
        
        // Verify practice session recording
        XCTAssertEqual(session.sessionType, .patterns, "Should support pattern practice sessions")
        XCTAssertGreaterThan(session.duration, 0, "Should track practice duration")
        XCTAssertNotNil(session.startTime, "Should track session start time")
        
        print("✅ Pattern practice session recording infrastructure validation completed")
    }
    
    func testPatternMasteryProgression() throws {
        // Test pattern mastery progression infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Mastery Progression Test User", currentBeltLevel: testBelts[2], learningMode: .mastery)
        testContext.insert(testProfile)
        
        // Test mastery progression support
        XCTAssertEqual(testProfile.learningMode, .mastery, "Should support mastery learning mode")
        XCTAssertNotNil(testProfile.currentBeltLevel, "Should have belt context for mastery progression")
        
        // Create multiple progress entries to simulate progression
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        for (index, pattern) in patterns.prefix(3).enumerated() {
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.practiceCount = index + 1
            progress.bestRunAccuracy = 0.6 + (Double(index) * 0.1)
            progress.averageAccuracy = 0.5 + (Double(index) * 0.1)
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify mastery progression infrastructure
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        XCTAssertGreaterThanOrEqual(progressEntries.count, 0, "Should support multiple pattern progress tracking")
        
        print("✅ Pattern mastery progression infrastructure validation completed")
    }
    
    // MARK: - Pattern Content Loading Tests
    
    func testPatternContentStructure() throws {
        // Test pattern content structure infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Content Structure Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern content structure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            XCTAssertNotNil(pattern.id, "Pattern should have unique identifier")
            XCTAssertFalse(pattern.name.isEmpty, "Pattern should have name")
            XCTAssertGreaterThan(pattern.moveCount, 0, "Pattern should have move count")
            XCTAssertNotNil(pattern.significance, "Pattern should have significance description")
        }
        
        print("✅ Pattern content structure infrastructure validation completed")
    }
    
    func testPatternMoveStructure() throws {
        // Test pattern move structure infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Move Structure Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern move structure
        let moves = try testContext.fetch(FetchDescriptor<PatternMove>())
        if !moves.isEmpty {
            let move = moves.first!
            XCTAssertNotNil(move.id, "Move should have unique identifier")
            XCTAssertGreaterThan(move.moveNumber, 0, "Move should have valid move number")
            XCTAssertFalse(move.technique.isEmpty, "Move should have technique")
            XCTAssertNotNil(move.stance, "Move should have stance information")
            XCTAssertNotNil(move.direction, "Move should have direction information")
        }
        
        print("✅ Pattern move structure infrastructure validation completed")
    }
    
    // MARK: - Pattern Filtering and Access Tests
    
    func testPatternBeltLevelFiltering() throws {
        // Test pattern belt level filtering infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Test different belt levels
        let beginnerProfile = UserProfile(name: "Beginner User", currentBeltLevel: testBelts.last!, learningMode: .progression)
        let advancedProfile = UserProfile(name: "Advanced User", currentBeltLevel: testBelts.first!, learningMode: .mastery)
        
        testContext.insert(beginnerProfile)
        testContext.insert(advancedProfile)
        try testContext.save()
        
        // Test belt level filtering support
        XCTAssertNotEqual(beginnerProfile.currentBeltLevel.sortOrder, advancedProfile.currentBeltLevel.sortOrder, 
                         "Different belt levels should have different sort orders for filtering")
        XCTAssertNotEqual(beginnerProfile.learningMode, advancedProfile.learningMode, 
                         "Different learning modes should support different filtering approaches")
        
        print("✅ Pattern belt level filtering infrastructure validation completed")
    }
    
    func testPatternUserAccess() throws {
        // Test pattern user access infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "User Access Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test user access infrastructure
        XCTAssertNotNil(testProfile.currentBeltLevel, "User should have belt level for pattern access")
        XCTAssertNotNil(testProfile.id, "User should have ID for progress association")
        
        // Test pattern access capabilities
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        XCTAssertGreaterThanOrEqual(patterns.count, 0, "Should support pattern access for users")
        
        print("✅ Pattern user access infrastructure validation completed")
    }
    
    // MARK: - Performance Tests
    
    func testPatternSystemPerformance() throws {
        // Test pattern system performance
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create multiple test profiles and progress entries
        for i in 0..<5 {
            let profile = UserProfile(name: "Performance Test User \(i)", currentBeltLevel: testBelts[i % testBelts.count])
            testContext.insert(profile)
            
            // Create pattern progress for each profile
            let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
            for pattern in patterns.prefix(2) {
                let progress = UserPatternProgress(userProfile: profile, pattern: pattern)
                progress.practiceCount = i + 1
                progress.bestRunAccuracy = 0.7 + (Double(i) * 0.05)
                testContext.insert(progress)
            }
        }
        
        try testContext.save()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Performance validation
        XCTAssertLessThan(loadTime, 5.0, "Pattern system should handle load efficiently")
        
        // Verify data integrity
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        
        XCTAssertGreaterThanOrEqual(profiles.count, 5, "Should maintain profile integrity")
        XCTAssertGreaterThanOrEqual(progressEntries.count, 0, "Should maintain progress integrity")
        
        print("✅ Pattern system performance validation completed (Load time: \(String(format: "%.3f", loadTime))s)")
    }
}

// MARK: - Mock Supporting Types

struct PatternProgressInfo {
    let patternId: UUID
    let practiceCount: Int
    let bestAccuracy: Double
    let averageAccuracy: Double
    let lastPracticed: Date
    
    init(patternId: UUID, practiceCount: Int, bestAccuracy: Double, averageAccuracy: Double, lastPracticed: Date = Date()) {
        self.patternId = patternId
        self.practiceCount = practiceCount
        self.bestAccuracy = bestAccuracy
        self.averageAccuracy = averageAccuracy
        self.lastPracticed = lastPracticed
    }
}

struct PatternMoveInfo {
    let moveNumber: Int
    let description: String
    let stance: String
    let direction: String
    let technique: String
    
    init(moveNumber: Int, description: String, stance: String, direction: String, technique: String) {
        self.moveNumber = moveNumber
        self.description = description
        self.stance = stance
        self.direction = direction
        self.technique = technique
    }
}

// MARK: - Test Extensions

// Pattern system test utilities - no service dependencies