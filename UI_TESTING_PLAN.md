# TKDojang UI Testing Plan

**Document Version:** 1.0
**Created:** 2025-10-15
**Status:** In Progress
**Approach:** Hybrid Testing (Component-First with ViewInspector + XCUITest E2E)

---

## Executive Summary

This plan establishes comprehensive UI testing for TKDojang to:
- Prevent future regressions during feature development
- Enable confident scaling to additional devices/platforms
- Validate user experience quality across all features
- Support targeted validation of user-reported issues

**Total Test Target:** 196-216 tests across 5 phases
**Estimated Timeline:** 3-4 weeks (Phases 1-4), +1 week (Phase 5 optional)
**Current Progress:** 16/196 tests implemented (8%)

---

## Testing Strategy

### Architecture: Bottom-Up Testing Pyramid

```
        /\
       /  \     Phase 3: E2E User Journeys (12 tests)
      / E2E \   - XCUITest for cross-feature flows
     /--------\  - Validates navigation & integration
    / Phase 2 \
   /Integration\ Phase 2: Feature Integration (23 tests)
  /   Tests     \- ViewInspector for multi-view flows
 /----------------\
/  Phase 1: Comp.  \ Phase 1: Component Tests (153 tests)
\    Tests (153)   / - ViewInspector for isolated views
 \----------------/  - Fast, focused, easy debugging
  \   Phase 4     /
   \ Edge Cases  /   Phase 4: Stress & Edge Cases (8 tests)
    \   (8)     /    - XCUITest for resilience validation
     \--------/
      \ Opt. /       Phase 5: Snapshot Tests (20 tests) [OPTIONAL]
       \    /        - Visual regression detection
        \  /         - Image display validation
         \/
```

### Why Component-First?

1. **Debugging Efficiency**: When E2E tests fail, component tests narrow the problem space
2. **Development Velocity**: Faster to write, faster to run, easier to parallelize
3. **Confidence Building**: Proven components → simpler integration validation
4. **Maintenance**: Changes to features immediately show localized failures

---

## Dependencies

### ViewInspector
- **Purpose:** Component and integration testing
- **License:** MIT (free, no attribution required)
- **Impact:** Development-only, zero bundle impact on end users
- **Version:** 0.10.3
- **Status:** ✅ Added to TKDojangTests target

### swift-snapshot-testing (Phase 5 - Optional)
- **Purpose:** Visual regression testing
- **License:** MIT (free)
- **Impact:** Development-only, zero bundle impact
- **Status:** ⬜ Not Added

---

## Implementation Workflow

For each test component:

1. **Analyze**: Review feature behavior and identify testable scenarios
2. **Validate**: Confirm test coverage addresses user concerns
3. **Implement**: Write tests with clear descriptions and assertions
4. **Execute**: Run tests and verify they pass
5. **Document**: Add clear comments explaining what's tested and why
6. **Mark Complete**: Update checkbox in this document
7. **Commit**: Commit test file to repository with descriptive message

---

## Phase 1: Component Tests (ViewInspector)

**Goal:** Test individual views in isolation with full state validation
**Timeline:** Week 1-2
**Total Tests:** 153
**Completed:** 16/153 (10%)

---

### 1.1 Flashcard Components (35 tests)

**Feature Path:** `TKDojang/Sources/Features/StepSparring/Flashcard*.swift`
**Test File:** `TKDojangTests/ComponentTests/FlashcardComponentTests.swift`
**Status:** 🔄 In Progress
**Completed:** 16/35 (46%)

**🐛 CRITICAL BUG DISCOVERED:** Property-based tests exposed that selecting N flashcards returned ALL available cards (not N) for single-direction modes. Bug fixed in FlashcardView.swift.

#### Supporting Component Tests (7 tests) ✅
- ✅ `testStudyModeCard_DisplaysCorrectly` - Study mode card shows selected state with checkmark
- ✅ `testStudyModeCard_UnselectedState` - Unselected card has no checkmark
- ✅ `testCardDirectionCard_EnglishToKorean` - Direction card displays correct label
- ✅ `testCardDirectionCard_BothDirections_ShowsRecommendedStar` - Both Directions shows star
- ✅ `testPreviewRow_DisplaysSessionInfo` - Preview row shows card count correctly
- ✅ `testLearningSystemCard_ClassicMode` - Classic mode card displays correctly
- ✅ `testLearningSystemCard_LeitnerMode` - Leitner mode card displays correctly

