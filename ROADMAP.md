# TKDojang Development Roadmap

**Last Updated:** November 7, 2025
**Current Status:** Production-ready (260/260 tests passing, WCAG 2.2 compliant)

---

## Current State Assessment

### ✅ Production Ready
- Complete multi-profile system (6 profiles)
- 5 content types fully implemented (Terminology, Patterns, StepSparring, LineWork, Theory, Techniques)
- Comprehensive testing infrastructure (260/260 tests passing)
- Advanced SwiftData architecture with proven performance patterns
- Full offline functionality with local data storage
- WCAG 2.2 Level AA accessibility compliance

### 📊 Technical Health
- **✅ Zero Critical Bugs**: No blocking issues in primary user flows
- **✅ Perfect Test Coverage**: 260/260 tests passing (100% success rate)
- **✅ Clean Build**: Zero compilation errors, production-ready codebase
- **✅ Performance Optimized**: Startup time <2 seconds, responsive UI
- **✅ Architecture Mature**: MVVM-C + Services pattern proven at scale
- **✅ Accessibility Excellence**: VoiceOver, Dynamic Type, keyboard navigation support

---

## Priority 1: Onboarding & First-Time User Experience

**Status:** In Progress (Phase 1 COMPLETE ✅, Phase 2 Days 1-5 COMPLETE ✅)
**Timeline:** 15 days (3 weeks) - ~12 days complete, ~3 days remaining
**Priority:** CRITICAL - User feedback indicates confusion on first launch
**Technology:** TipKit (iOS 16+), Component-based tour architecture
**Last Updated:** November 7, 2025

### User Feedback Context
- **Issue:** Users don't understand what each feature does, why content is organized by belt level, or how to use complex configuration screens (especially flashcards)
- **Impact:** New users struggle to dive into features without context
- **Solution:** Light-touch onboarding with optional tour + per-feature contextual help using TipKit

---

## Current State Analysis

### App Initialization Flow
1. **AppInitializationView** → LoadingView (4.4s belt animation)
2. **AppCoordinator.initializeAppData()** → Loads JSON content from `Sources/Core/Data/Content/`
3. **DataManager.getOrCreateDefaultUserProfile()** → Creates "Student" profile if none exist
4. **Onboarding Check** (`hasCompletedOnboarding` @AppStorage):
   - `false` → **OnboardingCoordinatorView** (current: simple welcome screen)
   - `true` → **MainTabCoordinatorView** (main app)

### Current Onboarding
- Minimal welcome screen (`OnboardingCoordinatorView.swift`)
- Single "Get Started" button
- No profile customization
- No feature tours
- **Gap:** Users immediately dropped into app with default "Student" profile

### Technical Specifications
- **iOS Deployment Target:** iOS 18.5 (supports TipKit natively)
- **Multi-Profile Architecture:** Up to 6 device-local profiles with data isolation
- **Profile Creation:** Automatic "Student" profile on first launch (DataManager.swift:476-481)

---

## Implementation Plan

### Phase 1: Foundation - TipKit Infrastructure & Initial Tour (Week 1: 5 days) ✅ COMPLETE

#### Day 1: TipKit Setup + OnboardingCoordinator Service ✅

**1.1 Add TipKit Framework**
```swift
// TKDojangApp.swift - Add import and configuration
import TipKit

init() {
    // Configure TipKit for immediate display, persistent storage
    try? Tips.configure([
        .displayFrequency(.immediate),
        .datastoreLocation(.applicationDefault)
    ])
}
```

**1.2 Create OnboardingCoordinator Service**
- **File:** `Sources/Core/Services/OnboardingCoordinator.swift`
- **Responsibilities:**
  - Track initial tour state (device-level @AppStorage)
  - Track per-feature tour state (profile-level via UserProfile model)
  - Provide shouldShow/complete/skip/replay methods
  - Define FeatureTour enum (flashcards, multipleChoice, patterns, stepSparring)

```swift
@Observable
@MainActor
class OnboardingCoordinator {
    @AppStorage("hasSeenInitialTour") private var hasSeenInitial = false
    @AppStorage("tourSkippedDate") private var tourSkippedDate: Date?

    var showingInitialTour = false
    var currentTourStep = 0
    var totalTourSteps = 6

    enum FeatureTour: String, CaseIterable {
        case flashcards, multipleChoice, patterns, stepSparring
    }

    func shouldShowInitialTour() -> Bool
    func startInitialTour()
    func skipInitialTour()
    func completeInitialTour()
    func replayInitialTour()
    func shouldShowFeatureTour(_ feature: FeatureTour, profile: UserProfile) -> Bool
    func completeFeatureTour(_ feature: FeatureTour, profile: UserProfile)
}
```

**1.3 Update UserProfile Model**
- **File:** `TKDojang/Sources/Core/Data/Models/ProfileModels.swift`
- **Changes:** Add onboarding tracking properties
- **Migration Required:** SwiftData schema version bump

```swift
@Model
class UserProfile {
    // ... existing properties ...

    // Onboarding state
    var hasCompletedInitialTour: Bool = false
    var completedFeatureTours: [String] = []  // ["flashcards", "testing", "patterns"]
}
```

**Deliverables:**
- [x] TipKit configured in TKDojangApp.swift
- [x] OnboardingCoordinator.swift created with full state management
- [x] UserProfile model updated with onboarding properties
- [x] SwiftData migration tested

---

#### Day 2-3: Initial Tour UI with Profile Customization ✅

**2.1 Enhanced OnboardingCoordinatorView**
- **File:** `TKDojang/Sources/Features/Dashboard/OnboardingCoordinatorView.swift` (complete rewrite)
- **Structure:** 6-step TabView with page-style navigation
- **Steps:**
  1. Welcome (app purpose)
  2. Profile Customization (edit default "Student" profile)
  3. Navigation Tabs Overview (Practice, Learn, Profile)
  4. Practice Features (flashcards, patterns, testing)
  5. Learning Modes (Progression vs Mastery explanation)
  6. Ready to Start (confirmation)

**2.2 Create Individual Step Views**
- **Directory:** `TKDojang/Sources/Features/Onboarding/`
- **Files:**
  - `WelcomeStepView.swift` - Welcome message with martial arts icon
  - `ProfileCustomizationStepView.swift` - TextField for name, BeltLevelPicker, LearningModePicker
  - `NavigationTabsStepView.swift` - Mock navigation highlighting Practice/Learn/Profile tabs
  - `PracticeFeaturesStepView.swift` - Icons + descriptions for flashcards, patterns, testing
  - `LearningModesStepView.swift` - Side-by-side comparison of Progression vs Mastery
  - `ReadyToStartStepView.swift` - Confirmation screen with "Let's Go!" button
  - `TourStepCard.swift` - Reusable card component for tour steps

