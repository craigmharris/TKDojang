import XCTest
@testable import TKDojang

/**
 * OnboardingCoordinatorTests.swift
 *
 * PURPOSE: Test the OnboardingCoordinator state management and tour logic
 *
 * COVERAGE:
 * - Initial tour state management
 * - Feature tour tracking per profile
 * - Tour completion and skip functionality
 * - Replay tour behavior
 */

@MainActor
class OnboardingCoordinatorTests: XCTestCase {

    var coordinator: OnboardingCoordinator!

    override func setUp() async throws {
        try await super.setUp()

        // Reset UserDefaults for clean state
        UserDefaults.standard.removeObject(forKey: "hasSeenInitialTour")
        UserDefaults.standard.removeObject(forKey: "tourSkippedDate")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        coordinator = OnboardingCoordinator()
    }

    override func tearDown() async throws {
        coordinator = nil

        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "hasSeenInitialTour")
        UserDefaults.standard.removeObject(forKey: "tourSkippedDate")
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        try await super.tearDown()
    }

    // MARK: - Initial Tour Tests

    func testShouldShowInitialTour_FirstLaunch() {
        // Given: Fresh app state
        // When: Checking if tour should show
        let shouldShow = coordinator.shouldShowInitialTour()

        // Then: Tour should show on first launch
        XCTAssertTrue(shouldShow, "Initial tour should show on first launch")
    }

    func testShouldShowInitialTour_AfterCompletion() {
        // Given: User completed the tour
        coordinator.completeInitialTour()

        // When: Checking if tour should show again
        let shouldShow = coordinator.shouldShowInitialTour()

        // Then: Tour should not show again
        XCTAssertFalse(shouldShow, "Initial tour should not show after completion")
    }

    func testShouldShowInitialTour_AfterSkip() {
        // Given: User skipped the tour
        coordinator.skipInitialTour()

        // When: Checking if tour should show again
        let shouldShow = coordinator.shouldShowInitialTour()

        // Then: Tour should not show again
        XCTAssertFalse(shouldShow, "Initial tour should not show after skip")
    }

    func testStartInitialTour() {
        // When: Starting initial tour
        coordinator.startInitialTour()

        // Then: Tour state should be active
        XCTAssertTrue(coordinator.showingInitialTour, "showingInitialTour should be true")
        XCTAssertEqual(coordinator.currentTourStep, 0, "Should start at step 0")
    }

    func testCompleteInitialTour() {
        // Given: Tour is showing
        coordinator.startInitialTour()

        // When: Completing the tour
        coordinator.completeInitialTour()

        // Then: Tour state should be inactive and marked complete
        XCTAssertFalse(coordinator.showingInitialTour, "showingInitialTour should be false")
        XCTAssertFalse(coordinator.shouldShowInitialTour(), "Tour should not show again")

        // And: hasCompletedOnboarding should be set
        let hasCompleted = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        XCTAssertTrue(hasCompleted, "hasCompletedOnboarding should be true")
    }

    func testSkipInitialTour() {
        // Given: Tour is showing
        coordinator.startInitialTour()

        // When: Skipping the tour
        coordinator.skipInitialTour()

        // Then: Tour state should be inactive and marked as seen
        XCTAssertFalse(coordinator.showingInitialTour, "showingInitialTour should be false")
        XCTAssertFalse(coordinator.shouldShowInitialTour(), "Tour should not show again after skip")
    }

    func testReplayInitialTour() {
        // Given: User completed the tour
        coordinator.completeInitialTour()
        XCTAssertFalse(coordinator.shouldShowInitialTour())

        // When: Replaying the tour
        coordinator.replayInitialTour()

        // Then: Tour should be available and showing
        XCTAssertTrue(coordinator.shouldShowInitialTour(), "Tour should be available after replay")
        XCTAssertTrue(coordinator.showingInitialTour, "showingInitialTour should be true")
        XCTAssertEqual(coordinator.currentTourStep, 0, "Should reset to step 0")
    }

    func testNavigateTourSteps() {
        // Given: Tour is active
        coordinator.startInitialTour()
        XCTAssertEqual(coordinator.currentTourStep, 0)

        // When: Moving to next step
        let canAdvance1 = coordinator.nextStep()

        // Then: Should advance
        XCTAssertTrue(canAdvance1, "Should be able to advance from step 0")
        XCTAssertEqual(coordinator.currentTourStep, 1)

        // When: Moving back
        let canGoBack = coordinator.previousStep()

        // Then: Should go back
        XCTAssertTrue(canGoBack, "Should be able to go back from step 1")
        XCTAssertEqual(coordinator.currentTourStep, 0)
    }

    func testNavigateTourSteps_Boundaries() {
        // Given: Tour at first step
        coordinator.startInitialTour()

        // When: Trying to go back from step 0
        let canGoBack = coordinator.previousStep()

        // Then: Should not be able to go back
        XCTAssertFalse(canGoBack, "Should not be able to go back from step 0")
        XCTAssertEqual(coordinator.currentTourStep, 0)

        // Given: Tour at last step
        coordinator.currentTourStep = coordinator.totalTourSteps - 1

        // When: Trying to advance from last step
        let canAdvance = coordinator.nextStep()

        // Then: Should not be able to advance
        XCTAssertFalse(canAdvance, "Should not be able to advance from last step")
        XCTAssertEqual(coordinator.currentTourStep, coordinator.totalTourSteps - 1)
    }

    // MARK: - Feature Tour Tests

    func testShouldShowFeatureTour_NewProfile() throws {
        // Given: A new profile with no tours completed
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)

        // When: Checking if feature tours should show
        let shouldShowFlashcards = coordinator.shouldShowFeatureTour(.flashcards, profile: profile)
        let shouldShowTesting = coordinator.shouldShowFeatureTour(.multipleChoice, profile: profile)

        // Then: All tours should show
        XCTAssertTrue(shouldShowFlashcards, "Flashcard tour should show for new profile")
        XCTAssertTrue(shouldShowTesting, "Testing tour should show for new profile")
    }

    func testCompleteFeatureTour() throws {
        // Given: A profile
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)

        // When: Completing a feature tour
        coordinator.completeFeatureTour(.flashcards, profile: profile)

        // Then: That tour should not show again
        XCTAssertFalse(
            coordinator.shouldShowFeatureTour(.flashcards, profile: profile),
            "Flashcard tour should not show after completion"
        )

        // But: Other tours should still show
        XCTAssertTrue(
            coordinator.shouldShowFeatureTour(.multipleChoice, profile: profile),
            "Other tours should still show"
        )

        // And: Completed tours should be persisted in profile
        XCTAssertTrue(
            profile.completedFeatureTours.contains("flashcards"),
            "Flashcards should be in completedFeatureTours"
        )
    }

    func testCompleteFeatureTour_Idempotent() throws {
        // Given: A profile with completed tour
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)
        coordinator.completeFeatureTour(.flashcards, profile: profile)

        let initialCount = profile.completedFeatureTours.count

        // When: Completing the same tour again
        coordinator.completeFeatureTour(.flashcards, profile: profile)

        // Then: Should not duplicate the entry
        XCTAssertEqual(
            profile.completedFeatureTours.count,
            initialCount,
            "Should not duplicate completed tour entries"
        )
    }

    func testResetFeatureTours() throws {
        // Given: A profile with completed tours
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)
        coordinator.completeFeatureTour(.flashcards, profile: profile)
        coordinator.completeFeatureTour(.multipleChoice, profile: profile)
        XCTAssertFalse(coordinator.shouldShowFeatureTour(.flashcards, profile: profile))

        // When: Resetting all feature tours
        coordinator.resetFeatureTours(for: profile)

        // Then: All tours should show again
        XCTAssertTrue(
            coordinator.shouldShowFeatureTour(.flashcards, profile: profile),
            "Tours should show after reset"
        )
        XCTAssertTrue(
            coordinator.shouldShowFeatureTour(.multipleChoice, profile: profile),
            "Tours should show after reset"
        )
        XCTAssertTrue(profile.completedFeatureTours.isEmpty, "completedFeatureTours should be empty")
    }

    func testResetSpecificFeatureTour() throws {
        // Given: A profile with multiple completed tours
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)
        coordinator.completeFeatureTour(.flashcards, profile: profile)
        coordinator.completeFeatureTour(.multipleChoice, profile: profile)

        // When: Resetting only one tour
        coordinator.resetFeatureTour(.flashcards, for: profile)

        // Then: That tour should show again
        XCTAssertTrue(
            coordinator.shouldShowFeatureTour(.flashcards, profile: profile),
            "Reset tour should show again"
        )

        // But: Other tours should still be marked complete
        XCTAssertFalse(
            coordinator.shouldShowFeatureTour(.multipleChoice, profile: profile),
            "Other tours should remain complete"
        )
    }

    // MARK: - Feature Tour Enum Tests

    func testFeatureTourEnumValues() {
        // Test all feature tour types are defined
        let allTours = OnboardingCoordinator.FeatureTour.allCases

        XCTAssertEqual(allTours.count, 5, "Should have 5 feature tours")
        XCTAssertTrue(allTours.contains(.flashcards))
        XCTAssertTrue(allTours.contains(.multipleChoice))
        XCTAssertTrue(allTours.contains(.patterns))
        XCTAssertTrue(allTours.contains(.stepSparring))
        XCTAssertTrue(allTours.contains(.patternTest))
    }

    func testFeatureTourDisplayNames() {
        // Test display names are set
        XCTAssertFalse(OnboardingCoordinator.FeatureTour.flashcards.title.isEmpty)
        XCTAssertFalse(OnboardingCoordinator.FeatureTour.multipleChoice.title.isEmpty)
        XCTAssertFalse(OnboardingCoordinator.FeatureTour.patterns.title.isEmpty)
        XCTAssertFalse(OnboardingCoordinator.FeatureTour.stepSparring.title.isEmpty)
        XCTAssertFalse(OnboardingCoordinator.FeatureTour.patternTest.title.isEmpty)
    }

    func testPatternTestTourSteps() {
        // Given: Pattern Test tour
        let tour = OnboardingCoordinator.FeatureTour.patternTest

        // When: Getting tour steps
        let steps = tour.tourSteps

        // Then: Should have 4 steps
        XCTAssertEqual(steps.count, 4, "Pattern Test tour should have 4 steps")

        // And: Each step should have required properties
        for (index, step) in steps.enumerated() {
            XCTAssertFalse(step.icon.isEmpty, "Step \(index) should have an icon")
            XCTAssertFalse(step.title.isEmpty, "Step \(index) should have a title")
            XCTAssertFalse(step.description.isEmpty, "Step \(index) should have a description")
        }

        // And: Tour metadata should be correct
        XCTAssertEqual(tour.title, "Pattern Test", "Title should be 'Pattern Test'")
        XCTAssertEqual(tour.estimatedMinutes, 2, "Should estimate 2 minutes")
        XCTAssertEqual(tour.helpButtonTitle, "How does pattern testing work?")
    }

    func testPatternTestTourCompletion() throws {
        // Given: A profile that hasn't seen the Pattern Test tour
        let testBelt = TestDataFactory().createBasicBeltLevels().first!
        let profile = UserProfile(name: "Test", currentBeltLevel: testBelt)

        // When: Checking if tour should show
        let shouldShowBefore = coordinator.shouldShowFeatureTour(.patternTest, profile: profile)

        // Then: Tour should show for new profile
        XCTAssertTrue(shouldShowBefore, "Pattern Test tour should show for new profile")

        // When: Completing the tour
        coordinator.completeFeatureTour(.patternTest, profile: profile)

        // Then: Tour should not show again
        let shouldShowAfter = coordinator.shouldShowFeatureTour(.patternTest, profile: profile)
        XCTAssertFalse(shouldShowAfter, "Pattern Test tour should not show after completion")

        // And: Should be persisted in profile
        XCTAssertTrue(
            profile.completedFeatureTours.contains("patternTest"),
            "patternTest should be in completedFeatureTours"
        )
    }
}
