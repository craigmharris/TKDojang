import Foundation

/**
 * PURPOSE: Content loader for line work technique data
 * 
 * Loads belt-specific line work requirements from JSON files including:
 * - Stance work moving forward/backward
 * - Blocking techniques in line formation
 * - Striking techniques with footwork
 * - Practice patterns and sequences
 * 
 * Follows the established pattern used by PatternContentLoader and StepSparringContentLoader
 * for consistency in content loading architecture.
 */

// MARK: - Line Work Content Models

struct LineWorkContent: Codable {
    let beltLevel: String
    let beltId: String
    let lineWorkSets: [LineWorkSet]
    let practiceNotes: PracticeNotes
    
    enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case beltId = "belt_id"
        case lineWorkSets = "line_work_sets"
        case practiceNotes = "practice_notes"
    }
}

struct LineWorkSet: Codable, Identifiable {
    let id: String
    let title: String
    let category: String
    let description: String
    let techniques: [LineWorkTechnique]
}

struct LineWorkTechnique: Codable, Identifiable {
    let id: String
    let name: String
    let korean: String
    let directionPattern: [DirectionSequence]
    let keyPoints: [String]
    let commonMistakes: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, korean
        case directionPattern = "direction_pattern"
        case keyPoints = "key_points"
        case commonMistakes = "common_mistakes"
    }
}

struct DirectionSequence: Codable, Identifiable, Equatable {
    let direction: String // "forward" or "backward"
    let count: Int
    let description: String
    
    var id: String { "\(direction)_\(count)" }
}

struct PracticeNotes: Codable {
    let warmup: String
    let focusAreas: [String]
    let progression: String
    
    enum CodingKeys: String, CodingKey {
        case warmup
        case focusAreas = "focus_areas"
        case progression
    }
}

// MARK: - Line Work Content Loader

@MainActor
class LineWorkContentLoader: ObservableObject {
    
    /**
     * PURPOSE: Load line work content for all belt levels
     * 
     * Returns dictionary mapping belt IDs to their line work requirements.
     * Uses the established pattern of loading JSON files from the app bundle.
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
                print("⚠️ Failed to load line work content for \(beltId)")
            }
        }
        
        print("✅ Loaded line work content for \(lineWorkContent.count) belt levels")
        return lineWorkContent
    }
    
    /**
     * PURPOSE: Load line work content for a specific belt level
     * 
     * Loads and parses JSON file containing line work sets, techniques,
     * and practice requirements for the specified belt level.
     */
    static func loadLineWorkContent(for beltId: String) async -> LineWorkContent? {
        guard let url = Bundle.main.url(forResource: "\(beltId)_linework", withExtension: "json") else {
            print("⚠️ Line work file not found: \(beltId)_linework.json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let lineWorkContent = try decoder.decode(LineWorkContent.self, from: data)
            
            let techniqueCount = lineWorkContent.lineWorkSets.reduce(0) { $0 + $1.techniques.count }
            print("✅ Loaded line work content for \(lineWorkContent.beltLevel): \(techniqueCount) techniques")
            return lineWorkContent
            
        } catch {
            print("❌ Failed to load line work content for \(beltId): \(error)")
            return nil
        }
    }
    
    /**
     * PURPOSE: Get all techniques from line work content
     * 
     * Flattens all techniques across all line work sets for a belt level,
     * useful for practice session creation and progress tracking.
     */
    static func extractTechniques(from lineWorkContent: LineWorkContent) -> [LineWorkTechnique] {
        return lineWorkContent.lineWorkSets.flatMap { $0.techniques }
    }
    
    /**
     * PURPOSE: Filter line work sets by category
     * 
     * Returns line work sets matching specific categories like
     * "Stances", "Blocking", "Striking", "Kicking"
     */
    static func filterSets(from lineWorkContent: LineWorkContent, byCategory category: String) -> [LineWorkSet] {
        return lineWorkContent.lineWorkSets.filter { $0.category == category }
    }
    
    /**
     * PURPOSE: Calculate total technique count for belt level
     * 
     * Returns the total number of individual techniques that need to be
     * practiced for the specified belt level's grading requirements.
     */
    static func getTechniqueCount(from lineWorkContent: LineWorkContent) -> Int {
        return lineWorkContent.lineWorkSets.reduce(0) { $0 + $1.techniques.count }
    }
    
    /**
     * PURPOSE: Get practice sequence for a technique
     * 
     * Returns the complete forward/backward sequence pattern for practicing
     * a specific technique, including repetition counts and descriptions.
     */
    static func getPracticeSequence(for technique: LineWorkTechnique) -> [DirectionSequence] {
        return technique.directionPattern
    }
}