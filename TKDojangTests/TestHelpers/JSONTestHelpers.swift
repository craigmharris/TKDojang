import Foundation
import SwiftData
@testable import TKDojang

/**
 * JSONTestHelpers.swift
 * 
 * PURPOSE: JSON-based test utilities that mirror production data loading
 * 
 * BENEFITS:
 * - Tests use same JSON data as production app
 * - Eliminates hardcoded test data inconsistencies
 * - Automatic updates when JSON content changes
 * - Ensures test coverage reflects actual app content
 */

@MainActor
class JSONTestHelpers {
    
    // MARK: - JSON Belt System Loading
    
    /**
     * Loads belt levels from actual belt_system.json used by app
     */
    static func loadBeltLevelsFromJSON() throws -> [BeltLevel] {
        guard let url = Bundle(for: JSONTestHelpers.self).url(forResource: "belt_system", withExtension: "json") else {
            // Fallback to main bundle if test bundle doesn't have the file
            guard let url = Bundle.main.url(forResource: "belt_system", withExtension: "json") else {
                throw TestError.missingJSONFile("belt_system.json")
            }
            return try parseBeltSystem(from: url)
        }
        
        return try parseBeltSystem(from: url)
    }
    
    private static func parseBeltSystem(from url: URL) throws -> [BeltLevel] {
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(BeltSystemConfig.self, from: data)
        
        return config.beltSystem.belts.map { beltConfig in
            let belt = BeltLevel(
                name: beltConfig.name,
                shortName: beltConfig.shortName,
                colorName: beltConfig.colorName,
                sortOrder: beltConfig.sortOrder,
                isKyup: beltConfig.isKeup
            )
            
            // Set visual properties from JSON
            belt.requirements = beltConfig.description
            belt.primaryColor = beltConfig.primaryColor
            belt.secondaryColor = beltConfig.secondaryColor
            belt.textColor = beltConfig.textColor
            belt.borderColor = beltConfig.borderColor
            
            return belt
        }
    }
    
    /**
     * Gets starting belt (white belt) from JSON data
     */
    static func getStartingBeltFromJSON() throws -> BeltLevel {
        let allBelts = try loadBeltLevelsFromJSON()
        guard let startingBelt = BeltLevel.findStartingBelt(from: allBelts) else {
            throw TestError.noStartingBelt
        }
        return startingBelt
    }
    
    /**
     * Gets specific belt level by ID from JSON data
     */
    static func getBeltFromJSON(id: String) throws -> BeltLevel {
        let allBelts = try loadBeltLevelsFromJSON()
        guard let belt = BeltLevel.findBelt(byId: id, in: allBelts) else {
            throw TestError.beltNotFound(id)
        }
        return belt
    }
    
    // MARK: - Test Categories from Production System
    
    /**
     * Creates terminology categories matching production system
     */
    static func createTestCategories() -> [TerminologyCategory] {
        return [
            TerminologyCategory(name: "basics", displayName: "Basics & Commands", sortOrder: 1),
            TerminologyCategory(name: "numbers", displayName: "Numbers & Counting", sortOrder: 2),
            TerminologyCategory(name: "techniques", displayName: "Techniques & Movements", sortOrder: 3),
            TerminologyCategory(name: "stances", displayName: "Stances & Positions", sortOrder: 4),
            TerminologyCategory(name: "blocks", displayName: "Blocks & Defense", sortOrder: 5),
            TerminologyCategory(name: "strikes", displayName: "Strikes & Attacks", sortOrder: 6),
            TerminologyCategory(name: "kicks", displayName: "Kicks & Leg Techniques", sortOrder: 7),
            TerminologyCategory(name: "patterns", displayName: "Patterns (Tul)", sortOrder: 8),
            TerminologyCategory(name: "titles", displayName: "Titles & Ranks", sortOrder: 9),
            TerminologyCategory(name: "philosophy", displayName: "Philosophy & Tenets", sortOrder: 10)
        ]
    }
    
    // MARK: - JSON Validation Utilities
    
    /**
     * Validates that belt system JSON matches expected structure
     */
    static func validateBeltSystemJSON() throws -> Bool {
        let belts = try loadBeltLevelsFromJSON()
        
        // Ensure we have expected number of belts
        guard belts.count >= 10 else {
            throw TestError.insufficientBelts(belts.count)
        }
        
        // Ensure sort orders are unique
        let sortOrders = belts.map { $0.sortOrder }
        let uniqueOrders = Set(sortOrders)
        guard sortOrders.count == uniqueOrders.count else {
            throw TestError.duplicateSortOrders
        }
        
        // Ensure starting belt exists
        guard BeltLevel.findStartingBelt(from: belts) != nil else {
            throw TestError.noStartingBelt
        }
        
        return true
    }
    
    /**
     * Compares belt data consistency between JSON and hardcoded tests
     */
    static func validateBeltDataConsistency() throws -> [String] {
        let jsonBelts = try loadBeltLevelsFromJSON()
        let hardcodedBelts = TestHelpers().createAllBeltLevels()
        
        var inconsistencies: [String] = []
        
        // Check if counts match
        if jsonBelts.count != hardcodedBelts.count {
            inconsistencies.append("Belt count mismatch: JSON=\(jsonBelts.count), Hardcoded=\(hardcodedBelts.count)")
        }
        
        // Check individual belt properties
        for jsonBelt in jsonBelts {
            if let hardcodedBelt = hardcodedBelts.first(where: { $0.shortName == jsonBelt.shortName }) {
                if jsonBelt.colorName != hardcodedBelt.colorName {
                    inconsistencies.append("\(jsonBelt.shortName): Color mismatch JSON=\(jsonBelt.colorName), Hardcoded=\(hardcodedBelt.colorName)")
                }
                
                if jsonBelt.sortOrder != hardcodedBelt.sortOrder {
                    inconsistencies.append("\(jsonBelt.shortName): Sort order mismatch JSON=\(jsonBelt.sortOrder), Hardcoded=\(hardcodedBelt.sortOrder)")
                }
            } else {
                inconsistencies.append("Belt \(jsonBelt.shortName) exists in JSON but not in hardcoded data")
            }
        }
        
        return inconsistencies
    }
}

// MARK: - Test Errors

enum TestError: Error, CustomStringConvertible {
    case missingJSONFile(String)
    case noStartingBelt
    case beltNotFound(String)
    case insufficientBelts(Int)
    case duplicateSortOrders
    case jsonParsingFailed(String)
    
    var description: String {
        switch self {
        case .missingJSONFile(let filename):
            return "Missing JSON file: \(filename)"
        case .noStartingBelt:
            return "No starting belt found in belt system"
        case .beltNotFound(let id):
            return "Belt not found with ID: \(id)"
        case .insufficientBelts(let count):
            return "Insufficient belts in system: \(count)"
        case .duplicateSortOrders:
            return "Duplicate sort orders found in belt system"
        case .jsonParsingFailed(let details):
            return "JSON parsing failed: \(details)"
        }
    }
}