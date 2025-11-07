import SwiftUI

/**
 * CardCountPickerComponent.swift
 *
 * PURPOSE: Reusable component for selecting number of flashcards in a session
 *
 * USAGE CONTEXTS:
 * 1. Production: FlashcardConfigurationView (live user interaction)
 * 2. Testing: Component tests with ViewInspector
 * 3. Tours: Live demo in feature tour (disabled mode)
 *
 * ARCHITECTURE: Extracted from FlashcardConfigurationView to enable reuse
 * WHY:
 * - Component can be embedded in tour with .disabled(true) for demo
 * - Changes to UI automatically update tour (zero maintenance)
 * - Testable in isolation with different configurations
 * - Consistent UX across all usage contexts
 */

struct CardCountPickerComponent: View {

    // MARK: - Properties

    /// Binding to the selected number of terms
    @Binding var numberOfTerms: Int

    /// Total available terms for the current configuration
    let availableTermsCount: Int

    /// Whether this component is in demo/disabled mode (for tours)
    var isDemo: Bool = false

    // MARK: - Computed Properties

    private var maxTerms: Int {
        min(50, max(availableTermsCount, 5))
    }

    private var sliderRange: ClosedRange<Double> {
        5...Double(maxTerms)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Current selection display
            HStack {
                Text("Terms in session:")
                    .font(.subheadline)
                    .accessibilityIdentifier("flashcard-cardcount-label")

                Spacer()

                Text("\(numberOfTerms)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .accessibilityIdentifier("flashcard-cardcount-value")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Terms in session: \(numberOfTerms)")

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(numberOfTerms) },
                        set: { numberOfTerms = Int($0) }
                    ),
                    in: sliderRange,
                    step: 5
                )
                .tint(.orange)
                .disabled(isDemo)
                .accessibilityIdentifier("flashcard-cardcount-slider")
                .accessibilityLabel("Number of flashcards slider")
                .accessibilityValue("\(numberOfTerms) cards")
                .accessibilityHint("Adjusts between 5 and \(maxTerms) cards in steps of 5")

                // Min/Max labels
                HStack {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Spacer()

                    Text("\(maxTerms)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }

            // Available terms info
            if availableTermsCount > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("\(availableTermsCount) terms available for your current settings")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(availableTermsCount) terms available")
                .accessibilityIdentifier("flashcard-cardcount-available-info")
            }
        }
        .opacity(isDemo ? 0.7 : 1.0) // Visual indication of demo mode
    }
}

// MARK: - Preview

#Preview("Interactive - 50 Available") {
    VStack(spacing: 32) {
        Text("Interactive Mode")
            .font(.headline)

        CardCountPickerComponent(
            numberOfTerms: .constant(20),
            availableTermsCount: 50
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Demo Mode (Tour)") {
    VStack(spacing: 32) {
        Text("Demo Mode (Tour)")
            .font(.headline)

        CardCountPickerComponent(
            numberOfTerms: .constant(25),
            availableTermsCount: 50,
            isDemo: true
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Limited Terms (15)") {
    VStack(spacing: 32) {
        Text("Limited Available Terms")
            .font(.headline)

        CardCountPickerComponent(
            numberOfTerms: .constant(15),
            availableTermsCount: 15
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}
