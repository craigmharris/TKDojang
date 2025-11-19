import Foundation
import SwiftData

/**
 * TemplateFillerService.swift
 *
 * PURPOSE: Service layer for Template Filler game mode
 *
 * FEATURES:
 * - Generate phrases with strategic blanks
 * - Provide multiple-choice options for each blank
 * - Validate user's word selections
 * - Support 2-5 word phrases with 1-2 blanks
 * - Track accuracy and provide hints
 *
 * GAME MECHANICS:
 * 1. Generate valid phrase from template
 * 2. Replace 1-2 words with blanks (strategic positions)
 * 3. For each blank, provide 4 choices (1 correct + 3 distractors from same category)
 * 4. User selects word for each blank
 * 5. Validate selections
 * 6. Provide feedback on correctness
 *
 * PEDAGOGY:
 * - Teaches pattern recognition (common phrase structures)
 * - Reinforces category understanding (which words fit where)
 * - Context clues help narrow choices
 * - Progressive difficulty (more blanks = harder)
 */

@MainActor
class TemplateFillerService: ObservableObject {
    private let modelContext: ModelContext
    private var techniquePhrases: [TechniquePhrase] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Technique Loading

    /**
     * Load real technique phrases from JSON files
     */
    func loadTechniques() throws {
        techniquePhrases = try TechniquePhraseLoader.loadAllTechniques()

        guard !techniquePhrases.isEmpty else {
            throw TemplateFillerError.noTechniquesAvailable
        }

        DebugLogger.data("📋 TemplateFillerService: Loaded \(techniquePhrases.count) technique phrases")
    }

    // MARK: - Session Generation

    /**
     * Generate a template filler session using real techniques
     */
    func generateSession(
        wordCount: Int,
        phraseCount: Int,
        blanksPerPhrase: Int = 1,
        direction: StudyDirection = .englishToKorean
    ) throws -> TemplateFillerSession {
        guard !techniquePhrases.isEmpty else {
            throw TemplateFillerError.techniquesNotLoaded
        }

        // Filter techniques by word count in the SOURCE language (direction-aware)
        // WHY: English and Korean may have different word counts - we only care about the language being studied
        let availableTechniques = TechniquePhraseLoader.filterByWordCount(
            techniquePhrases,
            wordCount: wordCount,
            direction: direction
        )

        guard availableTechniques.count >= phraseCount else {
            throw TemplateFillerError.insufficientTechniques(
                wordCount: wordCount,
                available: availableTechniques.count,
                needed: phraseCount
            )
        }

        DebugLogger.data("🎮 TemplateFillerService: Generating session with \(phraseCount) \(wordCount)-word technique phrases (\(blanksPerPhrase) blanks, \(direction.displayName)) - \(availableTechniques.count) valid techniques available")

        // Randomly select techniques
        let selectedTechniques = availableTechniques.shuffled().prefix(phraseCount)

        var challenges: [TemplateChallenge] = []
        for (index, technique) in selectedTechniques.enumerated() {
            let challenge = try generateChallenge(
                technique: technique,
                challengeNumber: index + 1,
                blanksPerPhrase: blanksPerPhrase,
                direction: direction
            )
            challenges.append(challenge)
        }

        DebugLogger.data("✅ TemplateFillerService: Session generation complete - \(challenges.count) challenges created")

        return TemplateFillerSession(
            wordCount: wordCount,
            totalChallenges: phraseCount,
            challenges: challenges,
            blanksPerPhrase: blanksPerPhrase,
            direction: direction,
            startTime: Date()
        )
    }

