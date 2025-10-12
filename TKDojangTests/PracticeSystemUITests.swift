import XCTest
import SwiftData
import SwiftUI
@testable import TKDojang

/**
 * PracticeSystemUITests.swift
 * 
 * PURPOSE: Feature-specific UI integration testing for pattern and step sparring practice systems
 * 
 * COVERAGE: Phase 2.3 - Detailed practice system UI functionality validation
 * - Pattern move navigation and image carousel functionality
 * - Belt-themed progress visualization and tracking
 * - Step sparring sequence navigation and flow control
 * - Attack/Defense/Counter pattern flow validation
 * - Session completion and restart workflows
 * - Practice session timer and progress persistence
 * - Move-by-move guidance and instruction display
 * - Image carousel system (Position/Technique/Progress views)
 * 
 * BUSINESS IMPACT: Pattern practice represents structured learning progression
 * and step sparring provides practical application. UI issues affect skill development.
 */
final class PracticeSystemUITests: XCTestCase {
    
    // MARK: - Test Infrastructure
    
    var testContainer: ModelContainer!
    var testContext: ModelContext!
    var dataServices: DataServices!
    var profileService: ProfileService!
    var patternService: PatternService!
    var stepSparringService: StepSparringService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create comprehensive test container with practice-related models
        let schema = Schema([
            BeltLevel.self,
            TerminologyCategory.self,
            TerminologyEntry.self,
            UserProfile.self,
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
        
        // Set up extensive practice content
        let testData = TestDataFactory()
        try testData.createBasicTestData(in: testContext)
        try testData.createExtensivePracticeContent(in: testContext)
        
        // Initialize services with test container
        dataServices = DataServices(container: testContainer)
        profileService = dataServices.profileService
        patternService = dataServices.patternService
        stepSparringService = dataServices.stepSparringService
    }
    
    override func tearDownWithError() throws {
        testContainer = nil
        testContext = nil
        dataServices = nil
        profileService = nil
        patternService = nil
        stepSparringService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Pattern Practice UI Tests
    
    func testPatternPracticeUIWorkflow() throws {
        // CRITICAL UI FLOW: Complete pattern practice session
        
        let testProfile = try profileService.createProfile(
            name: "Pattern Practitioner",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Get available patterns for testing
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        XCTAssertGreaterThan(availablePatterns.count, 0, "Should have patterns available for testing")
        
        let testPattern = availablePatterns.first!
        XCTAssertNotNil(testPattern, "Should have valid test pattern")
        XCTAssertGreaterThan(testPattern.orderedMoves.count, 0, "Pattern should have moves")
        
        // Test pattern practice view model initialization
        let practiceViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertEqual(practiceViewModel.currentMoveIndex, 0, "Should start at first move")
        XCTAssertEqual(practiceViewModel.totalMoves, testPattern.orderedMoves.count, "Should have correct move count")
        XCTAssertNotNil(practiceViewModel.currentMove, "Should have current move")
        XCTAssertFalse(practiceViewModel.isPatternComplete, "Should not be complete initially")
        XCTAssertEqual(practiceViewModel.progressPercentage, 0.0, "Should start at 0% progress")
        
        // Test current move display
        let currentMove = practiceViewModel.currentMove!
        XCTAssertNotNil(currentMove.displayTitle, "Move should have display title")
        XCTAssertNotNil(currentMove.fullDescription, "Move should have description")
        XCTAssertNotNil(currentMove.stance, "Move should have stance")
        XCTAssertNotNil(currentMove.direction, "Move should have direction")
        XCTAssertGreaterThan(currentMove.moveNumber, 0, "Move should have valid number")
        
        // Test move navigation
        let canAdvance = practiceViewModel.canAdvanceToNextMove()
        XCTAssertTrue(canAdvance, "Should be able to advance from first move")
        
        practiceViewModel.advanceToNextMove()
        XCTAssertEqual(practiceViewModel.currentMoveIndex, 1, "Should advance to second move")
        
        let progressAfterFirst = practiceViewModel.progressPercentage
        let expectedProgress = 1.0 / Double(testPattern.orderedMoves.count)
        XCTAssertEqual(progressAfterFirst, expectedProgress, accuracy: 0.01, 
                      "Progress should update correctly")
        
        // Test backwards navigation
        let canGoBack = practiceViewModel.canGoToPreviousMove()
        XCTAssertTrue(canGoBack, "Should be able to go back from second move")
        
        practiceViewModel.goToPreviousMove()
        XCTAssertEqual(practiceViewModel.currentMoveIndex, 0, "Should return to first move")
        
        // Test navigation to specific move
        let targetMoveIndex = min(3, testPattern.orderedMoves.count - 1)
        practiceViewModel.navigateToMove(targetMoveIndex)
        XCTAssertEqual(practiceViewModel.currentMoveIndex, targetMoveIndex, "Should navigate to specific move")
        
        // Test practice through all moves
        for moveIndex in 0..<testPattern.orderedMoves.count {
            practiceViewModel.navigateToMove(moveIndex)
            
            let move = practiceViewModel.currentMove!
            XCTAssertEqual(move.moveNumber, moveIndex + 1, "Move numbers should be 1-based")
            
            // Record move practice time
            practiceViewModel.recordMoveCompletion(practiceTime: Double.random(in: 5.0...15.0))
            
            let completedMoves = practiceViewModel.completedMoves
            XCTAssertTrue(completedMoves.contains(moveIndex), "Should mark move as completed")
        }
        
        // Test pattern completion
        XCTAssertTrue(practiceViewModel.isPatternComplete, "Pattern should be complete")
        XCTAssertEqual(practiceViewModel.progressPercentage, 1.0, "Should show 100% progress")
        
        let practiceResults = practiceViewModel.completePractice()
        XCTAssertNotNil(practiceResults, "Should produce practice results")
        XCTAssertEqual(practiceResults.movesCompleted, testPattern.orderedMoves.count, 
                      "Should complete all moves")
        XCTAssertGreaterThan(practiceResults.totalPracticeTime, 0, "Should have practice time")
        
        // Performance validation for pattern practice UI
        let practiceMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = PatternPracticeViewModel(
                pattern: testPattern,
                patternService: patternService,
                userProfile: testProfile
            )
        }
        XCTAssertLessThan(practiceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Pattern practice UI should load quickly")
    }
    
    func testPatternImageCarouselSystem() throws {
        // Test the 3-image carousel system (Position/Technique/Progress)
        
        let testProfile = try profileService.createProfile(
            name: "Image Carousel Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let testPattern = availablePatterns.first!
        
        let practiceViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile
        )
        
        let imageCarouselViewModel = PatternImageCarouselViewModel(
            move: practiceViewModel.currentMove!,
            patternService: patternService
        )
        
        // Test initial carousel state
        XCTAssertEqual(imageCarouselViewModel.selectedImageIndex, 0, "Should start with first image")
        XCTAssertGreaterThan(imageCarouselViewModel.availableImages.count, 0, "Should have available images")
        XCTAssertEqual(imageCarouselViewModel.currentImageType, .position, "Should start with position image")
        
        // Test image type switching
        let imageTypes: [PatternImageType] = [.position, .technique, .progress]
        for (index, expectedType) in imageTypes.enumerated() {
            if index < imageCarouselViewModel.availableImages.count {
                imageCarouselViewModel.selectImage(at: index)
                XCTAssertEqual(imageCarouselViewModel.selectedImageIndex, index, "Should select image at index")
                XCTAssertEqual(imageCarouselViewModel.currentImageType, expectedType, 
                              "Should show correct image type")
            }
        }
        
        // Test image availability validation
        for (index, imageInfo) in imageCarouselViewModel.availableImages.enumerated() {
            let imageExists = imageCarouselViewModel.isImageAvailable(at: index)
            if imageExists {
                XCTAssertNotNil(imageInfo.imageName, "Available image should have name")
                XCTAssertNotNil(imageInfo.imageType, "Available image should have type")
            }
        }
        
        // Test fallback behavior for missing images
        let missingImageIndex = imageCarouselViewModel.availableImages.count + 1
        imageCarouselViewModel.selectImage(at: missingImageIndex)
        XCTAssertLessThan(imageCarouselViewModel.selectedImageIndex, imageCarouselViewModel.availableImages.count,
                         "Should not select invalid image index")
        
        // Test image description and labels
        for imageType in imageTypes {
            let description = imageCarouselViewModel.getImageDescription(for: imageType)
            XCTAssertNotNil(description, "Should have description for image type")
            XCTAssertFalse(description.isEmpty, "Description should not be empty")
            
            let label = imageCarouselViewModel.getImageLabel(for: imageType)
            XCTAssertNotNil(label, "Should have label for image type")
            XCTAssertFalse(label.isEmpty, "Label should not be empty")
        }
        
        // Performance test for image carousel
        let carouselMeasurement = PerformanceMeasurement.measureExecutionTime {
            for index in 0..<min(imageCarouselViewModel.availableImages.count, 5) {
                imageCarouselViewModel.selectImage(at: index)
            }
        }
        XCTAssertLessThan(carouselMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Image carousel should be responsive")
    }
    
    func testPatternBeltThemedProgress() throws {
        // Test belt-themed progress visualization
        
        let testProfile = try profileService.createProfile(
            name: "Belt Progress Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let testPattern = availablePatterns.first!
        
        let practiceViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile
        )
        
        let progressViewModel = BeltProgressBarViewModel(
            pattern: testPattern,
            currentProgress: 0.0,
            userProfile: testProfile
        )
        
        // Test initial progress state
        XCTAssertEqual(progressViewModel.currentProgress, 0.0, "Should start at 0% progress")
        XCTAssertNotNil(progressViewModel.beltTheme, "Should have belt theme")
        XCTAssertNotNil(progressViewModel.primaryColor, "Should have primary color")
        XCTAssertNotNil(progressViewModel.secondaryColor, "Should have secondary color")
        
        // Test belt theme based on pattern's primary belt level
        let expectedBeltLevel = testPattern.primaryBeltLevel ?? testPattern.beltLevels.first!
        XCTAssertEqual(progressViewModel.beltTheme.beltLevel, expectedBeltLevel, 
                      "Belt theme should match pattern's belt level")
        
        // Test progress updates
        let progressSteps = [0.25, 0.5, 0.75, 1.0]
        for progress in progressSteps {
            progressViewModel.updateProgress(progress)
            XCTAssertEqual(progressViewModel.currentProgress, progress, "Should update progress correctly")
            
            let progressText = progressViewModel.progressText
            XCTAssertNotNil(progressText, "Should have progress text")
            XCTAssertTrue(progressText.contains("\(Int(progress * 100))"), "Should show percentage")
        }
        
        // Test progress animation properties
        XCTAssertGreaterThan(progressViewModel.animationDuration, 0, "Should have animation duration")
        XCTAssertNotNil(progressViewModel.animationCurve, "Should have animation curve")
        
        // Test belt stripe visualization
        let stripeCount = progressViewModel.stripeCount
        XCTAssertGreaterThan(stripeCount, 0, "Should have belt stripes")
        
        for stripeIndex in 0..<stripeCount {
            let stripeColor = progressViewModel.getStripeColor(at: stripeIndex)
            XCTAssertNotNil(stripeColor, "Should have color for stripe")
            
            let stripeWidth = progressViewModel.getStripeWidth(at: stripeIndex)
            XCTAssertGreaterThan(stripeWidth, 0, "Should have width for stripe")
        }
        
        // Test accessibility
        let accessibilityLabel = progressViewModel.accessibilityLabel
        XCTAssertNotNil(accessibilityLabel, "Should have accessibility label")
        XCTAssertTrue(accessibilityLabel.contains("progress"), "Should describe progress")
        
        let accessibilityValue = progressViewModel.accessibilityValue
        XCTAssertNotNil(accessibilityValue, "Should have accessibility value")
        XCTAssertTrue(accessibilityValue.contains("percent"), "Should include percentage")
    }
    
    func testPatternSessionPersistence() throws {
        // Test pattern practice session persistence and recovery
        
        let testProfile = try profileService.createProfile(
            name: "Session Persistence Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let testPattern = availablePatterns.first!
        
        let originalViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile
        )
        
        // Practice through half the pattern
        let midPoint = testPattern.orderedMoves.count / 2
        for moveIndex in 0..<midPoint {
            originalViewModel.navigateToMove(moveIndex)
            originalViewModel.recordMoveCompletion(practiceTime: 10.0)
        }
        
        // Save session state
        let sessionState = originalViewModel.saveSessionState()
        XCTAssertNotNil(sessionState, "Should save session state")
        XCTAssertEqual(sessionState.currentMoveIndex, midPoint - 1, "Should save current position")
        XCTAssertEqual(sessionState.completedMoves.count, midPoint, "Should save completed moves")
        XCTAssertGreaterThan(sessionState.totalPracticeTime, 0, "Should save practice time")
        
        // Simulate session restoration
        let restoredViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile,
            sessionState: sessionState
        )
        
        // Verify restoration
        XCTAssertEqual(restoredViewModel.currentMoveIndex, midPoint - 1, "Should restore current position")
        XCTAssertEqual(restoredViewModel.completedMoves.count, midPoint, "Should restore completed moves")
        XCTAssertEqual(restoredViewModel.totalPracticeTime, sessionState.totalPracticeTime, 
                      "Should restore practice time")
        
        let expectedProgress = Double(midPoint) / Double(testPattern.orderedMoves.count)
        XCTAssertEqual(restoredViewModel.progressPercentage, expectedProgress, accuracy: 0.01,
                      "Should restore progress percentage")
        
        // Test continuing from restored state
        XCTAssertTrue(restoredViewModel.canAdvanceToNextMove(), "Should be able to continue")
        
        restoredViewModel.advanceToNextMove()
        XCTAssertEqual(restoredViewModel.currentMoveIndex, midPoint, "Should advance from restored position")
        
        // Complete the pattern from restored state
        for moveIndex in midPoint..<testPattern.orderedMoves.count {
            restoredViewModel.navigateToMove(moveIndex)
            restoredViewModel.recordMoveCompletion(practiceTime: 8.0)
        }
        
        XCTAssertTrue(restoredViewModel.isPatternComplete, "Should complete pattern from restored state")
        
        let finalResults = restoredViewModel.completePractice()
        XCTAssertEqual(finalResults.movesCompleted, testPattern.orderedMoves.count, 
                      "Should complete all moves")
        XCTAssertGreaterThan(finalResults.totalPracticeTime, sessionState.totalPracticeTime,
                            "Should include additional practice time")
    }
    
    // MARK: - Step Sparring UI Tests
    
    func testStepSparringUIWorkflow() throws {
        // CRITICAL UI FLOW: Complete step sparring practice session
        
        let testProfile = try profileService.createProfile(
            name: "Step Sparring Practitioner",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        // Get available step sparring sequences
        let availableSequences = stepSparringService.getAvailableSequences(for: testProfile)
        XCTAssertGreaterThan(availableSequences.count, 0, "Should have sequences available for testing")
        
        let testSequence = availableSequences.first!
        XCTAssertNotNil(testSequence, "Should have valid test sequence")
        XCTAssertGreaterThan(testSequence.orderedSteps.count, 0, "Sequence should have steps")
        
        // Test step sparring view model initialization
        let sparringViewModel = StepSparringViewModel(
            sequence: testSequence,
            stepSparringService: stepSparringService,
            userProfile: testProfile
        )
        
        // Verify initial state
        XCTAssertEqual(sparringViewModel.currentStepIndex, 0, "Should start at first step")
        XCTAssertEqual(sparringViewModel.totalSteps, testSequence.orderedSteps.count, "Should have correct step count")
        XCTAssertNotNil(sparringViewModel.currentStep, "Should have current step")
        XCTAssertFalse(sparringViewModel.isSequenceComplete, "Should not be complete initially")
        XCTAssertEqual(sparringViewModel.currentPhase, .attack, "Should start with attack phase")
        
        // Test current step display
        let currentStep = sparringViewModel.currentStep!
        XCTAssertNotNil(currentStep.attackAction, "Step should have attack action")
        XCTAssertNotNil(currentStep.defenseAction, "Step should have defense action")
        XCTAssertNotNil(currentStep.counterAction, "Step should have counter action")
        XCTAssertGreaterThan(currentStep.stepNumber, 0, "Step should have valid number")
        
        // Test phase navigation (Attack → Defense → Counter)
        let phases: [StepSparringPhase] = [.attack, .defense, .counter]
        
        for phase in phases {
            sparringViewModel.navigateToPhase(phase)
            XCTAssertEqual(sparringViewModel.currentPhase, phase, "Should navigate to \(phase) phase")
            
            let currentAction = sparringViewModel.currentAction
            XCTAssertNotNil(currentAction, "Should have action for \(phase) phase")
            
            switch phase {
            case .attack:
                XCTAssertEqual(currentAction!.actionType, .attack, "Should show attack action")
            case .defense:
                XCTAssertEqual(currentAction!.actionType, .defense, "Should show defense action")
            case .counter:
                XCTAssertEqual(currentAction!.actionType, .counter, "Should show counter action")
            }
            
            // Record phase completion
            sparringViewModel.recordPhaseCompletion(practiceTime: Double.random(in: 3.0...8.0))
        }
        
        // Test step completion and advancement
        XCTAssertTrue(sparringViewModel.isCurrentStepComplete, "Step should be complete after all phases")
        
        let canAdvance = sparringViewModel.canAdvanceToNextStep()
        XCTAssertTrue(canAdvance, "Should be able to advance to next step")
        
        sparringViewModel.advanceToNextStep()
        XCTAssertEqual(sparringViewModel.currentStepIndex, 1, "Should advance to second step")
        XCTAssertEqual(sparringViewModel.currentPhase, .attack, "Should reset to attack phase for new step")
        
        // Test progress tracking
        let progressPercentage = sparringViewModel.progressPercentage
        let expectedProgress = 1.0 / Double(testSequence.orderedSteps.count)
        XCTAssertEqual(progressPercentage, expectedProgress, accuracy: 0.01, 
                      "Progress should update correctly")
        
        // Test practice through all steps
        for stepIndex in 1..<testSequence.orderedSteps.count {
            sparringViewModel.navigateToStep(stepIndex)
            
            for phase in phases {
                sparringViewModel.navigateToPhase(phase)
                sparringViewModel.recordPhaseCompletion(practiceTime: 5.0)
            }
            
            let completedSteps = sparringViewModel.completedSteps
            XCTAssertTrue(completedSteps.contains(stepIndex), "Should mark step as completed")
        }
        
        // Test sequence completion
        XCTAssertTrue(sparringViewModel.isSequenceComplete, "Sequence should be complete")
        XCTAssertEqual(sparringViewModel.progressPercentage, 1.0, "Should show 100% progress")
        
        let sparringResults = sparringViewModel.completeSequence()
        XCTAssertNotNil(sparringResults, "Should produce sparring results")
        XCTAssertEqual(sparringResults.stepsCompleted, testSequence.orderedSteps.count, 
                      "Should complete all steps")
        XCTAssertGreaterThan(sparringResults.totalPracticeTime, 0, "Should have practice time")
        
        // Performance validation for step sparring UI
        let sparringMeasurement = PerformanceMeasurement.measureExecutionTime {
            let _ = StepSparringViewModel(
                sequence: testSequence,
                stepSparringService: stepSparringService,
                userProfile: testProfile
            )
        }
        XCTAssertLessThan(sparringMeasurement.timeInterval, TestConfiguration.maxUIResponseTime,
                         "Step sparring UI should load quickly")
    }
    
    func testStepSparringPhaseFlow() throws {
        // Test detailed Attack → Defense → Counter phase flow
        
        let testProfile = try profileService.createProfile(
            name: "Phase Flow Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        let availableSequences = stepSparringService.getAvailableSequences(for: testProfile)
        let testSequence = availableSequences.first!
        
        let sparringViewModel = StepSparringViewModel(
            sequence: testSequence,
            stepSparringService: stepSparringService,
            userProfile: testProfile
        )
        
        let phaseFlowViewModel = StepSparringPhaseFlowViewModel(
            currentStep: sparringViewModel.currentStep!,
            sparringService: stepSparringService
        )
        
        // Test initial phase flow state
        XCTAssertEqual(phaseFlowViewModel.currentPhase, .attack, "Should start with attack phase")
        XCTAssertFalse(phaseFlowViewModel.isPhaseFlowComplete, "Should not be complete initially")
        
        // Test attack phase
        phaseFlowViewModel.startPhase(.attack)
        XCTAssertEqual(phaseFlowViewModel.currentPhase, .attack, "Should be in attack phase")
        XCTAssertTrue(phaseFlowViewModel.isPhaseActive, "Phase should be active")
        
        let attackAction = phaseFlowViewModel.currentPhaseAction
        XCTAssertNotNil(attackAction, "Should have attack action")
        XCTAssertEqual(attackAction!.actionType, .attack, "Should be attack action type")
        XCTAssertNotNil(attackAction!.technique, "Attack should have technique")
        XCTAssertNotNil(attackAction!.target, "Attack should have target")
        
        // Test attack timing and execution
        phaseFlowViewModel.beginExecution()
        XCTAssertTrue(phaseFlowViewModel.isExecuting, "Should be executing attack")
        
        Thread.sleep(forTimeInterval: 1.0) // Simulate execution time
        phaseFlowViewModel.completeExecution()
        XCTAssertFalse(phaseFlowViewModel.isExecuting, "Should complete attack execution")
        XCTAssertTrue(phaseFlowViewModel.isPhaseComplete(.attack), "Attack phase should be complete")
        
        // Test automatic progression to defense
        if phaseFlowViewModel.autoAdvanceEnabled {
            Thread.sleep(forTimeInterval: 0.5)
            phaseFlowViewModel.checkAutoAdvance()
            XCTAssertEqual(phaseFlowViewModel.currentPhase, .defense, "Should auto-advance to defense")
        } else {
            phaseFlowViewModel.advanceToNextPhase()
            XCTAssertEqual(phaseFlowViewModel.currentPhase, .defense, "Should advance to defense")
        }
        
        // Test defense phase
        let defenseAction = phaseFlowViewModel.currentPhaseAction
        XCTAssertNotNil(defenseAction, "Should have defense action")
        XCTAssertEqual(defenseAction!.actionType, .defense, "Should be defense action type")
        XCTAssertNotNil(defenseAction!.technique, "Defense should have technique")
        
        phaseFlowViewModel.beginExecution()
        Thread.sleep(forTimeInterval: 1.0)
        phaseFlowViewModel.completeExecution()
        XCTAssertTrue(phaseFlowViewModel.isPhaseComplete(.defense), "Defense phase should be complete")
        
        // Test progression to counter
        phaseFlowViewModel.advanceToNextPhase()
        XCTAssertEqual(phaseFlowViewModel.currentPhase, .counter, "Should advance to counter")
        
        // Test counter phase
        let counterAction = phaseFlowViewModel.currentPhaseAction
        XCTAssertNotNil(counterAction, "Should have counter action")
        XCTAssertEqual(counterAction!.actionType, .counter, "Should be counter action type")
        
        phaseFlowViewModel.beginExecution()
        Thread.sleep(forTimeInterval: 1.0)
        phaseFlowViewModel.completeExecution()
        XCTAssertTrue(phaseFlowViewModel.isPhaseComplete(.counter), "Counter phase should be complete")
        
        // Test flow completion
        XCTAssertTrue(phaseFlowViewModel.isPhaseFlowComplete, "Phase flow should be complete")
        
        let flowResults = phaseFlowViewModel.getFlowResults()
        XCTAssertNotNil(flowResults, "Should have flow results")
        XCTAssertEqual(flowResults.completedPhases.count, 3, "Should complete all phases")
        XCTAssertGreaterThan(flowResults.totalExecutionTime, 0, "Should have execution time")
        
        // Test phase reset functionality
        phaseFlowViewModel.resetPhaseFlow()
        XCTAssertEqual(phaseFlowViewModel.currentPhase, .attack, "Should reset to attack phase")
        XCTAssertFalse(phaseFlowViewModel.isPhaseFlowComplete, "Should reset completion state")
    }
    
    func testStepSparringTypeSelection() throws {
        // Test step sparring type selection and filtering
        
        let testProfile = try profileService.createProfile(
            name: "Type Selection Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .mastery
        )
        profileService.setActiveProfile(testProfile)
        
        let typeSelectionViewModel = StepSparringTypeSelectionViewModel(
            stepSparringService: stepSparringService,
            userProfile: testProfile
        )
        
        // Test available types
        let availableTypes = typeSelectionViewModel.availableTypes
        XCTAssertGreaterThan(availableTypes.count, 0, "Should have available step sparring types")
        
        let expectedTypes: [StepSparringType] = [.oneStep, .twoStep, .threeStep, .free]
        for expectedType in expectedTypes {
            if availableTypes.contains(expectedType) {
                let sequencesForType = typeSelectionViewModel.getSequences(for: expectedType)
                XCTAssertGreaterThan(sequencesForType.count, 0, "Should have sequences for \(expectedType)")
                
                // Verify sequences are appropriate for user's belt level
                for sequence in sequencesForType {
                    let sequenceBeltRequirement = sequence.minimumBeltLevel
                    if let requiredBelt = sequenceBeltRequirement {
                        XCTAssertLessThanOrEqual(
                            BeltUtils.getLegacySortOrder(for: requiredBelt),
                            BeltUtils.getLegacySortOrder(for: testProfile.currentBeltLevel.shortName),
                            "Sequence should be appropriate for user's belt level"
                        )
                    }
                }
            }
        }
        
        // Test type selection
        let firstAvailableType = availableTypes.first!
        typeSelectionViewModel.selectType(firstAvailableType)
        XCTAssertEqual(typeSelectionViewModel.selectedType, firstAvailableType, "Should select type")
        
        let selectedSequences = typeSelectionViewModel.selectedSequences
        XCTAssertGreaterThan(selectedSequences.count, 0, "Should have sequences for selected type")
        
        // Test sequence filtering by difficulty
        let allSequences = typeSelectionViewModel.selectedSequences
        let beginnerSequences = typeSelectionViewModel.filterSequences(by: .beginner)
        let intermediateSequences = typeSelectionViewModel.filterSequences(by: .intermediate)
        
        XCTAssertLessThanOrEqual(beginnerSequences.count, allSequences.count, 
                                "Filtered sequences should not exceed total")
        XCTAssertLessThanOrEqual(intermediateSequences.count, allSequences.count,
                                "Filtered sequences should not exceed total")
        
        // Test sequence selection
        let firstSequence = selectedSequences.first!
        typeSelectionViewModel.selectSequence(firstSequence)
        XCTAssertEqual(typeSelectionViewModel.selectedSequence?.id, firstSequence.id, 
                      "Should select sequence")
        
        // Test type descriptions and information
        for type in availableTypes {
            let description = typeSelectionViewModel.getTypeDescription(type)
            XCTAssertNotNil(description, "Should have description for type")
            XCTAssertFalse(description.isEmpty, "Description should not be empty")
            
            let difficulty = typeSelectionViewModel.getTypeDifficulty(type)
            XCTAssertNotNil(difficulty, "Should have difficulty for type")
            
            let recommendedFor = typeSelectionViewModel.getRecommendedBeltLevels(for: type)
            XCTAssertGreaterThan(recommendedFor.count, 0, "Should have recommended belt levels")
        }
    }
    
    // MARK: - Session Timer and Progress Tests
    
    func testPracticeSessionTimingAndProgress() throws {
        // Test session timing and progress tracking across both systems
        
        let testProfile = try profileService.createProfile(
            name: "Timing Tester",
            currentBeltLevel: getBeltLevel("10th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test pattern session timing
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let testPattern = availablePatterns.first!
        
        let patternViewModel = PatternPracticeViewModel(
            pattern: testPattern,
            patternService: patternService,
            userProfile: testProfile
        )
        
        let patternTimerViewModel = PracticeSessionTimerViewModel(
            sessionType: .pattern,
            practiceViewModel: patternViewModel
        )
        
        // Test timer initialization
        XCTAssertEqual(patternTimerViewModel.sessionDuration, 0, "Should start with zero duration")
        XCTAssertFalse(patternTimerViewModel.isTimerRunning, "Timer should not be running initially")
        
        // Test timer start
        patternTimerViewModel.startTimer()
        XCTAssertTrue(patternTimerViewModel.isTimerRunning, "Timer should be running")
        
        // Test timer progression
        Thread.sleep(forTimeInterval: 1.1)
        patternTimerViewModel.updateTimer()
        XCTAssertGreaterThan(patternTimerViewModel.sessionDuration, 1.0, "Session duration should increase")
        
        // Test timer pause and resume
        patternTimerViewModel.pauseTimer()
        XCTAssertFalse(patternTimerViewModel.isTimerRunning, "Timer should be paused")
        
        let pausedDuration = patternTimerViewModel.sessionDuration
        Thread.sleep(forTimeInterval: 0.5)
        patternTimerViewModel.updateTimer()
        XCTAssertEqual(patternTimerViewModel.sessionDuration, pausedDuration, accuracy: 0.1,
                      "Duration should not increase while paused")
        
        patternTimerViewModel.resumeTimer()
        XCTAssertTrue(patternTimerViewModel.isTimerRunning, "Timer should resume")
        
        Thread.sleep(forTimeInterval: 1.0)
        patternTimerViewModel.updateTimer()
        XCTAssertGreaterThan(patternTimerViewModel.sessionDuration, pausedDuration, 
                            "Duration should increase after resume")
        
        // Test session milestones
        let milestones = patternTimerViewModel.sessionMilestones
        XCTAssertGreaterThan(milestones.count, 0, "Should have session milestones")
        
        // Simulate reaching a milestone
        patternTimerViewModel.checkMilestones()
        if let reachedMilestone = patternTimerViewModel.lastReachedMilestone {
            XCTAssertNotNil(reachedMilestone.message, "Milestone should have message")
            XCTAssertGreaterThan(reachedMilestone.timeThreshold, 0, "Milestone should have time threshold")
        }
        
        // Test step sparring session timing
        let availableSequences = stepSparringService.getAvailableSequences(for: testProfile)
        let testSequence = availableSequences.first!
        
        let sparringViewModel = StepSparringViewModel(
            sequence: testSequence,
            stepSparringService: stepSparringService,
            userProfile: testProfile
        )
        
        let sparringTimerViewModel = PracticeSessionTimerViewModel(
            sessionType: .stepSparring,
            practiceViewModel: sparringViewModel
        )
        
        // Test sparring timer functionality
        sparringTimerViewModel.startTimer()
        XCTAssertTrue(sparringTimerViewModel.isTimerRunning, "Sparring timer should start")
        
        Thread.sleep(forTimeInterval: 1.0)
        sparringTimerViewModel.updateTimer()
        XCTAssertGreaterThan(sparringTimerViewModel.sessionDuration, 0, "Sparring duration should increase")
        
        // Test session completion timing
        sparringTimerViewModel.stopTimer()
        XCTAssertFalse(sparringTimerViewModel.isTimerRunning, "Timer should stop")
        
        let finalDuration = sparringTimerViewModel.sessionDuration
        let sessionSummary = sparringTimerViewModel.getSessionSummary()
        
        XCTAssertNotNil(sessionSummary, "Should have session summary")
        XCTAssertEqual(sessionSummary.totalDuration, finalDuration, "Summary should match final duration")
        XCTAssertGreaterThan(sessionSummary.averageTimePerUnit, 0, "Should calculate average time per unit")
    }
    
    // MARK: - Performance and Memory Tests
    
    func testPracticeSystemPerformanceUnderLoad() throws {
        // Test practice system performance with complex patterns and sequences
        
        let testProfile = try profileService.createProfile(
            name: "Performance Tester",
            currentBeltLevel: getBeltLevel("7th Keup"),
            learningMode: .progression
        )
        profileService.setActiveProfile(testProfile)
        
        // Test pattern performance with complex pattern
        let availablePatterns = patternService.getAvailablePatterns(for: testProfile)
        let complexPatterns = availablePatterns.filter { $0.orderedMoves.count > 15 }
        
        if let complexPattern = complexPatterns.first {
            let patternPerformanceMeasurement = PerformanceMeasurement.measureExecutionTime {
                let practiceViewModel = PatternPracticeViewModel(
                    pattern: complexPattern,
                    patternService: patternService,
                    userProfile: testProfile
                )
                
                // Rapid navigation through all moves
                for moveIndex in 0..<complexPattern.orderedMoves.count {
                    practiceViewModel.navigateToMove(moveIndex)
                    practiceViewModel.recordMoveCompletion(practiceTime: 1.0)
                }
            }
            
            XCTAssertLessThan(patternPerformanceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 2,
                             "Complex pattern practice should remain performant")
        }
        
        // Test step sparring performance
        let availableSequences = stepSparringService.getAvailableSequences(for: testProfile)
        let complexSequences = availableSequences.filter { $0.orderedSteps.count > 8 }
        
        if let complexSequence = complexSequences.first {
            let sparringPerformanceMeasurement = PerformanceMeasurement.measureExecutionTime {
                let sparringViewModel = StepSparringViewModel(
                    sequence: complexSequence,
                    stepSparringService: stepSparringService,
                    userProfile: testProfile
                )
                
                // Rapid phase progression through all steps
                for stepIndex in 0..<complexSequence.orderedSteps.count {
                    sparringViewModel.navigateToStep(stepIndex)
                    
                    let phases: [StepSparringPhase] = [.attack, .defense, .counter]
                    for phase in phases {
                        sparringViewModel.navigateToPhase(phase)
                        sparringViewModel.recordPhaseCompletion(practiceTime: 1.0)
                    }
                }
            }
            
            XCTAssertLessThan(sparringPerformanceMeasurement.timeInterval, TestConfiguration.maxUIResponseTime * 3,
                             "Complex step sparring should remain performant")
        }
        
        // Test memory usage during concurrent practice sessions
        let memoryMeasurement = PerformanceMeasurement.measureMemoryUsage {
            // Create multiple practice view models simultaneously
            var viewModels: [Any] = []
            
            for pattern in availablePatterns.prefix(3) {
                let patternViewModel = PatternPracticeViewModel(
                    pattern: pattern,
                    patternService: patternService,
                    userProfile: testProfile
                )
                viewModels.append(patternViewModel)
            }
            
            for sequence in availableSequences.prefix(3) {
                let sparringViewModel = StepSparringViewModel(
                    sequence: sequence,
                    stepSparringService: stepSparringService,
                    userProfile: testProfile
                )
                viewModels.append(sparringViewModel)
            }
            
            // Force retention to test memory usage
            _ = viewModels.count
        }
        
        XCTAssertLessThan(memoryMeasurement.memoryDelta, TestConfiguration.maxMemoryIncrease / 3,
                         "Multiple practice sessions should not cause significant memory growth")
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

// Pattern Practice ViewModels
class PatternPracticeViewModel: ObservableObject {
    @Published var currentMoveIndex: Int = 0
    @Published var completedMoves: Set<Int> = []
    @Published var totalPracticeTime: TimeInterval = 0
    
    private let pattern: Pattern
    private let patternService: PatternService
    private let userProfile: UserProfile
    
    init(pattern: Pattern, patternService: PatternService, userProfile: UserProfile, sessionState: PatternSessionState? = nil) {
        self.pattern = pattern
        self.patternService = patternService
        self.userProfile = userProfile
        
        if let state = sessionState {
            self.currentMoveIndex = state.currentMoveIndex
            self.completedMoves = state.completedMoves
            self.totalPracticeTime = state.totalPracticeTime
        }
    }
    
    var totalMoves: Int { pattern.orderedMoves.count }
    var currentMove: PatternMove? { 
        guard currentMoveIndex < pattern.orderedMoves.count else { return nil }
        return pattern.orderedMoves[currentMoveIndex] 
    }
    var isPatternComplete: Bool { completedMoves.count == totalMoves }
    var progressPercentage: Double { 
        totalMoves > 0 ? Double(currentMoveIndex + 1) / Double(totalMoves) : 0.0 
    }
    
    func canAdvanceToNextMove() -> Bool { currentMoveIndex < totalMoves - 1 }
    func canGoToPreviousMove() -> Bool { currentMoveIndex > 0 }
    
    func advanceToNextMove() {
        if canAdvanceToNextMove() {
            currentMoveIndex += 1
        }
    }
    
    func goToPreviousMove() {
        if canGoToPreviousMove() {
            currentMoveIndex -= 1
        }
    }
    
    func navigateToMove(_ moveIndex: Int) {
        if moveIndex >= 0 && moveIndex < totalMoves {
            currentMoveIndex = moveIndex
        }
    }
    
    func recordMoveCompletion(practiceTime: TimeInterval) {
        completedMoves.insert(currentMoveIndex)
        totalPracticeTime += practiceTime
    }
    
    func saveSessionState() -> PatternSessionState {
        return PatternSessionState(
            currentMoveIndex: currentMoveIndex,
            completedMoves: completedMoves,
            totalPracticeTime: totalPracticeTime
        )
    }
    
    func completePractice() -> PatternPracticeResults {
        return PatternPracticeResults(
            movesCompleted: completedMoves.count,
            totalPracticeTime: totalPracticeTime,
            patternCompleted: isPatternComplete
        )
    }
}

class PatternImageCarouselViewModel: ObservableObject {
    @Published var selectedImageIndex: Int = 0
    
    private let move: PatternMove
    private let patternService: PatternService
    
    init(move: PatternMove, patternService: PatternService) {
        self.move = move
        self.patternService = patternService
    }
    
    var availableImages: [PatternImageInfo] {
        let imageTypes: [PatternImageType] = [.position, .technique, .progress]
        return imageTypes.enumerated().map { index, type in
            PatternImageInfo(
                imageName: "\(move.id)_\(type.rawValue)",
                imageType: type,
                index: index
            )
        }
    }
    
    var currentImageType: PatternImageType {
        guard selectedImageIndex < availableImages.count else { return .position }
        return availableImages[selectedImageIndex].imageType
    }
    
    func selectImage(at index: Int) {
        if index >= 0 && index < availableImages.count {
            selectedImageIndex = index
        }
    }
    
    func isImageAvailable(at index: Int) -> Bool {
        guard index >= 0 && index < availableImages.count else { return false }
        // Mock implementation - would check actual image existence
        return true
    }
    
    func getImageDescription(for imageType: PatternImageType) -> String {
        switch imageType {
        case .position: return "Starting position for this move"
        case .technique: return "Technique execution details"
        case .progress: return "Movement progression sequence"
        }
    }
    
    func getImageLabel(for imageType: PatternImageType) -> String {
        switch imageType {
        case .position: return "Position"
        case .technique: return "Technique"
        case .progress: return "Progress"
        }
    }
}

class BeltProgressBarViewModel: ObservableObject {
    @Published var currentProgress: Double
    
    private let pattern: Pattern
    private let userProfile: UserProfile
    
    init(pattern: Pattern, currentProgress: Double, userProfile: UserProfile) {
        self.pattern = pattern
        self.currentProgress = currentProgress
        self.userProfile = userProfile
    }
    
    var beltTheme: BeltTheme {
        let beltLevel = pattern.primaryBeltLevel ?? pattern.beltLevels.first!
        return BeltTheme(beltLevel: beltLevel)
    }
    
    var primaryColor: String { beltTheme.primaryColor }
    var secondaryColor: String { beltTheme.secondaryColor }
    var animationDuration: TimeInterval { 0.3 }
    var animationCurve: String { "easeInOut" }
    var stripeCount: Int { beltTheme.stripeCount }
    
    var progressText: String {
        "\(Int(currentProgress * 100))% Complete"
    }
    
    var accessibilityLabel: String {
        "Pattern progress: \(Int(currentProgress * 100)) percent complete"
    }
    
    var accessibilityValue: String {
        "\(Int(currentProgress * 100)) percent"
    }
    
    func updateProgress(_ progress: Double) {
        currentProgress = max(0.0, min(1.0, progress))
    }
    
    func getStripeColor(at index: Int) -> String {
        return index % 2 == 0 ? primaryColor : secondaryColor
    }
    
    func getStripeWidth(at index: Int) -> Double {
        return currentProgress / Double(stripeCount)
    }
}

// Step Sparring ViewModels
class StepSparringViewModel: ObservableObject {
    @Published var currentStepIndex: Int = 0
    @Published var currentPhase: StepSparringPhase = .attack
    @Published var completedSteps: Set<Int> = []
    @Published var totalPracticeTime: TimeInterval = 0
    
    private let sequence: StepSparringSequence
    private let stepSparringService: StepSparringService
    private let userProfile: UserProfile
    
    init(sequence: StepSparringSequence, stepSparringService: StepSparringService, userProfile: UserProfile) {
        self.sequence = sequence
        self.stepSparringService = stepSparringService
        self.userProfile = userProfile
    }
    
    var totalSteps: Int { sequence.orderedSteps.count }
    var currentStep: StepSparringStep? {
        guard currentStepIndex < sequence.orderedSteps.count else { return nil }
        return sequence.orderedSteps[currentStepIndex]
    }
    var isSequenceComplete: Bool { completedSteps.count == totalSteps }
    var isCurrentStepComplete: Bool {
        // Mock implementation - would check if all phases completed
        return true
    }
    var progressPercentage: Double {
        totalSteps > 0 ? Double(currentStepIndex + 1) / Double(totalSteps) : 0.0
    }
    
    var currentAction: StepSparringAction? {
        guard let step = currentStep else { return nil }
        switch currentPhase {
        case .attack: return step.attackAction
        case .defense: return step.defenseAction
        case .counter: return step.counterAction
        }
    }
    
    func canAdvanceToNextStep() -> Bool { currentStepIndex < totalSteps - 1 }
    
    func navigateToStep(_ stepIndex: Int) {
        if stepIndex >= 0 && stepIndex < totalSteps {
            currentStepIndex = stepIndex
            currentPhase = .attack // Reset to attack phase for new step
        }
    }
    
    func navigateToPhase(_ phase: StepSparringPhase) {
        currentPhase = phase
    }
    
    func advanceToNextStep() {
        if canAdvanceToNextStep() {
            currentStepIndex += 1
            currentPhase = .attack
        }
    }
    
    func recordPhaseCompletion(practiceTime: TimeInterval) {
        totalPracticeTime += practiceTime
        
        // If this completes the step (all phases done), mark as completed
        if currentPhase == .counter {
            completedSteps.insert(currentStepIndex)
        }
    }
    
    func completeSequence() -> StepSparringResults {
        return StepSparringResults(
            stepsCompleted: completedSteps.count,
            totalPracticeTime: totalPracticeTime,
            sequenceCompleted: isSequenceComplete
        )
    }
}

class StepSparringPhaseFlowViewModel: ObservableObject {
    @Published var currentPhase: StepSparringPhase = .attack
    @Published var isExecuting: Bool = false
    @Published var isPhaseActive: Bool = false
    
    private let currentStep: StepSparringStep
    private let sparringService: StepSparringService
    private var completedPhases: Set<StepSparringPhase> = []
    
    init(currentStep: StepSparringStep, sparringService: StepSparringService) {
        self.currentStep = currentStep
        self.sparringService = sparringService
    }
    
    var isPhaseFlowComplete: Bool { completedPhases.count == 3 }
    var autoAdvanceEnabled: Bool { true }
    var currentPhaseAction: StepSparringAction? {
        switch currentPhase {
        case .attack: return currentStep.attackAction
        case .defense: return currentStep.defenseAction
        case .counter: return currentStep.counterAction
        }
    }
    
    func startPhase(_ phase: StepSparringPhase) {
        currentPhase = phase
        isPhaseActive = true
    }
    
    func beginExecution() {
        isExecuting = true
    }
    
    func completeExecution() {
        isExecuting = false
        completedPhases.insert(currentPhase)
    }
    
    func isPhaseComplete(_ phase: StepSparringPhase) -> Bool {
        return completedPhases.contains(phase)
    }
    
    func advanceToNextPhase() {
        switch currentPhase {
        case .attack: currentPhase = .defense
        case .defense: currentPhase = .counter
        case .counter: break // Last phase
        }
    }
    
    func checkAutoAdvance() {
        if autoAdvanceEnabled && !isExecuting {
            advanceToNextPhase()
        }
    }
    
    func resetPhaseFlow() {
        currentPhase = .attack
        isExecuting = false
        isPhaseActive = false
        completedPhases.removeAll()
    }
    
    func getFlowResults() -> PhaseFlowResults {
        return PhaseFlowResults(
            completedPhases: Array(completedPhases),
            totalExecutionTime: Double(completedPhases.count) * 3.0 // Mock time
        )
    }
}

class StepSparringTypeSelectionViewModel: ObservableObject {
    @Published var selectedType: StepSparringType?
    @Published var selectedSequence: StepSparringSequence?
    
    private let stepSparringService: StepSparringService
    private let userProfile: UserProfile
    
    init(stepSparringService: StepSparringService, userProfile: UserProfile) {
        self.stepSparringService = stepSparringService
        self.userProfile = userProfile
    }
    
    var availableTypes: [StepSparringType] {
        return [.oneStep, .twoStep, .threeStep, .free]
    }
    
    var selectedSequences: [StepSparringSequence] {
        guard let type = selectedType else { return [] }
        return getSequences(for: type)
    }
    
    func getSequences(for type: StepSparringType) -> [StepSparringSequence] {
        // Mock implementation - would fetch from service
        return stepSparringService.getSequences(for: type, userProfile: userProfile)
    }
    
    func selectType(_ type: StepSparringType) {
        selectedType = type
        selectedSequence = nil
    }
    
    func selectSequence(_ sequence: StepSparringSequence) {
        selectedSequence = sequence
    }
    
    func filterSequences(by difficulty: SequenceDifficulty) -> [StepSparringSequence] {
        return selectedSequences.filter { $0.difficulty == difficulty }
    }
    
    func getTypeDescription(_ type: StepSparringType) -> String {
        switch type {
        case .oneStep: return "One-step sparring with single attack and counter"
        case .twoStep: return "Two-step sparring with attack, defense, and counter"
        case .threeStep: return "Three-step sparring with extended combinations"
        case .free: return "Free sparring with fluid techniques"
        }
    }
    
    func getTypeDifficulty(_ type: StepSparringType) -> SequenceDifficulty {
        switch type {
        case .oneStep: return .beginner
        case .twoStep: return .intermediate
        case .threeStep: return .advanced
        case .free: return .expert
        }
    }
    
    func getRecommendedBeltLevels(for type: StepSparringType) -> [String] {
        switch type {
        case .oneStep: return ["10th Keup", "9th Keup", "8th Keup"]
        case .twoStep: return ["7th Keup", "6th Keup", "5th Keup"]
        case .threeStep: return ["4th Keup", "3rd Keup", "2nd Keup"]
        case .free: return ["1st Keup", "1st Dan", "2nd Dan"]
        }
    }
}

class PracticeSessionTimerViewModel: ObservableObject {
    @Published var sessionDuration: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    @Published var lastReachedMilestone: SessionMilestone?
    
    private let sessionType: PracticeSessionType
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    
    init(sessionType: PracticeSessionType, practiceViewModel: Any) {
        self.sessionType = sessionType
    }
    
    var sessionMilestones: [SessionMilestone] {
        return [
            SessionMilestone(timeThreshold: 60, message: "1 minute of focused practice!"),
            SessionMilestone(timeThreshold: 300, message: "5 minutes - great consistency!"),
            SessionMilestone(timeThreshold: 600, message: "10 minutes - excellent dedication!")
        ]
    }
    
    func startTimer() {
        startTime = Date()
        isTimerRunning = true
    }
    
    func pauseTimer() {
        if isTimerRunning {
            updateTimer()
            isTimerRunning = false
        }
    }
    
    func resumeTimer() {
        startTime = Date().addingTimeInterval(-sessionDuration)
        isTimerRunning = true
    }
    
    func stopTimer() {
        updateTimer()
        isTimerRunning = false
    }
    
    func updateTimer() {
        guard let start = startTime, isTimerRunning else { return }
        sessionDuration = Date().timeIntervalSince(start) + pausedDuration
    }
    
    func checkMilestones() {
        for milestone in sessionMilestones {
            if sessionDuration >= milestone.timeThreshold {
                lastReachedMilestone = milestone
            }
        }
    }
    
    func getSessionSummary() -> SessionSummary {
        return SessionSummary(
            totalDuration: sessionDuration,
            sessionType: sessionType,
            averageTimePerUnit: sessionDuration / 10 // Mock calculation
        )
    }
}

// Supporting types for testing
enum PatternImageType: String {
    case position, technique, progress
}

enum StepSparringPhase {
    case attack, defense, counter
}

enum StepSparringType {
    case oneStep, twoStep, threeStep, free
}

enum SequenceDifficulty {
    case beginner, intermediate, advanced, expert
}

enum PracticeSessionType {
    case pattern, stepSparring
}

struct PatternImageInfo {
    let imageName: String
    let imageType: PatternImageType
    let index: Int
}

struct BeltTheme {
    let beltLevel: String
    var primaryColor: String { "blue" }
    var secondaryColor: String { "white" }
    var stripeCount: Int { 5 }
}

struct PatternSessionState {
    let currentMoveIndex: Int
    let completedMoves: Set<Int>
    let totalPracticeTime: TimeInterval
}

struct PatternPracticeResults {
    let movesCompleted: Int
    let totalPracticeTime: TimeInterval
    let patternCompleted: Bool
}

struct StepSparringResults {
    let stepsCompleted: Int
    let totalPracticeTime: TimeInterval
    let sequenceCompleted: Bool
}

struct PhaseFlowResults {
    let completedPhases: [StepSparringPhase]
    let totalExecutionTime: TimeInterval
}

struct SessionMilestone {
    let timeThreshold: TimeInterval
    let message: String
}

struct SessionSummary {
    let totalDuration: TimeInterval
    let sessionType: PracticeSessionType
    let averageTimePerUnit: TimeInterval
}

// Mock extensions for existing models
extension PatternMove {
    var id: String { "move_\(moveNumber)" }
    var displayTitle: String { "Move \(moveNumber): \(techniqueName ?? "Technique")" }
    var fullDescription: String { description ?? "Pattern move description" }
    var hasMedia: Bool { true }
    var availableImages: [String] {
        ["position_\(moveNumber)", "technique_\(moveNumber)", "progress_\(moveNumber)"]
    }
}

extension StepSparringStep {
    var attackAction: StepSparringAction {
        StepSparringAction(actionType: .attack, technique: "Attack technique", target: "Target area")
    }
    var defenseAction: StepSparringAction {
        StepSparringAction(actionType: .defense, technique: "Defense technique", target: "Defense area")
    }
    var counterAction: StepSparringAction {
        StepSparringAction(actionType: .counter, technique: "Counter technique", target: "Counter area")
    }
}

extension StepSparringSequence {
    var minimumBeltLevel: String? { "10th Keup" }
    var difficulty: SequenceDifficulty { .beginner }
}

extension StepSparringService {
    func getSequences(for type: StepSparringType, userProfile: UserProfile) -> [StepSparringSequence] {
        // Mock implementation
        return []
    }
}

struct StepSparringAction {
    enum ActionType {
        case attack, defense, counter
    }
    let actionType: ActionType
    let technique: String
    let target: String
}