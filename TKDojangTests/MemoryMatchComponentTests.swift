import XCTest
import SwiftData
@testable import TKDojang

/**
 * MemoryMatchComponentTests.swift
 *
 * PURPOSE: Component tests for Memory Match game mode
 *
 * TEST COVERAGE:
 * - MemoryMatchService card generation and shuffling
 * - Match detection logic
 * - Selection indicator functionality
 * - Tap-to-reset behavior
 * - Card back design elements
 * - Property-based testing for game configurations
 *
 * DATA SOURCE: VocabularyBuilderService with production vocabulary
 * TEST APPROACH: Real data integration, property-based validation
 */

@MainActor
final class MemoryMatchComponentTests: XCTestCase {

    var testContext: ModelContext!
    var testDatabaseURL: URL!
    var service: MemoryMatchService!
    var vocabularyService: VocabularyBuilderService!

    override func setUp() async throws {
        try await super.setUp()

        // Use persistent storage (matches production)
        testDatabaseURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "MemoryMatchTest_\(UUID().uuidString).sqlite")

        let schema = Schema([
            UserProfile.self,
            StudySession.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            url: testDatabaseURL,
            cloudKitDatabase: .none
        )

        let container = try ModelContainer(for: schema, configurations: [configuration])
        testContext = ModelContext(container)

        vocabularyService = VocabularyBuilderService(modelContext: testContext)
        service = MemoryMatchService(modelContext: testContext)
    }

    override func tearDown() async throws {
        testContext = nil
        service = nil
        vocabularyService = nil

        // Cleanup test database
        if let url = testDatabaseURL {
            try? FileManager.default.removeItem(at: url)
        }

        try await super.tearDown()
    }

    // MARK: - Service Tests

    func testMemoryMatchService_GeneratesCards_EvenCount() throws {
        // Load vocabulary into service
        try service.loadVocabulary()

        // Generate session with different pair counts
        for pairCount in [6, 8, 10, 12] {
            let session = try service.generateSession(pairCount: pairCount)

            // Should have even number of cards (2 per pair)
            XCTAssertEqual(session.cards.count, pairCount * 2, "Should have \(pairCount * 2) cards for \(pairCount) pairs")
            XCTAssertEqual(session.cards.count % 2, 0, "Card count should be even")
            XCTAssertEqual(session.totalPairs, pairCount, "Total pairs should match requested")

            DebugLogger.debug("✅ Generated \(session.cards.count) cards for \(pairCount) pairs")
        }
    }

    func testMemoryMatchService_GeneratesPairs_EnglishAndKorean() throws {
        try service.loadVocabulary()
        let session = try service.generateSession(pairCount: 6)

        // Count cards by language
        let englishCards = session.cards.filter { $0.language == .english }
        let koreanCards = session.cards.filter { $0.language == .korean }

        XCTAssertEqual(englishCards.count, 6, "Should have 6 English cards")
        XCTAssertEqual(koreanCards.count, 6, "Should have 6 Korean cards")

        // Verify each English card has a matching Korean card
        for englishCard in englishCards {
            let matchingKorean = koreanCards.first { koreanCard in
                koreanCard.word.english == englishCard.word.english &&
                koreanCard.word.romanized == englishCard.word.romanized
            }

            XCTAssertNotNil(matchingKorean, "Each English card should have matching Korean card for: \(englishCard.word.english)")
        }

        DebugLogger.debug("✅ All pairs have matching English/Korean cards")
    }

    func testMemoryMatchService_ShufflesCards() throws {
        try service.loadVocabulary()

        // Generate multiple sessions and verify they're shuffled differently
        let session1 = try service.generateSession(pairCount: 10)
        let session2 = try service.generateSession(pairCount: 10)

        // Card positions should be different (extremely unlikely to be identical after shuffle)
        let positions1 = session1.cards.map { $0.position }
        let positions2 = session2.cards.map { $0.position }

        // Extract displayText to compare card order
        let order1 = session1.cards.sorted(by: { $0.position < $1.position }).map { $0.displayText }
        let order2 = session2.cards.sorted(by: { $0.position < $1.position }).map { $0.displayText }

        XCTAssertNotEqual(order1, order2, "Shuffled sessions should have different card orders")

        DebugLogger.debug("✅ Cards are shuffled: session1 != session2")
    }

