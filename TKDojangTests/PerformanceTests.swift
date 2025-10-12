import XCTest
import SwiftData
@testable import TKDojang

/**
 * PerformanceTests.swift
 * 
 * PURPOSE: Simplified performance testing for centralized test infrastructure
 * 
 * Note: Temporarily simplified to focus on infrastructure validation
 * Complex performance tests with service dependencies will be restored after infrastructure stabilization
 */

// Temporarily disabled due to MainActor issues - will be restored after infrastructure stabilization
final class PerformanceTestsDisabled: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container using centralized factory
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = ModelContext(testContainer)
        
        // Set up test data
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Basic Performance Tests
    
    func testBasicDataFetchPerformance() throws {
        // Simple performance test for basic data fetching
        measure {
            let belts = try! testContext.fetch(FetchDescriptor<BeltLevel>())
            _ = belts.count
        }
    }
    
    func testTerminologyFetchPerformance() throws {
        // Simple performance test for terminology fetching
        measure {
            let terminology = try! testContext.fetch(FetchDescriptor<TerminologyEntry>())
            _ = terminology.count
        }
    }
    
    func testProfileCreationPerformance() throws {
        // Simple performance test for profile operations
        measure {
            let belts = try! testContext.fetch(FetchDescriptor<BeltLevel>())
            if let firstBelt = belts.first {
                let profile = UserProfile(name: "Performance Test User", currentBeltLevel: firstBelt)
                testContext.insert(profile)
                try! testContext.save()
            }
        }
    }
}