import Foundation
import SwiftData

/**
 * SlotBuilderService.swift
 *
 * PURPOSE: Service layer for Slot Builder game mode
 *
 * FEATURES:
 * - Generate slot-based phrase building sessions
 * - Provide word choices for each slot based on grammar templates
 * - Validate user-constructed phrases against templates
 * - Track session progress and scoring
 * - Support 2-5 word phrase difficulty levels
 *
 * GAME MECHANICS:
 * 1. User selects phrase length (2-5 words) and session count
 * 2. Service generates random phrase template for target length
 * 3. For each slot, service provides 4-6 word choices from correct category
 * 4. User selects one word per slot to build phrase
 * 5. Service validates if constructed phrase matches template
 * 6. Immediate feedback + explanation if incorrect
 *
 * PEDAGOGY:
 * - Guided construction teaches grammar patterns
 * - Slot labels show category names (Tool, Action, Direction)
 * - Examples reinforce correct structures
 * - Progressive difficulty (2→5 words)
 */

@MainActor
class SlotBuilderService: ObservableObject {
    private let modelContext: ModelContext
    private var vocabularyWords: [VocabularyWord] = []
    private var categorizedWords: [WordCategory: [CategorizedWord]] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Vocabulary Loading

    /**
     * Load and categorize vocabulary words
     */
    func loadVocabulary() throws {
        // Load vocabulary from VocabularyBuilderService
        let vocabularyService = VocabularyBuilderService(modelContext: modelContext)
        vocabularyWords = try vocabularyService.loadVocabularyWords()

        // Categorize all words
        categorizedWords = [:]
        for category in WordCategory.allCases {
            categorizedWords[category] = VocabularyCategories.words(
                in: category,
                from: vocabularyWords
            )
        }

        DebugLogger.data("📋 SlotBuilderService: Categorized \(vocabularyWords.count) words")
        for (category, words) in categorizedWords {
            DebugLogger.data("   - \(category.displayName): \(words.count) words")
        }
    }

    // MARK: - Session Generation

    /**
     * Generate a slot builder session
     */
    func generateSession(wordCount: Int, phraseCount: Int) throws -> SlotBuilderSession {
        guard !vocabularyWords.isEmpty else {
            throw SlotBuilderError.vocabularyNotLoaded
        }

        // Get templates for target word count
        let templates = PhraseGrammar.templates(for: wordCount)
        guard !templates.isEmpty else {
            throw SlotBuilderError.noTemplatesAvailable(wordCount: wordCount)
        }

        DebugLogger.data("🎮 SlotBuilderService: Generating session with \(phraseCount) phrases of \(wordCount) words")
        DebugLogger.data("   - Found \(templates.count) templates for \(wordCount) words")

        // Generate phrase challenges
        var challenges: [PhraseChallenge] = []
        for index in 1...phraseCount {
            // Randomly select template
            guard let template = templates.randomElement() else {
                DebugLogger.data("❌ SlotBuilderService: Failed to select template for challenge \(index)")
                throw SlotBuilderError.templateSelectionFailed
            }

            DebugLogger.data("   - Generating challenge \(index) with template: \(template.displayName)")

            let challenge = try generateChallenge(
                template: template,
                challengeNumber: index
            )
            challenges.append(challenge)
        }

        DebugLogger.data("✅ SlotBuilderService: Session generation complete - \(challenges.count) challenges created")

        return SlotBuilderSession(
            wordCount: wordCount,
            totalChallenges: phraseCount,
            challenges: challenges,
            startTime: Date()
        )
    }

    /**
     * Generate a single phrase challenge from template
     */
    private func generateChallenge(
        template: PhraseTemplate,
        challengeNumber: Int
    ) throws -> PhraseChallenge {
        var slotChoices: [SlotChoices] = []

        for slot in template.slots {
            // Get available categories for this slot
            let categories = slot.allowedCategories

            // Collect all words from allowed categories
            var availableWords: [CategorizedWord] = []
            for category in categories {
                if let words = categorizedWords[category] {
                    availableWords.append(contentsOf: words)
                }
            }

            guard !availableWords.isEmpty else {
                throw SlotBuilderError.insufficientWordsForCategory(category: categories.first!)
            }

            // Select 4-6 random words for this slot
            let choiceCount = min(6, max(4, availableWords.count))
            let selectedWords = Array(availableWords.shuffled().prefix(choiceCount))

            slotChoices.append(SlotChoices(
                slotPosition: slot.position,
                slotLabel: slot.label,
                allowedCategories: slot.allowedCategories,
                wordChoices: selectedWords
            ))
        }

        return PhraseChallenge(
            challengeNumber: challengeNumber,
            template: template,
            slotChoices: slotChoices
        )
    }

