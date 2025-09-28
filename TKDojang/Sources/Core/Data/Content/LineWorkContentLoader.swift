import Foundation

/**
 * PURPOSE: Exercise-based LineWork content loader for traditional Taekwondo training
 *
 * Loads belt-specific line work requirements structured as complete exercise sequences
 * rather than isolated techniques. This matches actual syllabus methodology where
 * students practice flowing combinations of techniques with specific movement patterns.
 *
 * Key features:
 * - Exercise-based training sequences
 * - Movement type classification (STATIC/FWD/BWD/FWD & BWD/ALTERNATING)
 * - Multi-technique combinations with execution details
 * - Progressive skill development tracking
 */

// MARK: - LineWork Content Models

struct LineWorkContent: Codable {
    let beltLevel: String
    let beltId: String
    let beltColor: String
    let lineWorkExercises: [LineWorkExercise]
    let totalExercises: Int
    let skillFocus: [String]
    
    enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case beltId = "belt_id"
        case beltColor = "belt_color"
        case lineWorkExercises = "line_work_exercises"
        case totalExercises = "total_exercises"
        case skillFocus = "skill_focus"
    }
}

struct LineWorkExercise: Codable, Identifiable {
    let id: String
    let movementType: MovementType
    let order: Int
    let name: String
    let techniques: [LineWorkTechniqueDetail]
    let execution: ExerciseExecution
    let categories: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case movementType = "movement_type"
        case order, name, techniques, execution, categories
    }
}

struct LineWorkTechniqueDetail: Codable, Identifiable {
    let id: String
    let english: String
    let romanised: String
    let hangul: String
    let category: String
    let targetArea: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case id, english, romanised, hangul, category, description
        case targetArea = "target_area"
    }
}

enum MovementType: String, Codable, CaseIterable {
    case staticMovement = "STATIC"
    case forward = "FWD"
    case backward = "BWD"
    case forwardAndBackward = "FWD & BWD"
    case alternating = "ALTERNATING"
    
    var displayName: String {
        switch self {
        case .staticMovement:
            return "Static"
        case .forward:
            return "Forward"
        case .backward:
            return "Backward"
        case .forwardAndBackward:
            return "Forward & Backward"
        case .alternating:
            return "Alternating"
        }
    }
    
    var icon: String {
        switch self {
        case .staticMovement:
            return "figure.stand"
        case .forward:
            return "arrow.up"
        case .backward:
            return "arrow.down"
        case .forwardAndBackward:
            return "arrow.up.arrow.down"
        case .alternating:
            return "arrow.triangle.2.circlepath"
        }
    }
}

struct ExerciseExecution: Codable {
    let direction: String
    let repetitions: Int
    let movementPattern: String
    let sequenceNotes: String?
    let alternatingPattern: String?
    let keyPoints: [String]
    let commonMistakes: [String]?
    let executionTips: [String]?
    
    enum CodingKeys: String, CodingKey {
        case direction, repetitions
        case movementPattern = "movement_pattern"
        case sequenceNotes = "sequence_notes"
        case alternatingPattern = "alternating_pattern"
        case keyPoints = "key_points"
        case commonMistakes = "common_mistakes"
        case executionTips = "execution_tips"
    }
}


// MARK: - LineWork Category Classification

enum LineWorkCategory: String, CaseIterable {
    case stances = "Stances"
    case blocking = "Blocking"
    case striking = "Striking"
    case kicking = "Kicking"
    
    var icon: String {
        switch self {
        case .stances:
            return "figure.stand"
        case .blocking:
            return "shield"
        case .striking:
            return "hand.raised"
        case .kicking:
            return "figure.kickboxing"
        }
    }
    
    var color: String {
        switch self {
        case .stances:
            return "blue"
        case .blocking:
            return "green"
        case .striking:
            return "red"
        case .kicking:
            return "orange"
        }
    }
}

// MARK: - Display Models for UI

struct LineWorkExerciseDisplay {
    let id: String
    let name: String
    let movementType: MovementType
    let categories: [String]
    let repetitions: Int
    let techniqueCount: Int
    let isComplex: Bool
    
    init(from exercise: LineWorkExercise) {
        self.id = exercise.id
        self.name = exercise.name
        self.movementType = exercise.movementType
        self.categories = exercise.categories
        self.repetitions = exercise.execution.repetitions
        self.techniqueCount = exercise.techniques.count
        self.isComplex = exercise.techniques.count > 2 || exercise.execution.repetitions > 10
    }
}

struct LineWorkBeltDisplay {
    let beltLevel: String
    let beltId: String
    let beltColor: String
    let exerciseCount: Int
    let movementTypes: Set<MovementType>
    let skillFocus: [String]
    let hasComplexExercises: Bool
    
