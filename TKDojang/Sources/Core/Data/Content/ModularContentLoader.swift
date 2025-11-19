import Foundation
import SwiftData
import SwiftUI

/**
 * ModularContentLoader.swift
 * 
 * PURPOSE: Loads TAGB content from modular JSON files organized by belt and category
 * 
 * BENEFITS:
 * - Each file can be edited independently
 * - Easy collaboration (different developers work on different files)
 * - Automatic discovery of available content
 * - Belt-specific validation
 * - Visual theming based on belt colors
 */

@MainActor
class ModularContentLoader {
    private let dataService: TerminologyDataService
    
    init(dataService: TerminologyDataService) {
        self.dataService = dataService
    }
    
    /**
     * Loads complete TAGB system from modular JSON files
     */
    func loadCompleteSystem() {
        
        do {
            // Load belt system configuration
            let beltSystem = try loadBeltSystem()
            
            // Create belt levels
            let beltLevels = try createBeltLevels(from: beltSystem)
            
            // Create terminology categories
            let categories = dataService.createTerminologyCategories()
            
            // Discover and load all content files
            try loadAllContent(beltLevels: beltLevels, categories: categories)
            
            DebugLogger.data("✅ Successfully loaded complete TAGB system with \(beltLevels.count) belts and \(categories.count) categories")
            
        } catch {
            DebugLogger.data("❌ Failed to load TAGB system: \(error)")
        }
    }
    
