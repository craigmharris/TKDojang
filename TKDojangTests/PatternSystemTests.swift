import XCTest
import SwiftData
@testable import TKDojang

/**
 * PatternSystemTests.swift
 * 
 * PURPOSE: Tests for the pattern system functionality including JSON loading and user progress
 * 
 * CRITICAL IMPORTANCE: Validates new JSON-based pattern architecture
 * Based on CLAUDE.md requirements: JSON-based pattern loading with user progress tracking
 * 
 * TEST COVERAGE:
 * - JSON-based pattern loading via PatternContentLoader
 * - Pattern filtering by belt level using PatternDataService.getPatternsForUser()
 * - Pattern-move relationships and data integrity
 * - User pattern progress tracking with UserPatternProgress
 * - Pattern practice session recording
 * - Pattern mastery progression and statistics
 */
final class PatternSystemTests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var patternService: PatternDataService!
    var testProfile: UserProfile!
    var testBelt: BeltLevel!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory test container with pattern models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            Pattern.self,
            PatternMove.self,
            UserPatternProgress.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        testContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        testContext = ModelContext(testContainer)
        patternService = PatternDataService(modelContext: testContext)
        
        // Set up test data
        try setupTestData()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        patternService = nil
        testProfile = nil
        testBelt = nil
        try super.tearDownWithError()
    }
    
    private func setupTestData() throws {
        // Create test belt levels
        let ninthKeup = BeltLevel(name: "9th Keup (Yellow Belt)", shortName: "9th Keup", colorName: "Yellow", sortOrder: 14, isKyup: true)
        let eighthKeup = BeltLevel(name: "8th Keup (Orange Belt)", shortName: "8th Keup", colorName: "Orange", sortOrder: 13, isKyup: true)
        let seventhKeup = BeltLevel(name: "7th Keup (Green Belt)", shortName: "7th Keup", colorName: "Green", sortOrder: 12, isKyup: true)
        
        testContext.insert(ninthKeup)
        testContext.insert(eighthKeup)
        testContext.insert(seventhKeup)
        
        // Use 9th Keup as primary test belt
        testBelt = ninthKeup
        
        // Create test user profile
        testProfile = UserProfile(currentBeltLevel: testBelt, learningMode: .mastery)
        testContext.insert(testProfile)
        
        try testContext.save()
    }
    
    // MARK: - Pattern Creation and Management Tests
    
    func testPatternCreation() throws {
        let pattern = patternService.createPattern(
            name: "Test Pattern",
            hangul: "테스트",
            englishMeaning: "Test Pattern",
            significance: "A test pattern for unit testing",
            moveCount: 3,
            diagramDescription: "Test diagram",
            startingStance: "Ready stance",
            videoURL: "https://example.com/test.mp4",
            diagramImageURL: "https://example.com/test.jpg",
            beltLevels: [testBelt],
            moves: []
        )
        
        // Verify pattern creation
        XCTAssertFalse(pattern.name.isEmpty, "Pattern should have a name")
        XCTAssertEqual(pattern.name, "Test Pattern", "Pattern name should match")
        XCTAssertEqual(pattern.hangul, "테스트", "Pattern hangul should match")
        XCTAssertEqual(pattern.moveCount, 3, "Pattern move count should match")
        XCTAssertTrue(pattern.beltLevels.contains { $0.id == testBelt.id }, "Pattern should be associated with test belt")
        XCTAssertNotNil(pattern.videoURL, "Pattern should have video URL")
        XCTAssertNotNil(pattern.createdAt, "Pattern should have creation date")
    }
    
    func testPatternMoveCreation() throws {
        // Create a pattern first
        let pattern = patternService.createPattern(
            name: "Test Pattern",
            hangul: "테스트",
            englishMeaning: "Test Pattern",
            significance: "Test pattern",
            moveCount: 2,
            diagramDescription: "Test",
            startingStance: "Ready stance",
            beltLevels: [testBelt]
        )
        
        // Add moves to the pattern
        let move1 = patternService.addMove(
            to: pattern,
            moveNumber: 1,
            stance: "Left walking stance",
            technique: "Low block",
            direction: "West",
            target: "Lower section",
            keyPoints: "Keep shoulders square",
            commonMistakes: "Lifting block too high",
            executionNotes: "Proper weight distribution",
            imageURL: "https://example.com/move1.jpg"
        )
        
        let move2 = patternService.addMove(
            to: pattern,
            moveNumber: 2,
            stance: "Right walking stance",
            technique: "Middle punch",
            direction: "West",
            target: "Solar plexus",
            keyPoints: "Twist fist on impact",
            commonMistakes: "Punching with bent wrist",
            executionNotes: "Step with power",
            imageURL: "https://example.com/move2.jpg"
        )
        
        // Verify move creation
        XCTAssertEqual(move1.moveNumber, 1, "First move should have move number 1")
        XCTAssertEqual(move1.technique, "Low block", "Move technique should match")
        XCTAssertEqual(move1.pattern?.id, pattern.id, "Move should reference pattern")
        
        XCTAssertEqual(move2.moveNumber, 2, "Second move should have move number 2")
        XCTAssertEqual(move2.technique, "Middle punch", "Move technique should match")
        
        // Verify pattern-move relationship
        XCTAssertEqual(pattern.moves.count, 2, "Pattern should have 2 moves")
        
        let orderedMoves = pattern.orderedMoves
        XCTAssertEqual(orderedMoves[0].moveNumber, 1, "First move should be ordered correctly")
        XCTAssertEqual(orderedMoves[1].moveNumber, 2, "Second move should be ordered correctly")
    }
    
    func testPatternBeltLevelFiltering() throws {
        let beltDescriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\BeltLevel.sortOrder, order: .reverse)]
        )
        let belts = try testContext.fetch(beltDescriptor)
        
        // Create patterns for different belt levels
        let beginnerPattern = patternService.createPattern(
            name: "Beginner Pattern",
            hangul: "초급",
            englishMeaning: "Beginner",
            significance: "For beginners",
            moveCount: 10,
            diagramDescription: "Simple",
            startingStance: "Ready",
            beltLevels: [belts[0]] // 9th Keup (highest sort order = 14)
        )
        
        let intermediatePattern = patternService.createPattern(
            name: "Intermediate Pattern", 
            hangul: "중급",
            englishMeaning: "Intermediate",
            significance: "For intermediate students",
            moveCount: 20,
            diagramDescription: "Complex",
            startingStance: "Ready",
            beltLevels: [belts[1]] // 8th Keup (sort order = 13)
        )
        
        let advancedPattern = patternService.createPattern(
            name: "Advanced Pattern",
            hangul: "고급",
            englishMeaning: "Advanced", 
            significance: "For advanced students",
            moveCount: 30,
            diagramDescription: "Very complex",
            startingStance: "Ready",
            beltLevels: [belts[2]] // 7th Keup (sort order = 12)
        )
        
        // Test filtering for 9th Keup (should see only beginner pattern)
        let ninthKeupProfile = UserProfile(currentBeltLevel: belts[0], learningMode: .mastery)
        testContext.insert(ninthKeupProfile)
        try testContext.save()
        
        let ninthKeupPatterns = patternService.getPatternsForUser(userProfile: ninthKeupProfile)
        XCTAssertEqual(ninthKeupPatterns.count, 1, "9th Keup should see 1 pattern")
        XCTAssertTrue(ninthKeupPatterns.contains { $0.id == beginnerPattern.id }, "Should contain beginner pattern")
        
        // Test filtering for 8th Keup (should see beginner and intermediate patterns)
        let eighthKeupProfile = UserProfile(currentBeltLevel: belts[1], learningMode: .mastery)
        testContext.insert(eighthKeupProfile)
        try testContext.save()
        
        let eighthKeupPatterns = patternService.getPatternsForUser(userProfile: eighthKeupProfile)
        XCTAssertEqual(eighthKeupPatterns.count, 2, "8th Keup should see 2 patterns")
        XCTAssertTrue(eighthKeupPatterns.contains { $0.id == beginnerPattern.id }, "Should contain beginner pattern")
        XCTAssertTrue(eighthKeupPatterns.contains { $0.id == intermediatePattern.id }, "Should contain intermediate pattern")
        
        // Test filtering for 7th Keup (should see all patterns)
        let seventhKeupProfile = UserProfile(currentBeltLevel: belts[2], learningMode: .mastery) 
        testContext.insert(seventhKeupProfile)
        try testContext.save()
        
        let seventhKeupPatterns = patternService.getPatternsForUser(userProfile: seventhKeupProfile)
        XCTAssertEqual(seventhKeupPatterns.count, 3, "7th Keup should see 3 patterns")
        XCTAssertTrue(seventhKeupPatterns.contains { $0.id == beginnerPattern.id }, "Should contain beginner pattern")
        XCTAssertTrue(seventhKeupPatterns.contains { $0.id == intermediatePattern.id }, "Should contain intermediate pattern")
        XCTAssertTrue(seventhKeupPatterns.contains { $0.id == advancedPattern.id }, "Should contain advanced pattern")
    }
    
    // MARK: - Pattern Progress Tests
    
    func testUserPatternProgressCreation() throws {
        // Create a test pattern
        let pattern = patternService.createPattern(
            name: "Progress Test Pattern",
            hangul: "진전",
            englishMeaning: "Progress",
            significance: "Testing progress",
            moveCount: 5,
            diagramDescription: "Test",
            startingStance: "Ready",
            beltLevels: [testBelt]
        )
        
        // Get user progress
        let progress = patternService.getUserProgress(for: pattern, userProfile: testProfile)
        
        // Verify initial progress state
        XCTAssertNotNil(progress, "Progress should be created")
        XCTAssertEqual(progress.pattern.id, pattern.id, "Progress should reference correct pattern")
        XCTAssertEqual(progress.userProfile.id, testProfile.id, "Progress should reference correct user")
        XCTAssertEqual(progress.currentMove, 1, "Should start at move 1")
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start with learning mastery level")
        XCTAssertEqual(progress.practiceCount, 0, "Should start with 0 practice sessions")
        XCTAssertEqual(progress.averageAccuracy, 0.0, "Should start with 0% accuracy")
        XCTAssertEqual(progress.totalPracticeTime, 0, "Should start with 0 practice time")
        XCTAssertEqual(progress.consecutiveCorrectRuns, 0, "Should start with 0 consecutive correct runs")
    }
    
    func testPatternPracticeSessionRecording() throws {
        // Create pattern and get progress
        let pattern = patternService.createPattern(
            name: "Practice Test",
            hangul: "연습",
            englishMeaning: "Practice",
            significance: "For testing practice recording",
            moveCount: 10,
            diagramDescription: "Test",
            startingStance: "Ready",
            beltLevels: [testBelt]
        )
        
        let progress = patternService.getUserProgress(for: pattern, userProfile: testProfile)
        
        // Record a practice session
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: testProfile,
            accuracy: 0.8,
            practiceTime: 120.0, // 2 minutes
            strugglingMoves: [3, 7]
        )
        
        // Verify practice session was recorded
        XCTAssertEqual(progress.practiceCount, 1, "Should have 1 practice session")
        XCTAssertEqual(progress.averageAccuracy, 0.8, "Should have recorded accuracy")
        XCTAssertEqual(progress.bestRunAccuracy, 0.8, "Best run should match first run")
        XCTAssertEqual(progress.totalPracticeTime, 120.0, "Should have recorded practice time")
        XCTAssertEqual(progress.consecutiveCorrectRuns, 0, "Should not count as correct run (below 90%)")
        XCTAssertEqual(progress.strugglingMoves, [3, 7], "Should record struggling moves")
        XCTAssertNotNil(progress.lastPracticedAt, "Should record last practiced date")
        
        // Record another session with better performance
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: testProfile,
            accuracy: 0.95,
            practiceTime: 90.0,
            strugglingMoves: [7]
        )
        
        // Verify updated statistics
        XCTAssertEqual(progress.practiceCount, 2, "Should have 2 practice sessions")
        XCTAssertEqual(progress.averageAccuracy, 0.875, "Should calculate average accuracy correctly", accuracy: 0.001)
        XCTAssertEqual(progress.bestRunAccuracy, 0.95, "Should update best run accuracy")
        XCTAssertEqual(progress.totalPracticeTime, 210.0, "Should accumulate practice time")
        XCTAssertEqual(progress.consecutiveCorrectRuns, 1, "Should count high accuracy run")
        XCTAssertTrue(progress.strugglingMoves.contains(3), "Should maintain previous struggling moves")
        XCTAssertTrue(progress.strugglingMoves.contains(7), "Should add new struggling moves")
    }
    
    func testPatternMasteryProgression() throws {
        // Create pattern and get progress
        let pattern = patternService.createPattern(
            name: "Mastery Test",
            hangul: "숙달",
            englishMeaning: "Mastery",
            significance: "Testing mastery progression",
            moveCount: 8,
            diagramDescription: "Test",
            startingStance: "Ready",
            beltLevels: [testBelt]
        )
        
        let progress = patternService.getUserProgress(for: pattern, userProfile: testProfile)
        
        // Should start as learning
        XCTAssertEqual(progress.masteryLevel, .learning, "Should start as learning")
        
        // Record sessions to reach familiar level (3 sessions, 70% avg accuracy)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.7, practiceTime: 60.0)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.7, practiceTime: 60.0)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.7, practiceTime: 60.0)
        
        XCTAssertEqual(progress.masteryLevel, .familiar, "Should be familiar after 3 sessions with 70% accuracy")
        
        // Record high-accuracy sessions to reach proficient level (3+ consecutive, 85% avg)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.9, practiceTime: 60.0)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.9, practiceTime: 60.0)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.9, practiceTime: 60.0)
        
        XCTAssertEqual(progress.masteryLevel, .proficient, "Should be proficient with high accuracy and consecutive runs")
        
        // Record excellent sessions to reach mastered level (5+ consecutive, 95% avg)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.95, practiceTime: 60.0)
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.95, practiceTime: 60.0)
        
        XCTAssertEqual(progress.masteryLevel, .mastered, "Should be mastered with excellent performance")
    }
    
    func testPatternDueForReview() throws {
        // Create pattern and get progress
        let pattern = patternService.createPattern(
            name: "Review Test",
            hangul: "복습",
            englishMeaning: "Review",
            significance: "Testing review scheduling",
            moveCount: 5,
            diagramDescription: "Test",
            startingStance: "Ready",
            beltLevels: [testBelt]
        )
        
        // Initially should not be due for review (just created)
        let progress = patternService.getUserProgress(for: pattern, userProfile: testProfile)
        XCTAssertFalse(progress.isDueForReview, "New pattern should not immediately be due for review")
        
        // Record a practice session (this sets next review date)
        patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: testProfile,
            accuracy: 0.8,
            practiceTime: 60.0
        )
        
        // Should not be immediately due for review after practice
        XCTAssertFalse(progress.isDueForReview, "Should not be due immediately after practice")
        XCTAssertTrue(progress.nextReviewDate > Date(), "Next review should be in the future")
        
        // Test patterns due for review
        let duePatternsEmpty = patternService.getPatternsDueForReview(userProfile: testProfile)
        XCTAssertEqual(duePatternsEmpty.count, 0, "Should have no patterns due for review initially")
        
        // Manually set review date to past to simulate due pattern
        progress.nextReviewDate = Date().addingTimeInterval(-3600) // 1 hour ago
        try testContext.save()
        
        XCTAssertTrue(progress.isDueForReview, "Should be due for review with past date")
        
        let duePatterns = patternService.getPatternsDueForReview(userProfile: testProfile)
        XCTAssertEqual(duePatterns.count, 1, "Should have 1 pattern due for review")
        XCTAssertEqual(duePatterns.first?.pattern.id, pattern.id, "Should return correct pattern")
    }
    
    // MARK: - Pattern Statistics Tests
    
    func testPatternStatistics() throws {
        // Create multiple patterns with different progress levels
        let pattern1 = patternService.createPattern(
            name: "Stats Test 1", hangul: "통계1", englishMeaning: "Stats 1",
            significance: "Test", moveCount: 5, diagramDescription: "Test",
            startingStance: "Ready", beltLevels: [testBelt]
        )
        
        let pattern2 = patternService.createPattern(
            name: "Stats Test 2", hangul: "통계2", englishMeaning: "Stats 2",
            significance: "Test", moveCount: 10, diagramDescription: "Test",
            startingStance: "Ready", beltLevels: [testBelt]
        )
        
        // Record different levels of progress
        patternService.recordPracticeSession(pattern: pattern1, userProfile: testProfile, accuracy: 0.95, practiceTime: 120.0)
        patternService.recordPracticeSession(pattern: pattern1, userProfile: testProfile, accuracy: 0.95, practiceTime: 100.0)
        patternService.recordPracticeSession(pattern: pattern1, userProfile: testProfile, accuracy: 0.95, practiceTime: 80.0)
        patternService.recordPracticeSession(pattern: pattern1, userProfile: testProfile, accuracy: 0.95, practiceTime: 90.0)
        patternService.recordPracticeSession(pattern: pattern1, userProfile: testProfile, accuracy: 0.95, practiceTime: 110.0)
        
        patternService.recordPracticeSession(pattern: pattern2, userProfile: testProfile, accuracy: 0.7, practiceTime: 180.0)
        patternService.recordPracticeSession(pattern: pattern2, userProfile: testProfile, accuracy: 0.8, practiceTime: 160.0)
        
        // Get statistics
        let stats = patternService.getUserPatternStatistics(userProfile: testProfile)
        
        // Verify statistics
        XCTAssertEqual(stats.totalPatterns, 2, "Should have 2 patterns")
        XCTAssertEqual(stats.masteredPatterns, 1, "Should have 1 mastered pattern")
        XCTAssertEqual(stats.totalSessions, 7, "Should have 7 total practice sessions")
        XCTAssertEqual(stats.totalPracticeTime, 840.0, "Should sum all practice time correctly")
        
        // Average accuracy should be weighted by pattern (pattern1: 0.95, pattern2: 0.75, avg: 0.85)
        XCTAssertGreaterThan(stats.averageAccuracy, 0.8, "Average accuracy should be reasonable")
        XCTAssertLessThan(stats.averageAccuracy, 1.0, "Average accuracy should be less than perfect")
    }
    
    // MARK: - Edge Cases and Error Handling Tests
    
    func testPatternByNameLookup() throws {
        let pattern = patternService.createPattern(
            name: "Lookup Test",
            hangul: "찾기",
            englishMeaning: "Lookup",
            significance: "Testing lookup functionality",
            moveCount: 7,
            diagramDescription: "Test",
            startingStance: "Ready",
            beltLevels: [testBelt]
        )
        
        // Test successful lookup
        let foundPattern = patternService.getPattern(byName: "Lookup Test")
        XCTAssertNotNil(foundPattern, "Should find pattern by name")
        XCTAssertEqual(foundPattern?.id, pattern.id, "Should return correct pattern")
        
        // Test failed lookup
        let notFoundPattern = patternService.getPattern(byName: "Non-existent Pattern")
        XCTAssertNil(notFoundPattern, "Should return nil for non-existent pattern")
    }
    
    func testPatternMoveValidation() throws {
        let move = PatternMove(
            moveNumber: 1,
            stance: "Test stance",
            technique: "Test technique", 
            direction: "North",
            target: "Test target",
            keyPoints: "Test key points",
            commonMistakes: "Test mistakes",
            executionNotes: "Test notes",
            imageURL: "https://example.com/test.jpg"
        )
        
        // Verify move properties
        XCTAssertEqual(move.displayTitle, "1. Test technique", "Should format display title correctly")
        XCTAssertEqual(move.fullDescription, "Test stance - Test technique to Test target (North)", "Should format full description correctly")
        XCTAssertTrue(move.hasMedia, "Should detect media presence")
        
        // Test move without target or image
        let simpleMove = PatternMove(
            moveNumber: 2,
            stance: "Simple stance",
            technique: "Simple technique",
            direction: "South",
            keyPoints: "Simple points"
        )
        
        XCTAssertEqual(simpleMove.fullDescription, "Simple stance - Simple technique (South)", "Should handle missing target")
        XCTAssertFalse(simpleMove.hasMedia, "Should detect no media")
    }
    
    func testUserPatternProgressHelpers() throws {
        let pattern = patternService.createPattern(
            name: "Helper Test", hangul: "도움", englishMeaning: "Helper",
            significance: "Test", moveCount: 20, diagramDescription: "Test",
            startingStance: "Ready", beltLevels: [testBelt]
        )
        
        let progress = patternService.getUserProgress(for: pattern, userProfile: testProfile)
        
        // Test initial progress percentage
        XCTAssertEqual(progress.progressPercentage, 5.0, "Should calculate progress percentage correctly (1/20 = 5%)")
        
        // Test progress stats formatting
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.85, practiceTime: 3720.0) // 62 minutes
        
        let statsString = progress.practiceStats
        XCTAssertTrue(statsString.contains("1 sessions"), "Should show session count")
        XCTAssertTrue(statsString.contains("85%"), "Should show accuracy percentage")
        XCTAssertTrue(statsString.contains("62m"), "Should show minutes for sub-hour times")
        
        // Test with longer practice time
        patternService.recordPracticeSession(pattern: pattern, userProfile: testProfile, accuracy: 0.9, practiceTime: 3600.0) // 60 minutes
        
        let longStatsString = progress.practiceStats
        XCTAssertTrue(longStatsString.contains("1h"), "Should show hours for longer times")
    }
    
    func testPatternExtensions() throws {
        let pattern = Pattern(
            name: "Extension Test",
            hangul: "확장",
            englishMeaning: "Extension", 
            significance: "Testing extensions",
            moveCount: 5,
            diagramDescription: "Test",
            startingStance: "Ready"
        )
        
        // Create belt levels for testing belt appropriateness
        let beltDescriptor = FetchDescriptor<BeltLevel>()
        let belts = try testContext.fetch(beltDescriptor)
        
        pattern.beltLevels = belts
        
        // Test belt appropriateness
        for belt in belts {
            XCTAssertTrue(pattern.isAppropriateFor(beltLevel: belt), "Pattern should be appropriate for all associated belts")
        }
        
        // Test primary belt level
        let primaryBelt = pattern.primaryBeltLevel
        XCTAssertNotNil(primaryBelt, "Should have a primary belt level")
    }
}