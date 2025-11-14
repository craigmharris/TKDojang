import Foundation

/**
 * TechniquePhraseLoader.swift
 *
 * PURPOSE: Load real technique names from JSON files for Phrase Decoder game
 *
 * FEATURES:
 * - Loads techniques from blocks.json, kicks.json, strikes.json, hand_techniques.json
 * - Extracts English and Korean romanized names
 * - Provides technique phrase pairs for vocabulary learning
 *
 * ARCHITECTURE:
 * - Uses production technique JSON files (same as Techniques feature)
 * - Creates TechniquePhrase objects for Phrase Decoder challenges
 * - Ensures authentic technique terminology (not generated)
 */

// MARK: - Technique Phrase Model

struct TechniquePhrase: Identifiable {
    let id: String
    let english: String
    let koreanRomanized: String
    let category: TechniqueFileCategory

    /// Get English words as array
    var englishWords: [String] {
        english.components(separatedBy: " ")
    }

    /// Get Korean romanized words as array
    var koreanWords: [String] {
        koreanRomanized.components(separatedBy: " ")
    }

    /// Word count (for filtering by difficulty)
    var wordCount: Int {
        englishWords.count
    }
}

enum TechniqueFileCategory: String, CaseIterable {
    case blocks
    case kicks
    case strikes
    case handTechniques = "hand_techniques"

    var displayName: String {
        switch self {
        case .blocks: return "Blocks"
        case .kicks: return "Kicks"
        case .strikes: return "Strikes"
        case .handTechniques: return "Hand Techniques"
        }
    }

    var filename: String {
        switch self {
        case .blocks: return "blocks.json"
        case .kicks: return "kicks.json"
        case .strikes: return "strikes.json"
        case .handTechniques: return "hand_techniques.json"
        }
    }
}

// MARK: - JSON Structure

private struct TechniqueFile: Codable {
    let techniques: [TechniqueJSONData]
}

private struct TechniqueJSONData: Codable {
    let id: String
    let names: TechniqueJSONNames
}

private struct TechniqueJSONNames: Codable {
    let english: String
    let korean_romanized: String

    enum CodingKeys: String, CodingKey {
        case english
        case korean_romanized
    }
}

// MARK: - Loader

class TechniquePhraseLoader {

    static func loadAllTechniques() throws -> [TechniquePhrase] {
        var allPhrases: [TechniquePhrase] = []

        for category in TechniqueFileCategory.allCases {
            let phrases = try loadTechniques(category: category)
            allPhrases.append(contentsOf: phrases)
        }

        DebugLogger.data("✅ TechniquePhraseLoader: Loaded \(allPhrases.count) technique phrases")
        return allPhrases
    }

    static func loadTechniques(category: TechniqueFileCategory) throws -> [TechniquePhrase] {
        let resourceName = category.filename.replacingOccurrences(of: ".json", with: "")

        // Try multiple paths (same pattern as TechniquesDataService)
        var url: URL?

        // First try: Techniques subdirectory
        url = Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "Techniques")

        if url == nil {
            // Fallback: main bundle root
            url = Bundle.main.url(forResource: resourceName, withExtension: "json")
        }

        if url == nil {
            // Fallback: Core/Data/Content/Techniques path
            url = Bundle.main.url(forResource: resourceName, withExtension: "json", subdirectory: "Core/Data/Content/Techniques")
        }

        guard let url = url else {
            DebugLogger.data("❌ TechniquePhraseLoader: Could not find \(category.filename)")
            throw TechniquePhraseError.fileNotFound(category.filename)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let file = try decoder.decode(TechniqueFile.self, from: data)

        let phrases = file.techniques.map { technique in
            TechniquePhrase(
                id: technique.id,
                english: technique.names.english,
                koreanRomanized: technique.names.korean_romanized,
                category: category
            )
        }

        DebugLogger.data("  → Loaded \(phrases.count) phrases from \(category.displayName)")
        return phrases
    }

    /// Filter phrases by word count (for difficulty levels)
    static func filterByWordCount(_ phrases: [TechniquePhrase], wordCount: Int) -> [TechniquePhrase] {
        return phrases.filter { $0.wordCount == wordCount }
    }

    /// Filter phrases by word count range
    static func filterByWordCountRange(_ phrases: [TechniquePhrase], minWords: Int, maxWords: Int) -> [TechniquePhrase] {
        return phrases.filter { $0.wordCount >= minWords && $0.wordCount <= maxWords }
    }
}

// MARK: - Errors

enum TechniquePhraseError: Error, LocalizedError {
    case fileNotFound(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Technique file not found: \(filename)"
        case .decodingFailed(let message):
            return "Failed to decode technique data: \(message)"
        }
    }
}
