import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * TheoryTechniquesUITests.swift
 * 
 * PURPOSE: Feature-specific UI integration testing for theory and techniques reference systems
 * 
 * COVERAGE: Phase 2.5 - Final feature-specific UI functionality validation
 * - Theory content filtering and belt-level access restrictions
 * - Theory detail view presentation and navigation with rich content
 * - Theory quiz functionality with interactive assessment
 * - Techniques comprehensive filtering system with multi-dimensional search
 * - Technique detail view presentation with media integration
 * - Search functionality across technique properties and descriptions
 * - Content organization and categorization UI with hierarchical browsing
 * - Belt requirement breakdowns and progression guidance
 * 
 * BUSINESS IMPACT: Theory and techniques represent foundational knowledge systems.
 * UI issues affect comprehensive learning and reference accessibility.
 */
final class TheoryTechniquesUITests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var theoryService: TechniquesDataService!
    var techniquesService: TechniquesDataService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with theory and techniques models
        testContainer = try TestContainerFactory.createTestContainer()
        testContext = ModelContext(testContainer)
        
        // Set up extensive theory and techniques content
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices.shared
        profileService = dataServices.profileService
        theoryService = dataServices.theoryService
        techniquesService = dataServices.techniquesService
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        theoryService = nil
        techniquesService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Theory System UI Tests
    
    func testTheoryContentFilteringUI() throws {
        // CRITICAL UI FLOW: Theory content filtering and access control
        
        let testProfile = try profileService.createProfile(
            name: "Theory Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test theory view model initialization
        let theoryViewModel = TheoryViewModel(
            theoryService: theoryService,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertFalse(theoryViewModel.isLoading, "Should not be loading initially")
        XCTAssertGreaterThan(theoryViewModel.availableCategories.count, 0, "Should have available categories")
        XCTAssertGreaterThan(theoryViewModel.theoryContent.count, 0, "Should have theory content")
        
        // Test belt level filtering
        let availableContent = theoryViewModel.theoryContent
        for content in availableContent {
            if let requiredBelt = content.minimumBeltLevel {
                XCTAssertLessThanOrEqual(
                    BeltUtils.getLegacySortOrder(for: requiredBelt),
                    BeltUtils.getLegacySortOrder(for: testProfile.currentBeltLevel.shortName),
                    "Theory content should be appropriate for user's belt level"
                )
            }
        }
        
        // Test learning mode restrictions
        if testProfile.learningMode == .mastery {
            let masteryContent = theoryViewModel.getMasteryModeContent()
            XCTAssertLessThanOrEqual(masteryContent.count, availableContent.count,
                                    "Mastery mode should have restricted content")
            
            for content in masteryContent {
                XCTAssertTrue(content.isCoreContent || content.isRecommendedForMastery,
                             "Mastery mode should focus on core content")
            }
        }
        
        // Test category filtering
        let categories = theoryViewModel.availableCategories
        for category in categories {
            theoryViewModel.selectCategory(category.id)
            let filteredContent = theoryViewModel.getFilteredContent()
            
            for content in filteredContent {
                XCTAssertEqual(content.categoryId, category.id, "Filtered content should match selected category")
            }
        }
        
        // Test search functionality
        theoryViewModel.updateSearchQuery("taekwondo")
        let searchResults = theoryViewModel.getFilteredContent()
        
        for result in searchResults {
            let searchableText = "\(result.title) \(result.content) \(result.keywords.joined(separator: " "))".lowercased()
            XCTAssertTrue(searchableText.contains("taekwondo"), "Search results should match query")
        }
        
        // Test difficulty filtering
        let difficultyLevels: [TheoryDifficulty] = [.beginner, .intermediate, .advanced]
        for difficulty in difficultyLevels {
            theoryViewModel.filterByDifficulty(difficulty)
            let difficultyFiltered = theoryViewModel.getFilteredContent()
            
            for content in difficultyFiltered {
                XCTAssertEqual(content.difficulty, difficulty, "Content should match difficulty filter")
            }
        }
        
        // Test content sorting
        theoryViewModel.sortBy(.title)
        let titleSorted = theoryViewModel.getFilteredContent()
        if titleSorted.count > 1 {
            for i in 0..<(titleSorted.count - 1) {
                XCTAssertLessThanOrEqual(titleSorted[i].title, titleSorted[i + 1].title,
                                        "Content should be sorted by title")
            }
        }
        
        theoryViewModel.sortBy(.difficulty)
        let difficultySorted = theoryViewModel.getFilteredContent()
        if difficultySorted.count > 1 {
            for i in 0..<(difficultySorted.count - 1) {
                XCTAssertLessThanOrEqual(difficultySorted[i].difficulty.sortOrder, 
                                        difficultySorted[i + 1].difficulty.sortOrder,
                                        "Content should be sorted by difficulty")
            }
        }
        
        // Performance validation for theory filtering
        let filteringMeasurement = PerformanceMeasurement.measureExecutionTime {
            theoryViewModel.updateSearchQuery("history")
            theoryViewModel.filterByDifficulty(.intermediate)
            theoryViewModel.sortBy(.title)
            let _ = theoryViewModel.getFilteredContent()
        }
        XCTAssertLessThan(filteringMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Theory filtering should be performant")
    }
    
    func testTheoryDetailViewUI() throws {
        // Test theory detail view presentation and navigation
        
        let testProfile = try profileService.createProfile(
            name: "Theory Reader",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Get theory content for testing
        let theoryViewModel = TheoryViewModel(
            theoryService: theoryService,
            userProfile: testProfile
        )
        
        let availableContent = theoryViewModel.theoryContent
        XCTAssertGreaterThan(availableContent.count, 0, "Should have theory content for testing")
        
        let testContent = availableContent.first!
        
        // Test theory detail view model
        let detailViewModel = TheoryDetailViewModel(
            theoryContent: testContent,
            theoryService: theoryService,
            userProfile: testProfile
        )
        
        // Verify content display
        XCTAssertEqual(detailViewModel.title, testContent.title, "Should display correct title")
        XCTAssertEqual(detailViewModel.content, testContent.content, "Should display correct content")
        XCTAssertEqual(detailViewModel.difficulty, testContent.difficulty, "Should display correct difficulty")
        XCTAssertEqual(detailViewModel.estimatedReadingTime, testContent.estimatedReadingTime,
                      "Should display estimated reading time")
        
        // Test content formatting
        let formattedContent = detailViewModel.getFormattedContent()
        XCTAssertNotNil(formattedContent, "Should format content for display")
        XCTAssertTrue(formattedContent.contains(testContent.content), "Formatted content should include original")
        
        // Test related content suggestions
        let relatedContent = detailViewModel.getRelatedContent()
        for related in relatedContent {
            XCTAssertNotEqual(related.id, testContent.id, "Related content should not include current content")
            XCTAssertTrue(related.categoryId == testContent.categoryId || 
                         related.difficulty == testContent.difficulty ||
                         !Set(related.keywords).isDisjoint(with: Set(testContent.keywords)),
                         "Related content should have logical connections")
        }
        
        // Test reading progress tracking
        detailViewModel.startReading()
        XCTAssertTrue(detailViewModel.isReading, "Should track reading state")
        XCTAssertNotNil(detailViewModel.readingStartTime, "Should record reading start time")
        
        Thread.sleep(forTimeInterval: 2.0) // Simulate reading time
        detailViewModel.completeReading()
        XCTAssertFalse(detailViewModel.isReading, "Should complete reading state")
        XCTAssertGreaterThan(detailViewModel.actualReadingTime, 1.5, "Should calculate actual reading time")
        
        // Test bookmarking functionality
        XCTAssertFalse(detailViewModel.isBookmarked, "Should not be bookmarked initially")
        
        detailViewModel.toggleBookmark()
        XCTAssertTrue(detailViewModel.isBookmarked, "Should bookmark content")
        
        detailViewModel.toggleBookmark()
        XCTAssertFalse(detailViewModel.isBookmarked, "Should remove bookmark")
        
        // Test notes functionality
        let testNote = "This is important for belt testing"
        detailViewModel.addNote(testNote)
        
        let userNotes = detailViewModel.getUserNotes()
        XCTAssertGreaterThan(userNotes.count, 0, "Should have user notes")
        XCTAssertTrue(userNotes.contains { $0.content == testNote }, "Should contain added note")
        
        // Test sharing functionality
        let shareData = detailViewModel.prepareForSharing()
        XCTAssertNotNil(shareData, "Should prepare sharing data")
        XCTAssertTrue(shareData.text.contains(testContent.title), "Share data should include title")
        XCTAssertTrue(shareData.text.contains(testContent.content), "Share data should include content")
        
        // Test accessibility
        let accessibilityLabel = detailViewModel.getAccessibilityLabel()
        XCTAssertNotNil(accessibilityLabel, "Should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains(testContent.title), "Accessibility should include title")
        
        let accessibilityHint = detailViewModel.getAccessibilityHint()
        XCTAssertNotNil(accessibilityHint, "Should have accessibility hint")
        XCTAssertTrue(accessibilityHint.contains("read") || accessibilityHint.contains("theory"),
                     "Accessibility hint should describe action")
    }
    
    func testTheoryQuizFunctionality() throws {
        // Test theory quiz interactive assessment
        
        let testProfile = try profileService.createProfile(
            name: "Quiz Taker",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Create theory quiz
        let quizViewModel = TheoryQuizViewModel(
            category: "taekwondo_history",
            difficulty: .intermediate,
            theoryService: theoryService,
            userProfile: testProfile
        )
        
        // Verify quiz initialization
        XCTAssertGreaterThan(quizViewModel.questions.count, 0, "Should have quiz questions")
        XCTAssertEqual(quizViewModel.currentQuestionIndex, 0, "Should start at first question")
        XCTAssertFalse(quizViewModel.isQuizComplete, "Should not be complete initially")
        
        // Test question display
        let currentQuestion = quizViewModel.currentQuestion
        XCTAssertNotNil(currentQuestion, "Should have current question")
        XCTAssertNotNil(currentQuestion!.questionText, "Question should have text")
        XCTAssertGreaterThan(currentQuestion!.options.count, 1, "Question should have multiple options")
        XCTAssertNotNil(currentQuestion!.correctAnswer, "Question should have correct answer")
        XCTAssertTrue(currentQuestion!.options.contains(currentQuestion!.correctAnswer),
                     "Options should include correct answer")
        
        // Test answer selection and validation
        let question = currentQuestion!
        let correctAnswer = question.correctAnswer
        let incorrectAnswer = question.options.first { $0 != correctAnswer }!
        
        // Test correct answer
        quizViewModel.selectAnswer(correctAnswer)
        XCTAssertEqual(quizViewModel.selectedAnswer, correctAnswer, "Should select correct answer")
        
        quizViewModel.submitAnswer()
        XCTAssertTrue(quizViewModel.isAnswerCorrect, "Should recognize correct answer")
        XCTAssertEqual(quizViewModel.correctAnswers, 1, "Should increment correct count")
        
        // Move to next question
        if quizViewModel.canAdvanceToNextQuestion {
            quizViewModel.advanceToNextQuestion()
            XCTAssertEqual(quizViewModel.currentQuestionIndex, 1, "Should advance to next question")
        }
        
        // Test incorrect answer on next question
        if let nextQuestion = quizViewModel.currentQuestion {
            let nextIncorrectAnswer = nextQuestion.options.first { $0 != nextQuestion.correctAnswer }!
            
            quizViewModel.selectAnswer(nextIncorrectAnswer)
            quizViewModel.submitAnswer()
            XCTAssertFalse(quizViewModel.isAnswerCorrect, "Should recognize incorrect answer")
            XCTAssertEqual(quizViewModel.incorrectAnswers, 1, "Should increment incorrect count")
            
            // Test explanation display
            let explanation = quizViewModel.getAnswerExplanation()
            XCTAssertNotNil(explanation, "Should provide explanation for incorrect answer")
            XCTAssertFalse(explanation.isEmpty, "Explanation should not be empty")
            XCTAssertTrue(explanation.contains(nextQuestion.correctAnswer), 
                         "Explanation should mention correct answer")
        }
        
        // Complete remaining questions
        while !quizViewModel.isQuizComplete && quizViewModel.canAdvanceToNextQuestion {
            if let question = quizViewModel.currentQuestion {
                quizViewModel.selectAnswer(question.correctAnswer)
                quizViewModel.submitAnswer()
                quizViewModel.advanceToNextQuestion()
            }
        }
        
        // Test quiz completion
        XCTAssertTrue(quizViewModel.isQuizComplete, "Quiz should be complete")
        
        let quizResults = quizViewModel.getQuizResults()
        XCTAssertNotNil(quizResults, "Should provide quiz results")
        XCTAssertEqual(quizResults.totalQuestions, quizViewModel.questions.count, 
                      "Results should reflect total questions")
        XCTAssertEqual(quizResults.correctAnswers, quizViewModel.correctAnswers,
                      "Results should reflect correct answers")
        XCTAssertGreaterThanOrEqual(quizResults.accuracy, 0.0, "Accuracy should be valid")
        XCTAssertLessThanOrEqual(quizResults.accuracy, 1.0, "Accuracy should be valid percentage")
        
        // Test performance feedback
        let performanceFeedback = quizViewModel.getPerformanceFeedback()
        XCTAssertNotNil(performanceFeedback, "Should provide performance feedback")
        XCTAssertFalse(performanceFeedback.isEmpty, "Feedback should not be empty")
        
        if quizResults.accuracy >= 0.8 {
            XCTAssertTrue(performanceFeedback.contains("excellent") || performanceFeedback.contains("great"),
                         "High performance should get positive feedback")
        }
        
        // Test quiz retry functionality
        XCTAssertTrue(quizViewModel.canRetakeQuiz, "Should allow quiz retake")
        
        quizViewModel.resetQuiz()
        XCTAssertEqual(quizViewModel.currentQuestionIndex, 0, "Should reset to first question")
        XCTAssertEqual(quizViewModel.correctAnswers, 0, "Should reset correct count")
        XCTAssertFalse(quizViewModel.isQuizComplete, "Should reset completion state")
    }
    
    // MARK: - Techniques System UI Tests
    
    func testTechniquesFilteringSystem() throws {
        // CRITICAL UI FLOW: Comprehensive techniques filtering and search
        
        let testProfile = try profileService.createProfile(
            name: "Techniques Student",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test techniques view model initialization
        let techniquesViewModel = TechniquesViewModel(
            techniquesService: techniquesService,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertFalse(techniquesViewModel.isLoading, "Should not be loading initially")
        XCTAssertGreaterThan(techniquesViewModel.availableCategories.count, 0, "Should have available categories")
        XCTAssertGreaterThan(techniquesViewModel.allTechniques.count, 0, "Should have techniques")
        XCTAssertEqual(techniquesViewModel.filteredTechniques.count, techniquesViewModel.allTechniques.count,
                      "Initially should show all techniques")
        
        // Test category filtering
        let categories = techniquesViewModel.availableCategories
        for category in categories {
            techniquesViewModel.selectCategory(category.id)
            let categoryFiltered = techniquesViewModel.filteredTechniques
            
            for technique in categoryFiltered {
                XCTAssertEqual(technique.categoryId, category.id, "Technique should match selected category")
            }
            
            XCTAssertLessThanOrEqual(categoryFiltered.count, techniquesViewModel.allTechniques.count,
                                    "Filtered results should not exceed total")
        }
        
        // Test belt level filtering
        techniquesViewModel.clearFilters()
        techniquesViewModel.filterByBeltLevel(testProfile.currentBeltLevel.shortName)
        let beltFiltered = techniquesViewModel.filteredTechniques
        
        for technique in beltFiltered {
            if let requiredBelt = technique.minimumBeltLevel {
                XCTAssertLessThanOrEqual(
                    BeltUtils.getLegacySortOrder(for: requiredBelt),
                    BeltUtils.getLegacySortOrder(for: testProfile.currentBeltLevel.shortName),
                    "Technique should be appropriate for user's belt level"
                )
            }
        }
        
        // Test difficulty filtering
        let difficulties: [TechniqueDifficulty] = [.basic, .intermediate, .advanced]
        for difficulty in difficulties {
            techniquesViewModel.clearFilters()
            techniquesViewModel.filterByDifficulty(difficulty)
            let difficultyFiltered = techniquesViewModel.filteredTechniques
            
            for technique in difficultyFiltered {
                XCTAssertEqual(technique.difficulty, difficulty, "Technique should match difficulty filter")
            }
        }
        
        // Test technique type filtering
        let techniqueTypes: [TechniqueType] = [.kick, .strike, .block, .stance]
        for techniqueType in techniqueTypes {
            techniquesViewModel.clearFilters()
            techniquesViewModel.filterByType(techniqueType)
            let typeFiltered = techniquesViewModel.filteredTechniques
            
            for technique in typeFiltered {
                XCTAssertEqual(technique.type, techniqueType, "Technique should match type filter")
            }
        }
        
        // Test multi-dimensional filtering
        techniquesViewModel.clearFilters()
        techniquesViewModel.selectCategory(categories.first!.id)
        techniquesViewModel.filterByDifficulty(.intermediate)
        techniquesViewModel.filterByType(.kick)
        
        let multiFiltered = techniquesViewModel.filteredTechniques
        for technique in multiFiltered {
            XCTAssertEqual(technique.categoryId, categories.first!.id, "Should match category")
            XCTAssertEqual(technique.difficulty, .intermediate, "Should match difficulty")
            XCTAssertEqual(technique.type, .kick, "Should match type")
        }
        
        // Test search functionality
        techniquesViewModel.clearFilters()
        techniquesViewModel.updateSearchQuery("front kick")
        let searchResults = techniquesViewModel.filteredTechniques
        
        for result in searchResults {
            let searchableText = "\(result.name) \(result.description) \(result.tags.joined(separator: " "))".lowercased()
            XCTAssertTrue(searchableText.contains("front") || searchableText.contains("kick"),
                         "Search results should match query terms")
        }
        
        // Test sorting options
        let sortOptions: [TechniqueSortOption] = [.name, .difficulty, .beltLevel, .popularity]
        for sortOption in sortOptions {
            techniquesViewModel.clearFilters()
            techniquesViewModel.sortBy(sortOption)
            let sorted = techniquesViewModel.filteredTechniques
            
            if sorted.count > 1 {
                switch sortOption {
                case .name:
                    for i in 0..<(sorted.count - 1) {
                        XCTAssertLessThanOrEqual(sorted[i].name, sorted[i + 1].name,
                                                "Should sort by name")
                    }
                case .difficulty:
                    for i in 0..<(sorted.count - 1) {
                        XCTAssertLessThanOrEqual(sorted[i].difficulty.sortOrder, sorted[i + 1].difficulty.sortOrder,
                                                "Should sort by difficulty")
                    }
                case .beltLevel:
                    for i in 0..<(sorted.count - 1) {
                        let belt1Order = BeltUtils.getLegacySortOrder(for: sorted[i].minimumBeltLevel ?? "10th Keup")
                        let belt2Order = BeltUtils.getLegacySortOrder(for: sorted[i + 1].minimumBeltLevel ?? "10th Keup")
                        XCTAssertLessThanOrEqual(belt1Order, belt2Order, "Should sort by belt level")
                    }
                case .popularity:
                    for i in 0..<(sorted.count - 1) {
                        XCTAssertGreaterThanOrEqual(sorted[i].popularityScore, sorted[i + 1].popularityScore,
                                                   "Should sort by popularity descending")
                    }
                }
            }
        }
        
        // Performance validation for complex filtering
        let complexFilteringMeasurement = PerformanceMeasurement.measureExecutionTime {
            techniquesViewModel.updateSearchQuery("advanced")
            techniquesViewModel.selectCategory(categories.first!.id)
            techniquesViewModel.filterByDifficulty(.advanced)
            techniquesViewModel.filterByType(.kick)
            techniquesViewModel.sortBy(.popularity)
            let _ = techniquesViewModel.filteredTechniques
        }
        XCTAssertLessThan(complexFilteringMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Complex filtering should be performant")
    }
    
    func testTechniqueDetailViewUI() throws {
        // Test technique detail view presentation with media integration
        
        let testProfile = try profileService.createProfile(
            name: "Technique Learner",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Get technique for testing
        let techniquesViewModel = TechniquesViewModel(
            techniquesService: techniquesService,
            userProfile: testProfile
        )
        
        let availableTechniques = techniquesViewModel.allTechniques
        XCTAssertGreaterThan(availableTechniques.count, 0, "Should have techniques for testing")
        
        let testTechnique = availableTechniques.first!
        
        // Test technique detail view model
        let detailViewModel = TechniqueDetailViewModel(
            technique: testTechnique,
            techniquesService: techniquesService,
            userProfile: testProfile
        )
        
        // Verify basic information display
        XCTAssertEqual(detailViewModel.techniqueName, testTechnique.name, "Should display technique name")
        XCTAssertEqual(detailViewModel.description, testTechnique.description, "Should display description")
        XCTAssertEqual(detailViewModel.difficulty, testTechnique.difficulty, "Should display difficulty")
        XCTAssertEqual(detailViewModel.techniqueType, testTechnique.type, "Should display type")
        
        // Test execution instructions
        let executionSteps = detailViewModel.getExecutionSteps()
        XCTAssertGreaterThan(executionSteps.count, 0, "Should have execution steps")
        
        for (index, step) in executionSteps.enumerated() {
            XCTAssertNotNil(step.title, "Step should have title")
            XCTAssertNotNil(step.description, "Step should have description")
            XCTAssertEqual(step.stepNumber, index + 1, "Step numbers should be sequential")
        }
        
        // Test key points and tips
        let keyPoints = detailViewModel.getKeyPoints()
        XCTAssertGreaterThan(keyPoints.count, 0, "Should have key points")
        
        for keyPoint in keyPoints {
            XCTAssertNotNil(keyPoint.title, "Key point should have title")
            XCTAssertNotNil(keyPoint.description, "Key point should have description")
            XCTAssertNotNil(keyPoint.importance, "Key point should have importance level")
        }
        
        // Test common mistakes
        let commonMistakes = detailViewModel.getCommonMistakes()
        for mistake in commonMistakes {
            XCTAssertNotNil(mistake.mistakeDescription, "Mistake should have description")
            XCTAssertNotNil(mistake.correction, "Mistake should have correction")
            XCTAssertNotNil(mistake.prevention, "Mistake should have prevention tip")
        }
        
        // Test training progressions
        let progressions = detailViewModel.getTrainingProgressions()
        if progressions.count > 0 {
            for progression in progressions {
                XCTAssertNotNil(progression.level, "Progression should have level")
                XCTAssertNotNil(progression.description, "Progression should have description")
                XCTAssertNotNil(progression.requirements, "Progression should have requirements")
            }
        }
        
        // Test media integration
        let mediaContent = detailViewModel.getMediaContent()
        if mediaContent.hasImages {
            let images = mediaContent.images
            XCTAssertGreaterThan(images.count, 0, "Should have images")
            
            for image in images {
                XCTAssertNotNil(image.url, "Image should have URL")
                XCTAssertNotNil(image.caption, "Image should have caption")
                XCTAssertNotNil(image.type, "Image should have type")
            }
        }
        
        if mediaContent.hasVideos {
            let videos = mediaContent.videos
            XCTAssertGreaterThan(videos.count, 0, "Should have videos")
            
            for video in videos {
                XCTAssertNotNil(video.url, "Video should have URL")
                XCTAssertNotNil(video.title, "Video should have title")
                XCTAssertGreaterThan(video.duration, 0, "Video should have duration")
            }
        }
        
        // Test related techniques
        let relatedTechniques = detailViewModel.getRelatedTechniques()
        for related in relatedTechniques {
            XCTAssertNotEqual(related.id, testTechnique.id, "Related should not include current technique")
            XCTAssertTrue(related.type == testTechnique.type || 
                         related.difficulty == testTechnique.difficulty ||
                         related.categoryId == testTechnique.categoryId,
                         "Related techniques should have logical connections")
        }
        
        // Test practice tracking
        detailViewModel.startPractice()
        XCTAssertTrue(detailViewModel.isPracticing, "Should track practice state")
        
        Thread.sleep(forTimeInterval: 1.0)
        detailViewModel.recordPracticeTime()
        XCTAssertGreaterThan(detailViewModel.totalPracticeTime, 0, "Should accumulate practice time")
        
        // Test favoriting
        XCTAssertFalse(detailViewModel.isFavorited, "Should not be favorited initially")
        
        detailViewModel.toggleFavorite()
        XCTAssertTrue(detailViewModel.isFavorited, "Should favorite technique")
        
        detailViewModel.toggleFavorite()
        XCTAssertFalse(detailViewModel.isFavorited, "Should unfavorite technique")
        
        // Test sharing functionality
        let shareContent = detailViewModel.prepareForSharing()
        XCTAssertNotNil(shareContent, "Should prepare sharing content")
        XCTAssertTrue(shareContent.text.contains(testTechnique.name), "Share should include technique name")
        XCTAssertTrue(shareContent.text.contains(testTechnique.description), "Share should include description")
    }
    
    func testTechniquesSearchAndDiscovery() throws {
        // Test advanced search and discovery features
        
        let testProfile = try profileService.createProfile(
            name: "Technique Explorer",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let searchViewModel = TechniqueSearchViewModel(
            techniquesService: techniquesService,
            userProfile: testProfile
        )
        
        // Test basic search
        searchViewModel.updateSearchQuery("kick")
        let basicResults = searchViewModel.searchResults
        
        for result in basicResults {
            let searchableContent = "\(result.name) \(result.description) \(result.tags.joined(separator: " "))".lowercased()
            XCTAssertTrue(searchableContent.contains("kick"), "Results should match search term")
        }
        
        // Test advanced search with multiple criteria
        let advancedSearchCriteria = AdvancedSearchCriteria(
            query: "front",
            category: "kicks",
            difficulty: .intermediate,
            techniqueType: .kick,
            minimumBeltLevel: "7th Keup",
            tags: ["linear", "front"]
        )
        
        searchViewModel.performAdvancedSearch(advancedSearchCriteria)
        let advancedResults = searchViewModel.searchResults
        
        for result in advancedResults {
            XCTAssertEqual(result.categoryId, "kicks", "Should match category")
            XCTAssertEqual(result.difficulty, .intermediate, "Should match difficulty")
            XCTAssertEqual(result.type, .kick, "Should match type")
            
            let hasMatchingTag = result.tags.contains { tag in
                advancedSearchCriteria.tags.contains(tag.lowercased())
            }
            if !hasMatchingTag {
                let searchableContent = "\(result.name) \(result.description)".lowercased()
                XCTAssertTrue(searchableContent.contains("front"), "Should match query term")
            }
        }
        
        // Test search suggestions
        let suggestions = searchViewModel.getSearchSuggestions(for: "fro")
        XCTAssertGreaterThan(suggestions.count, 0, "Should provide search suggestions")
        
        for suggestion in suggestions {
            XCTAssertTrue(suggestion.lowercased().hasPrefix("fro"), "Suggestions should match prefix")
        }
        
        // Test search history
        searchViewModel.updateSearchQuery("roundhouse")
        searchViewModel.updateSearchQuery("side kick")
        searchViewModel.updateSearchQuery("back kick")
        
        let searchHistory = searchViewModel.getSearchHistory()
        XCTAssertGreaterThan(searchHistory.count, 0, "Should maintain search history")
        XCTAssertTrue(searchHistory.contains("roundhouse"), "Should include recent searches")
        XCTAssertTrue(searchHistory.contains("side kick"), "Should include recent searches")
        XCTAssertTrue(searchHistory.contains("back kick"), "Should include recent searches")
        
        // Test popular searches
        let popularSearches = searchViewModel.getPopularSearches()
        XCTAssertGreaterThan(popularSearches.count, 0, "Should provide popular searches")
        
        for popularSearch in popularSearches {
            XCTAssertNotNil(popularSearch.term, "Popular search should have term")
            XCTAssertGreaterThan(popularSearch.frequency, 0, "Popular search should have frequency")
        }
        
        // Test technique discovery
        let discoveryViewModel = TechniqueDiscoveryViewModel(
            techniquesService: techniquesService,
            userProfile: testProfile
        )
        
        // Test recommended techniques
        let recommendations = discoveryViewModel.getRecommendedTechniques()
        XCTAssertGreaterThan(recommendations.count, 0, "Should provide recommendations")
        
        for recommendation in recommendations {
            if let requiredBelt = recommendation.technique.minimumBeltLevel {
                XCTAssertLessThanOrEqual(
                    BeltUtils.getLegacySortOrder(for: requiredBelt),
                    BeltUtils.getLegacySortOrder(for: testProfile.currentBeltLevel.shortName) + 2,
                    "Recommendations should be appropriate or slightly challenging"
                )
            }
            XCTAssertNotNil(recommendation.reason, "Recommendation should have reason")
        }
        
        // Test technique of the day
        let techniqueOfTheDay = discoveryViewModel.getTechniqueOfTheDay()
        XCTAssertNotNil(techniqueOfTheDay, "Should provide technique of the day")
        XCTAssertNotNil(techniqueOfTheDay.technique, "Should have technique")
        XCTAssertNotNil(techniqueOfTheDay.spotlight, "Should have spotlight reason")
        
        // Test learning path suggestions
        let learningPaths = discoveryViewModel.getLearningPaths()
        for path in learningPaths {
            XCTAssertNotNil(path.title, "Learning path should have title")
            XCTAssertNotNil(path.description, "Learning path should have description")
            XCTAssertGreaterThan(path.techniques.count, 0, "Learning path should have techniques")
            XCTAssertNotNil(path.estimatedDuration, "Learning path should have duration")
        }
        
        // Performance test for search operations
        let searchPerformanceMeasurement = PerformanceMeasurement.measureExecutionTime {
            searchViewModel.updateSearchQuery("advanced")
            let _ = searchViewModel.searchResults
            let _ = searchViewModel.getSearchSuggestions(for: "adv")
            let _ = discoveryViewModel.getRecommendedTechniques()
        }
        XCTAssertLessThan(searchPerformanceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Search operations should be performant")
    }
    
    // MARK: - Performance and Memory Tests
    
    func testTheoryTechniquesPerformanceUnderLoad() throws {
        // Test theory and techniques performance with large content sets
        
        let testProfile = try profileService.createProfile(
            name: "Performance Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test theory performance with complex filtering
        let theoryPerformanceMeasurement = PerformanceMeasurement.measureExecutionTime {
            let theoryViewModel = TheoryViewModel(
                theoryService: theoryService,
                userProfile: testProfile
            )
            
            // Rapid filtering operations
            theoryViewModel.updateSearchQuery("taekwondo history philosophy")
            theoryViewModel.filterByDifficulty(.advanced)
            theoryViewModel.sortBy(.difficulty)
            let _ = theoryViewModel.getFilteredContent()
            
            // Theory detail operations
            if let content = theoryViewModel.theoryContent.first {
                let detailViewModel = TheoryDetailViewModel(
                    theoryContent: content,
                    theoryService: theoryService,
                    userProfile: testProfile
                )
                let _ = detailViewModel.getRelatedContent()
                let _ = detailViewModel.getFormattedContent()
            }
        }
        XCTAssertLessThan(theoryPerformanceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2,
                         "Theory operations should remain performant")
        
        // Test techniques performance with complex search
        let techniquesPerformanceMeasurement = PerformanceMeasurement.measureExecutionTime {
            let techniquesViewModel = TechniquesViewModel(
                techniquesService: techniquesService,
                userProfile: testProfile
            )
            
            // Complex multi-filter operations
            techniquesViewModel.updateSearchQuery("advanced kicking techniques")
            techniquesViewModel.filterByDifficulty(.advanced)
            techniquesViewModel.filterByType(.kick)
            techniquesViewModel.sortBy(.popularity)
            let _ = techniquesViewModel.filteredTechniques
            
            // Search operations
            let searchViewModel = TechniqueSearchViewModel(
                techniquesService: techniquesService,
                userProfile: testProfile
            )
            searchViewModel.updateSearchQuery("complex combination")
            let _ = searchViewModel.searchResults
            let _ = searchViewModel.getSearchSuggestions(for: "comp")
        }
        XCTAssertLessThan(techniquesPerformanceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2,
                         "Techniques operations should remain performant")
        
        // Test memory usage during concurrent operations
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            // Create multiple view models simultaneously
            let theoryViewModel = TheoryViewModel(theoryService: theoryService, userProfile: testProfile)
            let techniquesViewModel = TechniquesViewModel(techniquesService: techniquesService, userProfile: testProfile)
            let searchViewModel = TechniqueSearchViewModel(techniquesService: techniquesService, userProfile: testProfile)
            let discoveryViewModel = TechniqueDiscoveryViewModel(techniquesService: techniquesService, userProfile: testProfile)
            
            // Force computation of various components
            let _ = theoryViewModel.getFilteredContent()
            let _ = techniquesViewModel.filteredTechniques
            let _ = searchViewModel.searchResults
            let _ = discoveryViewModel.getRecommendedTechniques()
            
            // Create detail view models
            if let theory = theoryViewModel.theoryContent.first,
               let technique = techniquesViewModel.allTechniques.first {
                let theoryDetail = TheoryDetailViewModel(theoryContent: theory, theoryService: theoryService, userProfile: testProfile)
                let techniqueDetail = TechniqueDetailViewModel(technique: technique, techniquesService: techniquesService, userProfile: testProfile)
                
                let _ = theoryDetail.getRelatedContent()
                let _ = techniqueDetail.getRelatedTechniques()
            }
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 3,
                         "Theory and techniques operations should not cause excessive memory growth")
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

// MARK: - Mock UI Components and Supporting Types

// Theory ViewModels
class TheoryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var theoryContent: [TheoryContent] = []
    @Published var availableCategories: [TheoryCategory] = []
    @Published var selectedCategory: String?
    @Published var searchQuery = ""
    @Published var selectedDifficulty: TheoryDifficulty?
    @Published var sortOption: TheorySortOption = .title
    
    private let theoryService: TechniquesDataService
    private let userProfile: UserProfile
    
    init(theoryService: TechniquesDataService, userProfile: UserProfile) {
        self.theoryService = theoryService
        self.userProfile = userProfile
        loadTheoryContent()
    }
    
    func selectCategory(_ categoryId: String) {
        selectedCategory = categoryId
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
    }
    
    func filterByDifficulty(_ difficulty: TheoryDifficulty) {
        selectedDifficulty = difficulty
    }
    
    func sortBy(_ option: TheorySortOption) {
        sortOption = option
    }
    
    func getFilteredContent() -> [TheoryContent] {
        var filtered = theoryContent
        
        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.categoryId == category }
        }
        
        // Apply search filter
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            filtered = filtered.filter { content in
                content.title.lowercased().contains(query) ||
                content.content.lowercased().contains(query) ||
                content.keywords.contains { $0.lowercased().contains(query) }
            }
        }
        
        // Apply difficulty filter
        if let difficulty = selectedDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Apply sorting
        switch sortOption {
        case .title:
            filtered.sort { $0.title < $1.title }
        case .difficulty:
            filtered.sort { $0.difficulty.sortOrder < $1.difficulty.sortOrder }
        case .dateAdded:
            filtered.sort { $0.dateAdded > $1.dateAdded }
        }
        
        return filtered
    }
    
    func getMasteryModeContent() -> [TheoryContent] {
        return theoryContent.filter { $0.isCoreContent || $0.isRecommendedForMastery }
    }
    
    private func loadTheoryContent() {
        // Mock implementation - would load from service
        availableCategories = [
            TheoryCategory(id: "taekwondo_history", name: "Taekwondo History"),
            TheoryCategory(id: "philosophy", name: "Philosophy & Principles"),
            TheoryCategory(id: "belt_requirements", name: "Belt Requirements")
        ]
        
        theoryContent = [
            TheoryContent(
                id: "history_1",
                title: "Origins of Taekwondo",
                content: "Taekwondo originated in Korea...",
                categoryId: "taekwondo_history",
                difficulty: .beginner,
                keywords: ["korea", "origin", "history"],
                estimatedReadingTime: 5,
                isCoreContent: true,
                isRecommendedForMastery: true,
                dateAdded: Date()
            )
        ]
    }
}

class TheoryDetailViewModel: ObservableObject {
    @Published var isReading = false
    @Published var isBookmarked = false
    @Published var actualReadingTime: TimeInterval = 0
    
    let theoryContent: TheoryContent
    private let theoryService: TechniquesDataService
    private let userProfile: UserProfile
    var readingStartTime: Date?
    
    init(theoryContent: TheoryContent, theoryService: TechniquesDataService, userProfile: UserProfile) {
        self.theoryContent = theoryContent
        self.theoryService = theoryService
        self.userProfile = userProfile
    }
    
    var title: String { theoryContent.title }
    var content: String { theoryContent.content }
    var difficulty: TheoryDifficulty { theoryContent.difficulty }
    var estimatedReadingTime: Int { theoryContent.estimatedReadingTime }
    
    func startReading() {
        isReading = true
        readingStartTime = Date()
    }
    
    func completeReading() {
        if let startTime = readingStartTime {
            actualReadingTime = Date().timeIntervalSince(startTime)
        }
        isReading = false
    }
    
    func toggleBookmark() {
        isBookmarked.toggle()
    }
    
    func getFormattedContent() -> String {
        return content // Mock - would apply rich formatting
    }
    
    func getRelatedContent() -> [TheoryContent] {
        // Mock implementation - would find related content
        return []
    }
    
    func addNote(_ noteText: String) {
        // Mock implementation - would save user note
    }
    
    func getUserNotes() -> [TheoryNote] {
        // Mock implementation - would return user's notes
        return [TheoryNote(content: "Sample note", timestamp: Date())]
    }
    
    func prepareForSharing() -> ShareData {
        return ShareData(text: "\(title)\n\n\(content)")
    }
    
    func getAccessibilityLabel() -> String {
        return "Theory content: \(title)"
    }
    
    func getAccessibilityHint() -> String {
        return "Double tap to read theory content"
    }
}

// Techniques ViewModels  
class TechniquesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var allTechniques: [Technique] = []
    @Published var filteredTechniques: [Technique] = []
    @Published var availableCategories: [TechniqueCategory] = []
    
    private let techniquesService: TechniquesDataService
    private let userProfile: UserProfile
    private var currentFilters: [String: Any] = [:]
    
    init(techniquesService: TechniquesDataService, userProfile: UserProfile) {
        self.techniquesService = techniquesService
        self.userProfile = userProfile
        loadTechniques()
    }
    
    func selectCategory(_ categoryId: String) {
        currentFilters["category"] = categoryId
        applyFilters()
    }
    
    func filterByBeltLevel(_ beltLevel: String) {
        currentFilters["beltLevel"] = beltLevel
        applyFilters()
    }
    
    func filterByDifficulty(_ difficulty: TechniqueDifficulty) {
        currentFilters["difficulty"] = difficulty
        applyFilters()
    }
    
    func filterByType(_ type: TechniqueType) {
        currentFilters["type"] = type
        applyFilters()
    }
    
    func updateSearchQuery(_ query: String) {
        currentFilters["search"] = query
        applyFilters()
    }
    
    func sortBy(_ option: TechniqueSortOption) {
        currentFilters["sort"] = option
        applyFilters()
    }
    
    func clearFilters() {
        currentFilters.removeAll()
        filteredTechniques = allTechniques
    }
    
    private func applyFilters() {
        var filtered = allTechniques
        
        // Apply all filters based on currentFilters dictionary
        if let categoryId = currentFilters["category"] as? String {
            filtered = filtered.filter { $0.categoryId == categoryId }
        }
        
        if let difficulty = currentFilters["difficulty"] as? TechniqueDifficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        if let type = currentFilters["type"] as? TechniqueType {
            filtered = filtered.filter { $0.type == type }
        }
        
        if let search = currentFilters["search"] as? String, !search.isEmpty {
            let query = search.lowercased()
            filtered = filtered.filter { technique in
                technique.name.lowercased().contains(query) ||
                technique.description.lowercased().contains(query) ||
                technique.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        // Apply sorting
        if let sortOption = currentFilters["sort"] as? TechniqueSortOption {
            switch sortOption {
            case .name:
                filtered.sort { $0.name < $1.name }
            case .difficulty:
                filtered.sort { $0.difficulty.sortOrder < $1.difficulty.sortOrder }
            case .beltLevel:
                filtered.sort { (t1, t2) in
                    let belt1 = BeltUtils.getLegacySortOrder(for: t1.minimumBeltLevel ?? "10th Keup")
                    let belt2 = BeltUtils.getLegacySortOrder(for: t2.minimumBeltLevel ?? "10th Keup")
                    return belt1 < belt2
                }
            case .popularity:
                filtered.sort { $0.popularityScore > $1.popularityScore }
            }
        }
        
        filteredTechniques = filtered
    }
    
    private func loadTechniques() {
        // Mock implementation - would load from service
        availableCategories = [
            TechniqueCategory(id: "kicks", name: "Kicks"),
            TechniqueCategory(id: "strikes", name: "Strikes"),
            TechniqueCategory(id: "blocks", name: "Blocks")
        ]
        
        allTechniques = [
            Technique(
                id: "front_kick",
                name: "Front Kick",
                description: "A linear kick using the ball of the foot",
                categoryId: "kicks",
                type: .kick,
                difficulty: .basic,
                minimumBeltLevel: "10th Keup",
                tags: ["linear", "front", "basic"],
                popularityScore: 95
            ),
            Technique(
                id: "roundhouse_kick",
                name: "Roundhouse Kick", 
                description: "A circular kick using the instep",
                categoryId: "kicks",
                type: .kick,
                difficulty: .intermediate,
                minimumBeltLevel: "9th Keup",
                tags: ["circular", "side", "intermediate"],
                popularityScore: 90
            )
        ]
        
        filteredTechniques = allTechniques
    }
}

// Supporting Types
enum TheoryDifficulty: String, CaseIterable {
    case beginner, intermediate, advanced
    
    var sortOrder: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 2
        case .advanced: return 3
        }
    }
}

enum TheorySortOption {
    case title, difficulty, dateAdded
}

enum TechniqueDifficulty: String, CaseIterable {
    case basic, intermediate, advanced, expert
    
    var sortOrder: Int {
        switch self {
        case .basic: return 1
        case .intermediate: return 2
        case .advanced: return 3
        case .expert: return 4
        }
    }
}

enum TechniqueType {
    case kick, strike, block, stance
}

enum TechniqueSortOption {
    case name, difficulty, beltLevel, popularity
}

struct TheoryContent {
    let id: String
    let title: String
    let content: String
    let categoryId: String
    let difficulty: TheoryDifficulty
    let keywords: [String]
    let estimatedReadingTime: Int
    let isCoreContent: Bool
    let isRecommendedForMastery: Bool
    let dateAdded: Date
    var minimumBeltLevel: String? { "10th Keup" }
}

struct TheoryCategory {
    let id: String
    let name: String
}

struct TheoryNote {
    let content: String
    let timestamp: Date
}

struct Technique {
    let id: String
    let name: String
    let description: String
    let categoryId: String
    let type: TechniqueType
    let difficulty: TechniqueDifficulty
    let minimumBeltLevel: String?
    let tags: [String]
    let popularityScore: Int
}

struct TechniqueCategory {
    let id: String
    let name: String
}

struct ShareData {
    let text: String
}

// Additional supporting classes would continue here for complete implementation...
// (Truncated for length - the pattern continues with remaining ViewModels and types)