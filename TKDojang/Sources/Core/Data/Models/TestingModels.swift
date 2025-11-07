import Foundation
import SwiftData

/**
 * TestingModels.swift
 * 
 * PURPOSE: Data models for the multiple choice testing system
 * 
 * ARCHITECTURE:
 * - TestSession: Represents a complete test session with configuration and results
 * - TestQuestion: Individual question with options and correct answer
 * - TestResult: Performance analytics and study recommendations
 * - TestPerformance: Historical performance tracking at different granularities
 */

// MARK: - Test Session Management

@Model
class TestSession {
    /// Unique identifier for the test session
    var id: UUID
    
    /// Type of test being conducted
    var testType: TestType
    
    /// User's belt level when test was taken
    var userBeltLevel: BeltLevel?
    
    /// Specific categories included in this test
    private var categoriesString: String = ""
    
    var categories: [String] {
        get {
            categoriesString.isEmpty ? [] : categoriesString.components(separatedBy: ",")
        }
        set {
            categoriesString = newValue.joined(separator: ",")
        }
    }
    
    /// Configuration settings for this test
    var configuration: TestConfiguration
    
    /// All questions in this test session
    @Relationship(deleteRule: .cascade)
    var questions: [TestQuestion]
    
    /// Timestamp when test was started
    var startedAt: Date
    
    /// Timestamp when test was completed (nil if in progress)
    var completedAt: Date?
    
    /// Current question index (for pause/resume functionality)
    var currentQuestionIndex: Int
    
    /// Overall test results and analytics
    var result: TestResult?
    
    init(testType: TestType, userBeltLevel: BeltLevel, categories: [String], configuration: TestConfiguration) {
        self.id = UUID()
        self.testType = testType
        self.userBeltLevel = userBeltLevel
        self.categoriesString = categories.joined(separator: ",")
        self.configuration = configuration
        self.questions = []
        self.startedAt = Date()
        self.completedAt = nil
        self.currentQuestionIndex = 0
        self.result = nil
    }
    
    /// Check if test is completed
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    /// Calculate current progress percentage
    var progressPercentage: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count) * 100
    }
}

// MARK: - Test Configuration

@Model
class TestConfiguration {
    /// Maximum number of questions in the test
    var maxQuestions: Int
    
    /// Belt levels to include in question pool
    private var includedBeltLevelsString: String = ""
    
    var includedBeltLevels: [String] {
        get {
            includedBeltLevelsString.isEmpty ? [] : includedBeltLevelsString.components(separatedBy: ",")
        }
        set {
            includedBeltLevelsString = newValue.joined(separator: ",")
        }
    }
    
    /// Categories to focus on (empty means all categories)
    private var focusCategoriesString: String = ""
    
    var focusCategories: [String] {
        get {
            focusCategoriesString.isEmpty ? [] : focusCategoriesString.components(separatedBy: ",")
        }
        set {
            focusCategoriesString = newValue.joined(separator: ",")
        }
    }
    
    /// Whether to include time limits
    var hasTimeLimit: Bool
    
    /// Time limit per question in seconds (if hasTimeLimit is true)
    var timePerQuestionSeconds: Int
    
    /// Question types to include
    var questionTypes: [QuestionType]
    
    init(
        maxQuestions: Int,
        includedBeltLevels: [String],
        focusCategories: [String] = [],
        hasTimeLimit: Bool = false,
        timePerQuestionSeconds: Int = 30,
        questionTypes: [QuestionType] = [.englishToKorean, .koreanToEnglish]
    ) {
        self.maxQuestions = maxQuestions
        self.includedBeltLevelsString = includedBeltLevels.joined(separator: ",")
        self.focusCategoriesString = focusCategories.joined(separator: ",")
        self.hasTimeLimit = hasTimeLimit
        self.timePerQuestionSeconds = timePerQuestionSeconds
        self.questionTypes = questionTypes
    }
}

// MARK: - Individual Test Question

@Model
class TestQuestion {
    /// Unique identifier for the question
    var id: UUID
    
    /// Reference to the terminology entry this question is based on
    var terminologyEntry: TerminologyEntry?
    
    /// Type of question (English→Korean, Korean→English, etc.)
    var questionType: QuestionType
    
    /// The question text displayed to user
    var questionText: String
    
    /// Four possible answers (including one correct answer)
    private var optionsString: String = ""
    
