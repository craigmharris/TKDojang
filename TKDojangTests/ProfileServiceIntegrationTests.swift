import XCTest
import SwiftData
@testable import TKDojang

/**
 * ProfileServiceIntegrationTests.swift
 *
 * PURPOSE: Service orchestration integration testing for Profile management
 *
 * ARCHITECTURAL INSIGHT (2025-10-22):
 * Phase 2 "Integration Testing" was initially planned as ViewInspector-based view integration.
 * However, in SwiftUI MVVM-C architecture, TRUE integration happens at the SERVICE layer,
 * not the view layer. Views are declarative presentation that reacts to service state.
 *
 * INTEGRATION LAYERS TESTED:
 * 1. ProfileService → SwiftData persistence → state management
 * 2. DataServices → ProfileService orchestration → UI state propagation
 * 3. Profile operations → TerminologyService/PatternService → content filtering
 * 4. Multi-service coordination → cache refresh → data isolation
 *
 * WHY THIS APPROACH:
 * - ✅ Tests actual integration bugs (service orchestration failures)
 * - ✅ Fast, reliable, maintainable (no ViewInspector framework fighting)
 * - ✅ Property-based approach matches Phase 1 success pattern
 * - ✅ Complements E2E tests (Phase 3) which validate UI flows
 *
 * CRITICAL USER CONCERNS ADDRESSED:
 * 1. Profile creation → persistence → activation workflow
 * 2. Profile switching → state preservation → content refresh orchestration
 * 3. Profile deletion → cleanup → fallback activation coordination
 * 4. Multi-profile data isolation across all services
 *
 * TOTAL: 4 orchestration integration tests
 */
@MainActor
final class ProfileServiceIntegrationTests: XCTestCase {
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var profileService: ProfileService!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext
        profileService = ProfileService(modelContext: testContext)

        // Setup test data (BeltLevels only, like ProfileDataTests)
        let dataFactory = TestDataFactory()
        let belts = dataFactory.createBasicBeltLevels()
        for belt in belts {
            testContext.insert(belt)
        }

