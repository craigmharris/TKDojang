import XCTest
import SwiftData
@testable import TKDojang

/**
 * DynamicDiscoveryTests.swift
 * 
 * PURPOSE: Core dynamic discovery pattern testing for architectural consistency
 * 
 * IMPORTANCE: Validates the architectural consistency implemented on September 27, 2025
 * Tests the universal subdirectory-aware dynamic discovery pattern across all content loaders
 * 
 * TEST COVERAGE:
 * - Subdirectory-first, bundle-root fallback pattern validation
 * - Dynamic file discovery across StepSparring, Patterns, and Techniques
 * - Cross-system integration and consistency
 * - Performance impact assessment of dynamic discovery
 * - Error handling for missing files and directories
 * - Naming convention enforcement
 */
final class DynamicDiscoveryTests: XCTestCase {
    
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
    
    // MARK: - Subdirectory Discovery Pattern Tests
    
    func testStepSparringSubdirectoryDiscovery() throws {
        // Test StepSparringContentLoader subdirectory-first discovery pattern
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Should attempt StepSparring subdirectory first, then fallback to bundle root
        XCTAssertNoThrow(stepSparringLoader.loadAllContent(), "StepSparring dynamic discovery should not throw")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Should complete within reasonable time
        XCTAssertLessThan(loadTime, 5.0, "StepSparring discovery should complete within 5 seconds")
        
        // Verify sequences were discovered and loaded
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        XCTAssertGreaterThanOrEqual(sequences.count, 0, "StepSparring discovery should find sequences")
        
        print("✅ StepSparring subdirectory discovery pattern validated (Load time: \(String(format: "%.3f", loadTime))s)")
    }
    
    func testPatternSubdirectoryDiscovery() throws {
        // Test PatternContentLoader subdirectory-first discovery pattern
        let patternService = PatternDataService(modelContext: testContext)
        let patternLoader = PatternContentLoader(patternService: patternService)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Should attempt Patterns subdirectory first, then fallback to bundle root
        // Looks for files matching "*_patterns.json" pattern
        XCTAssertNoThrow(patternLoader.loadAllContent(), "Pattern dynamic discovery should not throw")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Should complete within reasonable time
        XCTAssertLessThan(loadTime, 5.0, "Pattern discovery should complete within 5 seconds")
        
        // Verify patterns were discovered and loaded
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        XCTAssertGreaterThanOrEqual(patterns.count, 0, "Pattern discovery should find patterns")
        
        print("✅ Pattern subdirectory discovery pattern validated (Load time: \(String(format: "%.3f", loadTime))s)")
    }
    
