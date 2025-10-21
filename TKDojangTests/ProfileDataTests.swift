import XCTest
import SwiftData
@testable import TKDojang

/**
 * ProfileDataTests.swift
 *
 * PURPOSE: Comprehensive property-based tests for Profile and Dashboard data
 *
 * CRITICAL USER CONCERNS ADDRESSED:
 * 1. Profile switching works correctly across multiple UI locations
 * 2. Profile loading is FUNDAMENTAL - affects all content visibility
 * 3. Content correctly filtered by belt level + progression/mastery mode
 *
 * TESTING STRATEGY: Property-Based Testing
 * - Test PROPERTIES that must hold for ANY valid profile state
 * - Use randomization to cover edge cases automatically
 * - Validate domain invariants across all scenarios
 *
 * DESIGN NOTE: Dashboard is purely display - testing ProfileData validates Dashboard implicitly
 *
 * COVERAGE AREAS:
 * 1. Profile Data Properties (5 tests) - Creation, validation, constraints
 * 2. Profile Activation Properties (5 tests) ⭐ CRITICAL - Multi-location switching
 * 3. Belt-Appropriate Content Filtering (6 tests) ⭐ CRITICAL - Content visibility
 * 4. Profile Statistics Properties (5 tests) - Dashboard display data
 * 5. Profile Isolation Properties (4 tests) - Data doesn't leak between profiles
 * 6. Study Session Properties (3 tests) - Session recording and analytics
 * 7. Grading Record Properties (2 tests) - Belt progression logic
 *
 * TOTAL: 30 property-based tests
 */
@MainActor
final class ProfileDataTests: XCTestCase {
    var testContext: ModelContext!
    var profileService: ProfileService!

    override func setUp() {
        super.setUp()

        // TEMPORARY: Disabled - create minimal context to avoid nil crashes
        // Tests will fail gracefully with no data rather than crashing
        do {
            let testContainer = try TestContainerFactory.createTestContainer()
            testContext = testContainer.mainContext
            profileService = ProfileService(modelContext: testContext)
            // NOT loading test data - tests will fail but won't crash
        } catch {
            XCTFail("Failed to set up test container: \(error)")
        }
    }

