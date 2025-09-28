import Foundation
import SwiftData
import SwiftUI

/**
 * BeltUtils.swift
 * 
 * PURPOSE: Centralized utilities for belt level operations and mappings
 * 
 * DESIGN DECISION: Replace hardcoded belt mappings with JSON-based lookups
 * WHY: Eliminates hardcoded belt references, makes system extensible for new belt levels
 * Benefits: Single source of truth, automatic updates when belt system changes
 */

@MainActor
final class BeltUtils {
    
    // MARK: - ID/Name Conversion Utilities
    
    /**
     * Converts belt level short name to JSON file ID
     * Example: "10th Keup" -> "10th_keup"
     */
    static func beltLevelToFileId(_ beltLevel: String) -> String {
        return beltLevel.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    /**
     * Converts JSON file ID to display name
     * Example: "10th_keup" -> "10th Keup"
     */
    static func fileIdToBeltLevel(_ fileId: String) -> String {
        return fileId.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { String($0).capitalized }
            .joined(separator: " ")
    }
    
    /**
     * Gets display name from BeltLevel model
     */
    static func getDisplayName(for beltLevel: BeltLevel) -> String {
        return beltLevel.shortName
    }
    
    // MARK: - Database Belt Queries
    
    /**
     * Fetches all belt levels from database, sorted by progression
     */
    static func fetchAllBeltLevels(from modelContext: ModelContext) -> [BeltLevel] {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\BeltLevel.sortOrder, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ BeltUtils: Failed to fetch belt levels: \(error)")
            return []
        }
    }
    
    /**
     * Finds starting belt (typically 10th Keup) from database
     */
    static func findStartingBelt(from modelContext: ModelContext) -> BeltLevel? {
        let allBelts = fetchAllBeltLevels(from: modelContext)
        return BeltLevel.findStartingBelt(from: allBelts)
    }
    
    /**
     * Finds belt by ID pattern with fallback
     */
    static func findBelt(byId beltId: String, from modelContext: ModelContext) -> BeltLevel? {
        let allBelts = fetchAllBeltLevels(from: modelContext)
        return BeltLevel.findBelt(byId: beltId, in: allBelts)
    }
    
    /**
     * Gets next belt in progression
     */
    static func findNextBelt(after currentBelt: BeltLevel, from modelContext: ModelContext) -> BeltLevel? {
        let allBelts = fetchAllBeltLevels(from: modelContext)
        return BeltLevel.findNextBelt(after: currentBelt, in: allBelts)
    }
    
    // MARK: - Belt ID Mapping
    
    /**
     * Gets belt ID to sort order mapping from actual belt system data
     */
    static func getBeltIdMapping(from modelContext: ModelContext) -> [String: Int] {
        let allBelts = fetchAllBeltLevels(from: modelContext)
        var mapping: [String: Int] = [:]
        
        for belt in allBelts {
            let beltId = beltLevelToFileId(belt.shortName)
            mapping[beltId] = belt.sortOrder
        }
        
        return mapping
    }
    
    // MARK: - Belt Color Utilities
    
    /**
     * Gets belt colors for UI display (replaces hardcoded color mappings)
     */
    static func getBeltColors(for beltLevel: BeltLevel) -> [Color] {
        guard let primaryHex = beltLevel.primaryColor else { return [.gray] }
        
        let primaryColor = Color(hex: primaryHex)
        
        if let secondaryHex = beltLevel.secondaryColor, 
           secondaryHex != primaryHex {
            return [primaryColor, Color(hex: secondaryHex)]
        }
        
        return [primaryColor]
    }
    
    /**
     * Gets belt colors by belt ID string (for JSON-based views)
     */
    static func getBeltColors(for beltId: String, from modelContext: ModelContext) -> [Color] {
        if let beltLevel = findBelt(byId: beltId, from: modelContext) {
            return getBeltColors(for: beltLevel)
        }
        
        // Fallback to legacy hardcoded colors for backward compatibility
        return getBeltColorsLegacy(for: beltId)
    }
    
    /**
     * Legacy hardcoded colors as fallback (public for view compatibility)
     */
    static func getBeltColorsLegacy(for beltId: String) -> [Color] {
        switch beltId {
        case "10th_keup": return [.white]
        case "9th_keup": return [.white, .yellow]
        case "8th_keup": return [.yellow]
        case "7th_keup": return [.yellow, .green]
        case "6th_keup": return [.green]
        case "5th_keup": return [.green, .blue]
        case "4th_keup": return [.blue]
        case "3rd_keup": return [.blue, .red]
        case "2nd_keup": return [.red]
        case "1st_keup": return [.red, .black]
        case "1st_dan", "2nd_dan": return [.black]
        default: return [.gray]
        }
    }
    
    /**
     * Gets sort order for belt ID string (for content sorting)
     * Returns actual sort order from database, fallback to high number for unknown belts
     */
    static func getSortOrder(for beltId: String, from modelContext: ModelContext) -> Int {
        if let beltLevel = findBelt(byId: beltId, from: modelContext) {
            return beltLevel.sortOrder
        }
        
        // Fallback to legacy hardcoded sort order for compatibility
        return getLegacySortOrder(for: beltId)
    }
    
    /**
     * Legacy hardcoded sort order as fallback (public for view compatibility)
     */
    static func getLegacySortOrder(for beltId: String) -> Int {
        let beltOrder = [
            "2nd_dan": 1, "1st_dan": 2,
            "1st_keup": 3, "2nd_keup": 4, "3rd_keup": 5, "4th_keup": 6, "5th_keup": 7,
            "6th_keup": 8, "7th_keup": 9, "8th_keup": 10, "9th_keup": 11, "10th_keup": 12
        ]
        return beltOrder[beltId] ?? 999
    }
    
    /**
     * Determines if belt level matches a JSON file pattern
     */
    static func beltMatchesFilePattern(_ beltLevel: BeltLevel, pattern: String) -> Bool {
        let beltId = beltLevelToFileId(beltLevel.shortName)
        return pattern.contains(beltId)
    }
}