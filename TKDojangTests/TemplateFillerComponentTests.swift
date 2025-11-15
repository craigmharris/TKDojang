import XCTest
import SwiftData
@testable import TKDojang

/**
 * TemplateFillerComponentTests.swift
 *
 * PURPOSE: Component tests for Template Filler game mode
 *
 * TEST COVERAGE:
 * - TemplateFillerService session generation with real techniques
 * - Positional distractor generation
 * - Multiple blank support (1-3 blanks)
 * - Validation logic correctness
 * - Property-based testing for blank generation
 *
 * DATA SOURCE: Production JSON files via TechniquePhraseLoader
 * TEST APPROACH: Real data integration, property-based validation
 */

@MainActor
final class TemplateFillerComponentTests: XCTestCase {

    var testContext: ModelContext!
    var testDatabaseURL: URL!
    var service: TemplateFillerService!

    override func setUp() async throws {
        try await super.setUp()

        // Use persistent storage (matches production)
        testDatabaseURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "TemplateFillerTest_\(UUID().uuidString).sqlite")

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

        service = TemplateFillerService(modelContext: testContext)
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

    // MARK: - Service Tests

    func testTemplateFillerService_LoadsTechniquesFromJSON() throws {
        // Service should load techniques from production JSON
        try service.loadTechniques()

        // Verify by generating a session
        let session = try service.generateSession(wordCount: 3, phraseCount: 5)

        XCTAssertEqual(session.totalChallenges, 5, "Session should have requested challenges")
        XCTAssertEqual(session.challenges.count, 5, "Should generate requested challenges")

        DebugLogger.debug("✅ Service loaded techniques and generated session")
    }