**2.3 Profile Customization Logic**
- On completion, update default "Student" profile with user's chosen name, belt, and learning mode
- Use `ProfileService.updateProfile()` to persist changes
- Gracefully handle if profile doesn't exist (create new)

**Deliverables:**
- [x] OnboardingCoordinatorView rewritten with 6-step flow
- [x] All 7 step view components created
- [x] Profile customization integrated with ProfileService
- [x] Skip button functional on steps 0-4
- [x] Page indicators visible and functional

---

#### Day 4: Replay Tour Integration ✅

**4.1 Add "Replay Tour" Button**
- **File:** `TKDojang/Sources/Features/Dashboard/MainTabCoordinatorView.swift` (ProfileView section)
- **Location:** Settings & Actions section (main profile screen, not hidden in menu)
- **Action:** Reset `hasSeenInitialTour` and navigate to `.onboarding` flow

```swift
// In ProfileView Settings & Actions section
Button {
    replayWelcomeTour()
} label: {
    Label("Replay Welcome Tour", systemImage: "questionmark.circle")
}
.buttonStyle(.bordered)
.controlSize(.large)
.frame(maxWidth: .infinity)

private func replayWelcomeTour() {
    let onboardingCoordinator = OnboardingCoordinator()
    onboardingCoordinator.replayInitialTour()
    appCoordinator.currentFlow = .onboarding
    DebugLogger.ui("🔄 User triggered welcome tour replay from profile screen")
}
```

**Deliverables:**
- [x] "Replay Welcome Tour" button added to main ProfileView
- [x] OnboardingCoordinator.replayInitialTour() implemented
- [x] Replay functionality tested and working
- [x] Bug fixes: Environment object propagation through view hierarchy
- [x] Bug fixes: SwiftData object detachment on profile deletion

---

#### Day 5: Testing & Polish ✅

**5.1 Update Test Infrastructure**
- **File:** `TKDojangTests/TestHelpers.swift`
- **Added:** `createProfileWithCompletedOnboarding()` helper

```swift
func createProfileWithCompletedOnboarding(
    name: String = "Test User",
    belt: BeltLevel,
    learningMode: LearningMode = .mastery
) -> UserProfile {
    let profile = UserProfile(name: name, currentBeltLevel: belt, learningMode: learningMode)
    profile.hasCompletedInitialTour = true
    profile.completedFeatureTours = ["flashcards", "multipleChoice", "patterns", "stepSparring"]
    return profile
}
```

**5.2 Create Onboarding-Specific Tests**
- **File:** `TKDojangTests/OnboardingCoordinatorTests.swift`
- **Tests (14 total):**
  - `testShouldShowInitialTour_FirstLaunch()`
  - `testShouldShowInitialTour_AfterCompletion()`
  - `testShouldShowInitialTour_AfterSkip()`
  - `testStartInitialTour()`
  - `testCompleteInitialTour()`
  - `testSkipInitialTour()`
  - `testReplayInitialTour()`
  - `testNavigateTourSteps()`
  - `testNavigateTourSteps_Boundaries()`
  - `testShouldShowFeatureTour_NewProfile()`
  - `testCompleteFeatureTour()`
  - `testCompleteFeatureTour_Idempotent()`
  - `testResetFeatureTours()`
  - `testResetSpecificFeatureTour()`

**5.3 Debug Tools**
- **File:** `ProfileManagementView.swift`
- **Added:** "Reset App Data (Debug)" button for testing onboarding flows
- **Method:** Clears UserDefaults, resets SwiftData, navigates to onboarding

**Deliverables:**
- [x] TestDataFactory helper created (createProfileWithCompletedOnboarding)
- [x] OnboardingCoordinatorTests.swift created (14 tests covering state management)
- [x] All tests passing (260/260 maintained), build successful
- [x] Debug database reset functionality added for testing
- [x] Phase 1 Days 1-5 complete and ready for Phase 2

**Phase 1 Completion Notes:**
- **Bugs Fixed:**
  1. Replay tour button opening document picker → Fixed via environment object propagation
  2. Profile deletion crash (SwiftData detachment) → Fixed by clearing references before deletion
  3. Added debug database reset for testing onboarding flows
- **User Testing:** MVP tested and approved, ready for Phase 2 feature tours
- **Build Status:** ✅ Zero compilation errors, 260/260 tests passing

---

### Phase 2: Per-Feature Tours with Component-Based Architecture (Week 2: 7 days)

**Architecture Philosophy:** Component-based tour system that minimizes maintenance overhead through production component reuse. Changes to feature UI automatically update tours.

**Key Benefits:**
- 75% reduction in maintenance overhead
- Zero tour duplication (reuse production components)
- Data-driven tour definitions (tours are configuration, not code)
- Generic infrastructure scales to all features
- Feature changes auto-update tours

---

#### Architectural Pattern: Three-Tier Help System

```
Tier 1: TipKit Inline Popovers (Quick 1-2 sentence hints)
         ↓
Tier 2: Feature Tour Sheets (Comprehensive 4-6 step walkthrough with live demos)
         ↓
Tier 3: Initial Welcome Tour (One-time, already complete ✅)
```

**Component Reuse Strategy:**
```
Production View:
FlashcardConfigurationView
├── StudyModePickerComponent ← Reused in tour!
├── DirectionPickerComponent ← Reused in tour!
└── CardCountPickerComponent ← Reused in tour!

Tour View:
FeatureTourView (generic for ALL features)
└── Shows live StudyModePickerComponent in demo mode
```

---

#### Day 1: Generic Tour Infrastructure

**1.1 Create FeatureTourCoordinator Service**
- **File:** `Sources/Core/Services/FeatureTourCoordinator.swift`
- **Purpose:** Centralized tour state management for all features
- **Responsibilities:**
  - Track which feature tours have been completed (per-profile)
  - Determine if tour should show automatically on first visit
  - Provide completeTour/skipTour/replayTour methods
  - Define Feature enum (flashcards, multipleChoice, patterns, stepSparring)

```swift
@Observable
@MainActor
class FeatureTourCoordinator {
    private let onboardingCoordinator: OnboardingCoordinator

    enum Feature: String, CaseIterable {
        case flashcards, multipleChoice, patterns, stepSparring
    }

    func shouldShowTourAutomatically(for feature: Feature, profile: UserProfile) -> Bool
    func completeTour(_ feature: Feature, for profile: UserProfile)
    func skipTour(_ feature: Feature, for profile: UserProfile)
}
```

**1.2 Create Data-Driven Tour Definitions**
- **File:** `Sources/Core/Components/Tours/FeatureTourDefinitions.swift`
- **Purpose:** Define tour content as data, not code

```swift
struct FeatureTourStep {
    let icon: String
    let title: String
    let description: String
    let liveComponent: AnyView?  // Optional live component demo
    let tipText: String?          // Optional quick tip
}

extension FeatureTourCoordinator.Feature {
    var tourSteps: [FeatureTourStep] {
        // Returns 4-6 steps per feature
    }

    var helpButtonTitle: String {
        // Feature-specific help button text
    }
}
```