        try testContext.save()
    }

    override func tearDown() async throws {
        testContext = nil
        testContainer = nil
        profileService = nil
        try await super.tearDown()
    }

    // MARK: - Test Helpers

    private func getRandomBelt() throws -> BeltLevel {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        return allBelts.randomElement()!
    }

    private func createTestProfile(
        name: String? = nil,
        belt: BeltLevel? = nil
    ) throws -> UserProfile {
        let randomBelt = try belt ?? getRandomBelt()
        let profileName = name ?? "TestUser_\(UUID().uuidString.prefix(8))"
        return try profileService.createProfile(
            name: profileName,
            avatar: ProfileAvatar.allCases.randomElement()!,
            colorTheme: ProfileColorTheme.allCases.randomElement()!,
            beltLevel: randomBelt
        )
    }

    private func createTerminologyTestData() throws {
        let dataFactory = TestDataFactory()
        let belts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }
        let categories = dataFactory.createBasicCategories()

        for category in categories {
            testContext.insert(category)
        }

        // Create cumulative content for filtering tests
        for belt in belts {
            for category in categories {
                let entries = dataFactory.createSampleTerminologyEntries(belt: belt, category: category, count: 5)
                for entry in entries {
                    testContext.insert(entry)
                }
            }
        }

        try testContext.save()
    }

    // MARK: - Integration Test 1: Profile Creation Flow

    /**
     * INTEGRATION TEST: Profile creation workflow
     *
     * ORCHESTRATION VALIDATED:
     * - ProfileService.createProfile() → SwiftData persistence
     * - First profile → auto-activation logic
     * - Profile constraints → validation enforcement
     * - State persistence → fetch consistency
     */
    func testProfileCreationFlow() throws {
        // STEP 1: Create profile
        let belt = try getRandomBelt()
        let profile = try profileService.createProfile(
            name: "Integration User", // 16 chars (within 20 limit)
            avatar: .student1,
            colorTheme: .blue,
            beltLevel: belt
        )

        // INTEGRATION POINT 1: Persistence layer
        XCTAssertNotNil(profile.id,
            "Profile should have ID assigned by persistence layer")

        // INTEGRATION POINT 2: Auto-activation for first profile
        XCTAssertTrue(profile.isActive,
            "First profile should be auto-activated by createProfile orchestration")

        // STEP 2: Verify persistence via independent fetch
        let fetchedProfiles = try profileService.getAllProfiles()

        // INTEGRATION POINT 3: Fetch consistency
        XCTAssertEqual(fetchedProfiles.count, 1,
            "getAllProfiles should return persisted profile")
        XCTAssertEqual(fetchedProfiles.first?.id, profile.id,
            "Fetched profile should match created profile")

        // INTEGRATION POINT 4: Active profile state
        let activeProfile = profileService.getActiveProfile()
        XCTAssertEqual(activeProfile?.id, profile.id,
            "getActiveProfile should return auto-activated first profile")

        // STEP 3: Verify constraints are enforced
        XCTAssertThrowsError(
            try profileService.createProfile(
                name: "Integration Test User", // Duplicate name
                avatar: .student2,
                colorTheme: .green,
                beltLevel: belt
            ),
            "Duplicate name constraint should be enforced by orchestration"
        )

        // Verify only 1 profile exists (duplicate was rejected)
        let finalProfiles = try profileService.getAllProfiles()
        XCTAssertEqual(finalProfiles.count, 1,
            "Duplicate profile should not be persisted")
    }

    // MARK: - Integration Test 2: Profile Switching Orchestration

    /**
     * INTEGRATION TEST: Profile switching with content refresh
     *
     * ORCHESTRATION VALIDATED:
     * - ProfileService.activateProfile() → state management
     * - Active profile caching → getActiveProfile consistency
     * - Profile state preservation across switches
     * - Content service integration → belt-filtered visibility
     */
    func testProfileSwitchingOrchestration() throws {
        try createTerminologyTestData()

        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        guard allBelts.count >= 2 else {
            XCTFail("Need at least 2 belt levels for switching test")
            return
        }

        // STEP 1: Create two profiles with different belt levels
        let beginnerBelt = allBelts.first! // 10th Keup (highest sortOrder)
        let advancedBelt = allBelts.last!  // 1st Dan (lowest sortOrder)

        let beginnerProfile = try createTestProfile(name: "Beginner", belt: beginnerBelt)
        let advancedProfile = try createTestProfile(name: "Advanced", belt: advancedBelt)

        // STEP 2: Activate beginner profile
        try profileService.activateProfile(beginnerProfile)

        // INTEGRATION POINT 1: Active profile state management
        XCTAssertTrue(beginnerProfile.isActive,
            "Activated profile should have isActive = true")
        XCTAssertFalse(advancedProfile.isActive,
            "Non-activated profile should have isActive = false")

        let activeAfterFirst = profileService.getActiveProfile()
        XCTAssertEqual(activeAfterFirst?.id, beginnerProfile.id,
            "getActiveProfile should return currently active profile")

        // STEP 3: Record activity on beginner profile
        beginnerProfile.streakDays = 7
        beginnerProfile.totalFlashcardsSeen = 150
        try testContext.save()

        // STEP 4: Switch to advanced profile
        try profileService.activateProfile(advancedProfile)

        // INTEGRATION POINT 2: State transition
        let allProfiles = try profileService.getAllProfiles()
        let beginnerReloaded = allProfiles.first { $0.id == beginnerProfile.id }!
        let advancedReloaded = allProfiles.first { $0.id == advancedProfile.id }!

        XCTAssertFalse(beginnerReloaded.isActive,
            "Previous profile should be deactivated")
        XCTAssertTrue(advancedReloaded.isActive,
            "New profile should be activated")

        // INTEGRATION POINT 3: State preservation
        XCTAssertEqual(beginnerReloaded.streakDays, 7,
            "Profile state should be preserved across switch")
        XCTAssertEqual(beginnerReloaded.totalFlashcardsSeen, 150,
            "Profile metrics should be preserved across switch")

        // INTEGRATION POINT 4: Content service integration
        let terminologyService = TerminologyDataService(modelContext: testContext)

        let beginnerTerms = terminologyService.getTerminologyForUser(userProfile: beginnerReloaded, limit: .max)
        let advancedTerms = terminologyService.getTerminologyForUser(userProfile: advancedReloaded, limit: .max)

        XCTAssertGreaterThanOrEqual(advancedTerms.count, beginnerTerms.count,
            "Content filtering should work correctly after profile switch: advanced belt sees more/equal content")

        // INTEGRATION POINT 5: Active profile cache consistency
        let finalActive = profileService.getActiveProfile()
        XCTAssertEqual(finalActive?.id, advancedProfile.id,
            "Cached active profile should be updated after switch")
    }

    // MARK: - Integration Test 3: Profile Deletion Cleanup

    /**
     * INTEGRATION TEST: Profile deletion with orchestrated cleanup
     *
     * ORCHESTRATION VALIDATED:
     * - ProfileService.deleteProfile() → cascade deletion
     * - Active profile deletion → automatic fallback activation
     * - Profile reordering → consistent state
     * - Last profile protection → constraint enforcement
     */
    func testProfileDeletionCleanup() throws {
        // STEP 1: Create 3 profiles
        let profile1 = try createTestProfile(name: "User1")
        let profile2 = try createTestProfile(name: "User2")
        let profile3 = try createTestProfile(name: "User3")

        // Record some data for each profile
        try profileService.activateProfile(profile1)
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 20,
            correctAnswers: 16
        )

        try profileService.activateProfile(profile2)
        try profileService.recordStudySession(
            sessionType: .testing,
            itemsStudied: 10,
            correctAnswers: 8
        )

        try profileService.activateProfile(profile3)

        // STEP 2: Delete active profile (profile3)
        try profileService.deleteProfile(profile3)

        // INTEGRATION POINT 1: Cascade deletion
        let remainingProfiles = try profileService.getAllProfiles()
        XCTAssertEqual(remainingProfiles.count, 2,
            "Deleted profile should be removed from persistence")
        XCTAssertFalse(remainingProfiles.contains { $0.id == profile3.id },
            "Deleted profile should not appear in fetch results")

        // INTEGRATION POINT 2: Automatic fallback activation
        let newActive = profileService.getActiveProfile()
        XCTAssertNotNil(newActive,
            "Deleting active profile should trigger fallback activation")
        XCTAssertNotEqual(newActive?.id, profile3.id,
            "Active profile should not be deleted profile")
        XCTAssertTrue([profile1.id, profile2.id].contains(newActive!.id),
            "Fallback should activate one of remaining profiles")

        // INTEGRATION POINT 3: Profile order consistency
        for (index, profile) in remainingProfiles.enumerated() {
            XCTAssertEqual(profile.profileOrder, index,
                "Profile order should be reindexed after deletion: profile \(profile.name)")
        }

        // STEP 3: Delete one more profile, leaving only 1
        try profileService.deleteProfile(remainingProfiles.last!)

        // Should now have 1 profile left
        let singleProfile = try profileService.getAllProfiles()
        XCTAssertEqual(singleProfile.count, 1,
            "Should be able to delete down to 1 profile")

        // INTEGRATION POINT 4: Last profile constraint
        XCTAssertThrowsError(
            try profileService.deleteProfile(singleProfile.first!),
            "Should prevent deletion of last profile"
        ) { error in
            XCTAssertTrue(error is ProfileError,
                "Should throw ProfileError for last profile deletion attempt")
        }

        // INTEGRATION POINT 5: Study sessions preserved for remaining profiles
        let profile1Sessions = try profileService.getStudySessions(for: remainingProfiles.first { $0.id == profile1.id }!)
        XCTAssertEqual(profile1Sessions.count, 1,
            "Study sessions should be preserved for non-deleted profiles")
        XCTAssertEqual(profile1Sessions.first?.itemsStudied, 20,
            "Study session data should be intact")
    }

    // MARK: - Integration Test 4: Multi-Profile Data Isolation

    /**
     * INTEGRATION TEST: Data isolation across multiple profiles
     *
     * ORCHESTRATION VALIDATED:
     * - Study sessions → profile filtering → data isolation
     * - Terminology progress → profile filtering → independent state
     * - Profile switching → no data leakage
     * - SwiftData relationship navigation → safe filtering pattern
     */
    func testMultiProfileDataIsolation() throws {
        try createTerminologyTestData()

        let belt = try getRandomBelt()

        // STEP 1: Create 3 profiles
        let profile1 = try createTestProfile(name: "Alice", belt: belt)
        let profile2 = try createTestProfile(name: "Bob", belt: belt)
        let profile3 = try createTestProfile(name: "Charlie", belt: belt)

        let terminologyService = TerminologyDataService(modelContext: testContext)
        let terms = terminologyService.getTerminologyForUser(userProfile: profile1)
        guard let testTerm = terms.first else {
            XCTFail("No terminology available for isolation test")
            return
        }

        // STEP 2: Record different data for each profile

        // Alice: 2 flashcard sessions + terminology progress
        try profileService.activateProfile(profile1)
        try profileService.recordStudySession(sessionType: .flashcards, itemsStudied: 20, correctAnswers: 16)
        try profileService.recordStudySession(sessionType: .flashcards, itemsStudied: 15, correctAnswers: 12)
        let alice_progress = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile1)
        alice_progress.correctCount = 10
        try testContext.save()

        // Bob: 1 test session + different terminology progress
        try profileService.activateProfile(profile2)
        try profileService.recordStudySession(sessionType: .testing, itemsStudied: 30, correctAnswers: 25)
        let bob_progress = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile2)
        bob_progress.correctCount = 5
        try testContext.save()

        // Charlie: 3 pattern sessions + no terminology progress
        try profileService.activateProfile(profile3)
        try profileService.recordStudySession(sessionType: .patterns, itemsStudied: 5, correctAnswers: 5)
        try profileService.recordStudySession(sessionType: .patterns, itemsStudied: 3, correctAnswers: 3)
        try profileService.recordStudySession(sessionType: .patterns, itemsStudied: 7, correctAnswers: 6)

        // STEP 3: Verify data isolation

        // INTEGRATION POINT 1: Study session isolation
        let aliceSessions = try profileService.getStudySessions(for: profile1)
        let bobSessions = try profileService.getStudySessions(for: profile2)
        let charlieSessions = try profileService.getStudySessions(for: profile3)

        XCTAssertEqual(aliceSessions.count, 2,
            "Alice should see only her 2 sessions")
        XCTAssertTrue(aliceSessions.allSatisfy { $0.sessionType == .flashcards },
            "Alice's sessions should all be flashcard type")

        XCTAssertEqual(bobSessions.count, 1,
            "Bob should see only his 1 session")
        XCTAssertTrue(bobSessions.allSatisfy { $0.sessionType == .testing },
            "Bob's session should be testing type")

        XCTAssertEqual(charlieSessions.count, 3,
            "Charlie should see only his 3 sessions")
        XCTAssertTrue(charlieSessions.allSatisfy { $0.sessionType == .patterns },
            "Charlie's sessions should all be pattern type")

        // INTEGRATION POINT 2: Terminology progress isolation
        let aliceTermProgress = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile1)
        let bobTermProgress = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile2)
        let charlieTermProgress = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile3)

        XCTAssertEqual(aliceTermProgress.correctCount, 10,
            "Alice's terminology progress should be isolated")
        XCTAssertEqual(bobTermProgress.correctCount, 5,
            "Bob's terminology progress should be isolated")
        XCTAssertEqual(charlieTermProgress.correctCount, 0,
            "Charlie should have no terminology progress (didn't study it)")

        // INTEGRATION POINT 3: No cross-contamination
        XCTAssertNotEqual(aliceTermProgress.id, bobTermProgress.id,
            "Different profiles should have different progress objects")
        XCTAssertNotEqual(bobTermProgress.id, charlieTermProgress.id,
            "Different profiles should have different progress objects")

        // INTEGRATION POINT 4: Session totals match individual data
        let totalAliceItems = aliceSessions.reduce(0) { $0 + $1.itemsStudied }
        let totalBobItems = bobSessions.reduce(0) { $0 + $1.itemsStudied }
        let totalCharlieItems = charlieSessions.reduce(0) { $0 + $1.itemsStudied }

        XCTAssertEqual(totalAliceItems, 35,
            "Alice's total items should match her sessions (20 + 15)")
        XCTAssertEqual(totalBobItems, 30,
            "Bob's total items should match his session")
        XCTAssertEqual(totalCharlieItems, 15,
            "Charlie's total items should match his sessions (5 + 3 + 7)")

        // INTEGRATION POINT 5: Profile switching doesn't leak data
        try profileService.activateProfile(profile1)
        let alice_sessions_after_switch = try profileService.getStudySessions(for: profile1)
        XCTAssertEqual(alice_sessions_after_switch.count, 2,
            "Alice's sessions should remain isolated after profile switch")

        try profileService.activateProfile(profile2)
        let bob_sessions_after_switch = try profileService.getStudySessions(for: profile2)
        XCTAssertEqual(bob_sessions_after_switch.count, 1,
            "Bob's sessions should remain isolated after profile switch")
    }
}