    var options: [String] {
        get {
            optionsString.isEmpty ? [] : optionsString.components(separatedBy: "|||")
        }
        set {
            optionsString = newValue.joined(separator: "|||")
        }
    }
    
    /// Index of the correct answer in the options array
    var correctAnswerIndex: Int
    
    /// Index of the user's selected answer (nil if not answered)
    var userAnswerIndex: Int?
    
    /// Whether the user answered correctly
    var isCorrect: Bool {
        return userAnswerIndex == correctAnswerIndex
    }
    
    /// Time taken to answer this question (in seconds)
    var timeToAnswerSeconds: Double?
    
    /// Timestamp when question was presented
    var presentedAt: Date?
    
    /// Timestamp when question was answered
    var answeredAt: Date?
    
    init(
        terminologyEntry: TerminologyEntry,
        questionType: QuestionType,
        questionText: String,
        options: [String],
        correctAnswerIndex: Int
    ) {
        self.id = UUID()
        self.terminologyEntry = terminologyEntry
        self.questionType = questionType
        self.questionText = questionText
        self.optionsString = options.joined(separator: "|||")
        self.correctAnswerIndex = correctAnswerIndex
        self.userAnswerIndex = nil
        self.timeToAnswerSeconds = nil
        self.presentedAt = nil
        self.answeredAt = nil
    }
    
    /// Record user's answer and timing
    func recordAnswer(_ answerIndex: Int) {
        self.userAnswerIndex = answerIndex
        self.answeredAt = Date()
        
        if let presentedTime = presentedAt {
            self.timeToAnswerSeconds = Date().timeIntervalSince(presentedTime)
        }
    }
    
    /// Mark question as presented
    func markAsPresented() {
        self.presentedAt = Date()
    }
}

// MARK: - Test Results and Analytics

@Model
class TestResult {
    /// Unique identifier for the result
    var id: UUID
    
    /// Total number of questions in the test
    var totalQuestions: Int
    
    /// Number of questions answered correctly
    var correctAnswers: Int
    
    /// Overall accuracy percentage
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    /// Total time taken for the test (in seconds)
    var totalTimeSeconds: Double
    
    /// Average time per question
    var averageTimePerQuestion: Double {
        guard totalQuestions > 0 else { return 0 }
        return totalTimeSeconds / Double(totalQuestions)
    }
    
    /// Performance breakdown by category
    var categoryPerformance: [CategoryPerformance]
    
    /// Performance breakdown by belt level
    var beltLevelPerformance: [BeltLevelPerformance]
    
    /// Areas that need improvement
    private var weakAreasString: String = ""
    
    var weakAreas: [String] {
        get {
            weakAreasString.isEmpty ? [] : weakAreasString.components(separatedBy: "|||")
        }
        set {
            weakAreasString = newValue.joined(separator: "|||")
        }
    }
    
    /// Recommended study topics
    private var studyRecommendationsString: String = ""
    
    var studyRecommendations: [String] {
        get {
            studyRecommendationsString.isEmpty ? [] : studyRecommendationsString.components(separatedBy: "|||")
        }
        set {
            studyRecommendationsString = newValue.joined(separator: "|||")
        }
    }
    
    /// Achievement unlocked (if any)
    var achievement: String?
    
    init(
        totalQuestions: Int,
        correctAnswers: Int,
        totalTimeSeconds: Double,
        categoryPerformance: [CategoryPerformance],
        beltLevelPerformance: [BeltLevelPerformance],
        weakAreas: [String],
        studyRecommendations: [String],
        achievement: String? = nil
    ) {
        self.id = UUID()
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
        self.totalTimeSeconds = totalTimeSeconds
        self.categoryPerformance = categoryPerformance
        self.beltLevelPerformance = beltLevelPerformance
        self.weakAreasString = weakAreas.joined(separator: "|||")
        self.studyRecommendationsString = studyRecommendations.joined(separator: "|||")
        self.achievement = achievement
    }
}

// MARK: - Performance Analytics

@Model
class CategoryPerformance {
    /// Category name (basics, techniques, numbers, etc.)
    var category: String
    
    /// Number of questions in this category
    var totalQuestions: Int
    
    /// Number of correct answers in this category
    var correctAnswers: Int
    
    /// Accuracy percentage for this category
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    init(category: String, totalQuestions: Int, correctAnswers: Int) {
        self.category = category
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
    }
}

