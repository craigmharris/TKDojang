import Foundation
import SwiftData

/**
 * TechniquesDataService.swift
 * 
 * PURPOSE: Data service for loading and managing Taekwondo technique reference data
 * 
 * DESIGN PATTERN: Service Layer Pattern
 * WHY: Separates data loading logic from UI, provides a clean API for accessing
 * technique data, and enables easy testing and mocking.
 * 
 * FEATURES:
 * - Loads all technique JSON files from the Techniques directory
 * - Provides filtering by belt level, category, difficulty, and tags
 * - Supports advanced search across all technique properties
 * - Maintains in-memory cache for performance
 * - Thread-safe operations with proper async/await patterns
 */

// MARK: - Technique Data Models

/**
 * Unified technique model that can represent any type of technique
 */
struct Technique: Identifiable, Codable {
    let id: String
    let names: TechniqueNames
    let description: String
    var category: String
    let beltLevels: [String]
    let difficulty: String
    let tags: [String]
    let images: [String]
    let commonMistakes: [String]
    
    // Optional properties that vary by technique type
    let execution: TechniqueExecution?
    let strikingTool: TechniqueNames?
    let blockingTool: TechniqueNames?
    let targetAreas: [String]?
    let applicableStances: [String]?
    let variations: [String]?
    let skillsDeveloped: [String]?
    let characteristics: TechniqueCharacteristics?
    let transitionsTo: [String]?
    
    // Sparring-specific properties
    let sparringType: String?
    let participants: Int?
    let attackPattern: String?
    let defensePattern: String?
    
    // Combination-specific properties
    let sequence: [TechniqueStep]?
    let combinationType: String?
    let totalMovements: Int?
    let setupTechniques: [String]?
    let followUpOptions: [String]?
    
    // Belt requirement properties
    let colorSignificance: String?
    let minimumTrainingTime: String?
    let requiredTechniques: [String]?
    let requiredFitness: [String]?
    let theoryRequirements: [String]?
    let pattern: String?
    let sparring: String?
    let breaking: String?
    
    // Fundamental properties
    let exerciseType: String?
    let movements: Int?
    
    // Footwork properties
    let footUsed: String?
    let primaryPurpose: String?
    let timing: String?
    
    var displayName: String {
        names.english
    }
    
    var koreanName: String {
        names.korean
    }
    
    var phoneticName: String {
        names.phonetic
    }
    
    /**
     * Check if technique is available for a specific belt level
     */
    func isAvailableForBelt(_ beltLevel: String) -> Bool {
        return beltLevels.contains(beltLevel)
    }
    
    /**
     * Get the minimum belt level required for this technique
     */
    var minimumBeltLevel: String? {
        let beltOrder = ["10th_keup", "9th_keup", "8th_keup", "7th_keup", "6th_keup", 
                        "5th_keup", "4th_keup", "3rd_keup", "2nd_keup", "1st_keup", "1st_dan", "2nd_dan"]
        
        for belt in beltOrder {
            if beltLevels.contains(belt) {
                return belt
            }
        }
        return nil
    }
}

struct TechniqueNames: Codable {
    let korean: String
    let koreanRomanized: String
    let english: String
    let phonetic: String
    
    private enum CodingKeys: String, CodingKey {
        case korean
        case koreanRomanized = "korean_romanized"
        case english
        case phonetic
    }
}

struct TechniqueExecution: Codable {
    let chamber: String?
    let strike: String?
    let block: String?
    let retraction: String?
    let setup: String?
    let kick: String?
    let recovery: String?
    let pattern: String?
    let sequence: String?
    let technique: String?
    let footPosition: String?
    let weightDistribution: String?
    let bodyPosture: String?
    
    private enum CodingKeys: String, CodingKey {
        case chamber, strike, block, retraction, setup, kick, recovery
        case pattern, sequence, technique
        case footPosition = "foot_position"
        case weightDistribution = "weight_distribution"
        case bodyPosture = "body_posture"
    }
}

