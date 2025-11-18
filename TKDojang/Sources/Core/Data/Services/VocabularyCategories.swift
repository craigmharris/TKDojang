import Foundation

/**
 * VocabularyCategories.swift
 *
 * PURPOSE: Define word categories for Korean Taekwondo phrase construction (7-Category System)
 *
 * FEATURES:
 * - 7 grammatical categories based on real technique analysis
 * - Words can belong to MULTIPLE categories (context-dependent)
 * - 96 actual techniques analyzed to determine proper categorization
 * - Supports complex phrases like "Twin Outer Forearm Inward High Block"
 *
 * CATEGORY SYSTEM:
 * 1. TECHNIQUE_MODIFIER: Modifies entire technique (twin, double, flying, x, w)
 * 2. POSITION: Body part orientation (outer/inner forearm, back fist, side fist)
 * 3. TOOL: Body parts used (forearm, fist, knife, palm, elbow, foot)
 * 4. DIRECTION: Movement path (inward, outward, rising, front kick, turning)
 * 5. TARGET: Height sections (high, middle, low)
 * 6. EXECUTION: How action is performed (pressing, snap, guarding, wedging)
 * 7. ACTION: Core technique verb - ALWAYS REQUIRED (block, kick, strike, punch, thrust)
 *
 * MULTI-CATEGORY WORDS:
 * - "front/back/side" → POSITION (Back Fist) + DIRECTION (Back Kick)
 * - "outer/inner" → POSITION (primary use)
 * - "rising" → DIRECTION (rising motion)
 */

// MARK: - Word Category Enum

enum WordCategory: String, CaseIterable, Identifiable {
    case techniqueModifier = "Technique Modifier"
    case position = "Position"
    case tool = "Tool"
    case direction = "Direction"
    case target = "Target"
    case execution = "Execution"
    case action = "Action"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .techniqueModifier:
            return "Modifies entire technique (twin, double, flying, x)"
        case .position:
            return "Body part orientation (outer forearm, back fist, inner knife)"
        case .tool:
            return "Body part used (forearm, fist, palm, knife, foot, elbow)"
        case .direction:
            return "Movement direction (inward, rising, turning, front, back)"
        case .target:
            return "Target height (high, middle, low)"
        case .execution:
            return "How performed (pressing, snap, guarding, wedging, checking)"
        case .action:
            return "Core technique (block, kick, strike, punch, thrust)"
        }
    }

    var icon: String {
        switch self {
        case .techniqueModifier: return "star.fill"
        case .position: return "move.3d"
        case .tool: return "hand.raised.fill"
        case .direction: return "arrow.up.and.down.and.arrow.left.and.right"
        case .target: return "target"
        case .execution: return "gearshape.fill"
        case .action: return "bolt.fill"
        }
    }

    var color: String {
        switch self {
        case .techniqueModifier: return "purple"
        case .position: return "cyan"
        case .tool: return "blue"
        case .direction: return "green"
        case .target: return "orange"
        case .execution: return "yellow"
        case .action: return "red"
        }
    }
}

// MARK: - Categorized Vocabulary

struct CategorizedWord: Identifiable, Hashable {
    let english: String
    let romanised: String
    let category: WordCategory
    let frequency: Int

    var id: String { "\(english)-\(category.rawValue)" } // Unique per category
}

class VocabularyCategories {

    // MARK: - Category Mappings

    /**
     * Map each English word to its possible grammatical categories
     * Returns array because words can belong to multiple categories
     */
    static func categorize(word: VocabularyWord) -> [WordCategory] {
        let key = word.english.lowercased()
        var categories: [WordCategory] = []

        // Check each category
        if techniqueModifierWords.contains(key) { categories.append(.techniqueModifier) }
        if positionWords.contains(key) { categories.append(.position) }
        if toolWords.contains(key) { categories.append(.tool) }
        if directionWords.contains(key) { categories.append(.direction) }
        if targetWords.contains(key) { categories.append(.target) }
        if executionWords.contains(key) { categories.append(.execution) }
        if actionWords.contains(key) { categories.append(.action) }

        return categories
    }

    /**
     * Get all words in a specific category
     */
    static func words(in category: WordCategory, from vocabulary: [VocabularyWord]) -> [CategorizedWord] {
        return vocabulary.compactMap { word in
            let categories = categorize(word: word)
            guard categories.contains(category) else {
                return nil
            }
            return CategorizedWord(
                english: word.english,
                romanised: word.romanised,
                category: category,
                frequency: word.frequency
            )
        }.sorted { $0.frequency > $1.frequency } // Most frequent first
    }

    // MARK: - Category Word Sets

    /// Modifies entire technique (appears first in phrase)
    private static let techniqueModifierWords: Set<String> = [
        "twin", "double", "x", "w", "u",
        "flying", "jumping", "parallel"
    ]