@Model
class BeltLevelPerformance {
    /// Belt level name
    var beltLevel: String
    
    /// Number of questions from this belt level
    var totalQuestions: Int
    
    /// Number of correct answers from this belt level
    var correctAnswers: Int
    
    /// Accuracy percentage for this belt level
    var accuracy: Double {
        guard totalQuestions > 0 else { return 0 }
        return Double(correctAnswers) / Double(totalQuestions) * 100
    }
    
    init(beltLevel: String, totalQuestions: Int, correctAnswers: Int) {
        self.beltLevel = beltLevel
        self.totalQuestions = totalQuestions
        self.correctAnswers = correctAnswers
    }
}

// MARK: - Historical Performance Tracking

@Model
class TestPerformance {
    /// Unique identifier
    var id: UUID
    
    /// User's belt level during this performance period
    var userBeltLevel: BeltLevel?
    
    /// Overall accuracy across all tests
    var overallAccuracy: Double
    
    /// Accuracy by category
    var categoryAccuracies: [String: Double]
    
    /// Accuracy by belt level
    var beltLevelAccuracies: [String: Double]
    
    /// Number of tests completed
    var testsCompleted: Int
    
    /// Streak of consecutive days with tests
    var dailyTestStreak: Int
    
    /// Last test completion date
    var lastTestDate: Date?
    
    /// Date this performance record was created
    var createdAt: Date
    
    /// Date this performance record was last updated
    var updatedAt: Date
    
    init(userBeltLevel: BeltLevel) {
        self.id = UUID()
        self.userBeltLevel = userBeltLevel
        self.overallAccuracy = 0.0
        self.categoryAccuracies = [:]
        self.beltLevelAccuracies = [:]
        self.testsCompleted = 0
        self.dailyTestStreak = 0
        self.lastTestDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Enums

enum TestType: String, CaseIterable, Codable {
    case comprehensive = "comprehensive"
    case quick = "quick"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .comprehensive:
            return "Comprehensive Test"
        case .quick:
            return "Quick Test"
        case .custom:
            return "Custom Test"
        }
    }
    
    var description: String {
        switch self {
        case .comprehensive:
            return "All questions for your current belt level"
        case .quick:
            return "5-10 questions for quick practice"
        case .custom:
            return "Customized test with your preferences"
        }
    }
}

enum QuestionType: String, CaseIterable, Codable {
    case englishToKorean = "english_to_korean"
    case koreanToEnglish = "korean_to_english"
    case definitionToTerm = "definition_to_term"
    case audioRecognition = "audio_recognition"

    var displayName: String {
        switch self {
        case .englishToKorean:
            return "English → Korean"
        case .koreanToEnglish:
            return "Korean → English"
        case .definitionToTerm:
            return "Definition → Term"
        case .audioRecognition:
            return "Audio Recognition"
        }
    }
}

// MARK: - UI Configuration (View Layer)

/**
 * TestUIConfig
 *
 * PURPOSE: Lightweight configuration struct for the test configuration UI
 * WHY: Separates view-layer configuration from data-layer TestConfiguration model
 * USAGE: MultipleChoiceConfigurationView → TestUIConfig → TestingService converts to TestConfiguration
 */
struct TestUIConfig {
    enum BeltScope: String, CaseIterable {
        case currentOnly = "current"
        case allUpToCurrent = "all_up_to_current"

        var displayName: String {
            switch self {
            case .currentOnly:
                return "Current Belt Only"
            case .allUpToCurrent:
                return "All Belts Up to Current"
            }
        }

        var description: String {
            switch self {
            case .currentOnly:
                return "Questions from your current belt level only"
            case .allUpToCurrent:
                return "Questions from white belt through your current belt"
            }
        }
    }

    var testType: TestType
    var questionCount: Int?  // Only used for .custom type
    var beltScope: BeltScope

    /// Default configuration for Quick test
    static var quick: TestUIConfig {
        TestUIConfig(testType: .quick, questionCount: nil, beltScope: .currentOnly)
    }

    /// Default configuration for Comprehensive test
    static var comprehensive: TestUIConfig {
        TestUIConfig(testType: .comprehensive, questionCount: nil, beltScope: .currentOnly)
    }

    /// Create custom test configuration
    static func custom(questionCount: Int, beltScope: BeltScope = .currentOnly) -> TestUIConfig {
        TestUIConfig(testType: .custom, questionCount: questionCount, beltScope: beltScope)
    }
}