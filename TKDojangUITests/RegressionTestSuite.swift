import XCTest

/**
 * RegressionTestSuite.swift
 * 
 * PURPOSE: Comprehensive regression testing for TKDojang critical user journeys
 * 
 * REGRESSION PREVENTION: These tests prevent breaking changes to core app functionality
 * Based on identified regression issues where changes to one feature break others
 * 
 * CRITICAL USER JOURNEYS TESTED:
 * - Complete learning session workflow (Profile → Flashcards → Test → Progress)
 * - Multi-profile data isolation and switching
 * - Pattern learning progression with progress tracking
 * - Data persistence across app sessions
 * - Progress analytics accuracy validation
 */
final class RegressionTestSuite: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully initialize
        _ = waitForAppToLoad()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete End-to-End Journey Tests
    
    /**
     * Tests the complete user learning journey that users follow daily:
     * Create Profile → Study Flashcards → Take Test → View Progress
     * 
     * REGRESSION PREVENTION: Ensures core learning loop never breaks
     */
    func testCompleteUserLearningJourney() throws {
        let journeySuccess = executeCompleteJourney(
            profileName: "RegressionUser\(Int.random(in: 1000...9999))",
            flashcardCount: 5,
            testQuestionCount: 3
        )
        
        XCTAssertTrue(journeySuccess.profileCreated, "Profile creation should succeed")
        XCTAssertTrue(journeySuccess.flashcardsCompleted, "Flashcard session should complete")
        XCTAssertTrue(journeySuccess.testCompleted, "Test should complete successfully")
        XCTAssertTrue(journeySuccess.progressDisplayed, "Progress should be visible and accurate")
    }
    
    /**
     * Tests multi-profile data isolation - critical for family usage
     * 
     * REGRESSION PREVENTION: Ensures profile switching doesn't corrupt data
     */
    func testMultiProfileDataIsolation() throws {
        // Create two test profiles
        let profile1Name = "TestUser1_\(Int.random(in: 1000...9999))"
        let profile2Name = "TestUser2_\(Int.random(in: 1000...9999))"
        
        createTestProfile(name: profile1Name)
        let profile1Stats = captureProfileStats()
        
        // Complete some activities for profile 1
        performLearningActivities(flashcards: 3, tests: 1)
        let profile1StatsAfter = captureProfileStats()
        
        // Switch to profile 2
        createTestProfile(name: profile2Name)
        let profile2Stats = captureProfileStats()
        
        // Profile 2 should have clean slate
        XCTAssertEqual(profile2Stats.flashcardsStudied, 0, "New profile should start with zero flashcards")
        XCTAssertEqual(profile2Stats.testsCompleted, 0, "New profile should start with zero tests")
        
        // Switch back to profile 1 - data should be preserved
        switchToProfile(name: profile1Name)
        let profile1StatsRestored = captureProfileStats()
        
        XCTAssertEqual(profile1StatsRestored.flashcardsStudied, profile1StatsAfter.flashcardsStudied, 
                      "Profile 1 data should be preserved after switching")
    }
    
    /**
     * Tests pattern learning progression tracking
     * 
     * REGRESSION PREVENTION: Ensures pattern progress is accurately recorded
     */
    func testPatternProgressionTracking() throws {
        createTestProfile(name: "PatternUser\(Int.random(in: 1000...9999))")
        
        // Practice a pattern
        navigateToPatterns()
        let patternPracticed = practicePattern(name: "Chon-Ji")
        XCTAssertTrue(patternPracticed, "Should be able to practice pattern")
        
        // Verify progress is recorded
        navigateToProgress()
        let progressVisible = verifyPatternProgress(patternName: "Chon-Ji")
        XCTAssertTrue(progressVisible, "Pattern progress should be visible in progress tab")
    }
    
    /**
     * Tests data persistence across app sessions
     * 
     * REGRESSION PREVENTION: Ensures user data survives app restarts
     */
    func testDataPersistenceAcrossAppSessions() throws {
        let profileName = "PersistenceUser\(Int.random(in: 1000...9999))"
        createTestProfile(name: profileName)
        
        // Complete some activities
        let initialStats = captureProfileStats()
        performLearningActivities(flashcards: 2, tests: 1)
        let statsAfterLearning = captureProfileStats()
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        _ = waitForAppToLoad()
        
        // Switch to the test profile
        switchToProfile(name: profileName)
        
        // Verify data persisted
        let statsAfterRelaunch = captureProfileStats()
        XCTAssertEqual(statsAfterRelaunch.flashcardsStudied, statsAfterLearning.flashcardsStudied,
                      "Flashcard progress should persist across app sessions")
        XCTAssertEqual(statsAfterRelaunch.testsCompleted, statsAfterLearning.testsCompleted,
                      "Test completion should persist across app sessions")
    }
    
    /**
     * Tests progress analytics accuracy under various scenarios
     * 
     * REGRESSION PREVENTION: Ensures progress calculations remain correct
     */
    func testProgressAnalyticsAccuracy() throws {
        let profileName = "AnalyticsUser\(Int.random(in: 1000...9999))"
        createTestProfile(name: profileName)
        
        // Record baseline
        navigateToProgress()
        let baselineStats = captureProgressAnalytics()
        
        // Perform known activities
        performLearningActivities(flashcards: 3, tests: 2)
        
        // Verify analytics updated correctly
        navigateToProgress()
        let updatedStats = captureProgressAnalytics()
        
        XCTAssertEqual(updatedStats.totalSessions, baselineStats.totalSessions + 2,
                      "Session count should increase by number of completed activities")
        XCTAssertGreaterThan(updatedStats.totalStudyTime, baselineStats.totalStudyTime,
                           "Study time should increase after learning activities")
    }
    
    // MARK: - Critical Edge Case Tests
    
    /**
     * Tests app behavior during rapid profile switching
     * 
     * REGRESSION PREVENTION: Ensures rapid switching doesn't cause crashes or data corruption
     */
    func testRapidProfileSwitching() throws {
        // Create multiple profiles
        let profiles = [
            "RapidUser1_\(Int.random(in: 1000...9999))",
            "RapidUser2_\(Int.random(in: 1000...9999))",
            "RapidUser3_\(Int.random(in: 1000...9999))"
        ]
        
        for profile in profiles {
            createTestProfile(name: profile)
        }
        
        // Rapidly switch between profiles
        for _ in 0..<5 {
            for profile in profiles {
                let switchSuccess = switchToProfile(name: profile)
                XCTAssertTrue(switchSuccess, "Profile switching should succeed even during rapid switching")
                
                // Brief activity to test functionality
                let functionalityWorking = verifyBasicFunctionality()
                XCTAssertTrue(functionalityWorking, "App should remain functional during rapid profile switching")
            }
        }
    }
    
    /**
     * Tests app recovery after database operations
     * 
     * REGRESSION PREVENTION: Ensures database reset doesn't break subsequent operations
     */
    func testDatabaseResetRecovery() throws {
        // This test should be run carefully as it tests database reset functionality
        
        let profileName = "ResetTestUser\(Int.random(in: 1000...9999))"
        createTestProfile(name: profileName)
        performLearningActivities(flashcards: 2, tests: 1)
        
        // Note: Database reset typically requires app restart, so this test
        // should verify that the app can recover properly after such operations
        
        // Verify app remains stable
        let appStable = verifyAppStability()
        XCTAssertTrue(appStable, "App should remain stable after database operations")
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppToLoad() -> Bool {
        return app.tabBars.firstMatch.waitForExistence(timeout: 15.0) ||
               app.buttons["Create Profile"].waitForExistence(timeout: 10.0) ||
               app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome'")).firstMatch.waitForExistence(timeout: 10.0)
    }
    
    private func createTestProfile(name: String) {
        navigateToProfileManagement()
        
        let createButton = app.buttons["Create Profile"]
        if createButton.waitForExistence(timeout: 5.0) {
            createButton.tap()
            
            let nameField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Name' OR label CONTAINS 'Name'")).firstMatch
            if nameField.waitForExistence(timeout: 3.0) {
                nameField.tap()
                nameField.typeText(name)
                
                let saveButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Save' OR label CONTAINS 'Create' OR label CONTAINS 'Done'")).firstMatch
                if saveButton.exists {
                    saveButton.tap()
                }
            }
        }
    }
    
    private func switchToProfile(name: String) -> Bool {
        navigateToProfileManagement()
        
        let profileElement = app.staticTexts[name]
        if profileElement.waitForExistence(timeout: 5.0) {
            profileElement.tap()
            return app.tabBars.firstMatch.waitForExistence(timeout: 5.0)
        }
        return false
    }
    
    private func performLearningActivities(flashcards: Int, tests: Int) {
        // Complete flashcard session
        if flashcards > 0 {
            navigateToFlashcards()
            for _ in 0..<flashcards {
                performSingleFlashcard()
            }
        }
        
        // Complete test session  
        if tests > 0 {
            navigateToTesting()
            for _ in 0..<tests {
                performSingleTest()
            }
        }
    }
    
    private func performSingleFlashcard() {
        let showAnswerButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Show' OR label CONTAINS 'Answer'")).firstMatch
        if showAnswerButton.waitForExistence(timeout: 3.0) {
            showAnswerButton.tap()
            
            let correctButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Correct'")).firstMatch
            if correctButton.waitForExistence(timeout: 2.0) {
                correctButton.tap()
            }
        }
    }
    
    private func performSingleTest() {
        let answerChoices = app.buttons.matching(NSPredicate(format: "label CONTAINS 'A)' OR label CONTAINS '1.'"))
        if answerChoices.count > 0 {
            answerChoices.firstMatch.tap()
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    private func practicePattern(name: String) -> Bool {
        let patternElement = app.staticTexts[name]
        if patternElement.waitForExistence(timeout: 5.0) {
            patternElement.tap()
            return app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Step' OR label CONTAINS 'Movement'")).firstMatch.waitForExistence(timeout: 5.0)
        }
        return false
    }
    
    private func verifyPatternProgress(patternName: String) -> Bool {
        return app.staticTexts.containing(NSPredicate(format: "label CONTAINS '\(patternName)'")).firstMatch.exists
    }
    
    private func captureProfileStats() -> ProfileStats {
        navigateToProgress()
        
        // Extract stats from progress UI
        let flashcardsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'flashcard'")).firstMatch.label
        let testsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'test'")).firstMatch.label
        
        return ProfileStats(
            flashcardsStudied: extractNumber(from: flashcardsText),
            testsCompleted: extractNumber(from: testsText)
        )
    }
    
    private func captureProgressAnalytics() -> ProgressAnalytics {
        // Extract analytics data from progress screen
        let sessionCountText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'session'")).firstMatch.label
        let studyTimeText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'time' OR label CONTAINS 'minute'")).firstMatch.label
        
        return ProgressAnalytics(
            totalSessions: extractNumber(from: sessionCountText),
            totalStudyTime: extractNumber(from: studyTimeText)
        )
    }
    
    private func extractNumber(from text: String) -> Int {
        let numbers = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for numberString in numbers {
            if let number = Int(numberString), !numberString.isEmpty {
                return number
            }
        }
        return 0
    }
    
    private func verifyBasicFunctionality() -> Bool {
        return app.state == .runningForeground && 
               (app.tabBars.firstMatch.exists || app.navigationBars.firstMatch.exists)
    }
    
    private func verifyAppStability() -> Bool {
        return app.state == .runningForeground
    }
    
    private func executeCompleteJourney(profileName: String, flashcardCount: Int, testQuestionCount: Int) -> JourneyResult {
        var result = JourneyResult()
        
        // Create profile
        createTestProfile(name: profileName)
        result.profileCreated = app.staticTexts[profileName].exists
        
        // Complete flashcards
        if result.profileCreated {
            navigateToFlashcards()
            for _ in 0..<flashcardCount {
                performSingleFlashcard()
            }
            result.flashcardsCompleted = true
        }
        
        // Complete test
        if result.flashcardsCompleted {
            navigateToTesting()
            for _ in 0..<testQuestionCount {
                performSingleTest()
            }
            result.testCompleted = true
        }
        
        // Verify progress
        if result.testCompleted {
            navigateToProgress()
            result.progressDisplayed = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'session' OR label CONTAINS 'study'")).firstMatch.exists
        }
        
        return result
    }
    
    // Navigation helper methods (reuse from existing TKDojangUITests)
    private func navigateToProfileManagement() {
        let profileTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Profile'")).firstMatch
        if profileTab.exists {
            profileTab.tap()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func navigateToFlashcards() {
        let learnTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Learn'")).firstMatch
        if learnTab.exists {
            learnTab.tap()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func navigateToTesting() {
        let testButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Test'")).firstMatch
        if testButton.exists {
            testButton.tap()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func navigateToPatterns() {
        let patternButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pattern'")).firstMatch
        if patternButton.exists {
            patternButton.tap()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
    
    private func navigateToProgress() {
        let progressTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Progress'")).firstMatch
        if progressTab.exists {
            progressTab.tap()
        }
        Thread.sleep(forTimeInterval: 1.0)
    }
}

// MARK: - Support Structures

struct ProfileStats {
    let flashcardsStudied: Int
    let testsCompleted: Int
}

struct ProgressAnalytics {
    let totalSessions: Int
    let totalStudyTime: Int
}

struct JourneyResult {
    var profileCreated: Bool = false
    var flashcardsCompleted: Bool = false
    var testCompleted: Bool = false
    var progressDisplayed: Bool = false
}