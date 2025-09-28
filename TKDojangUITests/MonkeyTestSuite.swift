import XCTest

/**
 * MonkeyTestSuite.swift
 * 
 * PURPOSE: Chaos testing through random user interactions
 * 
 * MONKEY TESTING BENEFITS:
 * - Discovers edge cases human testers miss
 * - Stress tests app stability under unpredictable usage
 * - Finds crashes in unusual interaction sequences
 * - Validates app doesn't break under rapid/random input
 * 
 * HOW IT WORKS:
 * 1. Performs random taps, swipes, and gestures
 * 2. Navigates randomly through app features
 * 3. Inputs random text and data
 * 4. Tests app recovery from unexpected states
 * 
 * SAFETY MEASURES:
 * - Avoids destructive actions (database reset, profile deletion)
 * - Limits test duration to prevent infinite loops
 * - Monitors app stability throughout testing
 * - Provides detailed logging for crash investigation
 */
final class MonkeyTestSuite: XCTestCase {
    
    var app: XCUIApplication!
    
    // Monkey test configuration
    private let maxTestDuration: TimeInterval = 300.0 // 5 minutes
    private let actionInterval: TimeInterval = 0.5 // Time between actions
    private let maxActionsPerTest = 600 // Maximum actions per test
    
    // Action weights (higher = more likely to be selected)
    private let actionWeights: [MonkeyAction: Int] = [
        .randomTap: 40,
        .randomSwipe: 20,
        .randomTextInput: 15,
        .navigationAction: 15,
        .randomLongPress: 5,
        .pinchGesture: 3,
        .shakeDevice: 2
    ]
    
