import Foundation
import SwiftUI

/**
 * FeatureTourDefinitions.swift
 *
 * PURPOSE: Data-driven tour step definitions for all features
 *
 * ARCHITECTURE DECISION: Tours defined as DATA, not code
 * WHY:
 * - Adding/modifying tour steps doesn't require code changes across files
 * - Generic FeatureTourView can display ANY feature's tour
 * - Tour content centralized in one location for easy maintenance
 * - Live component embedding allows production components to appear in tours
 *
 * KEY BENEFIT: When production components change, tours update automatically
 */

// MARK: - FeatureTourStep Structure

/**
 * Represents a single step in a feature tour
 *
 * WHY: Supports both static content and live component demos
 * - icon: SF Symbol name for visual consistency
 * - title: Brief step heading (3-8 words)
 * - description: Detailed explanation (2-4 sentences)
 * - liveComponent: Optional SwiftUI view to show component in demo mode
 * - tipText: Quick actionable tip (1 sentence, optional)
 */
struct FeatureTourStep: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let liveComponent: AnyView?
    let tipText: String?

    init(
        icon: String,
        title: String,
        description: String,
        liveComponent: AnyView? = nil,
        tipText: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.liveComponent = liveComponent
        self.tipText = tipText
    }
}

// MARK: - Feature Tour Extensions

/**
 * Extension to add tour step definitions to each feature
 *
 * WHY: Keeps tour content with feature enum, easy to find and update
 */
extension OnboardingCoordinator.FeatureTour {

    /// Tour steps for this feature
    /// Note: Day 2+ will add actual content. Day 1 provides structure only.
    var tourSteps: [FeatureTourStep] {
        switch self {
        case .flashcards:
            return flashcardTourSteps
        case .multipleChoice:
            return multipleChoiceTourSteps
        case .patterns:
            return patternTourSteps
        case .stepSparring:
            return stepSparringTourSteps
        }
    }

    /// Help button text for toolbar
    var helpButtonTitle: String {
        switch self {
        case .flashcards:
            return "How do flashcards work?"
        case .multipleChoice:
            return "How do tests work?"
        case .patterns:
            return "How to practice patterns?"
        case .stepSparring:
            return "How does step sparring work?"
        }
    }

    /// Accessibility identifier for help button
    var helpButtonAccessibilityID: String {
        return "\(self.rawValue)-help-button"
    }
}

// MARK: - Flashcard Tour Steps

/**
 * Flashcard feature tour (5 steps)
 *
 * WHY: Flashcards are the most complex feature with multiple configuration options
 * - Study modes (Learn vs Test)
 * - Card direction (Korean→English, English→Korean, Both)
 * - Card count selection
 * - Leitner spaced repetition system
 * - Progress tracking
 *
 * NOTE: Day 2 will add live component demos to steps 2-3
 */
