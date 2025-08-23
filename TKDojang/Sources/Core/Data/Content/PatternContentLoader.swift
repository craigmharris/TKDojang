import Foundation
import SwiftData

/**
 * PatternContentLoader.swift
 * 
 * PURPOSE: Loads pattern content from JSON files into SwiftData models
 * 
 * FEATURES:
 * - JSON-based content loading for patterns
 * - Belt level association and filtering  
 * - Complete pattern and move data
 * - Korean terminology integration
 */

struct PatternContentLoader {
    private let patternService: PatternDataService
    
    init(patternService: PatternDataService) {
        self.patternService = patternService
    }
    
    /**
     * Loads all pattern content from JSON files
     */
    @MainActor
    func loadAllContent() {
        // Load patterns for each belt level
        loadPatternContent(filename: "9th_keup_patterns")
        loadPatternContent(filename: "8th_keup_patterns")
        loadPatternContent(filename: "7th_keup_patterns")
        loadPatternContent(filename: "6th_keup_patterns")
        loadPatternContent(filename: "5th_keup_patterns")
        loadPatternContent(filename: "4th_keup_patterns")
        loadPatternContent(filename: "3rd_keup_patterns")
        loadPatternContent(filename: "2nd_keup_patterns")
        loadPatternContent(filename: "1st_keup_patterns")
    }
    
    /**
     * Loads pattern content from specified filename
     */
    @MainActor
    private func loadPatternContent(filename: String) {
        loadContentFromFile(filename: filename)
    }
    
    /**
     * Generic method to load content from any pattern JSON file
     */
    @MainActor
    private func loadContentFromFile(filename: String) {
        // Use the same pattern as StepSparringContentLoader for consistency
        var url: URL?
        
        print("🔍 Searching for \(filename).json...")
        
        // First try: Patterns subdirectory (matches terminology pattern exactly)
        url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Patterns")
        if url != nil {
            print("✅ Found \(filename).json in Patterns subdirectory")
        } else {
            print("❌ Not found in Patterns subdirectory")
            
            // Debug: List what IS in the Patterns subdirectory
            if let bundlePath = Bundle.main.resourcePath {
                let patternsPath = "\(bundlePath)/Patterns"
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: patternsPath) {
                    do {
                        let contents = try fileManager.contentsOfDirectory(atPath: patternsPath)
                        print("📁 Patterns directory contents: \(contents)")
                    } catch {
                        print("❌ Failed to list Patterns contents: \(error)")
                    }
                } else {
                    print("❌ Patterns directory doesn't exist in bundle")
                }
            }
        }
        
