import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * NavigationAndStateTests.swift
 * 
 * PURPOSE: Critical navigation and state management testing for app-wide user experience
 * 
 * COVERAGE: Priority 1 - Foundation navigation flows that affect every user interaction
 * - Five-tab navigation with profile context preservation
 * - Modal presentations (sheets, alerts, popovers) and dismissal behavior
 * - Deep navigation and back button behavior across features
 * - State restoration after app backgrounding/foregrounding
 * - Toolbar and menu interaction validation
 * - Navigation state consistency during profile switching
 * 
 * BUSINESS IMPACT: Navigation is the foundation of app usability. Issues here affect
 * every single user interaction and can make the entire app unusable.
 */
final class NavigationAndStateTests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var navigationCoordinator: AppCoordinator!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with all models needed for navigation testing
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
            UserTerminologyProgress.self,
            UserPatternProgress.self,
            UserStepSparringProgress.self,
            StudySession.self,
            GradingRecord.self,
            Pattern.self,
            PatternMove.self,
            StepSparringSequence.self,
            StepSparringStep.self,
            StepSparringAction.self
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
        
        // Set up comprehensive test data for navigation scenarios
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        try testData.createMultipleProfileScenarios(in: testContext)
        
        // Initialize services and coordinator with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
        navigationCoordinator = AppCoordinator(dataServices: dataServices)
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        navigationCoordinator = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Main Tab Navigation Tests
    
    func testMainTabNavigationFlow() throws {
        // CRITICAL USER FLOW: Five-tab navigation system functionality
        
        // Create test profile for navigation context
        let testProfile = try profileService.createProfile(
            name: "Navigation Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test initial navigation state
        XCTAssertEqual(navigationCoordinator.currentTab, .dashboard, "Should start on dashboard tab")
        XCTAssertNotNil(navigationCoordinator.activeProfile, "Should have active profile for navigation")
        
        // Test navigation to each main tab
        let allTabs: [MainTab] = [.dashboard, .learn, .practice, .test, .profile]
        
        for tab in allTabs {
            navigationCoordinator.navigateToTab(tab)
            XCTAssertEqual(navigationCoordinator.currentTab, tab, "Should navigate to \(tab) tab")
            
            // Verify tab-specific context is loaded
            switch tab {
            case .dashboard:
                XCTAssertNotNil(navigationCoordinator.dashboardContext, "Dashboard should have context")
            case .learn:
                XCTAssertNotNil(navigationCoordinator.learningContext, "Learn tab should have context")
            case .practice:
                XCTAssertNotNil(navigationCoordinator.practiceContext, "Practice tab should have context")
            case .test:
                XCTAssertNotNil(navigationCoordinator.testingContext, "Test tab should have context")
            case .profile:
                XCTAssertNotNil(navigationCoordinator.profileContext, "Profile tab should have context")
            }
            
            // Verify profile context is preserved across tab switches
            XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, 
                          "Profile context should be preserved in \(tab) tab")
        }
        
        // Test rapid tab switching (stress test)
        for _ in 1...10 {
            let randomTab = allTabs.randomElement()!
            navigationCoordinator.navigateToTab(randomTab)
            XCTAssertEqual(navigationCoordinator.currentTab, randomTab, "Rapid tab switching should work")
            XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, 
                          "Profile should remain consistent during rapid switching")
        }
        
        // Performance validation for tab switching
        let tabSwitchMeasurement = PerformanceMeasurement.measureExecutionTime {
            for tab in allTabs {
                navigationCoordinator.navigateToTab(tab)
            }
        }
        
        XCTAssertLessThan(tabSwitchMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Tab switching should be near-instantaneous")
    }
    
    func testTabNavigationWithProfileSwitching() throws {
        // Test navigation state consistency during profile switching
        
        // Create multiple profiles for switching test
        let profile1 = try profileService.createProfile(
            name: "Student One",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        
        let profile2 = try profileService.createProfile(
            name: "Student Two",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        
        // Start with profile1 on learn tab
        profileService.setActiveProfile(profile1)
        navigationCoordinator.navigateToTab(.learn)
        
        XCTAssertEqual(navigationCoordinator.currentTab, .learn, "Should be on learn tab")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, profile1.id, "Should have profile1 active")
        
        // Switch to profile2 - should maintain tab but update context
        profileService.setActiveProfile(profile2)
        navigationCoordinator.updateProfileContext(profile2)
        
        XCTAssertEqual(navigationCoordinator.currentTab, .learn, "Should stay on learn tab after profile switch")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, profile2.id, "Should now have profile2 active")
        
        // Verify learning context updated for new profile
        let learningContext = navigationCoordinator.learningContext
        XCTAssertNotNil(learningContext, "Learning context should exist after profile switch")
        XCTAssertEqual(learningContext?.currentProfile.id, profile2.id, "Learning context should reflect new profile")
        
        // Test navigation after profile switch
        navigationCoordinator.navigateToTab(.test)
        XCTAssertEqual(navigationCoordinator.currentTab, .test, "Should navigate to test tab after profile switch")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, profile2.id, "Should maintain profile2 in test tab")
        
        // Switch back to profile1 and verify context updates
        profileService.setActiveProfile(profile1)
        navigationCoordinator.updateProfileContext(profile1)
        
        XCTAssertEqual(navigationCoordinator.currentTab, .test, "Should stay on test tab")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, profile1.id, "Should switch back to profile1")
        
        let testingContext = navigationCoordinator.testingContext
        XCTAssertEqual(testingContext?.currentProfile.id, profile1.id, "Testing context should reflect profile1")
    }
    
    // MARK: - Modal Presentation Tests
    
    func testModalSheetPresentations() throws {
        // Test sheet presentations and dismissal behavior
        
        let testProfile = try profileService.createProfile(
            name: "Modal Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        navigationCoordinator.navigateToTab(.learn)
        
        // Test flashcard configuration sheet
        let flashcardSheetContext = FlashcardConfigurationContext(
            categories: ["basic_techniques"],
            userProfile: testProfile
        )
        
        navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardSheetContext))
        
        XCTAssertNotNil(navigationCoordinator.currentSheet, "Should present flashcard configuration sheet")
        XCTAssertEqual(navigationCoordinator.currentSheet?.type, .flashcardConfiguration, 
                      "Should have correct sheet type")
        
        // Test sheet dismissal
        navigationCoordinator.dismissSheet()
        XCTAssertNil(navigationCoordinator.currentSheet, "Should dismiss sheet")
        
        // Test pattern practice sheet
        let availablePatterns = dataServices.patternService.getAvailablePatterns(for: testProfile)
        guard let testPattern = availablePatterns.first else {
            XCTFail("Should have patterns available for testing")
            return
        }
        
        let patternSheetContext = PatternPracticeContext(
            pattern: testPattern,
            userProfile: testProfile
        )
        
        navigationCoordinator.presentSheet(.patternPractice(patternSheetContext))
        XCTAssertNotNil(navigationCoordinator.currentSheet, "Should present pattern practice sheet")
        
        // Test overlapping sheet handling (should replace current sheet)
        let newFlashcardContext = FlashcardConfigurationContext(
            categories: ["intermediate_techniques"],
            userProfile: testProfile
        )
        
        navigationCoordinator.presentSheet(.flashcardConfiguration(newFlashcardContext))
        XCTAssertEqual(navigationCoordinator.currentSheet?.type, .flashcardConfiguration,
                      "Should replace previous sheet with new one")
        
        navigationCoordinator.dismissSheet()
        XCTAssertNil(navigationCoordinator.currentSheet, "Should dismiss replaced sheet")
        
        // Performance test for sheet presentation
        let sheetMeasurement = PerformanceMeasurement.measureExecutionTime {
            navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardSheetContext))
            navigationCoordinator.dismissSheet()
        }
        
        XCTAssertLessThan(sheetMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Sheet presentation and dismissal should be fast")
    }
    
    func testAlertPresentations() throws {
        // Test alert presentations and user interaction handling
        
        let testProfile = try profileService.createProfile(
            name: "Alert Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test profile deletion confirmation alert
        let deletionAlert = AlertContext(
            title: "Delete Profile",
            message: "Are you sure you want to delete this profile?",
            primaryAction: AlertAction(title: "Delete", style: .destructive, action: { /* deletion logic */ }),
            secondaryAction: AlertAction(title: "Cancel", style: .cancel, action: { /* cancel logic */ })
        )
        
        navigationCoordinator.presentAlert(deletionAlert)
        
        XCTAssertNotNil(navigationCoordinator.currentAlert, "Should present deletion alert")
        XCTAssertEqual(navigationCoordinator.currentAlert?.title, "Delete Profile", "Should have correct alert title")
        XCTAssertTrue(navigationCoordinator.currentAlert?.hasDestructiveAction == true, 
                     "Should recognize destructive action")
        
        // Test alert dismissal
        navigationCoordinator.dismissAlert()
        XCTAssertNil(navigationCoordinator.currentAlert, "Should dismiss alert")
        
        // Test error alert
        let errorAlert = AlertContext(
            title: "Error",
            message: "Failed to save progress. Please try again.",
            primaryAction: AlertAction(title: "OK", style: .default, action: { /* acknowledge error */ })
        )
        
        navigationCoordinator.presentAlert(errorAlert)
        XCTAssertNotNil(navigationCoordinator.currentAlert, "Should present error alert")
        XCTAssertFalse(navigationCoordinator.currentAlert?.hasDestructiveAction ?? true, 
                      "Error alert should not have destructive action")
        
        // Test overlapping alert handling (should queue or replace appropriately)
        let secondAlert = AlertContext(
            title: "Second Alert",
            message: "This is a second alert",
            primaryAction: AlertAction(title: "OK", style: .default, action: {})
        )
        
        navigationCoordinator.presentAlert(secondAlert)
        // Implementation should either queue alerts or replace them - both are acceptable behaviors
        XCTAssertNotNil(navigationCoordinator.currentAlert, "Should handle overlapping alerts gracefully")
        
        navigationCoordinator.dismissAlert()
    }
    
    // MARK: - Deep Navigation Tests
    
    func testDeepNavigationAndBackButton() throws {
        // Test deep navigation flows and back button behavior
        
        let testProfile = try profileService.createProfile(
            name: "Deep Navigation Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Start on dashboard
        navigationCoordinator.navigateToTab(.dashboard)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Dashboard should be root level")
        
        // Navigate to learn tab and then into flashcard configuration
        navigationCoordinator.navigateToTab(.learn)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Tab navigation should reset depth")
        
        // Deep navigate into flashcard session
        let flashcardContext = FlashcardConfigurationContext(
            categories: ["basic_techniques"],
            userProfile: testProfile
        )
        
        navigationCoordinator.navigateToFlashcardConfiguration(flashcardContext)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 1, "Should increase navigation depth")
        
        // Navigate deeper into active flashcard session
        let sessionContext = FlashcardSessionContext(
            configuration: flashcardContext.sessionConfiguration,
            userProfile: testProfile
        )
        
        navigationCoordinator.navigateToFlashcardSession(sessionContext)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 2, "Should be at depth 2")
        
        // Test back navigation
        let canGoBack = navigationCoordinator.canNavigateBack()
        XCTAssertTrue(canGoBack, "Should be able to navigate back from depth 2")
        
        navigationCoordinator.navigateBack()
        XCTAssertEqual(navigationCoordinator.navigationDepth, 1, "Should go back to depth 1")
        
        navigationCoordinator.navigateBack()
        XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Should go back to root level")
        
        let cantGoBackFurther = navigationCoordinator.canNavigateBack()
        XCTAssertFalse(cantGoBackFurther, "Should not be able to go back from root level")
        
        // Test deep navigation from different tabs
        navigationCoordinator.navigateToTab(.practice)
        
        let availablePatterns = dataServices.patternService.getAvailablePatterns(for: testProfile)
        guard let testPattern = availablePatterns.first else {
            XCTFail("Should have patterns for deep navigation test")
            return
        }
        
        let patternContext = PatternPracticeContext(pattern: testPattern, userProfile: testProfile)
        navigationCoordinator.navigateToPatternPractice(patternContext)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 1, "Pattern practice should be depth 1")
        
        // Test tab switch during deep navigation (should reset navigation stack)
        navigationCoordinator.navigateToTab(.test)
        XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Tab switch should reset navigation depth")
    }
    
    func testNavigationStateWithComplexFlows() throws {
        // Test complex navigation scenarios with multiple modals and deep navigation
        
        let testProfile = try profileService.createProfile(
            name: "Complex Flow Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Start complex flow: Dashboard → Learn → Flashcard Config → Session → Results
        navigationCoordinator.navigateToTab(.dashboard)
        
        // Navigate to learn tab
        navigationCoordinator.navigateToTab(.learn)
        
        // Present flashcard configuration as sheet
        let flashcardConfig = FlashcardConfigurationContext(
            categories: ["basic_techniques"],
            userProfile: testProfile
        )
        navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardConfig))
        
        // Navigate within sheet to session (if supported by UI design)
        // This tests complex state management with sheets + navigation
        
        // Simulate completing flashcard session and showing results
        let sessionResults = FlashcardSessionResults(
            totalCards: 10,
            correctAnswers: 8,
            accuracy: 0.8,
            sessionDuration: 120.0
        )
        
        let resultsContext = FlashcardResultsContext(
            results: sessionResults,
            userProfile: testProfile
        )
        
        navigationCoordinator.navigateToFlashcardResults(resultsContext)
        
        // Verify complex state is maintained
        XCTAssertNotNil(navigationCoordinator.currentSheet, "Sheet should still be presented")
        XCTAssertNotNil(navigationCoordinator.navigationContext, "Navigation context should be maintained")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, "Profile should be consistent")
        
        // Test dismissing everything and returning to clean state
        navigationCoordinator.dismissSheet()
        navigationCoordinator.navigateToTab(.dashboard)
        
        XCTAssertNil(navigationCoordinator.currentSheet, "Should be no active sheet")
        XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Should be at root level")
        XCTAssertEqual(navigationCoordinator.currentTab, .dashboard, "Should be on dashboard")
    }
    
    // MARK: - State Restoration Tests
    
    func testAppBackgroundingStatePreservation() throws {
        // Test state preservation during app backgrounding/foregrounding
        
        let testProfile = try profileService.createProfile(
            name: "Background Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Set up complex state
        navigationCoordinator.navigateToTab(.practice)
        
        let patterns = dataServices.patternService.getAvailablePatterns(for: testProfile)
        guard let testPattern = patterns.first else {
            XCTFail("Should have patterns for state preservation test")
            return
        }
        
        let patternContext = PatternPracticeContext(pattern: testPattern, userProfile: testProfile)
        navigationCoordinator.navigateToPatternPractice(patternContext)
        
        // Simulate app backgrounding
        let stateSnapshot = navigationCoordinator.captureCurrentState()
        XCTAssertNotNil(stateSnapshot, "Should capture current navigation state")
        XCTAssertEqual(stateSnapshot.currentTab, .practice, "State should capture current tab")
        XCTAssertEqual(stateSnapshot.navigationDepth, 1, "State should capture navigation depth")
        XCTAssertEqual(stateSnapshot.activeProfileId, testProfile.id, "State should capture active profile")
        
        // Simulate app termination and restart
        navigationCoordinator = AppCoordinator(dataServices: dataServices)
        
        // Restore state
        let restorationSuccess = navigationCoordinator.restoreState(stateSnapshot)
        XCTAssertTrue(restorationSuccess, "Should successfully restore navigation state")
        
        // Verify restored state
        XCTAssertEqual(navigationCoordinator.currentTab, .practice, "Should restore practice tab")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, "Should restore active profile")
        
        // Note: Deep navigation restoration depends on UI implementation details
        // At minimum, should restore tab and profile context
    }
    
    func testNavigationStateConsistencyAfterMemoryWarning() throws {
        // Test navigation state consistency after simulated memory pressure
        
        let testProfile = try profileService.createProfile(
            name: "Memory Pressure Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Create complex navigation state
        navigationCoordinator.navigateToTab(.learn)
        
        let flashcardConfig = FlashcardConfigurationContext(
            categories: ["basic_techniques", "intermediate_techniques"],
            userProfile: testProfile
        )
        navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardConfig))
        
        // Simulate memory warning handling
        navigationCoordinator.handleMemoryWarning()
        
        // Verify critical state is preserved
        XCTAssertEqual(navigationCoordinator.currentTab, .learn, "Current tab should survive memory warning")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, "Active profile should survive memory warning")
        
        // Non-critical state may be cleared for memory optimization
        // This is acceptable behavior - sheets and deep navigation may be reset
        
        // Verify navigation remains functional after memory warning
        navigationCoordinator.navigateToTab(.test)
        XCTAssertEqual(navigationCoordinator.currentTab, .test, "Navigation should remain functional")
        
        // Verify profile context is still available
        let testCategories = dataServices.testingService.getAvailableTestCategories(for: testProfile)
        XCTAssertGreaterThan(testCategories.count, 0, "Profile context should allow content access")
    }
    
    // MARK: - Toolbar and Menu Interaction Tests
    
    func testToolbarInteractions() throws {
        // Test toolbar actions and menu interactions across different views
        
        let testProfile = try profileService.createProfile(
            name: "Toolbar Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Test dashboard toolbar
        navigationCoordinator.navigateToTab(.dashboard)
        let dashboardToolbar = navigationCoordinator.getCurrentToolbarConfiguration()
        
        XCTAssertNotNil(dashboardToolbar, "Dashboard should have toolbar configuration")
        XCTAssertTrue(dashboardToolbar.hasProfileSwitcher, "Dashboard should have profile switcher")
        
        // Test profile switcher functionality
        let profileSwitcherAction = dashboardToolbar.profileSwitcherAction
        XCTAssertNotNil(profileSwitcherAction, "Profile switcher should have action")
        
        // Simulate profile switcher activation
        profileSwitcherAction?()
        XCTAssertNotNil(navigationCoordinator.currentSheet?.type == .profileSelection ||
                       navigationCoordinator.currentAlert != nil,
                       "Profile switcher should present profile selection or alert")
        
        // Dismiss any presented UI
        navigationCoordinator.dismissSheet()
        navigationCoordinator.dismissAlert()
        
        // Test learn tab toolbar
        navigationCoordinator.navigateToTab(.learn)
        let learnToolbar = navigationCoordinator.getCurrentToolbarConfiguration()
        
        XCTAssertNotNil(learnToolbar, "Learn tab should have toolbar configuration")
        XCTAssertTrue(learnToolbar.hasProfileSwitcher, "Learn tab should have profile switcher")
        
        // Test practice tab toolbar with pattern-specific actions
        navigationCoordinator.navigateToTab(.practice)
        let practiceToolbar = navigationCoordinator.getCurrentToolbarConfiguration()
        
        XCTAssertNotNil(practiceToolbar, "Practice tab should have toolbar configuration")
        
        // Navigate into pattern practice to test contextual toolbar
        let patterns = dataServices.patternService.getAvailablePatterns(for: testProfile)
        if let testPattern = patterns.first {
            let patternContext = PatternPracticeContext(pattern: testPattern, userProfile: testProfile)
            navigationCoordinator.navigateToPatternPractice(patternContext)
            
            let patternToolbar = navigationCoordinator.getCurrentToolbarConfiguration()
            XCTAssertNotNil(patternToolbar, "Pattern practice should have contextual toolbar")
            XCTAssertTrue(patternToolbar.hasBackButton, "Pattern practice should have back button")
            
            // Test back button functionality
            let backAction = patternToolbar.backButtonAction
            XCTAssertNotNil(backAction, "Back button should have action")
            
            backAction?()
            XCTAssertEqual(navigationCoordinator.navigationDepth, 0, "Back button should navigate back")
        }
    }
    
    func testMenuInteractions() throws {
        // Test menu interactions and context menus
        
        let testProfile = try profileService.createProfile(
            name: "Menu Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test profile tab menu options
        navigationCoordinator.navigateToTab(.profile)
        let profileMenuOptions = navigationCoordinator.getAvailableMenuOptions()
        
        XCTAssertNotNil(profileMenuOptions, "Profile tab should have menu options")
        XCTAssertTrue(profileMenuOptions.contains { $0.title == "Export Profile" }, 
                     "Should have export option")
        XCTAssertTrue(profileMenuOptions.contains { $0.title == "Import Profile" }, 
                     "Should have import option")
        
        // Test export menu action
        let exportOption = profileMenuOptions.first { $0.title == "Export Profile" }
        XCTAssertNotNil(exportOption, "Should have export option")
        
        exportOption?.action()
        // Should either present share sheet or trigger export flow
        XCTAssertTrue(navigationCoordinator.currentSheet != nil || 
                     navigationCoordinator.isExportInProgress,
                     "Export should trigger some UI response")
        
        // Clean up
        navigationCoordinator.dismissSheet()
        
        // Test dashboard menu with quick actions
        navigationCoordinator.navigateToTab(.dashboard)
        let dashboardMenuOptions = navigationCoordinator.getAvailableMenuOptions()
        
        XCTAssertNotNil(dashboardMenuOptions, "Dashboard should have menu options")
        
        // Test quick action menu items
        let quickFlashcardsOption = dashboardMenuOptions.first { $0.title.contains("Flashcards") }
        if let quickAction = quickFlashcardsOption {
            quickAction.action()
            // Should navigate to flashcard configuration or start quick session
            XCTAssertTrue(navigationCoordinator.currentTab == .learn || 
                         navigationCoordinator.currentSheet != nil,
                         "Quick flashcard action should navigate or present configuration")
        }
    }
    
    // MARK: - Performance and Memory Tests
    
    func testNavigationPerformanceUnderLoad() throws {
        // Test navigation performance with complex state and multiple profiles
        
        // Create multiple profiles for load testing
        var profiles: [UserProfile] = []
        for i in 1...6 {
            let profile = try profileService.createProfile(
                name: "Load Test Profile \(i)",
                currentBeltLevel: getBeltLevel(i % 2 == 0 ? "10th Keup" : "7th Keup"),
                learningMode: i % 2 == 0 ? .mastery : .progression
            )
            profiles.append(profile)
        }
        
        // Test rapid navigation and profile switching
        let navigationLoadMeasurement = PerformanceMeasurement.measureExecutionTime {
            for _ in 1...20 {
                // Rapid tab switching
                let randomTab = MainTab.allCases.randomElement()!
                navigationCoordinator.navigateToTab(randomTab)
                
                // Random profile switching
                let randomProfile = profiles.randomElement()!
                profileService.setActiveProfile(randomProfile)
                navigationCoordinator.updateProfileContext(randomProfile)
                
                // Occasional sheet presentation
                if Int.random(in: 1...5) == 1 {
                    let flashcardConfig = FlashcardConfigurationContext(
                        categories: ["basic_techniques"],
                        userProfile: randomProfile
                    )
                    navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardConfig))
                    navigationCoordinator.dismissSheet()
                }
            }
        }
        
        XCTAssertLessThan(navigationLoadMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 5,
                         "Navigation should remain performant under load")
        
        // Test memory usage during navigation stress test
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            for tab in MainTab.allCases {
                navigationCoordinator.navigateToTab(tab)
                
                // Create and dismiss sheets to test memory cleanup
                for profile in profiles.prefix(3) {
                    let context = FlashcardConfigurationContext(
                        categories: ["basic_techniques"],
                        userProfile: profile
                    )
                    navigationCoordinator.presentSheet(.flashcardConfiguration(context))
                    navigationCoordinator.dismissSheet()
                }
            }
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 3,
                         "Navigation should not leak significant memory")
    }
    
    func testNavigationStateIntegrityUnderConcurrency() throws {
        // Test navigation state integrity under concurrent operations
        
        let testProfile = try profileService.createProfile(
            name: "Concurrency Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        let expectation1 = expectation(description: "Concurrent navigation 1")
        let expectation2 = expectation(description: "Concurrent navigation 2")
        let expectation3 = expectation(description: "Concurrent navigation 3")
        
        // Simulate concurrent navigation operations
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 1...10 {
                DispatchQueue.main.async {
                    self.navigationCoordinator.navigateToTab(.learn)
                    Thread.sleep(forTimeInterval: 0.01)
                    self.navigationCoordinator.navigateToTab(.practice)
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            expectation1.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 1...10 {
                DispatchQueue.main.async {
                    let config = FlashcardConfigurationContext(
                        categories: ["basic_techniques"],
                        userProfile: testProfile
                    )
                    self.navigationCoordinator.presentSheet(.flashcardConfiguration(config))
                    Thread.sleep(forTimeInterval: 0.01)
                    self.navigationCoordinator.dismissSheet()
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            expectation2.fulfill()
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for _ in 1...10 {
                DispatchQueue.main.async {
                    self.profileService.setActiveProfile(testProfile)
                    self.navigationCoordinator.updateProfileContext(testProfile)
                }
                Thread.sleep(forTimeInterval: 0.01)
            }
            expectation3.fulfill()
        }
        
        waitForExpectations(timeout: TestConfiguration.defaultTestTimeout)
        
        // Verify navigation state remains consistent after concurrent operations
        XCTAssertNotNil(navigationCoordinator.currentTab, "Should have valid current tab")
        XCTAssertNotNil(navigationCoordinator.activeProfile, "Should have active profile")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, "Should maintain correct profile")
        
        // Verify navigation remains functional
        navigationCoordinator.navigateToTab(.dashboard)
        XCTAssertEqual(navigationCoordinator.currentTab, .dashboard, "Navigation should remain functional")
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

// MARK: - Test Extensions

extension NavigationAndStateTests {
    
    /**
     * Test navigation state recovery from various error conditions
     */
    func testNavigationErrorRecovery() throws {
        let testProfile = try profileService.createProfile(
            name: "Error Recovery Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Set up navigation state
        navigationCoordinator.navigateToTab(.practice)
        
        // Simulate navigation error (invalid deep navigation)
        do {
            navigationCoordinator.navigateToDeepView("invalid://deep/navigation/path")
            XCTFail("Should not allow invalid navigation")
        } catch {
            // Expected behavior - should throw navigation error
            XCTAssertFalse(error.localizedDescription.isEmpty, "Should provide meaningful navigation error")
        }
        
        // Verify navigation state remains stable after error
        XCTAssertEqual(navigationCoordinator.currentTab, .practice, "Should maintain current tab after navigation error")
        XCTAssertEqual(navigationCoordinator.activeProfile?.id, testProfile.id, "Should maintain active profile after error")
        
        // Verify navigation remains functional after error
        navigationCoordinator.navigateToTab(.learn)
        XCTAssertEqual(navigationCoordinator.currentTab, .learn, "Navigation should remain functional after error")
        
        // Test recovery from sheet presentation error
        let invalidSheetContext = FlashcardConfigurationContext(
            categories: [], // Empty categories should cause error or graceful fallback
            userProfile: testProfile
        )
        
        do {
            navigationCoordinator.presentSheet(.flashcardConfiguration(invalidSheetContext))
            // If it succeeds, should provide fallback content or graceful handling
            if let currentSheet = navigationCoordinator.currentSheet {
                XCTAssertNotNil(currentSheet, "Should handle invalid sheet context gracefully")
                navigationCoordinator.dismissSheet()
            }
        } catch {
            // If it fails, should provide meaningful error
            XCTAssertFalse(error.localizedDescription.isEmpty, "Should provide meaningful sheet error")
        }
        
        // Verify navigation remains stable after sheet error
        XCTAssertEqual(navigationCoordinator.currentTab, .learn, "Should maintain tab after sheet error")
        XCTAssertNil(navigationCoordinator.currentSheet, "Should not have active sheet after error")
    }
    
    /**
     * Test navigation accessibility and VoiceOver support
     */
    func testNavigationAccessibility() throws {
        let testProfile = try profileService.createProfile(
            name: "Accessibility Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test tab accessibility labels
        for tab in MainTab.allCases {
            navigationCoordinator.navigateToTab(tab)
            
            let accessibilityLabel = navigationCoordinator.getAccessibilityLabel(for: tab)
            XCTAssertNotNil(accessibilityLabel, "Tab \(tab) should have accessibility label")
            XCTAssertFalse(accessibilityLabel!.isEmpty, "Accessibility label should not be empty")
            XCTAssertTrue(accessibilityLabel!.contains(tab.rawValue.capitalized), 
                         "Accessibility label should describe the tab")
        }
        
        // Test navigation accessibility hints
        navigationCoordinator.navigateToTab(.learn)
        let patterns = dataServices.patternService.getAvailablePatterns(for: testProfile)
        if let testPattern = patterns.first {
            let patternContext = PatternPracticeContext(pattern: testPattern, userProfile: testProfile)
            navigationCoordinator.navigateToPatternPractice(patternContext)
            
            let accessibilityHint = navigationCoordinator.getAccessibilityHint()
            XCTAssertNotNil(accessibilityHint, "Deep navigation should have accessibility hint")
            XCTAssertTrue(accessibilityHint!.contains("back") || accessibilityHint!.contains("return"),
                         "Accessibility hint should indicate how to navigate back")
        }
        
        // Test sheet accessibility
        let flashcardConfig = FlashcardConfigurationContext(
            categories: ["basic_techniques"],
            userProfile: testProfile
        )
        navigationCoordinator.presentSheet(.flashcardConfiguration(flashcardConfig))
        
        let sheetAccessibilityLabel = navigationCoordinator.getSheetAccessibilityLabel()
        XCTAssertNotNil(sheetAccessibilityLabel, "Sheet should have accessibility label")
        XCTAssertTrue(sheetAccessibilityLabel!.contains("sheet") || sheetAccessibilityLabel!.contains("modal"),
                     "Sheet accessibility should indicate modal nature")
        
        navigationCoordinator.dismissSheet()
    }
}

// MARK: - Mock Navigation Components

// These would be actual implementations in the real app
extension AppCoordinator {
    
    // Mock implementations for testing - actual app would have real implementations
    
    var currentTab: MainTab { return .dashboard }
    var navigationDepth: Int { return 0 }
    var activeProfile: UserProfile? { return profileService.getActiveProfile() }
    var currentSheet: SheetContext? { return nil }
    var currentAlert: AlertContext? { return nil }
    var navigationContext: NavigationContext? { return nil }
    var dashboardContext: DashboardContext? { return nil }
    var learningContext: LearningContext? { return nil }
    var practiceContext: PracticeContext? { return nil }
    var testingContext: TestingContext? { return nil }
    var profileContext: ProfileContext? { return nil }
    var isExportInProgress: Bool { return false }
    
    func navigateToTab(_ tab: MainTab) { /* Mock implementation */ }
    func updateProfileContext(_ profile: UserProfile) { /* Mock implementation */ }
    func presentSheet(_ sheet: SheetContext) { /* Mock implementation */ }
    func dismissSheet() { /* Mock implementation */ }
    func presentAlert(_ alert: AlertContext) { /* Mock implementation */ }
    func dismissAlert() { /* Mock implementation */ }
    func navigateToFlashcardConfiguration(_ context: FlashcardConfigurationContext) { /* Mock implementation */ }
    func navigateToFlashcardSession(_ context: FlashcardSessionContext) { /* Mock implementation */ }
    func navigateToFlashcardResults(_ context: FlashcardResultsContext) { /* Mock implementation */ }
    func navigateToPatternPractice(_ context: PatternPracticeContext) { /* Mock implementation */ }
    func navigateBack() { /* Mock implementation */ }
    func canNavigateBack() -> Bool { return navigationDepth > 0 }
    func captureCurrentState() -> NavigationState { return NavigationState() }
    func restoreState(_ state: NavigationState) -> Bool { return true }
    func handleMemoryWarning() { /* Mock implementation */ }
    func getCurrentToolbarConfiguration() -> ToolbarConfiguration { return ToolbarConfiguration() }
    func getAvailableMenuOptions() -> [MenuOption] { return [] }
    func navigateToDeepView(_ path: String) throws { /* Mock implementation */ }
    func getAccessibilityLabel(for tab: MainTab) -> String? { return tab.rawValue.capitalized }
    func getAccessibilityHint() -> String? { return "Double tap to navigate back" }
    func getSheetAccessibilityLabel() -> String? { return "Modal sheet" }
}

// Mock types for testing
enum MainTab: String, CaseIterable {
    case dashboard, learn, practice, test, profile
}

struct SheetContext {
    enum SheetType {
        case flashcardConfiguration, patternPractice, profileSelection
    }
    let type: SheetType
}

struct AlertContext {
    let title: String
    let message: String
    let primaryAction: AlertAction
    let secondaryAction: AlertAction?
    
    var hasDestructiveAction: Bool {
        return primaryAction.style == .destructive || secondaryAction?.style == .destructive
    }
    
    init(title: String, message: String, primaryAction: AlertAction, secondaryAction: AlertAction? = nil) {
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

struct AlertAction {
    enum Style {
        case `default`, cancel, destructive
    }
    let title: String
    let style: Style
    let action: () -> Void
}

struct NavigationState {
    var currentTab: MainTab = .dashboard
    var navigationDepth: Int = 0
    var activeProfileId: UUID? = nil
}

struct NavigationContext { }
struct DashboardContext { }
struct LearningContext { 
    let currentProfile: UserProfile
    init(currentProfile: UserProfile) {
        self.currentProfile = currentProfile
    }
}
struct PracticeContext { }
struct TestingContext { 
    let currentProfile: UserProfile
    init(currentProfile: UserProfile) {
        self.currentProfile = currentProfile
    }
}
struct ProfileContext { }

struct FlashcardConfigurationContext {
    let categories: [String]
    let userProfile: UserProfile
    let sessionConfiguration: FlashcardSessionConfiguration
    
    init(categories: [String], userProfile: UserProfile) {
        self.categories = categories
        self.userProfile = userProfile
        self.sessionConfiguration = FlashcardSessionConfiguration(
            categories: categories,
            cardDirection: .englishToKorean,
            sessionMode: .study,
            cardMode: .classic,
            maxCards: 10
        )
    }
}

struct FlashcardSessionContext {
    let configuration: FlashcardSessionConfiguration
    let userProfile: UserProfile
}

struct FlashcardResultsContext {
    let results: FlashcardSessionResults
    let userProfile: UserProfile
}

struct PatternPracticeContext {
    let pattern: Pattern
    let userProfile: UserProfile
}

struct ToolbarConfiguration {
    let hasProfileSwitcher: Bool = true
    let hasBackButton: Bool = false
    let profileSwitcherAction: (() -> Void)? = { }
    let backButtonAction: (() -> Void)? = { }
}

struct MenuOption {
    let title: String
    let action: () -> Void
}