    // MARK: - Validation

    /**
     * Validate if user-constructed phrase matches template
     */
    func validatePhrase(
        userPhrase: [CategorizedWord],
        challenge: PhraseChallenge
    ) -> PhraseValidationResult {
        // Check word count
        guard userPhrase.count == challenge.template.wordCount else {
            return PhraseValidationResult(
                isCorrect: false,
                feedback: "Phrase should have \(challenge.template.wordCount) words, but has \(userPhrase.count)",
                correctTemplate: challenge.template.displayName
            )
        }

        // Check each slot matches allowed categories
        for (index, word) in userPhrase.enumerated() {
            let expectedCategories = challenge.template.categoryForSlot(at: index)

            if !expectedCategories.contains(word.category) {
                let expectedNames = expectedCategories.map { $0.displayName }.joined(separator: " or ")
                return PhraseValidationResult(
                    isCorrect: false,
                    feedback: "Position \(index + 1) should be \(expectedNames), but got \(word.category.displayName): '\(word.english)'",
                    correctTemplate: challenge.template.displayName
                )
            }
        }

        // All checks passed
        return PhraseValidationResult(
            isCorrect: true,
            feedback: "Correct! You built a valid \(challenge.template.displayName) phrase.",
            correctTemplate: challenge.template.displayName
        )
    }

    // MARK: - Statistics

    /**
     * Get category availability statistics
     */
    func getCategoryStats() -> [WordCategory: Int] {
        var stats: [WordCategory: Int] = [:]
        for (category, words) in categorizedWords {
            stats[category] = words.count
        }
        return stats
    }

    /**
     * Check if sufficient words exist for a word count
     */
    func hasSufficientWords(for wordCount: Int) -> Bool {
        let templates = PhraseGrammar.templates(for: wordCount)

        for template in templates {
            var canBuild = true
            for slot in template.slots {
                let hasWords = slot.allowedCategories.contains { category in
                    (categorizedWords[category]?.count ?? 0) >= 4
                }
                if !hasWords {
                    canBuild = false
                    break
                }
            }
            if canBuild {
                return true
            }
        }

        return false
    }
}

// MARK: - Session Models

struct SlotBuilderSession {
    let wordCount: Int
    let totalChallenges: Int
    let challenges: [PhraseChallenge]
    let startTime: Date
    var currentChallengeIndex: Int = 0
    var completedChallenges: [CompletedChallenge] = []

    var currentChallenge: PhraseChallenge? {
        guard currentChallengeIndex < challenges.count else { return nil }
        return challenges[currentChallengeIndex]
    }

    var isComplete: Bool {
        return currentChallengeIndex >= challenges.count
    }

    var accuracy: Double {
        guard !completedChallenges.isEmpty else { return 0.0 }
        let correct = completedChallenges.filter { $0.isCorrect }.count
        return Double(correct) / Double(completedChallenges.count)
    }
}

struct PhraseChallenge: Identifiable {
    let id = UUID()
    let challengeNumber: Int
    let template: PhraseTemplate
    let slotChoices: [SlotChoices]

    var displayTitle: String {
        "Challenge \(challengeNumber): Build a \(template.displayName)"
    }
}

struct SlotChoices: Identifiable {
    let id = UUID()
    let slotPosition: Int
    let slotLabel: String
    let allowedCategories: [WordCategory]
    let wordChoices: [CategorizedWord]
}

struct CompletedChallenge {
    let challenge: PhraseChallenge
    let userPhrase: [CategorizedWord]
    let isCorrect: Bool
    let feedback: String
    let attemptTime: Date
}

struct PhraseValidationResult {
    let isCorrect: Bool
    let feedback: String
    let correctTemplate: String
}

// MARK: - Errors

enum SlotBuilderError: Error, LocalizedError {
    case vocabularyNotLoaded
    case noTemplatesAvailable(wordCount: Int)
    case templateSelectionFailed
    case insufficientWordsForCategory(category: WordCategory)

    var errorDescription: String? {
        switch self {
        case .vocabularyNotLoaded:
            return "Vocabulary not loaded. Please restart the game."
        case .noTemplatesAvailable(let wordCount):
            return "No phrase templates available for \(wordCount) words"
        case .templateSelectionFailed:
            return "Failed to select phrase template"
        case .insufficientWordsForCategory(let category):
            return "Not enough words in category: \(category.displayName)"
        }
    }
}