        // Fallback: try main bundle root
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "json")
            if url != nil {
                print("✅ Found \(filename).json in main bundle root")
            } else {
                print("❌ Not found in main bundle root")
            }
        }
        
        // Fallback: try Core/Data/Content/Patterns path
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Core/Data/Content/Patterns")
            if url != nil {
                print("✅ Found \(filename).json in Core/Data/Content/Patterns")
            } else {
                print("❌ Not found in Core/Data/Content/Patterns")
            }
        }
        
        guard let fileUrl = url else {
            print("❌ Could not find \(filename).json in any location")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let contentData = try JSONDecoder().decode(PatternContentData.self, from: data)
            
            print("📚 Loading \(contentData.patterns.count) patterns from \(filename)")
            
            // Get belt levels for association
            let beltLevels = getBeltLevels()
            let beltLevelDict = Dictionary(uniqueKeysWithValues: beltLevels.map { ($0.shortName, $0) })
            
            // Create patterns from JSON data
            for patternData in contentData.patterns {
                let pattern = createPattern(from: patternData, beltLevelDict: beltLevelDict)
                // Use the service method instead of direct modelContext access
                savePattern(pattern)
            }
            print("✅ Successfully loaded \(contentData.patterns.count) patterns from \(filename)")
            
        } catch {
            print("❌ Failed to load pattern content from \(filename): \(error)")
        }
    }
    
    /**
     * Creates a Pattern from JSON data with belt level associations
     */
    private func createPattern(from data: PatternJSONData, beltLevelDict: [String: BeltLevel]) -> Pattern {
        let pattern = Pattern(
            name: data.name,
            hangul: data.hangul,
            englishMeaning: data.englishMeaning,
            significance: data.significance,
            moveCount: data.moveCount,
            diagramDescription: data.diagramDescription,
            startingStance: data.startingStance,
            videoURL: data.videoUrl,
            diagramImageURL: data.diagramImageUrl
        )
        
        // Associate with belt levels using mapping function
        pattern.beltLevels = data.applicableBeltLevels.compactMap { beltId in
            mapJSONIdToBeltLevel(jsonId: beltId, beltLevelDict: beltLevelDict)
        }
        
        print("🔍 BELT DEBUG: Pattern '\(data.name)':")
        print("   JSON belt IDs: \(data.applicableBeltLevels)")
        print("   Available belt levels: \(Array(beltLevelDict.keys).sorted())")
        print("   Found belt levels: \(pattern.beltLevels.map { "\($0.id) (\($0.shortName))" })")
        
        if pattern.beltLevels.isEmpty {
            print("⚠️ WARNING: Pattern '\(data.name)' has no associated belt levels!")
        }
        
        // Create moves and sort by move number to ensure correct order
        pattern.moves = data.moves
            .sorted { $0.moveNumber < $1.moveNumber }
            .map { moveData in
                createMove(from: moveData, pattern: pattern)
            }
        
        return pattern
    }
    
    /**
     * Creates a PatternMove from JSON data
     */
    private func createMove(from data: PatternMoveJSONData, pattern: Pattern) -> PatternMove {
        let move = PatternMove(
            moveNumber: data.moveNumber,
            stance: data.stance,
            technique: data.technique,
            direction: data.direction,
            target: data.target,
            keyPoints: data.keyPoints,
            commonMistakes: data.commonMistakes,
            executionNotes: data.executionNotes,
            imageURL: data.imageUrl
        )
        
        move.pattern = pattern
        return move
    }
    
    /**
     * Saves a pattern using the service
     */
    @MainActor
    private func savePattern(_ pattern: Pattern) {
        // Insert the pattern and moves into the context
        insertPatternWithMoves(pattern)
        
        // Save using service's context
        saveToDatabase(pattern.name)
    }
    
    /**
     * Inserts pattern and all its moves into the context
     */
    @MainActor
    private func insertPatternWithMoves(_ pattern: Pattern) {
        // We need to access the pattern service's model context
        // Let's create a method in the service for this
        patternService.insertPattern(pattern)
    }
    
    /**
     * Saves changes to database
     */
    @MainActor
    private func saveToDatabase(_ patternName: String) {
        do {
            try patternService.saveContext()
            print("✅ Saved pattern '\(patternName)'")
        } catch {
            print("❌ Failed to save pattern '\(patternName)': \(error)")
        }
    }
    
    /**
     * Gets all belt levels from the database via service
     */
    @MainActor
    private func getBeltLevels() -> [BeltLevel] {
        return patternService.getAllBeltLevels()
    }
    
    /**
     * Maps JSON belt IDs (like "6th_keup") to BeltLevel objects
     * Uses shortName matching since belt system JSON uses different ID format
     */
    private func mapJSONIdToBeltLevel(jsonId: String, beltLevelDict: [String: BeltLevel]) -> BeltLevel? {
        // Create mapping from JSON ID format to shortName format
        // "6th_keup" -> "6th Keup", "1st_dan" -> "1st Dan"
        let shortName = jsonId
            .replacingOccurrences(of: "_keup", with: " Keup")
            .replacingOccurrences(of: "_dan", with: " Dan")
            .replacingOccurrences(of: "keup", with: "Keup")
            .replacingOccurrences(of: "dan", with: "Dan")
        
        if let beltLevel = beltLevelDict[shortName] {
            return beltLevel
        }
        
        // Fallback: try capitalized version
        let capitalizedShortName = shortName.capitalized
        if let beltLevel = beltLevelDict[capitalizedShortName] {
            return beltLevel
        }
        
        print("⚠️ WARNING: Could not map JSON belt ID '\(jsonId)' to BeltLevel (tried '\(shortName)' and '\(capitalizedShortName)')")
        return nil
    }
}

// MARK: - JSON Data Models

struct PatternContentData: Codable {
    let beltLevel: String
    let category: String
    let type: String
    let description: String
    let metadata: PatternMetadata
    let patterns: [PatternJSONData]
    
    enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case category
        case type
        case description
        case metadata
        case patterns
    }
}

struct PatternMetadata: Codable {
    let createdAt: String
    let source: String
    let totalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case source
        case totalCount = "total_count"
    }
}

struct PatternJSONData: Codable {
    let name: String
    let hangul: String
    let pronunciation: String
    let phonetic: String
    let englishMeaning: String
    let significance: String
    let moveCount: Int
    let diagramDescription: String
    let startingStance: String
    let difficulty: Int
    let applicableBeltLevels: [String]
    let videoUrl: String?
    let diagramImageUrl: String?
    let moves: [PatternMoveJSONData]
    
    enum CodingKeys: String, CodingKey {
        case name
        case hangul
        case pronunciation
        case phonetic
        case englishMeaning = "english_meaning"
        case significance
        case moveCount = "move_count"
        case diagramDescription = "diagram_description"
        case startingStance = "starting_stance"
        case difficulty
        case applicableBeltLevels = "applicable_belt_levels"
        case videoUrl = "video_url"
        case diagramImageUrl = "diagram_image_url"
        case moves
    }
}

struct PatternMoveJSONData: Codable {
    let moveNumber: Int
    let stance: String
    let technique: String
    let koreanTechnique: String?
    let direction: String
    let target: String?
    let keyPoints: String
    let commonMistakes: String?
    let executionNotes: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case moveNumber = "move_number"
        case stance
        case technique
        case koreanTechnique = "korean_technique"
        case direction
        case target
        case keyPoints = "key_points"
        case commonMistakes = "common_mistakes"
        case executionNotes = "execution_notes"
        case imageUrl = "image_url"
    }
}