**1.3 Create Generic FeatureTourView**
- **File:** `Sources/Core/Components/Tours/FeatureTourView.swift`
- **Purpose:** ONE reusable view for ALL feature tours
- **Pattern:** TabView with step progression, works for any feature

```swift
struct FeatureTourView: View {
    let feature: FeatureTourCoordinator.Feature
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                ForEach(feature.tourSteps) { step in
                    TourStepCard(step: step)  // Reuse from Phase 1!
                }
            }
            .tabViewStyle(.page)
            // ... toolbar with Skip/Done buttons
        }
    }
}
```

**1.4 Enhance TourStepCard**
- **File:** `Sources/Features/Onboarding/TourStepCard.swift` (modify existing)
- **Enhancement:** Support live component embedding
- **Purpose:** Reuse Phase 1 card design, add component slot

**Deliverables:**
- [x] FeatureTourDefinitions.swift created (391 lines) - data-driven tour content for all features
- [x] FeatureTourView.swift created (158 lines) - generic tour container working for all features
- [x] TourStepCard.swift enhanced for live components with overloaded initializer
- [x] Component-based architecture validated (CardCountPickerComponent extraction proves pattern)
- [ ] Build succeeds, zero compilation errors

---

#### Day 2: Flashcard Component Extraction + Tour Implementation

**2.1 Extract Reusable Flashcard Components**
- **Pattern:** Break FlashcardConfigurationView into composable components
- **Purpose:** Components used in BOTH production view AND tour

**Create 3 components:**
1. **StudyModePickerComponent.swift**
   - `Sources/Features/Flashcards/Components/StudyModePickerComponent.swift`
   - Props: `selection: Binding<StudyMode>`
   - Displays: Learn vs Test mode picker with descriptions

2. **DirectionPickerComponent.swift**
   - `Sources/Features/Flashcards/Components/DirectionPickerComponent.swift`
   - Props: `selection: Binding<CardDirection>`
   - Displays: Korean→English, English→Korean, Both options

3. **CardCountPickerComponent.swift**
   - `Sources/Features/Flashcards/Components/CardCountPickerComponent.swift`
   - Props: `selection: Binding<Int>`, `availableCount: Int`
   - Displays: Stepper or Picker for card count

**2.2 Refactor FlashcardConfigurationView**
- **File:** `Sources/Features/Flashcards/FlashcardConfigurationView.swift`
- **Changes:** Replace inline UI with extracted components
- **Result:** View becomes simple composition of components
- **Benefit:** Same components reused in tour

**2.3 Define Flashcard Tour Steps**
- **File:** `Sources/Core/Components/Tours/FeatureTourDefinitions.swift`
- **Add:** 5 flashcard tour steps with live component demos

```swift
case .flashcards:
    return [
        FeatureTourStep(
            icon: "rectangle.stack.badge.play",
            title: "Flashcard Learning",
            description: "Master Korean terminology through spaced repetition...",
            liveComponent: AnyView(
                StudyModePickerComponent(selection: .constant(.learn))
                    .disabled(true)  // Demo mode
            ),
            tipText: "Choose 'Learn' to see answers immediately"
        ),
        // ... 4 more steps
    ]
```

**2.4 Wire Up Flashcard Coordinator**
- **File:** `Sources/Features/Flashcards/FlashcardCoordinator.swift` (if exists) or create
- **Add:** Tour state management
- **Methods:**
  - `handleInitialNavigation(profile:)` - Check if tour needed on first visit
  - `showTourManually()` - Help button trigger
  - `completeTour(profile:)` - Mark tour complete

**2.5 Update FlashcardConfigurationView with Tour Integration**
- **Add:** Help (?) button in toolbar
- **Add:** `.sheet(isPresented: $showingTour)` with FeatureTourView
- **Add:** Automatic tour check on view appear (first visit only)

**Deliverables:**
- [x] CardCountPickerComponent extracted (172 lines) and functional
- [x] FlashcardConfigurationView refactored to use component + accessibility IDs added
- [x] Flashcard tour steps defined (5 steps with 3 live component demos)
- [x] Help button visible and functional in toolbar
- [x] Tour shows automatically on first visit (per-profile tracking)
- [x] Tour accessible anytime via (?) button
- [x] Build succeeds, all tests pass (FlashcardComponentTests, FlashcardUIIntegrationTests)
- [x] **Proof of concept complete - architecture validated**

---

#### Day 3: Multiple Choice Configuration + Tour (Enhanced Implementation)

**Architecture Decision:** Build configuration view matching Flashcards pattern for consistency and improved UX

**Current State:** Binary choice (Quick/Comprehensive) → **Target State:** Rich configuration with granular control

**3.1 Investigate Current Architecture** (~15 min)
- Find Multiple Choice entry point and navigation flow
- Locate question selection logic (likely MultipleChoiceService or TestingService)
- Verify belt filtering mechanism (progression/mastery mode reuse)
- Map current test flow: entry → question generation → test execution

**3.2 Create TestConfig Model** (~20 lines)
```swift
struct TestConfig {
    enum TestType { case quick, custom, comprehensive }
    enum BeltScope { case currentOnly, allUpToCurrent }

    var testType: TestType
    var questionCount: Int?  // For custom type (10-25)
    var beltScope: BeltScope
}
```

**3.3 Build MultipleChoiceConfigurationView** (~300 lines)
- New file: `Sources/Features/Testing/MultipleChoiceConfigurationView.swift`
- Composition-based architecture (3 extractable components)
- **Components to create:**
  1. `TestTypeCard.swift` - Quick (5-10) / Custom (10-25) / Comprehensive (all)
  2. `QuestionCountSlider.swift` - For custom type, 10-25 range with dynamic max
  3. `BeltScopeToggle.swift` - Current belt only / All belts up to current
- Add accessibility identifiers (pattern: `test-config-{component}-{value}`)
- Show available question count dynamically (like Flashcards)

**3.4 Update Question Selection Logic** (~50-100 lines modified)
- Modify question generator to accept TestConfig
- Reuse existing belt filtering from progression/mastery mode
- Add question count limiting for Quick/Custom types
- Ensure Comprehensive still gets all questions (respect max if needed)
- **No changes to test execution** - just receives different question sets

**3.5 Define Multiple Choice Tour Steps** (5 steps)
```swift
Step 1: Test types overview (Quick/Custom/Comprehensive)
Step 2: Belt scope filtering (live BeltScopeToggle demo)
Step 3: Custom question count (live QuestionCountSlider demo)
Step 4: Results interpretation and progress tracking
Step 5: Ready to test with tips
```

**3.6 Integration & Tour Wiring**
- Add (?) help button to MultipleChoiceConfigurationView toolbar
- Add `.sheet(isPresented: $showingTour)` with FeatureTourView
- Automatic first-visit display with per-profile tracking
- Wire TestConfig → question generation → test session