private var flashcardTourSteps: [FeatureTourStep] {
    [
        FeatureTourStep(
            icon: "rectangle.stack.badge.play",
            title: "Flashcard Learning",
            description: "Master Korean Taekwondo terminology through spaced repetition. Flashcards adapt to your learning progress, showing terms you struggle with more frequently.",
            tipText: "Start with 10-15 cards to build confidence before larger sessions"
        ),

        FeatureTourStep(
            icon: "brain.head.profile",
            title: "Study Modes",
            description: "Choose 'Learn' mode to see answers immediately and build familiarity. Switch to 'Test' mode when ready to challenge your memory without hints.",
            liveComponent: AnyView(
                VStack(spacing: 12) {
                    StudyModeCard(
                        mode: .learn,
                        isSelected: true,
                        onSelect: {}
                    )
                    StudyModeCard(
                        mode: .test,
                        isSelected: false,
                        onSelect: {}
                    )
                }
                .disabled(true) // Demo mode - visual only
            ),
            tipText: "Use Learn mode first, then Test mode once you know most terms"
        ),

        FeatureTourStep(
            icon: "arrow.left.arrow.right",
            title: "Card Direction",
            description: "Practice Korean→English to test recognition, English→Korean for recall, or Both to master terminology completely. Each direction builds different skills.",
            liveComponent: AnyView(
                VStack(spacing: 12) {
                    CardDirectionCard(
                        direction: .koreanToEnglish,
                        isSelected: false,
                        onSelect: {}
                    )
                    CardDirectionCard(
                        direction: .englishToKorean,
                        isSelected: false,
                        onSelect: {}
                    )
                    CardDirectionCard(
                        direction: .bothDirections,
                        isSelected: true,
                        onSelect: {}
                    )
                }
                .disabled(true) // Demo mode - visual only
            ),
            tipText: "Start with Korean→English (easier), then progress to English→Korean"
        ),

        FeatureTourStep(
            icon: "chart.line.uptrend.xyaxis",
            title: "Spaced Repetition",
            description: "The Leitner system automatically adjusts which cards you see based on your performance. Terms you know well appear less often, while challenging terms return sooner.",
            tipText: "Trust the system - it optimizes your learning efficiency"
        ),

        FeatureTourStep(
            icon: "checkmark.circle.fill",
            title: "Ready to Start",
            description: "Configure your session with the number of cards, study mode, and direction. Your progress is saved automatically, and you can resume anytime.",
            liveComponent: AnyView(
                CardCountPickerComponent(
                    numberOfTerms: .constant(20),
                    availableTermsCount: 50,
                    isDemo: true
                )
            ),
            tipText: "Consistent short sessions (10-15 min) are more effective than long cramming"
        )
    ]
}

// MARK: - Multiple Choice Tour Steps

/**
 * Multiple Choice test tour (5 steps)
 *
 * WHY: Testing system has complex configuration (test types, belt filtering, question selection)
 * ARCHITECTURE: Uses extracted components (TestTypeCard, QuestionCountSlider, BeltScopeToggle)
 * enabling live demos in tours
 */
private var multipleChoiceTourSteps: [FeatureTourStep] {
    [
        FeatureTourStep(
            icon: "checkmark.circle.fill",
            title: "Multiple Choice Testing",
            description: "Test your Taekwondo knowledge with customizable quizzes. Choose from Quick tests (5-10 questions), Custom tests (configurable), or Comprehensive tests (all available questions).",
            tipText: "Start with quick tests to gauge your knowledge level"
        ),

        FeatureTourStep(
            icon: "doc.text.fill",
            title: "Test Types",
            description: "Quick tests provide fast 5-10 question reviews. Custom tests let you choose exactly how many questions (10-25) to practice with. Comprehensive tests include all available content for thorough preparation.",
            liveComponent: AnyView(
                HStack(spacing: 12) {
                    TestTypeCard(
                        testType: .quick,
                        isSelected: false,
                        onSelect: {},
                        isDemo: true
                    )
                    TestTypeCard(
                        testType: .custom,
                        isSelected: true,
                        onSelect: {},
                        isDemo: true
                    )
                    TestTypeCard(
                        testType: .comprehensive,
                        isSelected: false,
                        onSelect: {},
                        isDemo: true
                    )
                }
            ),
            tipText: "Use quick tests for daily practice, comprehensive for exam prep"
        ),

        FeatureTourStep(
            icon: "number.circle.fill",
            title: "Question Count (Custom Only)",
            description: "When using Custom test mode, select between 10-25 questions in steps of 5. The slider shows how many questions are available for your current configuration.",
            liveComponent: AnyView(
                QuestionCountSlider(
                    questionCount: .constant(15),
                    availableQuestionsCount: 50,
                    isDemo: true
                )
                .padding()
            ),
            tipText: "Start with 10-15 questions until you build confidence"
        ),

        FeatureTourStep(
            icon: "figure.martial.arts",
            title: "Belt Scope Selection",
            description: "Choose 'Current Belt Only' to test just your current level, or 'All Belts Up to Current' to include all belts from white belt through your current rank for comprehensive review.",
            liveComponent: AnyView(
                BeltScopeToggle(
                    beltScope: .constant(.allUpToCurrent),
                    isDemo: true
                )
                .padding()
            ),
            tipText: "Focus on current belt first, then expand to all belts for review"
        ),

        FeatureTourStep(
            icon: "chart.bar.fill",
            title: "Ready to Test",
            description: "Configure your test settings and tap Start Test. There's no time limit - focus on learning, not speed. After each test, review detailed results showing what you missed and why.",
            tipText: "Review wrong answers immediately while the content is fresh"
        )
    ]
}

