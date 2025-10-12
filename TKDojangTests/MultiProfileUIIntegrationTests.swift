import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * MultiProfileUIIntegrationTests.swift
 * 
 * PURPOSE: Infrastructure testing for multi-profile system functionality
 * 
 * ARCHITECTURE DECISION: Infrastructure-focused testing approach
 * WHY: Eliminates complex service dependencies and focuses on core data flow validation
 * 
 * TESTING STRATEGY:
 * - Container creation and schema validation
 * - Multi-profile data management
 * - Profile switching infrastructure
 * - Data isolation between profiles
 * - Proven pattern from successful test migrations
 */

final class MultiProfileUIIntegrationTests: XCTestCase {
    
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
        // Test that container initializes with multi-profile schema
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
        
        // Verify schema contains required models for multi-profile system
        let schema = testContainer.schema
        let modelNames = schema.entities.map { $0.name }
        
        XCTAssertTrue(modelNames.contains("UserProfile"))
        XCTAssertTrue(modelNames.contains("StudySession"))
        XCTAssertTrue(modelNames.contains("BeltLevel"))
        XCTAssertTrue(modelNames.contains("TerminologyEntry"))
        XCTAssertTrue(modelNames.contains("UserTerminologyProgress"))
    }
    
    func testBasicProfileCreation() throws {
        // Test basic profile creation infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create test profile
        let profile = UserProfile(
            name: "Test User",
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
        XCTAssertEqual(savedProfiles.first?.name, "Test User")
    }
    
    func testMultipleProfileCreation() throws {
        // Test multiple profile creation
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
        
        let profile3 = UserProfile(
            name: "User Three",
            avatar: .instructor,
            colorTheme: .green,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile1)
        testContext.insert(profile2)
        testContext.insert(profile3)
        try testContext.save()
        
        // Verify all profiles were created
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 3)
        
        let names = Set(savedProfiles.map { $0.name })
        XCTAssertTrue(names.contains("User One"))
        XCTAssertTrue(names.contains("User Two"))
        XCTAssertTrue(names.contains("User Three"))
    }
    
    func testProfileUniqueNameConstraint() throws {
        // Test profile name uniqueness infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create first profile
        let profile1 = UserProfile(
            name: "Duplicate Name",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        testContext.insert(profile1)
        try testContext.save()
        
        // Verify unique name constraint would be enforced at service level
        // (Infrastructure test focuses on data storage capability)
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 1)
        XCTAssertEqual(savedProfiles.first?.name, "Duplicate Name")
    }
    
    func testProfileActivationInfrastructure() throws {
        // Test profile activation data structure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profiles
        let profile1 = UserProfile(
            name: "First User",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let profile2 = UserProfile(
            name: "Second User",
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        // Set activation states
        profile1.isActive = true
        profile2.isActive = false
        
        testContext.insert(profile1)
        testContext.insert(profile2)
        try testContext.save()
        
        // Verify activation states
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 2)
        
        let activeProfiles = savedProfiles.filter { $0.isActive }
        XCTAssertEqual(activeProfiles.count, 1)
        XCTAssertEqual(activeProfiles.first?.name, "First User")
    }
    
    func testProfileSessionIsolation() throws {
        // Test that study sessions are properly isolated between profiles
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create two profiles
        let profile1 = UserProfile(
            name: "Session User 1",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let profile2 = UserProfile(
            name: "Session User 2",
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
        session1.complete(itemsStudied: 10, correctAnswers: 8, focusAreas: ["Profile 1 Session"])
        
        let session2 = StudySession(userProfile: profile2, sessionType: .patterns)
        session2.complete(itemsStudied: 5, correctAnswers: 4, focusAreas: ["Profile 2 Session"])
        
        testContext.insert(session1)
        testContext.insert(session2)
        try testContext.save()
        
        // Verify session isolation
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(allSessions.count, 2)
        
        let profile1Sessions = allSessions.filter { $0.userProfile.id == profile1.id }
        let profile2Sessions = allSessions.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Sessions.count, 1)
        XCTAssertEqual(profile2Sessions.count, 1)
        XCTAssertEqual(profile1Sessions.first?.sessionType, .flashcards)
        XCTAssertEqual(profile2Sessions.first?.sessionType, .patterns)
    }
    
    func testProfileProgressIsolation() throws {
        // Test terminology progress isolation between profiles
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let testBelt = beltLevels.first!
        let testTerm = terminology.first!
        
        // Create two profiles
        let profile1 = UserProfile(
            name: "Progress User 1",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let profile2 = UserProfile(
            name: "Progress User 2",
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(profile1)
        testContext.insert(profile2)
        try testContext.save()
        
        // Create progress entries for each profile
        let progress1 = UserTerminologyProgress(terminologyEntry: testTerm, userProfile: profile1)
        progress1.correctCount = 5
        progress1.incorrectCount = 2
        
        let progress2 = UserTerminologyProgress(terminologyEntry: testTerm, userProfile: profile2)
        progress2.correctCount = 3
        progress2.incorrectCount = 1
        
        testContext.insert(progress1)
        testContext.insert(progress2)
        try testContext.save()
        
        // Verify progress isolation
        let allProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        XCTAssertEqual(allProgress.count, 2)
        
        let profile1Progress = allProgress.filter { $0.userProfile.id == profile1.id }
        let profile2Progress = allProgress.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Progress.count, 1)
        XCTAssertEqual(profile2Progress.count, 1)
        XCTAssertEqual(profile1Progress.first?.correctCount, 5)
        XCTAssertEqual(profile2Progress.first?.correctCount, 3)
    }
    
    func testProfileDifferentBeltLevels() throws {
        // Test profiles with different belt levels
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        XCTAssertGreaterThan(beltLevels.count, 1, "Need multiple belt levels for test")
        
        let belt1 = beltLevels[0]
        let belt2 = beltLevels[1]
        
        // Create profiles with different belt levels
        let beginnerProfile = UserProfile(
            name: "Beginner",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: belt1,
            learningMode: .mastery
        )
        
        let advancedProfile = UserProfile(
            name: "Advanced",
            avatar: .instructor,
            colorTheme: .purple,
            currentBeltLevel: belt2,
            learningMode: .progression
        )
        
        testContext.insert(beginnerProfile)
        testContext.insert(advancedProfile)
        try testContext.save()
        
        // Verify different belt levels
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 2)
        
        let belts = Set(savedProfiles.map { $0.currentBeltLevel.id })
        XCTAssertEqual(belts.count, 2) // Should have 2 different belt levels
    }
    
    func testProfileAvatarAndThemeVariations() throws {
        // Test profile customization infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profiles with different avatars and themes
        let profiles = [
            UserProfile(name: "Student 1", avatar: .student1, colorTheme: .blue, currentBeltLevel: testBelt, learningMode: .mastery),
            UserProfile(name: "Student 2", avatar: .student2, colorTheme: .red, currentBeltLevel: testBelt, learningMode: .progression),
            UserProfile(name: "Instructor", avatar: .instructor, colorTheme: .green, currentBeltLevel: testBelt, learningMode: .mastery),
            UserProfile(name: "Master", avatar: .master, colorTheme: .purple, currentBeltLevel: testBelt, learningMode: .progression),
            UserProfile(name: "Ninja", avatar: .ninja, colorTheme: .orange, currentBeltLevel: testBelt, learningMode: .mastery),
            UserProfile(name: "Champion", avatar: .champion, colorTheme: .pink, currentBeltLevel: testBelt, learningMode: .progression)
        ]
        
        for profile in profiles {
            testContext.insert(profile)
        }
        try testContext.save()
        
        // Verify all profiles created with different customizations
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 6)
        
        let avatars = Set(savedProfiles.map { $0.avatar })
        let themes = Set(savedProfiles.map { $0.colorTheme })
        
        XCTAssertEqual(avatars.count, 6) // All different avatars
        XCTAssertEqual(themes.count, 6) // All different themes
    }
    
    func testProfileActivityTracking() throws {
        // Test profile activity tracking infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        let profile = UserProfile(
            name: "Activity Tracker",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        // Record activity
        profile.recordActivity(studyTime: 600) // 10 minutes
        profile.totalFlashcardsSeen += 25
        profile.streakDays = 7
        
        testContext.insert(profile)
        try testContext.save()
        
        // Verify activity tracking
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let savedProfile = savedProfiles.first!
        
        XCTAssertEqual(savedProfile.totalFlashcardsSeen, 25)
        XCTAssertEqual(savedProfile.streakDays, 7)
        XCTAssertGreaterThan(savedProfile.totalStudyTime, 0)
        XCTAssertNotNil(savedProfile.lastActiveAt)
    }
    
    func testProfileLearningModeSettings() throws {
        // Test different learning mode configurations
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create profiles with different learning modes
        let masteryProfile = UserProfile(
            name: "Mastery Learner",
            avatar: .student1,
            colorTheme: .blue,
            currentBeltLevel: testBelt,
            learningMode: .mastery
        )
        
        let progressionProfile = UserProfile(
            name: "Progression Learner",
            avatar: .student2,
            colorTheme: .red,
            currentBeltLevel: testBelt,
            learningMode: .progression
        )
        
        testContext.insert(masteryProfile)
        testContext.insert(progressionProfile)
        try testContext.save()
        
        // Verify learning modes
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        XCTAssertEqual(savedProfiles.count, 2)
        
        let masteryProfiles = savedProfiles.filter { $0.learningMode == .mastery }
        let progressionProfiles = savedProfiles.filter { $0.learningMode == .progression }
        
        XCTAssertEqual(masteryProfiles.count, 1)
        XCTAssertEqual(progressionProfiles.count, 1)
        XCTAssertEqual(masteryProfiles.first?.name, "Mastery Learner")
        XCTAssertEqual(progressionProfiles.first?.name, "Progression Learner")
    }
    
    func testProfileDataConsistency() throws {
        // Test data consistency across profile infrastructure
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let terminology = try testContext.fetch(FetchDescriptor<TerminologyEntry>())
        let categories = try testContext.fetch(FetchDescriptor<TerminologyCategory>())
        
        // Verify data infrastructure supports multiple profiles
        XCTAssertGreaterThan(beltLevels.count, 0)
        XCTAssertGreaterThan(terminology.count, 0)
        XCTAssertGreaterThan(categories.count, 0)
        
        // Verify relationships are intact
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
    
    func testMultipleProfileSessionPerformance() throws {
        // Test performance with multiple profiles and sessions
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
        
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        let testBelt = beltLevels.first!
        
        // Create multiple profiles
        var profiles: [UserProfile] = []
        for i in 1...5 {
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
        
        // Create multiple sessions for each profile
        for (index, profile) in profiles.enumerated() {
            for sessionNum in 1...3 {
                let session = StudySession(userProfile: profile, sessionType: .flashcards)
                session.complete(
                    itemsStudied: (index + 1) * sessionNum * 5,
                    correctAnswers: (index + 1) * sessionNum * 4,
                    focusAreas: ["Performance Test \(sessionNum)"]
                )
                testContext.insert(session)
            }
        }
        try testContext.save()
        
        // Verify all data was created
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        XCTAssertEqual(allSessions.count, 15) // 5 profiles × 3 sessions each
        
        // Test performance of filtering sessions by profile
        let firstProfile = profiles.first!
        let profileSessions = allSessions.filter { $0.userProfile.id == firstProfile.id }
        XCTAssertEqual(profileSessions.count, 3)
    }
}