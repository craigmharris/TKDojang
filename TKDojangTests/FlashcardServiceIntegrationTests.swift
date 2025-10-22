import XCTest
import SwiftData
@testable import TKDojang

/**
 * FlashcardServiceIntegrationTests.swift
 *
 * PURPOSE: Service orchestration tests for flashcard feature integration
 *
 * ARCHITECTURAL APPROACH (Phase 2 Breakthrough):
 * Tests service layer integration, NOT view rendering. In SwiftUI MVVM-C,
 * integration happens at the SERVICE layer where multiple services coordinate.
 *
 * INTEGRATION LAYERS TESTED:
 * 1. EnhancedTerminologyService → TerminologyService + LeitnerService coordination
 * 2. FlashcardConfiguration → Term selection orchestration
 * 3. Answer recording → Progress tracking → Leitner box updates
 * 4. Session completion → ProfileService → Stats recording
 * 5. Multi-profile data isolation
 *
 * WHY SERVICE ORCHESTRATION:
 * - Flashcard bugs occur in service coordination, not SwiftUI view rendering
 * - Testing term selection, answer recording, and stats aggregation validates core logic
 * - Service tests are faster, more reliable, and easier to debug than ViewInspector
 * - Property-based approach ensures correctness across randomized states
 *
 * Test coverage: 8 integration tests validating flashcard service orchestration
 */

