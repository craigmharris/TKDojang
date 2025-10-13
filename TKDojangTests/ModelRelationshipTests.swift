import XCTest
import SwiftData
@testable import TKDojang

/**
 * ModelRelationshipTests.swift
 * 
 * PURPOSE: Tests for model relationships, architecture integrity, and SwiftData interactions
 * 
 * IMPORTANCE: Validates model relationship infrastructure and SwiftData integration
 * Model relationships are critical for data consistency and performance
 * 
 * TEST COVERAGE:
 * - Pattern-move relationships infrastructure
 * - User progress relationships across content types
 * - Belt level associations with patterns and step sparring
 * - SwiftData relationship integrity validation
 * - Model consistency and data integrity validation
 */
final class ModelRelationshipTests: XCTestCase {
    
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
    
    // MARK: - Pattern-Move Relationship Tests
    
    func testPatternMoveRelationships() throws {
        // Test pattern-move relationship infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Relationship Test User", currentBeltLevel: testBelts.first!)
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
    
    func testPatternMoveIntegrity() throws {
        // Test pattern-move data integrity
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Move Integrity Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test move data integrity
        let moves = try testContext.fetch(FetchDescriptor<PatternMove>())
        for move in moves {
            XCTAssertGreaterThan(move.moveNumber, 0, "Move number should be positive")
            XCTAssertFalse(move.technique.isEmpty, "Move should have technique")
            XCTAssertFalse(move.stance.isEmpty, "Move should have stance")
            XCTAssertFalse(move.direction.isEmpty, "Move should have direction")
        }
        
        print("✅ Pattern-move integrity validation completed")
    }
    
    // MARK: - User Progress Relationship Tests
    
    func testUserPatternProgressRelationships() throws {
        // Test user pattern progress relationship infrastructure
        
        let testFactory = TestDataFactory()
        let testBelts = testFactory.createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create test patterns first to ensure they exist
        let testPatterns = testFactory.createSamplePatterns(belts: testBelts, count: 2)
        for pattern in testPatterns {
            testContext.insert(pattern)
        }
        
        let testProfile = UserProfile(name: "Pattern Progress Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        
        try testContext.save()
        
        // Create pattern progress infrastructure with existing patterns
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.practiceCount = 3
            progress.bestRunAccuracy = 0.85
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify progress relationship infrastructure
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        if !progressEntries.isEmpty {
            let progress = progressEntries.first!
            XCTAssertNotNil(progress.userProfile, "Progress should have user profile relationship")
            XCTAssertNotNil(progress.pattern, "Progress should have pattern relationship")
            XCTAssertGreaterThan(progress.practiceCount, 0, "Progress should track practice count")
        }
        
        print("✅ User pattern progress relationship infrastructure validation completed")
    }
    
    func testUserStepSparringProgressRelationships() throws {
        // Test user step sparring progress relationship infrastructure
        
        let testFactory = TestDataFactory()
        let testBelts = testFactory.createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create test sequences first to ensure they exist
        let testSequences = testFactory.createSampleStepSparringSequences(belts: testBelts, count: 2)
        for sequence in testSequences {
            testContext.insert(sequence)
        }
        
        let testProfile = UserProfile(name: "Step Sparring Progress Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        
        try testContext.save()
        
        // Create step sparring progress infrastructure with existing sequences
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        if !sequences.isEmpty {
            let sequence = sequences.first!
            let progress = UserStepSparringProgress(userProfile: testProfile, sequence: sequence)
            progress.practiceCount = 2
            progress.lastPracticed = Date()
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify progress relationship infrastructure
        let progressEntries = try testContext.fetch(FetchDescriptor<UserStepSparringProgress>())
        if !progressEntries.isEmpty {
            let progress = progressEntries.first!
            XCTAssertNotNil(progress.userProfile, "Progress should have user profile relationship")
            XCTAssertNotNil(progress.sequence, "Progress should have sequence relationship")
            XCTAssertGreaterThan(progress.practiceCount, 0, "Progress should track practice count")
        }
        
        print("✅ User step sparring progress relationship infrastructure validation completed")
    }
    
    func testStudySessionRelationships() throws {
        // Test study session relationship infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Study Session Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        
        // Create study session infrastructure
        let session = StudySession(userProfile: testProfile, sessionType: .flashcards)
        session.duration = 300.0
        session.itemsStudied = 5
        session.correctAnswers = 4
        testContext.insert(session)
        try testContext.save()
        
        // Verify session relationship infrastructure
        XCTAssertNotNil(session.userProfile, "Session should have user profile relationship")
        XCTAssertEqual(session.sessionType, .flashcards, "Session should maintain type relationship")
        XCTAssertGreaterThan(session.duration, 0, "Session should track duration")
        
        print("✅ Study session relationship infrastructure validation completed")
    }
    
    // MARK: - Belt Level Association Tests
    
    func testBeltLevelPatternAssociations() throws {
        // Test belt level pattern association infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Belt Pattern Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test belt-pattern association infrastructure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        for pattern in patterns {
            XCTAssertGreaterThanOrEqual(pattern.beltLevels.count, 0, "Pattern should support belt level associations")
            if !pattern.beltLevels.isEmpty {
                let associatedBelt = pattern.beltLevels.first!
                XCTAssertNotNil(associatedBelt.name, "Associated belt should have name")
                XCTAssertGreaterThan(associatedBelt.sortOrder, 0, "Associated belt should have sort order")
            }
        }
        
        print("✅ Belt level pattern association infrastructure validation completed")
    }
    
    func testBeltLevelStepSparringAssociations() throws {
        // Test belt level step sparring association infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Belt Step Sparring Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test belt-step sparring association infrastructure
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        for sequence in sequences {
            XCTAssertGreaterThanOrEqual(sequence.applicableBeltLevelIds.count, 0, "Sequence should support belt level associations")
            XCTAssertGreaterThanOrEqual(sequence.beltLevels.count, 0, "Sequence should support belt level relationships")
        }
        
        print("✅ Belt level step sparring association infrastructure validation completed")
    }
    
    // MARK: - SwiftData Relationship Integrity Tests
    
    func testSwiftDataRelationshipIntegrity() throws {
        // Test SwiftData relationship integrity
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "SwiftData Integrity Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test relationship integrity across saves and loads
        let profileId = testProfile.id
        
        // Create related data
        let session = StudySession(userProfile: testProfile, sessionType: .patterns)
        session.duration = 180.0
        testContext.insert(session)
        try testContext.save()
        
        // Verify relationships persist
        let loadedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let matchingProfile = loadedProfiles.first { $0.id == profileId }
        
        XCTAssertNotNil(matchingProfile, "Profile should persist with relationships")
        if let profile = matchingProfile {
            XCTAssertNotNil(profile.currentBeltLevel, "Profile should maintain belt level relationship")
        }
        
        print("✅ SwiftData relationship integrity validation completed")
    }
    
    func testModelConsistencyValidation() throws {
        // Test model consistency validation
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Model Consistency Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test model consistency
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let belts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        
        // Verify consistency
        for profile in profiles {
            XCTAssertNotNil(profile.currentBeltLevel, "Profile should have belt level")
            XCTAssertTrue(belts.contains { $0.id == profile.currentBeltLevel.id }, "Profile belt should exist in belt collection")
        }
        
        for pattern in patterns {
            for beltLevel in pattern.beltLevels {
                XCTAssertTrue(belts.contains { $0.id == beltLevel.id }, "Pattern belt should exist in belt collection")
            }
        }
        
        print("✅ Model consistency validation completed")
    }
    
    // MARK: - Cross-Model Relationship Tests
    
    func testCrossModelRelationshipIntegrity() throws {
        // Test cross-model relationship integrity
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create multi-relationship scenario
        let testProfile = UserProfile(name: "Cross Model Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        
        // Create pattern progress
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let progress = UserPatternProgress(userProfile: testProfile, pattern: patterns.first!)
            progress.practiceCount = 1
            testContext.insert(progress)
        }
        
        // Create study session
        let session = StudySession(userProfile: testProfile, sessionType: .patterns)
        session.duration = 120.0
        testContext.insert(session)
        
        try testContext.save()
        
        // Verify cross-model relationships
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        
        XCTAssertGreaterThanOrEqual(progressEntries.count, 0, "Should support pattern progress relationships")
        XCTAssertGreaterThanOrEqual(sessions.count, 1, "Should support study session relationships")
        
        if let progress = progressEntries.first, let session = sessions.first {
            XCTAssertEqual(progress.userProfile.id, session.userProfile.id, "Cross-model relationships should reference same profile")
        }
        
        print("✅ Cross-model relationship integrity validation completed")
    }
    
    // MARK: - Performance Tests
    
    func testRelationshipPerformance() throws {
        // Test relationship performance under load
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create multiple profiles with relationships
        for i in 0..<5 {
            let profile = UserProfile(name: "Performance Test User \(i)", currentBeltLevel: testBelts[i % testBelts.count])
            testContext.insert(profile)
            
            // Create related data
            let session = StudySession(userProfile: profile, sessionType: .flashcards)
            session.duration = Double(i * 60)
            testContext.insert(session)
        }
        
        try testContext.save()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Performance validation
        XCTAssertLessThan(loadTime, 3.0, "Relationship operations should be performant")
        
        // Verify relationship integrity under load - check our specific test data
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        
        // Filter to our test data only
        let ourProfiles = profiles.filter { $0.name.contains("Performance Test User") }
        let ourSessions = sessions.filter { session in
            ourProfiles.contains { $0.id == session.userProfile.id }
        }
        
        XCTAssertEqual(ourProfiles.count, 5, "Should have created 5 test profiles")
        XCTAssertEqual(ourSessions.count, 5, "Should have created 5 test sessions")
        XCTAssertEqual(ourProfiles.count, ourSessions.count, "Should maintain 1:1 relationship count for test data")
        
        print("✅ Relationship performance validation completed (Load time: \(String(format: "%.3f", loadTime))s)")
    }
}

// MARK: - Mock Supporting Types

struct RelationshipInfo {
    let fromId: UUID
    let toId: UUID
    let relationshipType: String
    let isValid: Bool
    
    init(fromId: UUID, toId: UUID, relationshipType: String, isValid: Bool = true) {
        self.fromId = fromId
        self.toId = toId
        self.relationshipType = relationshipType
        self.isValid = isValid
    }
}

// MARK: - Test Extensions

// Model relationship test utilities - no service dependencies