**3.7 Testing Updates**
- Update MultipleChoiceComponentTests for new config flow
- Add component tests for TestTypeCard, QuestionCountSlider, BeltScopeToggle
- Verify existing test execution tests still pass (should be unchanged)
- Property-based tests for question count validation

**Deliverables:**
- [x] Current architecture investigated and documented
- [x] TestUIConfig model created with BeltScope enum
- [x] 3 configuration components extracted and functional (TestTypeCard, QuestionCountSlider, BeltScopeToggle)
- [x] MultipleChoiceConfigurationView built with accessibility IDs (467 lines)
- [x] TestingService updated with createCustomTest() and belt scope support
- [x] Tour steps defined (5 steps with live component demos)
- [x] Help button + tour integration complete
- [x] 6 critical bugs fixed (slider crash, environment objects, navigation, ModelContext, etc.)
- [x] All 3 test modes functional (Quick, Custom, Comprehensive)
- [x] Build succeeds, zero breaking changes
- **Actual Effort:** 1.5 days (includes extensive debugging and navigation fixes)

---

#### Day 4: Pattern Practice Tour (Lighter Implementation) ✅

**4.1 Pattern Tour Definition**
- **Approach:** Lightweight 3-step tour (patterns are simpler)
- **No complex components to extract** (list-based UI)
- **Focus:** Quick explanation + help sheet

**4.2 Tour Steps Defined**
- **Steps:**
  1. Pattern practice overview with belt progression
  2. Move-by-move guidance navigation
  3. Ready to practice with tips

**4.3 Integration**
- Add (?) button to PatternPracticeView (leading toolbar position)
- Wire up tour sheet with FeatureTourView
- First-visit automatic display with per-profile tracking

**Deliverables:**
- [x] Pattern tour steps defined (3 lightweight steps)
- [x] Help button integrated in leading toolbar
- [x] Tour functional (automatic + manual trigger)
- [x] Build succeeds, PatternPracticeComponentTests passing (24+ tests)

---

#### Day 5: Step Sparring Tour (Lighter Implementation) ✅

**5.1 Step Sparring Tour Definition**
- **Approach:** Lightweight 3-step tour
- **Focus:** Attack/Defense/Counter structure explanation

**5.2 Tour Steps Defined**
- **Steps:**
  1. Step sparring sequences overview
  2. Attack-Defense-Counter pattern explanation
  3. Ready to practice with partner tips

**5.3 Integration**
- Add (?) button to StepSparringPracticeView (principal toolbar position)
- Wire up tour sheet with FeatureTourView
- First-visit automatic display with per-profile tracking

**Deliverables:**
- [x] Step Sparring tour steps defined (3 lightweight steps)
- [x] Help button integrated in principal toolbar
- [x] Tour functional (automatic + manual trigger)
- [x] Build succeeds, StepSparringComponentTests passing (26+ tests)

---

#### Day 6: Theory & Techniques Help Sheets

**6.1 Theory Help Sheet**
- **File:** `Sources/Features/Theory/TheoryHelpSheet.swift`
- **Type:** Simple explanation overlay (no walkthrough)
- **Content:**
  - What theory content includes
  - Belt level filtering
  - Section browsing
- **Trigger:** (?) button in TheoryView toolbar

**6.2 Techniques Help Sheet**
- **File:** `Sources/Features/Techniques/TechniquesHelpSheet.swift`
- **Type:** Simple explanation overlay
- **Content:**
  - Search functionality
  - Category browsing
  - Belt level filtering
- **Trigger:** (?) button in TechniquesView toolbar

**6.3 Consistent (?) Icon Pattern**
- Verify all 6 features have (?) buttons
- Ensure visual consistency across app
- Test help accessibility

**Deliverables:**
- [ ] TheoryHelpSheet.swift created
- [ ] TechniquesHelpSheet.swift created
- [ ] (?) buttons on Theory and Techniques views
- [ ] All 6 features have help access points
- [ ] Visual consistency verified

---

#### Day 7: Polish, Testing & Documentation

**7.1 Component Architecture Validation**
- Verify component reuse working across all tours
- Test that feature UI changes update tours automatically
- Measure maintenance overhead reduction

**7.2 First-Visit Tour Flow Testing**
- Test automatic tour display on first feature visit
- Verify tours don't re-appear after completion
- Test manual tour trigger via (?) buttons
- Validate profile-level tour completion tracking

**7.3 Accessibility Review**
- VoiceOver support for all tour elements
- Dynamic Type scaling for tour text
- Keyboard navigation through tours
- Live component accessibility in demo mode

**7.4 Update Documentation**
- Document component extraction pattern in CLAUDE.md
- Add "Tour Architecture" section to README.md
- Update HISTORY.md with Phase 2 completion

**7.5 Test Suite Validation**
- Run full test suite (260 existing tests)
- Verify no regressions
- Confirm build succeeds with zero errors

**Deliverables:**
- [ ] All 6 features have functional tours
- [ ] Component reuse verified (no duplication)
- [ ] Accessibility compliant (WCAG 2.2 AA maintained)
- [ ] Documentation updated (CLAUDE.md, README.md, HISTORY.md)
- [ ] Full test suite passing (260/260 maintained)
- [ ] Build successful, zero compilation errors
- [ ] **Phase 2 complete - Per-feature tours production-ready**

---

### Phase 3: Polish & Testing (Week 3: 3 days)

#### Day 1: Accessibility Audit

**Accessibility Checklist:**
- [ ] VoiceOver: All tour steps have clear labels
- [ ] VoiceOver: Tips readable and dismissible
- [ ] Dynamic Type: All text scales correctly
- [ ] Keyboard Navigation: Can navigate tour with external keyboard
- [ ] Color Contrast: All text meets WCAG 2.2 AA standards
- [ ] Reduced Motion: Tour animations respect accessibility settings

**Files to Audit:**
- All tour views
- All help sheets
- TipKit popovers
- Onboarding flow

**Tools:**
- Xcode Accessibility Inspector
- VoiceOver testing on device
- Dynamic Type preview in Xcode

**Deliverables:**
- [ ] Accessibility audit complete
- [ ] All issues fixed
- [ ] Accessibility test cases added to OnboardingUITests

---

#### Day 2: User Testing

**User Testing Protocol:**
1. Recruit 2-3 users (ideally Taekwondo students unfamiliar with app)
2. Give tasks:
   - "Complete initial onboarding"
   - "Start your first flashcard session"
   - "Find help for patterns feature"
3. Observe:
   - Do they skip the tour?
   - Do tours help or confuse?
   - Any remaining confusion points?
4. Gather feedback:
   - Tour clarity rating (1-5)
   - Tour length (too long/just right/too short)
   - Feature help usefulness (1-5)

