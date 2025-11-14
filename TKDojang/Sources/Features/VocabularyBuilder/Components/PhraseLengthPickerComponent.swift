import SwiftUI

/**
 * PhraseLengthPickerComponent.swift
 *
 * PURPOSE: Reusable component for selecting phrase length (word count) in Slot Builder
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

struct PhraseLengthPickerComponent: View {

    // MARK: - Properties

    /// Binding to the selected phrase length (number of words)
    @Binding var phraseLength: Int

    /// Whether this component is in demo/disabled mode (for tours)
    var isDemo: Bool = false

    // MARK: - Constants

    private let availableLengths = [2, 3, 4, 5]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Phrase Length")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("slot-builder-phrase-length-header")

            // Description
            Text("Number of words in each phrase. Start with 2-3 words for easier patterns.")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityIdentifier("slot-builder-phrase-length-description")

            // Length options (segmented picker style)
            VStack(spacing: 12) {
                ForEach(availableLengths, id: \.self) { length in
                    phraseLengthOption(length: length)
                }
            }
        }
        .opacity(isDemo ? 0.7 : 1.0) // Visual indication of demo mode
    }

    // MARK: - Subviews

    private func phraseLengthOption(length: Int) -> some View {
        Button(action: {
            if !isDemo {
                phraseLength = length
            }
        }) {
            HStack {
                // Selection indicator
                Image(systemName: phraseLength == length ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(phraseLength == length ? .accentColor : .secondary)
                    .accessibilityHidden(true)

                // Length info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(length) Words")
                        .font(.body)
                        .fontWeight(phraseLength == length ? .semibold : .regular)
                        .foregroundColor(.primary)

                    Text(difficultyDescription(for: length))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Difficulty badge
                Text(difficultyLabel(for: length))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: length).opacity(0.2))
                    .foregroundColor(difficultyColor(for: length))
                    .cornerRadius(6)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        phraseLength == length ? Color.accentColor : Color.secondary.opacity(0.3),
                        lineWidth: phraseLength == length ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDemo)
        .accessibilityIdentifier("slot-builder-phrase-length-\(length)w")
        .accessibilityLabel("\(length) word phrases, \(difficultyLabel(for: length)) difficulty")
        .accessibilityHint(difficultyDescription(for: length))
        .accessibilityAddTraits(phraseLength == length ? .isSelected : [])
    }

    // MARK: - Helpers

    private func difficultyLabel(for length: Int) -> String {
        switch length {
        case 2: return "Beginner"
        case 3: return "Intermediate"
        case 4: return "Advanced"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }

    private func difficultyColor(for length: Int) -> Color {
        switch length {
        case 2: return .green
        case 3: return .blue
        case 4: return .orange
        case 5: return .red
        default: return .gray
        }
    }

    private func difficultyDescription(for length: Int) -> String {
        switch length {
        case 2:
            return "Simple patterns like 'Forearm Block' or 'Rising Kick'"
        case 3:
            return "Common techniques like 'Outer Forearm Block'"
        case 4:
            return "Complex phrases like 'Outer Forearm High Block'"
        case 5:
            return "Full complexity like 'Twin Outer Forearm High Block'"
        default:
            return ""
        }
    }
}

// MARK: - Preview

#Preview("Interactive Mode") {
    VStack(spacing: 32) {
        Text("Interactive Mode")
            .font(.headline)

        PhraseLengthPickerComponent(
            phraseLength: .constant(2)
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

        PhraseLengthPickerComponent(
            phraseLength: .constant(3),
            isDemo: true
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("All Lengths") {
    ScrollView {
        VStack(spacing: 32) {
            ForEach([2, 3, 4, 5], id: \.self) { length in
                VStack {
                    Text("\(length) Words Selected")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    PhraseLengthPickerComponent(
                        phraseLength: .constant(length)
                    )
                }
            }
        }
        .padding()
    }
}