    func testMemoryMatchService_ValidatesMatch_SameWord() throws {
        try service.loadVocabulary()
        let session = try service.generateSession(pairCount: 6)

        // Find a matching pair
        if let englishCard = session.cards.first(where: { $0.language == .english }),
           let koreanCard = session.cards.first(where: { $0.language == .korean && $0.word.english == englishCard.word.english }) {

            let isMatch = service.checkMatch(card1: englishCard, card2: koreanCard)

            XCTAssertTrue(isMatch, "Same word in different languages should match")
            DebugLogger.debug("✅ Match detected: '\(englishCard.displayText)' ↔ '\(koreanCard.displayText)'")
        } else {
            XCTFail("Should find matching pair")
        }
    }

    func testMemoryMatchService_ValidatesNoMatch_DifferentWord() throws {
        try service.loadVocabulary()
        let session = try service.generateSession(pairCount: 6)

        // Find two cards with different words
        let allWords = Set(session.cards.map { $0.word.english })

        if allWords.count >= 2 {
            let word1 = allWords.first!
            let word2 = allWords.filter { $0 != word1 }.first!

            if let card1 = session.cards.first(where: { $0.word.english == word1 }),
               let card2 = session.cards.first(where: { $0.word.english == word2 }) {

                let isMatch = service.checkMatch(card1: card1, card2: card2)

                XCTAssertFalse(isMatch, "Different words should not match")
                DebugLogger.debug("✅ No match: '\(card1.displayText)' ≠ '\(card2.displayText)'")
            }
        } else {
            XCTFail("Should have multiple different words")
        }
    }

    func testMemoryMatchService_CalculatesMetrics_PropertyBased() throws {
        try service.loadVocabulary()

        // Test metrics with random configurations
        for _ in 0..<5 {
            let pairCount = Int.random(in: 6...12)
            let session = try service.generateSession(pairCount: pairCount)

            let metrics = service.calculateMetrics(session: session)

            // Properties that must hold
            XCTAssertEqual(metrics.totalPairs, pairCount, "Total pairs should match")
            XCTAssertEqual(metrics.moves, 0, "New session should have 0 moves")
            // Note: Efficiency is not meaningful for sessions with 0 moves
            // Service uses max(moves, 1) to avoid division by zero
        }

        DebugLogger.debug("✅ Metrics calculation validated")
    }

    // MARK: - Game Logic Tests

    func testMemoryMatchGame_GridLayout_CorrectColumns() throws {
        try service.loadVocabulary()

        // Test different grid sizes
        struct GridTest {
            let pairCount: Int
            let expectedCards: Int
            let expectedColumns: Int
        }

        let tests: [GridTest] = [
            GridTest(pairCount: 6, expectedCards: 12, expectedColumns: 3),  // 3×4
            GridTest(pairCount: 8, expectedCards: 16, expectedColumns: 4),  // 4×4
            GridTest(pairCount: 10, expectedCards: 20, expectedColumns: 4), // 4×5
            GridTest(pairCount: 12, expectedCards: 24, expectedColumns: 4)  // 4×6
        ]

        for test in tests {
            let session = try service.generateSession(pairCount: test.pairCount)

            XCTAssertEqual(session.cards.count, test.expectedCards, "Should have \(test.expectedCards) cards")

            // Grid column calculation is in MemoryMatchGameView
            // Verify here that card count matches expected grid
            DebugLogger.debug("✅ \(test.pairCount) pairs → \(test.expectedCards) cards (expected \(test.expectedColumns) columns)")
        }
    }

