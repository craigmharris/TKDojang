import SwiftUI

/**
 * PhraseSlotComponent.swift
 *
 * PURPOSE: Reusable component for displaying individual phrase slots in Slot Builder
 *
 * FEATURES:
 * - Shows slot position, category label, and selected word
 * - Visual states: empty, filled, current (active)
 * - Category color coding (Action=red, Tool=blue, Direction=green, etc.)
 * - Tap to activate/edit slot
 * - Accessibility support with semantic labels
 *
 * USAGE CONTEXTS:
 * 1. Production: SlotBuilderGameView (interactive slot filling)
 * 2. Tours: Demo mode showing example phrase construction
 *
 * ARCHITECTURE: Extracted component for reusability and tour integration
 */

struct PhraseSlotComponent: View {

    // MARK: - Properties

    /// Slot position (1-based for display)
    let position: Int

    /// Category label (e.g., "Tool", "Action", "Direction")
    let categoryLabel: String

    /// Category for color coding
    let category: WordCategory

    /// Selected word for this slot (nil if empty)
    let selectedWord: CategorizedWord?

    /// Whether this is the current active slot
    let isCurrent: Bool

    /// Whether this component is in demo mode (for tours)
    var isDemo: Bool = false

    /// Action when slot is tapped
    var onTap: (() -> Void)?

    // MARK: - Body

    var body: some View {
        Button(action: {
            if !isDemo {
                onTap?()
            }
        }) {
            VStack(spacing: 8) {
                // Slot number badge
                HStack {
                    Text("\(position)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(categoryColor))

                    Spacer()

                    // Category label
                    Text(categoryLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                }

                // Selected word or empty state
                if let word = selectedWord {
                    VStack(spacing: 4) {
                        Text(word.english)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(word.romanized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                } else {
                    Text(isCurrent ? "Select word" : "Empty")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isCurrent ? 3 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDemo)
        .accessibilityIdentifier("slot-builder-slot-\(position)")
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    // MARK: - Styling

    private var categoryColor: Color {
        switch category {
        case .action: return .red
        case .tool: return .blue
        case .direction: return .green
        case .target: return .orange
        case .techniqueModifier: return .purple
        case .position: return .cyan
        case .execution: return .yellow
        }
    }

    private var backgroundColor: Color {
        if isCurrent {
            return categoryColor.opacity(0.1)
        } else if selectedWord != nil {
            return Color(.secondarySystemGroupedBackground)
        } else {
            return Color(.tertiarySystemGroupedBackground)
        }
    }

    private var borderColor: Color {
        if isCurrent {
            return categoryColor
        } else if selectedWord != nil {
            return categoryColor.opacity(0.3)
        } else {
            return Color.secondary.opacity(0.2)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let stateLabel = isCurrent ? "Current slot" : "Slot \(position)"
        let wordLabel = selectedWord?.english ?? "Empty"
        return "\(stateLabel), \(categoryLabel), \(wordLabel)"
    }

    private var accessibilityHint: String {
        if isDemo {
            return "Demo mode, interaction disabled"
        } else if isCurrent {
            return "Tap to select a word from \(categoryLabel) category"
        } else if selectedWord != nil {
            return "Tap to change selected word"
        } else {
            return "Tap to fill this slot"
        }
    }
}

// MARK: - Preview

#Preview("Empty Slot") {
    PhraseSlotComponent(
        position: 1,
        categoryLabel: "Tool",
        category: .tool,
        selectedWord: nil,
        isCurrent: false
    )
    .padding()
}

#Preview("Current Slot (Active)") {
    PhraseSlotComponent(
        position: 2,
        categoryLabel: "Action",
        category: .action,
        selectedWord: nil,
        isCurrent: true
    )
    .padding()
}

#Preview("Filled Slot") {
    PhraseSlotComponent(
        position: 1,
        categoryLabel: "Tool",
        category: .tool,
        selectedWord: CategorizedWord(
            english: "Forearm",
            romanized: "Palmok",
            category: .tool,
            frequency: 18
        ),
        isCurrent: false
    )
    .padding()
}

#Preview("Current Filled Slot") {
    PhraseSlotComponent(
        position: 3,
        categoryLabel: "Direction",
        category: .direction,
        selectedWord: CategorizedWord(
            english: "Outer",
            romanized: "Bakat",
            category: .direction,
            frequency: 10
        ),
        isCurrent: true
    )
    .padding()
}

#Preview("All Categories") {
    ScrollView {
        VStack(spacing: 16) {
            ForEach(WordCategory.allCases) { category in
                PhraseSlotComponent(
                    position: 1,
                    categoryLabel: category.displayName,
                    category: category,
                    selectedWord: CategorizedWord(
                        english: "Example",
                        romanized: "Example",
                        category: category,
                        frequency: 1
                    ),
                    isCurrent: false
                )
            }
        }
        .padding()
    }
}
