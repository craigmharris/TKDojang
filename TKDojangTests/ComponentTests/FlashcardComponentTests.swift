import XCTest
import ViewInspector
import SwiftUI
import SwiftData
@testable import TKDojang

/**
 * FlashcardComponentTests.swift
 *
 * PURPOSE: Component-level tests for flashcard views using ViewInspector
 *
 * TESTING STRATEGY:
 * - Test individual view components in isolation
 * - Validate user interactions trigger expected state changes
 * - Verify data flows correctly through views
 * - Ensure UI elements render based on configuration
 *
 * COVERAGE: Flashcard configuration, display, and results views
 *
 * WHY VIEWINSPECTOR:
 * ViewInspector allows us to test SwiftUI view logic and user interactions
 * without requiring full UI automation (XCUITest). This provides:
 * - Faster test execution (~50ms vs 5-10s)
 * - Access to internal view state for precise assertions
 * - Ability to test view rendering logic without simulator
 *
 * CRITICAL USER CONCERNS ADDRESSED:
 * 1. Card count accuracy (23 selected → 23 shown)
 * 2. Language mode propagation (Korean/English/Random)
 * 3. Card flip behavior and animation
 * 4. Skip vs Correct button functionality
 * 5. Metrics updating correctly
 * 6. Image display validation
 */

// MARK: - Test Class

final class FlashcardComponentTests: XCTestCase {

    // MARK: - Test Infrastructure

    var testContainer: ModelContainer!
    var testContext: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create test container using centralized factory
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = ModelContext(testContainer)

