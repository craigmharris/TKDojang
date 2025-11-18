import Foundation
import SwiftData

/**
 * TestingService.swift
 * 
 * PURPOSE: Service for managing test creation, question generation, and result analytics
 * 
 * FEATURES:
 * - Intelligent question generation with smart distractors
 * - Test session management (start, pause, resume, complete)
 * - Performance analytics and study recommendations
 * - Integration with existing flashcard spaced repetition system
 */

@MainActor
class TestingService: ObservableObject {
    private let modelContext: ModelContext
    private let terminologyService: TerminologyDataService
    
    init(modelContext: ModelContext, terminologyService: TerminologyDataService) {
        self.modelContext = modelContext
        self.terminologyService = terminologyService
    }
    
    // MARK: - Test Creation
    
    /**
     * Creates a comprehensive test for the user's belt level(s)
     * Includes all terminology from selected belt scope
     *
     * - Parameters:
     *   - userProfile: The user taking the test
     *   - beltScope: Which belt levels to include (.currentOnly or .allUpToCurrent)
     */
    func createComprehensiveTest(for userProfile: UserProfile, beltScope: TestUIConfig.BeltScope = .currentOnly) throws -> TestSession {
        let beltLevel = userProfile.currentBeltLevel
        DebugLogger.data("📚 TestingService: Creating comprehensive test for belt=\(beltLevel.shortName), scope=\(beltScope.rawValue)")

        // Get terminology based on belt scope
        let (terminology, includedBelts) = getTerminologyForBeltScope(beltLevel, scope: beltScope)
        DebugLogger.data("📊 TestingService: Retrieved \(terminology.count) terms, belts=\(includedBelts)")

        let configuration = TestConfiguration(
            maxQuestions: terminology.count,
            includedBeltLevels: includedBelts,
            focusCategories: [],
            hasTimeLimit: false,
            questionTypes: [.englishToKorean, .koreanToEnglish]
        )

        let testSession = TestSession(
            testType: .comprehensive,
            userBeltLevel: beltLevel,
            categories: Array(Set(terminology.map { $0.category.name })),
            configuration: configuration
        )

        // Generate questions for all terminology
        DebugLogger.data("🔄 TestingService: Generating questions from \(terminology.count) terms...")
        let questions = try generateQuestions(from: terminology, configuration: configuration)
        DebugLogger.data("✅ TestingService: Generated \(questions.count) questions")
        testSession.questions = questions.shuffled() // Randomize order

        modelContext.insert(testSession)
        try modelContext.save()
        DebugLogger.data("💾 TestingService: Test session saved with \(testSession.questions.count) questions")

        return testSession
    }
    
    /**
     * Creates a quick test with 5-10 questions
     * Uses current belt + previous belt if current belt has < 5 questions
     */
    func createQuickTest(for userProfile: UserProfile) throws -> TestSession {
        let currentBelt = userProfile.currentBeltLevel
        DebugLogger.data("⚡ TestingService: Creating quick test for belt=\(currentBelt.shortName)")

        var terminology = getTerminologyForBelt(currentBelt)
        var includedBelts = [currentBelt.shortName.replacingOccurrences(of: " ", with: "_").lowercased()]
        DebugLogger.data("📊 TestingService: Found \(terminology.count) terms for current belt")

        // If current belt has fewer than 3 terms, include previous belt
        if terminology.count < 3 {
            DebugLogger.data("⚠️ TestingService: Current belt has < 3 terms, looking for previous belt...")
            if let previousBelt = getPreviousBelt(from: currentBelt) {
                let previousTerminology = getTerminologyForBelt(previousBelt)
                terminology.append(contentsOf: previousTerminology)
                includedBelts.append(previousBelt.shortName.replacingOccurrences(of: " ", with: "_").lowercased())
                DebugLogger.data("✅ TestingService: Added \(previousTerminology.count) terms from previous belt (\(previousBelt.shortName))")
            }
        }

        let configuration = TestConfiguration(
            maxQuestions: 10,  // Will select 5-10 from generated pool
            includedBeltLevels: includedBelts,
            focusCategories: [],
            hasTimeLimit: false,
            questionTypes: [.englishToKorean, .koreanToEnglish]
        )

        // Generate ALL possible questions from available terminology (both directions)
        // This creates a large pool to select from, preventing paired questions
        DebugLogger.data("🔄 TestingService: Generating questions from \(terminology.count) terms...")
        let allQuestions = try generateQuestions(from: terminology, configuration: configuration)
        DebugLogger.data("✅ TestingService: Generated \(allQuestions.count) questions")

        // Randomly select 5-10 questions from the full pool
        // This ensures better variation and prevents answer hints
        let questionCount = min(10, max(5, allQuestions.count))
        let selectedQuestions = Array(allQuestions.shuffled().prefix(questionCount))
        DebugLogger.data("🎲 TestingService: Selected \(selectedQuestions.count) questions for quick test")

        let testSession = TestSession(
            testType: .quick,
            userBeltLevel: currentBelt,
            categories: Array(Set(selectedQuestions.compactMap { $0.terminologyEntry?.category.name })),
            configuration: configuration
        )

        testSession.questions = selectedQuestions

        modelContext.insert(testSession)
        try modelContext.save()
        DebugLogger.data("💾 TestingService: Quick test session saved with \(testSession.questions.count) questions")

        return testSession
    }

