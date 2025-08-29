import XCTest
import SwiftData
@testable import TKDojang

/**
 * EnhancedFlashcardSystemTests.swift
 * 
 * PURPOSE: Tests for the enhanced flashcard system features
 * 
 * FOCUSES ON:
 * - Enhanced terminology service
 * - Progression vs Mastery mode term selection
 * - Card repetition and both directions functionality
 * - User profile dailyStudyGoal integration
 * - Flashcard configuration system
 */
final class EnhancedFlashcardSystemTests: XCTestCase {
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var testProfile: UserProfile!
    var testBelts: [BeltLevel] = []
    var testCategory: TerminologyCategory!
    var testTerms: [TerminologyEntry] = []
    var terminologyService: TerminologyDataService!
    var leitnerService: LeitnerService!
    var enhancedService: EnhancedTerminologyService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory test container
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
        
        testContainer = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        testContext = ModelContext(testContainer)
        
        // Create services
        terminologyService = TerminologyDataService(modelContext: testContext)
        leitnerService = LeitnerService(modelContext: testContext)
        enhancedService = EnhancedTerminologyService(
            terminologyService: terminologyService,
            leitnerService: leitnerService
        )
        
        // Set up test data
        setupTestData()
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        testProfile = nil
        testBelts = []
        testCategory = nil
        testTerms = []
        terminologyService = nil
        leitnerService = nil
        enhancedService = nil
        try super.tearDownWithError()
    }
    
    private func setupTestData() {
        // Create test belts (reverse order for sort)
        let beltConfigs = [
            ("8th Keup", "Yellow", 13),
            ("7th Keup", "Yellow/Green", 12),
            ("6th Keup", "Green", 11)
        ]
        
        for (name, color, sortOrder) in beltConfigs {
            let belt = BeltLevel(name: "\(name) Belt", shortName: name, colorName: color, sortOrder: sortOrder, isKyup: true)
            testContext.insert(belt)
            testBelts.append(belt)
        }
        
        // Create test category
        testCategory = TerminologyCategory(name: "basics", displayName: "Basic Commands", sortOrder: 1)
        testContext.insert(testCategory)
        
        // Create terms for each belt (3 terms per belt)
        for (index, belt) in testBelts.enumerated() {
            for termIndex in 1...3 {
                let term = TerminologyEntry(
                    englishTerm: "\(belt.shortName) Term \(termIndex)",
                    koreanHangul: "한국어 \(index)-\(termIndex)",
                    romanizedPronunciation: "hangugeo \(index)-\(termIndex)",
                    beltLevel: belt,
                    category: testCategory,
                    difficulty: termIndex
                )
                testContext.insert(term)
                testTerms.append(term)
            }
        }
        
        // Create test profile with 7th Keup (middle belt)
        testProfile = UserProfile(
            name: "Test Enhanced User",
            currentBeltLevel: testBelts[1], // 7th Keup
            learningMode: .progression
        )
        testProfile.dailyStudyGoal = 5 // Custom study goal
        testContext.insert(testProfile)
        
        do {
            try testContext.save()
        } catch {
            XCTFail("Failed to save test data: \(error)")
        }
    }
    
    // MARK: - Enhanced Service Tests
    
    func testProgressionModeTermSelection() throws {
        // Set profile to progression mode
        testProfile.learningMode = .progression
        
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: testProfile,
            requestedCount: 10,
            learningSystem: .classic
        )
        
        // Should only get terms from current belt (7th Keup)
        XCTAssertEqual(terms.count, 3, "Should get 3 terms from current belt")
        
        for term in terms {
            XCTAssertEqual(term.beltLevel.shortName, "7th Keup", "All terms should be from current belt")
        }
    }
    
    func testMasteryModeTermSelection() throws {
        // Set profile to mastery mode
        testProfile.learningMode = .mastery
        
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: testProfile,
            requestedCount: 10,
            learningSystem: .classic
        )
        
        // Should get terms from current and prior belts (7th and 8th Keup)
        XCTAssertEqual(terms.count, 6, "Should get 6 terms from current and prior belts")
        
        let beltNames = Set(terms.map { $0.beltLevel.shortName })
        XCTAssert(beltNames.contains("7th Keup"), "Should include current belt terms")
        XCTAssert(beltNames.contains("8th Keup"), "Should include prior belt terms")
        XCTAssertFalse(beltNames.contains("6th Keup"), "Should not include future belt terms")
    }
    
    func testMasteryModeTermLimit() throws {
        // Create profile with early belt to get more terms
        let earlyBelt = BeltLevel(name: "10th Keup", shortName: "10th Keup", colorName: "White", sortOrder: 15, isKyup: true)
        testContext.insert(earlyBelt)
        
        let earlyProfile = UserProfile(name: "Early User", currentBeltLevel: earlyBelt, learningMode: .mastery)
        testContext.insert(earlyProfile)
        
        // Add many more terms to test the limit
        for i in 1...60 {
            let term = TerminologyEntry(
                englishTerm: "Many Term \(i)",
                koreanHangul: "많은 \(i)",
                romanizedPronunciation: "maneun \(i)",
                beltLevel: earlyBelt,
                category: testCategory,
                difficulty: 1
            )
            testContext.insert(term)
        }
        
        try testContext.save()
        
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: earlyProfile,
            requestedCount: 60,
            learningSystem: .classic
        )
        
        // Should be limited to 50 terms in mastery mode
        XCTAssertEqual(terms.count, 50, "Mastery mode should limit to 50 terms")
    }
    
    func testUserProfileStudyGoalIntegration() throws {
        // Test that dailyStudyGoal is used as default
        XCTAssertEqual(testProfile.dailyStudyGoal, 5, "Profile should have custom study goal")
        
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: testProfile,
            requestedCount: testProfile.dailyStudyGoal,
            learningSystem: .classic
        )
        
        // Should respect the requested count (even if less than available)
        XCTAssertLessThanOrEqual(terms.count, testProfile.dailyStudyGoal, "Should respect study goal limit")
    }
    
    // MARK: - Card Direction Tests
    
    func testFlashcardItemCreation() throws {
        let terms = Array(testTerms.prefix(2)) // Use 2 terms
        
        let items = enhancedService.createRepeatedCardsForBothDirections(
            terms: terms,
            targetCount: 6
        )
        
        XCTAssertEqual(items.count, 6, "Should create exactly 6 flashcard items")
        
        // Count direction distribution
        let englishToKorean = items.filter { $0.direction == .englishToKorean }.count
        let koreanToEnglish = items.filter { $0.direction == .koreanToEnglish }.count
        
        XCTAssert(englishToKorean > 0, "Should have English to Korean cards")
        XCTAssert(koreanToEnglish > 0, "Should have Korean to English cards")
        XCTAssertEqual(englishToKorean + koreanToEnglish, 6, "All cards should have valid directions")
    }
    
    func testCardRepetitionWhenInsufficientTerms() throws {
        // Use only 1 term but request 4 cards
        let singleTerm = [testTerms[0]]
        
        let items = enhancedService.createRepeatedCardsForBothDirections(
            terms: singleTerm,
            targetCount: 4
        )
        
        XCTAssertEqual(items.count, 4, "Should create 4 items from 1 term")
        
        // All items should use the same term
        for item in items {
            XCTAssertEqual(item.term.id, singleTerm[0].id, "All items should use the same term")
        }
    }
    
    // MARK: - Flashcard Configuration Tests
    
    func testFlashcardConfigurationInitialization() throws {
        let config = FlashcardConfiguration(
            studyMode: .test,
            cardDirection: .bothDirections,
            numberOfTerms: 20,
            learningSystem: .leitner
        )
        
        XCTAssertEqual(config.studyMode, .test, "Should initialize with correct study mode")
        XCTAssertEqual(config.cardDirection, .bothDirections, "Should initialize with correct direction")
        XCTAssertEqual(config.numberOfTerms, 20, "Should initialize with correct term count")
        XCTAssertEqual(config.learningSystem, .leitner, "Should initialize with correct learning system")
    }
    
    func testLearningSystemConversion() throws {
        XCTAssertTrue(LearningSystem.leitner.isLeitnerMode, "Leitner system should be Leitner mode")
        XCTAssertFalse(LearningSystem.classic.isLeitnerMode, "Classic system should not be Leitner mode")
        XCTAssertTrue(LearningSystem.classic.isClassicMode, "Classic system should be classic mode")
        XCTAssertFalse(LearningSystem.leitner.isClassicMode, "Leitner system should not be classic mode")
    }
    
    // MARK: - Integration Tests
    
    func testFullFlashcardSessionFlow() throws {
        // Simulate complete flashcard session setup
        testProfile.learningMode = .mastery
        testProfile.dailyStudyGoal = 4
        
        // Get terms using enhanced service
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: testProfile,
            requestedCount: testProfile.dailyStudyGoal,
            learningSystem: .classic
        )
        
        // Create flashcard items for both directions
        let items = enhancedService.createRepeatedCardsForBothDirections(
            terms: terms,
            targetCount: testProfile.dailyStudyGoal
        )
        
        XCTAssertEqual(items.count, testProfile.dailyStudyGoal, "Should create requested number of items")
        XCTAssertGreaterThan(terms.count, 0, "Should have terms available")
        
        // Verify items have both directions
        let directions = Set(items.map { $0.direction })
        XCTAssert(directions.count >= 1, "Should have at least one direction")
    }
    
    func testProgressionModeWithInsufficientTerms() throws {
        // Create a belt with only 1 term
        let sparseBelt = BeltLevel(name: "Sparse Belt", shortName: "Sparse", colorName: "Test", sortOrder: 10, isKyup: true)
        testContext.insert(sparseBelt)
        
        let sparseTerm = TerminologyEntry(
            englishTerm: "Only Term",
            koreanHangul: "유일한",
            romanizedPronunciation: "yuilhan",
            beltLevel: sparseBelt,
            category: testCategory,
            difficulty: 1
        )
        testContext.insert(sparseTerm)
        
        let sparseProfile = UserProfile(name: "Sparse User", currentBeltLevel: sparseBelt, learningMode: .progression)
        testContext.insert(sparseProfile)
        
        try testContext.save()
        
        // Request more terms than available
        let terms = enhancedService.getTermsForFlashcardSession(
            userProfile: sparseProfile,
            requestedCount: 5,
            learningSystem: .classic
        )
        
        // Should get the 1 available term
        XCTAssertEqual(terms.count, 1, "Should get the available term")
        
        // But flashcard items can be repeated in both directions
        let items = enhancedService.createRepeatedCardsForBothDirections(
            terms: terms,
            targetCount: 5
        )
        
        XCTAssertEqual(items.count, 5, "Should create 5 items through repetition")
    }
    
    // MARK: - Performance Tests
    
    func testTermSelectionPerformance() throws {
        measure {
            _ = enhancedService.getTermsForFlashcardSession(
                userProfile: testProfile,
                requestedCount: 20,
                learningSystem: .classic
            )
        }
    }
    
    func testFlashcardItemCreationPerformance() throws {
        let terms = Array(testTerms.prefix(5))
        
        measure {
            _ = enhancedService.createRepeatedCardsForBothDirections(
                terms: terms,
                targetCount: 20
            )
        }
    }
}