#### Session Statistics Tests (3 tests) ✅
- ✅ `testSessionStats_AccuracyCalculation_80Percent` - 16/20 = 80% calculated correctly
- ✅ `testSessionStats_AccuracyCalculation_100Percent` - 23/23 = 100% calculated correctly
- ✅ `testSessionStats_AccuracyCalculation_ZeroQuestions` - 0/0 handles gracefully

#### Enum Display Name Tests (3 tests) ✅
- ✅ `testStudyMode_DisplayNames` - Learn/Test modes show correct names
- ✅ `testCardDirection_DisplayNames` - All direction modes show correct names
- ✅ `testLearningSystem_DisplayNames` - Classic/Leitner show correct names

#### Property-Based Tests with Randomization (3 tests) ✅ **[BREAKTHROUGH]**
- ✅ `testArray_UniqueElements` - Array uniquing removes duplicates correctly
- ✅ `testFlashcardItemCreation_PropertyBased_CardCountMatchesRequest` - Random belt levels + random card counts (5-50) validate "N selected → N returned" property
- ✅ `testFlashcardItemCreation_MultipleRandomRuns` - 10 random configurations test edge cases every run

#### FlashcardConfigurationView Tests (10 tests) - NEXT
- ⬜ `testCardCountSelection_5Cards` - Verify selecting 5 cards sets configuration
- ⬜ `testCardCountSelection_10Cards` - Verify selecting 10 cards sets configuration
- ⬜ `testCardCountSelection_23Cards` - Verify selecting 23 cards sets configuration
- ⬜ `testCardCountSelection_50Cards` - Verify selecting 50 cards sets configuration
- ⬜ `testBeltLevelFilter` - Verify belt filter affects available cards
- ⬜ `testCategoryFilter` - Verify category filter affects available cards
- ⬜ `testLanguageModeSelection_Korean` - Verify Korean mode selected
- ⬜ `testLanguageModeSelection_English` - Verify English mode selected
- ⬜ `testLanguageModeSelection_Random` - Verify Random mode selected
- ⬜ `testStartButtonEnabledState` - Verify button enabled only when valid config

#### FlashcardDisplayView Tests (15 tests)
- ⬜ `testCardDisplaysKoreanSide_WhenKoreanMode` - Card shows Korean when mode=Korean
- ⬜ `testCardDisplaysEnglishSide_WhenEnglishMode` - Card shows English when mode=English
- ⬜ `testCardDisplaysRandomSide_WhenRandomMode` - Card shows random side when mode=Random
- ⬜ `testFlipAnimationTriggered_OnTap` - Tapping card triggers flip
- ⬜ `testFlipShowsOppositeSide` - Flip reveals opposite language
- ⬜ `testProgressIndicatorDisplay` - Shows "Card X of Y" correctly
- ⬜ `testProgressIndicatorUpdates` - Progress updates as cards advance
- ⬜ `testSkipButtonFunctionality` - Skip advances without recording answer
- ⬜ `testCorrectButtonFunctionality` - Correct records success and advances
- ⬜ `testHardButtonFunctionality` - Hard button moves to earlier Leitner box
- ⬜ `testEasyButtonFunctionality` - Easy button moves to later Leitner box
- ⬜ `testDefinitionDisplay` - Definition shown when card flipped
- ⬜ `testImageDisplay_WhenImageExists` - Image renders if card has image
- ⬜ `testNavigationToNextCard` - Next button advances card
- ⬜ `testNavigationButtonsDisabledAtEnd` - Next disabled on last card

#### FlashcardResultsView Tests (10 tests)
- ⬜ `testAccuracyCalculationDisplay` - Shows correct accuracy percentage
- ⬜ `testCardCountDisplay_MatchesSelected` - Shows exact card count studied (23 → 23)
- ⬜ `testCorrectCountDisplay` - Shows number marked correct
- ⬜ `testSkippedCountDisplay` - Shows number skipped
- ⬜ `testSessionDurationDisplay` - Shows elapsed time
- ⬜ `testLeitnerBoxMovementDisplay` - Shows cards moved between boxes
- ⬜ `testProgressBarUpdate` - Visual progress bar reflects accuracy
- ⬜ `testRestartSessionButton` - Restart button returns to configuration
- ⬜ `testReturnToDashboardButton` - Dashboard button navigates correctly
- ⬜ `testSessionDataPersistence` - Session saved to history