struct TechniqueCharacteristics: Codable {
    let stability: String?
    let mobility: String?
    let attackReadiness: String?
    let defenseReadiness: String?
    
    private enum CodingKeys: String, CodingKey {
        case stability, mobility
        case attackReadiness = "attack_readiness"
        case defenseReadiness = "defense_readiness"
    }
}

struct TechniqueStep: Codable {
    let step: Int
    let technique: String
    let korean: String?
    let timing: String?
}

// MARK: - Technique Category Data Model

struct TechniqueCategory: Identifiable, Codable {
    let id: String
    let name: String
    let korean: String
    let koreanRomanized: String
    let phonetic: String
    let description: String
    let file: String
    let icon: String
    let techniqueCount: Int
    let subcategories: [TechniqueSubcategory]?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, korean, description, file, icon, subcategories
        case koreanRomanized = "korean_romanized"
        case phonetic
        case techniqueCount = "technique_count"
    }
}

struct TechniqueSubcategory: Codable {
    let name: String
    let techniques: [String]
}

// MARK: - Target Area Models

struct TargetArea: Identifiable, Codable {
    let id: String
    let region: String
    let korean: String
    let koreanRomanized: String
    let phonetic: String
    let targets: [TargetPoint]
    
    private enum CodingKeys: String, CodingKey {
        case id, region, korean, targets
        case koreanRomanized = "korean_romanized"
        case phonetic
    }
}

struct TargetPoint: Identifiable, Codable {
    let id: String
    let name: String
    let korean: String
    let koreanRomanized: String
    let phonetic: String
    let description: String
    let effectiveTechniques: [String]
    let cautionLevel: String
    let controlRequired: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, korean, description
        case koreanRomanized = "korean_romanized"
        case phonetic
        case effectiveTechniques = "effective_techniques"
        case cautionLevel = "caution_level"
        case controlRequired = "control_required"
    }
}

// MARK: - Techniques Data Service

/**
 * Service for loading and managing technique reference data
 */
