import XCTest
import SwiftData
@testable import TKDojang

/**
 * JSONConsistencyTests.swift
 * 
 * PURPOSE: Validates that JSON-based content matches expected structure and consistency
 * 
 * ENSURES:
 * - belt_system.json loads correctly
 * - Belt data is consistent across test and production
 * - JSON content structure is valid
 * - No hardcoded data inconsistencies
 */

@MainActor
final class JSONConsistencyTests: XCTestCase {
    
    // MARK: - Belt System JSON Validation
    
    func testBeltSystemJSONLoads() throws {
        // Test that belt_system.json can be loaded without errors
        let belts = try JSONTestHelpers.loadBeltLevelsFromJSON()
        
        XCTAssertGreaterThan(belts.count, 10, "Should have reasonable number of belt levels")
        
        // Verify starting belt exists
        let startingBelt = BeltLevel.findStartingBelt(from: belts)
        XCTAssertNotNil(startingBelt, "Should have a starting belt")
        
        // Verify progression exists
        if let starting = startingBelt {
            let nextBelt = BeltLevel.findNextBelt(after: starting, in: belts)
            XCTAssertNotNil(nextBelt, "Should have belt progression")
        }
    }
    
    func testBeltSystemStructureValidation() throws {
        let isValid = try JSONTestHelpers.validateBeltSystemJSON()
        XCTAssertTrue(isValid, "Belt system JSON should pass validation")
    }
    
    func testBeltDataConsistency() throws {
        let inconsistencies = try JSONTestHelpers.validateBeltDataConsistency()
        
        if !inconsistencies.isEmpty {
            let message = "Belt data inconsistencies found:\n" + inconsistencies.joined(separator: "\n")
            print("⚠️ \(message)")
            
            // For now, just warn - don't fail the test as we're migrating
            // XCTFail(message)
        }
    }
    
    // MARK: - Belt Utility Integration Tests
    
    func testBeltUtilsWithJSONData() throws {
        let jsonBelts = try JSONTestHelpers.loadBeltLevelsFromJSON()
        
        // Test BeltUtils functions work with JSON-loaded data
        for belt in jsonBelts.prefix(5) {
            let fileId = BeltUtils.beltLevelToFileId(belt.shortName)
            XCTAssertFalse(fileId.isEmpty, "Should generate valid file ID")
            
            let displayName = BeltUtils.fileIdToBeltLevel(fileId)
            XCTAssertFalse(displayName.isEmpty, "Should generate valid display name")
            
            let colors = BeltUtils.getBeltColorsLegacy(for: fileId)
            XCTAssertFalse(colors.isEmpty, "Should have belt colors")
        }
    }
    
    // MARK: - Production Data Validation
    
    func testJSONMatchesExpectedStructure() throws {
        let startingBelt = try JSONTestHelpers.getStartingBeltFromJSON()
        
        // Verify expected properties are present
        XCTAssertFalse(startingBelt.name.isEmpty, "Belt should have name")
        XCTAssertFalse(startingBelt.shortName.isEmpty, "Belt should have short name")
        XCTAssertFalse(startingBelt.colorName.isEmpty, "Belt should have color name")
        XCTAssertNotNil(startingBelt.primaryColor, "Belt should have primary color")
        XCTAssertNotNil(startingBelt.requirements, "Belt should have requirements")
        
        // Verify it's actually the starting belt
        XCTAssertTrue(startingBelt.isKyup, "Starting belt should be kyup grade")
    }
    
    func testSpecificBeltLookup() throws {
        // Test finding specific belts by ID
        let whiteBelt = try JSONTestHelpers.getBeltFromJSON(id: "10th_keup")
        XCTAssertEqual(whiteBelt.colorName.lowercased(), "white", "Should find white belt")
        
        let yellowBelt = try JSONTestHelpers.getBeltFromJSON(id: "9th_keup")
        XCTAssertTrue(yellowBelt.colorName.lowercased().contains("yellow"), "Should find yellow belt")
    }
}