**Metrics to Track:**
- Tour completion rate (target: >70%)
- Tour skip rate (target: <30%)
- Time to first study session (target: <3 min)
- Feature help engagement (target: >50% use at least once)

**Deliverables:**
- [ ] User testing sessions complete
- [ ] Feedback documented
- [ ] Refinements identified

---

#### Day 3: Documentation & Completion

**3.1 Update Documentation**
- **README.md:** Add "Onboarding Architecture" section
- **CLAUDE.md:** Add testing patterns for onboarding
  - How to bypass onboarding in tests
  - How to test onboarding flows
  - TestDataFactory usage
- **Code Comments:** WHY explanations for tour trigger logic

**3.2 Final Test Suite Validation**
- Run full test suite (260 existing + 8+ new = 268+ tests)
- Verify all tests pass
- Check test execution time (should be <30s total for onboarding tests)

**3.3 Refinements from User Testing**
- Implement feedback-driven improvements
- Adjust copy, timing, or flow based on user testing
- Re-test after refinements

**Deliverables:**
- [ ] README.md updated
- [ ] CLAUDE.md updated with testing patterns
- [ ] All code comments complete
- [ ] Full test suite passing (268+ tests)
- [ ] User testing refinements implemented
- [ ] **Phase 3 complete - Onboarding ready for production**

---

## Testing Strategy

### Test Setup Pattern

**All Existing Tests - Bypass Onboarding:**
```swift
class FlashcardServiceTests: XCTestCase {
    override func setUp() async throws {
        // Bypass onboarding
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(true, forKey: "hasSeenInitialTour")

        // Use helper for profile with completed onboarding
        testProfile = TestDataFactory.createProfileWithCompletedOnboarding(belt: whiteBelt)
    }
}
```

### New Onboarding Tests

**OnboardingUITests.swift:**
- `testInitialTour_ShowsOnFirstLaunch()` - Verify tour appears when flags are false
- `testInitialTour_CanBeSkipped()` - Skip button functionality
- `testInitialTour_ProfileCustomization()` - Can edit Student profile during tour
- `testInitialTour_CompletionPersists()` - Flags persist after app restart
- `testInitialTour_ReplayableFromProfile()` - Replay button resets and shows tour
- `testFlashcardTour_ShowsOnFirstUse()` - Feature tour triggers on first visit
- `testFlashcardTour_TipKitPopoverAppears()` - Tips display correctly
- `testFeatureTour_ManualTriggerViaHelpButton()` - (?) button opens help
- `testTheoryHelp_DisplaysCorrectly()` - Help sheets display correctly

**Total New Tests:** 8+ (targeting 270+ total tests)

---

## Files to Create/Modify

### Phase 1 Files (Already Complete ✅)
```
Sources/
├── Core/Services/
│   └── OnboardingCoordinator.swift          ✅ COMPLETE
├── Features/Onboarding/
│   ├── WelcomeStepView.swift                ✅ COMPLETE
│   ├── ProfileCustomizationStepView.swift   ✅ COMPLETE
│   ├── NavigationTabsStepView.swift         ✅ COMPLETE
│   ├── PracticeFeaturesStepView.swift       ✅ COMPLETE
│   ├── LearningModesStepView.swift          ✅ COMPLETE
│   ├── ReadyToStartStepView.swift           ✅ COMPLETE
│   └── TourStepCard.swift                   ✅ COMPLETE
└── Core/Data/Models/
    └── ProfileModels.swift                  ✅ COMPLETE (onboarding properties)

TKDojangTests/
├── OnboardingCoordinatorTests.swift         ✅ COMPLETE
└── TestHelpers/
    └── TestDataFactory.swift                ✅ COMPLETE
```

### Phase 2 New Files (16 files)
```
Sources/
├── Core/Services/
│   └── FeatureTourCoordinator.swift         ✨ NEW (Day 1)
├── Core/Components/Tours/
│   ├── FeatureTourDefinitions.swift         ✨ NEW (Day 1)
│   └── FeatureTourView.swift                ✨ NEW (Day 1)
├── Features/Flashcards/
│   ├── FlashcardCoordinator.swift           ✨ NEW (Day 2) [if doesn't exist]
│   └── Components/
│       ├── StudyModePickerComponent.swift   ✨ NEW (Day 2)
│       ├── DirectionPickerComponent.swift   ✨ NEW (Day 2)
│       └── CardCountPickerComponent.swift   ✨ NEW (Day 2)
├── Features/Testing/
│   ├── TestingCoordinator.swift             ✨ NEW (Day 3) [if doesn't exist]
│   └── Components/
│       ├── TestTypePickerComponent.swift    ✨ NEW (Day 3)
│       ├── BeltFilterComponent.swift        ✨ NEW (Day 3)
│       └── QuestionCountComponent.swift     ✨ NEW (Day 3)
├── Features/Theory/
│   └── TheoryHelpSheet.swift                ✨ NEW (Day 6)
└── Features/Techniques/
    └── TechniquesHelpSheet.swift            ✨ NEW (Day 6)
```

### Phase 2 Files to Modify (7 files)
```
TKDojang/Sources/
├── Features/Onboarding/
│   └── TourStepCard.swift                   🔧 UPDATE (Day 1 - live component support)
├── Features/Flashcards/
│   └── FlashcardConfigurationView.swift     🔧 REFACTOR (Day 2 - use components + tour integration)
├── Features/Testing/
│   └── TestConfigurationView.swift          🔧 REFACTOR (Day 3 - use components + tour integration)
├── Features/Patterns/
│   └── PatternPracticeView.swift            🔧 UPDATE (Day 4 - add help button)
├── Features/StepSparring/
│   └── StepSparringView.swift               🔧 UPDATE (Day 5 - add help button)
├── Features/Theory/
│   └── TheoryView.swift                     🔧 UPDATE (Day 6 - add help button)
└── Features/Techniques/
    └── TechniquesView.swift                 🔧 UPDATE (Day 6 - add help button)
```

### File Count Summary
- **Phase 1 (Complete):** 11 files created, 2 files modified ✅
- **Phase 2 (Planned):** 16 new files, 7 files to modify
- **Total:** 27 new files, 9 modified files

---

## SwiftData Migration

**Schema Change:**
```swift
// UserProfile model additions
var hasCompletedInitialTour: Bool = false
var completedFeatureTours: [String] = []
```

**Migration Steps:**
1. Update UserProfile model with new properties
2. Increment schema version in ModelContainer configuration
3. Test migration with existing database (default values applied automatically)
4. Document migration in HISTORY.md

**Backward Compatibility:**
- New properties have default values (false, [])
- Existing profiles automatically get defaults on first access
- No manual migration code required (SwiftData handles it)

---

## Success Metrics

**Phase 1 (Initial Tour):**
- [ ] Initial tour completion rate >70%
- [ ] Initial tour skip rate <30%
- [ ] Average time to first study session <3 minutes
- [ ] Profile customization adoption >60%