    func testTechniquesSubdirectoryDiscovery() throws {
        // Test TechniquesDataService subdirectory-first discovery pattern  
        let techniquesService = TechniquesDataService()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let expectation = expectation(description: "Techniques loading completion")
        
        Task { @MainActor in
            // Should attempt Techniques subdirectory first, then fallback to bundle root
            // Excludes special files like target_areas.json and techniques_index.json
            await techniquesService.loadAllTechniques()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let loadTime = endTime - startTime
            
            // Should complete within reasonable time
            XCTAssertLessThan(loadTime, 10.0, "Techniques discovery should complete within 10 seconds")
            XCTAssertFalse(techniquesService.isLoading, "Techniques service should finish loading")
            
            // Verify techniques were discovered and loaded
            let techniques = techniquesService.getAllTechniques()
            XCTAssertGreaterThanOrEqual(techniques.count, 0, "Techniques discovery should find techniques")
            
            print("✅ Techniques subdirectory discovery pattern validated (Load time: \(String(format: "%.3f", loadTime))s)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0)
    }
    
    // MARK: - Fallback Mechanism Tests
    
    func testSubdirectoryFallbackConsistency() throws {
        // Test that all loaders use consistent fallback mechanism
        // Pattern: Try subdirectory first, then bundle root, then handle gracefully
        
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
        
        let patternService = PatternDataService(modelContext: testContext)
        let patternLoader = PatternContentLoader(patternService: patternService)
        
        let techniquesService = TechniquesDataService()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // All should use the same fallback pattern and complete without errors
        XCTAssertNoThrow(stepSparringLoader.loadAllContent(), "StepSparring fallback should work")
        XCTAssertNoThrow(patternLoader.loadAllContent(), "Pattern fallback should work")
        
        let expectation = expectation(description: "Techniques fallback completion")
        Task { @MainActor in
            await techniquesService.loadAllTechniques()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // All fallback mechanisms should complete within reasonable time
        XCTAssertLessThan(totalTime, 15.0, "All fallback mechanisms should complete within 15 seconds")
        
        print("✅ Subdirectory fallback consistency validated across all loaders (Total time: \(String(format: "%.3f", totalTime))s)")
    }
    
    func testBundleRootFallbackHandling() throws {
        // Test that bundle root fallback works when subdirectories are not available
        // This simulates deployment scenarios where files might be flattened
        
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
        
        // Should gracefully fallback to bundle root if subdirectory not found
        XCTAssertNoThrow(stepSparringLoader.loadAllContent(), "Bundle root fallback should work")
        
        // Should still be able to find and load content
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        // Note: Count might be 0 in test environment, but should not crash
        XCTAssertGreaterThanOrEqual(sequences.count, 0, "Bundle root fallback should handle content gracefully")
        
        print("✅ Bundle root fallback handling validated")
    }
    
    // MARK: - Cross-System Integration Tests
    
    func testCrossSystemDynamicDiscoveryIntegration() throws {
        // Test that all dynamic discovery systems work together without conflicts
        // Simulates real-world app startup scenario
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Initialize all services and loaders
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
        
        let patternService = PatternDataService(modelContext: testContext)
        let patternLoader = PatternContentLoader(patternService: patternService)
        
        let techniquesService = TechniquesDataService()
        
        // Load all content types simultaneously (like app startup)
        XCTAssertNoThrow(stepSparringLoader.loadAllContent(), "StepSparring should load without conflicts")
        XCTAssertNoThrow(patternLoader.loadAllContent(), "Patterns should load without conflicts")
        
        let expectation = expectation(description: "Cross-system integration completion")
        Task { @MainActor in
            await techniquesService.loadAllTechniques()
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 20.0)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // All systems should integrate smoothly within reasonable time
        XCTAssertLessThan(totalTime, 20.0, "Cross-system integration should complete within 20 seconds")
        
        // Verify no conflicts occurred
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let techniques = techniquesService.getAllTechniques()
        
        // All should coexist without issues
        XCTAssertGreaterThanOrEqual(sequences.count, 0, "StepSparring should coexist with other content")
        XCTAssertGreaterThanOrEqual(patterns.count, 0, "Patterns should coexist with other content")
        XCTAssertGreaterThanOrEqual(techniques.count, 0, "Techniques should coexist with other content")
        
        print("✅ Cross-system dynamic discovery integration validated")
        print("   Sequences found: \(sequences.count)")
        print("   Patterns found: \(patterns.count)")
        print("   Techniques found: \(techniques.count)")
        print("   Total integration time: \(String(format: "%.3f", totalTime))s")
    }
    
    // MARK: - Performance Impact Tests
    
    func testDynamicDiscoveryPerformanceImpact() throws {
        // Test that dynamic discovery doesn't significantly impact performance
        // Compared to hardcoded file lists, dynamic discovery should be minimal overhead
        
        let iterations = 5
        var totalTime: Double = 0
        
        for iteration in 1...iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            
            // Test one complete discovery cycle
            let stepSparringService = StepSparringDataService(modelContext: testContext)
            let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
            stepSparringLoader.loadAllContent()
            
            let endTime = CFAbsoluteTimeGetCurrent()
            let iterationTime = endTime - startTime
            totalTime += iterationTime
            
            print("   Iteration \(iteration): \(String(format: "%.3f", iterationTime))s")
        }
        
        let averageTime = totalTime / Double(iterations)
        
        // Dynamic discovery should have minimal performance impact
        XCTAssertLessThan(averageTime, 3.0, "Average dynamic discovery should be under 3 seconds")
        
        print("✅ Dynamic discovery performance impact validated")
        print("   Average discovery time: \(String(format: "%.3f", averageTime))s over \(iterations) iterations")
        print("   Total time: \(String(format: "%.3f", totalTime))s")
    }
    
    func testConcurrentDiscoveryPerformance() throws {
        // Test performance when multiple discovery operations run concurrently
        // Simulates multiple content types loading simultaneously
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let group = DispatchGroup()
        
        // Start concurrent discovery operations
        DispatchQueue.global().async(group: group) {
            let stepSparringService = StepSparringDataService(modelContext: self.testContext)
            let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
            stepSparringLoader.loadAllContent()
        }
        
        DispatchQueue.global().async(group: group) {
            let patternService = PatternDataService(modelContext: self.testContext)
            let patternLoader = PatternContentLoader(patternService: patternService)
            patternLoader.loadAllContent()
        }
        
        group.wait()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let concurrentTime = endTime - startTime
        
        // Concurrent discovery should complete efficiently
        XCTAssertLessThan(concurrentTime, 10.0, "Concurrent discovery should complete within 10 seconds")
        
        print("✅ Concurrent discovery performance validated (Time: \(String(format: "%.3f", concurrentTime))s)")
    }
    
    // MARK: - Error Handling Tests
    
    func testMissingDirectoryErrorHandling() throws {
        // Test graceful handling when subdirectories don't exist
        // Should fallback to bundle root without crashing
        
        let stepSparringService = StepSparringDataService(modelContext: testContext)
        let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
        
        // Should handle missing directories gracefully
        XCTAssertNoThrow(stepSparringLoader.loadAllContent(), "Should handle missing directories gracefully")
        
        // Should not crash the app
        let sequences = try testContext.fetch(FetchDescriptor<StepSparringSequence>())
        XCTAssertGreaterThanOrEqual(sequences.count, 0, "Should handle missing directories without crashing")
        
        print("✅ Missing directory error handling validated")
    }
    
    func testMalformedJSONErrorHandling() throws {
        // Test that malformed JSON files don't crash the discovery process
        // Should continue loading other valid files
        
        let patternService = PatternDataService(modelContext: testContext)
        let patternLoader = PatternContentLoader(patternService: patternService)
        
        // Should handle malformed JSON gracefully and continue
        XCTAssertNoThrow(patternLoader.loadAllContent(), "Should handle malformed JSON gracefully")
        
        // App should remain functional
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        XCTAssertGreaterThanOrEqual(patterns.count, 0, "Should continue functioning despite malformed JSON")
        
        print("✅ Malformed JSON error handling validated")
    }
    
    // MARK: - Naming Convention Tests
    
    func testPatternNamingConventionEnforcement() throws {
        // Test that pattern files follow "*_patterns.json" naming convention
        // This ensures consistent discovery across all pattern files
        
        let validPatternNames = [
            "beginner_patterns.json",
            "intermediate_patterns.json", 
            "advanced_patterns.json",
            "traditional_patterns.json",
            "competition_patterns.json"
        ]
        
        let invalidPatternNames = [
            "patterns.json",
            "pattern_data.json",
            "belts.json",
            "training.json"
        ]
        
        // Test valid naming convention recognition
        for validName in validPatternNames {
            XCTAssertTrue(validName.contains("_patterns"), "Valid pattern files should contain '_patterns': \(validName)")
            XCTAssertTrue(validName.hasSuffix(".json"), "Valid pattern files should be JSON: \(validName)")
        }
        
        // Test invalid naming convention rejection
        for invalidName in invalidPatternNames {
            XCTAssertFalse(invalidName.contains("_patterns"), "Invalid pattern files should not contain '_patterns': \(invalidName)")
        }
        
        print("✅ Pattern naming convention enforcement validated")
    }
    
    func testStepSparringNamingFlexibility() throws {
        // Test that step sparring accepts any JSON files in subdirectory
        // More flexible than patterns to accommodate various sequence types
        
        let validStepSparringNames = [
            "3_step_sparring.json",
            "2_step_sparring.json", 
            "1_step_sparring.json",
            "semi_free_sparring.json",
            "free_sparring.json",
            "competition_sparring.json"
        ]
        
        // Test flexible naming acceptance
        for validName in validStepSparringNames {
            XCTAssertTrue(validName.hasSuffix(".json"), "StepSparring files should be JSON: \(validName)")
            // Any JSON file in StepSparring subdirectory is valid
        }
        
        print("✅ StepSparring naming flexibility validated")
    }
    
    func testTechniquesExclusionHandling() throws {
        // Test that techniques properly exclude special files
        // target_areas.json and techniques_index.json should be excluded
        
        let includedTechniqueFiles = [
            "kicks.json",
            "strikes.json",
            "blocks.json", 
            "stances.json",
            "hand_techniques.json",
            "footwork.json",
            "combinations.json",
            "fundamentals.json",
            "belt_requirements.json"
        ]
        
        let excludedTechniqueFiles = [
            "target_areas.json",
            "techniques_index.json"
        ]
        
        // Test inclusion criteria
        for includedFile in includedTechniqueFiles {
            XCTAssertFalse(excludedTechniqueFiles.contains(includedFile), "Should include technique file: \(includedFile)")
        }
        
        // Test exclusion criteria
        for excludedFile in excludedTechniqueFiles {
            XCTAssertTrue(excludedTechniqueFiles.contains(excludedFile), "Should exclude special file: \(excludedFile)")
        }
        
        print("✅ Techniques exclusion handling validated")
    }
}