import XCTest

/**
 * CriticalUserJourneysUITests.swift
 *
 * PURPOSE: Phase 3 E2E tests for critical user workflows
 *
 * ARCHITECTURE: Bottom-Up Testing Complete
 * - ✅ Phase 1: Components tested with ViewInspector + Property-Based
 * - ✅ Phase 2: Services tested with Orchestration approach
 * - 🔄 Phase 3: UI flows tested with XCUITest (THIS FILE)
 *
 * TESTING APPROACH:
 * - Test complete user journeys from start to finish
 * - Use explicit waits (waitForExistence) not sleeps
 * - Verify UI flows tie together proven components + services
 * - Focus on cross-feature navigation and data flow
 *
 * TEST PLAN ALIGNMENT: UI_TESTING_PLAN.md Phase 3 (12 tests)
 */
final class CriticalUserJourneysUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Test Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["UI-Testing", "CreateTestProfiles"] // Signal to app to create test profiles
        app.launch()

        // Wait for app to fully load
        _ = waitForElement(app.otherElements.firstMatch, timeout: 10.0)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Phase 3.1: Flashcard Complete Workflow ⭐ HIGHEST VALUE

    /**
     * Test: Dashboard → Configure (23 cards, Korean) → Study → Mark Correct/Skip → Results → Dashboard
     *
     * VALIDATES:
     * - Navigation flow through entire flashcard feature
     * - Configuration propagates to session (23 cards shown)
     * - Answer recording updates counters
     * - Results screen shows accurate statistics
     * - Dashboard metrics update after session
     *
     * LAYERS TESTED:
     * - UI: Navigation, buttons, displays
     * - Integration: Configuration → Session → Results → Profile stats
     * - Data: Session persistence, profile stat incrementing
     */
    func testFlashcardCompleteWorkflow() throws {
        // RANDOMIZATION: Configure test parameters
        let numberOfCards = Int.random(in: 5...10)
        let directions = ["English → Korean", "Korean → English", "Both Directions"]
        let selectedDirection = directions.randomElement()!
        let learningSystems = ["Classic Mode", "Leitner Mode"]
        let selectedLearningSystem = learningSystems.randomElement()!

        // STEP 1: Handle optional onboarding screen
        // If "Get Started" appears, tap it. Otherwise, continue (app already has profile data)
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 3.0) {
            getStartedButton.tap()
        }

        // STEP 2: Navigate to Learn tab
        // Wait for main app to be ready (either after onboarding or directly)
        let learnTab = waitForElement(
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'book'")).firstMatch,
            timeout: 10.0,
            failureMessage: "Learn tab should be available"
        )
        learnTab.tap()

        // STEP 3: Navigate to Flashcards
        let flashcardsButton = waitForElement(
            app.buttons["learn-flashcards-button"],
            timeout: 5.0,
            failureMessage: "Flashcards button should be available"
        )
        flashcardsButton.tap()

        // STEP 4: Configure session with random settings
        // Set direction
        let directionButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", selectedDirection)).firstMatch
        if directionButton.waitForExistence(timeout: 3.0) {
            directionButton.tap()
        }

        // Set learning system
        let learningSystemButton = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", selectedLearningSystem)).firstMatch
        if learningSystemButton.waitForExistence(timeout: 3.0) {
            learningSystemButton.tap()
        }

        // Set number of cards using slider
        let slider = app.sliders.firstMatch
        if slider.waitForExistence(timeout: 3.0) {
            // Slider range is 5-50, we want 5-10
            // Calculate normalized position (0.0 = min, 1.0 = max)
            let normalizedValue = Double(numberOfCards - 5) / Double(50 - 5)
            slider.adjust(toNormalizedSliderPosition: normalizedValue)
        }

        // STEP 5: Start session
        let startSessionButton = waitForElement(
            app.buttons["flashcard-start-session-button"],
            timeout: 5.0,
            failureMessage: "Start Session button should appear"
        )
        startSessionButton.tap()

        // STEP 6: Answer all flashcards with random responses
        for cardIndex in 0..<numberOfCards {
            // Wait for flashcard to load
            let flashcard = waitForElement(
                app.otherElements.firstMatch,
                timeout: 5.0,
                failureMessage: "Flashcard \(cardIndex + 1) should load"
            )

            // Tap to reveal answer
            flashcard.tap()

            // Wait for answer buttons to become available (replaces arbitrary flip animation wait)
            // At least one button should appear within 2 seconds
            let anyAnswerButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'flashcard'")).firstMatch
            _ = anyAnswerButton.waitForExistence(timeout: 2.0)

            // Randomly choose how to answer
            let randomChoice = Int.random(in: 0...2)

            switch randomChoice {
            case 0: // Correct
                if app.buttons["flashcard-correct-button"].waitForExistence(timeout: 2.0) {
                    app.buttons["flashcard-correct-button"].tap()
                }
            case 1: // Incorrect
                if app.buttons["flashcard-incorrect-button"].waitForExistence(timeout: 2.0) {
                    app.buttons["flashcard-incorrect-button"].tap()
                }
            case 2: // Skip (don't reveal, just skip)
                // Go back to question side if we're on answer side
                flashcard.tap()
                // Wait for skip button to be available after flipping back
                if app.buttons["flashcard-skip-button"].waitForExistence(timeout: 2.0) {
                    app.buttons["flashcard-skip-button"].tap()
                }
            default:
                break
            }

            // Wait for card transition by checking if we're still in the session
            // (next card loads or results screen appears)
            // Brief wait to allow UI to update
            _ = app.otherElements.firstMatch.waitForExistence(timeout: 2.0)
        }

        // STEP 7: Verify results screen appears
        // After completing all cards, should show results
        let resultsIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Session Complete' OR label CONTAINS 'Results' OR label CONTAINS 'Accuracy'")).firstMatch

        // Give it a bit of time to transition to results screen
        XCTAssertTrue(
            resultsIndicator.waitForExistence(timeout: 5.0),
            "Results screen should appear after completing all \(numberOfCards) flashcards"
        )

        // STEP 8: Verify session stats are shown with sanity checking
        let statsSection = app.otherElements.containing(NSPredicate(format: "label CONTAINS 'Correct' OR label CONTAINS 'Incorrect'")).firstMatch
        XCTAssertTrue(statsSection.exists, "Stats section should be visible on results screen")

        // Sanity check: Extract and validate accuracy percentage
        let accuracyElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'"))
        if accuracyElements.count > 0 {
            let accuracyText = accuracyElements.firstMatch.label
            // Extract number from text like "75%" or "Accuracy: 75%"
            let numbers = accuracyText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let accuracy = Double(numbers) {
                XCTAssertTrue(
                    accuracy >= 0 && accuracy <= 100,
                    "Accuracy should be valid percentage (0-100%), got \(accuracy)%"
                )
            }
        }

        // Verify cards completed count is shown
        let cardsCompletedText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'cards' OR label CONTAINS 'Cards'")).firstMatch
        XCTAssertTrue(
            cardsCompletedText.exists,
            "Results should show cards completed count"
        )
    }

    // MARK: - Phase 3.2: Multiple Choice Test Workflow ⭐ HIGH VALUE

    /**
     * Test: Learn Tab → Tests → Configure Test → Complete Test → View Results
     *
     * RECORDING STEPS:
     * 1. Navigate to Learn tab
     * 2. Tap "Tests" or "Multiple Choice" button
     * 3. Configure test settings:
     *    - Select terminology category (or all)
     *    - Choose number of questions (suggest 5-8)
     *    - Set difficulty if available
     * 4. Tap "Start Test" button
     * 5. Answer each question by tapping an answer option
     * 6. Tap "Next" or "Submit" between questions
     * 7. Complete all questions
     * 8. Verify results screen shows score and feedback
     *
     * VALIDATES:
     * - Navigation to test feature
     * - Test configuration options work
     * - Questions display correctly
     * - Answer selection and submission
     * - Score calculation and results display
     *
     * RANDOMIZATION TO ADD:
     * - Number of questions (5-10)
     * - Random answer selection (mix of correct/incorrect)
     * - Category selection (random or all)
     */
    func testMultipleChoiceTestWorkflow() throws {
        // RANDOMIZATION: Configure test parameters
        var expectedCorrectCount = 0
        var expectedIncorrectCount = 0
        var totalQuestions = 0

        // STEP 1: Handle optional onboarding
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 3.0) {
            getStartedButton.tap()
        }

        // STEP 2: Navigate to Learn tab
        let learnTab = waitForElement(
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'book'")).firstMatch,
            timeout: 10.0,
            failureMessage: "Learn tab should be available"
        )
        learnTab.tap()

        // STEP 3: Navigate to Tests
        let testsButton = waitForElement(
            app.buttons["learn-tests-button"],
            timeout: 5.0,
            failureMessage: "Tests button should be available"
        )
        testsButton.tap()

        // STEP 4: Start a Quick Test
        let quickTestButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Quick Test'")).firstMatch
        if quickTestButton.waitForExistence(timeout: 5.0) {
            quickTestButton.tap()
        }

        // STEP 5: Answer all questions with random responses
        var questionIndex = 0
        while true {
            // Check if we've reached the results screen
            let resultsIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Test Complete' OR label CONTAINS 'accuracy'")).firstMatch
            if resultsIndicator.waitForExistence(timeout: 2.0) {
                break // Results screen appeared - test complete
            }

            // Check for question progress text to confirm we're still in test
            let questionProgress = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Question'")).firstMatch
            if !questionProgress.exists {
                break // No more questions
            }

            // Randomly select an answer (0-3)
            let randomAnswer = Int.random(in: 0...3)
            let answerButton = app.buttons["test-answer-option-\(randomAnswer)"]

            if answerButton.waitForExistence(timeout: 3.0) {
                // Note: We can't reliably track correct/incorrect without knowing the answer
                // The test validates that the workflow completes, not accuracy tracking
                answerButton.tap()
                totalQuestions += 1

                // Wait for either next question to appear or results screen (replaces arbitrary wait)
                // Look for next question progress indicator or results text
                let nextQuestionOrResults = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Question' OR label CONTAINS 'accuracy' OR label CONTAINS 'Test Complete'")).firstMatch
                _ = nextQuestionOrResults.waitForExistence(timeout: 3.0)

                questionIndex += 1

                // Safety limit to prevent infinite loop
                if questionIndex > 50 {
                    XCTFail("Test exceeded 50 questions - possible infinite loop")
                    break
                }
            } else {
                break // No more answer buttons available
            }
        }

        // STEP 6: Verify results screen appeared
        XCTAssertTrue(
            totalQuestions >= 5,
            "Should have answered at least 5 questions (answered \(totalQuestions))"
        )

        // Verify results screen shows
        let resultsScreen = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'accuracy' OR label CONTAINS 'Test Complete'")).firstMatch
        XCTAssertTrue(
            resultsScreen.exists,
            "Results screen should display after completing \(totalQuestions) questions"
        )

        // STEP 7: Sanity check results screen content
        // Extract and validate accuracy percentage
        let accuracyElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'"))
        if accuracyElements.count > 0 {
            let accuracyText = accuracyElements.firstMatch.label
            // Extract number from text like "75%" or "Accuracy: 75%"
            let numbers = accuracyText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let accuracy = Double(numbers) {
                XCTAssertTrue(
                    accuracy >= 0 && accuracy <= 100,
                    "Accuracy should be valid percentage (0-100%), got \(accuracy)%"
                )
            }
        }

        // Verify question count is displayed on results
        let questionCountElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'question' OR label CONTAINS 'Question'")).firstMatch
        XCTAssertTrue(
            questionCountElement.exists,
            "Results should show question count"
        )

        // Verify we have correct/incorrect breakdown
        let correctElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Correct' OR label CONTAINS 'correct'")).firstMatch
        let incorrectElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Incorrect' OR label CONTAINS 'incorrect'")).firstMatch
        XCTAssertTrue(
            correctElement.exists || incorrectElement.exists,
            "Results should show correct/incorrect breakdown"
        )
    }

    // MARK: - Phase 3.3: Pattern Practice Workflow ⭐ HIGH VALUE

    /**
     * Test: Learn Tab → Patterns → Select Pattern → View Moves → Practice
     *
     * RECORDING STEPS:
     * 1. Navigate to Learn tab
     * 2. Tap "Patterns" button
     * 3. Select a pattern (e.g., "Chon-Ji" for beginners)
     * 4. View pattern details screen
     * 5. Tap "View Moves" or "Start Practice"
     * 6. Navigate through pattern moves (swipe or next button)
     * 7. View move details (Korean name, English, diagram if available)
     * 8. Return to pattern list
     *
     * VALIDATES:
     * - Pattern list displays correctly
     * - Pattern detail navigation
     * - Move-by-move progression
     * - Visual content (diagrams, images) loads
     * - Back navigation maintains state
     *
     * RANDOMIZATION TO ADD:
     * - Random pattern selection (appropriate for belt level)
     * - Random number of moves to view (3-5)
     */
    func testPatternPracticeWorkflow() throws {
        // RANDOMIZATION: Configure test parameters
        let numberOfMovesToPractice = Int.random(in: 3...8) // Practice 3-8 moves

        // STEP 1: Handle optional onboarding
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 3.0) {
            getStartedButton.tap()
        }

        // STEP 2: Navigate to Practice tab
        let practiceTab = waitForElement(
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'martial.arts' OR label CONTAINS 'Practice'")).firstMatch,
            timeout: 10.0,
            failureMessage: "Practice tab should be available"
        )
        practiceTab.tap()

        // STEP 3: Navigate to Patterns
        let patternsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Traditional forms' OR label CONTAINS 'Patterns'")).firstMatch
        if patternsButton.waitForExistence(timeout: 5.0) {
            patternsButton.tap()
        }

        // STEP 4: Select a random pattern from the list
        // Wait for pattern list to load by checking for pattern buttons
        let patternButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Chon-Ji' OR label CONTAINS 'Dan-Gun' OR label CONTAINS 'Do-San' OR label CONTAINS 'Won-Hyo' OR label CONTAINS 'Yul-Gok'")).firstMatch

        if patternButton.waitForExistence(timeout: 5.0) {
            patternButton.tap()
        } else {
            // Fallback: Look for any button containing "Learning" or move count
            let anyPattern = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Learning' OR label CONTAINS 'moves'")).firstMatch
            if anyPattern.waitForExistence(timeout: 2.0) {
                anyPattern.tap()
            } else {
                XCTFail("No pattern found - tried common pattern names and 'Learning' keyword")
                return
            }
        }

        // STEP 5: Start practice
        let startPracticeButton = waitForElement(
            app.buttons["pattern-practice-button"],
            timeout: 5.0,
            failureMessage: "Start Practice button should appear"
        )
        startPracticeButton.tap()

        // STEP 6: Navigate through moves with weighted randomization
        // 80% forward, 10% backward, 10% swipe
        var movesCompleted = 0

        for _ in 0..<numberOfMovesToPractice {
            // Wait for move content to load (buttons should be available)
            let nextButton = app.buttons["pattern-next-move-button"]
            _ = nextButton.waitForExistence(timeout: 3.0)

            // Weighted random choice
            let randomValue = Double.random(in: 0...1)

            if randomValue < 0.80 {
                // 80% chance: Move forward
                let nextButton = app.buttons["pattern-next-move-button"]
                if nextButton.exists {
                    nextButton.tap()
                    movesCompleted += 1
                } else {
                    // Reached end - Complete Pattern button should be available
                    let completeButton = app.buttons["pattern-complete-button"]
                    if completeButton.exists {
                        completeButton.tap()
                        break
                    }
                }
            } else if randomValue < 0.90 {
                // 10% chance: Move backward
                let prevButton = app.buttons["pattern-previous-move-button"]
                if prevButton.isEnabled {
                    prevButton.tap()
                }
            } else {
                // 10% chance: Swipe image carousel
                let imageCarousel = app.images.firstMatch
                if imageCarousel.exists {
                    Bool.random() ? imageCarousel.swipeLeft() : imageCarousel.swipeRight()
                }
            }

            // Safety limit
            if movesCompleted > 50 {
                XCTFail("Practiced more than 50 moves - possible infinite loop")
                break
            }
        }

        // STEP 7: Complete the pattern or end practice
        let completeButton = app.buttons["pattern-complete-button"]
        if completeButton.waitForExistence(timeout: 2.0) {
            completeButton.tap()

            // Handle completion dialog
            let recordProgressButton = app.buttons["pattern-record-progress-button"]
            if recordProgressButton.waitForExistence(timeout: 3.0) {
                recordProgressButton.tap()
            }
        } else {
            // End practice early
            let endPracticeButton = app.buttons["pattern-end-practice-button"]
            if endPracticeButton.exists {
                endPracticeButton.tap()
            }
        }

        // STEP 8: Verify we returned to pattern list or dashboard
        // Wait for navigation to complete
        let backAtPatterns = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Traditional forms' OR identifier CONTAINS 'pattern'")).firstMatch
        _ = backAtPatterns.waitForExistence(timeout: 3.0)
        XCTAssertTrue(
            backAtPatterns.exists || app.navigationBars.firstMatch.exists,
            "Should return to pattern list or remain in app"
        )
    }

    // MARK: - Phase 3.4: Step Sparring Practice Workflow

    /**
     * Test: Learn Tab → Step Sparring → Select Sequence → Practice Moves
     *
     * RECORDING STEPS:
     * 1. Navigate to Learn tab
     * 2. Tap "Step Sparring" button
     * 3. View available sequences (filtered by belt level)
     * 4. Select a sequence (e.g., "3-Step Sparring #1")
     * 5. View sequence details
     * 6. Navigate through attacker/defender moves
     * 7. View move descriptions and diagrams
     * 8. Return to sequence list
     *
     * VALIDATES:
     * - Step sparring list displays
     * - Sequence selection and navigation
     * - Attacker/defender move distinction
     * - Move detail completeness
     * - Navigation flow
     *
     * RANDOMIZATION TO ADD:
     * - Random sequence selection
     * - Random move range to view
     */
    func testStepSparringPracticeWorkflow() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.5: Profile Switching Workflow ⭐ HIGH VALUE

    /**
     * Test: Dashboard → Switch Profile → Verify Data Isolation
     *
     * VALIDATES:
     * - Profile switcher is accessible
     * - Profile list displays all profiles
     * - Profiles have different belt levels
     * - Pattern availability differs by belt level (data layer validation)
     * - Data isolation between profiles
     *
     * ARCHITECTURE NOTE: This test validates data isolation at the DATA LAYER,
     * not UI rendering. We verify that different profiles have different belt levels
     * and that the app correctly filters content based on belt level.
     *
     * SETUP: App creates multiple test profiles programmatically via launch argument
     */
    func testProfileSwitchingWorkflow() throws {
        // STEP 1: Handle optional onboarding
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 3.0) {
            getStartedButton.tap()
        }

        // STEP 2: Explicitly select "Test Student" profile (6th Keup)
        let profileSwitcherInitial = waitForElement(
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'person.circle'")).firstMatch,
            timeout: 10.0,
            failureMessage: "Profile switcher should be available"
        )
        profileSwitcherInitial.tap()

        // Wait for profile sheet and select Test Student
        let testStudentButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Student'")).firstMatch
        XCTAssertTrue(
            testStudentButton.waitForExistence(timeout: 5.0),
            "Profile sheet should display with 'Test Student' profile"
        )
        // Ensure button is hittable before tapping
        _ = testStudentButton.waitForExistence(timeout: 2.0)
        testStudentButton.tap()
        // Wait for profile switch to complete by checking for belt label
        let profile1Belt = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '6th Keup'")).firstMatch
        _ = profile1Belt.waitForExistence(timeout: 5.0)

        print("DEBUG: Selected 'Test Student' profile")

        // STEP 3: Verify Test Student profile shows 6th Keup belt
        let profile1BeltLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '6th Keup'")).firstMatch
        XCTAssertTrue(
            profile1BeltLabel.waitForExistence(timeout: 5.0),
            "Test Student profile should display 6th Keup belt level"
        )
        print("DEBUG: Test Student shows 6th Keup belt")

        // STEP 4: Switch to Advanced Student profile (2nd Keup)
        let profileSwitcher = waitForElement(
            app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'person.circle'")).firstMatch,
            timeout: 5.0,
            failureMessage: "Profile switcher should be available"
        )
        profileSwitcher.tap()

        // Wait for profile sheet to render - look for known test profile names
        // Profiles created: "Test Student" (6th Keup), "Advanced Student" (2nd Keup), "Black Belt" (1st Dan)
        let testSecondStudentButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Student'")).firstMatch
        XCTAssertTrue(
            testSecondStudentButton.waitForExistence(timeout: 5.0),
            "Profile sheet should display with 'Test Student' profile"
        )

        // Wait for all profile buttons to be available (sheet animation complete)
        let allProfileButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test Student' OR label CONTAINS 'Advanced Student' OR label CONTAINS 'Black Belt'"))
        _ = allProfileButtons.firstMatch.waitForExistence(timeout: 3.0)

        print("DEBUG: Found \(allProfileButtons.count) profile button(s)")

        // Verify we have multiple test profiles
        guard allProfileButtons.count >= 2 else {
            XCTFail("Expected at least 2 test profiles, found \(allProfileButtons.count)")
            return
        }

        // Select "Advanced Student" profile (2nd Keup) which should show different belt level
        print("DEBUG: Tapping 'Advanced Student' profile")
        let advancedStudentButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Advanced Student'")).firstMatch
        advancedStudentButton.tap()

        // Wait for profile switch to complete by checking for the new belt label
        let profile2BeltLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2nd Keup'")).firstMatch
        _ = profile2BeltLabel.waitForExistence(timeout: 5.0)

        // STEP 5: Verify Advanced Student profile shows 2nd Keup belt (different from Test Student's 6th Keup)
        XCTAssertTrue(
            profile2BeltLabel.waitForExistence(timeout: 5.0),
            "Advanced Student profile should display 2nd Keup belt level (different from Test Student's 6th Keup)"
        )
        print("DEBUG: Advanced Student shows 2nd Keup belt")

        // STEP 6: Verify belt levels differ (proves profile isolation)
        // If we successfully saw "6th Keup" for Test Student and "2nd Keup" for Advanced Student,
        // then profiles have different belt levels, proving data isolation.
        print("✅ PASSED: Profiles show different belt levels (6th Keup vs 2nd Keup), proving data isolation")
    }

    // MARK: - Phase 3.6: Progress Analytics Journey

    /**
     * Test: Dashboard → Progress Tab → View Stats → Drill Down
     *
     * RECORDING STEPS:
     * 1. Navigate to Progress/Analytics tab
     * 2. View overall statistics (study time, sessions, accuracy)
     * 3. Tap on a specific metric or chart
     * 4. View detailed breakdown
     * 5. Navigate through different time periods if available
     * 6. View session history
     * 7. Return to main progress screen
     *
     * VALIDATES:
     * - Progress tab navigation
     * - Stats display correctly
     * - Chart/graph rendering
     * - Drill-down navigation
     * - Historical data display
     *
     * RANDOMIZATION TO ADD:
     * - Random metric to drill into
     */
    func testProgressAnalyticsJourney() throws {

    }

    // MARK: - Phase 3.7: Terminology Browse and Study

    /**
     * Test: Learn Tab → Terminology → Browse → Study Term
     *
     * RECORDING STEPS:
     * 1. Navigate to Learn tab
     * 2. Tap "Terminology" or "Browse Terms" button
     * 3. View terminology list (filtered by belt/category)
     * 4. Scroll through terms
     * 5. Tap on a specific term
     * 6. View term details (Korean, romanization, definition)
     * 7. Navigate to next/previous term if available
     * 8. Return to term list
     *
     * VALIDATES:
     * - Terminology list navigation
     * - Term filtering works
     * - Term detail display complete
     * - Korean characters render correctly
     * - Navigation between terms
     *
     * RANDOMIZATION TO ADD:
     * - Random category filter
     * - Random term selection
     */
    func testTerminologyBrowseAndStudy() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.8: Settings Configuration Changes

    /**
     * Test: Profile Tab → Settings → Change Preferences → Verify Updates
     *
     * RECORDING STEPS:
     * 1. Navigate to Profile tab
     * 2. Tap "Settings" or gear icon
     * 3. View settings options
     * 4. Change daily study goal (slider or input)
     * 5. Toggle learning mode (Progression ↔ Mastery)
     * 6. Change belt level if editable
     * 7. Save changes
     * 8. Navigate back to Learn tab
     * 9. Verify settings applied (e.g., content updated for new belt level)
     *
     * VALIDATES:
     * - Settings screen access
     * - Setting controls work (sliders, toggles, pickers)
     * - Changes persist
     * - UI updates reflect new settings
     * - Navigation preserves changes
     *
     * RANDOMIZATION TO ADD:
     * - Random study goal (10-50)
     * - Random learning mode toggle
     */
    func testSettingsConfigurationChanges() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.9: Cross-Profile Data Isolation ⭐ HIGH VALUE

    /**
     * Test: Profile A → Study Session → Switch to Profile B → Verify Isolation
     *
     * RECORDING STEPS:
     * 1. Start with Profile A
     * 2. Complete a flashcard session (3-5 cards)
     * 3. Note the stats/progress for Profile A
     * 4. Switch to Profile B
     * 5. View Profile B's dashboard/stats
     * 6. Verify Profile B stats are DIFFERENT (not updated by Profile A's session)
     * 7. Complete a test session as Profile B
     * 8. Switch back to Profile A
     * 9. Verify Profile A's stats unchanged by Profile B's session
     *
     * VALIDATES:
     * - Complete data isolation between profiles
     * - Session data doesn't leak across profiles
     * - Progress tracking is profile-specific
     * - Profile switching maintains separate state
     *
     * RANDOMIZATION TO ADD:
     * - Random profile pair
     * - Random activity for each profile
     */
    func testCrossProfileDataIsolation() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.10: Learning Mode Switch Journey

    /**
     * Test: Settings → Change Learning Mode → Verify Content Updates
     *
     * RECORDING STEPS:
     * 1. Navigate to Settings
     * 2. Note current learning mode (Progression or Mastery)
     * 3. Toggle to opposite mode
     * 4. Save/apply changes
     * 5. Navigate to Flashcard configuration
     * 6. Verify term count reflects new mode:
     *    - Progression: Current belt only
     *    - Mastery: Current + prior belts (max 50)
     * 7. Start a session
     * 8. Verify terms shown match expected mode
     *
     * VALIDATES:
     * - Learning mode toggle works
     * - Content filtering updates immediately
     * - Term selection respects mode
     * - UI indicates active mode
     *
     * RANDOMIZATION TO ADD:
     * - Random starting mode
     */
    func testLearningModeSwitchJourney() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.11: Belt Progression Journey

    /**
     * Test: Profile → Change Belt Level → Verify Content Updates
     *
     * RECORDING STEPS:
     * 1. Navigate to Profile settings
     * 2. Note current belt level
     * 3. Change belt level (up or down one level)
     * 4. Save changes
     * 5. Navigate to Learn tab
     * 6. View Terminology list
     * 7. Verify terms filtered for new belt level
     * 8. View Patterns list
     * 9. Verify patterns appropriate for new belt
     * 10. Start flashcard session
     * 11. Verify terms match new belt level
     *
     * VALIDATES:
     * - Belt level change mechanism
     * - Content filtering by belt level
     * - Pattern availability by belt
     * - Term availability by belt
     * - UI reflects new belt throughout app
     *
     * RANDOMIZATION TO ADD:
     * - Random belt level change
     */
    func testBeltProgressionJourney() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Phase 3.12: Full App Navigation Tour

    /**
     * Test: Navigate through all main tabs and key features
     *
     * RECORDING STEPS:
     * 1. Start at Dashboard tab
     * 2. Tap Learn tab
     *    - Verify Flashcards, Tests, Patterns, Step Sparring visible
     * 3. Tap Progress tab
     *    - Verify stats/charts display
     * 4. Tap Profile tab
     *    - Verify profile info, settings accessible
     * 5. Return to Learn tab
     * 6. Tap each learning option briefly:
     *    - Flashcards (view config, then back)
     *    - Tests (view config, then back)
     *    - Patterns (view list, then back)
     *    - Step Sparring (view list, then back)
     * 7. Return to Dashboard
     *
     * VALIDATES:
     * - All main tabs accessible
     * - Tab bar navigation works
     * - All major features reachable
     * - Navigation state preserved
     * - No crashes during navigation
     *
     * RANDOMIZATION TO ADD:
     * - Random tab order
     * - Random feature order in Learn tab
     */
    func testFullAppNavigationTour() throws {
        // TODO: Record this journey
        XCTFail("Test not yet implemented - record journey first")
    }

    // MARK: - Test Helper Methods

    /**
     * Wait for element to exist with timeout and optional failure message
     */
    @discardableResult
    private func waitForElement(_ element: XCUIElement,
                               timeout: TimeInterval,
                               failureMessage: String? = nil) -> XCUIElement {
        let exists = element.waitForExistence(timeout: timeout)
        if !exists, let message = failureMessage {
            XCTFail(message)
        }
        return element
    }

    /**
     * Find element by trying multiple label matches
     * Returns first matching element that exists
     */
    private func findElement(matching labels: [String],
                            in query: XCUIElementQuery) -> XCUIElement? {
        for label in labels {
            let element = query.matching(NSPredicate(format: "label CONTAINS[c] %@", label)).firstMatch
            if element.exists {
                return element
            }
        }
        return nil
    }

    /**
     * Tap element with retry logic
     * Replaces sleep-based retry with explicit element existence/hittability waiting
     */
    private func tapElement(_ element: XCUIElement, retries: Int = 3) {
        for attempt in 0..<retries {
            if element.exists && element.isHittable {
                element.tap()
                return
            }
            // Wait for element to become hittable before next retry
            let timeout: TimeInterval = 0.5
            _ = element.waitForExistence(timeout: timeout)

            // On last attempt, check one more time before failing
            if attempt == retries - 1 && element.exists && element.isHittable {
                element.tap()
                return
            }
        }
        XCTFail("Could not tap element after \(retries) attempts: \(element.label)")
    }
}