    /**
     * Generate a single template challenge from a technique with blanks
     */
    private func generateChallenge(
        technique: TechniquePhrase,
        challengeNumber: Int,
        blanksPerPhrase: Int,
        direction: StudyDirection
    ) throws -> TemplateChallenge {
        let englishWords = technique.englishWords
        let koreanWords = technique.koreanWords

        // CRITICAL: Verify English and Korean word counts match
        guard englishWords.count == koreanWords.count else {
            throw TemplateFillerError.wordCountMismatch(
                techniqueId: technique.id,
                english: englishWords.count,
                korean: koreanWords.count
            )
        }

        // Use specified blank count (ensure it doesn't exceed available positions)
        let maxBlanks = max(1, englishWords.count - 1) // Leave at least one word visible
        let blankCount = min(blanksPerPhrase, maxBlanks)

        // Select random positions for blanks (avoid adjacent blanks for clarity)
        var blankPositions: [Int] = []
        var availablePositions = Array(0..<englishWords.count)

        for _ in 0..<blankCount {
            guard let position = availablePositions.randomElement() else { break }

            blankPositions.append(position)

            // Remove adjacent positions to avoid consecutive blanks
            availablePositions = availablePositions.filter { pos in
                abs(pos - position) > 1
            }
        }

        blankPositions.sort()

        // Create blanks with choices (direction-aware)
        var blanks: [TemplateBlank] = []
        for (blankIndex, position) in blankPositions.enumerated() {
            let (correctWord, correctTranslation) = direction == .englishToKorean
                ? (englishWords[position], koreanWords[position])
                : (koreanWords[position], englishWords[position])

            let choices = try generateChoices(
                correctWord: correctWord,
                position: position,
                wordCount: englishWords.count,
                direction: direction
            )

            blanks.append(TemplateBlank(
                blankNumber: blankIndex + 1,
                position: position,
                correctWord: correctWord,
                correctKorean: correctTranslation,
                choices: choices
            ))
        }

        return TemplateChallenge(
            challengeNumber: challengeNumber,
            technique: technique,
            englishWords: englishWords,
            koreanWords: koreanWords,
            blanks: blanks,
            direction: direction
        )
    }

    /**
     * Generate choices for a blank (1 correct + positional distractors)
     * Uses words from the same position in other techniques as distractors
     * Adapts distractor count based on available words:
     * - 4+ words: 3 distractors (4 total choices)
     * - 3 words: 2 distractors (3 total choices)
     * - 2 words: 1 distractor (2 total choices)
     */
    private func generateChoices(
        correctWord: String,
        position: Int,
        wordCount: Int,
        direction: StudyDirection
    ) throws -> [String] {
        // Get all techniques with same word count in the SOURCE language
        // WHY: We only care about the language being studied, not both languages matching
        let sameLengthTechniques = TechniquePhraseLoader.filterByWordCount(
            techniquePhrases,
            wordCount: wordCount,
            direction: direction
        )

        // Extract words at this position from other techniques (direction-aware)
        var positionalWords: [String] = []
        for technique in sameLengthTechniques {
            // Get source words based on study direction
            let sourceWords = direction == .englishToKorean
                ? technique.englishWords
                : technique.koreanWords

            // Bounds check for the source language only
            guard position < sourceWords.count else {
                continue
            }

            let wordAtPosition = sourceWords[position]

            if wordAtPosition != correctWord && !positionalWords.contains(wordAtPosition) {
                positionalWords.append(wordAtPosition)
            }
        }

        guard !positionalWords.isEmpty else {
            throw TemplateFillerError.insufficientDistractors(position: position)
        }

        // Adapt distractor count based on available words
        let distractorCount = min(3, positionalWords.count)
        let distractors = Array(positionalWords.shuffled().prefix(distractorCount))

        // Combine and shuffle
        var choices = [correctWord] + distractors
        choices.shuffle()

        DebugLogger.data("  ✅ Generated \(choices.count) choices for blank at position \(position)")
        return choices
    }

    // MARK: - Validation

    /**
     * Validate user's selections for all blanks
     */
    func validateSelections(
        userSelections: [Int: String], // blank position -> selected word
        challenge: TemplateChallenge
    ) -> TemplateValidationResult {
        var correctBlanks: [Int] = []

        for blank in challenge.blanks {
            if let selectedWord = userSelections[blank.position],
               selectedWord == blank.correctWord {
                correctBlanks.append(blank.blankNumber)
            }
        }

        let isCorrect = correctBlanks.count == challenge.blanks.count

        let feedback: String
        if isCorrect {
            feedback = "Perfect! All blanks filled correctly."
        } else {
            feedback = "\(correctBlanks.count) of \(challenge.blanks.count) blanks correct"
        }

        return TemplateValidationResult(
            isCorrect: isCorrect,
            correctBlanks: correctBlanks,
            feedback: feedback
        )
    }