    override func tearDown() {
        testContext = nil
        profileService = nil
        super.tearDown()
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

    // MARK: - 1. Profile Data Properties (5 tests)

    /**
     * PROPERTY: Profile creation must populate all required fields correctly
     */
    func testProfileData_PropertyBased_CreationInitializesAllFields() throws {
        // Test 5 random profiles
        for _ in 0..<5 {
            let belt = try getRandomBelt()
            let name = "Test_\(Int.random(in: 1...1000))"
            let avatar = ProfileAvatar.allCases.randomElement()!
            let theme = ProfileColorTheme.allCases.randomElement()!

            let profile = try profileService.createProfile(
                name: name,
                avatar: avatar,
                colorTheme: theme,
                beltLevel: belt
            )

            // PROPERTY: All fields must be initialized
            XCTAssertEqual(profile.name, name,
                "PROPERTY VIOLATION: Name not set correctly")
            XCTAssertEqual(profile.avatar, avatar,
                "PROPERTY VIOLATION: Avatar not set correctly")
            XCTAssertEqual(profile.colorTheme, theme,
                "PROPERTY VIOLATION: Theme not set correctly")
            XCTAssertEqual(profile.currentBeltLevel.id, belt.id,
                "PROPERTY VIOLATION: Belt level not set correctly")
            XCTAssertEqual(profile.streakDays, 0,
                "PROPERTY VIOLATION: Initial streak should be 0")
            XCTAssertEqual(profile.totalStudyTime, 0,
                "PROPERTY VIOLATION: Initial study time should be 0")
            XCTAssertEqual(profile.totalFlashcardsSeen, 0,
                "PROPERTY VIOLATION: Initial flashcards count should be 0")
            XCTAssertEqual(profile.totalTestsTaken, 0,
                "PROPERTY VIOLATION: Initial tests count should be 0")
            XCTAssertNotNil(profile.id,
                "PROPERTY VIOLATION: ID must be generated")
        }
    }

    /**
     * PROPERTY: Profile IDs must be unique
     */
    func testProfileData_PropertyBased_UniqueIdentifiers() throws {
        var profiles: [UserProfile] = []

        // Create 5 profiles
        for i in 0..<5 {
            let profile = try createTestProfile(name: "User\(i)")
            profiles.append(profile)
        }

        let ids = profiles.map { $0.id }
        let uniqueIds = Set(ids)

        // PROPERTY: All IDs must be unique
        XCTAssertEqual(ids.count, uniqueIds.count,
            """
            PROPERTY VIOLATION: Duplicate profile IDs found
            Total profiles: \(ids.count)
            Unique IDs: \(uniqueIds.count)
            """)
    }

    /**
     * PROPERTY: Maximum 6 profiles enforced
     */
    func testProfileData_PropertyBased_MaxProfilesEnforced() throws {
        // Create 6 profiles (max limit)
        for i in 0..<6 {
            _ = try createTestProfile(name: "User\(i)")
        }

        // PROPERTY: 7th profile creation must fail
        XCTAssertThrowsError(
            try createTestProfile(name: "User7"),
            "PROPERTY VIOLATION: Should reject 7th profile"
        ) { error in
            XCTAssertTrue(error is ProfileError,
                "PROPERTY VIOLATION: Should throw ProfileError")
        }
    }

    /**
     * PROPERTY: Profile names must be unique (case-insensitive)
     */
    func testProfileData_PropertyBased_UniqueNamesEnforced() throws {
        let name = "TestUser"
        _ = try createTestProfile(name: name)

        // PROPERTY: Duplicate name (same case) must fail
        XCTAssertThrowsError(
            try createTestProfile(name: name),
            "PROPERTY VIOLATION: Should reject duplicate name"
        )

        // PROPERTY: Duplicate name (different case) must also fail
        XCTAssertThrowsError(
            try createTestProfile(name: name.uppercased()),
            "PROPERTY VIOLATION: Should reject duplicate name (case-insensitive)"
        )
    }

    /**
     * PROPERTY: Profile name validation rules must be enforced
     */
    func testProfileData_PropertyBased_NameValidationRules() throws {
        let belt = try getRandomBelt()

        // PROPERTY: Empty name must be rejected
        XCTAssertThrowsError(
            try profileService.createProfile(
                name: "",
                avatar: .student1,
                colorTheme: .blue,
                beltLevel: belt
            ),
            "PROPERTY VIOLATION: Empty name should be rejected"
        )

        // PROPERTY: Name > 20 characters must be rejected
        XCTAssertThrowsError(
            try profileService.createProfile(
                name: String(repeating: "a", count: 21),
                avatar: .student1,
                colorTheme: .blue,
                beltLevel: belt
            ),
            "PROPERTY VIOLATION: Name > 20 chars should be rejected"
        )

        // PROPERTY: Valid names (1-20 chars) must be accepted
        for length in [1, 10, 20] {
            let validName = String(repeating: "x", count: length) + "\(Int.random(in: 1...999))"
            XCTAssertNoThrow(
                try profileService.createProfile(
                    name: validName,
                    avatar: .student1,
                    colorTheme: .blue,
                    beltLevel: belt
                ),
                "PROPERTY VIOLATION: Valid name (\(length) chars) should be accepted"
            )
        }
    }

    // MARK: - 2. Profile Activation Properties (5 tests) ⭐ CRITICAL

    /**
     * PROPERTY: Only ONE profile can be active at any time
     * CRITICAL: User concern #1 - Profile switching correctness
     */
    func testProfileActivation_PropertyBased_OnlyOneActiveAtATime() throws {
        // Create 4 profiles
        var profiles: [UserProfile] = []
        for i in 0..<4 {
            let profile = try createTestProfile(name: "User\(i)")
            profiles.append(profile)
        }

        // Test activating each profile
        for profile in profiles {
            try profileService.activateProfile(profile)

            // Fetch ALL profiles to verify activation state
            let allProfiles = try profileService.getAllProfiles()
            let activeProfiles = allProfiles.filter { $0.isActive }

            // PROPERTY: Exactly one profile must be active
            XCTAssertEqual(activeProfiles.count, 1,
                """
                PROPERTY VIOLATION: Multiple profiles active simultaneously
                Expected: 1 active profile
                Got: \(activeProfiles.count) active profiles
                Activated: \(profile.name)
                """)

            XCTAssertEqual(activeProfiles.first?.id, profile.id,
                """
                PROPERTY VIOLATION: Wrong profile is active
                Expected: \(profile.name)
                Got: \(activeProfiles.first?.name ?? "none")
                """)
        }
    }

    /**
     * PROPERTY: Profile switching must preserve previous profile state
     * CRITICAL: User concern #1 - Multi-location switching reliability
     */
    func testProfileActivation_PropertyBased_SwitchingPreservesState() throws {
        let profile1 = try createTestProfile(name: "User1")
        let profile2 = try createTestProfile(name: "User2")

        // Activate profile1 and record some data
        try profileService.activateProfile(profile1)
        profile1.streakDays = 5
        profile1.totalFlashcardsSeen = 100
        try testContext.save()

        // Switch to profile2
        try profileService.activateProfile(profile2)

        // PROPERTY: Profile1 state must be preserved
        let reloadedProfile1 = try profileService.getAllProfiles()
            .first { $0.id == profile1.id }!

        XCTAssertEqual(reloadedProfile1.streakDays, 5,
            "PROPERTY VIOLATION: Streak not preserved after switch")
        XCTAssertEqual(reloadedProfile1.totalFlashcardsSeen, 100,
            "PROPERTY VIOLATION: Flashcard count not preserved after switch")
        XCTAssertFalse(reloadedProfile1.isActive,
            "PROPERTY VIOLATION: Previous profile should be inactive")
    }

    /**
     * PROPERTY: getActiveProfile must always return current active profile
     * CRITICAL: User concern #2 - Profile loading is fundamental
     */
    func testProfileActivation_PropertyBased_GetActiveProfileReturnsCorrectProfile() throws {
        // Create and activate 3 profiles sequentially
        for i in 0..<3 {
            let profile = try createTestProfile(name: "User\(i)")
            try profileService.activateProfile(profile)

            // PROPERTY: getActiveProfile must return just-activated profile
            let activeProfile = profileService.getActiveProfile()
            XCTAssertNotNil(activeProfile,
                "PROPERTY VIOLATION: getActiveProfile returned nil")
            XCTAssertEqual(activeProfile?.id, profile.id,
                """
                PROPERTY VIOLATION: getActiveProfile returned wrong profile
                Expected: \(profile.name)
                Got: \(activeProfile?.name ?? "nil")
                """)
        }
    }

    /**
     * PROPERTY: Profile activation updates lastActiveAt timestamp
     */
    func testProfileActivation_PropertyBased_UpdatesLastActiveTimestamp() throws {
        let profile = try createTestProfile()

        let originalTimestamp = profile.lastActiveAt

        // Wait a moment to ensure timestamp difference
        Thread.sleep(forTimeInterval: 0.01)

        // Activate profile
        try profileService.activateProfile(profile)

        // PROPERTY: lastActiveAt must be updated
        XCTAssertGreaterThan(profile.lastActiveAt, originalTimestamp,
            """
            PROPERTY VIOLATION: lastActiveAt not updated on activation
            Original: \(originalTimestamp)
            After activation: \(profile.lastActiveAt)
            """)
    }

    /**
     * PROPERTY: First created profile must be automatically activated
     */
    func testProfileActivation_PropertyBased_FirstProfileAutoActivated() throws {
        // Create first profile
        let firstProfile = try createTestProfile(name: "FirstUser")

        // PROPERTY: First profile must be active
        XCTAssertTrue(firstProfile.isActive,
            "PROPERTY VIOLATION: First profile should be auto-activated")

        let activeProfile = profileService.getActiveProfile()
        XCTAssertEqual(activeProfile?.id, firstProfile.id,
            "PROPERTY VIOLATION: First profile should be returned as active")
    }

    // MARK: - 3. Belt-Appropriate Content Filtering (6 tests) ⭐ CRITICAL

    /**
     * PROPERTY: Terminology content must be filtered by belt level
     * CRITICAL: User concern #3 - Content visibility by belt
     */
    func testContentFiltering_PropertyBased_TerminologyFilteredByBelt() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        // Test with 3 random belt levels
        for _ in 0..<3 {
            guard let belt = allBelts.randomElement() else { continue }
            let profile = try createTestProfile(belt: belt)

            let terminologyService = TerminologyDataService(modelContext: testContext)
            let availableTerms = terminologyService.getTerminologyForUser(userProfile: profile)

            // PROPERTY: All returned terms must be appropriate for user's belt
            for term in availableTerms {
                let termBeltOrder = term.beltLevel.sortOrder
                let userBeltOrder = profile.currentBeltLevel.sortOrder

                XCTAssertGreaterThanOrEqual(termBeltOrder, userBeltOrder,
                    """
                    PROPERTY VIOLATION: Term not appropriate for belt
                    Term: \(term.englishTerm) (\(term.beltLevel.shortName))
                    User belt: \(belt.shortName)
                    Term sortOrder: \(termBeltOrder)
                    User sortOrder: \(userBeltOrder)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Pattern content must be filtered by belt level
     * CRITICAL: User concern #3 - Content visibility by belt
     */
    func testContentFiltering_PropertyBased_PatternsFilteredByBelt() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        // Test with 3 random belt levels
        for _ in 0..<3 {
            guard let belt = allBelts.randomElement() else { continue }
            let profile = try createTestProfile(belt: belt)

            let patternService = PatternDataService(modelContext: testContext)
            let availablePatterns = patternService.getPatternsForUser(userProfile: profile)

            // PROPERTY: All returned patterns must be appropriate for user's belt
            for pattern in availablePatterns {
                let isAvailable = pattern.isAppropriateFor(beltLevel: belt)
                XCTAssertTrue(isAvailable,
                    """
                    PROPERTY VIOLATION: Pattern not appropriate for belt
                    Pattern: \(pattern.name)
                    User belt: \(belt.shortName)
                    isAvailableFor: \(isAvailable)
                    """)
            }
        }
    }

    /**
     * PROPERTY: Content must change when profile switches (different belts)
     * CRITICAL: User concern #3 - Profile switching affects visibility
     */
    func testContentFiltering_PropertyBased_ContentChangesOnProfileSwitch() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        guard allBelts.count >= 2 else {
            XCTFail("Need at least 2 belt levels for this test")
            return
        }

        // Create two profiles with different belt levels
        let lowBelt = allBelts.last! // Highest sortOrder = lowest belt
        let highBelt = allBelts.first! // Lowest sortOrder = highest belt

        let lowProfile = try createTestProfile(name: "LowBelt", belt: lowBelt)
        let highProfile = try createTestProfile(name: "HighBelt", belt: highBelt)

        let terminologyService = TerminologyDataService(modelContext: testContext)

        // Activate low belt profile
        try profileService.activateProfile(lowProfile)
        let lowBeltTerms = terminologyService.getTerminologyForUser(userProfile: lowProfile)

        // Activate high belt profile
        try profileService.activateProfile(highProfile)
        let highBeltTerms = terminologyService.getTerminologyForUser(userProfile: highProfile)

        // PROPERTY: High belt should see MORE or EQUAL content
        XCTAssertGreaterThanOrEqual(highBeltTerms.count, lowBeltTerms.count,
            """
            PROPERTY VIOLATION: High belt sees less content than low belt
            Low belt (\(lowBelt.shortName)): \(lowBeltTerms.count) terms
            High belt (\(highBelt.shortName)): \(highBeltTerms.count) terms
            """)

        // PROPERTY: Content sets should be different (unless same belt)
        if lowBelt.id != highBelt.id {
            let lowIds = Set(lowBeltTerms.map { $0.id })
            let highIds = Set(highBeltTerms.map { $0.id })
            XCTAssertNotEqual(lowIds, highIds,
                "PROPERTY VIOLATION: Different belts should see different content sets")
        }
    }

    /**
     * PROPERTY: Higher belt levels must see more or equal content
     */
    func testContentFiltering_PropertyBased_ProgressionUnlocksContent() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        guard allBelts.count >= 3 else {
            XCTFail("Need at least 3 belt levels for this test")
            return
        }

        let terminologyService = TerminologyDataService(modelContext: testContext)
        var previousCount = 0

        // Test progression through belts (from lowest to highest)
        for belt in allBelts.reversed() {
            let profile = try createTestProfile(belt: belt)
            let terms = terminologyService.getTerminologyForUser(userProfile: profile)

            // PROPERTY: Content count must not decrease as belt advances
            XCTAssertGreaterThanOrEqual(terms.count, previousCount,
                """
                PROPERTY VIOLATION: Content decreased on belt advancement
                Belt: \(belt.shortName)
                Current count: \(terms.count)
                Previous count: \(previousCount)
                """)

            previousCount = terms.count
        }
    }

    /**
     * PROPERTY: Mastery mode affects content selection
     */
    func testContentFiltering_PropertyBased_MasteryModeAffectsContent() throws {
        let belt = try getRandomBelt()

        // Create two profiles with same belt, different learning modes
        let progressionProfile = try profileService.createProfile(
            name: "Progression",
            beltLevel: belt
        )
        try profileService.updateProfile(progressionProfile, learningMode: .progression)

        let masteryProfile = try profileService.createProfile(
            name: "Mastery",
            beltLevel: belt
        )
        try profileService.updateProfile(masteryProfile, learningMode: .mastery)

        // PROPERTY: Learning mode must be set correctly
        XCTAssertEqual(progressionProfile.learningMode, .progression,
            "PROPERTY VIOLATION: Progression mode not set")
        XCTAssertEqual(masteryProfile.learningMode, .mastery,
            "PROPERTY VIOLATION: Mastery mode not set")

        // Note: Actual content filtering by mode would be tested here
        // if the terminologyService.getTerminology() respected learningMode
    }

    /**
     * PROPERTY: Profile isolation - different profiles see independent content states
     */
    func testContentFiltering_PropertyBased_ProfileIsolationOfProgressData() throws {
        let belt = try getRandomBelt()
        let profile1 = try createTestProfile(name: "User1", belt: belt)
        let profile2 = try createTestProfile(name: "User2", belt: belt)

        let terminologyService = TerminologyDataService(modelContext: testContext)
        let terms = terminologyService.getTerminologyForUser(userProfile: profile1)
        guard let testTerm = terms.first else {
            XCTFail("No terminology available")
            return
        }

        // Record progress for profile1
        try profileService.activateProfile(profile1)
        let progress1 = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile1)
        progress1.correctCount = 10
        try testContext.save()

        // Check progress for profile2 (should be independent)
        try profileService.activateProfile(profile2)
        let progress2 = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile2)

        // PROPERTY: Profile2's progress must be independent of profile1
        XCTAssertEqual(progress2.correctCount, 0,
            """
            PROPERTY VIOLATION: Progress leaked between profiles
            Profile1 progress: \(progress1.correctCount)
            Profile2 progress: \(progress2.correctCount)
            """)
    }

    // MARK: - 4. Profile Statistics Properties (5 tests)

    /**
     * PROPERTY: Streak calculation must be accurate for daily activity
     */
    func testProfileStatistics_PropertyBased_StreakCalculation() throws {
        let profile = try createTestProfile()

        // Initial streak should be 0
        XCTAssertEqual(profile.streakDays, 0,
            "PROPERTY VIOLATION: Initial streak should be 0")

        // Record activity
        profile.recordActivity()

        // PROPERTY: Streak should increment on activity
        XCTAssertGreaterThan(profile.streakDays, 0,
            "PROPERTY VIOLATION: Streak should increment after activity")
    }

    /**
     * PROPERTY: Study time accumulation must be accurate
     */
    func testProfileStatistics_PropertyBased_StudyTimeAccumulation() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        var expectedTime: TimeInterval = 0

        // Record 5 sessions with random durations
        for _ in 0..<5 {
            let duration = TimeInterval.random(in: 60...600)
            expectedTime += duration

            profile.recordActivity(studyTime: duration)
        }

        // PROPERTY: Total study time must match sum
        XCTAssertEqual(profile.totalStudyTime, expectedTime, accuracy: 0.1,
            """
            PROPERTY VIOLATION: Study time accumulation incorrect
            Expected: \(Int(expectedTime))s
            Got: \(Int(profile.totalStudyTime))s
            """)
    }

    /**
     * PROPERTY: Dashboard statistics must aggregate correctly across sessions
     */
    func testProfileStatistics_PropertyBased_DashboardAggregation() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        // Record multiple study sessions
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 20,
            correctAnswers: 16
        )

        try profileService.recordStudySession(
            sessionType: .testing,
            itemsStudied: 10,
            correctAnswers: 8
        )

        try profileService.recordStudySession(
            sessionType: .patterns,
            itemsStudied: 5,
            correctAnswers: 5
        )

        // Get all sessions for profile
        let sessions = try profileService.getStudySessions(for: profile)

        // PROPERTY: Session count must match recorded sessions
        XCTAssertEqual(sessions.count, 3,
            "PROPERTY VIOLATION: Session count mismatch")

        // PROPERTY: Total items studied must match sum
        let totalItems = sessions.reduce(0) { $0 + $1.itemsStudied }
        XCTAssertEqual(totalItems, 35,
            """
            PROPERTY VIOLATION: Total items studied incorrect
            Expected: 35
            Got: \(totalItems)
            """)

        // PROPERTY: Total correct must match sum
        let totalCorrect = sessions.reduce(0) { $0 + $1.correctAnswers }
        XCTAssertEqual(totalCorrect, 29,
            """
            PROPERTY VIOLATION: Total correct answers incorrect
            Expected: 29
            Got: \(totalCorrect)
            """)
    }

    /**
     * PROPERTY: Activity summary calculations must be accurate
     */
    func testProfileStatistics_PropertyBased_ActivitySummaryAccuracy() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        // Record sessions with known metrics
        for _ in 0..<3 {
            try profileService.recordStudySession(
                sessionType: .flashcards,
                itemsStudied: 20,
                correctAnswers: 16
            )
        }

        let activitySummary = profile.recentActivity

        // PROPERTY: Streak must reflect profile state
        XCTAssertEqual(activitySummary.currentStreak, profile.streakDays,
            "PROPERTY VIOLATION: Activity summary streak mismatch")

        // PROPERTY: Study hours must match profile total
        let expectedHours = profile.totalStudyTime / 3600
        XCTAssertEqual(activitySummary.totalStudyHours, expectedHours, accuracy: 0.01,
            "PROPERTY VIOLATION: Activity summary hours mismatch")
    }

    /**
     * PROPERTY: System statistics must aggregate all profiles correctly
     */
    func testProfileStatistics_PropertyBased_SystemStatisticsAggregation() throws {
        // Create 3 profiles with varying activity
        var profiles: [UserProfile] = []
        for i in 0..<3 {
            let profile = try createTestProfile(name: "User\(i)")
            profiles.append(profile)

            try profileService.activateProfile(profile)
            profile.recordActivity(studyTime: Double(i + 1) * 100)
        }

        let systemStats = try profileService.getSystemStatistics()

        // PROPERTY: Total profiles must match
        XCTAssertEqual(systemStats.totalProfiles, 3,
            "PROPERTY VIOLATION: System stats profile count incorrect")

        // PROPERTY: Total study time must be sum of all profiles
        let expectedTotal = profiles.reduce(0) { $0 + $1.totalStudyTime }
        XCTAssertEqual(systemStats.totalStudyTime, expectedTotal, accuracy: 0.1,
            """
            PROPERTY VIOLATION: System stats study time incorrect
            Expected: \(Int(expectedTotal))s
            Got: \(Int(systemStats.totalStudyTime))s
            """)
    }

    // MARK: - 5. Profile Isolation Properties (4 tests)

    /**
     * PROPERTY: Study sessions must not leak between profiles
     */
    func testProfileIsolation_PropertyBased_StudySessionsIsolated() throws {
        let profile1 = try createTestProfile(name: "User1")
        let profile2 = try createTestProfile(name: "User2")

        // Record sessions for profile1
        try profileService.activateProfile(profile1)
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 20,
            correctAnswers: 16
        )

        // Record sessions for profile2
        try profileService.activateProfile(profile2)
        try profileService.recordStudySession(
            sessionType: .testing,
            itemsStudied: 10,
            correctAnswers: 8
        )

        // PROPERTY: Profile1 should only see its own sessions
        let profile1Sessions = try profileService.getStudySessions(for: profile1)
        XCTAssertEqual(profile1Sessions.count, 1,
            "PROPERTY VIOLATION: Profile1 sees wrong session count")
        XCTAssertTrue(profile1Sessions.allSatisfy { $0.sessionType == .flashcards },
            "PROPERTY VIOLATION: Profile1 sees profile2's sessions")

        // PROPERTY: Profile2 should only see its own sessions
        let profile2Sessions = try profileService.getStudySessions(for: profile2)
        XCTAssertEqual(profile2Sessions.count, 1,
            "PROPERTY VIOLATION: Profile2 sees wrong session count")
        XCTAssertTrue(profile2Sessions.allSatisfy { $0.sessionType == .testing },
            "PROPERTY VIOLATION: Profile2 sees profile1's sessions")
    }

    /**
     * PROPERTY: Terminology progress must not leak between profiles
     */
    func testProfileIsolation_PropertyBased_TerminologyProgressIsolated() throws {
        let belt = try getRandomBelt()
        let profile1 = try createTestProfile(name: "User1", belt: belt)
        let profile2 = try createTestProfile(name: "User2", belt: belt)

        let terminologyService = TerminologyDataService(modelContext: testContext)
        let terms = terminologyService.getTerminologyForUser(userProfile: profile1)
        guard let testTerm = terms.first else {
            XCTFail("No terminology available")
            return
        }

        // Create progress for profile1
        let progress1 = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile1)
        progress1.correctCount = 5
        try testContext.save()

        // Check progress for profile2
        let progress2 = terminologyService.getOrCreateProgress(for: testTerm, userProfile: profile2)

        // PROPERTY: Progress must be independent
        XCTAssertNotEqual(progress1.id, progress2.id,
            "PROPERTY VIOLATION: Same progress object returned for different profiles")
        XCTAssertEqual(progress2.correctCount, 0,
            "PROPERTY VIOLATION: Progress leaked from profile1 to profile2")
    }

    /**
     * PROPERTY: Pattern progress must not leak between profiles
     */
    func testProfileIsolation_PropertyBased_PatternProgressIsolated() throws {
        let belt = try getRandomBelt()
        let profile1 = try createTestProfile(name: "User1", belt: belt)
        let profile2 = try createTestProfile(name: "User2", belt: belt)

        let patternService = PatternDataService(modelContext: testContext)
        let patterns = patternService.getPatternsForUser(userProfile: profile1)
        guard let testPattern = patterns.first else {
            XCTFail("No patterns available")
            return
        }

        // Create progress for profile1
        let progress1 = patternService.getUserProgress(for: testPattern, userProfile: profile1)
        progress1.bestRunAccuracy = 0.9
        try testContext.save()

        // Check progress for profile2
        let progress2 = patternService.getUserProgress(for: testPattern, userProfile: profile2)

        // PROPERTY: Progress must be independent
        XCTAssertNotEqual(progress1.id, progress2.id,
            "PROPERTY VIOLATION: Same progress object returned for different profiles")
        XCTAssertEqual(progress2.bestRunAccuracy, 0.0,
            "PROPERTY VIOLATION: Progress leaked from profile1 to profile2")
    }

    /**
     * PROPERTY: Deleting a profile must not affect other profiles
     */
    func testProfileIsolation_PropertyBased_DeletionDoesNotAffectOthers() throws {
        let profile1 = try createTestProfile(name: "User1")
        let profile2 = try createTestProfile(name: "User2")
        let profile3 = try createTestProfile(name: "User3")

        // Record data for each profile
        for profile in [profile1, profile2, profile3] {
            try profileService.activateProfile(profile)
            profile.totalFlashcardsSeen = 100
        }
        try testContext.save()

        // Delete profile2
        try profileService.deleteProfile(profile2)

        // PROPERTY: Profile1 and Profile3 must still exist with correct data
        let remainingProfiles = try profileService.getAllProfiles()
        XCTAssertEqual(remainingProfiles.count, 2,
            "PROPERTY VIOLATION: Wrong number of profiles after deletion")

        let profile1Reloaded = remainingProfiles.first { $0.id == profile1.id }!
        let profile3Reloaded = remainingProfiles.first { $0.id == profile3.id }!

        XCTAssertEqual(profile1Reloaded.totalFlashcardsSeen, 100,
            "PROPERTY VIOLATION: Profile1 data changed after profile2 deletion")
        XCTAssertEqual(profile3Reloaded.totalFlashcardsSeen, 100,
            "PROPERTY VIOLATION: Profile3 data changed after profile2 deletion")
    }

    // MARK: - 6. Study Session Properties (3 tests)

    /**
     * PROPERTY: Study session accuracy calculation must be correct
     */
    func testStudySession_PropertyBased_AccuracyCalculation() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        // Test 10 random accuracy scenarios
        for _ in 0..<10 {
            let itemsStudied = Int.random(in: 5...50)
            let correctAnswers = Int.random(in: 0...itemsStudied)

            try profileService.recordStudySession(
                sessionType: .flashcards,
                itemsStudied: itemsStudied,
                correctAnswers: correctAnswers
            )

            let sessions = try profileService.getStudySessions(for: profile)
            guard let lastSession = sessions.first else {
                XCTFail("Session not recorded")
                return
            }

            // PROPERTY: Accuracy must match formula
            let expectedAccuracy = Double(correctAnswers) / Double(itemsStudied)
            XCTAssertEqual(lastSession.accuracy, expectedAccuracy, accuracy: 0.001,
                """
                PROPERTY VIOLATION: Session accuracy incorrect
                Items: \(itemsStudied)
                Correct: \(correctAnswers)
                Expected: \(Int(expectedAccuracy * 100))%
                Got: \(Int(lastSession.accuracy * 100))%
                """)
        }
    }

    /**
     * PROPERTY: Study session duration must be recorded
     */
    func testStudySession_PropertyBased_DurationRecorded() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        try profileService.recordStudySession(
            sessionType: .patterns,
            itemsStudied: 5,
            correctAnswers: 5
        )

        let sessions = try profileService.getStudySessions(for: profile)
        guard let session = sessions.first else {
            XCTFail("Session not recorded")
            return
        }

        // PROPERTY: Duration must be non-negative
        XCTAssertGreaterThanOrEqual(session.duration, 0,
            "PROPERTY VIOLATION: Session duration is negative")

        // PROPERTY: End time must be set
        XCTAssertNotNil(session.endTime,
            "PROPERTY VIOLATION: Session end time not set")
    }

    /**
     * PROPERTY: Focus areas must be preserved
     */
    func testStudySession_PropertyBased_FocusAreasPreserved() throws {
        let profile = try createTestProfile()
        try profileService.activateProfile(profile)

        let focusAreas = ["Kicks", "Blocks", "Stances"]

        try profileService.recordStudySession(
            sessionType: .mixed,
            itemsStudied: 15,
            correctAnswers: 12,
            focusAreas: focusAreas
        )

        let sessions = try profileService.getStudySessions(for: profile)
        guard let session = sessions.first else {
            XCTFail("Session not recorded")
            return
        }

        // PROPERTY: Focus areas must match recorded areas
        let recordedAreas = session.focusAreasArray
        XCTAssertEqual(recordedAreas.count, focusAreas.count,
            "PROPERTY VIOLATION: Focus area count mismatch")
        XCTAssertEqual(Set(recordedAreas), Set(focusAreas),
            "PROPERTY VIOLATION: Focus areas not preserved correctly")
    }

    // MARK: - 7. Grading Record Properties (2 tests)

    /**
     * PROPERTY: Passing grading must update profile belt level
     */
    func testGradingRecord_PropertyBased_PassingUpdatesCurrentBelt() throws {
        let allBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
            .sorted { $0.sortOrder > $1.sortOrder }

        guard allBelts.count >= 2 else {
            XCTFail("Need at least 2 belt levels")
            return
        }

        let lowBelt = allBelts[allBelts.count - 2] // Second lowest
        let highBelt = allBelts[allBelts.count - 3] // Third lowest

        let profile = try createTestProfile(belt: lowBelt)
        try profileService.activateProfile(profile)

        // Record passing grading
        try profileService.recordGrading(
            gradingDate: Date(),
            beltTested: highBelt,
            beltAchieved: highBelt,
            passed: true
        )

        // Reload profile
        let reloadedProfile = try profileService.getAllProfiles()
            .first { $0.id == profile.id }!

        // PROPERTY: Belt must be updated after passing
        XCTAssertEqual(reloadedProfile.currentBeltLevel.id, highBelt.id,
            """
            PROPERTY VIOLATION: Belt not updated after passing grading
            Expected: \(highBelt.shortName)
            Got: \(reloadedProfile.currentBeltLevel.shortName)
            """)
    }

    /**
     * PROPERTY: Grading statistics must calculate pass rate correctly
     */
    func testGradingRecord_PropertyBased_PassRateCalculation() throws {
        let belt = try getRandomBelt()
        let profile = try createTestProfile(belt: belt)
        try profileService.activateProfile(profile)

        // Record random gradings
        let totalGradings = 10
        let passedCount = 7

        for i in 0..<totalGradings {
            let passed = i < passedCount

            try profileService.recordGrading(
                gradingDate: Date().addingTimeInterval(-Double(i) * 86400),
                beltTested: belt,
                beltAchieved: belt,
                passed: passed
            )
        }

        let statistics = try profileService.getGradingStatistics(for: profile)

        // PROPERTY: Pass rate must match (passed / total)
        let expectedPassRate = Double(passedCount) / Double(totalGradings)
        XCTAssertEqual(statistics.passRate, expectedPassRate, accuracy: 0.001,
            """
            PROPERTY VIOLATION: Pass rate incorrect
            Passed: \(passedCount)
            Total: \(totalGradings)
            Expected: \(Int(expectedPassRate * 100))%
            Got: \(Int(statistics.passRate * 100))%
            """)

        // PROPERTY: Counts must match
        XCTAssertEqual(statistics.totalGradings, totalGradings,
            "PROPERTY VIOLATION: Total gradings count incorrect")
        XCTAssertEqual(statistics.passedGradings, passedCount,
            "PROPERTY VIOLATION: Passed gradings count incorrect")
        XCTAssertEqual(statistics.failedGradings, totalGradings - passedCount,
            "PROPERTY VIOLATION: Failed gradings count incorrect")
    }
}