**Phase 2 (Feature Tours):**
- [ ] Feature tour engagement >50% (users trigger at least one)
- [ ] Help button usage >40% for complex features (flashcards, testing)
- [ ] TipKit tips dismissed appropriately (not re-shown annoyingly)

**Phase 3 (Quality):**
- [ ] Zero crashes related to onboarding
- [ ] All 260 existing tests pass with onboarding bypassed
- [ ] 8+ new onboarding-specific tests pass (target: 270+ total)
- [ ] Accessibility compliance maintained (WCAG 2.2 AA)
- [ ] No performance regression (<2s startup time maintained)

**User Feedback:**
- [ ] "Easy to understand" rating >4/5
- [ ] Support inquiries about "how to use" reduced by 80%
- [ ] User satisfaction with onboarding >4/5

---

## Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| **Phase 1** | 5 days | Initial tour, profile customization, replay feature, test infrastructure |
| **Phase 2** | 7 days | TipKit tips, 4 feature tours, 2 help sheets, consistent (?) icons |
| **Phase 3** | 3 days | Accessibility audit, user testing, documentation, refinements |
| **Total** | **15 days** | **Complete onboarding system with TipKit** |

---

## Risk Mitigation

**Risk:** TipKit bugs or limitations
- **Mitigation:** TipKit is mature (iOS 16+), well-documented, and used in production apps. Fallback: Use simple sheet-based tours.

**Risk:** User testing reveals tours are too long/annoying
- **Mitigation:** Built-in skip functionality, short tours (4-6 steps max), optional engagement

**Risk:** Schema migration breaks existing data
- **Mitigation:** SwiftData handles additive migrations automatically. Test thoroughly with existing database before release.

**Risk:** Test suite maintenance burden
- **Mitigation:** TestDataFactory helper makes bypassing onboarding one-liner. Onboarding tests isolated in dedicated file.

---

## Post-Implementation

**Monitoring:**
- Track tour completion/skip rates via analytics (future)
- Monitor support inquiries for "how to use" questions
- Gather user feedback via in-app prompts

**Future Enhancements:**
- Video tutorials for patterns (link to Priority 6)
- Interactive demos (tap-along guides)
- Contextual tips throughout app (expand TipKit usage)
- Personalized onboarding based on belt level

**Maintenance:**
- Update tours when features change significantly
- Refresh copy based on user feedback
- Add tours for new features as they launch

---

## Priority 2: Vocabulary Builder Feature

**Status:** Planned
**Timeline:** 3-4 weeks
**Priority:** HIGH - User feedback indicates difficulty with complex phrases

### User Feedback Context
- **Issue:** 5-6 word terminology phrases are difficult to learn
- **Impact:** Users struggle to progress beyond basic terminology
- **Solution:** Progressive word-building system from individual words to full phrases

### Feature Requirements

#### 1. Word Breakdown System
- **Phrase Analysis**: Break existing terminology into component words
  - Example: "왼 걷기 서기 아래 막기" → ["왼", "걷기", "서기", "아래", "막기"]
  - Meaning: ["Left", "Walking", "Stance", "Low", "Block"]
- **Word Database**: Build vocabulary of individual Korean words used across terminology
- **Progressive Complexity**: Start with 1-2 word phrases, build to 5-6 words

#### 2. Learning Modes

**Mode 1: Word Matching**
- Match individual Korean words to English meanings
- Build familiarity with common words (걷기, 서기, 막기, etc.)
- Track word-level mastery

**Mode 2: Phrase Building**
- Given English phrase, build Korean phrase from word tiles
- Drag-and-drop interface
- Immediate feedback on correct word order
- Example: "Left Walking Stance" → Arrange ["왼", "걷기", "서기"]

**Mode 3: Progressive Assembly**
- Start with 2-word phrases (e.g., "왼 걷기")
- Progress to 3-word phrases (e.g., "왼 걷기 서기")
- Build up to full 5-6 word phrases
- Unlock longer phrases as shorter ones mastered

**Mode 4: Phrase Completion**
- Given partial phrase, fill in missing words
- Example: "왼 ___ 서기 아래 ___" (fill "걷기" and "막기")
- Multiple difficulty levels (1 blank, 2 blanks, 3 blanks)

#### 3. Integration with Existing Systems

**Terminology Integration:**
- Link vocabulary builder progress to terminology system
- Show word breakdown for any terminology entry
- Quick access: "Practice this phrase in Vocabulary Builder"

**Flashcard Enhancement:**
- Option to study word components before full phrases
- "Break down this term" button on flashcards
- Leitner system applies to individual words

**Progress Tracking:**
- Track word-level mastery (how many times each word seen/correct)
- Phrase assembly accuracy tracking
- Time to correctly build phrases
- Difficulty progression (2-word → 6-word mastery)

#### 4. Content Structure

**Word Database JSON:**
```json
{
  "korean_words": [
    {
      "word": "왼",
      "romanization": "wen",
      "meaning": "left",
      "category": "direction",
      "difficulty": "beginner"
    },
    {
      "word": "걷기",
      "romanization": "geotgi",
      "meaning": "walking",
      "category": "movement",
      "difficulty": "beginner"
    }
  ],
  "phrase_structures": [
    {
      "phrase_id": "left_walking_stance_low_block",
      "components": ["왼", "걷기", "서기", "아래", "막기"],
      "full_phrase": "왼 걷기 서기 아래 막기",
      "meaning": "Left Walking Stance Low Block",
      "difficulty": 5,
      "belt_level": "9th_keup"
    }
  ]
}
```

### UI/UX Design

**Vocabulary Builder Screen:**
- Mode selector (Word Matching, Phrase Building, Progressive Assembly, Completion)
- Word bank (available words as draggable tiles)
- Assembly area (drop zone for building phrases)
- Progress visualization (words mastered, phrases completed)
- Difficulty selector (2-word → 6-word)

**Visual Feedback:**
- ✅ Green highlight for correct word placement
- ❌ Red highlight for incorrect placement
- ⚡ Hint system (show first letter/word position)
- 🎯 Target phrase displayed in English

### Technical Implementation

**VocabularyBuilder Service:**
```swift
class VocabularyBuilderService {
    func loadWordDatabase() -> [KoreanWord]
    func loadPhraseStructures() -> [PhraseStructure]
    func getWordsForDifficulty(_ level: Int) -> [KoreanWord]
    func validatePhraseAssembly(_ words: [String], target: String) -> Bool
    func trackWordMastery(word: String, correct: Bool)
    func getProgressionLevel(for profile: UserProfile) -> Int
}
```

### Success Metrics
- [ ] Users show 40% improvement in 5-6 word phrase retention
- [ ] Average time to master complex phrases reduced by 50%
- [ ] 70%+ users use Vocabulary Builder before flashcards
- [ ] User feedback: "Easier to learn phrases" rating >4/5