    init(from content: LineWorkContent) {
        self.beltLevel = content.beltLevel
        self.beltId = content.beltId
        self.beltColor = content.beltColor
        self.exerciseCount = content.lineWorkExercises.count
        self.movementTypes = Set(content.lineWorkExercises.map { $0.movementType })
        self.skillFocus = content.skillFocus
        self.hasComplexExercises = content.lineWorkExercises.contains { exercise in
            exercise.techniques.count > 3 || exercise.execution.repetitions > 20
        }
    }
}

// MARK: - LineWork Content Loader

@MainActor
class LineWorkContentLoader: ObservableObject {
    
    /**
     * PURPOSE: Load exercise-based line work content for all belt levels
     *
     * Returns dictionary mapping belt IDs to their complete exercise requirements.
     * Loads from new exercise-based JSON structure that matches traditional
     * Taekwondo training methodology.
     */
    static func loadAllLineWorkContent() async -> [String: LineWorkContent] {
        let beltIds = [
            "10th_keup", "9th_keup", "8th_keup", "7th_keup", "6th_keup",
            "5th_keup", "4th_keup", "3rd_keup", "2nd_keup", "1st_keup"
        ]
        
        var lineWorkContent: [String: LineWorkContent] = [:]
        
        for beltId in beltIds {
            if let content = await loadLineWorkContent(for: beltId) {
                lineWorkContent[beltId] = content
            } else {
                DebugLogger.data("⚠️ Failed to load line work content for \(beltId)")
            }
        }
        
        DebugLogger.data("✅ Loaded line work content for \(lineWorkContent.count) belt levels")
        return lineWorkContent
    }
    
    /**
     * PURPOSE: Load line work content for a specific belt level
     *
     * Loads and parses JSON file containing exercise sequences, movement patterns,
     * and skill requirements for the specified belt level.
     */
    static func loadLineWorkContent(for beltId: String) async -> LineWorkContent? {
        guard let url = Bundle.main.url(forResource: "\(beltId)_linework", withExtension: "json") else {
            DebugLogger.data("⚠️ Line work file not found: \(beltId)_linework.json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let lineWorkContent = try decoder.decode(LineWorkContent.self, from: data)
            
            DebugLogger.data("✅ Loaded line work content for \(lineWorkContent.beltLevel): \(lineWorkContent.totalExercises) exercises")
            return lineWorkContent
            
        } catch {
            DebugLogger.data("❌ Failed to load line work content for \(beltId): \(error)")
            return nil
        }
    }
    
    /**
     * PURPOSE: Filter exercises by movement type
     *
     * Returns exercises matching specific movement patterns for
     * focused practice sessions (e.g., only forward movements).
     */
    static func filterExercises(from content: LineWorkContent, byMovementType movementType: MovementType) -> [LineWorkExercise] {
        return content.lineWorkExercises.filter { $0.movementType == movementType }
    }
    
    /**
     * PURPOSE: Filter exercises by category
     *
     * Returns exercises containing specific technique categories
     * like "Stances", "Blocking", "Striking", "Kicking".
     */
    static func filterExercises(from content: LineWorkContent, byCategory category: String) -> [LineWorkExercise] {
        return content.lineWorkExercises.filter { $0.categories.contains(category) }
    }
    
    /**
     * PURPOSE: Get exercises sorted by complexity
     *
     * Returns exercises ordered by complexity (technique count + repetitions)
     * for progressive training sessions.
     */
    static func getExercisesByComplexity(from content: LineWorkContent) -> [LineWorkExercise] {
        return content.lineWorkExercises.sorted { exercise1, exercise2 in
            let complexity1 = exercise1.techniques.count + (exercise1.execution.repetitions / 10)
            let complexity2 = exercise2.techniques.count + (exercise2.execution.repetitions / 10)
            return complexity1 < complexity2
        }
    }
    
    /**
     * PURPOSE: Extract all unique techniques from exercises
     *
     * Returns list of all individual techniques mentioned across
     * all exercises for vocabulary and reference purposes.
     */
    static func extractUniqueTechniques(from content: LineWorkContent) -> [String] {
        let allTechniques = content.lineWorkExercises.flatMap { $0.techniques }
        return Array(Set(allTechniques.map { $0.english })).sorted()
    }
    
    /**
     * PURPOSE: Calculate total repetition count for belt level
     *
     * Sums all exercise repetitions to provide training volume
     * metrics for the belt level requirements.
     */
    static func getTotalRepetitions(from content: LineWorkContent) -> Int {
        return content.lineWorkExercises.reduce(0) { $0 + $1.execution.repetitions }
    }
    
    /**
     * PURPOSE: Get practice sequence details for an exercise
     *
     * Returns complete execution details including movement pattern,
     * key points, and sequence notes for guided practice.
     */
    static func getPracticeDetails(for exercise: LineWorkExercise) -> ExerciseExecution {
        return exercise.execution
    }
}