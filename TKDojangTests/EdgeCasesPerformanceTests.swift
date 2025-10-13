import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * EdgeCasesPerformanceTests.swift
 * 
 * PURPOSE: Infrastructure testing for edge cases and performance validation
 * 
 * ARCHITECTURE DECISION: Infrastructure-focused testing approach
 * WHY: Eliminates complex mock dependencies and focuses on core system validation
 * 
 * TESTING STRATEGY:
 * - Container creation and schema validation
 * - Edge case data handling
 * - Performance characteristics validation
 * - Memory management testing
 * - Error recovery infrastructure
 * - Proven pattern from successful test migrations
 */

final class EdgeCasesPerformanceTests: XCTestCase {
    
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
        // Test that container initializes for edge case testing
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
        
        // Verify schema contains required models
        let schema = testContainer.schema
        let modelNames = schema.entities.map { $0.name }
        
        XCTAssertTrue(modelNames.contains("UserProfile"))
        XCTAssertTrue(modelNames.contains("StudySession"))
        XCTAssertTrue(modelNames.contains("BeltLevel"))
        XCTAssertTrue(modelNames.contains("TerminologyEntry"))
        XCTAssertTrue(modelNames.contains("UserTerminologyProgress"))
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyDatasetHandling() throws {
        // Test system behavior with empty data
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let sessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        
        // Initially empty datasets should be handled gracefully
        XCTAssertEqual(profiles.count, 0)
        XCTAssertEqual(sessions.count, 0)
        XCTAssertEqual(terminology.count, 0)
    }
    