    /**
     * Creates a custom test with user-specified parameters
     *
     * - Parameters:
     *   - userProfile: The user taking the test
     *   - questionCount: Number of questions to generate (10-25)
     *   - beltScope: Which belt levels to include (.currentOnly or .allUpToCurrent)
     */
    func createCustomTest(for userProfile: UserProfile, questionCount: Int, beltScope: TestUIConfig.BeltScope) throws -> TestSession {
        let beltLevel = userProfile.currentBeltLevel
        DebugLogger.data("🎨 TestingService: Creating custom test for belt=\(beltLevel.shortName), questionCount=\(questionCount), scope=\(beltScope.rawValue)")

        // Get terminology based on belt scope
        let (terminology, includedBelts) = getTerminologyForBeltScope(beltLevel, scope: beltScope)
        DebugLogger.data("📊 TestingService: Retrieved \(terminology.count) terms, belts=\(includedBelts)")

        guard !terminology.isEmpty else {
            DebugLogger.data("❌ TestingService: No terminology available for custom test")
            throw TestingError.noQuestionsAvailable
        }

        let configuration = TestConfiguration(
            maxQuestions: questionCount,
            includedBeltLevels: includedBelts,
            focusCategories: [],
            hasTimeLimit: false,
            questionTypes: [.englishToKorean, .koreanToEnglish]
        )

        // Generate ALL possible questions from available terminology (both directions)
        DebugLogger.data("🔄 TestingService: Generating questions from \(terminology.count) terms...")
        let allQuestions = try generateQuestions(from: terminology, configuration: configuration)
        DebugLogger.data("✅ TestingService: Generated \(allQuestions.count) questions")

        guard !allQuestions.isEmpty else {
            DebugLogger.data("❌ TestingService: Question generation returned 0 questions")
            throw TestingError.noQuestionsAvailable
        }

        // Select requested number of questions from the pool
        let actualQuestionCount = min(questionCount, allQuestions.count)
        let selectedQuestions = Array(allQuestions.shuffled().prefix(actualQuestionCount))
        DebugLogger.data("🎲 TestingService: Selected \(selectedQuestions.count) of \(allQuestions.count) questions for custom test")

        let testSession = TestSession(
            testType: .custom,
            userBeltLevel: beltLevel,
            categories: Array(Set(selectedQuestions.compactMap { $0.terminologyEntry?.category.name })),
            configuration: configuration
        )

        testSession.questions = selectedQuestions

        modelContext.insert(testSession)
        try modelContext.save()
        DebugLogger.data("💾 TestingService: Custom test session saved with \(testSession.questions.count) questions")

        return testSession
    }

    // MARK: - Question Generation
    
    /**
     * Generates test questions with smart distractors
     * Creates both English→Korean and Korean→English questions
     */
    private func generateQuestions(from terminology: [TerminologyEntry], configuration: TestConfiguration) throws -> [TestQuestion] {
        var questions: [TestQuestion] = []
        
        for entry in terminology {
            // Generate English→Korean question
            if configuration.questionTypes.contains(.englishToKorean) {
                if let question = try generateEnglishToKoreanQuestion(from: entry, allTerminology: terminology) {
                    questions.append(question)
                }
            }
            
            // Generate Korean→English question  
            if configuration.questionTypes.contains(.koreanToEnglish) {
                if let question = try generateKoreanToEnglishQuestion(from: entry, allTerminology: terminology) {
                    questions.append(question)
                }
            }
        }
        
        return questions
    }
    