---

### 1.2 Multiple Choice Components (25 tests)

**Feature Path:** `TKDojang/Sources/Features/Testing/MultipleChoice*.swift`
**Test File:** `TKDojangTests/ComponentTests/MultipleChoiceComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/25

#### MultipleChoiceConfigurationView Tests (8 tests)
- ⬜ `testQuestionCountSelection_10Questions` - Verify 10 question selection
- ⬜ `testQuestionCountSelection_20Questions` - Verify 20 question selection
- ⬜ `testBeltLevelFilter` - Questions filtered by selected belt
- ⬜ `testCategoryFilter_Terminology` - Terminology category filter works
- ⬜ `testCategoryFilter_Patterns` - Patterns category filter works
- ⬜ `testCategoryFilter_Theory` - Theory category filter works
- ⬜ `testDifficultyFilter` - Difficulty filter affects question pool
- ⬜ `testStartButtonState` - Button enabled only with valid config

#### MultipleChoiceQuestionView Tests (12 tests)
- ⬜ `testQuestionDisplay` - Question text displays correctly
- ⬜ `testFourAnswerOptionsDisplay` - All 4 answer choices shown
- ⬜ `testAnswerSelectionHighlight` - Selected answer is highlighted
- ⬜ `testCorrectAnswerFeedback_Immediate` - Correct answer shows success
- ⬜ `testIncorrectAnswerFeedback_Immediate` - Wrong answer shows failure
- ⬜ `testCorrectAnswerRevealed_AfterSelection` - Shows correct answer after wrong selection
- ⬜ `testProgressIndicatorDisplay` - Shows "Question X of Y"
- ⬜ `testProgressIndicatorUpdates` - Updates as questions advance
- ⬜ `testQuestionNumberIncrement` - Question counter increments correctly
- ⬜ `testCannotChangeAnswerAfterSubmission` - Answers locked after selection
- ⬜ `testNextQuestionNavigation` - Next button advances question
- ⬜ `testFinalQuestionTransition` - Last question transitions to results

#### MultipleChoiceResultsView Tests (5 tests)
- ⬜ `testScoreCalculationDisplay` - Shows correct score (e.g., 16/20 = 80%)
- ⬜ `testScorePercentageDisplay` - Shows percentage accurately
- ⬜ `testQuestionReviewList` - Shows list of questions with results
- ⬜ `testRetakeButton` - Retake returns to configuration
- ⬜ `testReturnToDashboardButton` - Dashboard button navigates correctly

---

### 1.3 Pattern Practice Components (28 tests)

**Feature Path:** `TKDojang/Sources/Features/Patterns/Pattern*.swift`
**Test File:** `TKDojangTests/ComponentTests/PatternPracticeComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/28

#### PatternSelectionView Tests (6 tests)
- ⬜ `testPatternListFilteredByBelt` - Only belt-appropriate patterns shown
- ⬜ `testPatternDetails_MoveCount` - Move count displayed correctly
- ⬜ `testPatternDetails_Difficulty` - Difficulty level shown
- ⬜ `testPatternStartButton` - Start button begins practice
- ⬜ `testBeltProgressionIndicator` - Shows current belt progress
- ⬜ `testLockedPatternsDisplay` - Higher belt patterns locked/grayed

#### PatternPracticeView Tests (16 tests)
- ⬜ `testImageCarouselDisplay_PositionView` - Position image shown in carousel
- ⬜ `testImageCarouselDisplay_TechniqueView` - Technique image shown in carousel
- ⬜ `testImageCarouselDisplay_ProgressView` - Progress view shown in carousel
- ⬜ `testMoveCounterDisplay` - Shows "Move X of Y" correctly
- ⬜ `testMoveCounterUpdates` - Counter updates as moves advance
- ⬜ `testBeltThemedProgressBar` - Progress bar uses belt color
- ⬜ `testBeltThemedProgressBarFill` - Progress bar fills proportionally
- ⬜ `testNextMoveNavigation` - Next button advances move
- ⬜ `testPreviousMoveNavigation` - Previous button goes back
- ⬜ `testMoveInstructionTextDisplay` - Instruction text shown
- ⬜ `testKoreanTechniqueNameDisplay` - Korean name displayed
- ⬜ `testEnglishTranslationDisplay` - English translation shown
- ⬜ `testImageLoadingForCurrentMove` - Current move image loads
- ⬜ `testCarouselSwipeGesture` - Swipe changes carousel view
- ⬜ `testSessionTimerDisplay` - Timer shows elapsed time
- ⬜ `testCompletePatternTransition` - Last move transitions to results

