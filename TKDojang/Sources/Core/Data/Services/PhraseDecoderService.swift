import Foundation
import SwiftData

/**
 * PhraseDecoderService.swift
 *
 * PURPOSE: Service layer for Phrase Decoder game mode using REAL technique names
 *
 * FEATURES:
 * - Load authentic technique names from JSON files
 * - Scramble real technique phrases for decoding
 * - Support bilingual mode (English ↔ Korean romanized)
 * - Validate user's word arrangement
 * - Track attempts and provide feedback
 *
 * GAME MECHANICS:
 * 1. Load real techniques (blocks, kicks, strikes, hand techniques)
 * 2. Select technique matching desired word count
 * 3. Scramble words (ensure not in correct order)
 * 4. User drags/reorders words to match correct sequence
 * 5. Validate word order against original technique name
 * 6. Show both English and Korean for learning
 *
 * PEDAGOGY:
 * - Uses REAL Korean Taekwondo terminology (not generated)
 * - Teaches authentic technique names students must know
 * - Bilingual display reinforces translation learning
 * - Progressive difficulty by word count (2-5 words)
 */

@MainActor
class PhraseDecoderService: ObservableObject {
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
            throw PhraseDecoderError.noTechniquesAvailable
        }

        DebugLogger.data("📋 PhraseDecoderService: Loaded \(techniquePhrases.count) technique phrases")
    }

    // MARK: - Session Generation

    /**
     * Generate a phrase decoder session using real techniques
     */
    func generateSession(wordCount: Int, phraseCount: Int) throws -> PhraseDecoderSession {
        guard !techniquePhrases.isEmpty else {
            throw PhraseDecoderError.techniquesNotLoaded
        }

        // Filter techniques by word count
        let availableTechniques = TechniquePhraseLoader.filterByWordCount(
            techniquePhrases,
            wordCount: wordCount
        )

        guard availableTechniques.count >= phraseCount else {
            throw PhraseDecoderError.insufficientTechniques(
                wordCount: wordCount,
                available: availableTechniques.count,
                needed: phraseCount
            )
        }

        DebugLogger.data("🎮 PhraseDecoderService: Generating session with \(phraseCount) \(wordCount)-word technique phrases")

        // Randomly select techniques (without replacement)
        let selectedTechniques = availableTechniques.shuffled().prefix(phraseCount)

        var challenges: [DecoderChallenge] = []
        for (index, technique) in selectedTechniques.enumerated() {
            let challenge = generateChallenge(
                technique: technique,
                challengeNumber: index + 1
            )
            challenges.append(challenge)
        }

        DebugLogger.data("✅ PhraseDecoderService: Session generation complete - \(challenges.count) challenges created")

        return PhraseDecoderSession(
            wordCount: wordCount,
            totalChallenges: phraseCount,
            challenges: challenges,
            startTime: Date()
        )
    }

    /**
     * Generate a single phrase challenge from a real technique
     */
    private func generateChallenge(
        technique: TechniquePhrase,
        challengeNumber: Int
    ) -> DecoderChallenge {
        // Get English and Korean words
        let englishWords = technique.englishWords
        let koreanWords = technique.koreanWords

        // Scramble both (ensure different from correct order)
        var scrambledEnglish = englishWords
        var attempts = 0
        repeat {
            scrambledEnglish.shuffle()
            attempts += 1
        } while scrambledEnglish == englishWords && attempts < 10

        var scrambledKorean = koreanWords
        attempts = 0
        repeat {
            scrambledKorean.shuffle()
            attempts += 1
        } while scrambledKorean == koreanWords && attempts < 10

        return DecoderChallenge(
            challengeNumber: challengeNumber,
            technique: technique,
            correctEnglish: englishWords,
            correctKorean: koreanWords,
            scrambledEnglish: scrambledEnglish,
            scrambledKorean: scrambledKorean
        )
    }

    // MARK: - Validation

    /**
     * Validate user's phrase arrangement
     */
    func validatePhrase(
        userWords: [String],
        challenge: DecoderChallenge,
        language: PhraseLanguage
    ) -> DecoderValidationResult {
        let correctWords = language == .english ? challenge.correctEnglish : challenge.correctKorean

        guard userWords.count == correctWords.count else {
            return DecoderValidationResult(
                isCorrect: false,
                correctPositions: [],
                feedback: "Phrase incomplete"
            )
        }

        // Check each position
        var correctPositions: [Int] = []
        for (index, word) in userWords.enumerated() {
            if word == correctWords[index] {
                correctPositions.append(index)
            }
        }

        let isCorrect = correctPositions.count == userWords.count

        let feedback: String
        if isCorrect {
            feedback = "Perfect! Correct word order."
        } else {
            feedback = "\(correctPositions.count) of \(userWords.count) words in correct position"
        }

        return DecoderValidationResult(
            isCorrect: isCorrect,
            correctPositions: correctPositions,
            feedback: feedback
        )
    }

    /**
     * Calculate performance metrics
     */
    func calculateMetrics(session: PhraseDecoderSession) -> DecoderMetrics {
        let duration = Date().timeIntervalSince(session.startTime)
        let totalChallenges = session.totalChallenges
        let totalAttempts = session.completedChallenges.reduce(0) { $0 + $1.attempts }
        let averageAttempts = Double(totalAttempts) / Double(totalChallenges)

        // Performance rating
        let stars: Int
        if averageAttempts <= 1.5 {
            stars = 3 // Excellent: mostly first try
        } else if averageAttempts <= 2.5 {
            stars = 2 // Good: average 2-3 attempts
        } else {
            stars = 1 // Completed
        }

        return DecoderMetrics(
            totalChallenges: totalChallenges,
            totalAttempts: totalAttempts,
            averageAttempts: averageAttempts,
            duration: duration,
            stars: stars
        )
    }
}