@MainActor
class TechniquesDataService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isLoading = false
    @Published private(set) var loadingError: Error?
    
    // MARK: - Private Properties
    
    private var techniquesCache: [String: [Technique]] = [:]
    private var categoriesCache: [TechniqueCategory] = []
    private var targetAreasCache: [TargetArea] = []
    private var allTechniques: [Technique] = []
    
    /**
     * Dynamically discovers technique files from Techniques subdirectory
     */
    private func discoverTechniqueFiles() -> [String] {
        var foundFiles: [String] = []
        
        // First try: Scan Techniques subdirectory for any JSON files
        if let techniquesPath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "Techniques") {
            DebugLogger.data("📁 Scanning Techniques subdirectory: \(techniquesPath)")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: techniquesPath)
                let jsonFiles = contents.filter { filename in
                    guard filename.hasSuffix(".json") else { return false }
                    // Skip special files that have different structure
                    return !["target_areas.json", "techniques_index.json"].contains(filename)
                }
                
                for jsonFile in jsonFiles {
                    foundFiles.append(jsonFile)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan Techniques subdirectory: \(error)")
            }
        }
        
        // Fallback: Try bundle root for technique files
        if foundFiles.isEmpty, let bundlePath = Bundle.main.resourcePath {
            DebugLogger.data("📁 Techniques subdirectory not found, scanning bundle root for technique files...")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let techniqueFiles = contents.filter { filename in
                    guard filename.hasSuffix(".json") else { return false }
                    // Look for common technique file patterns, excluding special files
                    return ["kicks.json", "strikes.json", "blocks.json", "stances.json", 
                           "hand_techniques.json", "footwork.json", "sparring.json", 
                           "combinations.json", "fundamentals.json", "belt_requirements.json"].contains(filename)
                }
                
                foundFiles = techniqueFiles
            } catch {
                DebugLogger.data("⚠️ Failed to scan bundle root: \(error)")
            }
        }
        
        DebugLogger.data("📁 Found \(foundFiles.count) technique JSON files: \(foundFiles.sorted())")
        return foundFiles.sorted()
    }
    
    // MARK: - Public Methods
    
    /**
     * Load all technique data from JSON files
     */
    func loadAllTechniques() async {
        guard !isLoading else { return }
        
        isLoading = true
        loadingError = nil
        
        DebugLogger.data("🗃️ TechniquesDataService: Loading all technique data...")
        
        // Dynamically discover and load technique files
        let techniqueFiles = discoverTechniqueFiles()
        DebugLogger.data("🔍 TechniquesDataService: Discovered \(techniqueFiles.count) technique files: \(techniqueFiles)")
        
        for file in techniqueFiles {
            await loadTechniqueFile(file)
        }
        
        // Load categories index
        await loadCategoriesIndex()
        
        // Load target areas
        await loadTargetAreas()
        
        // Build master list of all techniques
        allTechniques = techniquesCache.values.flatMap { $0 }
        
        DebugLogger.data("✅ TechniquesDataService: Loaded \(allTechniques.count) techniques across \(techniquesCache.count) categories")
        
        isLoading = false
    }
    
    /**
     * Get all technique categories for navigation
     */
    func getCategories() -> [TechniqueCategory] {
        return categoriesCache
    }
    
    /**
     * Get techniques by category
     */
    func getTechniques(for category: String) -> [Technique] {
        return techniquesCache[category] ?? []
    }
    
    /**
     * Get all techniques
     */
    func getAllTechniques() -> [Technique] {
        return allTechniques
    }
    
    /**
     * Search techniques by text query
     */
    func searchTechniques(query: String) -> [Technique] {
        guard !query.isEmpty else { return allTechniques }
        
        let lowercaseQuery = query.lowercased()
        
        return allTechniques.filter { technique in
            technique.names.english.lowercased().contains(lowercaseQuery) ||
            technique.names.korean.contains(lowercaseQuery) ||
            technique.names.koreanRomanized.lowercased().contains(lowercaseQuery) ||
            technique.description.lowercased().contains(lowercaseQuery) ||
            technique.tags.contains { $0.lowercased().contains(lowercaseQuery) }
        }
    }
    
    /**
     * Filter techniques by various criteria
     */
    func filterTechniques(
        category: String? = nil,
        beltLevel: String? = nil,
        difficulty: String? = nil,
        tags: [String] = []
    ) -> [Technique] {
        var filtered = allTechniques
        
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        if let beltLevel = beltLevel {
            filtered = filtered.filter { $0.beltLevels.contains(beltLevel) }
        }
        
        if let difficulty = difficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        if !tags.isEmpty {
            filtered = filtered.filter { technique in
                tags.allSatisfy { tag in
                    technique.tags.contains(tag)
                }
            }
        }
        
        return filtered
    }
    
    /**
     * Get target areas reference data
     */
    func getTargetAreas() -> [TargetArea] {
        return targetAreasCache
    }
    
    /**
     * Get available filter options
     */
    func getFilterOptions() -> TechniqueFilterOptions {
        let categories = Set(allTechniques.map { $0.category })
        let beltLevels = Set(allTechniques.flatMap { $0.beltLevels })
        let difficulties = Set(allTechniques.map { $0.difficulty })
        let tags = Set(allTechniques.flatMap { $0.tags })
        
        return TechniqueFilterOptions(
            categories: Array(categories).sorted(),
            beltLevels: Array(beltLevels).sorted { beltLevelSortOrder($0) > beltLevelSortOrder($1) },
            difficulties: Array(difficulties).sorted(),
            tags: Array(tags).sorted()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadTechniqueFile(_ filename: String) async {
        let category = String(filename.dropLast(5)) // Remove .json
        
        do {
            var url: URL?
            
            // First try: Techniques subdirectory (consistent with architectural pattern)
            url = Bundle.main.url(forResource: category, withExtension: "json", subdirectory: "Techniques")
            
            if url == nil {
                // Fallback: try main bundle root for deployment flexibility
                url = Bundle.main.url(forResource: category, withExtension: "json")
            }
            
            if url == nil {
                // Fallback: try Core/Data/Content/Techniques path
                url = Bundle.main.url(forResource: category, withExtension: "json", subdirectory: "Core/Data/Content/Techniques")
            }
            
            guard let url = url else {
                DebugLogger.data("❌ Could not find \(filename) at expected path")
                return
            }
            
            let data = try Data(contentsOf: url)
            
            // Skip target_areas and techniques_index in this loop
            if category == "target_areas" || category == "techniques_index" {
                return
            }
            
            if category == "belt_requirements" {
                // Belt requirements has different structure
                let beltData = try JSONDecoder().decode(BeltRequirementsData.self, from: data)
                let techniques = beltData.beltLevels.map { beltLevel in
                    Technique(
                        id: beltLevel.id,
                        names: TechniqueNames(
                            korean: beltLevel.korean,
                            koreanRomanized: beltLevel.koreanRomanized,
                            english: beltLevel.name,
                            phonetic: beltLevel.phonetic
                        ),
                        description: beltLevel.colorSignificance,
                        category: "belt_requirements",
                        beltLevels: [beltLevel.id],
                        difficulty: "basic",
                        tags: ["belt", "requirements", "grading"],
                        images: [],
                        commonMistakes: [],
                        execution: nil,
                        strikingTool: nil,
                        blockingTool: nil,
                        targetAreas: beltLevel.requiredTechniques,
                        applicableStances: nil,
                        variations: nil,
                        skillsDeveloped: beltLevel.theoryRequirements,
                        characteristics: nil,
                        transitionsTo: nil,
                        sparringType: nil,
                        participants: nil,
                        attackPattern: nil,
                        defensePattern: nil,
                        sequence: nil,
                        combinationType: nil,
                        totalMovements: nil,
                        setupTechniques: nil,
                        followUpOptions: nil,
                        colorSignificance: beltLevel.colorSignificance,
                        minimumTrainingTime: beltLevel.minimumTrainingTime,
                        requiredTechniques: beltLevel.requiredTechniques,
                        requiredFitness: beltLevel.requiredFitness,
                        theoryRequirements: beltLevel.theoryRequirements,
                        pattern: beltLevel.pattern,
                        sparring: beltLevel.sparring,
                        breaking: beltLevel.breaking,
                        exerciseType: nil,
                        movements: nil,
                        footUsed: nil,
                        primaryPurpose: nil,
                        timing: nil
                    )
                }
                techniquesCache[category] = techniques
            } else {
                // Standard technique file structure
                let techniqueData = try JSONDecoder().decode(TechniqueFileData.self, from: data)
                var techniques = techniqueData.techniques
                
                // Set category for each technique
                for i in 0..<techniques.count {
                    techniques[i].category = category
                }
                
                techniquesCache[category] = techniques
            }
            
            DebugLogger.data("✅ Loaded \(techniquesCache[category]?.count ?? 0) techniques from \(filename)")
            
        } catch {
            DebugLogger.data("❌ Failed to load \(filename): \(error)")
        }
    }
    
    private func loadCategoriesIndex() async {
        do {
            var url: URL?
            
            // First try: Techniques subdirectory (consistent with architectural pattern)
            url = Bundle.main.url(forResource: "techniques_index", withExtension: "json", subdirectory: "Techniques")
            
            if url == nil {
                // Fallback: try main bundle root for deployment flexibility
                url = Bundle.main.url(forResource: "techniques_index", withExtension: "json")
            }
            
            if url == nil {
                // Fallback: try Core/Data/Content/Techniques path
                url = Bundle.main.url(forResource: "techniques_index", withExtension: "json", subdirectory: "Core/Data/Content/Techniques")
            }
            
            guard let url = url else {
                DebugLogger.data("❌ Could not find techniques_index.json")
                return
            }
            
            let data = try Data(contentsOf: url)
            let indexData = try JSONDecoder().decode(TechniquesIndex.self, from: data)
            categoriesCache = indexData.categories
            
        } catch {
            DebugLogger.data("❌ Failed to load techniques index: \(error)")
        }
    }
    
    private func loadTargetAreas() async {
        do {
            var url: URL?
            
            // First try: Techniques subdirectory (consistent with architectural pattern)
            url = Bundle.main.url(forResource: "target_areas", withExtension: "json", subdirectory: "Techniques")
            
            if url == nil {
                // Fallback: try main bundle root for deployment flexibility
                url = Bundle.main.url(forResource: "target_areas", withExtension: "json")
            }
            
            if url == nil {
                // Fallback: try Core/Data/Content/Techniques path
                url = Bundle.main.url(forResource: "target_areas", withExtension: "json", subdirectory: "Core/Data/Content/Techniques")
            }
            
            guard let url = url else {
                DebugLogger.data("❌ Could not find target_areas.json")
                return
            }
            
            let data = try Data(contentsOf: url)
            let targetData = try JSONDecoder().decode(TargetAreasData.self, from: data)
            targetAreasCache = targetData.targetAreas
            
        } catch {
            DebugLogger.data("❌ Failed to load target areas: \(error)")
        }
    }
    
    private func beltLevelSortOrder(_ beltLevel: String) -> Int {
        let beltOrder = [
            "10th_keup": 10, "9th_keup": 9, "8th_keup": 8, "7th_keup": 7, "6th_keup": 6,
            "5th_keup": 5, "4th_keup": 4, "3rd_keup": 3, "2nd_keup": 2, "1st_keup": 1,
            "1st_dan": 0, "2nd_dan": -1
        ]
        return beltOrder[beltLevel] ?? 999
    }
}

// MARK: - Supporting Data Models

struct TechniqueFileData: Codable {
    let version: String
    let category: String
    let description: String
    let techniques: [Technique]
}

struct TechniquesIndex: Codable {
    let version: String
    let name: String
    let description: String
    let categories: [TechniqueCategory]
}

struct BeltRequirementsData: Codable {
    let version: String
    let category: String
    let description: String
    let beltLevels: [BeltRequirement]
    
    private enum CodingKeys: String, CodingKey {
        case version, category, description
        case beltLevels = "belt_levels"
    }
}

struct BeltRequirement: Codable {
    let id: String
    let name: String
    let korean: String
    let koreanRomanized: String
    let phonetic: String
    let colorSignificance: String
    let minimumTrainingTime: String
    let requiredTechniques: [String]
    let requiredFitness: [String]
    let theoryRequirements: [String]
    let pattern: String
    let sparring: String
    let breaking: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, korean, pattern, sparring, breaking
        case koreanRomanized = "korean_romanized"
        case phonetic
        case colorSignificance = "color_significance"
        case minimumTrainingTime = "minimum_training_time"
        case requiredTechniques = "required_techniques"
        case requiredFitness = "required_fitness"
        case theoryRequirements = "theory_requirements"
    }
}

