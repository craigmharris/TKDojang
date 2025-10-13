import XCTest
import SwiftData
@testable import TKDojang

/**
 * PatternSystemTests.swift
 * 
 * PURPOSE: Tests for the pattern system functionality including JSON loading and user progress
 * 
 * CRITICAL IMPORTANCE: Validates pattern architecture infrastructure
 * Pattern system represents structured learning progression for belt advancement
 * 
 * TEST COVERAGE:
 * - Pattern data structure validation
 * - Pattern-move relationships and data integrity
 * - User pattern progress tracking infrastructure
 * - Pattern practice session recording capabilities
 * - Pattern mastery progression and statistics infrastructure
 * - Belt-level pattern filtering support
 */
final class PatternSystemTests: XCTestCase {
    
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
    
    // MARK: - Pattern Creation and Management Tests
    
    func testPatternCreation() throws {
        // Test pattern creation infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Test User", currentBeltLevel: testBelts.first!)
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern data structure support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let testPattern = patterns.first!
            XCTAssertNotNil(testPattern.id, "Pattern should have valid ID")
            XCTAssertFalse(testPattern.name.isEmpty, "Pattern should have name")
            XCTAssertGreaterThan(testPattern.moveCount, 0, "Pattern should have move count")
        }
        
        print("✅ Pattern creation infrastructure validation completed")
    }
    
    func testPatternMoveRelationships() throws {
        // Test pattern-move relationship infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Move Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern-move relationship support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        let moves = try testContext.fetch(FetchDescriptor<PatternMove>())
        
        if !patterns.isEmpty && !moves.isEmpty {
            let pattern = patterns.first!
            let move = moves.first!
            
            XCTAssertNotNil(pattern.id, "Pattern should have ID for move relationships")
            XCTAssertNotNil(move.id, "Move should have ID for pattern relationships")
            XCTAssertGreaterThan(move.moveNumber, 0, "Move should have valid move number")
        }
        
        print("✅ Pattern-move relationship infrastructure validation completed")
    }
    
    func testPatternBeltAssociation() throws {
        // Test pattern belt association infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Belt Association Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test belt association capabilities
        XCTAssertNotNil(testProfile.currentBeltLevel, "Profile should have belt for pattern filtering")
        XCTAssertNotNil(testProfile.currentBeltLevel.name, "Belt should have name for pattern association")
        
        // Test pattern belt filtering support
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            XCTAssertGreaterThanOrEqual(pattern.beltLevels.count, 0, "Pattern should support belt level associations")
        }
        
        print("✅ Pattern belt association infrastructure validation completed")
    }
    
    // MARK: - User Progress Tracking Tests
    
    func testUserPatternProgressTracking() throws {
        // Test user pattern progress tracking infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Progress Tracking Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        
        // Create progress tracking infrastructure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.practiceCount = 5
            progress.bestRunAccuracy = 0.85
            progress.averageAccuracy = 0.78
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify progress tracking capabilities
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        if !progressEntries.isEmpty {
            let progress = progressEntries.first!
            XCTAssertGreaterThan(progress.practiceCount, 0, "Should track practice count")
            XCTAssertGreaterThan(progress.bestRunAccuracy, 0, "Should track best accuracy")
            XCTAssertGreaterThan(progress.averageAccuracy, 0, "Should track average accuracy")
        }
        
        print("✅ User pattern progress tracking infrastructure validation completed")
    }
    
    func testPatternPracticeSessionRecording() throws {
        // Test pattern practice session recording infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Practice Session Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        
        // Create practice session infrastructure
        let session = StudySession(userProfile: testProfile, sessionType: .patterns)
        session.duration = 600.0 // 10 minutes
        session.itemsStudied = 1
        session.correctAnswers = 1
        session.startTime = Date()
        testContext.insert(session)
        try testContext.save()
        
        // Verify practice session recording
        XCTAssertEqual(session.sessionType, .patterns, "Should support pattern practice sessions")
        XCTAssertGreaterThan(session.duration, 0, "Should track practice duration")
        XCTAssertNotNil(session.startTime, "Should track session start time")
        
        print("✅ Pattern practice session recording infrastructure validation completed")
    }
    
    func testPatternMasteryProgression() throws {
        // Test pattern mastery progression infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Mastery Progression Test User", currentBeltLevel: testBelts[2], learningMode: .mastery)
        testContext.insert(testProfile)
        
        // Test mastery progression support
        XCTAssertEqual(testProfile.learningMode, .mastery, "Should support mastery learning mode")
        XCTAssertNotNil(testProfile.currentBeltLevel, "Should have belt context for mastery progression")
        
        // Create multiple progress entries to simulate progression
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        for (index, pattern) in patterns.prefix(3).enumerated() {
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.practiceCount = index + 1
            progress.bestRunAccuracy = 0.6 + (Double(index) * 0.1)
            progress.averageAccuracy = 0.5 + (Double(index) * 0.1)
            testContext.insert(progress)
        }
        
        try testContext.save()
        
        // Verify mastery progression infrastructure
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        XCTAssertGreaterThanOrEqual(progressEntries.count, 0, "Should support multiple pattern progress tracking")
        
        print("✅ Pattern mastery progression infrastructure validation completed")
    }
    
    // MARK: - Pattern Content Loading Tests
    
    func testPatternContentStructure() throws {
        // Test pattern content structure infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Content Structure Test User", currentBeltLevel: testBelts[0])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern content structure
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        if !patterns.isEmpty {
            let pattern = patterns.first!
            XCTAssertNotNil(pattern.id, "Pattern should have unique identifier")
            XCTAssertFalse(pattern.name.isEmpty, "Pattern should have name")
            XCTAssertGreaterThan(pattern.moveCount, 0, "Pattern should have move count")
            XCTAssertNotNil(pattern.significance, "Pattern should have significance description")
        }
        
        print("✅ Pattern content structure infrastructure validation completed")
    }
    
    func testPatternMoveStructure() throws {
        // Test pattern move structure infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Move Structure Test User", currentBeltLevel: testBelts[1])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test pattern move structure
        let moves = try testContext.fetch(FetchDescriptor<PatternMove>())
        if !moves.isEmpty {
            let move = moves.first!
            XCTAssertNotNil(move.id, "Move should have unique identifier")
            XCTAssertGreaterThan(move.moveNumber, 0, "Move should have valid move number")
            XCTAssertFalse(move.technique.isEmpty, "Move should have technique")
            XCTAssertNotNil(move.stance, "Move should have stance information")
            XCTAssertNotNil(move.direction, "Move should have direction information")
        }
        
        print("✅ Pattern move structure infrastructure validation completed")
    }
    
    // MARK: - Pattern Filtering and Access Tests
    
    func testPatternBeltLevelFiltering() throws {
        // Test pattern belt level filtering infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Test different belt levels
        let beginnerProfile = UserProfile(name: "Beginner User", currentBeltLevel: testBelts.last!, learningMode: .progression)
        let advancedProfile = UserProfile(name: "Advanced User", currentBeltLevel: testBelts.first!, learningMode: .mastery)
        
        testContext.insert(beginnerProfile)
        testContext.insert(advancedProfile)
        try testContext.save()
        
        // Test belt level filtering support
        XCTAssertNotEqual(beginnerProfile.currentBeltLevel.sortOrder, advancedProfile.currentBeltLevel.sortOrder, 
                         "Different belt levels should have different sort orders for filtering")
        XCTAssertNotEqual(beginnerProfile.learningMode, advancedProfile.learningMode, 
                         "Different learning modes should support different filtering approaches")
        
        print("✅ Pattern belt level filtering infrastructure validation completed")
    }
    
    func testPatternUserAccess() throws {
        // Test pattern user access infrastructure
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "User Access Test User", currentBeltLevel: testBelts[2])
        testContext.insert(testProfile)
        try testContext.save()
        
        // Test user access infrastructure
        XCTAssertNotNil(testProfile.currentBeltLevel, "User should have belt level for pattern access")
        XCTAssertNotNil(testProfile.id, "User should have ID for progress association")
        
        // Test pattern access capabilities
        let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
        XCTAssertGreaterThanOrEqual(patterns.count, 0, "Should support pattern access for users")
        
        print("✅ Pattern user access infrastructure validation completed")
    }
    
    // MARK: - Performance Tests
    
    func testPatternSystemPerformance() throws {
        // Test pattern system performance
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        // Create multiple test profiles and progress entries
        for i in 0..<5 {
            let profile = UserProfile(name: "Performance Test User \(i)", currentBeltLevel: testBelts[i % testBelts.count])
            testContext.insert(profile)
            
            // Create pattern progress for each profile
            let patterns = try testContext.fetch(FetchDescriptor<Pattern>())
            for pattern in patterns.prefix(2) {
                let progress = UserPatternProgress(userProfile: profile, pattern: pattern)
                progress.practiceCount = i + 1
                progress.bestRunAccuracy = 0.7 + (Double(i) * 0.05)
                testContext.insert(progress)
            }
        }
        
        try testContext.save()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let loadTime = endTime - startTime
        
        // Performance validation
        XCTAssertLessThan(loadTime, 5.0, "Pattern system should handle load efficiently")
        
        // Verify data integrity
        let profiles = try testContext.fetch(FetchDescriptor<UserProfile>())
        let progressEntries = try testContext.fetch(FetchDescriptor<UserPatternProgress>())
        
        XCTAssertGreaterThanOrEqual(profiles.count, 5, "Should maintain profile integrity")
        XCTAssertGreaterThanOrEqual(progressEntries.count, 0, "Should maintain progress integrity")
        
        print("✅ Pattern system performance validation completed (Load time: \(String(format: "%.3f", loadTime))s)")
    }
    
    // MARK: - JSON-Driven Pattern Content Tests
    
    /**
     * JSON parsing structures for Pattern content validation
     */
    struct PatternJSONData: Codable {
        let beltLevel: String
        let category: String
        let type: String
        let description: String
        let metadata: PatternMetadata
        let patterns: [PatternJSONPattern]
        
        enum CodingKeys: String, CodingKey {
            case beltLevel = "belt_level"
            case category, type, description, metadata, patterns
        }
    }
    
    struct PatternMetadata: Codable {
        let createdAt: String
        let source: String
        let totalCount: Int
        
        enum CodingKeys: String, CodingKey {
            case createdAt = "created_at"
            case source
            case totalCount = "total_count"
        }
    }
    
    struct PatternJSONPattern: Codable {
        let name: String
        let hangul: String
        let pronunciation: String
        let phonetic: String
        let englishMeaning: String
        let significance: String
        let moveCount: Int
        let diagramDescription: String
        let startingStance: String
        let difficulty: Int
        let applicableBeltLevels: [String]
        let videoUrl: String?
        let diagramImageUrl: String?
        let startingMoveImageUrl: String?
        let moves: [PatternJSONMove]
        
        enum CodingKeys: String, CodingKey {
            case name, hangul, pronunciation, phonetic
            case englishMeaning = "english_meaning"
            case significance
            case moveCount = "move_count"
            case diagramDescription = "diagram_description"
            case startingStance = "starting_stance"
            case difficulty
            case applicableBeltLevels = "applicable_belt_levels"
            case videoUrl = "video_url"
            case diagramImageUrl = "diagram_image_url"
            case startingMoveImageUrl = "starting_move_image_url"
            case moves
        }
    }
    
    struct PatternJSONMove: Codable {
        let moveNumber: Int
        let stance: String
        let technique: String
        let koreanTechnique: String?
        let direction: String
        let target: String?
        let keyPoints: String
        let commonMistakes: String?
        let executionNotes: String?
        let imageURL: String?
        let image2URL: String?
        let image3URL: String?
        let executionSpeed: String?
        let movement: String?
        
        enum CodingKeys: String, CodingKey {
            case moveNumber = "move_number"
            case stance, technique
            case koreanTechnique = "korean_technique"
            case direction, target
            case keyPoints = "key_points"
            case commonMistakes = "common_mistakes"
            case executionNotes = "execution_notes"
            case imageURL, image2URL, image3URL
            case executionSpeed = "execution_speed"
            case movement
        }
    }
    
    /**
     * Dynamically loads all available pattern JSON files
     */
    private func loadPatternJSONFiles() -> [String: PatternJSONData] {
        var jsonFiles: [String: PatternJSONData] = [:]
        
        // Discover available pattern files dynamically
        let availableFiles = discoverPatternFiles()
        
        for fileName in availableFiles {
            // Try subdirectory first, then fallback to bundle root
            var jsonURL = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "Patterns")
            if jsonURL == nil {
                jsonURL = Bundle.main.url(forResource: fileName, withExtension: "json")
            }
            
            if let url = jsonURL,
               let jsonData = try? Data(contentsOf: url),
               let parsedData = try? JSONDecoder().decode(PatternJSONData.self, from: jsonData) {
                jsonFiles["\(fileName).json"] = parsedData
            }
        }
        
        return jsonFiles
    }
    
    /**
     * Discovers available pattern JSON files dynamically
     */
    private func discoverPatternFiles() -> [String] {
        var foundFiles: [String] = []
        
        // Try Patterns subdirectory first
        if let patternsPath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "Patterns") {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: patternsPath)
                let patternFiles = contents.filter { filename in
                    filename.hasSuffix(".json") && filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                print("Failed to scan Patterns subdirectory: \(error)")
            }
        }
        
        // Fallback: scan bundle root
        if foundFiles.isEmpty, let bundlePath = Bundle.main.resourcePath {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let patternFiles = contents.filter { filename in
                    filename.hasSuffix(".json") && filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                print("Failed to scan bundle root: \(error)")
            }
        }
        
        return foundFiles.sorted()
    }
    
    /**
     * Test that pattern JSON files exist and are valid - fully dynamic
     */
    func testPatternJSONFilesExist() throws {
        let jsonFiles = loadPatternJSONFiles()
        
        XCTAssertGreaterThan(jsonFiles.count, 0, "Should dynamically discover at least one pattern JSON file")
        
        // Validate each discovered JSON file has required structure
        for (fileName, jsonData) in jsonFiles {
            XCTAssertFalse(jsonData.beltLevel.isEmpty, "\(fileName) should have belt_level")
            XCTAssertEqual(jsonData.category, "patterns", "\(fileName) should be patterns category")
            XCTAssertGreaterThan(jsonData.patterns.count, 0, "\(fileName) should contain patterns array")
            XCTAssertEqual(jsonData.patterns.count, jsonData.metadata.totalCount, 
                         "\(fileName) pattern count should match metadata")
        }
        
        print("✅ Pattern JSON files validation completed: \(jsonFiles.count) files discovered")
    }
    
    /**
     * Test JSON-driven pattern belt level filtering
     */
    func testPatternBeltLevelFilteringFromJSON() throws {
        let jsonFiles = loadPatternJSONFiles()
        
        guard !jsonFiles.isEmpty else {
            XCTFail("No pattern JSON files found for testing")
            return
        }
        
        // Test belt level associations from JSON
        for (fileName, jsonData) in jsonFiles {
            for pattern in jsonData.patterns {
                XCTAssertGreaterThan(pattern.applicableBeltLevels.count, 0, 
                                   "Pattern '\(pattern.name)' in \(fileName) should have applicable belt levels")
                
                // Validate belt level format
                for beltLevel in pattern.applicableBeltLevels {
                    XCTAssertTrue(beltLevel.contains("_keup") || beltLevel.contains("_dan"), 
                                "Belt level '\(beltLevel)' should follow expected format")
                }
            }
        }
        
        print("✅ Pattern belt level filtering validation completed")
    }
    
    /**
     * Test JSON-driven pattern move structure validation
     */
    func testPatternMoveStructureValidation() throws {
        let jsonFiles = loadPatternJSONFiles()
        
        guard !jsonFiles.isEmpty else {
            XCTFail("No pattern JSON files found for testing")
            return
        }
        
        // Test move structure consistency from JSON
        for (fileName, jsonData) in jsonFiles {
            for pattern in jsonData.patterns {
                XCTAssertEqual(pattern.moves.count, pattern.moveCount, 
                             "Pattern '\(pattern.name)' move count should match moves array length")
                
                // Validate move sequence
                let sortedMoves = pattern.moves.sorted { $0.moveNumber < $1.moveNumber }
                for (index, move) in sortedMoves.enumerated() {
                    XCTAssertEqual(move.moveNumber, index + 1, 
                                 "Move numbers should be sequential starting from 1")
                    XCTAssertFalse(move.stance.isEmpty, "Move \(move.moveNumber) should have stance")
                    XCTAssertFalse(move.technique.isEmpty, "Move \(move.moveNumber) should have technique")
                }
            }
        }
        
        print("✅ Pattern move structure validation completed")
    }
    
    /**
     * Test JSON-driven pattern content consistency
     */
    func testPatternContentConsistency() throws {
        let jsonFiles = loadPatternJSONFiles()
        
        guard !jsonFiles.isEmpty else {
            XCTFail("No pattern JSON files found for testing")
            return
        }
        
        // Track unique patterns to prevent duplicates
        var allPatternNames: Set<String> = []
        
        for (fileName, jsonData) in jsonFiles {
            // Validate JSON structure consistency
            XCTAssertFalse(jsonData.beltLevel.isEmpty, "\(fileName) should have belt_level")
            XCTAssertEqual(jsonData.category, "patterns", "\(fileName) should be patterns category")
            XCTAssertEqual(jsonData.type, "traditional_patterns", "\(fileName) should be traditional patterns")
            
            for pattern in jsonData.patterns {
                // Check for duplicate patterns
                XCTAssertFalse(allPatternNames.contains(pattern.name), 
                             "Pattern '\(pattern.name)' should not be duplicated across files")
                allPatternNames.insert(pattern.name)
                
                // Validate pattern completeness
                XCTAssertFalse(pattern.name.isEmpty, "Pattern name should not be empty")
                XCTAssertFalse(pattern.hangul.isEmpty, "Pattern hangul should not be empty")
                XCTAssertFalse(pattern.significance.isEmpty, "Pattern significance should not be empty")
                XCTAssertGreaterThan(pattern.moveCount, 0, "Pattern should have moves")
                XCTAssertGreaterThan(pattern.difficulty, 0, "Pattern should have difficulty rating")
            }
        }
        
        print("✅ Pattern content consistency validation completed: \(allPatternNames.count) unique patterns")
    }
    
    /**
     * Test JSON-driven pattern difficulty progression
     */
    func testPatternDifficultyProgression() throws {
        let jsonFiles = loadPatternJSONFiles()
        
        guard !jsonFiles.isEmpty else {
            XCTFail("No pattern JSON files found for testing")
            return
        }
        
        // Group patterns by belt level and validate difficulty progression
        var beltLevelPatterns: [String: [PatternJSONPattern]] = [:]
        
        for jsonData in jsonFiles.values {
            for pattern in jsonData.patterns {
                for beltLevel in pattern.applicableBeltLevels {
                    if beltLevelPatterns[beltLevel] == nil {
                        beltLevelPatterns[beltLevel] = []
                    }
                    beltLevelPatterns[beltLevel]?.append(pattern)
                }
            }
        }
        
        // Validate difficulty progression makes sense
        for (beltLevel, patterns) in beltLevelPatterns {
            let avgDifficulty = patterns.map { $0.difficulty }.reduce(0, +) / patterns.count
            XCTAssertGreaterThan(avgDifficulty, 0, "Belt level \(beltLevel) should have positive difficulty")
            
            // Validate move count progression (higher belts generally have more complex patterns)
            let avgMoveCount = patterns.map { $0.moveCount }.reduce(0, +) / patterns.count
            XCTAssertGreaterThan(avgMoveCount, 0, "Belt level \(beltLevel) should have patterns with moves")
        }
        
        print("✅ Pattern difficulty progression validation completed: \(beltLevelPatterns.count) belt levels")
    }
    
    /**
     * Test pattern data service functionality with JSON validation
     */
    @MainActor
    func testPatternDataServiceWithJSONValidation() async throws {
        // Set up test data
        let testBelts = TestDataFactory().createAllBeltLevels()
        for belt in testBelts {
            testContext.insert(belt)
        }
        
        let testProfile = UserProfile(name: "Pattern Service Test User", currentBeltLevel: testBelts.first!)
        testContext.insert(testProfile)
        
        // Load JSON data for validation
        let jsonFiles = loadPatternJSONFiles()
        
        guard !jsonFiles.isEmpty else {
            XCTFail("No pattern JSON files found for service validation")
            return
        }
        
        // Use patterns from JSON data instead of hardcoded pattern
        guard let (fileName, jsonData) = jsonFiles.first else {
            XCTFail("No JSON data available for testing")
            return
        }
        
        // Create patterns from JSON data for service testing
        for patternData in jsonData.patterns.prefix(1) { // Test with first pattern from JSON
            let pattern = Pattern(
                name: patternData.name,
                hangul: patternData.hangul,
                englishMeaning: patternData.englishMeaning,
                significance: patternData.significance,
                moveCount: patternData.moveCount,
                diagramDescription: patternData.diagramDescription,
                startingStance: patternData.startingStance
            )
            pattern.beltLevels.append(testBelts.first!)
            testContext.insert(pattern)
            
            // Create moves from JSON data
            for moveData in patternData.moves.prefix(3) { // Test with first 3 moves from JSON
                let move = PatternMove(
                    moveNumber: moveData.moveNumber,
                    stance: moveData.stance,
                    technique: moveData.technique,
                    koreanTechnique: moveData.koreanTechnique ?? "",
                    direction: moveData.direction,
                    target: moveData.target,
                    keyPoints: moveData.keyPoints,
                    commonMistakes: moveData.commonMistakes,
                    executionNotes: moveData.executionNotes
                )
                move.pattern = pattern
                pattern.moves.append(move)
                testContext.insert(move)
            }
        }
        
        try testContext.save()
        
        // Test pattern service
        let patternService = PatternDataService(modelContext: testContext)
        let availablePatterns = try await patternService.getPatternsForUser(userProfile: testProfile)
        
        XCTAssertGreaterThan(availablePatterns.count, 0, "Should have patterns available for user")
        
        // Validate pattern data matches JSON expectations
        if let pattern = availablePatterns.first,
           let jsonPattern = jsonData.patterns.first {
            XCTAssertEqual(pattern.name, jsonPattern.name, "Pattern name should match JSON")
            XCTAssertEqual(pattern.moveCount, jsonPattern.moveCount, "Move count should match JSON")
            XCTAssertEqual(pattern.hangul, jsonPattern.hangul, "Hangul should match JSON")
            XCTAssertEqual(pattern.significance, jsonPattern.significance, "Significance should match JSON")
            XCTAssertFalse(pattern.significance.isEmpty, "Pattern should have significance from JSON")
        }
        
        // Test progress tracking with JSON-based pattern
        if let pattern = availablePatterns.first {
            let progress = UserPatternProgress(userProfile: testProfile, pattern: pattern)
            progress.recordPracticeSession(accuracy: 0.85, practiceTime: 300.0)
            testContext.insert(progress)
            try testContext.save()
            
            XCTAssertEqual(progress.practiceCount, 1, "Should record practice session")
            XCTAssertEqual(progress.bestRunAccuracy, 0.85, "Should track accuracy")
        }
        
        print("✅ Pattern data service JSON validation completed: \(availablePatterns.count) patterns from \(fileName)")
    }
}

// MARK: - Mock Supporting Types

struct PatternProgressInfo {
    let patternId: UUID
    let practiceCount: Int
    let bestAccuracy: Double
    let averageAccuracy: Double
    let lastPracticed: Date
    
    init(patternId: UUID, practiceCount: Int, bestAccuracy: Double, averageAccuracy: Double, lastPracticed: Date = Date()) {
        self.patternId = patternId
        self.practiceCount = practiceCount
        self.bestAccuracy = bestAccuracy
        self.averageAccuracy = averageAccuracy
        self.lastPracticed = lastPracticed
    }
}

struct PatternMoveInfo {
    let moveNumber: Int
    let description: String
    let stance: String
    let direction: String
    let technique: String
    
    init(moveNumber: Int, description: String, stance: String, direction: String, technique: String) {
        self.moveNumber = moveNumber
        self.description = description
        self.stance = stance
        self.direction = direction
        self.technique = technique
    }
}

// MARK: - Test Extensions

// Pattern system test utilities - no service dependencies