import SwiftUI

/**
 * SessionCountPickerComponent.swift
 *
 * PURPOSE: Reusable component for selecting number of phrase challenges in a Slot Builder session
 *
 * USAGE CONTEXTS:
 * 1. Production: SlotBuilderConfigurationView (live user interaction)
 * 2. Testing: Component tests with ViewInspector
 * 3. Tours: Live demo in feature tour (disabled mode)
 *
 * ARCHITECTURE: Extracted component for reusability and tour integration
 * WHY:
 * - Component can be embedded in tour with isDemo=true for demo
 * - Changes to UI automatically update tour (zero maintenance)
 * - Testable in isolation with different configurations
 * - Consistent UX across all usage contexts
 */

struct SessionCountPickerComponent: View {

    // MARK: - Properties

    /// Binding to the selected number of phrases in session
    @Binding var phraseCount: Int

    /// Whether this component is in demo/disabled mode (for tours)
    var isDemo: Bool = false

    // MARK: - Computed Properties

    private var sliderRange: ClosedRange<Double> {
        5...20
    }

    private var estimatedTime: String {
        let minutes = phraseCount * 1 // ~1 minute per phrase
        if minutes < 5 {
            return "~5 min"
        } else if minutes <= 10 {
            return "~\(minutes) min"
        } else {
            return "~\(minutes) min"
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Current selection display
            HStack {
                Text("Phrases in session:")
                    .font(.subheadline)
                    .accessibilityIdentifier("slot-builder-sessioncount-label")

                Spacer()

                Text("\(phraseCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .accessibilityIdentifier("slot-builder-sessioncount-value")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Phrases in session: \(phraseCount)")

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(phraseCount) },
                        set: { phraseCount = Int($0) }
                    ),
                    in: sliderRange,
                    step: 1
                )
                .tint(.blue)
                .disabled(isDemo)
                .accessibilityIdentifier("slot-builder-sessioncount-slider")
                .accessibilityLabel("Number of phrases slider")
                .accessibilityValue("\(phraseCount) phrases")
                .accessibilityHint("Adjusts between 5 and 20 phrases")

                // Min/Max labels
                HStack {
                    Text("5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Spacer()

                    Text("20")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }

            // Estimated time info
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Estimated time: \(estimatedTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Estimated time: \(estimatedTime)")
            .accessibilityIdentifier("slot-builder-sessioncount-time-info")
        }
        .opacity(isDemo ? 0.7 : 1.0) // Visual indication of demo mode
    }
}

// MARK: - Preview

#Preview("Interactive - 10 Phrases") {
    VStack(spacing: 32) {
        Text("Interactive Mode")
            .font(.headline)

        SessionCountPickerComponent(
            phraseCount: .constant(10)
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

        SessionCountPickerComponent(
            phraseCount: .constant(15),
            isDemo: true
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Short Session (5)") {
    VStack(spacing: 32) {
        Text("Short Session")
            .font(.headline)

        SessionCountPickerComponent(
            phraseCount: .constant(5)
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Long Session (20)") {
    VStack(spacing: 32) {
        Text("Long Session")
            .font(.headline)

        SessionCountPickerComponent(
            phraseCount: .constant(20)
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}