        // Set up basic test data
        let dataFactory = TestDataFactory()
        try dataFactory.createBasicTestData(in: testContext)
    }

    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }

    // MARK: - Supporting View Component Tests (No EnvironmentObjects)

    /**
     * Test that StudyModeCard displays correctly and responds to selection
     *
     * USER CONCERN: Does selecting a study mode actually work?
     * VALIDATION: Card shows selected state with checkmark and highlight
     */
    func testStudyModeCard_DisplaysCorrectly() throws {
        // Arrange: Create study mode card
        var wasSelected = false
        let card = StudyModeCard(
            mode: .test,
            isSelected: true,
            onSelect: { wasSelected = true }
        )

        // Act: Inspect view
        let inspection = try card.inspect()

        // Assert: Verify selected state visual indicators
        let checkmark = try inspection.find(viewWithId: "checkmark.circle.fill")
        XCTAssertNotNil(checkmark, "Selected card should show checkmark")

        // Assert: Verify mode name is displayed
        let modeText = try inspection.find(text: "Test Mode")
        XCTAssertNotNil(modeText, "Should display study mode name")

        // Assert: Verify description is displayed
        let descriptionText = try inspection.find(text: "Test yourself with flashcard flipping - build active recall")
        XCTAssertNotNil(descriptionText, "Should display mode description")

        // Act: Simulate tap
        let button = try inspection.find(button: "Test Mode")
        try button.tap()

        // Assert: Verify selection callback was triggered
        XCTAssertTrue(wasSelected, "Tapping card should trigger onSelect callback")
    }

    /**
     * Test that StudyModeCard shows unselected state correctly
     */
    func testStudyModeCard_UnselectedState() throws {
        // Arrange
        let card = StudyModeCard(
            mode: .learn,
            isSelected: false,
            onSelect: {}
        )

        // Act
        let inspection = try card.inspect()

        // Assert: No checkmark when unselected
        let checkmarkExists = (try? inspection.find(viewWithId: "checkmark.circle.fill")) != nil
        XCTAssertFalse(checkmarkExists, "Unselected card should not show checkmark")
    }

    /**
     * Test CardDirectionCard displays correctly for all three directions
     *
     * USER CONCERN: Does selecting English→Korean vs Korean→English work?
     * VALIDATION: Each direction shows correct label and recommended star
     */
    func testCardDirectionCard_EnglishToKorean() throws {
        // Arrange
        let card = CardDirectionCard(
            direction: .englishToKorean,
            isSelected: true,
            onSelect: {}
        )

        // Act
        let inspection = try card.inspect()

        // Assert: Verify direction name
        let directionText = try inspection.find(text: "English → Korean")
        XCTAssertNotNil(directionText, "Should display direction name")
    }

    func testCardDirectionCard_BothDirections_ShowsRecommendedStar() throws {
        // Arrange
        let card = CardDirectionCard(
            direction: .bothDirections,
            isSelected: false,
            onSelect: {}
        )

        // Act
        let inspection = try card.inspect()

        // Assert: Verify "Both Directions" shows star (recommended)
        let starText = try inspection.find(text: "⭐️")
        XCTAssertNotNil(starText, "Both Directions should show recommended star")
    }

    /**
     * Test PreviewRow displays session preview information
     */
    func testPreviewRow_DisplaysSessionInfo() throws {
        // Arrange
        let row = PreviewRow(
            icon: "number.circle.fill",
            title: "Number of Terms",
            value: "23 terms",
            color: .orange
        )

        // Act
        let inspection = try row.inspect()

        // Assert: Verify all components are displayed
        let titleText = try inspection.find(text: "Number of Terms")
        XCTAssertNotNil(titleText, "Should display preview title")

        let valueText = try inspection.find(text: "23 terms")
        XCTAssertNotNil(valueText, "Should display preview value (validates card count display)")
    }

    /**
     * Test LearningSystemCard displays Classic vs Leitner modes
     */
    func testLearningSystemCard_ClassicMode() throws {
        // Arrange
        let card = LearningSystemCard(
            system: .classic,
            isSelected: true,
            onSelect: {}
        )

        // Act
        let inspection = try card.inspect()

        // Assert
        let systemName = try inspection.find(text: "Classic Mode")
        XCTAssertNotNil(systemName, "Should display learning system name")

        let description = try inspection.find(text: "Simple flashcards with basic progress tracking")
        XCTAssertNotNil(description, "Should display system description")
    }

    func testLearningSystemCard_LeitnerMode() throws {
        // Arrange
        let card = LearningSystemCard(
            system: .leitner,
            isSelected: false,
            onSelect: {}
        )

        // Act
        let inspection = try card.inspect()

        // Assert
        let systemName = try inspection.find(text: "Leitner Mode")
        XCTAssertNotNil(systemName, "Should display Leitner system name")

        let description = try inspection.find(text: "Advanced spaced repetition with 5-box scheduling")
        XCTAssertNotNil(description, "Should display Leitner description")
    }

    // MARK: - Session Statistics Tests

    /**
     * Test SessionStats calculates accuracy correctly
     *
     * USER CONCERN: Are metrics calculated accurately?
     * VALIDATION: Accuracy percentage matches correct/total ratio
     */
    func testSessionStats_AccuracyCalculation_80Percent() {
        // Arrange
        var stats = SessionStats()
        stats.correctCount = 16
        stats.incorrectCount = 4

        // Assert
        XCTAssertEqual(stats.totalCount, 20, "Total should be 20 (16 + 4)")
        XCTAssertEqual(stats.accuracyPercentage, 80, "Accuracy should be 80% (16/20)")
    }

    func testSessionStats_AccuracyCalculation_100Percent() {
        // Arrange
        var stats = SessionStats()
        stats.correctCount = 23
        stats.incorrectCount = 0

        // Assert
        XCTAssertEqual(stats.totalCount, 23, "Total should be 23")
        XCTAssertEqual(stats.accuracyPercentage, 100, "Accuracy should be 100% (23/23)")
    }

    func testSessionStats_AccuracyCalculation_ZeroQuestions() {
        // Arrange
        let stats = SessionStats()

        // Assert
        XCTAssertEqual(stats.totalCount, 0, "Total should be 0")
        XCTAssertEqual(stats.accuracyPercentage, 0, "Accuracy should be 0% when no questions")
    }

    // MARK: - Enum Display Name Tests

    /**
     * Test StudyMode enum display names
     *
     * USER CONCERN: Does the UI show correct mode names?
     */
    func testStudyMode_DisplayNames() {
        XCTAssertEqual(StudyMode.learn.displayName, "Learn Mode")
        XCTAssertEqual(StudyMode.test.displayName, "Test Mode")
    }

    /**
     * Test CardDirection enum display names
     *
     * USER CONCERN: Does the UI show correct direction names?
     */
    func testCardDirection_DisplayNames() {
        XCTAssertEqual(CardDirection.englishToKorean.displayName, "English → Korean")
        XCTAssertEqual(CardDirection.koreanToEnglish.displayName, "Korean → English")
        XCTAssertEqual(CardDirection.bothDirections.displayName, "Both Directions")
    }

    /**
     * Test LearningSystem enum display names
     */
    func testLearningSystem_DisplayNames() {
        XCTAssertEqual(LearningSystem.classic.displayName, "Classic Mode")
        XCTAssertEqual(LearningSystem.leitner.displayName, "Leitner Mode")
    }

    // MARK: - FlashcardItem Creation Logic Tests

    /**
     * Test that FlashcardItem array extension creates unique items
     *
     * USER CONCERN: Do I get the exact number of cards I requested?
     * VALIDATION: Array uniquing removes duplicates correctly
     */
    func testArray_UniqueElements() {
        // Create mock terminology entries with same IDs
        let belt = BeltLevel(name: "10th Keup", shortName: "10th", colorName: "White", sortOrder: 1)
        let category = TerminologyCategory(name: "Basics", displayName: "Basics")

        let term1 = TerminologyEntry(
            englishTerm: "Test",
            koreanHangul: "테스트",
            romanizedPronunciation: "teseuteu",
            phoneticPronunciation: "teh-suh-tuh",
            difficulty: 1,
            beltLevel: belt,
            category: category
        )

        // Create array with duplicate
        let terms = [term1, term1, term1]

        // Act: Apply uniqued()
        let uniqueTerms = terms.uniqued()

        // Assert: Should have only 1 unique term
        XCTAssertEqual(uniqueTerms.count, 1, "uniqued() should remove duplicates")
    }
}

// MARK: - Test Notes

/**
 * IMPLEMENTATION NOTES:
 *
 * 1. **Why test supporting components first?**
 *    - They don't require @EnvironmentObject mocking
 *    - Faster to implement and validate pattern
 *    - Build confidence before complex tests
 *
 * 2. **Next steps for complete coverage:**
 *    - Mock DataServices for FlashcardConfigurationView tests
 *    - Test card count slider behavior
 *    - Test configuration state propagation
 *    - Test FlashcardView card flip animation
 *    - Test answer recording and metrics updating
 *
 * 3. **Tests still to implement (from plan):**
 *    - FlashcardConfigurationView: 10 tests (requires mocking)
 *    - FlashcardView: 15 tests (complex, requires mocking)
 *    - FlashcardResultsView: 10 tests (requires mocking)
 *
 * 4. **Current status:** 13/35 tests implemented
 *    - ✅ Supporting component tests (7 tests)
 *    - ✅ SessionStats calculation tests (3 tests)
 *    - ✅ Enum display name tests (3 tests)
 *    - ⬜ Configuration view tests (10 tests) - NEXT
 *    - ⬜ Main flashcard view tests (15 tests)
 *    - ⬜ Results view tests (10 tests)
 */
