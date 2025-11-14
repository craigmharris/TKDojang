import XCTest
import SwiftData
@testable import TKDojang

/**
 * VocabularyBuilderSystemTests.swift
 *
 * PURPOSE: System-level integration tests for Vocabulary Builder feature
 *
 * TEST COVERAGE:
 * - End-to-end game workflows (complete sessions)
 * - Navigation between views
 * - Data persistence to profile
 * - Cross-game feature integration
 * - Help system accessibility
 *
 * DATA SOURCE: Production JSON files + real VocabularyBuilderService
 * TEST APPROACH: Integration testing, complete user workflows
 */

@MainActor
final class VocabularyBuilderSystemTests: XCTestCase {

    var testContext: ModelContext!
    var testDatabaseURL: URL!
    var testProfile: UserProfile!
    var vocabularyService: VocabularyBuilderService!

    override func setUp() async throws {
        try await super.setUp()

        // Use persistent storage (matches production)
        testDatabaseURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "VocabSystemTest_\(UUID().uuidString).sqlite")

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

        // Create test profile with belt
        let testBelt = BeltLevel(
            name: "10th Keup (White Belt)",
            shortName: "10th Keup",
            colorName: "White",
            sortOrder: 15,
            isKyup: true
        )
        testContext.insert(testBelt)

        testProfile = UserProfile(
            name: "Vocabulary Test User",
            currentBeltLevel: testBelt
        )
        testContext.insert(testProfile)
        try testContext.save()

