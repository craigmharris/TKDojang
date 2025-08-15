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
        print("🌟 Starting ModularContentLoader.loadCompleteSystem()")
        
        // Debug: Check what JSON files are available in bundle
        if let bundlePath = Bundle.main.resourcePath {
            print("📦 Bundle resource path: \(bundlePath)")
        }
        
        // List all JSON files in bundle
        let jsonFiles = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        print("📄 JSON files in bundle: \(jsonFiles)")
        
        do {
            // 1. Load belt system configuration
            let beltSystem = try loadBeltSystem()
            let beltLevels = try createBeltLevels(from: beltSystem)
            let categories = dataService.createTerminologyCategories()
            
            // 2. Discover and load all content files
            try loadAllContent(beltLevels: beltLevels, categories: categories)
            
            print("✅ Successfully loaded complete TAGB system")
            
        } catch {
            print("❌ Failed to load TAGB system: \(error)")
        }
    }
    
    /**
     * Loads belt system configuration with colors and metadata
     */
    private func loadBeltSystem() throws -> BeltSystemConfig {
        print("🔍 Looking for belt_system.json in bundle...")
        guard let url = Bundle.main.url(forResource: "belt_system", withExtension: "json") else {
            print("❌ belt_system.json not found in bundle")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        print("✅ Found belt_system.json at: \(url)")
        guard let data = try? Data(contentsOf: url) else {
            print("❌ Failed to read belt_system.json data")
            throw ContentLoadError.missingFile("belt_system.json")
        }
        
        let config = try JSONDecoder().decode(BeltSystemConfig.self, from: data)
        print("✅ Successfully decoded belt system with \(config.beltSystem.belts.count) belts")
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
            
            print("🎯 Created belt: '\(beltConfig.id)' -> '\(belt.shortName)' with colors: \(belt.primaryColor ?? "nil")")
            
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
        // Try to find belt-specific content files with unique naming
        let categoryNames = ["basics", "numbers", "techniques", "stances", "blocks", "strikes", "kicks", "patterns", "titles", "philosophy"]
        
        for categoryName in categoryNames {
            // Try flat file structure that actually exists in bundle
            let uniqueFileName = "\(beltId)_\(categoryName)"
            let simpleFileName = categoryName
            
            print("🔍 Looking for content files: '\(uniqueFileName).json' or '\(simpleFileName).json'")
            
            var fileURL: URL?
            
            // Try unique filename first (e.g., "10th_keup_basics.json")
            if let url = Bundle.main.url(forResource: uniqueFileName, withExtension: "json") {
                print("✅ Found unique filename: \(uniqueFileName).json")
                fileURL = url
            } else if let url = Bundle.main.url(forResource: simpleFileName, withExtension: "json") {
                print("✅ Found simple filename: \(simpleFileName).json")
                fileURL = url
            } else {
                print("❌ Neither file found for \(beltId)/\(categoryName)")
            }
            
            guard let url = fileURL,
                  let category = categories[categoryName] else {
                if fileURL == nil {
                    print("⚠️ No file found for \(categoryName)")
                } else {
                    print("⚠️ Category '\(categoryName)' not found in categories")
                }
                continue // Skip if file doesn't exist or category not found
            }
            
            try loadCategoryContent(from: url, belt: belt, category: category)
        }
    }
    
    /**
     * Alternative method using file discovery (if needed)
     */
    private func loadBeltContentDiscovery(beltId: String, belt: BeltLevel, categories: [String: TerminologyCategory]) throws {
        let beltPath = "Belts/\(beltId)"
        
        // Discover all JSON files in this belt's directory
        guard let beltURL = Bundle.main.url(forResource: beltPath, withExtension: nil) else {
            print("⚠️ No content directory found for \(beltId)")
            return
        }
        
        let contentFiles = try FileManager.default.contentsOfDirectory(at: beltURL, 
                                                                       includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        
        for fileURL in contentFiles {
            let categoryName = fileURL.deletingPathExtension().lastPathComponent
            
            guard let category = categories[categoryName] else {
                print("⚠️ Unknown category: \(categoryName)")
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
        let content = try JSONDecoder().decode(CategoryContent.self, from: data)
        
        // Create expected belt level ID from belt short name
        let expectedBeltId = belt.shortName.replacingOccurrences(of: " ", with: "_").lowercased()
        
        print("🔍 Loading \(url.lastPathComponent): expected belt ID '\(expectedBeltId)', file has '\(content.beltLevel)'")
        
        // Validate that file matches expected belt level
        guard content.beltLevel == expectedBeltId else {
            print("⚠️ Belt level mismatch in \(url.lastPathComponent): expected \(expectedBeltId), got \(content.beltLevel)")
            return
        }
        
        // Add all terms from this file
        for term in content.terms {
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
        
        print("✅ Loaded \(content.terms.count) terms from \(url.lastPathComponent)")
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
 * Individual category content file
 */
struct CategoryContent: Codable {
    let beltLevel: String
    let category: String
    let description: String
    let terms: [TerminologyItem]
    
    private enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case category, description, terms
    }
}

/**
 * Individual terminology item
 */
struct TerminologyItem: Codable {
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