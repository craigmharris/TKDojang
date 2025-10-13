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
     * Dynamically loads all pattern content from JSON files discovered in Patterns subdirectory
     */
    @MainActor
    func loadAllContent() {
        // Dynamically discover pattern files
        let patternFiles = discoverPatternFiles()
        
        DebugLogger.data("📁 Dynamically discovered \(patternFiles.count) pattern JSON files: \(patternFiles)")
        
        // Load patterns for each discovered file
        for filename in patternFiles {
            loadPatternContent(filename: filename)
        }
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
        
        DebugLogger.data("🔍 Searching for \(filename).json...")
        
        // First try: Patterns subdirectory (consistent with architectural pattern)
        url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Patterns")
        if url != nil {
            DebugLogger.data("✅ Found \(filename).json in Patterns subdirectory")
        } else {
            DebugLogger.data("❌ Not found in Patterns subdirectory")
            
            // Fallback: try main bundle root for deployment flexibility
            url = Bundle.main.url(forResource: filename, withExtension: "json")
            if url != nil {
                DebugLogger.data("✅ Found \(filename).json in main bundle root (fallback)")
            } else {
                DebugLogger.data("❌ Not found in main bundle root")
                
                // Fallback: try Core/Data/Content/Patterns path
                url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Core/Data/Content/Patterns")
                if url != nil {
                    DebugLogger.data("✅ Found \(filename).json in Core/Data/Content/Patterns (fallback)")
                } else {
                    DebugLogger.data("❌ Not found in Core/Data/Content/Patterns")
                }
            }
        }
        
        guard let fileUrl = url else {
            DebugLogger.data("❌ Could not find \(filename).json in any location")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let contentData = try JSONDecoder().decode(PatternContentData.self, from: data)
            
            DebugLogger.data("📚 Loading \(contentData.patterns.count) patterns from \(filename)")
            
            // Get belt levels for association
            let beltLevels = getBeltLevels()
            let beltLevelDict = Dictionary(uniqueKeysWithValues: beltLevels.map { ($0.shortName, $0) })
            
            // Create patterns from JSON data
            for patternData in contentData.patterns {
                DebugLogger.data("🔍 DEBUG: Creating pattern '\(patternData.name)' with \(patternData.moves.count) moves from JSON")
                let pattern = createPattern(from: patternData, beltLevelDict: beltLevelDict)
                DebugLogger.data("🔍 DEBUG: Pattern object created: '\(pattern.name)' has \(pattern.moves.count) moves")
                // Use the service method instead of direct modelContext access
                savePattern(pattern)
                DebugLogger.data("🔍 DEBUG: Pattern saved: '\(pattern.name)' - final move count: \(pattern.moves.count)")
            }
            DebugLogger.data("✅ Successfully loaded \(contentData.patterns.count) patterns from \(filename)")
            
        } catch {
            DebugLogger.data("❌ Failed to load pattern content from \(filename): \(error)")
        }
    }
    
    /**
     * Dynamically discovers pattern files from Patterns subdirectory
     */
    private func discoverPatternFiles() -> [String] {
        var foundFiles: [String] = []
        
        // First try: Scan Patterns subdirectory for any JSON files ending with "_patterns"
        if let patternsPath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "Patterns") {
            DebugLogger.data("📁 Scanning Patterns subdirectory: \(patternsPath)")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: patternsPath)
                let patternFiles = contents.filter { filename in
                    filename.hasSuffix(".json") && filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan Patterns subdirectory: \(error)")
            }
        }
        
        // Fallback: Try bundle root for files containing pattern patterns
        if foundFiles.isEmpty, let bundlePath = Bundle.main.resourcePath {
            DebugLogger.data("📁 Patterns subdirectory not found, scanning bundle root for pattern files...")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let patternFiles = contents.filter { filename in
                    guard filename.hasSuffix(".json") else { return false }
                    // Look for files that match pattern naming conventions
                    return filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan bundle root: \(error)")
            }
        }
        
        return foundFiles.sorted()
    }
    
    /**
     * Creates a Pattern from JSON data with belt level associations
     */
    private func createPattern(from data: PatternJSONData, beltLevelDict: [String: BeltLevel]) -> Pattern {
        let pattern = Pattern(
            name: data.name,
            hangul: data.hangul,
            pronunciation: data.pronunciation,
            phonetic: data.phonetic,
            englishMeaning: data.englishMeaning,
            significance: data.significance,
            moveCount: data.moveCount,
            diagramDescription: data.diagramDescription,
            startingStance: data.startingStance,
            difficulty: data.difficulty,
            videoURL: data.videoUrl,
            diagramImageURL: data.diagramImageUrl,
            startingMoveImageURL: data.startingMoveImageUrl
        )
        
        // Associate with belt levels using mapping function
        pattern.beltLevels = data.applicableBeltLevels.compactMap { beltId in
            mapJSONIdToBeltLevel(jsonId: beltId, beltLevelDict: beltLevelDict)
        }
        
        DebugLogger.data("🔍 BELT DEBUG: Pattern '\(data.name)':")
        DebugLogger.data("   JSON belt IDs: \(data.applicableBeltLevels)")
        DebugLogger.data("   Available belt levels: \(Array(beltLevelDict.keys).sorted())")
        DebugLogger.data("   Found belt levels: \(pattern.beltLevels.map { "\($0.id) (\($0.shortName))" })")
        
        if pattern.beltLevels.isEmpty {
            DebugLogger.data("⚠️ WARNING: Pattern '\(data.name)' has no associated belt levels!")
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
            koreanTechnique: data.koreanTechnique ?? "",
            direction: data.direction,
            target: data.target,
            keyPoints: data.keyPoints,
            commonMistakes: data.commonMistakes,
            executionNotes: data.executionNotes,
            movement: data.movement,
            executionSpeed: data.executionSpeed,
            imageURL: data.imageURL,
            image2URL: data.image2URL,
            image3URL: data.image3URL
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
            DebugLogger.data("✅ Saved pattern '\(patternName)'")
        } catch {
            DebugLogger.data("❌ Failed to save pattern '\(patternName)': \(error)")
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
        
        DebugLogger.data("⚠️ WARNING: Could not map JSON belt ID '\(jsonId)' to BeltLevel (tried '\(shortName)' and '\(capitalizedShortName)')")
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
    let startingMoveImageUrl: String?
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
        case startingMoveImageUrl = "starting_move_image_url"
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
    let movement: String?
    let executionSpeed: String?
    let imageURL: String?
    let image2URL: String?
    let image3URL: String?
    
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
        case movement = "movement"
        case executionSpeed = "execution_speed"
        case imageURL = "imageURL"
        case image2URL = "image2URL"
        case image3URL = "image3URL"
    }
}