    /**
     * Generates English→Korean question with smart distractors
     * Shows English term, user picks correct Korean (romanised)
     */
    private func generateEnglishToKoreanQuestion(from entry: TerminologyEntry, allTerminology: [TerminologyEntry]) throws -> TestQuestion? {
        let questionText = "What is the Korean term for:"
        let correctAnswer = entry.romanisedPronunciation
        
        // Generate 3 distractors from same category and belt level
        let distractors = generateSmartDistractors(
            correctAnswer: correctAnswer,
            sourceEntry: entry,
            allTerminology: allTerminology,
            extractionMethod: { $0.romanisedPronunciation }
        )
        
        guard distractors.count == 3 else {
            DebugLogger.data("⚠️ Could not generate enough distractors for: \(entry.englishTerm)")
            return nil
        }
        
        // Create options array with correct answer and distractors
        var options = distractors
        let correctIndex = Int.random(in: 0...3)
        options.insert(correctAnswer, at: correctIndex)
        
        return TestQuestion(
            terminologyEntry: entry,
            questionType: .englishToKorean,
            questionText: questionText,
            options: options,
            correctAnswerIndex: correctIndex
        )
    }
    
    /**
     * Generates Korean→English question with smart distractors
     * Shows Korean (romanised + hangul), user picks correct English term
     */
    private func generateKoreanToEnglishQuestion(from entry: TerminologyEntry, allTerminology: [TerminologyEntry]) throws -> TestQuestion? {
        let questionText = "What does this Korean term mean?"
        let correctAnswer = entry.englishTerm
        
        // Generate 3 distractors from same category and belt level
        let distractors = generateSmartDistractors(
            correctAnswer: correctAnswer,
            sourceEntry: entry,
            allTerminology: allTerminology,
            extractionMethod: { $0.englishTerm }
        )
        
        guard distractors.count == 3 else {
            DebugLogger.data("⚠️ Could not generate enough distractors for: \(entry.englishTerm)")
            return nil
        }
        
        // Create options array with correct answer and distractors
        var options = distractors
        let correctIndex = Int.random(in: 0...3)
        options.insert(correctAnswer, at: correctIndex)
        
        return TestQuestion(
            terminologyEntry: entry,
            questionType: .koreanToEnglish,
            questionText: questionText,
            options: options,
            correctAnswerIndex: correctIndex
        )
    }
    
    /**
     * Generates smart distractors that are plausible but incorrect
     * Priority: Same category > Same belt level > Any terminology
     */
    private func generateSmartDistractors(
        correctAnswer: String,
        sourceEntry: TerminologyEntry,
        allTerminology: [TerminologyEntry],
        extractionMethod: (TerminologyEntry) -> String
    ) -> [String] {
        // Filter out the correct answer
        let availableTerminology = allTerminology.filter { extractionMethod($0) != correctAnswer }
        
        var distractors: [String] = []
        
        // Priority 1: Same category and belt level
        let sameCategoryBelt = availableTerminology.filter { 
            $0.category.name == sourceEntry.category.name && 
            $0.beltLevel.sortOrder == sourceEntry.beltLevel.sortOrder 
        }
        distractors.append(contentsOf: sameCategoryBelt.shuffled().prefix(2).map(extractionMethod))
        
        // Priority 2: Same category, different belt
        if distractors.count < 3 {
            let sameCategory = availableTerminology.filter { 
                $0.category.name == sourceEntry.category.name &&
                !distractors.contains(extractionMethod($0))
            }
            let needed = 3 - distractors.count
            distractors.append(contentsOf: sameCategory.shuffled().prefix(needed).map(extractionMethod))
        }
        
        // Priority 3: Same belt level, different category
        if distractors.count < 3 {
            let sameBelt = availableTerminology.filter { 
                $0.beltLevel.sortOrder == sourceEntry.beltLevel.sortOrder &&
                !distractors.contains(extractionMethod($0))
            }
            let needed = 3 - distractors.count
            distractors.append(contentsOf: sameBelt.shuffled().prefix(needed).map(extractionMethod))
        }
        
        // Priority 4: Any remaining terminology
        if distractors.count < 3 {
            let remaining = availableTerminology.filter { !distractors.contains(extractionMethod($0)) }
            let needed = 3 - distractors.count
            distractors.append(contentsOf: remaining.shuffled().prefix(needed).map(extractionMethod))
        }
        
        return Array(distractors.prefix(3))
    }
    
    // MARK: - Test Session Management
    
    /**
     * Records user's answer for a question and handles flashcard integration
     */
    func recordAnswer(for question: TestQuestion, answerIndex: Int) throws {
        question.recordAnswer(answerIndex)
        
        // If answer is wrong, add to flashcard review queue
        if !question.isCorrect, let terminologyEntry = question.terminologyEntry {
            try terminologyService.addToReviewQueue(terminologyEntry)
        }
        
        try modelContext.save()
    }
    