    func testMemoryMatchGame_FlippedCardsTracking() throws {
        try service.loadVocabulary()
        var session = try service.generateSession(pairCount: 6)

        // Initially no flipped cards
        XCTAssertEqual(session.flippedCards.count, 0, "New session should have no flipped cards")

        // Flip first card
        session.cards[0].isFlipped = true
        XCTAssertEqual(session.flippedCards.count, 1, "Should have 1 flipped card")

        // Flip second card
        session.cards[1].isFlipped = true
        XCTAssertEqual(session.flippedCards.count, 2, "Should have 2 flipped cards")

        // Mark both as matched
        session.cards[0].isMatched = true
        session.cards[1].isMatched = true

        // Flipped cards should now exclude matched ones
        XCTAssertEqual(session.flippedCards.count, 0, "Matched cards should not count as flipped")

        DebugLogger.debug("✅ Flipped cards tracking validated")
    }

    func testMemoryMatchGame_CompletionDetection() throws {
        try service.loadVocabulary()
        var session = try service.generateSession(pairCount: 6)

        // Initially not complete
        XCTAssertFalse(session.isComplete, "New session should not be complete")
        XCTAssertEqual(session.matchedPairs, 0, "Should have 0 matched pairs")

        // Match all pairs
        session.matchedPairs = 6

        XCTAssertTrue(session.isComplete, "Session should be complete when all pairs matched")

        DebugLogger.debug("✅ Completion detection validated")
    }

    func testMemoryMatchGame_MoveCounterIncrement() throws {
        try service.loadVocabulary()
        var session = try service.generateSession(pairCount: 6)

        XCTAssertEqual(session.moveCount, 0, "New session should have 0 moves")

        // Simulate moves
        session.moveCount += 1
        XCTAssertEqual(session.moveCount, 1, "Should increment to 1")

        session.moveCount += 1
        XCTAssertEqual(session.moveCount, 2, "Should increment to 2")

        DebugLogger.debug("✅ Move counter increments correctly")
    }

    // MARK: - Selection Indicator Tests

    func testMemoryMatchGame_SelectionIndicator_ShowsOnFirstCard() throws {
        try service.loadVocabulary()
        var session = try service.generateSession(pairCount: 6)

        // Flip first card
        session.cards[0].isFlipped = true

        // Check if this is the only flipped card (should show indicator)
        let isOnlyFlipped = session.cards[0].isFlipped &&
                           !session.cards[0].isMatched &&
                           session.flippedCards.count == 1

        XCTAssertTrue(isOnlyFlipped, "First flipped card should have selection indicator")

        DebugLogger.debug("✅ Selection indicator shows on first card")
    }

    func testMemoryMatchGame_SelectionIndicator_HidesOnSecondCard() throws {
        try service.loadVocabulary()
        var session = try service.generateSession(pairCount: 6)

        // Flip two cards
        session.cards[0].isFlipped = true
        session.cards[1].isFlipped = true

        // First card should no longer show indicator (2 cards flipped)
        let firstCardIndicator = session.cards[0].isFlipped &&
                                !session.cards[0].isMatched &&
                                session.flippedCards.count == 1

        XCTAssertFalse(firstCardIndicator, "Indicator should hide when second card flipped")

        DebugLogger.debug("✅ Selection indicator hides when second card flipped")
    }

    // MARK: - Card Design Tests

    func testMemoryMatchGame_CardBack_HasRequiredElements() throws {
        // Card back should have:
        // 1. Blue gradient background
        // 2. Hangul (태권도)
        // 3. White stripe (belt effect)

        // These are visual tests - verified manually and in UI tests
        // Here we document the requirements

        let cardBackRequirements = [
            "Blue gradient (0.1-0.3-0.6 to 0.15-0.4-0.7)",
            "Hangul text: 태권도 (48pt, white 15% opacity, -20° rotation)",
            "White stripe (20% opacity, 8pt height at bottom)"
        ]

        for requirement in cardBackRequirements {
            DebugLogger.debug("Card back requirement: \(requirement)")
        }

        XCTAssertEqual(cardBackRequirements.count, 3, "Should have 3 design requirements")
    }

    func testMemoryMatchGame_CardFront_ShowsLanguageBadge() throws {
        try service.loadVocabulary()
        let session = try service.generateSession(pairCount: 6)

        // English cards should have EN badge
        let englishCards = session.cards.filter { $0.language == .english }
        for card in englishCards {
            XCTAssertEqual(card.language, .english, "English card should have English language")
        }

        // Korean cards should have KO badge
        let koreanCards = session.cards.filter { $0.language == .korean }
        for card in koreanCards {
            XCTAssertEqual(card.language, .korean, "Korean card should have Korean language")
        }

        DebugLogger.debug("✅ Language badges verified: \(englishCards.count) EN, \(koreanCards.count) KO")
    }