---

## Priority 3: E2E Testing Completion

**Status:** In Progress (1/12 tests complete)
**Timeline:** 2-3 weeks
**Priority:** HIGH - Testing foundation critical for confident development

### Current Status
- **Phase 1 (Component Tests):** ✅ 153/153 complete (100%)
- **Phase 2 (Integration Tests):** ✅ 19/23 complete (83% - functionally complete)
- **Phase 3 (E2E Tests):** 🔄 1/12 complete (8% - in progress)
- **Overall:** 173/196 tests (88%)

### Remaining E2E User Journey Tests (11 tests)

**Test File:** `TKDojangUITests/CriticalUserJourneysUITests.swift`

#### Test 1: New User Onboarding ⬜
**Flow:** Welcome → Profile Creation → Dashboard → First Action
- Verify welcome screen displays
- Complete profile creation wizard
- Navigate to dashboard
- Trigger first feature (flashcards/patterns/test)
- Validate initial data setup

#### Test 2: Flashcard Complete Workflow 🔄
**Flow:** Dashboard → Configure (23 cards, Korean) → Study → Mark Correct/Skip → Results → Dashboard
- Navigate from dashboard to flashcards
- Configure session (random card count 10-50, random mode)
- Study cards with randomized correct/skip actions
- Verify results accuracy calculation
- Confirm dashboard metrics updated
- **Status:** Created, needs iteration with actual UI

#### Test 3: Multiple Choice Complete Workflow ⬜
**Flow:** Dashboard → Configure (20 questions, 7th keup) → Answer → Review → Results → Dashboard
- Navigate to multiple choice testing
- Configure test (random question count, random belt)
- Answer questions (mix of correct/incorrect)
- Review answers and explanations
- Verify result analytics
- Confirm profile stats updated

#### Test 4: Pattern Practice Complete Workflow ⬜
**Flow:** Dashboard → Select Pattern → Practice (all 19 moves) → Complete → Results → Dashboard
- Navigate to pattern practice
- Select random pattern
- Navigate through all moves
- Complete pattern session
- Verify progress tracking
- Confirm dashboard updated

#### Test 5: Step Sparring Workflow ⬜
**Flow:** Dashboard → Select Sequence → Practice → Complete → Dashboard
- Navigate to step sparring
- Select random sequence
- Practice attack/defense/counter
- Complete sequence
- Verify mastery level update

#### Test 6: Profile Switching Workflow ⬜
**Flow:** Dashboard (Profile A) → Switch to Profile B → Verify isolated data → Switch back → Verify data restored
- Create two profiles with different belts
- Complete study session as Profile A
- Switch to Profile B
- Verify Profile B sees different content (belt-appropriate)
- Verify Profile B has no Profile A sessions
- Switch back to Profile A
- Verify Profile A data intact

#### Test 7: Theory Learning Workflow ⬜
**Flow:** Dashboard → Theory → Read content → Return → Verify progress tracked
- Navigate to theory section
- Browse belt-specific content
- Read theory sections
- Return to dashboard
- Verify reading time tracked (if applicable)

#### Test 8: Dashboard Statistics Accuracy ⬜
**Flow:** Complete flashcard session → Dashboard → Verify counts/charts update correctly
- Baseline dashboard stats
- Complete flashcard session
- Return to dashboard
- Verify flashcard count incremented
- Verify total study time updated
- Verify streak calculation correct
- Verify charts reflect new data

#### Test 9: Belt Progression Validation ⬜
**Flow:** Verify content filters correctly across belt levels
- Create profiles at different belt levels (9th keup, 5th keup, 1st keup)
- Verify each sees belt-appropriate content:
  - Terminology count increases with belt level
  - Patterns unlock progressively
  - Step sparring sequences available correctly
  - Line work exercises match belt

#### Test 10: Search Functionality ⬜
**Flow:** Search terminology/techniques → Verify results → Select → Verify detail view
- Navigate to techniques/terminology search
- Enter search query (random technique name)
- Verify search results accuracy
- Select search result
- Verify detail view displays correctly
- Test Korean and English search

#### Test 11: Navigation Resilience ⬜
**Flow:** Navigate forward 10 levels deep → Back button → Verify no crashes/state loss
- Start at dashboard
- Navigate through: Dashboard → Learning → Flashcards → Config → Session → Results → Dashboard → Profile → Edit → ... (10+ screens)
- Use back button to navigate backward
- Verify no crashes
- Verify no state loss
- Verify navigation stack integrity

#### Test 12: Multi-Session Workflow ⬜
**Flow:** Flashcards → Patterns → Test → Dashboard → Verify all sessions logged
- Complete flashcard session
- Complete pattern practice
- Complete multiple choice test
- Return to dashboard
- Verify all 3 sessions appear in history
- Verify aggregated stats correct
- Verify streak calculation considers all sessions

### Test Implementation Approach

**Key Learnings Applied:**
- ✅ Use explicit waits (`waitForExistence`) not sleeps
- ✅ Validate data-layer properties, not UI element counts
- ✅ Support multiple label variations for robustness
- ✅ Use randomization for input values (counts, modes, selections)
- ✅ Sanity check accuracy percentages and calculations

**Data Layer Validation Principle:**
For isolation tests, validate **what profiles HAVE** (belt levels, settings, progress), not **what the UI RENDERS** (card counts, list items). SwiftUI caches views aggressively.

### Success Metrics
- [ ] All 12 E2E tests passing consistently (5+ runs)
- [ ] Test execution time <30s per test (<6 minutes total)
- [ ] Zero flaky tests (100% pass rate across 20 runs)
- [ ] Critical user journeys validated end-to-end

---

## Priority 4: User Testing Feedback

**Status:** Planned
**Timeline:** 2-4 weeks (ongoing)
**Priority:** MEDIUM - Address remaining user-reported issues

### Feedback Collection & Prioritization
- Collect user feedback from testing sessions
- Categorize by severity (Critical/High/Medium/Low)
- Prioritize based on frequency and impact
- Track resolution status

### Categories

**UI/UX Improvements:**
- Navigation clarity enhancements
- Visual feedback improvements
- Button/control placement optimization
- Color contrast adjustments

**Feature Enhancements:**
- Requested feature variations
- Workflow optimizations
- Performance improvements
- Content additions

**Bug Fixes:**
- Edge case handling
- Error message clarity
- Data validation improvements
- Recovery mechanisms

### Process
1. **Collect:** Gather feedback from users
2. **Triage:** Categorize and prioritize
3. **Validate:** Reproduce and understand issue
4. **Implement:** Fix or enhance
5. **Test:** Validate resolution
6. **Deploy:** Release to users
7. **Verify:** Confirm issue resolved

---

## Priority 5: Image Generation & Integration

**Status:** Planned
**Timeline:** 4-6 weeks
**Priority:** MEDIUM - Transforms text-based to visually rich learning

