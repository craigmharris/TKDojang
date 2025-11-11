import Foundation
import SwiftData

/**
 * MemoryMatchService.swift
 *
 * PURPOSE: Service layer for Memory Match game mode
 *
 * FEATURES:
 * - Generate memory card pairs from vocabulary words
 * - Track game state (flipped cards, matched pairs)
 * - Validate card matches
 * - Calculate performance metrics (moves, time, accuracy)
 *
 * GAME MECHANICS:
 * 1. User selects difficulty (6-12 pairs)
 * 2. Service generates shuffled card grid with English/Korean pairs
 * 3. User taps cards to flip them
 * 4. Service checks if 2 flipped cards match (same word, different language)
 * 5. Matched pairs stay face-up, non-matches flip back
 * 6. Game completes when all pairs matched
 *
 * PEDAGOGY:
 * - Visual/spatial learning reinforcement
 * - Strengthens English ↔ Korean associations
 * - Memory practice aids long-term retention
 * - Lower pressure than timed vocabulary quizzes
 */

@MainActor
class MemoryMatchService: ObservableObject {
    private let modelContext: ModelContext
    private var vocabularyWords: [VocabularyWord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Vocabulary Loading

    /**
     * Load vocabulary words from VocabularyBuilderService
     */
    func loadVocabulary() throws {
        let vocabularyService = VocabularyBuilderService(modelContext: modelContext)
        vocabularyWords = try vocabularyService.loadVocabularyWords()

        DebugLogger.data("📋 MemoryMatchService: Loaded \(vocabularyWords.count) words")
    }

    // MARK: - Session Generation

    /**
     * Generate a memory match session
     */
    func generateSession(pairCount: Int) throws -> MemoryMatchSession {
        guard !vocabularyWords.isEmpty else {
            throw MemoryMatchError.vocabularyNotLoaded
        }

        guard pairCount >= 3 && pairCount <= 12 else {
            throw MemoryMatchError.invalidPairCount(count: pairCount)
        }

        // Select random words for pairs
        let selectedWords = vocabularyWords
            .shuffled()
            .prefix(pairCount)

        guard selectedWords.count == pairCount else {
            throw MemoryMatchError.insufficientWords(needed: pairCount, available: vocabularyWords.count)
        }

        // Create card pairs (English + Korean for each word)
        var cards: [MemoryCard] = []
        for word in selectedWords {
            // English card
            cards.append(MemoryCard(
                word: word,
                language: .english,
                position: 0 // Will be shuffled
            ))

            // Korean card
            cards.append(MemoryCard(
                word: word,
                language: .korean,
                position: 0 // Will be shuffled
            ))
        }

        // Shuffle cards and assign positions
        cards.shuffle()
        for (index, _) in cards.enumerated() {
            cards[index].position = index
        }

        DebugLogger.data("🎮 MemoryMatchService: Generated session with \(pairCount) pairs (\(cards.count) cards)")

        return MemoryMatchSession(
            pairCount: pairCount,
            totalPairs: pairCount,
            cards: cards,
            startTime: Date()
        )
    }

    // MARK: - Game Logic

    /**
     * Check if two cards match (same word, different language)
     */
    func checkMatch(card1: MemoryCard, card2: MemoryCard) -> Bool {
        // Must be same word but different languages
        guard card1.word.id == card2.word.id else { return false }
        guard card1.language != card2.language else { return false }

        return true
    }

    /**
     * Calculate performance metrics for completed session
     */
    func calculateMetrics(session: MemoryMatchSession) -> MemoryMatchMetrics {
        let duration = Date().timeIntervalSince(session.startTime)
        let totalPairs = session.totalPairs
        let moves = session.moveCount

        // Perfect game would be exactly pairCount moves (one move per pair)
        let optimalMoves = totalPairs
        let efficiency = Double(optimalMoves) / Double(max(moves, 1))

        // Performance rating based on efficiency
        let stars: Int
        if efficiency >= 0.9 {
            stars = 3 // Excellent: ≤10% extra moves
        } else if efficiency >= 0.7 {
            stars = 2 // Good: ≤30% extra moves
        } else {
            stars = 1 // Completed
        }

        return MemoryMatchMetrics(
            totalPairs: totalPairs,
            moves: moves,
            duration: duration,
            efficiency: efficiency,
            stars: stars
        )
    }
}

// MARK: - Session Models

struct MemoryMatchSession {
    let pairCount: Int
    let totalPairs: Int
    var cards: [MemoryCard]
    let startTime: Date
    var moveCount: Int = 0
    var matchedPairs: Int = 0
    var version: Int = 0  // Incremented on each update to force SwiftUI change detection

    var isComplete: Bool {
        return matchedPairs >= totalPairs
    }

    var flippedCards: [MemoryCard] {
        cards.filter { $0.isFlipped && !$0.isMatched }
    }
}

struct MemoryCard: Identifiable, Equatable {
    let id = UUID()
    let word: VocabularyWord
    let language: CardLanguage
    var position: Int
    var isFlipped: Bool = false
    var isMatched: Bool = false

    var displayText: String {
        switch language {
        case .english:
            return word.english
        case .korean:
            return word.romanized
        }
    }

    static func == (lhs: MemoryCard, rhs: MemoryCard) -> Bool {
        lhs.id == rhs.id
    }
}

enum CardLanguage {
    case english
    case korean
}

struct MemoryMatchMetrics {
    let totalPairs: Int
    let moves: Int
    let duration: TimeInterval
    let efficiency: Double // 0.0 to 1.0
    let stars: Int // 1-3

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var efficiencyPercentage: Int {
        return Int(efficiency * 100)
    }
}

// MARK: - Errors

enum MemoryMatchError: Error, LocalizedError {
    case vocabularyNotLoaded
    case invalidPairCount(count: Int)
    case insufficientWords(needed: Int, available: Int)

    var errorDescription: String? {
        switch self {
        case .vocabularyNotLoaded:
            return "Vocabulary not loaded. Please restart the game."
        case .invalidPairCount(let count):
            return "Invalid pair count: \(count). Must be between 3 and 12."
        case .insufficientWords(let needed, let available):
            return "Not enough words available. Need \(needed), have \(available)."
        }
    }
}