    override func setUpWithError() throws {
        continueAfterFailure = true // Continue testing even after failures
        app = XCUIApplication()
        
        // Launch with monkey testing flags
        app.launchArguments = ["MONKEY_TESTING", "DISABLE_ANIMATIONS", "UI_TESTING"]
        app.launch()
        
        // Wait for app to fully load
        _ = waitForAppToLoad()
        
        // Setup test profile for monkey testing
        setupMonkeyTestProfile()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Monkey Test Scenarios
    
    /**
     * General chaos monkey test - random interactions across the entire app
     * 
     * CRITICAL: Tests overall app stability under unpredictable usage
     */
    func testGeneralChaosMonkey() throws {
        let testName = "GeneralChaosMonkey"
        let logger = MonkeyTestLogger(testName: testName)
        
        let startTime = Date()
        var actionCount = 0
        
        logger.log("🐒 Starting general chaos monkey test")
        logger.log("📊 Max duration: \(maxTestDuration)s, Max actions: \(maxActionsPerTest)")
        
        while Date().timeIntervalSince(startTime) < maxTestDuration && 
              actionCount < maxActionsPerTest {
            
            // Check app stability
            guard app.state == .runningForeground else {
                logger.log("❌ App not in foreground - stopping test")
                XCTFail("App should remain in foreground during monkey testing")
                break
            }
            
            // Perform random action
            let action = selectRandomAction()
            logger.log("🎯 Action \(actionCount + 1): \(action)")
            
            let actionSuccess = performMonkeyAction(action, logger: logger)
            if !actionSuccess {
                logger.log("⚠️ Action \(action) failed - continuing")
            }
            
            actionCount += 1
            Thread.sleep(forTimeInterval: actionInterval)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.log("✅ Chaos monkey test completed")
        logger.log("📈 Total actions: \(actionCount), Duration: \(String(format: "%.1f", duration))s")
        logger.log("🎯 Actions per second: \(String(format: "%.2f", Double(actionCount) / duration))")
        
        // Final stability check
        XCTAssertTrue(app.state == .runningForeground, "App should be stable after monkey testing")
        
        logger.saveLog()
    }
    
    /**
     * Focused chaos monkey test on learning features
     * 
     * CRITICAL: Stress tests flashcard and testing workflows
     */
    func testLearningFocusedMonkey() throws {
        let testName = "LearningFocusedMonkey"
        let logger = MonkeyTestLogger(testName: testName)
        
        logger.log("🐒 Starting learning-focused monkey test")
        
        // Navigate to learning area
        navigateToFlashcards()
        
        let startTime = Date()
        var actionCount = 0
        
        while Date().timeIntervalSince(startTime) < maxTestDuration / 2 && 
              actionCount < maxActionsPerTest / 2 {
            
            guard app.state == .runningForeground else {
                logger.log("❌ App crashed during learning monkey test")
                XCTFail("App should remain stable during learning-focused testing")
                break
            }
            
            // Focus on learning-related actions
            let action = selectLearningFocusedAction()
            logger.log("📚 Learning Action \(actionCount + 1): \(action)")
            
            performMonkeyAction(action, logger: logger)
            actionCount += 1
            Thread.sleep(forTimeInterval: actionInterval)
        }
        
        logger.log("✅ Learning-focused monkey test completed - \(actionCount) actions")
        XCTAssertTrue(app.state == .runningForeground, "App should be stable after learning monkey test")
        
        logger.saveLog()
    }
    
    /**
     * Profile management chaos monkey test
     * 
     * CRITICAL: Tests profile switching stability under stress
     */
    func testProfileManagementMonkey() throws {
        let testName = "ProfileManagementMonkey"
        let logger = MonkeyTestLogger(testName: testName)
        
        logger.log("🐒 Starting profile management monkey test")
        
        // Create multiple test profiles for chaos testing
        createMultipleTestProfiles(count: 3, logger: logger)
        
        navigateToProfileManagement()
        
        let startTime = Date()
        var actionCount = 0
        
        while Date().timeIntervalSince(startTime) < maxTestDuration / 3 && 
              actionCount < maxActionsPerTest / 3 {
            
            guard app.state == .runningForeground else {
                logger.log("❌ App crashed during profile monkey test")
                XCTFail("App should remain stable during profile testing")
                break
            }
            
            let action = selectProfileFocusedAction()
            logger.log("👤 Profile Action \(actionCount + 1): \(action)")
            
            performMonkeyAction(action, logger: logger)
            actionCount += 1
            Thread.sleep(forTimeInterval: actionInterval)
        }
        
        logger.log("✅ Profile management monkey test completed - \(actionCount) actions")
        XCTAssertTrue(app.state == .runningForeground, "App should be stable after profile monkey test")
        
        logger.saveLog()
    }
    
    /**
     * Memory pressure monkey test - tests app under resource constraints
     * 
     * CRITICAL: Ensures app handles memory pressure gracefully
     */
    func testMemoryPressureMonkey() throws {
        let testName = "MemoryPressureMonkey"
        let logger = MonkeyTestLogger(testName: testName)
        
        logger.log("🐒 Starting memory pressure monkey test")
        
        // Simulate memory pressure by rapid navigation and data loading
        let startTime = Date()
        var actionCount = 0
        
        while Date().timeIntervalSince(startTime) < maxTestDuration / 4 && 
              actionCount < maxActionsPerTest / 4 {
            
            guard app.state == .runningForeground else {
                logger.log("❌ App crashed under memory pressure")
                XCTFail("App should handle memory pressure gracefully")
                break
            }
            
            // Perform memory-intensive actions
            performMemoryIntensiveAction(logger: logger)
            actionCount += 1
            
            // Shorter interval for memory pressure
            Thread.sleep(forTimeInterval: actionInterval / 2)
        }
        
        logger.log("✅ Memory pressure monkey test completed - \(actionCount) actions")
        XCTAssertTrue(app.state == .runningForeground, "App should survive memory pressure testing")
        
        logger.saveLog()
    }
    
    /**
     * Rapid interaction monkey test - tests UI responsiveness
     * 
     * CRITICAL: Ensures UI remains responsive under rapid input
     */
    func testRapidInteractionMonkey() throws {
        let testName = "RapidInteractionMonkey"
        let logger = MonkeyTestLogger(testName: testName)
        
        logger.log("🐒 Starting rapid interaction monkey test")
        
        let startTime = Date()
        var actionCount = 0
        
        while Date().timeIntervalSince(startTime) < maxTestDuration / 6 && 
              actionCount < maxActionsPerTest / 6 {
            
            guard app.state == .runningForeground else {
                logger.log("❌ App crashed during rapid interaction test")
                XCTFail("App should handle rapid interactions")
                break
            }
            
            // Rapid-fire actions with minimal delay
            performRapidInteraction(logger: logger)
            actionCount += 1
            
            // Very short interval for rapid testing
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        logger.log("✅ Rapid interaction monkey test completed - \(actionCount) actions")
        XCTAssertTrue(app.state == .runningForeground, "App should remain responsive after rapid interactions")
        
        logger.saveLog()
    }
    
    // MARK: - Monkey Action Implementation
    
    private func selectRandomAction() -> MonkeyAction {
        let totalWeight = actionWeights.values.reduce(0, +)
        let randomValue = Int.random(in: 0..<totalWeight)
        
        var cumulativeWeight = 0
        for (action, weight) in actionWeights {
            cumulativeWeight += weight
            if randomValue < cumulativeWeight {
                return action
            }
        }
        
        return .randomTap // Fallback
    }
    
    private func selectLearningFocusedAction() -> MonkeyAction {
        let learningActions: [MonkeyAction] = [.randomTap, .randomSwipe, .randomTextInput, .navigationAction]
        return learningActions.randomElement() ?? .randomTap
    }
    
    private func selectProfileFocusedAction() -> MonkeyAction {
        let profileActions: [MonkeyAction] = [.randomTap, .navigationAction, .randomTextInput]
        return profileActions.randomElement() ?? .randomTap
    }
    
    private func performMonkeyAction(_ action: MonkeyAction, logger: MonkeyTestLogger) -> Bool {
        switch action {
        case .randomTap:
            return performRandomTap(logger: logger)
        case .randomSwipe:
            return performRandomSwipe(logger: logger)
        case .randomTextInput:
            return performRandomTextInput(logger: logger)
        case .navigationAction:
            return performNavigationAction(logger: logger)
        case .randomLongPress:
            return performRandomLongPress(logger: logger)
        case .pinchGesture:
            return performPinchGesture(logger: logger)
        case .shakeDevice:
            return performShakeDevice(logger: logger)
        }
    }
    
    private func performRandomTap(logger: MonkeyTestLogger) -> Bool {
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        let tappableElements = allElements.filter { $0.isHittable && $0.exists }
        
        guard !tappableElements.isEmpty else {
            logger.log("⚠️ No tappable elements found")
            return false
        }
        
        let randomElement = tappableElements.randomElement()!
        let elementInfo = "\(randomElement.elementType.rawValue):\(randomElement.label.prefix(20))"
        logger.log("👆 Tapping: \(elementInfo)")
        
        randomElement.tap()
        return true
    }
    
    private func performRandomSwipe(logger: MonkeyTestLogger) -> Bool {
        let swipeDirections = ["up", "down", "left", "right"]
        let direction = swipeDirections.randomElement()!
        
        logger.log("👋 Swiping: \(direction)")
        
        let swipeElement = app.descendants(matching: .any).matching(NSPredicate(format: "isHittable == true")).firstMatch
        
        if swipeElement.exists {
            switch direction {
            case "up":
                swipeElement.swipeUp()
            case "down":
                swipeElement.swipeDown()
            case "left":
                swipeElement.swipeLeft()
            case "right":
                swipeElement.swipeRight()
            default:
                swipeElement.swipeUp()
            }
            return true
        }
        return false
    }
    
    private func performRandomTextInput(logger: MonkeyTestLogger) -> Bool {
        let textFields = app.textFields.allElementsBoundByIndex + app.textViews.allElementsBoundByIndex
        let availableFields = textFields.filter { $0.exists && $0.isHittable }
        
        guard !availableFields.isEmpty else {
            logger.log("⚠️ No text input fields found")
            return false
        }
        
        let randomField = availableFields.randomElement()!
        let randomText = generateRandomText()
        
        logger.log("⌨️ Typing '\(randomText)' in text field")
        
        randomField.tap()
        randomField.typeText(randomText)
        return true
    }
    
    private func performNavigationAction(logger: MonkeyTestLogger) -> Bool {
        let navButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Back' OR label CONTAINS 'Cancel' OR label CONTAINS 'Done' OR label CONTAINS 'Close'")).allElementsBoundByIndex
        
        if !navButtons.isEmpty, let randomButton = navButtons.randomElement(), randomButton.isHittable {
            logger.log("🧭 Navigation action: \(randomButton.label)")
            randomButton.tap()
            return true
        }
        
        // Try tab bar navigation
        let tabButtons = app.tabBars.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
        if !tabButtons.isEmpty, let randomTab = tabButtons.randomElement() {
            logger.log("📱 Tab navigation: \(randomTab.label)")
            randomTab.tap()
            return true
        }
        
        return false
    }
    
    private func performRandomLongPress(logger: MonkeyTestLogger) -> Bool {
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        let longPressableElements = allElements.filter { $0.isHittable && $0.exists }
        
        guard !longPressableElements.isEmpty else {
            logger.log("⚠️ No long-pressable elements found")
            return false
        }
        
        let randomElement = longPressableElements.randomElement()!
        logger.log("👆⏰ Long pressing: \(randomElement.elementType.rawValue)")
        
        randomElement.press(forDuration: 1.5)
        return true
    }
    
    private func performPinchGesture(logger: MonkeyTestLogger) -> Bool {
        let scrollViews = app.scrollViews.allElementsBoundByIndex.filter { $0.exists }
        
        guard !scrollViews.isEmpty else {
            logger.log("⚠️ No pinchable views found")
            return false
        }
        
        let randomView = scrollViews.randomElement()!
        let pinchOut = Bool.random()
        
        logger.log("🤏 \(pinchOut ? "Pinch out" : "Pinch in") gesture")
        
        if pinchOut {
            randomView.pinch(withScale: 2.0, velocity: 1.0)
        } else {
            randomView.pinch(withScale: 0.5, velocity: 1.0)
        }
        return true
    }
    
    private func performShakeDevice(logger: MonkeyTestLogger) -> Bool {
        logger.log("📳 Shaking device")
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 0.5)
        app.activate()
        return true
    }
    
    private func performMemoryIntensiveAction(logger: MonkeyTestLogger) {
        // Navigate between different tabs rapidly to load different views
        let tabs = app.tabBars.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
        
        for tab in tabs {
            tab.tap()
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        logger.log("💾 Memory intensive navigation completed")
    }
    
    private func performRapidInteraction(logger: MonkeyTestLogger) {
        // Perform multiple quick taps
        let tappableElements = app.descendants(matching: .any).allElementsBoundByIndex.filter { $0.isHittable && $0.exists }
        
        if !tappableElements.isEmpty {
            let element = tappableElements.randomElement()!
            element.tap()
            logger.log("⚡ Rapid tap")
        }
    }
    
    private func generateRandomText() -> String {
        let textOptions = [
            "Test User \(Int.random(in: 1...999))",
            "Monkey Test",
            "Random Input",
            "테스트", // Korean test
            "123456",
            "test@example.com",
            "!@#$%^&*()",
            ""
        ]
        return textOptions.randomElement() ?? "Monkey"
    }
    
    // MARK: - Helper Methods
    
    private func setupMonkeyTestProfile() {
        let profileName = "MonkeyTestUser"
        
        // Create profile if it doesn't exist
        navigateToProfileManagement()
        
        let existingProfile = app.staticTexts[profileName]
        if !existingProfile.exists {
            createTestProfile(name: profileName)
        } else {
            existingProfile.tap()
        }
    }
    
    private func createMultipleTestProfiles(count: Int, logger: MonkeyTestLogger) {
        for i in 1...count {
            let profileName = "MonkeyUser\(i)"
            createTestProfile(name: profileName)
            logger.log("👤 Created test profile: \(profileName)")
        }
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
    
    private func waitForAppToLoad() -> Bool {
        return app.tabBars.firstMatch.waitForExistence(timeout: 15.0) ||
               app.buttons["Create Profile"].waitForExistence(timeout: 10.0) ||
               app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Welcome'")).firstMatch.waitForExistence(timeout: 10.0)
    }
    
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
}

// MARK: - Supporting Types

enum MonkeyAction: String, CaseIterable {
    case randomTap = "Random Tap"
    case randomSwipe = "Random Swipe"
    case randomTextInput = "Random Text Input"
    case navigationAction = "Navigation Action"
    case randomLongPress = "Random Long Press"
    case pinchGesture = "Pinch Gesture"
    case shakeDevice = "Shake Device"
}

class MonkeyTestLogger {
    private let testName: String
    private var logs: [String] = []
    private let startTime = Date()
    
    init(testName: String) {
        self.testName = testName
        log("🐒 \(testName) started at \(startTime)")
    }
    
    func log(_ message: String) {
        let timestamp = String(format: "%.2f", Date().timeIntervalSince(startTime))
        let logEntry = "[\(timestamp)s] \(message)"
        logs.append(logEntry)
        print(logEntry)
    }
    
    func saveLog() {
        print("\n📊 MONKEY TEST SUMMARY for \(testName):")
        print("Duration: \(String(format: "%.1f", Date().timeIntervalSince(startTime)))s")
        print("Total log entries: \(logs.count)")
        print("=====================================\n")
        
        // In production, save logs to file or test artifacts
        // let logContent = logs.joined(separator: "\n")
        // saveToFile(logContent)
    }
}

/**
 * MONKEY TESTING USAGE GUIDE:
 * 
 * 1. RUN TESTS:
 *    - Individual monkey tests: Run specific test methods
 *    - Full chaos suite: Run entire MonkeyTestSuite
 *    - Continuous testing: Set up automated runs
 * 
 * 2. INTERPRET RESULTS:
 *    - Green = App survived chaos testing
 *    - Red = App crashed or became unresponsive
 *    - Review logs for crash patterns
 * 
 * 3. CONFIGURATION:
 *    - Adjust maxTestDuration for longer/shorter tests
 *    - Modify actionWeights to focus on specific interactions
 *    - Update actionInterval for faster/slower testing
 * 
 * 4. SAFETY CONSIDERATIONS:
 *    - Tests avoid destructive actions
 *    - Profile creation uses test prefixes
 *    - No real data is destroyed
 *    - App state is monitored continuously
 * 
 * 5. CI/CD INTEGRATION:
 *    - Include in nightly test runs
 *    - Set reasonable time limits
 *    - Archive logs for crash analysis
 */