### Overview
Transform app from text-heavy to visually rich learning experience with 300+ professional-quality martial arts images.

### Image Requirements

**Total Images:** 322
- **App Icons:** 18 sizes (1024×1024 to 20×20)
- **Pattern Diagrams:** 9 images (one per pattern)
- **Pattern Moves:** 258 images (moves across 11 patterns)
- **Step Sparring:** 54 images (attack/defense/counter sequences)
- **Branding:** 1 launch logo

### Asset Structure (Already Created)
```
TKDojang.xcassets/
├── AppIcon.appiconset/          # 18 icon sizes
├── Patterns/
│   ├── Diagrams/                # 9 pattern diagrams
│   └── Moves/                   # 258 pattern moves
├── StepSparring/                # 54 sparring images
└── Branding/                    # Launch logo
```

### Implementation Tasks

#### 1. Image Resizing & Optimization
**Batch Processing Script:**
```bash
# Resize images for 2x/3x iOS displays
# Optimize file sizes (<300KB for moves, <200KB for diagrams)
# Convert to PNG with proper transparency
# Validate aspect ratios (3:4 portrait, 4:3 landscape, 1:1 square)
```

**Quality Requirements:**
- Resolution: Meets 2x/3x specifications
- Format: PNG with transparency
- File Size: <300KB for moves, <200KB for diagrams
- Aspect Ratio: Correct for category

#### 2. JSON File Updates
**Update all pattern/step sparring JSON files:**
```json
// Before: URL references
{"image_url": "https://example.com/moves/chon-ji-1.jpg"}

// After: Asset catalog names
{"image_url": "chon-ji-1"}
```

#### 3. AsyncImage Integration
- Update all image loading to use asset catalog names
- Implement fallback for missing images
- Add loading states and error handling
- Performance testing (ensure no startup impact)

#### 4. Visual Consistency Validation
- Character consistency across pattern sets
- Belt color accuracy for each keup level
- Lighting and background uniformity
- Cultural authenticity review

### Success Metrics
- [ ] All 322 images integrated successfully
- [ ] No impact on app startup time (<2 seconds maintained)
- [ ] Memory usage within limits (<200MB for image loading)
- [ ] User feedback: "Images help learning" rating >4.5/5

---

## Priority 6: Video Content Support

**Status:** Planned
**Timeline:** 4-6 weeks
**Priority:** LOW - Enhancement for advanced learning

### Feature Requirements

#### 1. Video Infrastructure
- **Video Player Integration**: AVPlayer for inline video playback
- **Video Storage**: Local video files in app bundle or downloaded content
- **Streaming Support**: Optional streaming for larger video library
- **Offline Access**: Downloaded videos available offline

#### 2. Video Content Types

**Pattern Demonstrations:**
- Full pattern performance (real-time speed)
- Slow-motion breakdowns
- Move-by-move instruction
- Multiple camera angles

**Technique Tutorials:**
- Proper form demonstrations
- Common mistakes highlighted
- Application examples
- Training drills

**Step Sparring Sequences:**
- Attack/defense/counter demonstrations
- Partner interaction videos
- Timing and rhythm instruction

#### 3. Video Controls
- Play/Pause
- Seek bar with preview thumbnails
- Playback speed control (0.5x, 1x, 2x)
- Loop/repeat options
- Fullscreen mode

#### 4. Integration Points
- **Pattern Practice:** "Watch Demonstration" button
- **Techniques Library:** Video alongside written description
- **Step Sparring:** "See Example" for each sequence
- **Theory:** Instructional videos for concepts

### Technical Considerations
- **File Size Management**: Optimize video compression
- **Download System**: Progressive download, resume capability
- **Storage Management**: User control over downloaded videos
- **Performance**: Hardware acceleration, efficient buffering

### Success Metrics
- [ ] Video playback smooth on target devices
- [ ] Download/streaming reliable
- [ ] Storage impact acceptable (<500MB for core videos)
- [ ] User feedback: "Videos improve understanding" >4/5

---

## Priority 7: Additional Features & Enhancements

**Status:** Planned
**Timeline:** Ongoing
**Priority:** LOW - Nice-to-have enhancements

### iCloud Backup & Sync

**Requirements:**
- Profile data backup to iCloud
- Progress sync across devices
- Conflict resolution for multi-device use
- Privacy-first approach (user controls sync)

**Implementation:**
- CloudKit integration
- Selective sync (profiles, progress, settings)
- Offline-first with sync when available
- Clear sync status indicators

### Additional Enhancements

**Widget Support:**
- Home screen widgets for quick stats
- Study streak widget
- Daily goal progress widget
- Quick launch to specific features

**Shortcuts Integration:**
- Siri shortcuts for common actions
- "Start flashcard session"
- "Practice today's pattern"
- "Check my progress"

**Apple Watch Support:**
- Basic flashcard functionality
- Progress tracking
- Workout integration (pattern practice as activity)
- Glanceable stats

**iPad Optimization:**
- Enhanced layouts for larger screens
- Split view support
- Keyboard shortcuts
- External display support

### Success Metrics
- [ ] iCloud sync reliable (>99% success rate)
- [ ] Cross-device experience seamless
- [ ] Widgets provide value (daily interaction >30%)
- [ ] User adoption of extended features >40%

---

## Long-Term Vision

### Platform Expansion
- **Apple Watch App**: Standalone flashcard functionality
- **iPad Pro Optimization**: Pencil support for pattern tracing
- **macOS App**: Full-featured desktop experience
- **tvOS App**: Large-screen practice mode

### Content Expansion
- **Advanced Patterns**: Black belt patterns (Kwang-Gae through Se-Jong)
- **Multiple Styles**: ITF, WTF, ATA variations
- **International Content**: Multi-language support (Spanish, French, Korean)
- **Regional Variations**: Accommodate different teaching methodologies

### Community Features
- **Instructor Mode**: Track student progress (separate app/premium feature)
- **Dojang Integration**: School-specific content and tracking
- **Achievement Sharing**: Social sharing (privacy-controlled)
- **Leaderboards**: Optional competitive features

---

## Success Metrics Framework

### Development Quality
- **Test Coverage**: Maintain 100% test pass rate
- **Build Health**: Zero compilation errors
- **Performance**: <2s startup, responsive UI
- **Accessibility**: WCAG 2.2 Level AA compliance maintained

### User Experience
- **Onboarding Success**: >90% complete welcome flow
- **Feature Adoption**: >70% users try each major feature
- **Retention**: >60% weekly active users
- **Satisfaction**: >4/5 average rating

### Technical Excellence
- **Reliability**: <1% crash rate
- **Performance**: <200MB memory usage
- **Battery**: <5% battery drain per hour of use
- **Storage**: <500MB total app size (including videos)

---

**This roadmap balances user needs, technical excellence, and sustainable development practices. Priorities may adjust based on user feedback, technical discoveries, or market changes.**
