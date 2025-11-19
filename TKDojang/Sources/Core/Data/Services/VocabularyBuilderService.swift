import Foundation
import SwiftData

/**
 * VocabularyBuilderService.swift
 *
 * PURPOSE: Service for managing vocabulary word learning and phrase construction
 *
 * FEATURES:
 * - Load vocabulary words from generated JSON (English ↔ Korean romanised mappings)
 * - Provide words filtered by frequency and mastery level
 * - Track word-level mastery (separate from phrase-level terminology mastery)
 * - Support progressive learning (2-word → 6-word phrase construction)
 *
 * LEARNING MODES SUPPORTED:
 * - Word Matching: Match individual English words to Korean romanised equivalents
 * - Phrase Building: Construct phrases by arranging word tiles in correct order
 * - Progressive Assembly: Start with 2-word phrases, unlock longer phrases as mastery grows
 *
 * DATA SOURCE:
 * - Generated from existing terminology via Scripts/generate-vocabulary.py
 * - Automatically updated when terminology JSON files change
 * - No manual maintenance required
 */

@MainActor
class VocabularyBuilderService: ObservableObject {
    private let modelContext: ModelContext
    private var cachedWords: [VocabularyWord] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Vocabulary Loading

    /**
     * Load all vocabulary words from JSON
     * Caches results for performance
     */
    func loadVocabularyWords() throws -> [VocabularyWord] {
        if !cachedWords.isEmpty {
            return cachedWords
        }

        // Try multiple possible locations
        var url: URL?

        // Try 1: VocabularyBuilder subdirectory (like Terminology)
        url = Bundle.main.url(forResource: "vocabulary_words", withExtension: "json", subdirectory: "VocabularyBuilder")

        // Try 2: Content/VocabularyBuilder
        if url == nil {
            url = Bundle.main.url(forResource: "vocabulary_words", withExtension: "json", subdirectory: "Content/VocabularyBuilder")
        }

        // Try 3: Core/Data/Content/VocabularyBuilder (full path)
        if url == nil {
            url = Bundle.main.url(forResource: "vocabulary_words", withExtension: "json", subdirectory: "Core/Data/Content/VocabularyBuilder")
        }

        // Try 4: Bundle root
        if url == nil {
            url = Bundle.main.url(forResource: "vocabulary_words", withExtension: "json")
        }

        guard let validUrl = url else {
            DebugLogger.data("❌ VocabularyBuilderService: vocabulary_words.json not found in any location")
            DebugLogger.data("   Tried: VocabularyBuilder/, Content/VocabularyBuilder/, Core/Data/Content/VocabularyBuilder/, and bundle root")
            throw VocabularyBuilderError.vocabularyFileNotFound
        }

        DebugLogger.data("📂 VocabularyBuilderService: Loading vocabulary from \(validUrl.lastPathComponent)")

        let data = try Data(contentsOf: validUrl)
        let vocabularyData = try JSONDecoder().decode(VocabularyData.self, from: data)

        cachedWords = vocabularyData.words
        DebugLogger.data("✅ VocabularyBuilderService: Loaded \(cachedWords.count) vocabulary words")

        return cachedWords
    }

    // MARK: - Word Selection

    /**
     * Get words for Word Matching mode
     * Returns most frequent words (easier) or random words (harder)
     */
    func getWordsForMatching(count: Int, difficulty: WordDifficulty = .beginner) throws -> [VocabularyWord] {
        let allWords = try loadVocabularyWords()

        let selectedWords: [VocabularyWord]
        switch difficulty {
        case .beginner:
            // Most frequent words (easier)
            selectedWords = Array(allWords.prefix(count))
        case .intermediate:
            // Mid-frequency words
            let startIndex = min(20, allWords.count / 3)
            let endIndex = min(startIndex + count, allWords.count)
            selectedWords = Array(allWords[startIndex..<endIndex])
        case .advanced:
            // Random words from full set
            selectedWords = Array(allWords.shuffled().prefix(count))
        }

        DebugLogger.data("🎯 VocabularyBuilderService: Selected \(selectedWords.count) words for matching (difficulty=\(difficulty))")
        return selectedWords
    }

