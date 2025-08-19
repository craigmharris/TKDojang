import Foundation
import SwiftData
import XCTest
@testable import TKDojang

/**
 * TestHelpers.swift
 * 
 * PURPOSE: Shared testing utilities and infrastructure for TKDojang test suite
 * 
 * ARCHITECTURE DECISION: Centralized test helpers to reduce code duplication
 * WHY: Ensures consistent test setup, reduces maintenance burden, improves test reliability
 * 
 * PROVIDES:
 * - Test data creation utilities
 * - SwiftData container setup helpers
 * - Common assertions and validations
 * - Performance measurement utilities
 */

// MARK: - Test Container Factory

/**
 * Factory for creating test-specific SwiftData containers
 */
class TestContainerFactory {
    
    /**
     * Creates an in-memory SwiftData container for testing
     * 
     * PURPOSE: Provides isolated, fast storage for tests
     * WHY: In-memory storage prevents test data persistence between runs
     */
    static func createTestContainer() throws -> ModelContainer {
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
    
    /**
     * Creates a test container pre-loaded with basic test data
     */
    static func createTestContainerWithData() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: context)
        
        return (container, context)
    }
}

// MARK: - Test Data Factory

/**
 * Factory for creating consistent test data across test suites
 */
class TestDataFactory {
    
    // MARK: - Belt Level Creation
    
    /**
     * Creates a complete set of TAGB belt levels for testing
     */
    func createAllBeltLevels() -> [BeltLevel] {
        let beltData: [(name: String, short: String, color: String, order: Int, isKyup: Bool)] = [
            ("10th Keup (White Belt)", "10th Keup", "White", 15, true),
            ("9th Keup (Yellow Belt)", "9th Keup", "Yellow", 14, true),
            ("8th Keup (Orange Belt)", "8th Keup", "Orange", 13, true),
            ("7th Keup (Green Belt)", "7th Keup", "Green", 12, true),
            ("6th Keup (Purple Belt)", "6th Keup", "Purple", 11, true),
            ("5th Keup (Blue Belt)", "5th Keup", "Blue", 10, true),
            ("4th Keup (Blue/Red Belt)", "4th Keup", "Blue/Red", 9, true),
            ("3rd Keup (Red Belt)", "3rd Keup", "Red", 8, true),
            ("2nd Keup (Brown Belt)", "2nd Keup", "Brown", 7, true),
            ("1st Keup (Brown/Black Belt)", "1st Keup", "Brown/Black", 6, true),
            ("1st Dan (Black Belt)", "1st Dan", "Black", 5, false),
            ("2nd Dan (Black Belt)", "2nd Dan", "Black", 4, false),
            ("3rd Dan (Black Belt)", "3rd Dan", "Black", 3, false)
        ]
        
        return beltData.map { data in
            let belt = BeltLevel(name: data.name, shortName: data.short, colorName: data.color, sortOrder: data.order, isKyup: data.isKyup)
            belt.primaryColor = data.color.lowercased().replacingOccurrences(of: "/", with: "")
            belt.secondaryColor = data.color.contains("/") ? data.color.components(separatedBy: "/").last : nil
            return belt
        }
    }
    
    /**
     * Creates basic test belt levels (white, yellow, green)
     */
    func createBasicBeltLevels() -> [BeltLevel] {
        let basicBelts = [
            BeltLevel(name: "10th Keup (White Belt)", shortName: "10th Keup", colorName: "White", sortOrder: 15, isKyup: true),
            BeltLevel(name: "9th Keup (Yellow Belt)", shortName: "9th Keup", colorName: "Yellow", sortOrder: 14, isKyup: true),
            BeltLevel(name: "7th Keup (Green Belt)", shortName: "7th Keup", colorName: "Green", sortOrder: 12, isKyup: true)
        ]
        
        // Set colors
        basicBelts[0].primaryColor = "white"
        basicBelts[1].primaryColor = "yellow"
        basicBelts[2].primaryColor = "green"
        
        return basicBelts
    }
    
    // MARK: - Category Creation
    
    /**
     * Creates all terminology categories for testing
     */
    func createAllCategories() -> [TerminologyCategory] {
        let categoryData: [(name: String, display: String, order: Int)] = [
            ("basics", "Basic Terms", 1),
            ("techniques", "Techniques & Movements", 2),
            ("commands", "Commands & Instructions", 3),
            ("numbers", "Numbers & Counting", 4),
            ("stances", "Stances & Positions", 5),
            ("blocks", "Blocks & Defenses", 6),
            ("strikes", "Strikes & Attacks", 7),
            ("titles", "Titles & Honorifics", 8)
        ]
        
        return categoryData.map { data in
            let category = TerminologyCategory(name: data.name, displayName: data.display, sortOrder: data.order)
            category.iconName = "circle.fill" // Default SF Symbol
            return category
        }
    }
    
