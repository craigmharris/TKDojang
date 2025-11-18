import SwiftUI
import SwiftData

/**
 * CreativeSandboxService.swift
 *
 * PURPOSE: Service layer for Creative Sandbox mode
 *
 * FEATURES:
 * - Load and categorize vocabulary words
 * - Track phrase constructions (no validation)
 * - Provide words organized by category
 *
 * ARCHITECTURE:
 * - Minimal service layer (no sessions, no validation)
 * - Focus on providing organized word access
 * - Optional construction history tracking
 */

@MainActor
class CreativeSandboxService: ObservableObject {
    private let modelContext: ModelContext
    private let vocabularyService: VocabularyBuilderService

    @Published var categorizedWords: [WordCategory: [CategorizedWord]] = [:]
    @Published var allWords: [CategorizedWord] = []
    @Published var isLoaded = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.vocabularyService = VocabularyBuilderService(modelContext: modelContext)
    }

    // MARK: - Vocabulary Loading

    func loadVocabulary() throws {
        let vocabularyWords = try vocabularyService.loadVocabularyWords()

        // Convert to CategorizedWord (words can belong to multiple categories)
        var expandedWords: [CategorizedWord] = []
        for word in vocabularyWords {
            let categories = VocabularyCategories.categorize(word: word)
            for category in categories {
                let categorizedWord = CategorizedWord(
                    english: word.english,
                    romanised: word.romanised,
                    category: category,
                    frequency: word.frequency
                )
                expandedWords.append(categorizedWord)
            }
        }

        allWords = expandedWords

        // Group by category
        categorizedWords = Dictionary(grouping: allWords) { $0.category }

        // Sort within each category by frequency (most common first)
        for category in categorizedWords.keys {
            categorizedWords[category] = categorizedWords[category]?.sorted { $0.frequency > $1.frequency }
        }

        isLoaded = true
        DebugLogger.data("✅ CreativeSandbox: Loaded \(allWords.count) word-category pairs across \(categorizedWords.keys.count) categories")
    }

    // MARK: - Word Access

    func words(for category: WordCategory) -> [CategorizedWord] {
        return categorizedWords[category] ?? []
    }

    func allCategories() -> [WordCategory] {
        return WordCategory.allCases.filter { categorizedWords[$0] != nil }
    }
}

// MARK: - Construction History (Optional Future Feature)

struct PhraseConstruction: Identifiable {
    let id = UUID()
    let words: [CategorizedWord]
    let timestamp: Date

    var displayPhrase: String {
        words.map { $0.english }.joined(separator: " ")
    }

    var romanisedPhrase: String {
        words.map { $0.romanised }.joined(separator: " ")
    }
}