#### PatternSessionResultsView Tests (6 tests)
- ⬜ `testCompletionDisplay` - Shows completion message
- ⬜ `testSessionDurationDisplay` - Shows total time spent
- ⬜ `testMovesReviewedCount` - Shows number of moves (19/19)
- ⬜ `testPatternMasteryIndicator` - Shows mastery level if tracked
- ⬜ `testRepeatPatternButton` - Repeat restarts same pattern
- ⬜ `testReturnToDashboardButton` - Dashboard button navigates correctly

---

### 1.4 Step Sparring Components (20 tests)

**Feature Path:** `TKDojang/Sources/Features/StepSparring/StepSparring*.swift`
**Test File:** `TKDojangTests/ComponentTests/StepSparringComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/20

#### StepSparringSelectionView Tests (5 tests)
- ⬜ `testSequenceListFilteredByBelt` - Only belt-appropriate sequences shown
- ⬜ `testSequenceTypeFilter` - 3-step, 5-step filtering works
- ⬜ `testDifficultyDisplay` - Difficulty level shown per sequence
- ⬜ `testStartButton` - Start button begins practice
- ⬜ `testSequencePreview` - Preview shows sequence overview

#### StepSparringPracticeView Tests (12 tests)
- ⬜ `testPhaseDisplay_Attack` - Attack phase clearly indicated
- ⬜ `testPhaseDisplay_Defense` - Defense phase clearly indicated
- ⬜ `testPhaseDisplay_Counter` - Counter phase clearly indicated
- ⬜ `testActionSequenceDisplay` - All actions in sequence shown
- ⬜ `testCurrentStepHighlight` - Current step highlighted
- ⬜ `testImageDisplayForCurrentAction` - Image loads for current action
- ⬜ `testTechniqueNameDisplay_Korean` - Korean technique name shown
- ⬜ `testTechniqueNameDisplay_English` - English translation shown
- ⬜ `testNextActionNavigation` - Next advances action
- ⬜ `testPreviousActionNavigation` - Previous goes back
- ⬜ `testPhaseTransitionAnimation` - Phases transition smoothly
- ⬜ `testCompleteSequenceTransition` - Last action transitions to results

#### StepSparringResultsView Tests (3 tests)
- ⬜ `testSequenceCompletionDisplay` - Shows completion message
- ⬜ `testRepeatButton` - Repeat restarts sequence
- ⬜ `testReturnToDashboardButton` - Dashboard button navigates correctly

---

### 1.5 Dashboard Components (18 tests)

**Feature Path:** `TKDojang/Sources/Features/Dashboard/Dashboard*.swift`
**Test File:** `TKDojangTests/ComponentTests/DashboardComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/18

#### DashboardView Tests (18 tests)
- ⬜ `testProfileNameDisplay` - Current profile name shown
- ⬜ `testCurrentBeltDisplay` - Current belt level displayed
- ⬜ `testStreakCountDisplay` - Study streak count shown
- ⬜ `testStreakCountAccuracy` - Streak count matches actual data
- ⬜ `testTotalStudyTimeDisplay` - Total study time shown
- ⬜ `testTotalStudyTimeAccuracy` - Study time matches session sum
- ⬜ `testRecentActivityList` - Recent sessions listed
- ⬜ `testSessionStatisticsAccuracy` - Session stats match reality
- ⬜ `testProgressChartsDisplay` - Charts render without errors
- ⬜ `testQuickActionButtons_Flashcards` - Flashcard quick action works
- ⬜ `testQuickActionButtons_Test` - Test quick action works
- ⬜ `testQuickActionButtons_Patterns` - Pattern quick action works
- ⬜ `testFlashcardsSeenCount` - Flashcard count accurate
- ⬜ `testPatternsMasteredCount` - Pattern count accurate
- ⬜ `testTestsCompletedCount` - Test count accurate
- ⬜ `testAverageAccuracyDisplay` - Average accuracy calculated correctly
- ⬜ `testEmptyStateDisplay_NewUser` - New user sees empty state
- ⬜ `testSwitchProfileButton` - Switch profile button visible