    /**
     * Get phrases for Phrase Building mode
     * Uses existing terminology to find multi-word phrases
     */
    func getPhrasesForBuilding(wordCount: Int, maxPhrases: Int = 10) throws -> [TerminologyPhrase] {
        // Load terminology to find multi-word phrases
        guard let url = Bundle.main.url(forResource: "terminology", withExtension: "json", subdirectory: "Content/Terminology") else {
            // Fallback: search all terminology JSON files
            return try loadPhrasesFromAllTerminology(wordCount: wordCount, maxPhrases: maxPhrases)
        }

        let data = try Data(contentsOf: url)
        let terminologyData = try JSONDecoder().decode(VocabTerminologyContainer.self, from: data)

        // Filter for phrases with target word count
        let phrases = terminologyData.terminology
            .filter { $0.romanisedPronunciation.split(separator: " ").count == wordCount }
            .prefix(maxPhrases)
            .map { term in
                TerminologyPhrase(
                    english: term.englishTerm,
                    romanised: term.romanisedPronunciation,
                    hangul: term.koreanHangul,
                    wordCount: wordCount
                )
            }

        DebugLogger.data("📝 VocabularyBuilderService: Found \(phrases.count) phrases with \(wordCount) words")
        return Array(phrases)
    }

    // MARK: - Helper Methods

    private func loadPhrasesFromAllTerminology(wordCount: Int, maxPhrases: Int) throws -> [TerminologyPhrase] {
        var allPhrases: [TerminologyPhrase] = []

        // Search all terminology JSON files
        if let resourcePath = Bundle.main.resourcePath {
            let terminologyPath = (resourcePath as NSString).appendingPathComponent("Content/Terminology")
            let fileManager = FileManager.default

            if let files = try? fileManager.contentsOfDirectory(atPath: terminologyPath) {
                for file in files where file.hasSuffix(".json") {
                    let filePath = (terminologyPath as NSString).appendingPathComponent(file)
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
                       let terminologyData = try? JSONDecoder().decode(VocabTerminologyContainer.self, from: data) {

                        let phrases = terminologyData.terminology
                            .filter { $0.romanisedPronunciation.split(separator: " ").count == wordCount }
                            .map { term in
                                TerminologyPhrase(
                                    english: term.englishTerm,
                                    romanised: term.romanisedPronunciation,
                                    hangul: term.koreanHangul,
                                    wordCount: wordCount
                                )
                            }

                        allPhrases.append(contentsOf: phrases)
                    }
                }
            }
        }

        DebugLogger.data("📚 VocabularyBuilderService: Found \(allPhrases.count) total phrases, selecting \(min(maxPhrases, allPhrases.count))")
        return Array(allPhrases.shuffled().prefix(maxPhrases))
    }
}

// MARK: - Models

struct VocabularyWord: Codable, Identifiable, Hashable {
    let english: String
    let romanised: String
    let hangul: String?
    let frequency: Int

    var id: String { english }
}

struct VocabularyData: Codable {
    let words: [VocabularyWord]
}

struct TerminologyPhrase: Identifiable, Hashable {
    let english: String
    let romanised: String
    let hangul: String
    let wordCount: Int

    var id: String { english }

    var words: [String] {
        romanised.split(separator: " ").map { String($0) }
    }
}

// MARK: - Supporting Types

enum WordDifficulty: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum VocabularyBuilderError: Error, LocalizedError {
    case vocabularyFileNotFound
    case invalidVocabularyData

    var errorDescription: String? {
        switch self {
        case .vocabularyFileNotFound:
            return "Vocabulary words file not found. Please regenerate using Scripts/generate-vocabulary.py"
        case .invalidVocabularyData:
            return "Vocabulary data is invalid or corrupted"
        }
    }
}

// MARK: - Terminology JSON Structure

private struct VocabTerminologyContainer: Codable {
    let terminology: [VocabTerminologyEntry]
}

private struct VocabTerminologyEntry: Codable {
    let englishTerm: String
    let romanisedPronunciation: String
    let koreanHangul: String

    enum CodingKeys: String, CodingKey {
        case englishTerm = "english"
        case romanisedPronunciation = "romanised"
        case koreanHangul = "hangul"
    }
}