    /**
     * Completes a test session and generates results
     */
    func completeTest(session: TestSession, for userProfile: UserProfile? = nil) throws -> TestResult {
        session.completedAt = Date()
        
        let result = generateTestResult(for: session)
        session.result = result
        
        // Update user's historical performance
        try updatePerformanceHistory(with: result, session: session, userProfile: userProfile)
        
        try modelContext.save()
        return result
    }
    
    // MARK: - Result Analytics
    
    /**
     * Generates comprehensive test results with analytics and recommendations
     */
    private func generateTestResult(for session: TestSession) -> TestResult {
        let questions = session.questions
        let correctAnswers = questions.filter { $0.isCorrect }.count
        let totalTime = questions.compactMap { $0.timeToAnswerSeconds }.reduce(0, +)
        
        // Calculate category performance
        let categoryPerformance = generateCategoryPerformance(questions: questions)
        
        // Calculate belt level performance
        let beltLevelPerformance = generateBeltLevelPerformance(questions: questions)
        
        // Identify weak areas
        let weakAreas = identifyWeakAreas(categoryPerformance: categoryPerformance, beltLevelPerformance: beltLevelPerformance)
        
        // Generate study recommendations
        let studyRecommendations = generateStudyRecommendations(
            weakAreas: weakAreas,
            incorrectQuestions: questions.filter { !$0.isCorrect }
        )
        
        // Check for achievements
        let achievement = checkForAchievements(correctAnswers: correctAnswers, totalQuestions: questions.count)
        
        return TestResult(
            totalQuestions: questions.count,
            correctAnswers: correctAnswers,
            totalTimeSeconds: totalTime,
            categoryPerformance: categoryPerformance,
            beltLevelPerformance: beltLevelPerformance,
            weakAreas: weakAreas,
            studyRecommendations: studyRecommendations,
            achievement: achievement
        )
    }
    
    private func generateCategoryPerformance(questions: [TestQuestion]) -> [CategoryPerformance] {
        let categoryGroups = Dictionary(grouping: questions) { $0.terminologyEntry?.category.name ?? "general" }
        
        return categoryGroups.map { (category, questions) in
            let correct = questions.filter { $0.isCorrect }.count
            return CategoryPerformance(category: category, totalQuestions: questions.count, correctAnswers: correct)
        }
    }
    
    private func generateBeltLevelPerformance(questions: [TestQuestion]) -> [BeltLevelPerformance] {
        let beltGroups = Dictionary(grouping: questions) { $0.terminologyEntry?.beltLevel.shortName ?? "Unknown" }
        
        return beltGroups.map { (belt, questions) in
            let correct = questions.filter { $0.isCorrect }.count
            return BeltLevelPerformance(beltLevel: belt, totalQuestions: questions.count, correctAnswers: correct)
        }
    }
    
    private func identifyWeakAreas(categoryPerformance: [CategoryPerformance], beltLevelPerformance: [BeltLevelPerformance]) -> [String] {
        var weakAreas: [String] = []
        
        // Categories with < 70% accuracy
        for category in categoryPerformance {
            if category.accuracy < 70 {
                weakAreas.append("\(category.category) (\(Int(category.accuracy))% accuracy)")
            }
        }
        
        return weakAreas
    }
    
    private func generateStudyRecommendations(weakAreas: [String], incorrectQuestions: [TestQuestion]) -> [String] {
        var recommendations: [String] = []
        
        if !weakAreas.isEmpty {
            recommendations.append("Focus on these weak areas: \(weakAreas.joined(separator: ", "))")
        }
        
        if incorrectQuestions.count > 0 {
            recommendations.append("Review the \(incorrectQuestions.count) terms you got wrong using flashcards")
        }
        
        if incorrectQuestions.count > 5 {
            recommendations.append("Consider taking more quick tests to build confidence")
        }
        
        return recommendations
    }
    
    private func checkForAchievements(correctAnswers: Int, totalQuestions: Int) -> String? {
        let accuracy = Double(correctAnswers) / Double(totalQuestions) * 100
        
        if accuracy == 100 {
            return "Perfect Score! 🎯"
        } else if accuracy >= 90 {
            return "Excellent Performance! ⭐"
        } else if accuracy >= 80 {
            return "Great Progress! 📈"
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /**
     * Get terminology for a single belt level
     */
    private func getTerminologyForBelt(_ beltLevel: BeltLevel) -> [TerminologyEntry] {
        let beltSortOrder = beltLevel.sortOrder
        let descriptor = FetchDescriptor<TerminologyEntry>(
            predicate: #Predicate { entry in
                entry.beltLevel.sortOrder == beltSortOrder
            }
        )

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            DebugLogger.data("Failed to fetch terminology for belt \\(beltLevel.shortName): \\(error)")
            return []
        }
    }

