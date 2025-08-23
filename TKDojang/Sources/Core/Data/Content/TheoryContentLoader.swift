import Foundation

/**
 * PURPOSE: Content loader for theory knowledge base data
 * 
 * Loads belt-specific theory content from JSON files including:
 * - Belt meanings and significance
 * - Taekwondo tenets and philosophy
 * - TAGB organizational history
 * - Korean terminology and language
 * - Grading theory requirements
 * 
 * Follows the established pattern used by PatternContentLoader and StepSparringContentLoader
 * for consistency in content loading architecture.
 */

// MARK: - Theory Content Models

struct TheoryContent: Codable {
    let beltLevel: String
    let beltId: String
    let theorySections: [TheorySection]
    
    enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case beltId = "belt_id"
        case theorySections = "theory_sections"
    }
}

struct TheorySection: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let content: TheorySectionContent
    let questions: [TheoryQuestion]
}

struct TheorySectionContent: Codable {
    // Dynamic content structure to accommodate different section types
    private let _content: [String: AnyCodableValue]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawContent = try container.decode([String: AnyCodableValue].self)
        self._content = rawContent
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_content)
    }
    
    // Accessor methods for common content types
    func getString(_ key: String) -> String? {
        return _content[key]?.stringValue
    }
    
    func getArray<T: Codable>(_ key: String, as type: T.Type) -> [T]? {
        return _content[key]?.arrayValue(as: type)
    }
    
    func getObject<T: Codable>(_ key: String, as type: T.Type) -> T? {
        return _content[key]?.objectValue(as: type)
    }
    
    // Raw access for complex structures
    var rawContent: [String: Any] {
        return _content.mapValues { $0.value }
    }
}

struct TheoryQuestion: Codable, Identifiable {
    let question: String
    let answer: String
    
    var id: String { question }
}

// MARK: - Dynamic Content Value Wrapper

struct AnyCodableValue: Codable {
    let value: Any
    
    var stringValue: String? { value as? String }
    var intValue: Int? { value as? Int }
    var boolValue: Bool? { value as? Bool }
    
    func arrayValue<T: Codable>(as type: T.Type) -> [T]? {
        guard let data = try? JSONSerialization.data(withJSONObject: value),
              let array = try? JSONDecoder().decode([T].self, from: data) else {
            return nil
        }
        return array
    }
    
    func objectValue<T: Codable>(as type: T.Type) -> T? {
        guard let data = try? JSONSerialization.data(withJSONObject: value),
              let object = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return object
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            // For complex types, convert to JSON data
            let data = try JSONSerialization.data(withJSONObject: value)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            try container.encode(jsonString)
        }
    }
}

// MARK: - Theory Content Loader

@MainActor
class TheoryContentLoader: ObservableObject {
    
    /**
     * PURPOSE: Load theory content for all belt levels
     * 
     * Returns dictionary mapping belt IDs to their theory content.
     * Uses the established pattern of loading JSON files from the app bundle.
     */
    static func loadAllTheoryContent() async -> [String: TheoryContent] {
        let beltIds = [
            "10th_keup", "9th_keup", "8th_keup", "7th_keup", "6th_keup",
            "5th_keup", "4th_keup", "3rd_keup", "2nd_keup", "1st_keup"
        ]
        
        var theoryContent: [String: TheoryContent] = [:]
        
        for beltId in beltIds {
            if let content = await loadTheoryContent(for: beltId) {
                theoryContent[beltId] = content
            } else {
                print("⚠️ Failed to load theory content for \(beltId)")
            }
        }
        
        print("✅ Loaded theory content for \(theoryContent.count) belt levels")
        return theoryContent
    }
    
    /**
     * PURPOSE: Load theory content for a specific belt level
     * 
     * Loads and parses JSON file containing theory sections, questions,
     * and knowledge base content for the specified belt level.
     */
    static func loadTheoryContent(for beltId: String) async -> TheoryContent? {
        guard let url = Bundle.main.url(forResource: "\(beltId)_theory", withExtension: "json") else {
            print("⚠️ Theory file not found: \(beltId)_theory.json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let theoryContent = try decoder.decode(TheoryContent.self, from: data)
            
            print("✅ Loaded theory content for \(theoryContent.beltLevel): \(theoryContent.theorySections.count) sections")
            return theoryContent
            
        } catch {
            print("❌ Failed to load theory content for \(beltId): \(error)")
            return nil
        }
    }
    
    /**
     * PURPOSE: Get all questions from theory content for testing
     * 
     * Extracts all questions across all theory sections for a belt level,
     * useful for generating theory-based test questions.
     */
    static func extractQuestions(from theoryContent: TheoryContent) -> [TheoryQuestion] {
        return theoryContent.theorySections.flatMap { $0.questions }
    }
    
    /**
     * PURPOSE: Filter theory sections by category
     * 
     * Returns theory sections matching specific categories like
     * "Philosophy", "Belt Knowledge", "Organization", "Language"
     */
    static func filterSections(from theoryContent: TheoryContent, byCategory category: String) -> [TheorySection] {
        return theoryContent.theorySections.filter { $0.category == category }
    }
}