    /**
     * Creates basic test categories
     */
    func createBasicCategories() -> [TerminologyCategory] {
        return [
            TerminologyCategory(name: "techniques", displayName: "Basic Techniques", sortOrder: 1),
            TerminologyCategory(name: "commands", displayName: "Commands", sortOrder: 2),
            TerminologyCategory(name: "numbers", displayName: "Numbers", sortOrder: 3)
        ]
    }
    
    // MARK: - Terminology Entry Creation
    
    /**
     * Creates sample terminology entries for testing
     */
    func createSampleTerminologyEntries(belt: BeltLevel, category: TerminologyCategory, count: Int = 5) -> [TerminologyEntry] {
        let sampleTerms = [
            ("Front Kick", "앞차기", "ap chagi"),
            ("Side Kick", "옆차기", "yeop chagi"),
            ("Roundhouse Kick", "돌려차기", "dollyeo chagi"),
            ("Back Kick", "뒤차기", "dwi chagi"),
            ("Hook Kick", "후크차기", "huk chagi"),
            ("Axe Kick", "내려차기", "naeryeo chagi"),
            ("Low Block", "하단막기", "hadan makgi"),
            ("Middle Block", "중단막기", "jungdan makgi"),
            ("High Block", "상단막기", "sangdan makgi"),
            ("Attention", "차렷", "charyeot"),
            ("Ready Position", "준비자세", "junbi jase"),
            ("Begin", "시작", "sijak"),
            ("Stop", "그만", "geuman"),
            ("One", "하나", "hana"),
            ("Two", "둘", "dul"),
            ("Three", "셋", "set"),
            ("Four", "넷", "net"),
            ("Five", "다섯", "daseot")
        ]
        
        var entries: [TerminologyEntry] = []
        for i in 0..<min(count, sampleTerms.count) {
            let term = sampleTerms[i]
            let entry = TerminologyEntry(
                englishTerm: term.0,
                koreanHangul: term.1,
                romanizedPronunciation: term.2,
                beltLevel: belt,
                category: category,
                difficulty: Int.random(in: 1...3)
            )
            
            // Add some variety to test data
            if i % 3 == 0 {
                entry.phoneticPronunciation = "[\(term.2)]"
            }
            if i % 4 == 0 {
                entry.definition = "A \(category.name) technique used in Taekwondo"
            }
            
            entries.append(entry)
        }
        
        return entries
    }
    
    // MARK: - User Profile Creation
    
    /**
     * Creates test user profiles with different configurations
     */
    func createTestUserProfiles(belts: [BeltLevel]) -> [UserProfile] {
        guard !belts.isEmpty else { return [] }
        
        var profiles: [UserProfile] = []
        
        // Beginner profile
        let beginnerProfile = UserProfile(currentBeltLevel: belts[0], learningMode: .mastery)
        beginnerProfile.dailyStudyGoal = 15
        beginnerProfile.preferredCategories = ["techniques", "basics"]
        profiles.append(beginnerProfile)
        
        // Intermediate profile
        if belts.count > 1 {
            let intermediateProfile = UserProfile(currentBeltLevel: belts[1], learningMode: .progression)
            intermediateProfile.dailyStudyGoal = 25
            intermediateProfile.preferredCategories = ["techniques", "commands", "stances"]
            profiles.append(intermediateProfile)
        }
        
        // Advanced profile
        if belts.count > 2 {
            let advancedProfile = UserProfile(currentBeltLevel: belts[2], learningMode: .mastery)
            advancedProfile.dailyStudyGoal = 40
            advancedProfile.preferredCategories = ["techniques", "commands", "strikes", "blocks"]
            profiles.append(advancedProfile)
        }
        
        return profiles
    }
    
    // MARK: - Progress Data Creation
    
