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

    /// Content readiness flag
    @State private var isContentReady = false

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
            ZStack {
                // Main content (only shown when ready)
                if isContentReady {
                    TabView(selection: $currentStep) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            TourStepCard(step: step)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    .transition(.opacity)
                } else {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Preparing tour...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    skipButton
                }

                ToolbarItem(placement: .principal) {
                    if isContentReady {
                        progressIndicator
                    }
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
        .task {
            // Validate content and show with small delay to ensure components are ready
            await validateAndShowContent()
        }
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

    // MARK: - Content Validation

    /**
     * Validate content and show tour when ready
     *
     * WHY: Prevents blank screen issues when live components take time to load
     * - Validates that steps array is not empty
     * - Adds small delay to ensure SwiftUI components are rendered
     * - Auto-dismisses if no valid content (edge case protection)
     */
    @MainActor
    private func validateAndShowContent() async {
        // Check if we have valid steps
        guard !steps.isEmpty else {
            DebugLogger.ui("⚠️ Feature tour has no steps, auto-dismissing")
            // Auto-dismiss if no content
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            onSkip()
            return
        }

        // Add small delay to ensure live components are ready
        // WHY: Live components (like flashcard config UI) may need time to render
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        // Show content with animation
        withAnimation(.easeIn(duration: 0.2)) {
            isContentReady = true
        }

        DebugLogger.ui("✅ Feature tour content ready: \(feature.title) with \(steps.count) steps")
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