    /**
     * Get terminology based on belt scope
     *
     * - Parameters:
     *   - currentBelt: The user's current belt level
     *   - scope: Which belts to include
     * - Returns: Tuple of (terminology entries, belt level identifiers)
     */
    private func getTerminologyForBeltScope(_ currentBelt: BeltLevel, scope: TestUIConfig.BeltScope) -> ([TerminologyEntry], [String]) {
        let currentBeltSortOrder = currentBelt.sortOrder

        switch scope {
        case .currentOnly:
            // Just current belt
            let terminology = getTerminologyForBelt(currentBelt)
            let beltIds = [currentBelt.shortName.replacingOccurrences(of: " ", with: "_").lowercased()]
            return (terminology, beltIds)

        case .allUpToCurrent:
            // All belts from white belt up to current (inclusive)
            let descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate { entry in
                    entry.beltLevel.sortOrder >= currentBeltSortOrder
                }
            )

            do {
                let terminology = try modelContext.fetch(descriptor)

                // Get all unique belt IDs from the terminology
                let beltIds = Array(Set(terminology.map {
                    $0.beltLevel.shortName.replacingOccurrences(of: " ", with: "_").lowercased()
                }))

                return (terminology, beltIds)
            } catch {
                DebugLogger.data("Failed to fetch terminology for belt scope: \\(error)")
                return ([], [])
            }
        }
    }

    private func getPreviousBelt(from currentBelt: BeltLevel) -> BeltLevel? {
        let targetSortOrder = currentBelt.sortOrder + 1
        let descriptor = FetchDescriptor<BeltLevel>(
            predicate: #Predicate { belt in
                belt.sortOrder == targetSortOrder  // Higher sort order = lower rank
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            DebugLogger.data("Failed to fetch previous belt: \\(error)")
            return nil
        }
    }
    
    private func updatePerformanceHistory(with result: TestResult, session: TestSession, userProfile: UserProfile? = nil) throws {
        guard let userBeltLevel = session.userBeltLevel else { return }
        
        // If userProfile is provided, record test history for that specific profile
        if let profile = userProfile {
            // Update profile test statistics
            profile.totalTestsTaken += 1
            profile.recordActivity()
            
            // Record study session for this test
            try recordProfileTestSession(profile: profile, result: result, session: session)
        }
        
        // Get or create performance record for user's belt level
        let _ = userBeltLevel.sortOrder
        let descriptor = FetchDescriptor<TestPerformance>()
        
        let existingPerformance = try modelContext.fetch(descriptor).first
        let performance = existingPerformance ?? TestPerformance(userBeltLevel: userBeltLevel)
        
        // Update performance metrics
        let newTestCount = performance.testsCompleted + 1
        let newOverallAccuracy = ((performance.overallAccuracy * Double(performance.testsCompleted)) + result.accuracy) / Double(newTestCount)
        
        performance.testsCompleted = newTestCount
        performance.overallAccuracy = newOverallAccuracy
        performance.lastTestDate = Date()
        performance.updatedAt = Date()
        
        // Update daily streak
        if let lastTest = performance.lastTestDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastTest) {
                // Same day, don't change streak
            } else if calendar.isDateInYesterday(lastTest) {
                performance.dailyTestStreak += 1
            } else {
                performance.dailyTestStreak = 1 // Reset streak
            }
        } else {
            performance.dailyTestStreak = 1
        }
        
        if existingPerformance == nil {
            modelContext.insert(performance)
        }
    }
    
    /**
     * Records a study session for profile-specific test tracking
     */
    private func recordProfileTestSession(profile: UserProfile, result: TestResult, session: TestSession) throws {
        // Create StudySession directly for the specific profile
        let studySession = StudySession(userProfile: profile, sessionType: .testing)
        
        // Set session details
        studySession.itemsStudied = result.totalQuestions
        studySession.correctAnswers = result.correctAnswers
        
        // Get focus areas from the test session and convert to comma-separated string
        let focusAreasArray = session.categories.isEmpty ? [profile.currentBeltLevel.shortName] : session.categories
        studySession.focusAreas = focusAreasArray.joined(separator: ", ")
        
        // Insert the session into the model context
        modelContext.insert(studySession)
        
        DebugLogger.data("📊 Recorded test session for \(profile.name): \(result.correctAnswers)/\(result.totalQuestions) (\(Int(result.accuracy))%)")
    }
}

// MARK: - Testing Errors

enum TestingError: Error, LocalizedError {
    case noQuestionsAvailable

    var errorDescription: String? {
        switch self {
        case .noQuestionsAvailable:
            return "No questions available for the selected configuration"
        }
    }
}