    /**
     * Creates sample progress entries for testing
     */
    func createSampleProgress(entries: [TerminologyEntry], profile: UserProfile, progressVariety: Bool = true) -> [UserTerminologyProgress] {
        var progressEntries: [UserTerminologyProgress] = []
        
        for (index, entry) in entries.enumerated() {
            let progress = UserTerminologyProgress(terminologyEntry: entry, userProfile: profile)
            
            if progressVariety {
                // Add variety to progress states for realistic testing
                switch index % 5 {
                case 0:
                    // New item - no progress
                    break
                case 1:
                    // Some correct answers
                    progress.recordAnswer(isCorrect: true, responseTime: 2.0)
                    progress.recordAnswer(isCorrect: true, responseTime: 1.8)
                case 2:
                    // Mixed performance
                    progress.recordAnswer(isCorrect: true, responseTime: 2.5)
                    progress.recordAnswer(isCorrect: false, responseTime: 4.0)
                    progress.recordAnswer(isCorrect: true, responseTime: 2.2)
                case 3:
                    // Advanced progress
                    for _ in 0..<6 {
                        progress.recordAnswer(isCorrect: true, responseTime: Double.random(in: 1.5...2.5))
                    }
                case 4:
                    // Struggling item
                    progress.recordAnswer(isCorrect: false, responseTime: 5.0)
                    progress.recordAnswer(isCorrect: false, responseTime: 4.5)
                    progress.recordAnswer(isCorrect: true, responseTime: 3.0)
                default:
                    break
                }
            }
            
            progressEntries.append(progress)
        }
        
        return progressEntries
    }
    
    // MARK: - Complete Setup Methods
    
    /**
     * Creates basic test data structure in the provided context
     */
    func createBasicTestData(in context: ModelContext) throws {
        let belts = createBasicBeltLevels()
        let categories = createBasicCategories()
        
        // Insert belt levels and categories
        for belt in belts {
            context.insert(belt)
        }
        for category in categories {
            context.insert(category)
        }
        
        // Create terminology entries
        for belt in belts {
            for category in categories {
                let entries = createSampleTerminologyEntries(belt: belt, category: category, count: 3)
                for entry in entries {
                    context.insert(entry)
                }
            }
        }
        
        // Create test profiles
        let profiles = createTestUserProfiles(belts: belts)
        for profile in profiles {
            context.insert(profile)
        }
        
        try context.save()
    }
    
    /**
     * Creates comprehensive test data for performance testing
     */
    func createLargeTestDataset(in context: ModelContext) throws {
        let belts = createAllBeltLevels()
        let categories = createAllCategories()
        
        // Insert belt levels and categories
        for belt in belts {
            context.insert(belt)
        }
        for category in categories {
            context.insert(category)
        }
        
        // Create terminology entries (10-15 per belt-category combination)
        var totalEntries = 0
        for belt in belts {
            for category in categories {
                let count = Int.random(in: 10...15)
                let entries = createSampleTerminologyEntries(belt: belt, category: category, count: count)
                for entry in entries {
                    context.insert(entry)
                    totalEntries += 1
                }
            }
        }
        
        try context.save()
        print("📊 Created large test dataset: \(totalEntries) terminology entries")
    }
}

// MARK: - Test Assertion Helpers

/**
 * Custom assertions for TKDojang-specific validations
 */
class TKDojangAssertions {
    
    /**
     * Asserts that a terminology entry is valid
     */
    static func assertValidTerminologyEntry(_ entry: TerminologyEntry, file: StaticString = #file, line: UInt = #line) {
        XCTAssertFalse(entry.englishTerm.isEmpty, "English term should not be empty", file: file, line: line)
        XCTAssertFalse(entry.koreanHangul.isEmpty, "Korean hangul should not be empty", file: file, line: line)
        XCTAssertFalse(entry.romanizedPronunciation.isEmpty, "Romanized pronunciation should not be empty", file: file, line: line)
        XCTAssertNotNil(entry.beltLevel, "Entry should have belt level", file: file, line: line)
        XCTAssertNotNil(entry.category, "Entry should have category", file: file, line: line)
        XCTAssertGreaterThan(entry.difficulty, 0, "Difficulty should be positive", file: file, line: line)
        XCTAssertLessThanOrEqual(entry.difficulty, 5, "Difficulty should not exceed 5", file: file, line: line)
    }
    
    /**
     * Asserts that a user profile is valid
     */
    static func assertValidUserProfile(_ profile: UserProfile, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(profile.currentBeltLevel, "Profile should have current belt level", file: file, line: line)
        XCTAssertGreaterThan(profile.dailyStudyGoal, 0, "Study goal should be positive", file: file, line: line)
        XCTAssertLessThan(profile.dailyStudyGoal, 1000, "Study goal should be reasonable", file: file, line: line)
        XCTAssertNotNil(profile.createdAt, "Profile should have creation date", file: file, line: line)
        XCTAssertNotNil(profile.updatedAt, "Profile should have update date", file: file, line: line)
    }
    
