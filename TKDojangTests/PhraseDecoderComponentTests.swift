import XCTest
import SwiftData
@testable import TKDojang

/**
 * PhraseDecoderComponentTests.swift
 *
 * PURPOSE: Component tests for Phrase Decoder game mode
 *
 * TEST COVERAGE:
 * - TechniquePhraseLoader data loading from JSON
 * - PhraseDecoderService session generation
 * - Validation logic correctness
 * - Property-based testing for configuration
 *
 * DATA SOURCE: Production JSON files (blocks.json, kicks.json, strikes.json, hand_techniques.json)
 * TEST APPROACH: Real data integration, property-based validation
 */

@MainActor
final class PhraseDecoderComponentTests: XCTestCase {

    var testContext: ModelContext!
    var testDatabaseURL: URL!
    var service: PhraseDecoderService!

    override func setUp() async throws {
        try await super.setUp()

        // Use persistent storage (matches production, required for multi-level @Model)
        testDatabaseURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "PhraseDecoderTest_\(UUID().uuidString).sqlite")

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

        service = PhraseDecoderService(modelContext: testContext)
    }

    override func tearDown() async throws {
        testContext = nil
        service = nil

        // Cleanup test database
        if let url = testDatabaseURL {
            try? FileManager.default.removeItem(at: url)
        }

        try await super.tearDown()
    }

    // MARK: - Data Model Tests

    func testTechniquePhraseLoader_LoadsAllTechniques() throws {
        // Load all techniques from production JSON
        let techniques = try TechniquePhraseLoader.loadAllTechniques()

        // Should load techniques from all 4 categories
        XCTAssertGreaterThan(techniques.count, 50, "Should load 50+ techniques from all JSON files")

        // Verify all categories represented
        let categories = Set(techniques.map { $0.category })
        XCTAssertTrue(categories.contains(.blocks), "Should load blocks")
        XCTAssertTrue(categories.contains(.kicks), "Should load kicks")
        XCTAssertTrue(categories.contains(.strikes), "Should load strikes")
        XCTAssertTrue(categories.contains(.handTechniques), "Should load hand techniques")

        DebugLogger.debug("✅ Loaded \(techniques.count) techniques from production JSON")
    }

    func testTechniquePhraseLoader_LoadsFromBlocks() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()
        let blocks = techniques.filter { $0.category == .blocks }

        XCTAssertGreaterThan(blocks.count, 0, "Should load block techniques")

        // Verify structure
        if let firstBlock = blocks.first {
            XCTAssertFalse(firstBlock.english.isEmpty, "English name should not be empty")
            XCTAssertFalse(firstBlock.koreanRomanized.isEmpty, "Korean romanization should not be empty")
            XCTAssertGreaterThan(firstBlock.englishWords.count, 0, "Should have English words")
            XCTAssertGreaterThan(firstBlock.koreanWords.count, 0, "Should have Korean words")
        }

        DebugLogger.debug("✅ Loaded \(blocks.count) block techniques")
    }

    func testTechniquePhraseLoader_LoadsFromKicks() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()
        let kicks = techniques.filter { $0.category == .kicks }

        XCTAssertGreaterThan(kicks.count, 0, "Should load kick techniques")

        DebugLogger.debug("✅ Loaded \(kicks.count) kick techniques")
    }

    func testTechniquePhraseLoader_LoadsFromStrikes() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()
        let strikes = techniques.filter { $0.category == .strikes }

        XCTAssertGreaterThan(strikes.count, 0, "Should load strike techniques")

        DebugLogger.debug("✅ Loaded \(strikes.count) strike techniques")
    }

    func testTechniquePhraseLoader_LoadsFromHandTechniques() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()
        let handTechniques = techniques.filter { $0.category == .handTechniques }

        XCTAssertGreaterThan(handTechniques.count, 0, "Should load hand techniques")

        DebugLogger.debug("✅ Loaded \(handTechniques.count) hand techniques")
    }

    func testTechniquePhraseLoader_WordArrays_SplitCorrectly() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()

        for technique in techniques {
            // English and Korean should have same word count
            XCTAssertEqual(
                technique.englishWords.count,
                technique.koreanWords.count,
                "English and Korean word counts should match for: \(technique.english)"
            )

            // Word arrays should match original strings
            let reconstructedEnglish = technique.englishWords.joined(separator: " ")
            XCTAssertEqual(reconstructedEnglish, technique.english, "English word array should reconstruct original")

            let reconstructedKorean = technique.koreanWords.joined(separator: " ")
            XCTAssertEqual(reconstructedKorean, technique.koreanRomanized, "Korean word array should reconstruct original")
        }

        DebugLogger.debug("✅ All \(techniques.count) techniques have correctly split word arrays")
    }

    func testTechniquePhraseLoader_WordCount_CalculatesCorrectly() throws {
        let techniques = try TechniquePhraseLoader.loadAllTechniques()

        for technique in techniques {
            let expectedCount = technique.english.components(separatedBy: " ").count
            XCTAssertEqual(technique.wordCount, expectedCount, "Word count should match for: \(technique.english)")
            XCTAssertEqual(technique.englishWords.count, expectedCount)
            XCTAssertEqual(technique.koreanWords.count, expectedCount)
        }

        DebugLogger.debug("✅ All techniques have correct word counts")
    }

    func testTechniquePhraseLoader_FiltersByWordCount() throws {
        let allTechniques = try TechniquePhraseLoader.loadAllTechniques()

        // Test filtering for different word counts
        for targetWordCount in 2...5 {
            let filtered = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: targetWordCount)

            for technique in filtered {
                XCTAssertEqual(
                    technique.wordCount,
                    targetWordCount,
                    "Filtered technique should have \(targetWordCount) words: \(technique.english)"
                )
            }

            DebugLogger.debug("✅ Found \(filtered.count) techniques with \(targetWordCount) words")
        }
    }

    // MARK: - Service Tests

    func testPhraseDecoderService_LoadsTechniquesFromJSON() throws {
        // Service should load techniques from production JSON
        try service.loadTechniques()

        // Verify techniques loaded (checked internally via session generation)
        // This is validated by attempting to generate a session
        let session = try service.generateSession(wordCount: 3, phraseCount: 5)

        XCTAssertEqual(session.totalChallenges, 5, "Session should have requested number of challenges")
        XCTAssertEqual(session.challenges.count, 5, "Should generate requested challenges")

        DebugLogger.debug("✅ Service loaded techniques and generated session")
    }

    func testPhraseDecoderService_FiltersByWordCount() throws {
        try service.loadTechniques()

        // Generate sessions with different word counts
        for wordCount in 2...5 {
            let session = try service.generateSession(wordCount: wordCount, phraseCount: 5)

            for challenge in session.challenges {
                XCTAssertEqual(
                    challenge.correctEnglish.count,
                    wordCount,
                    "Challenge should have \(wordCount) words in English"
                )
                XCTAssertEqual(
                    challenge.correctKorean.count,
                    wordCount,
                    "Challenge should have \(wordCount) words in Korean"
                )
                XCTAssertEqual(
                    challenge.technique.wordCount,
                    wordCount,
                    "Technique should have \(wordCount) words"
                )
            }

            DebugLogger.debug("✅ All challenges have \(wordCount) words")
        }
    }

    func testPhraseDecoderService_GeneratesSession_WithSufficientTechniques() throws {
        try service.loadTechniques()

        // Should successfully generate when sufficient techniques available
        let session = try service.generateSession(wordCount: 3, phraseCount: 10)

        XCTAssertEqual(session.wordCount, 3)
        XCTAssertEqual(session.totalChallenges, 10)
        XCTAssertEqual(session.challenges.count, 10)
        XCTAssertEqual(session.currentChallengeIndex, 0)
        XCTAssertFalse(session.isComplete)

        // Verify start time is recent
        XCTAssertLessThan(Date().timeIntervalSince(session.startTime), 1.0)

        DebugLogger.debug("✅ Session generated successfully with 10 challenges")
    }

    func testPhraseDecoderService_GeneratesSession_ThrowsWhenInsufficient() throws {
        try service.loadTechniques()

        // Should throw when requesting more phrases than available
        XCTAssertThrowsError(
            try service.generateSession(wordCount: 3, phraseCount: 1000),
            "Should throw when insufficient techniques available"
        ) { error in
            guard let decoderError = error as? PhraseDecoderError else {
                XCTFail("Should throw PhraseDecoderError")
                return
            }

            if case .insufficientTechniques = decoderError {
                // Expected error type
            } else {
                XCTFail("Should throw insufficientTechniques error")
            }
        }

        DebugLogger.debug("✅ Service correctly throws error for insufficient techniques")
    }

    func testPhraseDecoderService_ScramblesTechniques_DifferentFromOriginal() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 10)

        var allScrambledDifferent = true

        for challenge in session.challenges {
            // For phrases with 3+ words, scrambling should usually produce different order
            let englishScrambledDifferent = challenge.scrambledEnglish != challenge.correctEnglish
            let koreanScrambledDifferent = challenge.scrambledKorean != challenge.correctKorean

            // At least one language should be scrambled (unless unlucky random)
            if !englishScrambledDifferent && !koreanScrambledDifferent {
                allScrambledDifferent = false
            }
        }

        // With 10 challenges of 3 words each, at least some should be scrambled
        XCTAssertTrue(
            allScrambledDifferent || session.challenges.count == 1,
            "Most challenges should have scrambled word order"
        )

        DebugLogger.debug("✅ Challenges are scrambled from original order")
    }

    func testPhraseDecoderService_ScramblesBothLanguages() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 4, phraseCount: 5)

        for challenge in session.challenges {
            // Verify both languages have scrambled arrays
            XCTAssertEqual(challenge.scrambledEnglish.count, 4, "Scrambled English should have 4 words")
            XCTAssertEqual(challenge.scrambledKorean.count, 4, "Scrambled Korean should have 4 words")

            // Verify arrays contain same words (just reordered)
            let correctEnglishSet = Set(challenge.correctEnglish)
            let scrambledEnglishSet = Set(challenge.scrambledEnglish)
            XCTAssertEqual(correctEnglishSet, scrambledEnglishSet, "Scrambled should contain same English words")

            let correctKoreanSet = Set(challenge.correctKorean)
            let scrambledKoreanSet = Set(challenge.scrambledKorean)
            XCTAssertEqual(correctKoreanSet, scrambledKoreanSet, "Scrambled should contain same Korean words")
        }

        DebugLogger.debug("✅ Both languages scrambled correctly")
    }

    func testPhraseDecoderService_ValidatesCorrectOrder() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 1)
        let challenge = session.challenges[0]

        // Test English validation
        let englishResult = service.validatePhrase(
            userWords: challenge.correctEnglish,
            challenge: challenge,
            language: .english
        )

        XCTAssertTrue(englishResult.isCorrect, "Correct English order should validate")
        XCTAssertEqual(englishResult.correctPositions.count, 3, "All positions should be correct")
        XCTAssertTrue(englishResult.feedback.contains("Perfect"), "Feedback should indicate success")

        // Test Korean validation
        let koreanResult = service.validatePhrase(
            userWords: challenge.correctKorean,
            challenge: challenge,
            language: .korean
        )

        XCTAssertTrue(koreanResult.isCorrect, "Correct Korean order should validate")
        XCTAssertEqual(koreanResult.correctPositions.count, 3, "All positions should be correct")

        DebugLogger.debug("✅ Correct phrase order validates successfully")
    }

    func testPhraseDecoderService_ValidatesPartialCorrectness() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 1)
        let challenge = session.challenges[0]

        // Create partially correct order (swap last two words)
        var partiallyCorrect = challenge.correctEnglish
        if partiallyCorrect.count >= 2 {
            partiallyCorrect.swapAt(1, 2)
        }

        let result = service.validatePhrase(
            userWords: partiallyCorrect,
            challenge: challenge,
            language: .english
        )

        XCTAssertFalse(result.isCorrect, "Partially correct should not fully validate")
        XCTAssertGreaterThan(result.correctPositions.count, 0, "Should have some correct positions")
        XCTAssertLessThan(result.correctPositions.count, challenge.correctEnglish.count, "Should not be fully correct")
        XCTAssertTrue(result.feedback.contains("position"), "Feedback should mention positions")

        DebugLogger.debug("✅ Partial correctness detected: \(result.correctPositions.count)/\(challenge.correctEnglish.count) correct")
    }

    func testPhraseDecoderService_CalculatesMetrics_PropertyBased() throws {
        try service.loadTechniques()

        // Test metrics calculation with random session configurations
        for _ in 0..<5 {
            let phraseCount = Int.random(in: 5...10)
            let session = try service.generateSession(wordCount: 3, phraseCount: phraseCount)

            let metrics = service.calculateMetrics(session: session)

            // Properties that must hold
            XCTAssertEqual(metrics.totalChallenges, phraseCount, "Total challenges should match session size")
            XCTAssertEqual(metrics.totalAttempts, 0, "New session should have 0 attempts")
            XCTAssertEqual(metrics.averageAttempts, 0.0, accuracy: 0.01, "New session should have 0 average attempts")
        }

        DebugLogger.debug("✅ Metrics calculation validated with property-based testing")
    }

    // MARK: - Property-Based Tests

    func testPhraseDecoderService_SessionGeneration_PropertyBased() throws {
        try service.loadTechniques()

        // Test with random valid configurations
        for _ in 0..<10 {
            let wordCount = Int.random(in: 2...5)
            let phraseCount = Int.random(in: 5...15)

            // Only test if sufficient techniques available
            let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
            let filtered = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: wordCount)

            guard filtered.count >= phraseCount else {
                DebugLogger.debug("⏭️ Skipping test: insufficient techniques for wordCount=\(wordCount), phraseCount=\(phraseCount)")
                continue
            }

            let session = try service.generateSession(wordCount: wordCount, phraseCount: phraseCount)

            // Properties that must hold for ANY valid configuration
            XCTAssertEqual(session.wordCount, wordCount, "Session word count should match requested")
            XCTAssertEqual(session.totalChallenges, phraseCount, "Total challenges should match requested")
            XCTAssertEqual(session.challenges.count, phraseCount, "Should generate requested number of challenges")

            for challenge in session.challenges {
                XCTAssertEqual(challenge.correctEnglish.count, wordCount, "English phrase should have correct word count")
                XCTAssertEqual(challenge.correctKorean.count, wordCount, "Korean phrase should have correct word count")
                XCTAssertEqual(challenge.scrambledEnglish.count, wordCount, "Scrambled English should have correct word count")
                XCTAssertEqual(challenge.scrambledKorean.count, wordCount, "Scrambled Korean should have correct word count")
            }

            DebugLogger.debug("✅ Property-based test passed: wordCount=\(wordCount), phraseCount=\(phraseCount)")
        }
    }

    func testPhraseDecoderService_SessionGeneration_UniquePhrases() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 10)

        // Challenges should use different techniques (no duplicates)
        let techniqueIds = session.challenges.map { $0.technique.id }
        let uniqueIds = Set(techniqueIds)

        XCTAssertEqual(
            techniqueIds.count,
            uniqueIds.count,
            "All challenges should use unique techniques (no duplicates)"
        )

        DebugLogger.debug("✅ Session has \(uniqueIds.count) unique techniques")
    }
}