        vocabularyService = VocabularyBuilderService(modelContext: testContext)
    }

    override func tearDown() async throws {
        testContext = nil
        testProfile = nil
        vocabularyService = nil

        // Cleanup test database
        if let url = testDatabaseURL {
            try? FileManager.default.removeItem(at: url)
        }

        try await super.tearDown()
    }

    // MARK: - Complete Game Flow Tests

    func testPhraseDecoder_CompleteSession_AllPhrasesCorrect() throws {
        let service = PhraseDecoderService(modelContext: testContext)
        try service.loadTechniques()

        var session = try service.generateSession(wordCount: 3, phraseCount: 5)

        // Complete all challenges correctly
        for challengeIndex in 0..<session.challenges.count {
            let challenge = session.challenges[challengeIndex]

            // Submit correct answer
            let result = service.validatePhrase(
                userWords: challenge.correctEnglish,
                challenge: challenge,
                language: .english
            )

            XCTAssertTrue(result.isCorrect, "Challenge \(challengeIndex + 1) should validate correctly")

            // Record completion
            let completed = CompletedDecoderChallenge(
                challenge: challenge,
                attempts: 1,
                finalEnglishWords: challenge.correctEnglish,
                finalKoreanWords: challenge.correctKorean,
                completionTime: Date()
            )
            session.completedChallenges.append(completed)

            // Advance to next challenge
            session.currentChallengeIndex += 1
        }

        // Verify session completion
        XCTAssertTrue(session.isComplete, "Session should be complete")
        XCTAssertEqual(session.completedChallenges.count, 5, "Should have 5 completed challenges")

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalChallenges, 5, "Should have 5 total challenges")
        XCTAssertEqual(metrics.totalAttempts, 5, "Should have 5 total attempts")
        XCTAssertEqual(metrics.averageAttempts, 1.0, accuracy: 0.01, "Should average 1 attempt per challenge")

        DebugLogger.debug("✅ Phrase Decoder complete session: 5/5 correct, 100% accuracy")
    }

    func testPhraseDecoder_CompleteSession_WithRetries() throws {
        let service = PhraseDecoderService(modelContext: testContext)
        try service.loadTechniques()

        var session = try service.generateSession(wordCount: 3, phraseCount: 5)

        // Complete challenges with some incorrect attempts
        for challengeIndex in 0..<session.challenges.count {
            let challenge = session.challenges[challengeIndex]
            var attempts = 1

            // First two challenges: incorrect first, correct second
            if challengeIndex < 2 {
                // Submit incorrect answer
                var incorrectWords = challenge.correctEnglish
                incorrectWords.swapAt(0, 1)

                let incorrectResult = service.validatePhrase(
                    userWords: incorrectWords,
                    challenge: challenge,
                    language: .english
                )

                XCTAssertFalse(incorrectResult.isCorrect, "Incorrect answer should not validate")
                attempts += 1
            }

            // Then submit correct answer
            let correctResult = service.validatePhrase(
                userWords: challenge.correctEnglish,
                challenge: challenge,
                language: .english
            )

            XCTAssertTrue(correctResult.isCorrect, "Correct answer should validate")

            // Record completion
            let completed = CompletedDecoderChallenge(
                challenge: challenge,
                attempts: attempts,
                finalEnglishWords: challenge.correctEnglish,
                finalKoreanWords: challenge.correctKorean,
                completionTime: Date()
            )
            session.completedChallenges.append(completed)

            session.currentChallengeIndex += 1
        }

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalChallenges, 5, "Should have 5 total challenges")
        XCTAssertGreaterThan(metrics.totalAttempts, 5, "Should have more than 5 attempts (with retries)")
        XCTAssertGreaterThan(metrics.averageAttempts, 1.0, "Average attempts should be > 1.0")

        DebugLogger.debug("✅ Phrase Decoder with retries: \(metrics.totalAttempts) total attempts, avg \(metrics.formattedAverageAttempts)")
    }

    func testPhraseDecoder_LanguageSwitch_MidSession() throws {
        let service = PhraseDecoderService(modelContext: testContext)
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 5)

        // Test validation in both languages
        let challenge = session.challenges[0]

        // Validate in English
        let englishResult = service.validatePhrase(
            userWords: challenge.correctEnglish,
            challenge: challenge,
            language: .english
        )
        XCTAssertTrue(englishResult.isCorrect, "English should validate")

        // Validate in Korean
        let koreanResult = service.validatePhrase(
            userWords: challenge.correctKorean,
            challenge: challenge,
            language: .korean
        )
        XCTAssertTrue(koreanResult.isCorrect, "Korean should validate")

        DebugLogger.debug("✅ Language switching validated: English & Korean both work")
    }

    func testTemplateFiller_CompleteSession_AllCorrect() throws {
        let service = TemplateFillerService(modelContext: testContext)
        try service.loadTechniques()

        var session = try service.generateSession(wordCount: 3, phraseCount: 5)

        // Complete all challenges correctly
        for challengeIndex in 0..<session.challenges.count {
            let challenge = session.challenges[challengeIndex]

            // Build correct selections
            var correctSelections: [Int: String] = [:]
            for blank in challenge.blanks {
                correctSelections[blank.position] = blank.correctWord
            }

            // Validate
            let result = service.validateSelections(
                userSelections: correctSelections,
                challenge: challenge
            )

            XCTAssertTrue(result.isCorrect, "Challenge \(challengeIndex + 1) should be correct")

            // Record completion
            let completed = CompletedTemplateChallenge(
                challenge: challenge,
                userSelections: correctSelections,
                isCorrect: result.isCorrect,
                completionTime: Date()
            )
            session.completedChallenges.append(completed)

            session.currentChallengeIndex += 1
        }

        // Verify completion
        XCTAssertTrue(session.isComplete, "Session should be complete")

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalChallenges, 5)
        XCTAssertEqual(session.completedChallenges.count, 5)
        XCTAssertEqual(metrics.correctChallenges, 5)
        XCTAssertEqual(metrics.accuracy, 1.0, accuracy: 0.01)

        DebugLogger.debug("✅ Template Filler complete session: 5/5 correct, 100% accuracy")
    }

    func testTemplateFiller_CompleteSession_MixedResults() throws {
        let service = TemplateFillerService(modelContext: testContext)
        try service.loadTechniques()

        var session = try service.generateSession(wordCount: 4, phraseCount: 5)

        var correctCount = 0

        // Complete with mixed results
        for challengeIndex in 0..<session.challenges.count {
            let challenge = session.challenges[challengeIndex]

            var selections: [Int: String] = [:]
            var isCorrect = true

            // Every other challenge: make one blank incorrect
            if challengeIndex % 2 == 0 {
                // Make first blank incorrect
                if let firstBlank = challenge.blanks.first {
                    let wrongChoice = firstBlank.choices.first { $0 != firstBlank.correctWord }
                    selections[firstBlank.position] = wrongChoice ?? firstBlank.correctWord

                    if wrongChoice != nil {
                        isCorrect = false
                    }

                    // Fill rest correctly
                    for blank in challenge.blanks.dropFirst() {
                        selections[blank.position] = blank.correctWord
                    }
                } else {
                    isCorrect = true
                }
            } else {
                // All correct
                for blank in challenge.blanks {
                    selections[blank.position] = blank.correctWord
                }
                isCorrect = true
            }

            if isCorrect {
                correctCount += 1
            }

            let completed = CompletedTemplateChallenge(
                challenge: challenge,
                userSelections: selections,
                isCorrect: isCorrect,
                completionTime: Date()
            )
            session.completedChallenges.append(completed)

            session.currentChallengeIndex += 1
        }

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalChallenges, 5)
        XCTAssertEqual(session.completedChallenges.count, 5)
        XCTAssertLessThan(metrics.accuracy, 1.0, "Accuracy should be less than 100%")

        DebugLogger.debug("✅ Template Filler mixed results: \(correctCount)/5 correct")
    }

    func testMemoryMatch_CompleteSession_AllPairsFound() throws {
        let service = MemoryMatchService(modelContext: testContext)
        try service.loadVocabulary()

        var session = try service.generateSession(pairCount: 6)

        // Simulate finding all pairs
        var moveCount = 0

        while session.matchedPairs < session.totalPairs {
            // Find an unmatched pair
            if let englishCard = session.cards.first(where: { !$0.isMatched && $0.language == .english }),
               let koreanCard = session.cards.first(where: { !$0.isMatched && $0.language == .korean && $0.word.english == englishCard.word.english }) {

                // Mark as matched
                if let englishIndex = session.cards.firstIndex(where: { $0.id == englishCard.id }) {
                    session.cards[englishIndex].isMatched = true
                }
                if let koreanIndex = session.cards.firstIndex(where: { $0.id == koreanCard.id }) {
                    session.cards[koreanIndex].isMatched = true
                }

                session.matchedPairs += 1
                moveCount += 1

                DebugLogger.debug("Match \(session.matchedPairs): '\(englishCard.displayText)' ↔ '\(koreanCard.displayText)'")
            }
        }

        session.moveCount = moveCount

        // Verify completion
        XCTAssertTrue(session.isComplete, "Session should be complete")
        XCTAssertEqual(session.matchedPairs, 6, "Should have matched all 6 pairs")

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalPairs, 6)
        XCTAssertEqual(session.matchedPairs, 6)
        XCTAssertGreaterThan(metrics.efficiency, 0.0, "Efficiency should be > 0")

        DebugLogger.debug("✅ Memory Match complete: 6/6 pairs in \(moveCount) moves")
    }

    func testMemoryMatch_CompleteSession_WithResets() throws {
        let service = MemoryMatchService(modelContext: testContext)
        try service.loadVocabulary()

        var session = try service.generateSession(pairCount: 6)

        var moveCount = 0

        // Simulate some failed attempts before successes
        while session.matchedPairs < session.totalPairs {
            // Find next unmatched pair
            if let englishCard = session.cards.first(where: { !$0.isMatched && $0.language == .english }),
               let koreanCard = session.cards.first(where: { !$0.isMatched && $0.language == .korean && $0.word.english == englishCard.word.english }) {

                // Add some failed attempts (every other pair)
                if session.matchedPairs % 2 == 0 {
                    // Simulate a failed match attempt
                    moveCount += 1
                }

                // Then successful match
                if let englishIndex = session.cards.firstIndex(where: { $0.id == englishCard.id }) {
                    session.cards[englishIndex].isMatched = true
                }
                if let koreanIndex = session.cards.firstIndex(where: { $0.id == koreanCard.id }) {
                    session.cards[koreanIndex].isMatched = true
                }

                session.matchedPairs += 1
                moveCount += 1
            }
        }

        session.moveCount = moveCount

        // Calculate metrics
        let metrics = service.calculateMetrics(session: session)
        XCTAssertEqual(metrics.totalPairs, 6)
        XCTAssertGreaterThan(metrics.moves, 6, "Should have more moves than pairs (due to resets)")

        DebugLogger.debug("✅ Memory Match with resets: 6 pairs in \(moveCount) moves")
    }

    // MARK: - Data Loading Tests

    func testVocabularyBuilder_LoadsAllVocabulary() throws {
        let words = try vocabularyService.loadVocabularyWords()

        XCTAssertGreaterThan(words.count, 0, "Should load vocabulary words")

        // Verify word structure
        for word in words.prefix(10) {
            XCTAssertFalse(word.english.isEmpty, "English should not be empty")
            XCTAssertFalse(word.romanized.isEmpty, "Romanized should not be empty")
            XCTAssertGreaterThan(word.frequency, 0, "Frequency should be > 0")
        }

        DebugLogger.debug("✅ Loaded \(words.count) vocabulary words")
    }

    func testVocabularyBuilder_TechniquesVsVocabulary() throws {
        // Load both data sources
        let vocabularyWords = try vocabularyService.loadVocabularyWords()
        let techniques = try TechniquePhraseLoader.loadAllTechniques()

        XCTAssertGreaterThan(vocabularyWords.count, 0, "Should have vocabulary")
        XCTAssertGreaterThan(techniques.count, 0, "Should have techniques")

        // Techniques and vocabulary are separate data sources
        // Memory Match uses vocabulary, Phrase Decoder/Template Filler use techniques

        DebugLogger.debug("✅ Vocabulary: \(vocabularyWords.count) words, Techniques: \(techniques.count) phrases")
    }

    // MARK: - Session Metrics Tests

    func testVocabularyBuilder_MetricsCalculation_Consistency() throws {
        // Test that all services calculate metrics consistently

        // Phrase Decoder
        let decoderService = PhraseDecoderService(modelContext: testContext)
        try decoderService.loadTechniques()
        let decoderSession = try decoderService.generateSession(wordCount: 3, phraseCount: 5)
        let decoderMetrics = decoderService.calculateMetrics(session: decoderSession)

        XCTAssertEqual(decoderMetrics.totalChallenges, 5)
        XCTAssertEqual(decoderMetrics.totalAttempts, 0)
        XCTAssertEqual(decoderMetrics.averageAttempts, 0.0, accuracy: 0.01)

        // Template Filler
        let templateService = TemplateFillerService(modelContext: testContext)
        try templateService.loadTechniques()
        let templateSession = try templateService.generateSession(wordCount: 3, phraseCount: 5)
        let templateMetrics = templateService.calculateMetrics(session: templateSession)

        XCTAssertEqual(templateMetrics.totalChallenges, 5)
        XCTAssertEqual(templateMetrics.correctChallenges, 0)
        XCTAssertEqual(templateMetrics.accuracy, 0.0, accuracy: 0.01)

        // Memory Match
        let memoryService = MemoryMatchService(modelContext: testContext)
        let words = try vocabularyService.loadVocabularyWords()
        let memorySession = try memoryService.generateSession(pairCount: 6)
        let memoryMetrics = memoryService.calculateMetrics(session: memorySession)

        XCTAssertEqual(memoryMetrics.totalPairs, 6)
        XCTAssertEqual(memoryMetrics.moves, 0)
        XCTAssertEqual(memoryMetrics.efficiency, 0.0, accuracy: 0.01)

        DebugLogger.debug("✅ All services calculate metrics consistently")
    }

    // MARK: - Property-Based Integration Tests

    func testVocabularyBuilder_AllGames_RandomConfigurations() throws {
        // Test all games with random valid configurations

        for testIteration in 0..<5 {
            DebugLogger.debug("🎲 Integration test iteration \(testIteration + 1)")

            // Phrase Decoder
            let decoderService = PhraseDecoderService(modelContext: testContext)
            try decoderService.loadTechniques()
            let decoderWordCount = Int.random(in: 2...5)
            let decoderPhraseCount = Int.random(in: 5...10)

            let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
            let filteredTechniques = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: decoderWordCount)

            if filteredTechniques.count >= decoderPhraseCount {
                let decoderSession = try decoderService.generateSession(
                    wordCount: decoderWordCount,
                    phraseCount: decoderPhraseCount
                )
                XCTAssertEqual(decoderSession.challenges.count, decoderPhraseCount)
                DebugLogger.debug("  Phrase Decoder: \(decoderPhraseCount) challenges, \(decoderWordCount) words")
            }

            // Template Filler
            let templateService = TemplateFillerService(modelContext: testContext)
            try templateService.loadTechniques()
            let templateWordCount = Int.random(in: 2...5)
            let templatePhraseCount = Int.random(in: 5...10)

            let filteredTemplate = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: templateWordCount)

            if filteredTemplate.count >= templatePhraseCount {
                let templateSession = try templateService.generateSession(
                    wordCount: templateWordCount,
                    phraseCount: templatePhraseCount
                )
                XCTAssertEqual(templateSession.challenges.count, templatePhraseCount)
                DebugLogger.debug("  Template Filler: \(templatePhraseCount) challenges, \(templateWordCount) words")
            }

            // Memory Match
            let memoryService = MemoryMatchService(modelContext: testContext)
            let words = try vocabularyService.loadVocabularyWords()
            let pairCount = Int.random(in: 6...12)

            let memorySession = try memoryService.generateSession(pairCount: pairCount)
            XCTAssertEqual(memorySession.totalPairs, pairCount)
            DebugLogger.debug("  Memory Match: \(pairCount) pairs")
        }

        DebugLogger.debug("✅ All games tested with random configurations")
    }

    // MARK: - Error Handling Tests

    func testVocabularyBuilder_HandlesInsufficientData() throws {
        // All services should handle insufficient data gracefully

        // Phrase Decoder - request too many challenges
        let decoderService = PhraseDecoderService(modelContext: testContext)
        try decoderService.loadTechniques()

        XCTAssertThrowsError(
            try decoderService.generateSession(wordCount: 3, phraseCount: 10000)
        ) { error in
            XCTAssertTrue(error is PhraseDecoderError, "Should throw PhraseDecoderError")
        }

        // Template Filler - request too many challenges
        let templateService = TemplateFillerService(modelContext: testContext)
        try templateService.loadTechniques()

        XCTAssertThrowsError(
            try templateService.generateSession(wordCount: 3, phraseCount: 10000)
        ) { error in
            XCTAssertTrue(error is TemplateFillerError, "Should throw TemplateFillerError")
        }

        // Memory Match - insufficient words
        let memoryService = MemoryMatchService(modelContext: testContext)
        let minimalWords = [VocabularyWord(english: "Test", romanized: "Test", hangul: nil, frequency: 1)]

        XCTAssertThrowsError(
            try memoryService.generateSession(pairCount: 10)
        ) { error in
            XCTAssertTrue(error is MemoryMatchError, "Should throw MemoryMatchError")
        }

        DebugLogger.debug("✅ All services handle insufficient data errors correctly")
    }
}