// MARK: - Pattern Practice Tour Steps

/**
 * Pattern practice tour (3 steps - lighter)
 *
 * WHY: Patterns are more straightforward (list-based selection, step-through practice)
 * Lighter tour focuses on essentials without overwhelming
 */
private var patternTourSteps: [FeatureTourStep] {
    [
        FeatureTourStep(
            icon: "figure.martial.arts",
            title: "Pattern Practice",
            description: "Practice traditional ITF Taekwondo patterns with step-by-step guidance. Each pattern is appropriate for your belt level and builds on previous patterns.",
            tipText: "Master each pattern's diagram before practicing individual moves"
        ),

        FeatureTourStep(
            icon: "arrow.forward.circle",
            title: "Move-by-Move Guidance",
            description: "Navigate through each move with detailed descriptions, Korean terminology, and key points. Swipe or tap arrows to progress through the pattern at your own pace.",
            tipText: "Practice slowly first, focusing on correct form over speed"
        ),

        FeatureTourStep(
            icon: "checkmark.circle.fill",
            title: "Ready to Practice",
            description: "Select a pattern appropriate for your belt level. Practice each move carefully, and return anytime to review. Your progress through patterns is tracked automatically.",
            tipText: "Practice patterns daily for 10-15 minutes to build muscle memory"
        )
    ]
}

// MARK: - Step Sparring Tour Steps

/**
 * Step sparring tour (3 steps - lighter)
 *
 * WHY: Step sparring has clear structure (attack→defense→counter)
 * Lighter tour explains the sequence concept
 */
private var stepSparringTourSteps: [FeatureTourStep] {
    [
        FeatureTourStep(
            icon: "figure.2.arms.open",
            title: "Step Sparring Sequences",
            description: "Learn pre-arranged sparring sequences that teach timing, distance, and defensive techniques. Each sequence follows a structured attack, defense, and counter pattern.",
            tipText: "Practice with a partner to develop proper timing and control"
        ),

        FeatureTourStep(
            icon: "arrow.triangle.2.circlepath",
            title: "Attack-Defense-Counter",
            description: "Each sequence shows the attacker's move, defender's block or evasion, and defender's counter-attack. Study each component separately, then practice the full sequence.",
            tipText: "Understand the purpose of each move - defense isn't just blocking"
        ),

        FeatureTourStep(
            icon: "checkmark.circle.fill",
            title: "Ready to Practice",
            description: "Select a sequence appropriate for your belt level. Review each step carefully before practicing with a partner. Sequences build progressive difficulty as you advance.",
            tipText: "Focus on control and accuracy - speed develops naturally with practice"
        )
    ]
}

// MARK: - Tour Metadata

/**
 * Additional metadata for tour display and behavior
 */
extension OnboardingCoordinator.FeatureTour {

    /// Number of steps in this tour
    var tourStepCount: Int {
        return tourSteps.count
    }

    /// Whether this tour includes live component demos
    /// (Used to adjust layout and spacing)
    var hasLiveComponents: Bool {
        return tourSteps.contains { $0.liveComponent != nil }
    }

    /// Estimated completion time in minutes
    var estimatedMinutes: Int {
        switch self {
        case .flashcards, .multipleChoice:
            return 3 // 5 steps @ ~35s each
        case .patterns, .stepSparring:
            return 2 // 3 steps @ ~40s each
        }
    }
}