---

### 1.6 Profile Components (15 tests)

**Feature Path:** `TKDojang/Sources/Features/Profile/Profile*.swift`
**Test File:** `TKDojangTests/ComponentTests/ProfileComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/15

#### ProfileSelectionView Tests (5 tests)
- ⬜ `testProfileListDisplay_UpTo6` - Shows up to 6 profiles
- ⬜ `testProfileAvatarDisplay` - Each profile shows correct avatar
- ⬜ `testProfileThemeIndicator` - Theme colors shown per profile
- ⬜ `testProfileSelection` - Tapping profile selects it
- ⬜ `testCreateNewProfileButton_Visible` - Create button visible if <6 profiles

#### ProfileCreationView Tests (6 tests)
- ⬜ `testNameInputValidation_Empty` - Empty name rejected
- ⬜ `testNameInputValidation_Valid` - Valid name accepted
- ⬜ `testAvatarSelection` - Avatar picker works
- ⬜ `testColorThemeSelection` - Theme picker works
- ⬜ `testBeltLevelSelection` - Belt selector works
- ⬜ `testCreateProfileButton_EnabledWhenValid` - Button enabled only when valid

#### ProfileSettingsView Tests (4 tests)
- ⬜ `testProfileEditMode` - Edit mode allows changes
- ⬜ `testDeleteProfileConfirmation` - Delete shows confirmation dialog
- ⬜ `testDataIsolationValidation` - Changing profile shows different data
- ⬜ `testProfileSwitchSeamless` - Switching profiles is smooth

---

### 1.7 Theory/Techniques Components (12 tests)

**Feature Path:** `TKDojang/Sources/Features/Theory/*.swift` & `TKDojang/Sources/Features/Techniques/*.swift`
**Test File:** `TKDojangTests/ComponentTests/TheoryTechniquesComponentTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/12

#### TheoryListView Tests (6 tests)
- ⬜ `testContentFilteredByBelt` - Content filtered by current belt
- ⬜ `testCategoryFilter_History` - History category filter works
- ⬜ `testCategoryFilter_Philosophy` - Philosophy filter works
- ⬜ `testCategoryFilter_Techniques` - Techniques filter works
- ⬜ `testSearchFunctionality` - Search returns relevant results
- ⬜ `testContentSelection` - Selecting content opens detail view

#### TheoryDetailView Tests (6 tests)
- ⬜ `testContentDisplay_Text` - Text content renders correctly
- ⬜ `testContentDisplay_Images` - Images render if present
- ⬜ `testImageDisplay_NoError` - Missing images don't crash
- ⬜ `testRelatedContentLinks` - Related content links work
- ⬜ `testProgressTracking_MarkRead` - Reading content marks as read
- ⬜ `testBackNavigation` - Back button returns to list

---

## Phase 2: Feature Integration Tests (ViewInspector)

**Goal:** Test multi-view flows within a single feature
**Timeline:** Week 2
**Total Tests:** 23
**Completed:** 0/23 (0%)

---

### 2.1 Flashcard Feature Integration (8 tests)

**Test File:** `TKDojangTests/IntegrationTests/FlashcardFeatureIntegrationTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/8

- ⬜ `testConfigurationToSessionFlow` - Config → Session navigation
- ⬜ `testSessionToResultsFlow` - Session → Results navigation
- ⬜ `testCompleteFlashcardWorkflow` - Config → Study → Results → Dashboard
- ⬜ `testRestartFromResults` - Results → Restart → Config
- ⬜ `testCardCountPropagation_23Cards` - 23 selected → 23 shown in session
- ⬜ `testLanguageModePropagation_Korean` - Korean mode → all cards Korean
- ⬜ `testMetricsUpdateFlow_CorrectButton` - Correct button → counter increments
- ⬜ `testLeitnerBoxUpdateFlow` - Marking cards updates Leitner boxes

---

### 2.2 Pattern Feature Integration (6 tests)

**Test File:** `TKDojangTests/IntegrationTests/PatternFeatureIntegrationTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/6

- ⬜ `testPatternSelectionToPracticeFlow` - Selection → Practice navigation
- ⬜ `testMoveNavigationFlow_AllMoves` - Navigate through all 19 moves
- ⬜ `testCompletionToResultsFlow` - Practice → Results navigation
- ⬜ `testImageCarouselSwitchingFlow` - Carousel switches between 3 views
- ⬜ `testBeltProgressPropagation` - Belt theme applied throughout
- ⬜ `testSessionPersistenceFlow` - Session saved after completion

---

### 2.3 Multiple Choice Feature Integration (5 tests)

**Test File:** `TKDojangTests/IntegrationTests/MultipleChoiceFeatureIntegrationTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/5

- ⬜ `testConfigurationToQuestionFlow` - Config → Questions navigation
- ⬜ `testQuestionNavigationFlow_AllQuestions` - Navigate through all questions
- ⬜ `testAnswerValidationFlow` - Answer → Feedback → Next question
- ⬜ `testScoringCalculationFlow` - Answers → Correct score calculation
- ⬜ `testResultsDisplayFlow` - Questions → Results with accurate data

---

### 2.4 Profile Feature Integration (4 tests)

**Test File:** `TKDojangTests/IntegrationTests/ProfileFeatureIntegrationTests.swift`
**Status:** ⬜ Not Started
**Completed:** 0/4

- ⬜ `testProfileCreationToSelectionFlow` - Create → Profile appears in list
- ⬜ `testProfileSwitchingDataIsolation` - Switch → Verify different data
- ⬜ `testProfileEditingPersistence` - Edit → Changes saved
- ⬜ `testMultiProfileManagement` - Create/Switch/Delete multiple profiles

---

## Phase 3: End-to-End User Journeys (XCUITest)

**Goal:** Test cross-feature navigation with proven components
**Timeline:** Week 3
**Total Tests:** 12
**Completed:** 0/12 (0%)

**Test File:** `TKDojangUITests/CriticalUserJourneysUITests.swift`
**Status:** ⬜ Not Started

---

### 3.1 User Journey Tests (12 tests)

- ⬜ `testNewUserOnboarding` - Welcome → Profile Creation → Dashboard → First Action
- ⬜ `testFlashcardCompleteWorkflow` - Dashboard → Configure (23 cards, Korean) → Study → Mark Correct/Skip → Results → Dashboard (verify metrics updated)
- ⬜ `testMultipleChoiceCompleteWorkflow` - Dashboard → Configure (20 questions, 7th keup) → Answer → Review → Results → Dashboard
- ⬜ `testPatternPracticeCompleteWorkflow` - Dashboard → Select Pattern → Practice (all 19 moves) → Complete → Results → Dashboard
- ⬜ `testStepSparringWorkflow` - Dashboard → Select Sequence → Practice → Complete → Dashboard
- ⬜ `testProfileSwitchingWorkflow` - Dashboard (Profile A) → Switch to Profile B → Verify isolated data → Switch back → Verify data restored
- ⬜ `testTheoryLearningWorkflow` - Dashboard → Theory → Read content → Return → Verify progress tracked
- ⬜ `testDashboardStatisticsAccuracy` - Complete flashcard session → Dashboard → Verify counts/charts update correctly
- ⬜ `testBeltProgressionValidation` - Verify content filters correctly across belt levels
- ⬜ `testSearchFunctionality` - Search terminology/techniques → Verify results → Select → Verify detail view
- ⬜ `testNavigationResilience` - Navigate forward 10 levels deep → Back button → Verify no crashes/state loss
- ⬜ `testMultiSessionWorkflow` - Flashcards → Patterns → Test → Dashboard → Verify all sessions logged

---

## Phase 4: Edge Cases & Stress Testing (XCUITest)

**Goal:** Validate app resilience under stress conditions
**Timeline:** Week 3-4
**Total Tests:** 8
**Completed:** 0/8 (0%)

**Test File:** `TKDojangUITests/StressTestingUITests.swift`
**Status:** ⬜ Not Started

---

### 4.1 Stress Tests (8 tests)

- ⬜ `testRapidNavigationStability` - Tap tabs rapidly 50 times → Verify no crashes
- ⬜ `testRapidButtonClicking_Flashcards` - Spam "Correct" button 100 times → Verify state consistent
- ⬜ `testBackgroundingDuringSession` - Start flashcard session → Background app → Wait 30s → Foreground → Verify session restored
- ⬜ `testMemoryPressure_ImageLoading` - Load pattern with many images → Verify no crashes/warnings
- ⬜ `testDataCorruptionRecovery` - Simulate corrupted data → Launch app → Verify recovery flow
- ⬜ `testMaxProfilesCreation` - Create 6 profiles → Verify limit enforced → Attempt 7th → Verify error message
- ⬜ `testConcurrentOperations` - Start flashcard + profile switch → Verify no race conditions
- ⬜ `testLongSessionStability` - Run 1-hour session → Verify no memory leaks/crashes

---

## Phase 5: Snapshot Tests (Optional)

**Goal:** Visual regression detection for image-heavy features
**Timeline:** Week 4 (Optional)
**Total Tests:** 20
**Completed:** 0/20 (0%)

**Test File:** `TKDojangTests/SnapshotTests/VisualRegressionTests.swift`
**Status:** ⬜ Not Started

---

### 5.1 Snapshot Tests (20 tests)

#### Pattern Image Snapshots (10 tests)
- ⬜ `testPatternImageSnapshot_ChonJi` - Snapshot Chon-Ji pattern images
- ⬜ `testPatternImageSnapshot_DanGun` - Snapshot Dan-Gun pattern images
- ⬜ `testPatternImageSnapshot_DoSan` - Snapshot Do-San pattern images
- ⬜ `testPatternImageSnapshot_WonHyo` - Snapshot Won-Hyo pattern images
- ⬜ `testPatternImageSnapshot_YulGok` - Snapshot Yul-Gok pattern images
- ⬜ `testPatternImageSnapshot_JungGun` - Snapshot Jung-Gun pattern images
- ⬜ `testPatternImageSnapshot_TaeGye` - Snapshot Tae-Gye pattern images
- ⬜ `testPatternImageSnapshot_HwaRang` - Snapshot Hwa-Rang pattern images
- ⬜ `testPatternImageSnapshot_ChoongMoo` - Snapshot Choong-Moo pattern images
- ⬜ `testPatternImageSnapshot_AllPatternsList` - Snapshot pattern selection list

#### Flashcard Layout Snapshots (5 tests)
- ⬜ `testFlashcardLayout_KoreanMode` - Snapshot Korean-first layout
- ⬜ `testFlashcardLayout_EnglishMode` - Snapshot English-first layout
- ⬜ `testFlashcardLayout_FlippedState` - Snapshot flipped card state
- ⬜ `testFlashcardLayout_WithImage` - Snapshot card with image
- ⬜ `testFlashcardLayout_WithoutImage` - Snapshot card without image

#### Dashboard Snapshots (5 tests)
- ⬜ `testDashboardSnapshot_EmptyState` - Snapshot new user dashboard
- ⬜ `testDashboardSnapshot_WithData` - Snapshot active user dashboard
- ⬜ `testDashboardSnapshot_Charts` - Snapshot progress charts
- ⬜ `testDashboardSnapshot_Statistics` - Snapshot statistics section
- ⬜ `testDashboardSnapshot_BeltTheme` - Snapshot belt-themed elements

---

## Definition of Done (DoD)

A test is considered "complete" when:

### ✅ Implementation Criteria
- [ ] Test method implemented with clear descriptive name
- [ ] Test includes header comment explaining what it validates
- [ ] Test uses proper assertions (XCTAssert*, not just execution)
- [ ] Test validates expected vs actual state (not just "doesn't crash")
- [ ] Test is isolated (doesn't depend on other tests)

### ✅ Execution Criteria
- [ ] Test passes on iPhone 16 simulator (iOS 18.6)
- [ ] Test passes consistently (5+ runs without flakes)
- [ ] Test execution time is reasonable (<5s for component, <30s for E2E)
- [ ] No warnings or errors in console output

### ✅ Documentation Criteria
- [ ] Checkbox marked complete in this document
- [ ] Test file committed to repository
- [ ] Commit message describes what tests were added
- [ ] If test revealed bugs, those are documented/fixed

### ✅ Quality Criteria
- [ ] Test validates user concern (e.g., "23 cards selected → 23 shown")
- [ ] Test would catch regression if feature broke
- [ ] Test failure message is clear and actionable
- [ ] No force unwraps or unsafe operations in test code

---

## Progress Tracking

### Overall Progress

| Phase | Total Tests | Completed | Percentage | Status |
|-------|-------------|-----------|------------|--------|
| **Phase 1: Components** | 153 | 16 | 10% | 🔄 In Progress |
| **Phase 2: Integration** | 23 | 0 | 0% | ⬜ Not Started |
| **Phase 3: E2E Journeys** | 12 | 0 | 0% | ⬜ Not Started |
| **Phase 4: Stress Tests** | 8 | 0 | 0% | ⬜ Not Started |
| **Phase 5: Snapshots** | 20 | 0 | 0% | ⬜ Not Started |
| **TOTAL** | **216** | **16** | **7%** | 🔄 In Progress |

### Milestone Tracking

- ✅ **Milestone 1:** ViewInspector dependency added (v0.10.3)
- ⬜ **Milestone 2:** Phase 1 (Component Tests) complete
- ⬜ **Milestone 3:** Phase 2 (Integration Tests) complete
- ⬜ **Milestone 4:** Phase 3 (E2E Tests) complete
- ⬜ **Milestone 5:** Phase 4 (Stress Tests) complete
- ⬜ **Milestone 6:** (Optional) Snapshot dependency added
- ⬜ **Milestone 7:** (Optional) Phase 5 (Snapshot Tests) complete
- ⬜ **Milestone 8:** Full test suite passing in CI/CD

---

## Risk & Issue Tracking

### Known Risks
- **ViewInspector Limitations**: Some complex SwiftUI views may not be inspectable
  - *Mitigation:* Fall back to XCUITest for non-inspectable views
- **XCUITest Flakiness**: UI tests can be flaky with timing issues
  - *Mitigation:* Use explicit waits, avoid hard-coded delays
- **Test Maintenance Burden**: Large test suites require ongoing maintenance
  - *Mitigation:* Focus on high-value tests, delete tests that don't catch regressions

### Issues Log

| Date | Issue | Resolution | Status |
|------|-------|------------|--------|
| 2025-10-15 | **Critical**: FlashcardView returned ALL cards instead of N when user selected N (single-direction modes) | Fixed in FlashcardView.swift:547-617 - added defensive trimming to respect targetCount | ✅ Resolved |
| 2025-10-15 | Property-based tests discovered card count bug by testing with random configurations (5-50 cards, random belts) | Validated fix with testFlashcardItemCreation_PropertyBased_CardCountMatchesRequest | ✅ Resolved |

---

## Appendix: Testing Best Practices

### Component Testing Guidelines
1. **Test One Thing**: Each test validates one specific behavior
2. **Clear Naming**: Test names describe what's being validated
3. **AAA Pattern**: Arrange (setup) → Act (execute) → Assert (verify)
4. **No Shared State**: Tests don't depend on execution order
5. **Fast Execution**: Component tests should run in <100ms

### XCUITest Guidelines
1. **Accessibility Identifiers**: Use identifiers for reliable element selection
2. **Explicit Waits**: Use `waitForExistence(timeout:)` not `sleep()`
3. **Resilient Selectors**: Prefer IDs over label text (localization-safe)
4. **Clear User Actions**: Test should read like user instructions
5. **Verify State Changes**: Don't just tap, verify the result

### Documentation Guidelines
1. **Test Headers**: Every test file has purpose comment
2. **Complex Tests**: Add inline comments explaining non-obvious steps
3. **Failure Messages**: Custom assertions with helpful error messages
4. **WHY over WHAT**: Comments explain why test exists, not what code does

---

## Next Steps

**Immediate Action:** Add ViewInspector dependency and implement Phase 1.1 (Flashcard Components)

**Workflow Per Test:**
1. Analyze feature behavior
2. Validate test coverage
3. Implement test
4. Run and verify pass
5. Document with clear comments
6. Mark checkbox complete in this document
7. Commit to repository

---

**Document Maintained By:** Claude Code + Craig
**Last Updated:** 2025-10-15
**Next Review:** After Phase 1 completion