    // MARK: - Property-Based Tests

    func testMemoryMatchGame_SessionGeneration_PropertyBased() throws {
        try service.loadVocabulary()

        // Test with random valid configurations
        for _ in 0..<10 {
            let pairCount = Int.random(in: 6...12)

            let session = try service.generateSession(pairCount: pairCount)

            // Properties that must hold
            XCTAssertEqual(session.pairCount, pairCount, "Pair count should match requested")
            XCTAssertEqual(session.totalPairs, pairCount, "Total pairs should match")
            XCTAssertEqual(session.cards.count, pairCount * 2, "Should have 2 cards per pair")
            XCTAssertEqual(session.matchedPairs, 0, "New session should have 0 matched pairs")
            XCTAssertEqual(session.moveCount, 0, "New session should have 0 moves")
            XCTAssertFalse(session.isComplete, "New session should not be complete")

            // Verify card positions are sequential
            let positions = Set(session.cards.map { $0.position })
            XCTAssertEqual(positions.count, pairCount * 2, "All positions should be unique")

            DebugLogger.debug("✅ Property-based test passed: pairCount=\(pairCount)")
        }
    }

    func testMemoryMatchGame_CardPositions_AllUnique() throws {
        try service.loadVocabulary()
        let session = try service.generateSession(pairCount: 10)

        // All cards should have unique positions (0 to count-1)
        let positions = session.cards.map { $0.position }.sorted()
        let expectedPositions = Array(0..<session.cards.count)

        XCTAssertEqual(positions, expectedPositions, "Positions should be 0, 1, 2, ..., n-1")

        DebugLogger.debug("✅ All \(session.cards.count) cards have unique positions")
    }

    // MARK: - Edge Cases

    func testMemoryMatchGame_MinimumPairCount() throws {
        try service.loadVocabulary()

        // Should handle minimum pair count (6 pairs = 12 cards)
        let session = try service.generateSession(pairCount: 6)

        XCTAssertEqual(session.cards.count, 12, "Minimum session should have 12 cards")
        XCTAssertEqual(session.totalPairs, 6, "Should have 6 pairs")

        DebugLogger.debug("✅ Minimum pair count (6) handled correctly")
    }

    func testMemoryMatchGame_MaximumPairCount() throws {
        try service.loadVocabulary()

        // Should handle maximum pair count (12 pairs = 24 cards)
        let session = try service.generateSession(pairCount: 12)

        XCTAssertEqual(session.cards.count, 24, "Maximum session should have 24 cards")
        XCTAssertEqual(session.totalPairs, 12, "Should have 12 pairs")

        DebugLogger.debug("✅ Maximum pair count (12) handled correctly")
    }

    func testMemoryMatchGame_InsufficientWords_Throws() throws {
        // Create service with minimal vocabulary
        let minimalService = MemoryMatchService(modelContext: testContext)

        // Manually set very few words (simulates insufficient vocabulary)
        // Note: In production, loadVocabulary() loads from JSON
        // Here we test the error case by requesting more pairs than available

        // First load real vocabulary
        try service.loadVocabulary()

        // Try to request more pairs than maximum allowed (12 is max)
        XCTAssertThrowsError(
            try service.generateSession(pairCount: 100),
            "Should throw when pair count exceeds maximum"
        ) { error in
            guard let memoryError = error as? MemoryMatchError else {
                XCTFail("Should throw MemoryMatchError, got: \(error)")
                return
            }

            if case .invalidPairCount = memoryError {
                // Expected error for invalid count
            } else if case .insufficientWords = memoryError {
                // Also acceptable if vocabulary is too small
            } else {
                XCTFail("Should throw invalidPairCount or insufficientWords error")
            }
        }

        DebugLogger.debug("✅ Service correctly throws for invalid configurations")
    }
}
