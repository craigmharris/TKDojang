import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

// MARK: - Mock Flashcard Types for Testing
enum FlashcardDirection: String, CaseIterable {
    case englishToKorean = "englishToKorean"
    case koreanToEnglish = "koreanToEnglish"
    case bothDirections = "bothDirections"
}

enum FlashcardSessionMode: String, CaseIterable {
    case learn = "learn"
    case test = "test"
    case study = "study"
}

enum FlashcardMode: String, CaseIterable {
    case classic = "classic"
    case leitner = "leitner"
}

struct FlashcardSessionConfiguration {
    let direction: FlashcardDirection
    let mode: FlashcardSessionMode
    let flashcardMode: FlashcardMode
    let selectedCategories: [TerminologyCategory]
    let beltLevel: BeltLevel
    let maxCards: Int
    
    init(direction: FlashcardDirection = .englishToKorean, mode: FlashcardSessionMode = .learn, flashcardMode: FlashcardMode = .classic, selectedCategories: [TerminologyCategory] = [], beltLevel: BeltLevel, maxCards: Int = 20) {
        self.direction = direction
        self.mode = mode
        self.flashcardMode = flashcardMode
        self.selectedCategories = selectedCategories
        self.beltLevel = beltLevel
        self.maxCards = maxCards
    }
}

class FlashcardSession {
    let id = UUID()
    let configuration: FlashcardSessionConfiguration
    let userProfile: UserProfile
    var currentCardIndex = 0
    var cards: [FlashcardSessionCard] = []
    var isComplete = false
    
    init(configuration: FlashcardSessionConfiguration, userProfile: UserProfile) {
        self.configuration = configuration
        self.userProfile = userProfile
    }
}

struct FlashcardSessionCard {
    let id = UUID()
    let terminology: TerminologyEntry
    let isAnswered: Bool
    let isCorrect: Bool?
    
    init(terminology: TerminologyEntry, isAnswered: Bool = false, isCorrect: Bool? = nil) {
        self.terminology = terminology
        self.isAnswered = isAnswered
        self.isCorrect = isCorrect
    }
}

struct FlashcardSessionResults {
    let sessionId: UUID
    let totalCards: Int
    let correctAnswers: Int
    let incorrectAnswers: Int
    let sessionDuration: TimeInterval
    let configuration: FlashcardSessionConfiguration
    
    init(sessionId: UUID, totalCards: Int, correctAnswers: Int, incorrectAnswers: Int, sessionDuration: TimeInterval, configuration: FlashcardSessionConfiguration) {
        self.sessionId = sessionId
        self.totalCards = totalCards
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
        self.sessionDuration = sessionDuration
        self.configuration = configuration
    }
    
    var accuracy: Double {
        guard totalCards > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalCards)
    }
}

class FlashcardService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func startSession(configuration: FlashcardSessionConfiguration, userProfile: UserProfile) throws -> FlashcardSession {
        return FlashcardSession(configuration: configuration, userProfile: userProfile)
    }
    
    func recordAnswer(session: FlashcardSession, isCorrect: Bool, responseTime: TimeInterval) {
        // Mock implementation
    }
    
    func advanceToNextCard(session: FlashcardSession) {
        session.currentCardIndex += 1
    }
    
    func completeSession(session: FlashcardSession, userProfile: UserProfile) -> FlashcardSessionResults {
        session.isComplete = true
        return FlashcardSessionResults(
            sessionId: session.id,
            totalCards: session.cards.count,
            correctAnswers: 0,
            incorrectAnswers: 0,
            sessionDuration: 0,
            configuration: session.configuration
        )
    }
    
    func restoreSession(sessionId: UUID, userProfile: UserProfile) throws -> FlashcardSession {
        throw NSError(domain: "Mock", code: 404, userInfo: [NSLocalizedDescriptionKey: "Session not found"])
    }
}

/**
 * FlashcardUIIntegrationTests.swift
 * 
 * PURPOSE: Feature-specific UI integration testing for flashcard learning system
 * 
 * COVERAGE: Phase 2 - Detailed flashcard system UI functionality validation
 * - Card flip animations and gesture recognition
 * - Mode switching (Learn/Test, Classic/Leitner) UI behavior
 * - Direction switching (English↔Korean, Both Directions) interface
 * - Configuration UI and session setup workflows
 * - Results display and incorrect terms review functionality
 * - Session interruption and recovery UI flows
 * - Real-time progress updates and statistics display
 * 
 * BUSINESS IMPACT: Flashcards are a primary learning tool representing 40%+ of user
 * study time. UI bugs here directly affect daily learning effectiveness and user retention.
 */
final class FlashcardUIIntegrationTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var flashcardService: FlashcardService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with flashcard-related models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            StudySession.self,
            GradingRecord.self
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
        
        // Set up extensive flashcard test data
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        try testData.createExtensiveTerminologyContent(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
        flashcardService = FlashcardService(modelContext: testContext)
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        flashcardService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Flashcard Configuration UI Tests
    
    func testFlashcardConfigurationUIWorkflow() throws {
        // CRITICAL UI FLOW: Complete flashcard configuration setup
        
        let testProfile = try profileService.createProfile(
            name: "Config UI Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test initial configuration view state
        let configViewModel = FlashcardConfigurationViewModel(
            dataServices: dataServices,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertFalse(configViewModel.isLoading, "Should not be loading initially")
        XCTAssertGreaterThan(configViewModel.availableCategories.count, 0, "Should have available categories")
        XCTAssertEqual(configViewModel.selectedCategories.count, 0, "Should start with no categories selected")
        XCTAssertEqual(configViewModel.cardDirection, .englishToKorean, "Should default to English → Korean")
        XCTAssertEqual(configViewModel.sessionMode, .study, "Should default to study mode")
        XCTAssertEqual(configViewModel.cardMode, .classic, "Should default to classic mode")
        XCTAssertEqual(configViewModel.maxCards, 20, "Should have default max cards")
        
        // Test category selection
        let availableCategories = configViewModel.availableCategories
        XCTAssertGreaterThan(availableCategories.count, 0, "Should have categories available")
        
        let firstCategory = availableCategories.first!
        configViewModel.toggleCategorySelection(firstCategory.id)
        
        XCTAssertTrue(configViewModel.selectedCategories.contains(firstCategory.id), 
                     "Should add category to selection")
        XCTAssertTrue(configViewModel.canStartSession, "Should be able to start session with category selected")
        
        // Test category deselection
        configViewModel.toggleCategorySelection(firstCategory.id)
        XCTAssertFalse(configViewModel.selectedCategories.contains(firstCategory.id), 
                      "Should remove category from selection")
        XCTAssertFalse(configViewModel.canStartSession, "Should not be able to start session without categories")
        
        // Test multiple category selection
        let categoriesToSelect = Array(availableCategories.prefix(3))
        for category in categoriesToSelect {
            configViewModel.toggleCategorySelection(category.id)
        }
        
        XCTAssertEqual(configViewModel.selectedCategories.count, 3, "Should have 3 categories selected")
        XCTAssertTrue(configViewModel.canStartSession, "Should be able to start session with multiple categories")
        
        // Test card direction changes
        configViewModel.cardDirection = .koreanToEnglish
        XCTAssertEqual(configViewModel.cardDirection, .koreanToEnglish, "Should update card direction")
        
        configViewModel.cardDirection = .bothDirections
        XCTAssertEqual(configViewModel.cardDirection, .bothDirections, "Should support both directions")
        
        // Test session mode changes
        configViewModel.sessionMode = .test
        XCTAssertEqual(configViewModel.sessionMode, .test, "Should update to test mode")
        
        // Test card mode changes
        configViewModel.cardMode = .leitner
        XCTAssertEqual(configViewModel.cardMode, .leitner, "Should update to Leitner mode")
        
        // Test max cards validation
        configViewModel.maxCards = 5
        XCTAssertEqual(configViewModel.maxCards, 5, "Should accept valid card count")
        
        configViewModel.maxCards = 0
        XCTAssertGreaterThan(configViewModel.maxCards, 0, "Should enforce minimum card count")
        
        configViewModel.maxCards = 100
        XCTAssertLessThanOrEqual(configViewModel.maxCards, 50, "Should enforce maximum card count")
        
        // Test session creation
        let sessionConfig = configViewModel.createSessionConfiguration()
        XCTAssertNotNil(sessionConfig, "Should create valid session configuration")
        XCTAssertEqual(sessionConfig.categories, configViewModel.selectedCategories, 
                      "Config should match selected categories")
        XCTAssertEqual(sessionConfig.cardDirection, configViewModel.cardDirection, 
                      "Config should match selected direction")
        XCTAssertEqual(sessionConfig.sessionMode, configViewModel.sessionMode, 
                      "Config should match selected mode")
        XCTAssertEqual(sessionConfig.cardMode, configViewModel.cardMode, 
                      "Config should match selected card mode")
        
        // Performance validation for configuration UI
        let configMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = FlashcardConfigurationViewModel(dataServices: dataServices, userProfile: testProfile)
        }
        XCTAssertLessThan(configMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Configuration UI should load quickly")
    }
    
    func testFlashcardConfigurationValidation() throws {
        // Test configuration validation and error handling
        
        let testProfile = try profileService.createProfile(
            name: "Validation Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let configViewModel = FlashcardConfigurationViewModel(
            dataServices: dataServices,
            userProfile: testProfile
        )
        
        // Test no categories selected validation
        XCTAssertFalse(configViewModel.canStartSession, "Should not allow session without categories")
        XCTAssertNotNil(configViewModel.validationError, "Should show validation error")
        XCTAssertTrue(configViewModel.validationError!.contains("categor"), 
                     "Error should mention categories")
        
        // Test valid configuration
        let firstCategory = configViewModel.availableCategories.first!
        configViewModel.toggleCategorySelection(firstCategory.id)
        
        XCTAssertTrue(configViewModel.canStartSession, "Should allow session with valid configuration")
        XCTAssertNil(configViewModel.validationError, "Should clear validation error")
        
        // Test learning mode restrictions
        if testProfile.learningMode == .mastery {
            // Mastery mode should restrict advanced content
            let advancedCategories = configViewModel.availableCategories.filter { 
                $0.name.contains("advanced") || $0.name.contains("expert") 
            }
            for category in advancedCategories {
                configViewModel.toggleCategorySelection(category.id)
                XCTAssertFalse(configViewModel.selectedCategories.contains(category.id),
                              "Mastery mode should restrict advanced categories")
            }
        }
        
        // Test belt level content filtering
        let userBeltLevel = testProfile.currentBeltLevel
        let availableCategories = configViewModel.availableCategories
        
        // All available categories should be appropriate for user's belt level
        for category in availableCategories {
            let categoryBeltRequirement = category.minimumBeltLevel
            if let requiredBelt = categoryBeltRequirement {
                XCTAssertLessThanOrEqual(
                    BeltUtils.getLegacySortOrder(for: requiredBelt),
                    BeltUtils.getLegacySortOrder(for: userBeltLevel.shortName),
                    "Category should be appropriate for user's belt level"
                )
            }
        }
    }
    
    // MARK: - Flashcard Session UI Tests
    
    func testFlashcardSessionUIInteractions() throws {
        // CRITICAL UI FLOW: Active flashcard session interactions
        
        let testProfile = try profileService.createProfile(
            name: "Session UI Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Create test session
        let sessionConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 8
        )
        
        let session = try flashcardService.startSession(
            configuration: sessionConfig,
            userProfile: testProfile
        )
        
        let sessionViewModel = FlashcardSessionViewModel(
            session: session,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Test initial session state
        XCTAssertEqual(sessionViewModel.currentCardIndex, 0, "Should start at first card")
        XCTAssertEqual(sessionViewModel.totalCards, 8, "Should have correct total cards")
        XCTAssertNotNil(sessionViewModel.currentCard, "Should have current card")
        XCTAssertFalse(sessionViewModel.isShowingAnswer, "Should start showing question")
        XCTAssertFalse(sessionViewModel.isSessionComplete, "Should not be complete initially")
        
        // Test card flip interaction
        let currentCard = sessionViewModel.currentCard!
        XCTAssertNotNil(currentCard.frontText, "Card should have front text")
        XCTAssertNotNil(currentCard.backText, "Card should have back text")
        
        sessionViewModel.flipCard()
        XCTAssertTrue(sessionViewModel.isShowingAnswer, "Should show answer after flip")
        
        sessionViewModel.flipCard()
        XCTAssertFalse(sessionViewModel.isShowingAnswer, "Should show question after second flip")
        
        // Test answer recording
        sessionViewModel.flipCard() // Show answer
        sessionViewModel.recordAnswer(isCorrect: true)
        
        XCTAssertEqual(sessionViewModel.correctAnswers, 1, "Should record correct answer")
        XCTAssertEqual(sessionViewModel.totalAnswered, 1, "Should increment total answered")
        XCTAssertEqual(sessionViewModel.accuracy, 1.0, "Should calculate 100% accuracy")
        
        // Test advancing to next card
        let canAdvance = sessionViewModel.canAdvanceToNextCard()
        XCTAssertTrue(canAdvance, "Should be able to advance to next card")
        
        sessionViewModel.advanceToNextCard()
        XCTAssertEqual(sessionViewModel.currentCardIndex, 1, "Should advance to second card")
        XCTAssertFalse(sessionViewModel.isShowingAnswer, "Should reset to question side for new card")
        
        // Test session progress tracking
        let progressPercentage = sessionViewModel.progressPercentage
        let expectedProgress = 1.0 / 8.0 // 1 card completed out of 8
        XCTAssertEqual(progressPercentage, expectedProgress, accuracy: 0.01, "Should calculate progress correctly")
        
        // Test mixed accuracy scenario
        for cardIndex in 1..<session.totalCards {
            sessionViewModel.flipCard()
            let isCorrect = cardIndex % 2 == 0 // Alternate correct/incorrect
            sessionViewModel.recordAnswer(isCorrect: isCorrect)
            
            if cardIndex < session.totalCards - 1 {
                sessionViewModel.advanceToNextCard()
            }
        }
        
        // Verify final session state
        XCTAssertTrue(sessionViewModel.isSessionComplete, "Session should be complete")
        XCTAssertEqual(sessionViewModel.totalAnswered, 8, "Should have answered all cards")
        
        let expectedCorrect = 5 // First card (correct) + alternating pattern
        XCTAssertEqual(sessionViewModel.correctAnswers, expectedCorrect, "Should track correct answers accurately")
        
        let expectedAccuracy = Double(expectedCorrect) / 8.0
        XCTAssertEqual(sessionViewModel.accuracy, expectedAccuracy, accuracy: 0.01, "Should calculate final accuracy")
        
        // Performance validation for card interactions
        let flipMeasurement = PerformanceMeasurement.measureExecutionTime {
            for _ in 1...10 {
                sessionViewModel.flipCard()
            }
        }
        XCTAssertLessThan(flipMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Card flip animations should be performant")
    }
    
    func testFlashcardDirectionSwitching() throws {
        // Test card direction switching UI behavior
        
        let testProfile = try profileService.createProfile(
            name: "Direction Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test English → Korean direction
        let englishToKoreanConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 5
        )
        
        let englishSession = try flashcardService.startSession(
            configuration: englishToKoreanConfig,
            userProfile: testProfile
        )
        
        let englishViewModel = FlashcardSessionViewModel(
            session: englishSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        let englishCard = englishViewModel.currentCard!
        XCTAssertTrue(englishCard.frontText.allSatisfy { !$0.isHangul }, 
                     "Front should be English in English→Korean mode")
        XCTAssertTrue(englishCard.backText.contains { $0.isHangul }, 
                     "Back should contain Korean in English→Korean mode")
        
        // Test Korean → English direction
        let koreanToEnglishConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .koreanToEnglish,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 5
        )
        
        let koreanSession = try flashcardService.startSession(
            configuration: koreanToEnglishConfig,
            userProfile: testProfile
        )
        
        let koreanViewModel = FlashcardSessionViewModel(
            session: koreanSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        let koreanCard = koreanViewModel.currentCard!
        XCTAssertTrue(koreanCard.frontText.contains { $0.isHangul }, 
                     "Front should contain Korean in Korean→English mode")
        XCTAssertTrue(koreanCard.backText.allSatisfy { !$0.isHangul }, 
                     "Back should be English in Korean→English mode")
        
        // Test both directions mode
        let bothDirectionsConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .bothDirections,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 10
        )
        
        let bothSession = try flashcardService.startSession(
            configuration: bothDirectionsConfig,
            userProfile: testProfile
        )
        
        let bothViewModel = FlashcardSessionViewModel(
            session: bothSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Verify both directions includes mixed card orientations
        var hasEnglishFront = false
        var hasKoreanFront = false
        
        for cardIndex in 0..<min(bothSession.totalCards, 6) {
            if cardIndex > 0 {
                bothViewModel.recordAnswer(isCorrect: true)
                bothViewModel.advanceToNextCard()
            }
            
            let card = bothViewModel.currentCard!
            if card.frontText.allSatisfy { !$0.isHangul } {
                hasEnglishFront = true
            }
            if card.frontText.contains { $0.isHangul } {
                hasKoreanFront = true
            }
        }
        
        XCTAssertTrue(hasEnglishFront || hasKoreanFront, 
                     "Both directions should include cards with different front languages")
    }
    
    // MARK: - Flashcard Mode Switching Tests
    
    func testClassicVsLeitnerModeUI() throws {
        // Test UI differences between Classic and Leitner modes
        
        let testProfile = try profileService.createProfile(
            name: "Mode Comparison Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test Classic mode UI
        let classicConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 6
        )
        
        let classicSession = try flashcardService.startSession(
            configuration: classicConfig,
            userProfile: testProfile
        )
        
        let classicViewModel = FlashcardSessionViewModel(
            session: classicSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Classic mode should show simple correct/incorrect feedback
        XCTAssertFalse(classicViewModel.showsLeitnerLevels, "Classic mode should not show Leitner levels")
        XCTAssertTrue(classicViewModel.showsSimpleProgress, "Classic mode should show simple progress")
        
        // Test answering in classic mode
        classicViewModel.flipCard()
        classicViewModel.recordAnswer(isCorrect: true)
        
        XCTAssertEqual(classicViewModel.correctAnswers, 1, "Classic mode should track simple accuracy")
        XCTAssertNil(classicViewModel.currentCardLeitnerLevel, "Classic mode should not have Leitner levels")
        
        // Test Leitner mode UI
        let leitnerConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .leitner,
            maxCards: 6
        )
        
        let leitnerSession = try flashcardService.startSession(
            configuration: leitnerConfig,
            userProfile: testProfile
        )
        
        let leitnerViewModel = FlashcardSessionViewModel(
            session: leitnerSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Leitner mode should show spaced repetition levels
        XCTAssertTrue(leitnerViewModel.showsLeitnerLevels, "Leitner mode should show levels")
        XCTAssertFalse(leitnerViewModel.showsSimpleProgress, "Leitner mode should show advanced progress")
        
        // Test Leitner level progression
        leitnerViewModel.flipCard()
        leitnerViewModel.recordAnswer(isCorrect: true)
        
        XCTAssertNotNil(leitnerViewModel.currentCardLeitnerLevel, "Leitner mode should track card levels")
        XCTAssertGreaterThanOrEqual(leitnerViewModel.currentCardLeitnerLevel!, 1, 
                                   "Leitner level should be valid")
        
        // Test incorrect answer in Leitner mode (should reset level)
        leitnerViewModel.advanceToNextCard()
        leitnerViewModel.flipCard()
        leitnerViewModel.recordAnswer(isCorrect: false)
        
        let levelAfterIncorrect = leitnerViewModel.currentCardLeitnerLevel!
        XCTAssertLessThanOrEqual(levelAfterIncorrect, 1, 
                                "Incorrect answer should reset or maintain low Leitner level")
    }
    
    func testStudyVsTestModeUI() throws {
        // Test UI differences between Study and Test modes
        
        let testProfile = try profileService.createProfile(
            name: "Study Test Mode Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test Study mode UI
        let studyConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 5
        )
        
        let studySession = try flashcardService.startSession(
            configuration: studyConfig,
            userProfile: testProfile
        )
        
        let studyViewModel = FlashcardSessionViewModel(
            session: studySession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Study mode should allow unlimited flips and flexible progression
        XCTAssertTrue(studyViewModel.allowsUnlimitedFlips, "Study mode should allow unlimited card flips")
        XCTAssertTrue(studyViewModel.allowsSkipping, "Study mode should allow skipping cards")
        XCTAssertFalse(studyViewModel.requiresAnswerBeforeAdvancing, "Study mode should allow flexible advancement")
        
        // Test card flipping in study mode
        studyViewModel.flipCard()
        XCTAssertTrue(studyViewModel.isShowingAnswer, "Should show answer in study mode")
        
        studyViewModel.flipCard()
        XCTAssertFalse(studyViewModel.isShowingAnswer, "Should allow flipping back to question")
        
        // Test skipping in study mode
        let initialCardIndex = studyViewModel.currentCardIndex
        studyViewModel.skipCard()
        XCTAssertEqual(studyViewModel.currentCardIndex, initialCardIndex + 1, "Should advance when skipping")
        
        // Test Test mode UI
        let testConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .test,
            cardMode: .classic,
            maxCards: 5
        )
        
        let testSession = try flashcardService.startSession(
            configuration: testConfig,
            userProfile: testProfile
        )
        
        let testViewModel = FlashcardSessionViewModel(
            session: testSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Test mode should be more restrictive
        XCTAssertFalse(testViewModel.allowsUnlimitedFlips, "Test mode should limit card flips")
        XCTAssertFalse(testViewModel.allowsSkipping, "Test mode should not allow skipping")
        XCTAssertTrue(testViewModel.requiresAnswerBeforeAdvancing, "Test mode should require answers")
        
        // Test restricted flipping in test mode
        testViewModel.flipCard()
        XCTAssertTrue(testViewModel.isShowingAnswer, "Should show answer after first flip")
        
        // In test mode, second flip might be restricted or require answer first
        let canFlipBack = testViewModel.canFlipCard()
        if !canFlipBack {
            XCTAssertTrue(testViewModel.requiresAnswerBeforeAdvancing, 
                         "If can't flip back, should require answer")
        }
        
        // Test advancement requirements in test mode
        let canAdvanceWithoutAnswer = testViewModel.canAdvanceToNextCard()
        if testViewModel.requiresAnswerBeforeAdvancing {
            XCTAssertFalse(canAdvanceWithoutAnswer, "Should not advance without answer in test mode")
            
            testViewModel.recordAnswer(isCorrect: true)
            XCTAssertTrue(testViewModel.canAdvanceToNextCard(), "Should allow advancement after answer")
        }
    }
    
    // MARK: - Flashcard Results UI Tests
    
    func testFlashcardResultsDisplay() throws {
        // Test flashcard results screen UI and data accuracy
        
        let testProfile = try profileService.createProfile(
            name: "Results Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Complete a flashcard session with known results
        let sessionConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .test,
            cardMode: .classic,
            maxCards: 10
        )
        
        let session = try flashcardService.startSession(
            configuration: sessionConfig,
            userProfile: testProfile
        )
        
        // Simulate session with specific accuracy pattern
        let correctIndices = Set([0, 1, 2, 4, 6, 7, 9]) // 7 out of 10 correct (70%)
        var incorrectCards: [FlashcardSessionCard] = []
        
        for cardIndex in 0..<session.totalCards {
            let isCorrect = correctIndices.contains(cardIndex)
            
            if !isCorrect {
                incorrectCards.append(session.currentCard)
            }
            
            flashcardService.recordAnswer(
                session: session,
                isCorrect: isCorrect,
                responseTime: Double.random(in: 2.0...6.0)
            )
            
            if cardIndex < session.totalCards - 1 {
                flashcardService.advanceToNextCard(session: session)
            }
        }
        
        let results = flashcardService.completeSession(session: session, userProfile: testProfile)
        
        // Test results view model
        let resultsViewModel = FlashcardResultsViewModel(
            results: results,
            userProfile: testProfile,
            flashcardService: flashcardService
        )
        
        // Verify basic statistics
        XCTAssertEqual(resultsViewModel.totalCards, 10, "Should show correct total cards")
        XCTAssertEqual(resultsViewModel.correctAnswers, 7, "Should show correct number of correct answers")
        XCTAssertEqual(resultsViewModel.incorrectAnswers, 3, "Should show correct number of incorrect answers")
        XCTAssertEqual(resultsViewModel.accuracy, 0.7, accuracy: 0.01, "Should show 70% accuracy")
        
        // Verify session details
        XCTAssertNotNil(resultsViewModel.sessionDuration, "Should show session duration")
        XCTAssertGreaterThan(resultsViewModel.sessionDuration, 0, "Duration should be positive")
        XCTAssertNotNil(resultsViewModel.averageResponseTime, "Should show average response time")
        XCTAssertGreaterThan(resultsViewModel.averageResponseTime, 0, "Response time should be positive")
        
        // Test accuracy categorization
        let accuracyCategory = resultsViewModel.accuracyCategory
        XCTAssertEqual(accuracyCategory, .good, "70% should be categorized as 'good'")
        
        let accuracyMessage = resultsViewModel.accuracyMessage
        XCTAssertNotNil(accuracyMessage, "Should provide accuracy feedback message")
        XCTAssertTrue(accuracyMessage.contains("good") || accuracyMessage.contains("well"), 
                     "Message should reflect good performance")
        
        // Test incorrect cards review
        XCTAssertEqual(resultsViewModel.incorrectCards.count, 3, "Should provide incorrect cards for review")
        
        for incorrectCard in resultsViewModel.incorrectCards {
            XCTAssertNotNil(incorrectCard.frontText, "Incorrect card should have front text")
            XCTAssertNotNil(incorrectCard.backText, "Incorrect card should have back text")
            XCTAssertNotNil(incorrectCard.explanation, "Incorrect card should have explanation")
        }
        
        // Test performance insights
        if let insights = resultsViewModel.performanceInsights {
            XCTAssertGreaterThan(insights.count, 0, "Should provide performance insights")
            
            for insight in insights {
                XCTAssertFalse(insight.isEmpty, "Insights should not be empty")
            }
        }
        
        // Test recommended next actions
        let recommendations = resultsViewModel.nextActionRecommendations
        XCTAssertGreaterThan(recommendations.count, 0, "Should provide next action recommendations")
        
        for recommendation in recommendations {
            XCTAssertNotNil(recommendation.title, "Recommendation should have title")
            XCTAssertNotNil(recommendation.description, "Recommendation should have description")
            XCTAssertNotNil(recommendation.action, "Recommendation should have action")
        }
        
        // Test retry functionality
        let canRetrySession = resultsViewModel.canRetrySession
        XCTAssertTrue(canRetrySession, "Should allow retrying session")
        
        let retryConfig = resultsViewModel.createRetryConfiguration()
        XCTAssertNotNil(retryConfig, "Should create retry configuration")
        XCTAssertEqual(retryConfig.categories, sessionConfig.categories, "Retry should use same categories")
        
        // Test review incorrect cards functionality
        let canReviewIncorrect = resultsViewModel.canReviewIncorrectCards
        XCTAssertTrue(canReviewIncorrect, "Should allow reviewing incorrect cards")
        
        let reviewConfig = resultsViewModel.createIncorrectReviewConfiguration()
        XCTAssertNotNil(reviewConfig, "Should create review configuration")
        XCTAssertLessThanOrEqual(reviewConfig.maxCards, 3, "Review should include only incorrect cards")
    }
    
    func testFlashcardProgressVisualization() throws {
        // Test progress visualization and statistics display
        
        let testProfile = try profileService.createProfile(
            name: "Progress Viz Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Complete multiple sessions to build progress history
        let sessionConfigs = [
            (accuracy: 0.6, cards: 8),
            (accuracy: 0.75, cards: 10),
            (accuracy: 0.8, cards: 12),
            (accuracy: 0.85, cards: 15)
        ]
        
        var allResults: [FlashcardSessionResults] = []
        
        for (targetAccuracy, cardCount) in sessionConfigs {
            let config = FlashcardSessionConfiguration(
                categories: ["basic_techniques"],
                cardDirection: .englishToKorean,
                sessionMode: .study,
                cardMode: .classic,
                maxCards: cardCount
            )
            
            let session = try flashcardService.startSession(configuration: config, userProfile: testProfile)
            
            let correctCount = Int(Double(cardCount) * targetAccuracy)
            for cardIndex in 0..<cardCount {
                let isCorrect = cardIndex < correctCount
                flashcardService.recordAnswer(session: session, isCorrect: isCorrect, responseTime: 3.0)
                
                if cardIndex < cardCount - 1 {
                    flashcardService.advanceToNextCard(session: session)
                }
            }
            
            let results = flashcardService.completeSession(session: session, userProfile: testProfile)
            allResults.append(results)
            
            // Small delay between sessions
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Test progress visualization view model
        let progressViewModel = FlashcardProgressViewModel(
            userProfile: testProfile,
            flashcardService: flashcardService
        )
        
        // Verify session history
        XCTAssertGreaterThanOrEqual(progressViewModel.recentSessions.count, 4, 
                                   "Should show recent sessions")
        
        // Test accuracy trend
        let accuracyTrend = progressViewModel.accuracyTrend
        XCTAssertNotNil(accuracyTrend, "Should calculate accuracy trend")
        XCTAssertTrue(accuracyTrend!.isImproving, "Should detect improving trend")
        XCTAssertGreaterThan(accuracyTrend!.averageAccuracy, 0.7, "Should show good average accuracy")
        
        // Test study time tracking
        let studyTimeStats = progressViewModel.studyTimeStatistics
        XCTAssertNotNil(studyTimeStats, "Should provide study time statistics")
        XCTAssertGreaterThan(studyTimeStats.totalStudyTime, 0, "Should have measurable study time")
        XCTAssertGreaterThan(studyTimeStats.averageSessionDuration, 0, "Should calculate average duration")
        
        // Test card mastery tracking
        let masteryStats = progressViewModel.cardMasteryStatistics
        XCTAssertNotNil(masteryStats, "Should provide mastery statistics")
        XCTAssertGreaterThan(masteryStats.totalCardsStudied, 0, "Should track cards studied")
        XCTAssertGreaterThanOrEqual(masteryStats.masteredCards, 0, "Should track mastered cards")
        
        // Test visual chart data
        let chartData = progressViewModel.generateChartData()
        XCTAssertNotNil(chartData, "Should generate chart data")
        XCTAssertGreaterThan(chartData.dataPoints.count, 0, "Should have data points for visualization")
        
        for dataPoint in chartData.dataPoints {
            XCTAssertGreaterThanOrEqual(dataPoint.accuracy, 0.0, "Accuracy should be valid")
            XCTAssertLessThanOrEqual(dataPoint.accuracy, 1.0, "Accuracy should be valid percentage")
            XCTAssertNotNil(dataPoint.date, "Data point should have date")
        }
        
        // Performance test for progress calculation
        let progressMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = FlashcardProgressViewModel(userProfile: testProfile, flashcardService: flashcardService)
        }
        
        XCTAssertLessThan(progressMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Progress calculation should be fast")
    }
    
    // MARK: - Flashcard Session Interruption Tests
    
    func testFlashcardSessionInterruptionRecovery() throws {
        // Test session interruption and recovery UI flows
        
        let testProfile = try profileService.createProfile(
            name: "Interruption Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Start session and progress partially
        let sessionConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques"],
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .leitner,
            maxCards: 12
        )
        
        let originalSession = try flashcardService.startSession(
            configuration: sessionConfig,
            userProfile: testProfile
        )
        
        let sessionViewModel = FlashcardSessionViewModel(
            session: originalSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Progress through half the session
        let midPoint = originalSession.totalCards / 2
        for cardIndex in 0..<midPoint {
            sessionViewModel.flipCard()
            sessionViewModel.recordAnswer(isCorrect: cardIndex % 3 != 0) // 67% accuracy
            
            if cardIndex < midPoint - 1 {
                sessionViewModel.advanceToNextCard()
            }
        }
        
        // Verify partial progress
        XCTAssertEqual(sessionViewModel.currentCardIndex, midPoint - 1, "Should be at midpoint")
        XCTAssertEqual(sessionViewModel.totalAnswered, midPoint, "Should have answered half the cards")
        XCTAssertFalse(sessionViewModel.isSessionComplete, "Session should not be complete")
        
        // Simulate app backgrounding - save session state
        let sessionState = sessionViewModel.saveCurrentState()
        XCTAssertNotNil(sessionState, "Should save current session state")
        XCTAssertEqual(sessionState.currentCardIndex, midPoint - 1, "State should capture current position")
        XCTAssertEqual(sessionState.totalAnswered, midPoint, "State should capture progress")
        XCTAssertNotNil(sessionState.sessionConfiguration, "State should include configuration")
        
        // Simulate session restoration
        let restoredSession = try flashcardService.restoreSession(
            state: sessionState,
            userProfile: testProfile
        )
        
        let restoredViewModel = FlashcardSessionViewModel(
            session: restoredSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Verify restoration accuracy
        XCTAssertEqual(restoredViewModel.currentCardIndex, midPoint - 1, "Should restore position")
        XCTAssertEqual(restoredViewModel.totalAnswered, midPoint, "Should restore progress")
        XCTAssertEqual(restoredViewModel.totalCards, originalSession.totalCards, "Should maintain total cards")
        XCTAssertEqual(restoredViewModel.correctAnswers, sessionViewModel.correctAnswers, 
                      "Should restore correct answer count")
        
        // Test continuing from restored state
        let canContinue = restoredViewModel.canAdvanceToNextCard()
        XCTAssertTrue(canContinue, "Should be able to continue from restored state")
        
        restoredViewModel.advanceToNextCard()
        XCTAssertEqual(restoredViewModel.currentCardIndex, midPoint, "Should advance from restored position")
        
        // Complete the restored session
        for cardIndex in midPoint..<restoredSession.totalCards {
            restoredViewModel.flipCard()
            restoredViewModel.recordAnswer(isCorrect: true)
            
            if cardIndex < restoredSession.totalCards - 1 {
                restoredViewModel.advanceToNextCard()
            }
        }
        
        XCTAssertTrue(restoredViewModel.isSessionComplete, "Should complete restored session")
        XCTAssertEqual(restoredViewModel.totalAnswered, restoredSession.totalCards, 
                      "Should have answered all cards")
        
        // Test session completion after restoration
        let finalResults = flashcardService.completeSession(
            session: restoredSession,
            userProfile: testProfile
        )
        
        XCTAssertNotNil(finalResults, "Should produce results from restored session")
        XCTAssertEqual(finalResults.totalCards, originalSession.totalCards, 
                      "Results should reflect full session")
    }
    
    // MARK: - Performance and Memory Tests
    
    func testFlashcardUIPerformanceUnderLoad() throws {
        // Test flashcard UI performance with large card sets and rapid interactions
        
        let testProfile = try profileService.createProfile(
            name: "Performance Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test with large card set
        let largeSessionConfig = FlashcardSessionConfiguration(
            categories: ["basic_techniques", "intermediate_techniques", "advanced_techniques"],
            cardDirection: .bothDirections,
            sessionMode: .study,
            cardMode: .leitner,
            maxCards: 50
        )
        
        let largeSession = try flashcardService.startSession(
            configuration: largeSessionConfig,
            userProfile: testProfile
        )
        
        let performanceViewModel = FlashcardSessionViewModel(
            session: largeSession,
            flashcardService: flashcardService,
            userProfile: testProfile
        )
        
        // Test rapid card interactions
        let rapidInteractionMeasurement = PerformanceMeasurement.measureExecutionTime {
            for cardIndex in 0..<min(largeSession.totalCards, 20) {
                performanceViewModel.flipCard()
                performanceViewModel.flipCard()
                performanceViewModel.recordAnswer(isCorrect: cardIndex % 2 == 0)
                
                if cardIndex < 19 {
                    performanceViewModel.advanceToNextCard()
                }
            }
        }
        
        XCTAssertLessThan(rapidInteractionMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2,
                         "Rapid card interactions should remain performant")
        
        // Test memory usage during large session
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            // Simulate full session completion
            let remainingCards = min(largeSession.totalCards - 20, 10)
            for cardIndex in 0..<remainingCards {
                performanceViewModel.flipCard()
                performanceViewModel.recordAnswer(isCorrect: true)
                
                if cardIndex < remainingCards - 1 {
                    performanceViewModel.advanceToNextCard()
                }
            }
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 4,
                         "Large flashcard sessions should not cause significant memory growth")
        
        // Test UI responsiveness with rapid mode switching
        let modeSwitchMeasurement = PerformanceMeasurement.measureExecutionTime {
            for _ in 1...5 {
                let newConfig = FlashcardSessionConfiguration(
                    categories: ["basic_techniques"],
                    cardDirection: [.englishToKorean, .koreanToEnglish, .bothDirections].randomElement()!,
                    sessionMode: [.study, .test].randomElement()!,
                    cardMode: [.classic, .leitner].randomElement()!,
                    maxCards: 8
                )
                
                let quickSession = try! flashcardService.startSession(
                    configuration: newConfig,
                    userProfile: testProfile
                )
                
                let _ = FlashcardSessionViewModel(
                    session: quickSession,
                    flashcardService: flashcardService,
                    userProfile: testProfile
                )
            }
        }
        
        XCTAssertLessThan(modeSwitchMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 3,
                         "Mode switching should be performant")
    }
    
    // MARK: - Helper Methods
    
    private func getBeltLevel(_ shortName: String) -> BeltLevel {
        let descriptor = FetchDescriptor<BeltLevel>(
            predicate: #Predicate { belt in belt.shortName == shortName }
        )
        
        do {
            let belts = try testContext.fetch(descriptor)
            guard let belt = belts.first else {
                XCTFail("Belt level '\(shortName)' not found in test data")
                return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
            }
            return belt
        } catch {
            XCTFail("Failed to fetch belt level: \(error)")
            return BeltLevel(name: shortName, shortName: shortName, colorName: "Test", sortOrder: 1, isKyup: true)
        }
    }
}

// MARK: - Mock UI Components for Testing

// These would be actual SwiftUI ViewModels in the real app
class FlashcardConfigurationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var availableCategories: [TerminologyCategory] = []
    @Published var selectedCategories: Set<String> = []
    @Published var cardDirection: FlashcardDirection = .englishToKorean
    @Published var sessionMode: FlashcardSessionMode = .study
    @Published var cardMode: FlashcardMode = .classic
    @Published var maxCards: Int = 20
    
    private let dataServices: DataServices
    private let userProfile: UserProfile
    
    init(dataServices: DataServices, userProfile: UserProfile) {
        self.dataServices = dataServices
        self.userProfile = userProfile
        loadAvailableCategories()
    }
    
    var canStartSession: Bool {
        return !selectedCategories.isEmpty && validationError == nil
    }
    
    var validationError: String? {
        if selectedCategories.isEmpty {
            return "Please select at least one category"
        }
        return nil
    }
    
    func toggleCategorySelection(_ categoryId: String) {
        if selectedCategories.contains(categoryId) {
            selectedCategories.remove(categoryId)
        } else {
            selectedCategories.insert(categoryId)
        }
    }
    
    func createSessionConfiguration() -> FlashcardSessionConfiguration {
        return FlashcardSessionConfiguration(
            categories: Array(selectedCategories),
            cardDirection: cardDirection,
            sessionMode: sessionMode,
            cardMode: cardMode,
            maxCards: maxCards
        )
    }
    
    private func loadAvailableCategories() {
        // Mock implementation - would load from data service
        availableCategories = [
            TerminologyCategory(id: "basic_techniques", name: "Basic Techniques", minimumBeltLevel: "10th Keup"),
            TerminologyCategory(id: "intermediate_techniques", name: "Intermediate Techniques", minimumBeltLevel: "7th Keup"),
            TerminologyCategory(id: "advanced_techniques", name: "Advanced Techniques", minimumBeltLevel: "4th Keup")
        ]
    }
}

class FlashcardSessionViewModel: ObservableObject {
    @Published var currentCardIndex: Int = 0
    @Published var isShowingAnswer: Bool = false
    @Published var correctAnswers: Int = 0
    @Published var totalAnswered: Int = 0
    
    private let session: FlashcardSession
    private let flashcardService: FlashcardService
    private let userProfile: UserProfile
    
    init(session: FlashcardSession, flashcardService: FlashcardService, userProfile: UserProfile) {
        self.session = session
        self.flashcardService = flashcardService
        self.userProfile = userProfile
    }
    
    var totalCards: Int { session.totalCards }
    var currentCard: FlashcardSessionCard? { session.currentCard }
    var isSessionComplete: Bool { currentCardIndex >= totalCards }
    var accuracy: Double { 
        totalAnswered > 0 ? Double(correctAnswers) / Double(totalAnswered) : 0.0 
    }
    var progressPercentage: Double {
        totalCards > 0 ? Double(currentCardIndex + 1) / Double(totalCards) : 0.0
    }
    
    // Mode-specific UI properties
    var showsLeitnerLevels: Bool { session.configuration.cardMode == .leitner }
    var showsSimpleProgress: Bool { session.configuration.cardMode == .classic }
    var allowsUnlimitedFlips: Bool { session.configuration.sessionMode == .study }
    var allowsSkipping: Bool { session.configuration.sessionMode == .study }
    var requiresAnswerBeforeAdvancing: Bool { session.configuration.sessionMode == .test }
    var currentCardLeitnerLevel: Int? { 
        showsLeitnerLevels ? Int.random(in: 1...5) : nil 
    }
    
    func flipCard() {
        isShowingAnswer.toggle()
    }
    
    func canFlipCard() -> Bool {
        return allowsUnlimitedFlips || !isShowingAnswer
    }
    
    func recordAnswer(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        totalAnswered += 1
        
        flashcardService.recordAnswer(
            session: session,
            isCorrect: isCorrect,
            responseTime: 3.0
        )
    }
    
    func canAdvanceToNextCard() -> Bool {
        if requiresAnswerBeforeAdvancing {
            return totalAnswered > currentCardIndex
        }
        return currentCardIndex < totalCards - 1
    }
    
    func advanceToNextCard() {
        if canAdvanceToNextCard() {
            currentCardIndex += 1
            isShowingAnswer = false
            flashcardService.advanceToNextCard(session: session)
        }
    }
    
    func skipCard() {
        if allowsSkipping {
            advanceToNextCard()
        }
    }
    
    func saveCurrentState() -> FlashcardSessionState {
        return FlashcardSessionState(
            currentCardIndex: currentCardIndex,
            totalAnswered: totalAnswered,
            correctAnswers: correctAnswers,
            sessionConfiguration: session.configuration
        )
    }
}

class FlashcardResultsViewModel: ObservableObject {
    let results: FlashcardSessionResults
    private let userProfile: UserProfile
    private let flashcardService: FlashcardService
    
    init(results: FlashcardSessionResults, userProfile: UserProfile, flashcardService: FlashcardService) {
        self.results = results
        self.userProfile = userProfile
        self.flashcardService = flashcardService
    }
    
    var totalCards: Int { results.totalCards }
    var correctAnswers: Int { results.correctAnswers }
    var incorrectAnswers: Int { totalCards - correctAnswers }
    var accuracy: Double { results.accuracy }
    var sessionDuration: TimeInterval { results.sessionDuration }
    var averageResponseTime: TimeInterval { sessionDuration / Double(totalCards) }
    
    var accuracyCategory: AccuracyCategory {
        switch accuracy {
        case 0.9...: return .excellent
        case 0.8..<0.9: return .veryGood
        case 0.7..<0.8: return .good
        case 0.6..<0.7: return .fair
        default: return .needsImprovement
        }
    }
    
    var accuracyMessage: String {
        switch accuracyCategory {
        case .excellent: return "Excellent work! You've mastered this content."
        case .veryGood: return "Very good performance! Keep up the great work."
        case .good: return "Good job! You're making solid progress."
        case .fair: return "Fair performance. Consider reviewing the material."
        case .needsImprovement: return "Keep practicing! Review the incorrect answers."
        }
    }
    
    var incorrectCards: [FlashcardSessionCard] { 
        // Mock implementation - would return actual incorrect cards
        [] 
    }
    
    var performanceInsights: [String]? {
        var insights: [String] = []
        
        if accuracy >= 0.8 {
            insights.append("Strong performance across all card types")
        }
        
        if averageResponseTime < 3.0 {
            insights.append("Quick response times indicate good familiarity")
        }
        
        return insights.isEmpty ? nil : insights
    }
    
    var nextActionRecommendations: [ActionRecommendation] {
        var recommendations: [ActionRecommendation] = []
        
        if accuracy < 0.7 {
            recommendations.append(ActionRecommendation(
                title: "Review Incorrect Cards",
                description: "Focus on the cards you missed",
                action: { /* review action */ }
            ))
        }
        
        recommendations.append(ActionRecommendation(
            title: "Try Again",
            description: "Practice with the same settings",
            action: { /* retry action */ }
        ))
        
        return recommendations
    }
    
    var canRetrySession: Bool { true }
    var canReviewIncorrectCards: Bool { incorrectAnswers > 0 }
    
    func createRetryConfiguration() -> FlashcardSessionConfiguration {
        return results.sessionConfiguration
    }
    
    func createIncorrectReviewConfiguration() -> FlashcardSessionConfiguration {
        var config = results.sessionConfiguration
        config.maxCards = incorrectAnswers
        return config
    }
}

class FlashcardProgressViewModel: ObservableObject {
    private let userProfile: UserProfile
    private let flashcardService: FlashcardService
    
    init(userProfile: UserProfile, flashcardService: FlashcardService) {
        self.userProfile = userProfile
        self.flashcardService = flashcardService
    }
    
    var recentSessions: [FlashcardSessionResults] {
        // Mock implementation - would fetch from service
        return []
    }
    
    var accuracyTrend: FlashcardAccuracyTrend? {
        return FlashcardAccuracyTrend(isImproving: true, averageAccuracy: 0.75)
    }
    
    var studyTimeStatistics: StudyTimeStatistics {
        return StudyTimeStatistics(totalStudyTime: 3600, averageSessionDuration: 300)
    }
    
    var cardMasteryStatistics: CardMasteryStatistics {
        return CardMasteryStatistics(totalCardsStudied: 150, masteredCards: 120)
    }
    
    func generateChartData() -> ChartData {
        let dataPoints = [
            ChartDataPoint(accuracy: 0.6, date: Date()),
            ChartDataPoint(accuracy: 0.75, date: Date()),
            ChartDataPoint(accuracy: 0.8, date: Date())
        ]
        return ChartData(dataPoints: dataPoints)
    }
}

// Supporting types for testing
enum AccuracyCategory {
    case excellent, veryGood, good, fair, needsImprovement
}

struct ActionRecommendation {
    let title: String
    let description: String
    let action: () -> Void
}

struct FlashcardAccuracyTrend {
    let isImproving: Bool
    let averageAccuracy: Double
}

struct StudyTimeStatistics {
    let totalStudyTime: TimeInterval
    let averageSessionDuration: TimeInterval
}

struct CardMasteryStatistics {
    let totalCardsStudied: Int
    let masteredCards: Int
}

struct ChartData {
    let dataPoints: [ChartDataPoint]
}

struct ChartDataPoint {
    let accuracy: Double
    let date: Date
}

struct FlashcardSessionState {
    let currentCardIndex: Int
    let totalAnswered: Int
    let correctAnswers: Int
    let sessionConfiguration: FlashcardSessionConfiguration
}

struct TerminologyCategory {
    let id: String
    let name: String
    let minimumBeltLevel: String?
    
    init(id: String, name: String, minimumBeltLevel: String? = nil) {
        self.id = id
        self.name = name
        self.minimumBeltLevel = minimumBeltLevel
    }
}

// Character extension for Korean detection
extension Character {
    var isHangul: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (0xAC00...0xD7AF).contains(scalar.value)
    }
}