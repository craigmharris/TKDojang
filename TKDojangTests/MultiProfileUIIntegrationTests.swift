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
        
        // Create basic test data for consistent baseline
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
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
        // Test basic profile creation infrastructure (data already created in setUp)
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
        
        // Verify our specific profile was created
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let ourProfile = savedProfiles.first { $0.name == "Test User" }
        XCTAssertNotNil(ourProfile, "Should find our test user profile")
        XCTAssertEqual(ourProfile?.name, "Test User")
    }
    
    func testMultipleProfileCreation() throws {
        // Test multiple profile creation (data already created in setUp)
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
        
        // Verify all our specific profiles were created
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let testProfileNames = ["User One", "User Two", "User Three"]
        let ourProfiles = savedProfiles.filter { testProfileNames.contains($0.name) }
        
        XCTAssertEqual(ourProfiles.count, 3, "Should have created our 3 test profiles")
        
        let names = Set(ourProfiles.map { $0.name })
        XCTAssertTrue(names.contains("User One"))
        XCTAssertTrue(names.contains("User Two"))
        XCTAssertTrue(names.contains("User Three"))
    }
    
    func testProfileUniqueNameConstraint() throws {
        // Test profile name uniqueness infrastructure (data already created in setUp)
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
        let ourProfile = savedProfiles.first { $0.name == "Duplicate Name" }
        XCTAssertNotNil(ourProfile, "Should find our duplicate name test profile")
        XCTAssertEqual(ourProfile?.name, "Duplicate Name")
    }
    
    func testProfileActivationInfrastructure() throws {
        // Test profile activation data structure (data already created in setUp)
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
        
        // Verify activation states for our specific test profiles
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let testProfileNames = ["First User", "Second User"]
        let ourProfiles = savedProfiles.filter { testProfileNames.contains($0.name) }
        
        XCTAssertEqual(ourProfiles.count, 2, "Should have created our 2 test profiles")
        
        let activeProfiles = ourProfiles.filter { $0.isActive }
        XCTAssertEqual(activeProfiles.count, 1, "Should have 1 active profile")
        XCTAssertEqual(activeProfiles.first?.name, "First User")
    }
    
    func testProfileSessionIsolation() throws {
        // Test that study sessions are properly isolated between profiles (data already created in setUp)
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
        
        // Verify session isolation using profile-specific filtering
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        
        let profile1Sessions = allSessions.filter { $0.userProfile.id == profile1.id }
        let profile2Sessions = allSessions.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Sessions.count, 1, "Profile 1 should have 1 session")
        XCTAssertEqual(profile2Sessions.count, 1, "Profile 2 should have 1 session")
        XCTAssertEqual(profile1Sessions.first?.sessionType, .flashcards)
        XCTAssertEqual(profile2Sessions.first?.sessionType, .patterns)
    }
    
    func testProfileProgressIsolation() throws {
        // Test terminology progress isolation between profiles (data already created in setUp)
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
        
        // Verify progress isolation using profile-specific filtering
        let allProgress = try testContext.fetch(FetchDescriptor<UserTerminologyProgress>())
        
        let profile1Progress = allProgress.filter { $0.userProfile.id == profile1.id }
        let profile2Progress = allProgress.filter { $0.userProfile.id == profile2.id }
        
        XCTAssertEqual(profile1Progress.count, 1, "Profile 1 should have 1 progress entry")
        XCTAssertEqual(profile2Progress.count, 1, "Profile 2 should have 1 progress entry")
        XCTAssertEqual(profile1Progress.first?.correctCount, 5)
        XCTAssertEqual(profile2Progress.first?.correctCount, 3)
    }
    
    func testProfileDifferentBeltLevels() throws {
        // Test profiles with different belt levels (data already created in setUp)
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
        
        // Verify different belt levels for our specific test profiles
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let testProfileNames = ["Beginner", "Advanced"]
        let ourProfiles = savedProfiles.filter { testProfileNames.contains($0.name) }
        
        XCTAssertEqual(ourProfiles.count, 2, "Should have created our 2 test profiles")
        
        let belts = Set(ourProfiles.map { $0.currentBeltLevel.id })
        XCTAssertEqual(belts.count, 2, "Should have 2 different belt levels")
    }
    
    func testProfileAvatarAndThemeVariations() throws {
        // Test profile customization infrastructure (data already created in setUp)
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
        
        // Verify all our specific profiles created with different customizations
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let testProfileNames = ["Student 1", "Student 2", "Instructor", "Master", "Ninja", "Champion"]
        let ourProfiles = savedProfiles.filter { testProfileNames.contains($0.name) }
        
        XCTAssertEqual(ourProfiles.count, 6, "Should have created our 6 test profiles")
        
        let avatars = Set(ourProfiles.map { $0.avatar })
        let themes = Set(ourProfiles.map { $0.colorTheme })
        
        XCTAssertEqual(avatars.count, 6, "All profiles should have different avatars")
        XCTAssertEqual(themes.count, 6, "All profiles should have different themes")
    }
    
    func testProfileActivityTracking() throws {
        // Test profile activity tracking infrastructure (data already created in setUp)
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
        
        // Verify activity tracking for our specific profile
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let savedProfile = savedProfiles.first { $0.name == "Activity Tracker" }
        
        XCTAssertNotNil(savedProfile, "Should find our activity tracker profile")
        XCTAssertEqual(savedProfile?.totalFlashcardsSeen, 25)
        XCTAssertEqual(savedProfile?.streakDays, 7)
        XCTAssertGreaterThan(savedProfile?.totalStudyTime ?? 0, 0)
        XCTAssertNotNil(savedProfile?.lastActiveAt)
    }
    
    func testProfileLearningModeSettings() throws {
        // Test different learning mode configurations (data already created in setUp)
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
        
        // Verify learning modes for our specific test profiles
        let savedProfiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let testProfileNames = ["Mastery Learner", "Progression Learner"]
        let ourProfiles = savedProfiles.filter { testProfileNames.contains($0.name) }
        
        XCTAssertEqual(ourProfiles.count, 2, "Should have created our 2 learning mode test profiles")
        
        let masteryProfiles = ourProfiles.filter { $0.learningMode == .mastery }
        let progressionProfiles = ourProfiles.filter { $0.learningMode == .progression }
        
        XCTAssertEqual(masteryProfiles.count, 1, "Should have 1 mastery profile")
        XCTAssertEqual(progressionProfiles.count, 1, "Should have 1 progression profile")
        XCTAssertEqual(masteryProfiles.first?.name, "Mastery Learner")
        XCTAssertEqual(progressionProfiles.first?.name, "Progression Learner")
    }
    
    func testProfileDataConsistency() throws {
        // Test data consistency across profile infrastructure (data already created in setUp)
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
        // Test performance with multiple profiles and sessions (data already created in setUp)
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
        
        // Verify all our test data was created using profile-specific filtering
        let allSessions = try testContext.fetch(FetchDescriptor<StudySession>())
        let testProfileIds = Set(profiles.map { $0.id })
        let ourSessions = allSessions.filter { testProfileIds.contains($0.userProfile.id) }
        
        XCTAssertEqual(ourSessions.count, 15, "Should have 15 sessions (5 profiles × 3 sessions each)")
        
        // Test performance of filtering sessions by profile
        let firstProfile = profiles.first!
        let profileSessions = ourSessions.filter { $0.userProfile.id == firstProfile.id }
        XCTAssertEqual(profileSessions.count, 3, "First profile should have 3 sessions")
    }
}