    /**
     * Loads belt system configuration with colors and metadata
     */
    private func loadBeltSystem() throws -> BeltSystemConfig {
        guard let url = Bundle.main.url(forResource: "belt_system", withExtension: "json") else {
            DebugLogger.data("❌ belt_system.json not found in bundle")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            DebugLogger.data("❌ Failed to read belt_system.json data")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        let config = try JSONDecoder().decode(BeltSystemConfig.self, from: data)
        return config
    }
    
    /**
     * Creates belt levels with full metadata from configuration
     *
     * WHY: Only creates belts if they don't already exist to prevent duplicates
     * during database reset where ensureBeltSystemIsSynchronized() runs first
     */
    private func createBeltLevels(from config: BeltSystemConfig) throws -> [String: BeltLevel] {
        // First, check if belt levels already exist
        let existingBelts = try dataService.modelContextForLoading.fetch(FetchDescriptor<BeltLevel>())

        if !existingBelts.isEmpty {
            DebugLogger.data("✅ Belt levels already exist (\(existingBelts.count)), reusing existing belts")
            // Return existing belts mapped by shortName -> config ID
            var beltDict: [String: BeltLevel] = [:]
            for beltConfig in config.beltSystem.belts {
                if let existingBelt = existingBelts.first(where: { $0.shortName == beltConfig.shortName }) {
                    beltDict[beltConfig.id] = existingBelt
                }
            }
            return beltDict
        }

        // No existing belts, create them
        DebugLogger.data("📋 Creating \(config.beltSystem.belts.count) new belt levels from configuration")
        var beltDict: [String: BeltLevel] = [:]

        for beltConfig in config.beltSystem.belts {
            let belt = BeltLevel(
                name: beltConfig.name,
                shortName: beltConfig.shortName,
                colorName: beltConfig.colorName,
                sortOrder: beltConfig.sortOrder,
                isKyup: beltConfig.isKeup
            )

            // Store visual styling information
            belt.requirements = beltConfig.description
            belt.primaryColor = beltConfig.primaryColor
            belt.secondaryColor = beltConfig.secondaryColor
            belt.textColor = beltConfig.textColor
            belt.borderColor = beltConfig.borderColor

            // Belt created successfully

            dataService.modelContextForLoading.insert(belt)
            beltDict[beltConfig.id] = belt
        }

        try dataService.modelContextForLoading.save()
        DebugLogger.data("✅ Created \(beltDict.count) new belt levels")
        return beltDict
    }
    
    /**
     * Discovers and loads all content files from Belts directory
     */
    private func loadAllContent(beltLevels: [String: BeltLevel], categories: [TerminologyCategory]) throws {
        let categoryDict = Dictionary(uniqueKeysWithValues: categories.map { ($0.name, $0) })
        
        // Load content for each belt level using the config ID as the directory name
        for (configId, beltLevel) in beltLevels {
            try loadBeltContent(beltId: configId, belt: beltLevel, categories: categoryDict)
        }
    }
    
    /**
     * Loads all content files for a specific belt level
     */
    private func loadBeltContent(beltId: String, belt: BeltLevel, categories: [String: TerminologyCategory]) throws {
        // Try to find belt-specific content files in Resources/Content/Belts directory
        let categoryNames = ["basics", "numbers", "techniques", "stances", "blocks", "strikes", "kicks", "patterns", "titles", "philosophy"]
        
        for categoryName in categoryNames {
            // Try unique filename in multiple locations
            let uniqueFileName = "\(beltId)_\(categoryName)"
            var resourceURL: URL?
            
            // First try: Terminology subdirectory
            resourceURL = Bundle.main.url(forResource: uniqueFileName, withExtension: "json", subdirectory: "Terminology")
            
            // Fallback: try main bundle root
            if resourceURL == nil {
                resourceURL = Bundle.main.url(forResource: uniqueFileName, withExtension: "json")
            }
            
            // Fallback: try Core/Data/Content/Terminology path
            if resourceURL == nil {
                resourceURL = Bundle.main.url(forResource: uniqueFileName, withExtension: "json", subdirectory: "Core/Data/Content/Terminology")
            }
            
            if let resourceURL = resourceURL {
                if let category = categories[categoryName] {
                    do {
                        try loadCategoryContent(from: resourceURL, belt: belt, category: category)
                    } catch {
                        DebugLogger.data("❌ Failed to load content from \(uniqueFileName).json: \(error)")
                    }
                } else {
                    DebugLogger.data("❌ Category '\(categoryName)' not found in categories")
                }
            }
        }
    }
    
    /**
     * Alternative method using file discovery (if needed)
     */
    private func loadBeltContentDiscovery(beltId: String, belt: BeltLevel, categories: [String: TerminologyCategory]) throws {
        let beltPath = "Belts/\(beltId)"
        
        // Discover all JSON files in this belt's directory
        guard let beltURL = Bundle.main.url(forResource: beltPath, withExtension: nil) else {
            return
        }
        
        let contentFiles = try FileManager.default.contentsOfDirectory(at: beltURL, 
                                                                       includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        
        for fileURL in contentFiles {
            let categoryName = fileURL.deletingPathExtension().lastPathComponent
            
            guard let category = categories[categoryName] else {
                continue
            }
            
            try loadCategoryContent(from: fileURL, belt: belt, category: category)
        }
    }
    
    /**
     * Loads content from a specific category file
     */
    private func loadCategoryContent(from url: URL, belt: BeltLevel, category: TerminologyCategory) throws {
        let data = try Data(contentsOf: url)

        do {
            let _ = try JSONDecoder().decode(CategoryContent.self, from: data)
        } catch {
            DebugLogger.data("❌ Failed to decode \(url.lastPathComponent): \(error)")
            throw error
        }

        let content = try JSONDecoder().decode(CategoryContent.self, from: data)

        // Create expected belt level ID from belt short name
        let expectedBeltId = belt.shortName.replacingOccurrences(of: " ", with: "_").lowercased()

        // Validate that file matches expected belt level
        guard content.beltLevel == expectedBeltId else {
            DebugLogger.data("⚠️ Belt level mismatch in \(url.lastPathComponent): expected \(expectedBeltId), got \(content.beltLevel)")
            return
        }

        // Load terminology entries (standardized format)
        for term in content.terminology {
            _ = dataService.addTerminologyEntry(
                englishTerm: term.englishTerm,
                koreanHangul: term.koreanHangul,
                romanisedPronunciation: term.romanisedPronunciation,
                beltLevel: belt,
                category: category,
                difficulty: term.difficulty,
                phoneticPronunciation: term.phoneticPronunciation,
                definition: term.definition,
                notes: nil
            )
        }

        // Successfully loaded terms
    }
}

// MARK: - Data Structures

/**
 * Belt system configuration from JSON
 */
struct BeltSystemConfig: Codable {
    let beltSystem: BeltSystemData
    
    private enum CodingKeys: String, CodingKey {
        case beltSystem = "belt_system"
    }
}

struct BeltSystemData: Codable {
    let name: String
    let belts: [BeltConfig]
}

struct BeltConfig: Codable {
    let id: String
    let name: String
    let shortName: String
    let displayName: String
    let colorName: String
    let sortOrder: Int
    let isKeup: Bool
    let primaryColor: String
    let secondaryColor: String
    let textColor: String
    let borderColor: String
    let gradient: [String]
    let requiredCategories: [String]
    let optionalCategories: [String]
    let description: String
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description
        case shortName = "short_name"
        case displayName = "display_name"
        case colorName = "color_name"
        case sortOrder = "sort_order"
        case isKeup = "is_keup"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
        case textColor = "text_color"
        case borderColor = "border_color"
        case gradient
        case requiredCategories = "required_categories"
        case optionalCategories = "optional_categories"
    }
}

/**
 * Individual category content file (standardized format)
 */
struct CategoryContent: Codable {
    let beltLevel: String
    let category: String
    let terminology: [TerminologyEntryJSON]
    let metadata: ContentMetadata?
    let description: String?

    private enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case category, terminology, metadata, description
    }
}

struct ContentMetadata: Codable {
    let createdAt: String
    let totalCount: Int
    let source: String
    
    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case totalCount = "total_count"
        case source
    }
}

/**
 * Individual terminology item (standardized format)
 */
struct TerminologyEntryJSON: Codable {
    let englishTerm: String
    let koreanHangul: String
    let romanisedPronunciation: String
    let phoneticPronunciation: String?
    let definition: String?
    let category: String
    let difficulty: Int
    let beltLevel: String
    let createdAt: String

    private enum CodingKeys: String, CodingKey {
        case englishTerm = "english"
        case koreanHangul = "hangul"
        case romanisedPronunciation = "romanised"
        case phoneticPronunciation = "phonetic"
        case definition, category, difficulty
        case beltLevel = "belt_level"
        case createdAt = "created_at"
    }
}

/**
 * Content loading errors
 */
enum ContentLoadError: Error {
    case missingFile(String)
    case invalidStructure(String)
    case beltMismatch(String, String)
}