    /**
     * Asserts that progress data is consistent
     */
    static func assertValidProgress(_ progress: UserTerminologyProgress, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNotNil(progress.terminologyEntry, "Progress should have terminology entry", file: file, line: line)
        XCTAssertNotNil(progress.userProfile, "Progress should have user profile", file: file, line: line)
        XCTAssertGreaterThanOrEqual(progress.currentBox, 1, "Current box should be at least 1", file: file, line: line)
        XCTAssertLessThanOrEqual(progress.currentBox, 5, "Current box should not exceed 5", file: file, line: line)
        XCTAssertGreaterThanOrEqual(progress.correctCount, 0, "Correct count should be non-negative", file: file, line: line)
        XCTAssertGreaterThanOrEqual(progress.incorrectCount, 0, "Incorrect count should be non-negative", file: file, line: line)
        XCTAssertGreaterThanOrEqual(progress.consecutiveCorrect, 0, "Consecutive correct should be non-negative", file: file, line: line)
        
        // Logical consistency checks
        XCTAssertEqual(progress.totalReviews, progress.correctCount + progress.incorrectCount, 
                      "Total reviews should equal correct + incorrect", file: file, line: line)
        
        if progress.correctCount == 0 {
            XCTAssertEqual(progress.consecutiveCorrect, 0, "No consecutive correct if no correct answers", file: file, line: line)
        }
    }
    
    /**
     * Asserts that belt levels are properly sorted
     */
    static func assertBeltLevelSorting(_ belts: [BeltLevel], file: StaticString = #file, line: UInt = #line) {
        guard belts.count > 1 else { return }
        
        for i in 1..<belts.count {
            let current = belts[i].sortOrder
            let previous = belts[i-1].sortOrder
            XCTAssertGreaterThan(current, previous, "Belt levels should be sorted by sort order", file: file, line: line)
        }
    }
}

// MARK: - Performance Measurement Helpers

/**
 * Utilities for measuring and validating performance
 */
class PerformanceMeasurement {
    
    /**
     * Measures the time taken to execute a block
     */
    static func measureExecutionTime<T>(_ operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeInterval = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeInterval)
    }
    
    /**
     * Asserts that an operation completes within a time limit
     */
    static func assertPerformance<T>(
        _ operation: () throws -> T,
        completesWithin timeLimit: TimeInterval,
        file: StaticString = #file,
        line: UInt = #line
    ) rethrows -> T {
        let measurement = try measureExecutionTime(operation)
        XCTAssertLessThan(measurement.timeInterval, timeLimit, 
                         "Operation should complete within \(timeLimit) seconds, took \(measurement.timeInterval)", 
                         file: file, line: line)
        return measurement.result
    }
    
    /**
     * Measures memory usage before and after an operation
     */
    static func measureMemoryUsage<T>(_ operation: () throws -> T) rethrows -> (result: T, memoryDelta: Int64) {
        let startMemory = getCurrentMemoryUsage()
        let result = try operation()
        let endMemory = getCurrentMemoryUsage()
        let memoryDelta = endMemory - startMemory
        return (result, memoryDelta)
    }
    
    private static func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Mock Objects

/**
 * Mock implementations for testing complex interactions
 */
class MockTerminologyService {
    var mockEntries: [TerminologyEntry] = []
    var getEntriesCallCount = 0
    var shouldSimulateError = false
    
    func getTerminologyEntries(forBeltLevel beltLevel: BeltLevel) throws -> [TerminologyEntry] {
        getEntriesCallCount += 1
        
        if shouldSimulateError {
            throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error"])
        }
        
        return mockEntries.filter { $0.beltLevel.id == beltLevel.id }
    }
}

// MARK: - Test Configuration

/**
 * Centralized test configuration and constants
 */
struct TestConfiguration {
    static let defaultTestTimeout: TimeInterval = 10.0
    static let performanceTestTimeout: TimeInterval = 30.0
    static let maxMemoryIncrease: Int64 = 100 * 1024 * 1024 // 100MB
    static let maxDatabaseQueryTime: TimeInterval = 2.0
    static let maxUIResponseTime: TimeInterval = 1.0
    
    // Test data sizes
    static let smallDatasetSize = 10
    static let mediumDatasetSize = 50
    static let largeDatasetSize = 200
}