// MARK: - Session Models

enum PhraseLanguage: String, CaseIterable {
    case english = "English"
    case korean = "Korean"

    var displayName: String { rawValue }
}

struct PhraseDecoderSession {
    let wordCount: Int
    let totalChallenges: Int
    let challenges: [DecoderChallenge]
    let startTime: Date
    var currentChallengeIndex: Int = 0
    var completedChallenges: [CompletedDecoderChallenge] = []

    var currentChallenge: DecoderChallenge? {
        guard currentChallengeIndex < challenges.count else { return nil }
        return challenges[currentChallengeIndex]
    }

    var isComplete: Bool {
        return currentChallengeIndex >= challenges.count
    }
}

struct DecoderChallenge: Identifiable {
    let id = UUID()
    let challengeNumber: Int
    let technique: TechniquePhrase
    let correctEnglish: [String]
    let correctKorean: [String]
    let scrambledEnglish: [String]
    let scrambledKorean: [String]

    var displayTitle: String {
        "Challenge \(challengeNumber): \(technique.category.displayName)"
    }

    var correctEnglishPhrase: String {
        correctEnglish.joined(separator: " ")
    }

    var correctKoreanPhrase: String {
        correctKorean.joined(separator: " ")
    }
}

struct CompletedDecoderChallenge {
    let challenge: DecoderChallenge
    let attempts: Int
    let finalEnglishWords: [String]
    let finalKoreanWords: [String]
    let completionTime: Date
}

struct DecoderValidationResult {
    let isCorrect: Bool
    let correctPositions: [Int]
    let feedback: String
}

struct DecoderMetrics {
    let totalChallenges: Int
    let totalAttempts: Int
    let averageAttempts: Double
    let duration: TimeInterval
    let stars: Int

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedAverageAttempts: String {
        return String(format: "%.1f", averageAttempts)
    }
}

// MARK: - Errors

enum PhraseDecoderError: Error, LocalizedError {
    case techniquesNotLoaded
    case noTechniquesAvailable
    case insufficientTechniques(wordCount: Int, available: Int, needed: Int)

    var errorDescription: String? {
        switch self {
        case .techniquesNotLoaded:
            return "Techniques not loaded. Please restart the game."
        case .noTechniquesAvailable:
            return "No techniques available to load."
        case .insufficientTechniques(let wordCount, let available, let needed):
            return "Not enough \(wordCount)-word techniques. Need \(needed), found \(available)."
        }
    }
}
