import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * TestDataFactoryDebugTest.swift
 * 
 * PURPOSE: Debug TestDataFactory failures to identify root cause
 */

final class TestDataFactoryDebugTest: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = testContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    func testBasicContainerWorks() throws {
        // This should pass - basic container functionality
        XCTAssertNotNil(testContainer)
        XCTAssertNotNil(testContext)
        
        let schema = testContainer.schema
        let modelNames = schema.entities.map { $0.name }
        
        XCTAssertTrue(modelNames.contains("UserProfile"))
        XCTAssertTrue(modelNames.contains("BeltLevel"))
    }
    
    func testTestDataFactoryInstantiation() throws {
        // Test if we can create the factory
        let dataFactory = TestDataFactory()
        XCTAssertNotNil(dataFactory)
    }
    
    func testBasicBeltLevelCreation() throws {
        // Test individual components of TestDataFactory
        let dataFactory = TestDataFactory()
        let belts = dataFactory.createBasicBeltLevels()
        
        XCTAssertGreaterThan(belts.count, 0)
        XCTAssertNotNil(belts.first?.name)
    }
    
    func testBasicCategoryCreation() throws {
        // Test category creation
        let dataFactory = TestDataFactory()
        let categories = dataFactory.createBasicCategories()
        
        XCTAssertGreaterThan(categories.count, 0)
        XCTAssertNotNil(categories.first?.name)
    }
    
    func testIndividualDataInsertion() throws {
        // Test inserting data step by step
        let dataFactory = TestDataFactory()
        let belts = dataFactory.createBasicBeltLevels()
        
        // Try inserting just belt levels
        for belt in belts {
            testContext.insert(belt)
        }
        
        try testContext.save()
        
        // Verify belt levels were saved
        let savedBelts = try testContext.fetch(FetchDescriptor<BeltLevel>())
        XCTAssertEqual(savedBelts.count, belts.count)
    }
    
    func testFullDataFactoryCreation() throws {
        // This is where the failure likely occurs
        let dataFactory = TestDataFactory()
        
        // Break down the creation step by step to find exact failure point
        print("🔍 Creating basic belt levels...")
        let belts = dataFactory.createBasicBeltLevels()
        XCTAssertGreaterThan(belts.count, 0)
        print("✅ Created \(belts.count) belt levels")
        
        print("🔍 Creating basic categories...")
        let categories = dataFactory.createBasicCategories()
        XCTAssertGreaterThan(categories.count, 0)
        print("✅ Created \(categories.count) categories")
        
        print("🔍 Inserting belt levels into context...")
        for belt in belts {
            testContext.insert(belt)
        }
        print("✅ Inserted belt levels")
        
        print("🔍 Inserting categories into context...")
        for category in categories {
            testContext.insert(category)
        }
        print("✅ Inserted categories")
        
        print("🔍 Saving belt levels and categories...")
        try testContext.save()
        print("✅ Saved basic data")
        
        print("🔍 Creating terminology entries...")
        for belt in belts {
            for category in categories {
                let entries = dataFactory.createSampleTerminologyEntries(belt: belt, category: category, count: 1)
                for entry in entries {
                    testContext.insert(entry)
                }
            }
        }
        print("✅ Created terminology entries")
        
        print("🔍 Final save...")
        try testContext.save()
        print("✅ COMPLETED - All data factory creation steps succeeded")
        
        // If we get here, it worked
        let beltLevels = try testContext.fetch(FetchDescriptor<BeltLevel>())
        XCTAssertGreaterThan(beltLevels.count, 0)
    }
}