    /// Body part orientation/position (modifies tool specifically)
    private static let positionWords: Set<String> = [
        // Primary position modifiers
        "outer", "inner", "reverse",
        // Multi-use: position when modifying tool
        "back", "front", "side", "upper", "rear",
        // Shape/form positions
        "vertical", "straight", "flat", "arc"
    ]

    /// Body parts used as striking/blocking surfaces
    private static let toolWords: Set<String> = [
        // Hand tools
        "forearm", "fist", "knife", "palm", "hand", "fingertip",
        // Arm tools
        "elbow",
        // Leg tools
        "foot", "heel", "knee", "sole",
        // Body sections
        "waist"
    ]

    /// Movement direction/path
    private static let directionWords: Set<String> = [
        // Primary directions
        "inward", "outward", "upward", "downward", "rising",
        // Multi-use: direction when describing movement
        "front", "back", "side", "rear",
        // Rotational
        "turning", "circular", "crescent", "hook",
        // Linear
        "forward", "backward", "straight", "vertical",
        // Lateral
        "left", "right"
    ]

    /// Target height sections
    private static let targetWords: Set<String> = [
        "high", "middle", "low"
    ]

    /// How the action is executed/performed
    private static let executionWords: Set<String> = [
        // Execution modifiers
        "pressing", "pushing", "hooking", "checking", "wedging",
        "snap", "grasping", "piercing", "guarding",
        // Descriptive execution
        "bending", "shifting", "sliding", "jumping",
        "fixed", "closed", "upset"
    ]

    /// Core technique verbs (ALWAYS REQUIRED)
    private static let actionWords: Set<String> = [
        "block", "kick", "strike", "punch", "thrust"
    ]

    // MARK: - Statistics

    /**
     * Get category distribution from vocabulary
     */
    static func categoryDistribution(from vocabulary: [VocabularyWord]) -> [WordCategory: Int] {
        var distribution: [WordCategory: Int] = [:]

        for word in vocabulary {
            let categories = categorize(word: word)
            for category in categories {
                distribution[category, default: 0] += 1
            }
        }

        return distribution
    }

    /**
     * Get total categorized words (unique words, even if in multiple categories)
     */
    static func categorizedCount(from vocabulary: [VocabularyWord]) -> Int {
        return vocabulary.filter { !categorize(word: $0).isEmpty }.count
    }

    /**
     * Get uncategorized words (numbers, commands, etc.)
     */
    static func uncategorizedWords(from vocabulary: [VocabularyWord]) -> [VocabularyWord] {
        return vocabulary.filter { categorize(word: $0).isEmpty }
    }

    /**
     * Get words that belong to multiple categories
     */
    static func multiCategoryWords(from vocabulary: [VocabularyWord]) -> [(VocabularyWord, [WordCategory])] {
        return vocabulary.compactMap { word in
            let categories = categorize(word: word)
            return categories.count > 1 ? (word, categories) : nil
        }
    }
}

// MARK: - Example Phrases (for reference)

/**
 * Examples of valid phrase structures using 7-category system:
 *
 * 2-word phrases:
 * - [Tool] + [Action]: "Forearm Block" (Palmok Makgi)
 * - [Execution] + [Action]: "Pressing Block" (Noollo Makgi)
 * - [Direction] + [Action]: "Rising Block" (Chookyo Makgi)
 *
 * 3-word phrases:
 * - [Position] + [Tool] + [Action]: "Outer Forearm Block" (Bakat Palmok Makgi)
 * - [Tool] + [Execution] + [Action]: "Knife Checking Block" (Sonkal Momchau Makgi)
 * - [Tool] + [Target] + [Action]: "Fist Middle Punch" (Joomuk Kaunde Jirugi)
 * - [Technique_Modifier] + [Tool] + [Action]: "Twin Fist Punch"
 *
 * 4-word phrases:
 * - [Position] + [Tool] + [Direction] + [Action]: "Outer Forearm Inward Block"
 * - [Position] + [Tool] + [Target] + [Action]: "Outer Forearm High Block"
 * - [Technique_Modifier] + [Tool] + [Execution] + [Action]: "Twin Knife Guarding Block"
 * - [Direction] + [Tool] + [Target] + [Action]: "Front Knife High Strike"
 *
 * 5-word phrases:
 * - [Technique_Modifier] + [Position] + [Tool] + [Target] + [Action]: "Twin Outer Forearm High Block"
 * - [Position] + [Tool] + [Direction] + [Target] + [Action]: "Outer Forearm Inward High Block"
 * - [Technique_Modifier] + [Position] + [Tool] + [Execution] + [Action]: "X Knife Checking Block"
 *
 * 6-word phrases:
 * - [Technique_Modifier] + [Position] + [Tool] + [Direction] + [Target] + [Action]:
 *   "Twin Outer Forearm Inward High Block" (Sang Bakat Palmok Anaero Nopunde Makgi)
 */