    func testTemplateFillerService_GeneratesChallenge_WithMultipleBlanks() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 4, phraseCount: 5)

        for challenge in session.challenges {
            // 4-word phrases should have 1-3 blanks
            XCTAssertGreaterThanOrEqual(challenge.blanks.count, 1, "Should have at least 1 blank")
            XCTAssertLessThanOrEqual(challenge.blanks.count, 3, "Should have at most 3 blanks")

            // Blanks should have valid positions
            for blank in challenge.blanks {
                XCTAssertGreaterThanOrEqual(blank.position, 0, "Blank position should be >= 0")
                XCTAssertLessThan(blank.position, challenge.englishWords.count, "Blank position should be valid")
            }

            DebugLogger.debug("Challenge has \(challenge.blanks.count) blanks in \(challenge.englishWords.count)-word phrase")
        }
    }

    func testTemplateFillerService_BlankGeneration_PropertyBased() throws {
        try service.loadTechniques()

        // Verify blank count adapts to phrase length
        for wordCount in 2...5 {
            let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
            let filtered = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: wordCount)

            guard filtered.count >= 5 else {
                DebugLogger.debug("⏭️ Skipping wordCount=\(wordCount): insufficient techniques")
                continue
            }

            let session = try service.generateSession(wordCount: wordCount, phraseCount: 5)

            for challenge in session.challenges {
                let expectedMinBlanks = 1
                let expectedMaxBlanks = min(3, wordCount - 1)

                XCTAssertGreaterThanOrEqual(
                    challenge.blanks.count,
                    expectedMinBlanks,
                    "Should have at least \(expectedMinBlanks) blank"
                )
                XCTAssertLessThanOrEqual(
                    challenge.blanks.count,
                    expectedMaxBlanks,
                    "Should have at most \(expectedMaxBlanks) blanks for \(wordCount)-word phrase"
                )

                // Blanks should not be adjacent
                if challenge.blanks.count > 1 {
                    let positions = challenge.blanks.map { $0.position }.sorted()
                    for i in 0..<positions.count-1 {
                        XCTAssertGreaterThan(
                            positions[i+1] - positions[i],
                            1,
                            "Blanks should not be adjacent"
                        )
                    }
                }
            }

            DebugLogger.debug("✅ Blank generation validated for \(wordCount)-word phrases")
        }
    }

    func testTemplateFillerService_PositionalDistractors_SamePosition() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 5)
        let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
        let threeWordTechniques = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: 3)

        for challenge in session.challenges {
            for blank in challenge.blanks {
                // Verify all choices could appear at this position
                for choice in blank.choices {
                    let validChoice = threeWordTechniques.contains { technique in
                        technique.englishWords[blank.position] == choice
                    }

                    XCTAssertTrue(
                        validChoice,
                        "Choice '\(choice)' should be valid for position \(blank.position)"
                    )
                }

                DebugLogger.debug("Blank \(blank.blankNumber): All \(blank.choices.count) choices valid for position \(blank.position)")
            }
        }

        DebugLogger.debug("✅ All distractors are positionally valid")
    }

    func testTemplateFillerService_PositionalDistractors_AdaptiveCount() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 5)

        for challenge in session.challenges {
            for blank in challenge.blanks {
                // Should have 2-4 choices (1 correct + 1-3 distractors)
                XCTAssertGreaterThanOrEqual(blank.choices.count, 2, "Should have at least 2 choices (1 correct + 1 distractor)")
                XCTAssertLessThanOrEqual(blank.choices.count, 4, "Should have at most 4 choices (1 correct + 3 distractors)")

                // Correct word should be in choices
                XCTAssertTrue(
                    blank.choices.contains(blank.correctWord),
                    "Choices should contain correct word: \(blank.correctWord)"
                )

                // All choices should be unique
                let uniqueChoices = Set(blank.choices)
                XCTAssertEqual(
                    blank.choices.count,
                    uniqueChoices.count,
                    "All choices should be unique"
                )

                DebugLogger.debug("Blank has \(blank.choices.count) unique choices including correct answer")
            }
        }

        DebugLogger.debug("✅ Adaptive distractor generation validated")
    }

    func testTemplateFillerService_Validation_ChecksAllBlanks() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 1)
        let challenge = session.challenges[0]

        // Build correct selections
        var correctSelections: [Int: String] = [:]
        for blank in challenge.blanks {
            correctSelections[blank.position] = blank.correctWord
        }

        // Validate with all correct
        let correctResult = service.validateSelections(
            userSelections: correctSelections,
            challenge: challenge
        )

        XCTAssertTrue(correctResult.isCorrect, "All correct selections should validate")
        XCTAssertTrue(correctResult.feedback.contains("Correct") || correctResult.feedback.contains("Perfect"), "Should indicate success")

        // Build partially incorrect selections
        var incorrectSelections = correctSelections
        if let firstBlank = challenge.blanks.first {
            // Pick a wrong choice (not the correct word)
            let wrongChoice = firstBlank.choices.first { $0 != firstBlank.correctWord }
            if let wrong = wrongChoice {
                incorrectSelections[firstBlank.position] = wrong

                let incorrectResult = service.validateSelections(
                    userSelections: incorrectSelections,
                    challenge: challenge
                )

                XCTAssertFalse(incorrectResult.isCorrect, "Incorrect selection should not validate")
                XCTAssertFalse(
                    incorrectResult.feedback.isEmpty,
                    "Should provide error feedback (got: '\(incorrectResult.feedback)')"
                )
            }
        }

        DebugLogger.debug("✅ Validation correctly checks all blanks")
    }

    func testTemplateFillerService_SessionGeneration_PropertyBased() throws {
        try service.loadTechniques()

        // Test with random valid configurations
        for _ in 0..<10 {
            let wordCount = Int.random(in: 2...5)
            let phraseCount = Int.random(in: 5...10)

            // Check if sufficient techniques available
            let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
            let filtered = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: wordCount)

            guard filtered.count >= phraseCount else {
                DebugLogger.debug("⏭️ Skipping: insufficient techniques for wordCount=\(wordCount), phraseCount=\(phraseCount)")
                continue
            }

            let session = try service.generateSession(wordCount: wordCount, phraseCount: phraseCount)

            // Properties that must hold
            XCTAssertEqual(session.wordCount, wordCount, "Session word count should match")
            XCTAssertEqual(session.totalChallenges, phraseCount, "Total challenges should match")
            XCTAssertEqual(session.challenges.count, phraseCount, "Should generate all challenges")

            for challenge in session.challenges {
                XCTAssertEqual(challenge.englishWords.count, wordCount, "English should have correct word count")
                XCTAssertEqual(challenge.koreanWords.count, wordCount, "Korean should have correct word count")
                XCTAssertGreaterThan(challenge.blanks.count, 0, "Should have at least 1 blank")
            }

            DebugLogger.debug("✅ Property-based test passed: wordCount=\(wordCount), phraseCount=\(phraseCount)")
        }
    }

    func testTemplateFillerService_CalculatesMetrics_PropertyBased() throws {
        try service.loadTechniques()

        // Test metrics with random configurations
        for _ in 0..<5 {
            let phraseCount = Int.random(in: 5...10)
            let session = try service.generateSession(wordCount: 3, phraseCount: phraseCount)

            let metrics = service.calculateMetrics(session: session)

            // Properties that must hold
            XCTAssertEqual(metrics.totalChallenges, phraseCount, "Total should match session size")
            XCTAssertEqual(metrics.correctChallenges, 0, "New session should have 0 correct challenges")
            XCTAssertEqual(metrics.accuracy, 0.0, accuracy: 0.01, "New session should have 0% accuracy")
        }

        DebugLogger.debug("✅ Metrics calculation validated")
    }

    // MARK: - Data Structure Tests

    func testTemplateFillerService_ShowsFullKoreanReference() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 5)

        for challenge in session.challenges {
            // Korean phrase should be complete (no blanks in Korean)
            let koreanPhrase = challenge.correctKoreanPhrase
            XCTAssertFalse(koreanPhrase.isEmpty, "Korean reference should not be empty")

            // Korean should be full technique name
            let expectedKorean = challenge.koreanWords.joined(separator: " ")
            XCTAssertEqual(koreanPhrase, expectedKorean, "Korean should be complete phrase")

            // English has blanks
            XCTAssertGreaterThan(challenge.blanks.count, 0, "English should have blanks to fill")

            DebugLogger.debug("Korean reference: '\(koreanPhrase)' with \(challenge.blanks.count) English blank(s)")
        }

        DebugLogger.debug("✅ All challenges show full Korean reference")
    }

    func testTemplateFillerService_UniqueChallenges() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 3, phraseCount: 10)

        // Challenges should use different techniques
        let techniqueIds = session.challenges.map { $0.technique.id }
        let uniqueIds = Set(techniqueIds)

        XCTAssertEqual(
            techniqueIds.count,
            uniqueIds.count,
            "All challenges should use unique techniques"
        )

        DebugLogger.debug("✅ Session has \(uniqueIds.count) unique techniques")
    }

    func testTemplateFillerService_BlankNumbering() throws {
        try service.loadTechniques()

        let session = try service.generateSession(wordCount: 4, phraseCount: 5)

        for challenge in session.challenges {
            // Blanks should be numbered sequentially starting from 1
            let expectedNumbers = Array(1...challenge.blanks.count)
            let actualNumbers = challenge.blanks.map { $0.blankNumber }.sorted()

            XCTAssertEqual(actualNumbers, expectedNumbers, "Blanks should be numbered 1, 2, 3...")

            DebugLogger.debug("Challenge has blanks numbered: \(actualNumbers)")
        }

        DebugLogger.debug("✅ Blank numbering validated")
    }

    // MARK: - Edge Cases

    func testTemplateFillerService_TwoWordPhrases_OnlyOneBlank() throws {
        try service.loadTechniques()

        let allTechniques = try TechniquePhraseLoader.loadAllTechniques()
        let twoWordTechniques = TechniquePhraseLoader.filterByWordCount(allTechniques, wordCount: 2)

        guard twoWordTechniques.count >= 5 else {
            throw XCTSkip("Not enough 2-word techniques for this test")
        }

        let session = try service.generateSession(wordCount: 2, phraseCount: 5)

        for challenge in session.challenges {
            // 2-word phrases should have exactly 1 blank (can't blank both)
            XCTAssertEqual(challenge.blanks.count, 1, "2-word phrases should have exactly 1 blank")

            DebugLogger.debug("2-word phrase has 1 blank at position \(challenge.blanks[0].position)")
        }

        DebugLogger.debug("✅ 2-word phrases correctly have only 1 blank")
    }

    func testTemplateFillerService_InsufficientTechniques_Throws() throws {
        try service.loadTechniques()

        // Should throw when requesting more challenges than available techniques
        XCTAssertThrowsError(
            try service.generateSession(wordCount: 3, phraseCount: 1000),
            "Should throw when insufficient techniques"
        ) { error in
            guard let templateError = error as? TemplateFillerError else {
                XCTFail("Should throw TemplateFillerError")
                return
            }

            if case .insufficientTechniques = templateError {
                // Expected error
            } else {
                XCTFail("Should throw insufficientTechniques error")
            }
        }

        DebugLogger.debug("✅ Service correctly throws for insufficient techniques")
    }
}
