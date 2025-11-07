import SwiftUI

/**
 * FeatureTourView.swift
 *
 * PURPOSE: Generic, reusable tour view that works for ALL features
 *
 * ARCHITECTURE DECISION: ONE view for ALL feature tours
 * WHY:
 * - Zero code duplication - same tour UI for flashcards, testing, patterns, step sparring
 * - Tours defined as data (FeatureTourDefinitions), not code
 * - Adding new features requires only adding tour step data
 * - Consistent user experience across all feature tours
 *
 * KEY BENEFIT: Feature changes don't require tour updates (components are reused live)
 *
 * USAGE:
 * ```swift
 * .sheet(isPresented: $showingTour) {
 *     FeatureTourView(
 *         feature: .flashcards,
 *         onComplete: { coordinator.completeTour(.flashcards, for: profile) },
 *         onSkip: { coordinator.completeTour(.flashcards, for: profile) }
 *     )
 * }
 * ```
 */

struct FeatureTourView: View {

    // MARK: - Properties

    /// The feature to show tour for
    let feature: OnboardingCoordinator.FeatureTour

    /// Called when user completes tour (reaches last step and taps Done)
    let onComplete: () -> Void

    /// Called when user skips tour (taps Skip button)
    let onSkip: () -> Void

    // MARK: - State

    /// Current step index (0-based)
    @State private var currentStep = 0

    /// Tour steps loaded from feature definition
    private let steps: [FeatureTourStep]

    // MARK: - Initialization

    init(
        feature: OnboardingCoordinator.FeatureTour,
        onComplete: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) {
        self.feature = feature
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.steps = feature.tourSteps
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    TourStepCard(step: step)
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    skipButton
                }

                ToolbarItem(placement: .principal) {
                    progressIndicator
                }

                ToolbarItem(placement: .topBarTrailing) {
                    doneOrNextButton
                }
            }
            .navigationTitle(feature.title)
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled() // Prevent accidental dismissal - force skip/done
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(feature.title) tour, step \(currentStep + 1) of \(steps.count)")
    }

    // MARK: - Toolbar Components

    @ViewBuilder
    private var skipButton: some View {
        // Show Skip button on all steps except the last one
        if currentStep < steps.count - 1 {
            Button("Skip") {
                handleSkip()
            }
            .accessibilityLabel("Skip tour")
            .accessibilityHint("Close this tour without completing it")
        }
    }

    @ViewBuilder
    private var progressIndicator: some View {
        Text("\(currentStep + 1) / \(steps.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Step \(currentStep + 1) of \(steps.count)")
    }

    @ViewBuilder
    private var doneOrNextButton: some View {
        if currentStep == steps.count - 1 {
            // Last step - show Done button
            Button("Done") {
                handleComplete()
            }
            .fontWeight(.semibold)
            .accessibilityLabel("Complete tour")
            .accessibilityHint("Mark this tour as complete and close")
        } else {
            // Not last step - show empty space (swipe to advance)
            // Note: TabView handles swipe gestures automatically
            EmptyView()
        }
    }

    // MARK: - Actions

    private func handleSkip() {
        DebugLogger.ui("⏭️ User skipped \(feature.title) tour at step \(currentStep + 1)/\(steps.count)")
        onSkip()
    }

    private func handleComplete() {
        DebugLogger.ui("✅ User completed \(feature.title) tour")
        onComplete()
    }
}

// MARK: - Preview

#Preview("Flashcard Tour") {
    FeatureTourView(
        feature: .flashcards,
        onComplete: {
            print("Tour completed")
        },
        onSkip: {
            print("Tour skipped")
        }
    )
}

#Preview("Multiple Choice Tour") {
    FeatureTourView(
        feature: .multipleChoice,
        onComplete: {
            print("Tour completed")
        },
        onSkip: {
            print("Tour skipped")
        }
    )
}

#Preview("Pattern Tour") {
    FeatureTourView(
        feature: .patterns,
        onComplete: {
            print("Tour completed")
        },
        onSkip: {
            print("Tour skipped")
        }
    )
}

#Preview("Step Sparring Tour") {
    FeatureTourView(
        feature: .stepSparring,
        onComplete: {
            print("Tour completed")
        },
        onSkip: {
            print("Tour skipped")
        }
    )
}