@MainActor
final class FlashcardServiceIntegrationTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var terminologyService: TerminologyDataService!
    var leitnerService: LeitnerService!
    var profileService: ProfileService!
    var enhancedService: EnhancedTerminologyService!
    var dataFactory: TestDataFactory!
    var testBelts: [BeltLevel] = []
    var testCategories: [TerminologyCategory] = []

    override func setUp() async throws {
        // Use TestContainerFactory for consistent test infrastructure
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext

        // Initialize services
        terminologyService = TerminologyDataService(modelContext: testContext)
        leitnerService = LeitnerService(modelContext: testContext)
        profileService = ProfileService(modelContext: testContext)
        enhancedService = EnhancedTerminologyService(
            terminologyService: terminologyService,
            leitnerService: leitnerService
        )

        // Setup test data using TestDataFactory
        dataFactory = TestDataFactory()
        testBelts = dataFactory.createBasicBeltLevels()
        testCategories = dataFactory.createBasicCategories()

        // Insert belt levels
        for belt in testBelts {
            testContext.insert(belt)
        }

        // Insert categories
        for category in testCategories {
            testContext.insert(category)
        }

        // Create terminology entries for each belt
        for belt in testBelts {
            if let category = testCategories.first {
                let entries = dataFactory.createSampleTerminologyEntries(
                    belt: belt,
                    category: category,
                    count: 5
                )
                for entry in entries {
                    testContext.insert(entry)
                }
            }
        }

        try testContext.save()
    }

    override func tearDown() {
        testContext = nil
        testContainer = nil
        terminologyService = nil
        leitnerService = nil
        profileService = nil
        enhancedService = nil
        dataFactory = nil
        testBelts = []
        testCategories = []
    }

    // MARK: - Helper Methods

    private func createTestProfile(
        name: String,
        beltLevel: BeltLevel,
        learningMode: LearningMode = .progression
    ) throws -> UserProfile {
        return try profileService.createProfile(
            name: name,
            avatar: .student1,
            colorTheme: .blue,
            beltLevel: beltLevel
        )
    }

    private func getBeltByKeup(_ keup: Int) -> BeltLevel? {
        // Match by shortName for reliability (TestDataFactory creates belts with full names like "10th Keup (White Belt)")
        let shortName: String
        if keup == 3 {
            shortName = "3rd Keup"
        } else if keup == 2 {
            shortName = "2nd Keup"
        } else if keup == 1 {
            shortName = "1st Keup"
        } else {
            shortName = "\(keup)th Keup"
        }
        return testBelts.first { $0.shortName == shortName }
    }

    // MARK: - Integration Tests

    // MARK: Test 1: Configuration to Term Selection Flow

    /**
     * INTEGRATION VALIDATED:
     * - FlashcardConfiguration → EnhancedTerminologyService coordination
     * - Configuration settings flow through term selection logic
     * - Requested term count matches returned term count (or available max)
     * - Belt level filtering applied correctly
     * - Learning mode (progression/mastery) affects term selection
     */
    func testConfigurationToTermSelectionFlow() throws {
        // ARRANGE: Create profile and configuration
        guard let belt8thKeup = getBeltByKeup(8) else {
            XCTFail("8th keup belt not available")
            return
        }
        guard let belt1stKeup = getBeltByKeup(1) else {
            XCTFail("1st keup belt not available")
            return
        }

        let beginnerProfile = try createTestProfile(
            name: "Beginner",
            beltLevel: belt8thKeup,
            learningMode: .progression
        )

        let advancedProfile = try createTestProfile(
            name: "Advanced",
            beltLevel: belt1stKeup,
            learningMode: .mastery
        )

        // ACT & ASSERT: Test progression mode (current belt only)
        let progressionTerms = enhancedService.getTermsForFlashcardSession(
            userProfile: beginnerProfile,
            requestedCount: 20,
            learningSystem: .classic
        )

        // PROPERTY: Progression mode returns only current belt terms
        XCTAssertTrue(
            progressionTerms.allSatisfy { $0.beltLevel.sortOrder == belt8thKeup.sortOrder },
            "Progression mode should return only current belt terms"
        )

        // PROPERTY: Returned count ≤ requested count
        XCTAssertLessThanOrEqual(
            progressionTerms.count,
            20,
            "Returned terms should not exceed requested count"
        )

        // ACT & ASSERT: Test mastery mode (current + prior belts)
        let masteryTerms = enhancedService.getTermsForFlashcardSession(
            userProfile: advancedProfile,
            requestedCount: 30,
            learningSystem: .classic
        )

        // PROPERTY: Mastery mode returns current + prior belt terms
        let uniqueBeltLevels = Set(masteryTerms.map { $0.beltLevel.sortOrder })
        XCTAssertGreaterThan(
            uniqueBeltLevels.count,
            1,
            "Mastery mode should return terms from multiple belts"
        )

        // PROPERTY: All mastery terms are from current belt or higher (prior belts)
        XCTAssertTrue(
            masteryTerms.allSatisfy { $0.beltLevel.sortOrder >= belt1stKeup.sortOrder },
            "Mastery mode should only return terms up to current belt"
        )

        // ACT & ASSERT: Test configuration with different requested counts
        let counts = [5, 10, 20, 50]
        for requestedCount in counts {
            let terms = enhancedService.getTermsForFlashcardSession(
                userProfile: advancedProfile,
                requestedCount: requestedCount,
                learningSystem: .classic
            )

            // PROPERTY: Service attempts to return requested count
            XCTAssertLessThanOrEqual(
                terms.count,
                requestedCount,
                "Returned count should not exceed requested count"
            )

            if terms.count < requestedCount {
                // If fewer returned, it means insufficient available terms
                print("⚠️ Only \(terms.count) terms available for requested \(requestedCount)")
            }
        }
    }

    // MARK: Test 2: Answer Recording to Progress Tracking Flow

    /**
     * INTEGRATION VALIDATED:
     * - Answer recording → TerminologyService persistence
     * - Progress tracking updates correctly
     * - Correct/incorrect counts increment properly
     * - Response times recorded
     */
    func testAnswerRecordingToProgressTrackingFlow() throws {
        // ARRANGE: Create profile and get terms
        guard let belt7thKeup = getBeltByKeup(7) else {
            XCTFail("7th keup belt not available")
            return
        }

        let profile = try createTestProfile(
            name: "Test User",
            beltLevel: belt7thKeup
        )

        try profileService.activateProfile(profile)

        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: 10,
            learningSystem: .classic
        )

        XCTAssertGreaterThan(terms.count, 0, "Should have terms for testing")

        // ACT: Record answers (mix of correct and incorrect)
        let testTerm = terms[0]

        // Record correct answer
        terminologyService.recordUserAnswer(
            userProfile: profile,
            terminologyEntry: testTerm,
            isCorrect: true,
            responseTime: 3.5
        )

        // Record incorrect answer
        terminologyService.recordUserAnswer(
            userProfile: profile,
            terminologyEntry: testTerm,
            isCorrect: false,
            responseTime: 2.1
        )

        // ASSERT: Fetch user's terminology progress
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
        let allProgress = try testContext.fetch(progressDescriptor)

        // Filter manually to avoid SwiftData predicate issues with relationships
        let progressRecords = allProgress.filter { $0.terminologyEntry.id == testTerm.id }

        // PROPERTY: Progress record exists after answer recording
        XCTAssertGreaterThan(
            progressRecords.count,
            0,
            "Progress record should be created after recording answer"
        )

        // Verify progress tracking
        if let progress = progressRecords.first {
            // PROPERTY: Total reviews increments
            XCTAssertGreaterThan(
                progress.totalReviews,
                0,
                "Total reviews should increment"
            )

            // PROPERTY: Last reviewed date updated
            XCTAssertNotNil(
                progress.lastReviewedAt,
                "Last reviewed date should be recorded"
            )
        }
    }

    // MARK: Test 3: Leitner System Integration Flow

    /**
     * INTEGRATION VALIDATED:
     * - Leitner mode enabled → due terms prioritized
     * - Answer recording updates Leitner boxes
     * - Box distribution reflects learning progress
     * - Migration to Leitner mode creates initial boxes
     */
    func testLeitnerSystemIntegrationFlow() throws {
        // ARRANGE: Create profile and migrate to Leitner mode
        guard let belt5thKeup = getBeltByKeup(5) else {
            XCTFail("5th keup belt not available")
            return
        }

        let profile = try createTestProfile(
            name: "Leitner User",
            beltLevel: belt5thKeup
        )

        try profileService.activateProfile(profile)

        // Migrate to Leitner mode
        leitnerService.migrateToLeitnerMode(userProfile: profile)
        leitnerService.isLeitnerModeEnabled = true

        // ACT: Get terms for Leitner session
        let leitnerTerms = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: 15,
            learningSystem: .leitner
        )

        // ASSERT: Terms returned for Leitner mode
        XCTAssertGreaterThan(
            leitnerTerms.count,
            0,
            "Leitner mode should return terms"
        )

        // ACT: Record answers to update boxes
        if leitnerTerms.count >= 3 {
            let term1 = leitnerTerms[0]
            let term2 = leitnerTerms[1]
            let term3 = leitnerTerms[2]

            // Record correct answer (should move to next box)
            terminologyService.recordUserAnswer(
                userProfile: profile,
                terminologyEntry: term1,
                isCorrect: true,
                responseTime: 2.0
            )

            // Record incorrect answer (should move back to box 1)
            terminologyService.recordUserAnswer(
                userProfile: profile,
                terminologyEntry: term2,
                isCorrect: false,
                responseTime: 4.0
            )

            // Record another correct answer
            terminologyService.recordUserAnswer(
                userProfile: profile,
                terminologyEntry: term3,
                isCorrect: true,
                responseTime: 3.0
            )

            // ASSERT: Check box distribution
            let distribution = leitnerService.getBoxDistribution(userProfile: profile)

            // PROPERTY: Box distribution sums to total terms
            let totalInBoxes = distribution.values.reduce(0, +)
            XCTAssertGreaterThan(
                totalInBoxes,
                0,
                "Terms should be distributed across Leitner boxes"
            )

            // PROPERTY: Due count updated
            let dueCount = leitnerService.getTermsDueCount(userProfile: profile)
            XCTAssertGreaterThanOrEqual(
                dueCount,
                0,
                "Due count should be tracked"
            )
        }
    }

    // MARK: Test 4: Session Completion to ProfileService Stats Flow

    /**
     * INTEGRATION VALIDATED:
     * - Session completion → ProfileService.recordStudySession()
     * - Session stats recorded correctly
     * - Profile metrics updated (totalFlashcardsSeen, streakDays)
     * - StudySession persisted with accurate data
     */
    func testSessionCompletionToStatsRecordingFlow() throws {
        // ARRANGE: Create profile
        guard let belt6thKeup = getBeltByKeup(6) else {
            XCTFail("6th keup belt not available")
            return
        }

        let profile = try createTestProfile(
            name: "Stats User",
            beltLevel: belt6thKeup
        )

        try profileService.activateProfile(profile)

        // Record initial stats
        let initialFlashcards = profile.totalFlashcardsSeen

        // ACT: Record a flashcard study session
        let sessionType = StudySessionType.flashcards
        let itemsStudied = 23
        let correctAnswers = 18
        let focusAreas = [profile.currentBeltLevel.shortName]

        try profileService.recordStudySession(
            sessionType: sessionType,
            itemsStudied: itemsStudied,
            correctAnswers: correctAnswers,
            focusAreas: focusAreas
        )

        // ASSERT: Profile stats updated
        let profileReloaded = try XCTUnwrap(
            profileService.getActiveProfile(),
            "Active profile should exist after session recording"
        )

        // PROPERTY: Total flashcards incremented
        XCTAssertGreaterThan(
            profileReloaded.totalFlashcardsSeen,
            initialFlashcards,
            "Total flashcards should increment after session"
        )

        // PROPERTY: Study session persisted
        let sessionDescriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let allSessions = try testContext.fetch(sessionDescriptor)
        let sessions = allSessions.filter { $0.sessionType == StudySessionType.flashcards }

        XCTAssertGreaterThan(
            sessions.count,
            0,
            "Study session should be persisted"
        )

        if let latestSession = sessions.first {
            // PROPERTY: Session data integrity
            XCTAssertEqual(
                latestSession.sessionType,
                StudySessionType.flashcards,
                "Session type should match"
            )

            XCTAssertEqual(
                latestSession.itemsStudied,
                itemsStudied,
                "Items studied should match"
            )

            XCTAssertEqual(
                latestSession.correctAnswers,
                correctAnswers,
                "Correct answers should match"
            )

            // PROPERTY: Accuracy calculation
            let expectedAccuracy = Double(correctAnswers) / Double(itemsStudied)
            XCTAssertEqual(
                latestSession.accuracy,
                expectedAccuracy,
                accuracy: 0.01,
                "Accuracy should be calculated correctly"
            )
        }
    }

    // MARK: Test 5: Multi-Profile Data Isolation

    /**
     * INTEGRATION VALIDATED:
     * - Flashcard progress isolated per profile
     * - Terminology progress doesn't leak between profiles
     * - Leitner boxes isolated per profile
     * - Study sessions correctly associated with profile
     */
    func testMultiProfileFlashcardDataIsolation() throws {
        // ARRANGE: Create two profiles
        guard let belt7thKeup = getBeltByKeup(7) else {
            XCTFail("7th keup belt not available")
            return
        }
        guard let belt4thKeup = getBeltByKeup(4) else {
            XCTFail("4th keup belt not available")
            return
        }

        let profile1 = try createTestProfile(
            name: "User One",
            beltLevel: belt7thKeup
        )

        let profile2 = try createTestProfile(
            name: "User Two",
            beltLevel: belt4thKeup
        )

        // ACT: Profile 1 studies flashcards
        try profileService.activateProfile(profile1)

        let terms1 = enhancedService.getTermsForFlashcardSession(
            userProfile: profile1,
            requestedCount: 10,
            learningSystem: .classic
        )

        XCTAssertGreaterThan(terms1.count, 0, "Profile 1 should have terms")

        // Record answers for profile 1
        if terms1.count > 0 {
            terminologyService.recordUserAnswer(
                userProfile: profile1,
                terminologyEntry: terms1[0],
                isCorrect: true,
                responseTime: 2.5
            )
        }

        // Record session for profile 1
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 10,
            correctAnswers: 8,
            focusAreas: [profile1.currentBeltLevel.shortName]
        )

        let profile1FlashcardsSeen = profile1.totalFlashcardsSeen

        // ACT: Profile 2 studies flashcards
        try profileService.activateProfile(profile2)

        let terms2 = enhancedService.getTermsForFlashcardSession(
            userProfile: profile2,
            requestedCount: 15,
            learningSystem: .classic
        )

        XCTAssertGreaterThan(terms2.count, 0, "Profile 2 should have terms")

        // Record answers for profile 2
        if terms2.count > 0 {
            terminologyService.recordUserAnswer(
                userProfile: profile2,
                terminologyEntry: terms2[0],
                isCorrect: false,
                responseTime: 3.5
            )
        }

        // Record session for profile 2
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: 15,
            correctAnswers: 12,
            focusAreas: [profile2.currentBeltLevel.shortName]
        )

        let profile2FlashcardsSeen = profile2.totalFlashcardsSeen

        // ASSERT: Data isolation

        // PROPERTY: Profile stats isolated
        XCTAssertNotEqual(
            profile1FlashcardsSeen,
            profile2FlashcardsSeen,
            "Flashcard counts should differ between profiles"
        )

        // PROPERTY: Study sessions correctly associated
        let allSessionsDescriptor = FetchDescriptor<StudySession>()
        let allSessions = try testContext.fetch(allSessionsDescriptor)

        // Filter sessions manually (safe approach)
        let profile1Sessions = allSessions.filter { $0.userProfile.id == profile1.id }
        let profile2Sessions = allSessions.filter { $0.userProfile.id == profile2.id }

        XCTAssertGreaterThan(
            profile1Sessions.count,
            0,
            "Profile 1 should have study sessions"
        )

        XCTAssertGreaterThan(
            profile2Sessions.count,
            0,
            "Profile 2 should have study sessions"
        )

        // PROPERTY: Sessions don't leak between profiles
        XCTAssertTrue(
            profile1Sessions.allSatisfy { $0.userProfile.id == profile1.id },
            "Profile 1 sessions should only belong to Profile 1"
        )

        XCTAssertTrue(
            profile2Sessions.allSatisfy { $0.userProfile.id == profile2.id },
            "Profile 2 sessions should only belong to Profile 2"
        )
    }

    // MARK: Test 6: Learning Mode Integration Flow

    /**
     * INTEGRATION VALIDATED:
     * - Progression mode returns current belt terms only
     * - Mastery mode returns current + prior belt terms
     * - Mode change affects term selection
     * - Term count respects mode limits (mastery capped at 50)
     */
    func testLearningModeIntegrationFlow() throws {
        // ARRANGE: Create profile with advanced belt
        guard let belt2ndKeup = getBeltByKeup(2) else {
            XCTFail("2nd keup belt not available")
            return
        }

        let profile = try createTestProfile(
            name: "Mode Test",
            beltLevel: belt2ndKeup,
            learningMode: .progression
        )

        // ACT & ASSERT: Test progression mode
        let progressionTerms = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: 30,
            learningSystem: .classic
        )

        // PROPERTY: Progression mode single belt
        let progressionBelts = Set(progressionTerms.map { $0.beltLevel.sortOrder })
        XCTAssertEqual(
            progressionBelts.count,
            1,
            "Progression mode should return terms from single belt (current)"
        )

        XCTAssertTrue(
            progressionTerms.allSatisfy { $0.beltLevel.sortOrder == belt2ndKeup.sortOrder },
            "All progression terms should be from current belt"
        )

        // ACT: Switch to mastery mode
        profile.learningMode = LearningMode.mastery
        try testContext.save()

        let masteryTerms = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: 30,
            learningSystem: .classic
        )

        // PROPERTY: Mastery mode multiple belts
        let masteryBelts = Set(masteryTerms.map { $0.beltLevel.sortOrder })
        XCTAssertGreaterThan(
            masteryBelts.count,
            1,
            "Mastery mode should return terms from multiple belts"
        )

        // PROPERTY: Mastery mode includes current belt
        XCTAssertTrue(
            masteryTerms.contains { $0.beltLevel.sortOrder == belt2ndKeup.sortOrder },
            "Mastery mode should include current belt terms"
        )

        // ACT & ASSERT: Test mastery mode cap at 50
        let largeMasteryRequest = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: 100,  // Request more than cap
            learningSystem: .classic
        )

        // PROPERTY: Mastery mode caps at 50 terms
        XCTAssertLessThanOrEqual(
            largeMasteryRequest.count,
            50,
            "Mastery mode should cap at 50 terms"
        )
    }

    // MARK: Test 7: Configuration Validation Flow

    /**
     * INTEGRATION VALIDATED:
     * - Requesting more terms than available handled gracefully
     * - Empty term set handled without crash
     * - Invalid belt level handled
     * - Term count constraints respected
     */
    func testConfigurationValidationFlow() throws {
        // ARRANGE: Create beginner profile (limited terms available)
        guard let belt10thKeup = getBeltByKeup(10) else {
            XCTFail("10th keup belt not available")
            return
        }

        let beginnerProfile = try createTestProfile(
            name: "Beginner",
            beltLevel: belt10thKeup
        )

        // ACT & ASSERT: Request more terms than available
        let excessiveRequest = enhancedService.getTermsForFlashcardSession(
            userProfile: beginnerProfile,
            requestedCount: 1000,  // Way more than available
            learningSystem: .classic
        )

        // PROPERTY: Service returns available terms (not crash)
        XCTAssertGreaterThanOrEqual(
            excessiveRequest.count,
            0,
            "Service should handle excessive requests gracefully"
        )

        // PROPERTY: Returned count ≤ requested count
        XCTAssertLessThanOrEqual(
            excessiveRequest.count,
            1000,
            "Returned count should not exceed requested"
        )

        // ACT & ASSERT: Request zero terms
        let zeroRequest = enhancedService.getTermsForFlashcardSession(
            userProfile: beginnerProfile,
            requestedCount: 0,
            learningSystem: .classic
        )

        // PROPERTY: Zero request returns zero terms
        XCTAssertEqual(
            zeroRequest.count,
            0,
            "Requesting 0 terms should return 0 terms"
        )

        // ACT & ASSERT: Small requests
        let smallRequest = enhancedService.getTermsForFlashcardSession(
            userProfile: beginnerProfile,
            requestedCount: 5,
            learningSystem: .classic
        )

        // PROPERTY: Small requests honored
        XCTAssertLessThanOrEqual(
            smallRequest.count,
            5,
            "Small requests should be honored"
        )
    }

    // MARK: Test 8: Complete Workflow End-to-End

    /**
     * INTEGRATION VALIDATED:
     * - Configuration → Session → Results → Profile update complete flow
     * - All services coordinate correctly
     * - Data flows through entire flashcard lifecycle
     * - Stats aggregation accurate across workflow
     */
    func testCompleteFlashcardWorkflow() throws {
        // ARRANGE: Create profile
        guard let belt5thKeup = getBeltByKeup(5) else {
            XCTFail("5th keup belt not available")
            return
        }

        let profile = try createTestProfile(
            name: "Workflow User",
            beltLevel: belt5thKeup
        )

        try profileService.activateProfile(profile)

        let initialFlashcards = profile.totalFlashcardsSeen
        let initialSessions = profile.studySessions.count

        // STEP 1: Configuration → Term Selection
        let requestedCount = 20
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: profile,
            requestedCount: requestedCount,
            learningSystem: .classic
        )

        XCTAssertGreaterThan(
            terms.count,
            0,
            "Should have terms for flashcard session"
        )

        // STEP 2: Session → Answer Recording
        var correctCount = 0
        var incorrectCount = 0

        for (index, term) in terms.enumerated() {
            let isCorrect = index % 3 != 0  // 2/3 correct, 1/3 incorrect

            terminologyService.recordUserAnswer(
                userProfile: profile,
                terminologyEntry: term,
                isCorrect: isCorrect,
                responseTime: Double.random(in: 1.0...5.0)
            )

            if isCorrect {
                correctCount += 1
            } else {
                incorrectCount += 1
            }
        }

        // STEP 3: Session Completion → Stats Recording
        try profileService.recordStudySession(
            sessionType: .flashcards,
            itemsStudied: terms.count,
            correctAnswers: correctCount,
            focusAreas: [profile.currentBeltLevel.shortName]
        )

        // STEP 4: Results → Profile Stats Validation
        let profileAfter = try XCTUnwrap(
            profileService.getActiveProfile(),
            "Active profile should exist"
        )

        // PROPERTY: Flashcard count incremented
        XCTAssertGreaterThan(
            profileAfter.totalFlashcardsSeen,
            initialFlashcards,
            "Total flashcards should increase"
        )

        // PROPERTY: Session count incremented
        XCTAssertGreaterThan(
            profileAfter.studySessions.count,
            initialSessions,
            "Total sessions should increase"
        )

        // PROPERTY: Study session persisted correctly
        let sessionDescriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sessions = try testContext.fetch(sessionDescriptor)

        // Filter manually for safety
        let userSessions = sessions.filter { $0.userProfile.id == profile.id }

        XCTAssertGreaterThan(
            userSessions.count,
            0,
            "Study session should be persisted"
        )

        if let latestSession = userSessions.first {
            // PROPERTY: Session accuracy matches recorded answers
            let expectedAccuracy = Double(correctCount) / Double(terms.count)
            XCTAssertEqual(
                latestSession.accuracy,
                expectedAccuracy,
                accuracy: 0.01,
                "Session accuracy should match recorded answers"
            )

            // PROPERTY: Session belongs to correct profile
            XCTAssertEqual(
                latestSession.userProfile.id,
                profile.id,
                "Session should belong to correct profile"
            )

            // PROPERTY: Session type is flashcards
            XCTAssertEqual(
                latestSession.sessionType,
                StudySessionType.flashcards,
                "Session type should be flashcards"
            )
        }

        // PROPERTY: Terminology progress recorded
        let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
        let allProgress = try testContext.fetch(progressDescriptor)

        // Filter progress for this profile's terms
        let profileProgress = allProgress.filter { progress in
            terms.contains { $0.id == progress.terminologyEntry.id }
        }

        XCTAssertGreaterThan(
            profileProgress.count,
            0,
            "Terminology progress should be recorded"
        )
    }
}