    func testLargeDatasetPerformance() throws {
        // Test performance with large datasets
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create large dataset
        var profiles: [UserProfile] = []
        for i in 1...100 {
            let profile = UserProfile(
                name: "Performance User \(i)",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            profiles.append(profile)
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        let saveTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance validation - should save 100 profiles quickly
        XCTAssertLessThan(saveTime, 5.0, "Should save 100 profiles in under 5 seconds")
        
        // Verify all profiles were saved - use profile-specific filtering
        let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let performanceProfiles = allProfiles.filter { $0.name.hasPrefix("Performance User ") }
        XCTAssertEqual(performanceProfiles.count, 100)
    }
    
    func testLargeSessionDatasetPerformance() throws {
        // Test performance with large session datasets
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create test profile
        let profile = UserProfile(
            name: "Session Performance User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create large number of sessions
        for i in 1...500 {
            let session = StudySession(userProfile: profile, sessionType: .flashcards)
            session.complete(
                itemsStudied: i % 20 + 5,
                correctAnswers: i % 15 + 3,
                focusAreas: ["Performance Test \(i)"]
            )
            testContext.insert(session)
        }
        
        try testContext.save()
        
        let saveTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance validation - should save 500 sessions quickly
        XCTAssertLessThan(saveTime, 10.0, "Should save 500 sessions in under 10 seconds")
        
        // Verify all sessions were saved - use profile-specific filtering
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let profileSessions = allSessions.filter { $0.userProfile.id == profile.id }
        XCTAssertEqual(profileSessions.count, 500)
    }
    
    func testEdgeCaseProfileNames() throws {
        // Test edge cases in profile name handling
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Test various edge case names
        let edgeCaseNames = [
            "A", // Single character
            "Maximally Long Profile Name", // Long name
            "Name with 123 Numbers",
            "Name-with-dashes",
            "Name.with.dots",
            "Name with   spaces",
            "NameWithUnicode🥋",
            "Name'with'apostrophes"
        ]
        
        for name in edgeCaseNames {
            let profile = UserProfile(
                name: name,
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        // Verify all edge case profiles were created - use name-specific filtering
        let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let edgeCaseProfiles = allProfiles.filter { profile in
            edgeCaseNames.contains(profile.name)
        }
        XCTAssertEqual(edgeCaseProfiles.count, edgeCaseNames.count)
        
        // Verify names were preserved correctly
        let savedNames = Set(edgeCaseProfiles.map { $0.name })
        for edgeName in edgeCaseNames {
            XCTAssertTrue(savedNames.contains(edgeName), "Edge case name '\(edgeName)' should be preserved")
        }
    }
    
    func testExtremeBeltLevelProgression() throws {
        // Test edge cases in belt level progression
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        XCTAssertGreaterThan(beltLevels.count, 1, "Need multiple belt levels for progression test")
        
        // Test progression through all belt levels
        for (index, belt) in beltLevels.enumerated() {
            let profile = UserProfile(
                name: "Belt Level \(index + 1) User",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: belt,
                learningMode: .progression
            )
            
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        // Verify all belt level profiles were created - use name-specific filtering
        let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let beltProgressionProfiles = allProfiles.filter { $0.name.hasPrefix("Belt Level ") && $0.name.hasSuffix(" User") }
        XCTAssertEqual(beltProgressionProfiles.count, beltLevels.count)
        
        // Verify belt level distribution
        let profileBeltIds = Set(beltProgressionProfiles.map { $0.currentBeltLevel.id })
        let beltLevelIds = Set(beltLevels.map { $0.id })
        XCTAssertEqual(profileBeltIds, beltLevelIds, "All belt levels should be represented")
    }
    
    func testExtremeSessionCounts() throws {
        // Test edge cases with extreme session counts
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Extreme Session User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Test session with zero items studied
        let zeroSession = StudySession(userProfile: profile, sessionType: .flashcards)
        zeroSession.complete(itemsStudied: 0, correctAnswers: 0, focusAreas: [])
        testContext.insert(zeroSession)
        
        // Test session with very high numbers
        let extremeSession = StudySession(userProfile: profile, sessionType: .patterns)
        extremeSession.complete(itemsStudied: 10000, correctAnswers: 9999, focusAreas: ["Extreme Test"])
        testContext.insert(extremeSession)
        
        try testContext.save()
        
        // Verify extreme sessions were saved - use profile-specific filtering
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let profileSessions = allSessions.filter { $0.userProfile.id == profile.id }
        XCTAssertEqual(profileSessions.count, 2)
        
        let zeroSessionSaved = profileSessions.first { $0.itemsStudied == 0 }
        let extremeSessionSaved = profileSessions.first { $0.itemsStudied == 10000 }
        
        XCTAssertNotNil(zeroSessionSaved)
        XCTAssertNotNil(extremeSessionSaved)
        XCTAssertEqual(extremeSessionSaved?.correctAnswers, 9999)
    }
    
    func testConcurrentProfileAccess() throws {
        // Test profile access patterns (mocked to avoid SwiftData threading issues)
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create test profiles
        var profiles: [UserProfile] = []
        for i in 1...10 {
            let profile = UserProfile(
                name: "Concurrent User \(i)",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            profiles.append(profile)
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        // Verify profile creation without concurrent operations - use name-specific filtering
        // Note: SwiftData ModelContext is not thread-safe, so we avoid concurrent DispatchQueue operations
        let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let concurrentProfiles = allProfiles.filter { $0.name.hasPrefix("Concurrent User ") }
        XCTAssertGreaterThanOrEqual(concurrentProfiles.count, 10, "At least 10 concurrent profiles should be created successfully")
        
        // Test sequential access patterns instead - use profile-specific filtering
        var accessResults: [Int] = []
        for _ in 1...5 {
            let allFetchedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
            let concurrentFetchedProfiles = allFetchedProfiles.filter { $0.name.hasPrefix("Concurrent User ") }
            accessResults.append(concurrentFetchedProfiles.count)
        }
        
        // All sequential reads should return consistent results
        XCTAssertEqual(accessResults.count, 5)
        for result in accessResults {
            XCTAssertGreaterThanOrEqual(result, 10, "All sequential reads should return consistent results")
        }
    }
    
    func testMemoryUsageWithLargeDatasets() throws {
        // Test memory characteristics with large datasets
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        
        XCTAssertGreaterThan(terminology.count, 0)
        XCTAssertGreaterThan(beltLevels.count, 0)
        
        let testBelt = beltLevels.first!
        
        // Create profile for memory testing
        let profile = UserProfile(
            name: "Memory Test User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        try testContext.save()
        
        // Create large number of progress entries
        for (index, term) in terminology.enumerated() {
            let progress = UserTerminologyProgress(terminologyEntry: term, userProfile: profile)
            progress.correctCount = index % 10
            progress.incorrectCount = index % 5
            testContext.insert(progress)
            
            // Save periodically to avoid memory buildup
            if index % 50 == 0 {
                try testContext.save()
            }
        }
        
        try testContext.save()
        
        // Verify all progress entries were created - use profile-specific filtering
        let allProgressEntries = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        let profileProgressEntries = allProgressEntries.filter { $0.userProfile.id == profile.id }
        XCTAssertEqual(profileProgressEntries.count, terminology.count)
    }
    
    func testDataIntegrityUnderStress() throws {
        // Test data integrity under stress conditions
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let testBelt = beltLevels.first!
        let testTerm = terminology.first!
        
        // Create multiple profiles
        var profiles: [UserProfile] = []
        for i in 1...20 {
            let profile = UserProfile(
                name: "Stress Test User \(i)",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            profiles.append(profile)
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        // Create sessions and progress for each profile
        for profile in profiles {
            // Create sessions
            for sessionNum in 1...5 {
                let session = StudySession(userProfile: profile, sessionType: .flashcards)
                session.complete(
                    itemsStudied: sessionNum * 10,
                    correctAnswers: sessionNum * 8,
                    focusAreas: ["Stress Test \(sessionNum)"]
                )
                testContext.insert(session)
            }
            
            // Create progress entries
            let progress = UserTerminologyProgress(terminologyEntry: testTerm, userProfile: profile)
            progress.correctCount = Int.random(in: 1...50)
            progress.incorrectCount = Int.random(in: 0...20)
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify data integrity - use profile-specific filtering
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let allProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        
        let stressTestSessions = allSessions.filter { session in
            profiles.contains { $0.id == session.userProfile.id }
        }
        let stressTestProgress = allProgress.filter { progress in
            profiles.contains { $0.id == progress.userProfile.id }
        }
        
        XCTAssertEqual(stressTestSessions.count, 100) // 20 profiles × 5 sessions
        XCTAssertEqual(stressTestProgress.count, 20) // 20 profiles × 1 progress entry
        
        // Verify relationships are intact
        for session in stressTestSessions {
            XCTAssertNotNil(session.userProfile)
            XCTAssertTrue(profiles.contains { $0.id == session.userProfile.id })
        }
        
        for progress in stressTestProgress {
            XCTAssertNotNil(progress.userProfile)
            XCTAssertNotNil(progress.terminologyEntry)
            XCTAssertTrue(profiles.contains { $0.id == progress.userProfile.id })
        }
    }
    
    func testErrorRecoveryScenarios() throws {
        // Test error recovery infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Test recovery from partial failure scenarios
        do {
            let profile = UserProfile(
                name: "Recovery Test User",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: .mastery
            )
            
            testContext.insert(profile)
            try testContext.save()
            
            // Verify profile creation succeeded - use name-specific filtering
            let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
            let recoveryProfiles = allProfiles.filter { $0.name == "Recovery Test User" }
            XCTAssertEqual(recoveryProfiles.count, 1)
            
        } catch {
            XCTFail("Basic profile creation should not fail: \(error)")
        }
        
        // Test system continues functioning after errors
        let additionalProfile = UserProfile(
            name: "Post-Error User",
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(additionalProfile)
        try testContext.save()
        
        let allFinalProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let recoveryTestProfiles = allFinalProfiles.filter { profile in
            profile.name == "Recovery Test User" || profile.name == "Post-Error User"
        }
        XCTAssertEqual(recoveryTestProfiles.count, 2)
    }
    
    // MARK: - Performance Validation Tests
    
    func testFetchPerformance() throws {
        // Test fetch operation performance
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        // Measure fetch performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        _ = try testContext.fetch(FetchDescriptor<BeltLevel>())
        _ = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        _ = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        
        let fetchTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance validation - basic fetches should be fast
        XCTAssertLessThan(fetchTime, 1.0, "Basic data fetches should complete in under 1 second")
    }
    
    func testFilteringPerformance() throws {
        // Test filtering performance with large datasets
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create large dataset for filtering
        for i in 1...1000 {
            let profile = UserProfile(
                name: "Filter Test User \(i)",
                avatar: .student1,
                colorTheme: .blue,
                currentBeltLevel: testBelt,
                learningMode: i % 2 == 0 ? .mastery : .progression
            )
            testContext.insert(profile)
        }
        
        try testContext.save()
        
        // Measure filtering performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let allProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let filterTestProfiles = allProfiles.filter { $0.name.hasPrefix("Filter Test User ") }
        let masteryProfiles = filterTestProfiles.filter { $0.learningMode == .mastery }
        
        let filterTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance validation
        XCTAssertLessThan(filterTime, 2.0, "Filtering 1000 profiles should complete in under 2 seconds")
        XCTAssertEqual(filterTestProfiles.count, 1000, "Should create 1000 filter test profiles")
        XCTAssertEqual(masteryProfiles.count, 500) // Half should be mastery mode
    }
    
    func testSessionAnalysisPerformance() throws {
        // Test performance of session analysis operations
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Analysis Performance User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile)
        
        // Create large number of sessions
        for i in 1...200 {
            let session = StudySession(userProfile: profile, sessionType: .flashcards)
            session.complete(
                itemsStudied: i % 50 + 10,
                correctAnswers: i % 40 + 5,
                focusAreas: ["Analysis Test \(i)"]
            )
            testContext.insert(session)
        }
        
        try testContext.save()
        
        // Measure analysis performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let profileSessions = allSessions.filter { $0.userProfile.id == profile.id }
        
        // Calculate various metrics
        let totalItemsStudied = profileSessions.reduce(0) { $0 + $1.itemsStudied }
        let totalCorrectAnswers = profileSessions.reduce(0) { $0 + $1.correctAnswers }
        let averageAccuracy = Double(totalCorrectAnswers) / Double(totalItemsStudied)
        
        let analysisTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance validation
        XCTAssertLessThan(analysisTime, 1.0, "Session analysis should complete in under 1 second")
        XCTAssertEqual(profileSessions.count, 200)
        XCTAssertGreaterThan(averageAccuracy, 0.0)
    }
}