struct TargetAreasData: Codable {
    let version: String
    let category: String
    let description: String
    let targetAreas: [TargetArea]
    
    private enum CodingKeys: String, CodingKey {
        case version, category, description
        case targetAreas = "target_areas"
    }
}

struct TechniqueFilterOptions {
    let categories: [String]
    let beltLevels: [String]
    let difficulties: [String]
    let tags: [String]
}

// MARK: - Extension for Technique Decoding

extension Technique {
    private enum CodingKeys: String, CodingKey {
        case id, names, description, category, difficulty, tags, images, execution, variations
        case beltLevels = "belt_levels"
        case commonMistakes = "common_mistakes"
        case strikingTool = "striking_tool"
        case blockingTool = "blocking_tool"
        case targetAreas = "target_areas"
        case applicableStances = "applicable_stances"
        case skillsDeveloped = "skills_developed"
        case characteristics
        case transitionsTo = "transitions_to"
        case sparringType = "sparring_type"
        case participants
        case attackPattern = "attack_pattern"
        case defensePattern = "defense_pattern"
        case sequence
        case combinationType = "combination_type"
        case totalMovements = "total_movements"
        case setupTechniques = "setup_techniques"
        case followUpOptions = "follow_up_options"
        case colorSignificance = "color_significance"
        case minimumTrainingTime = "minimum_training_time"
        case requiredTechniques = "required_techniques"
        case requiredFitness = "required_fitness"
        case theoryRequirements = "theory_requirements"
        case pattern, sparring, breaking
        case exerciseType = "exercise_type"
        case movements
        case footUsed = "foot_used"
        case primaryPurpose = "primary_purpose"
        case timing
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        names = try container.decode(TechniqueNames.self, forKey: .names)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "unknown"
        beltLevels = try container.decode([String].self, forKey: .beltLevels)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        tags = try container.decode([String].self, forKey: .tags)
        images = try container.decode([String].self, forKey: .images)
        commonMistakes = try container.decode([String].self, forKey: .commonMistakes)
        
