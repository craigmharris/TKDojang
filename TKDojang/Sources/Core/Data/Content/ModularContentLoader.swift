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
            
            print("✅ Successfully loaded complete TAGB system with \(beltLevels.count) belts and \(categories.count) categories")
            
        } catch {
            print("❌ Failed to load TAGB system: \(error)")
        }
    }
    
    /**
     * Loads belt system configuration with colors and metadata
     */
    private func loadBeltSystem() throws -> BeltSystemConfig {
        guard let url = Bundle.main.url(forResource: "belt_system", withExtension: "json") else {
            print("❌ belt_system.json not found in bundle")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Failed to read belt_system.json data")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        let config = try JSONDecoder().decode(BeltSystemConfig.self, from: data)
        return config
    }
    
    /**
     * Creates belt levels with full metadata from configuration
     */
    private func createBeltLevels(from config: BeltSystemConfig) throws -> [String: BeltLevel] {
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
                        print("❌ Failed to load content from \(uniqueFileName).json: \(error)")
                    }
                } else {
                    print("❌ Category '\(categoryName)' not found in categories")
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
            print("❌ Failed to decode \(url.lastPathComponent): \(error)")
            throw error
        }
        
        let content = try JSONDecoder().decode(CategoryContent.self, from: data)
        
        // Create expected belt level ID from belt short name
        let expectedBeltId = belt.shortName.replacingOccurrences(of: " ", with: "_").lowercased()
        
        // Validate that file matches expected belt level
        guard content.beltLevel == expectedBeltId else {
            print("⚠️ Belt level mismatch in \(url.lastPathComponent): expected \(expectedBeltId), got \(content.beltLevel)")
            return
        }
        
        // Handle both old and new format
        if let newTerms = content.terminology {
            // New format (from CSV tool)
            for term in newTerms {
                _ = dataService.addTerminologyEntry(
                    englishTerm: term.englishTerm,
                    koreanHangul: term.koreanHangul,
                    romanizedPronunciation: term.romanizedPronunciation,
                    beltLevel: belt,
                    category: category,
                    difficulty: term.difficulty,
                    phoneticPronunciation: term.phoneticPronunciation,
                    definition: term.definition,
                    notes: nil
                )
            }
            
        } else if let oldTerms = content.terms {
            // Old format (existing files)
            for term in oldTerms {
                _ = dataService.addTerminologyEntry(
                    englishTerm: term.english,
                    koreanHangul: term.korean,
                    romanizedPronunciation: term.pronunciation,
                    beltLevel: belt,
                    category: category,
                    difficulty: term.difficulty ?? 1,
                    phoneticPronunciation: term.phonetic,
                    definition: term.definition,
                    notes: term.notes
                )
            }
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
 * Individual category content file (supports both old and new formats)
 */
struct CategoryContent: Codable {
    let beltLevel: String
    let category: String
    let terminology: [TerminologyEntryJSON]?
    let terms: [TerminologyItemOld]?
    let metadata: ContentMetadata?
    let description: String?
    
    private enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case category, terminology, terms, metadata, description
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
 * Individual terminology item (new format from CSV tool)
 */
struct TerminologyEntryJSON: Codable {
    let englishTerm: String
    let koreanHangul: String
    let romanizedPronunciation: String
    let phoneticPronunciation: String?
    let definition: String?
    let category: String
    let difficulty: Int
    let beltLevel: String
    let createdAt: String
    
    private enum CodingKeys: String, CodingKey {
        case englishTerm = "english_term"
        case koreanHangul = "korean_hangul"
        case romanizedPronunciation = "romanized_pronunciation"
        case phoneticPronunciation = "phonetic_pronunciation"
        case definition, category, difficulty
        case beltLevel = "belt_level"
        case createdAt = "created_at"
    }
}

/**
 * Individual terminology item (old format)
 */
struct TerminologyItemOld: Codable {
    let english: String
    let korean: String
    let pronunciation: String
    let phonetic: String?
    let definition: String?
    let notes: String?
    let difficulty: Int?
}

/**
 * Content loading errors
 */
enum ContentLoadError: Error {
    case missingFile(String)
    case invalidStructure(String)
    case beltMismatch(String, String)
}