    /**
     * Calculate performance metrics
     */
    func calculateMetrics(session: TemplateFillerSession) -> TemplateMetrics {
        let duration = Date().timeIntervalSince(session.startTime)
        let totalChallenges = session.totalChallenges
        let correctChallenges = session.completedChallenges.filter { $0.isCorrect }.count
        let accuracy = Double(correctChallenges) / Double(max(totalChallenges, 1))

        // Performance rating
        let stars: Int
        if accuracy >= 0.9 {
            stars = 3 // Excellent
        } else if accuracy >= 0.7 {
            stars = 2 // Good
        } else {
            stars = 1 // Completed
        }

        return TemplateMetrics(
            totalChallenges: totalChallenges,
            correctChallenges: correctChallenges,
            accuracy: accuracy,
            duration: duration,
            stars: stars
        )
    }
}

// MARK: - Study Direction

enum StudyDirection: String, CaseIterable {
    case englishToKorean = "english-to-korean"
    case koreanToEnglish = "korean-to-english"

    var displayName: String {
        switch self {
        case .englishToKorean: return "English → Korean"
        case .koreanToEnglish: return "Korean → English"
        }
    }

    var description: String {
        switch self {
        case .englishToKorean: return "Fill blanks in English phrases (Korean shown for reference)"
        case .koreanToEnglish: return "Fill blanks in Korean phrases (English shown for reference)"
        }
    }
}

// MARK: - Session Models

struct TemplateFillerSession {
    let wordCount: Int
    let totalChallenges: Int
    let challenges: [TemplateChallenge]
    let blanksPerPhrase: Int
    let direction: StudyDirection
    let startTime: Date
    var currentChallengeIndex: Int = 0
    var completedChallenges: [CompletedTemplateChallenge] = []

    var currentChallenge: TemplateChallenge? {
        guard currentChallengeIndex < challenges.count else { return nil }
        return challenges[currentChallengeIndex]
    }

    var isComplete: Bool {
        return currentChallengeIndex >= challenges.count
    }
}

struct TemplateChallenge: Identifiable {
    let id = UUID()
    let challengeNumber: Int
    let technique: TechniquePhrase
    let englishWords: [String]
    let koreanWords: [String]
    let blanks: [TemplateBlank]
    let direction: StudyDirection

    var displayTitle: String {
        "Challenge \(challengeNumber): \(technique.category.displayName)"
    }

    var correctEnglishPhrase: String {
        englishWords.joined(separator: " ")
    }

    var correctKoreanPhrase: String {
        koreanWords.joined(separator: " ")
    }

    /// The phrase being filled (with blanks)
    var targetPhrase: [String] {
        direction == .englishToKorean ? englishWords : koreanWords
    }

    /// The reference phrase (shown for context)
    var referencePhrase: String {
        direction == .englishToKorean ? correctKoreanPhrase : correctEnglishPhrase
    }
}

struct TemplateBlank: Identifiable {
    let id = UUID()
    let blankNumber: Int
    let position: Int // Position in phrase (0-indexed)
    let correctWord: String
    let correctKorean: String
    let choices: [String] // 2-4 choices including correct
}

struct CompletedTemplateChallenge {
    let challenge: TemplateChallenge
    let userSelections: [Int: String] // position -> selected word
    let isCorrect: Bool
    let completionTime: Date
}

struct TemplateValidationResult {
    let isCorrect: Bool
    let correctBlanks: [Int] // Blank numbers that are correct
    let feedback: String
}

struct TemplateMetrics {
    let totalChallenges: Int
    let correctChallenges: Int
    let accuracy: Double
    let duration: TimeInterval
    let stars: Int

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var accuracyPercentage: Int {
        return Int(accuracy * 100)
    }
}

// MARK: - Errors

enum TemplateFillerError: Error, LocalizedError {
    case techniquesNotLoaded
    case noTechniquesAvailable
    case insufficientTechniques(wordCount: Int, available: Int, needed: Int)
    case insufficientDistractors(position: Int)
    case wordCountMismatch(techniqueId: String, english: Int, korean: Int)

    var errorDescription: String? {
        switch self {
        case .techniquesNotLoaded:
            return "Techniques not loaded. Please restart the game."
        case .noTechniquesAvailable:
            return "No techniques available to load."
        case .insufficientTechniques(let wordCount, let available, let needed):
            return "Not enough \(wordCount)-word techniques. Need \(needed), found \(available)."
        case .insufficientDistractors(let position):
            return "Not enough distractor words for position \(position)"
        case .wordCountMismatch(let id, let english, let korean):
            return "Technique \(id) has mismatched word counts (English: \(english), Korean: \(korean))"
        }
    }
}