        // Optional properties
        execution = try container.decodeIfPresent(TechniqueExecution.self, forKey: .execution)
        strikingTool = try container.decodeIfPresent(TechniqueNames.self, forKey: .strikingTool)
        blockingTool = try container.decodeIfPresent(TechniqueNames.self, forKey: .blockingTool)
        targetAreas = try container.decodeIfPresent([String].self, forKey: .targetAreas)
        applicableStances = try container.decodeIfPresent([String].self, forKey: .applicableStances)
        variations = try container.decodeIfPresent([String].self, forKey: .variations)
        skillsDeveloped = try container.decodeIfPresent([String].self, forKey: .skillsDeveloped)
        characteristics = try container.decodeIfPresent(TechniqueCharacteristics.self, forKey: .characteristics)
        transitionsTo = try container.decodeIfPresent([String].self, forKey: .transitionsTo)
        
        // Sparring properties
        sparringType = try container.decodeIfPresent(String.self, forKey: .sparringType)
        participants = try container.decodeIfPresent(Int.self, forKey: .participants)
        attackPattern = try container.decodeIfPresent(String.self, forKey: .attackPattern)
        defensePattern = try container.decodeIfPresent(String.self, forKey: .defensePattern)
        
        // Combination properties
        sequence = try container.decodeIfPresent([TechniqueStep].self, forKey: .sequence)
        combinationType = try container.decodeIfPresent(String.self, forKey: .combinationType)
        totalMovements = try container.decodeIfPresent(Int.self, forKey: .totalMovements)
        setupTechniques = try container.decodeIfPresent([String].self, forKey: .setupTechniques)
        followUpOptions = try container.decodeIfPresent([String].self, forKey: .followUpOptions)
        
        // Belt requirement properties
        colorSignificance = try container.decodeIfPresent(String.self, forKey: .colorSignificance)
        minimumTrainingTime = try container.decodeIfPresent(String.self, forKey: .minimumTrainingTime)
        requiredTechniques = try container.decodeIfPresent([String].self, forKey: .requiredTechniques)
        requiredFitness = try container.decodeIfPresent([String].self, forKey: .requiredFitness)
        theoryRequirements = try container.decodeIfPresent([String].self, forKey: .theoryRequirements)
        pattern = try container.decodeIfPresent(String.self, forKey: .pattern)
        sparring = try container.decodeIfPresent(String.self, forKey: .sparring)
        breaking = try container.decodeIfPresent(String.self, forKey: .breaking)
        
        // Fundamental properties
        exerciseType = try container.decodeIfPresent(String.self, forKey: .exerciseType)
        movements = try container.decodeIfPresent(Int.self, forKey: .movements)
        
        // Footwork properties
        footUsed = try container.decodeIfPresent(String.self, forKey: .footUsed)
        primaryPurpose = try container.decodeIfPresent(String.self, forKey: .primaryPurpose)
        timing = try container.decodeIfPresent(String.self, forKey: .timing)
    }
}