import SwiftUI

/**
 * WordCategoryPickerComponent.swift
 *
 * PURPOSE: Reusable component for selecting words from a category in Slot Builder
 *
 * FEATURES:
 * - Shows 4-6 word choices for current slot
 * - Displays English + romanised Korean for each option
 * - Category color coding
 * - Tap to select word
 * - Grid layout for compact presentation
 * - Accessibility support with semantic labels
 *
 * USAGE CONTEXTS:
 * 1. Production: SlotBuilderGameView (word selection during gameplay)
 * 2. Tours: Demo mode showing available choices
 *
 * ARCHITECTURE: Extracted component for reusability and tour integration
 */

struct WordCategoryPickerComponent: View {

    // MARK: - Properties

    /// Available word choices for this slot
    let wordChoices: [CategorizedWord]

    /// Category label for display
    let categoryLabel: String

    /// Category for color coding
    let category: WordCategory

    /// Currently selected word (if any)
    let selectedWord: CategorizedWord?

    /// Whether this component is in demo mode (for tours)
    var isDemo: Bool = false

    /// Action when word is selected
    var onSelectWord: ((CategorizedWord) -> Void)?

    // MARK: - Layout

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(categoryColor)
                    .accessibilityHidden(true)

                Text("Select \(categoryLabel)")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                Text("\(wordChoices.count) options")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Select \(categoryLabel), \(wordChoices.count) options")

            // Word choices grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(wordChoices) { word in
                    wordChoiceButton(word: word)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Subviews

    private func wordChoiceButton(word: CategorizedWord) -> some View {
        Button(action: {
            if !isDemo {
                onSelectWord?(word)
            }
        }) {
            VStack(spacing: 6) {
                Text(word.english)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(word.romanised)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected(word) ? categoryColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected(word) ? categoryColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDemo)
        .accessibilityIdentifier("slot-builder-word-choice-\(word.english.lowercased())")
        .accessibilityLabel("\(word.english), \(word.romanised)")
        .accessibilityHint(isSelected(word) ? "Currently selected" : "Tap to select this word")
        .accessibilityAddTraits(isSelected(word) ? .isSelected : [])
    }

    // MARK: - Helpers

    private func isSelected(_ word: CategorizedWord) -> Bool {
        selectedWord?.id == word.id
    }

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
}

// MARK: - Preview

#Preview("Tool Category") {
    WordCategoryPickerComponent(
        wordChoices: [
            CategorizedWord(english: "Forearm", romanised: "Palmok", category: .tool, frequency: 18),
            CategorizedWord(english: "Fist", romanised: "Joomuk", category: .tool, frequency: 11),
            CategorizedWord(english: "Palm", romanised: "Sonbadak", category: .tool, frequency: 10),
            CategorizedWord(english: "Knife", romanised: "Sonkal", category: .tool, frequency: 13)
        ],
        categoryLabel: "Tool",
        category: .tool,
        selectedWord: nil
    )
    .padding()
}

#Preview("Action Category - With Selection") {
    WordCategoryPickerComponent(
        wordChoices: [
            CategorizedWord(english: "Block", romanised: "Makgi", category: .action, frequency: 27),
            CategorizedWord(english: "Kick", romanised: "Chagi", category: .action, frequency: 14),
            CategorizedWord(english: "Punch", romanised: "Jirugi", category: .action, frequency: 9),
            CategorizedWord(english: "Strike", romanised: "Taerigi", category: .action, frequency: 11)
        ],
        categoryLabel: "Action",
        category: .action,
        selectedWord: CategorizedWord(english: "Block", romanised: "Makgi", category: .action, frequency: 27)
    )
    .padding()
}

#Preview("Direction Category - 6 Options") {
    WordCategoryPickerComponent(
        wordChoices: [
            CategorizedWord(english: "Outer", romanised: "Bakat", category: .direction, frequency: 10),
            CategorizedWord(english: "Inner", romanised: "An", category: .direction, frequency: 3),
            CategorizedWord(english: "Rising", romanised: "Chookyo", category: .direction, frequency: 3),
            CategorizedWord(english: "Upward", romanised: "Ollyo", category: .direction, frequency: 4),
            CategorizedWord(english: "Front", romanised: "Ap", category: .direction, frequency: 5),
            CategorizedWord(english: "Side", romanised: "Yop", category: .direction, frequency: 8)
        ],
        categoryLabel: "Direction",
        category: .direction,
        selectedWord: nil
    )
    .padding()
}

#Preview("Demo Mode") {
    WordCategoryPickerComponent(
        wordChoices: [
            CategorizedWord(english: "High", romanised: "Nopunde", category: .target, frequency: 5),
            CategorizedWord(english: "Middle", romanised: "Kaunde", category: .target, frequency: 3),
            CategorizedWord(english: "Low", romanised: "Daebi", category: .target, frequency: 4)
        ],
        categoryLabel: "Target",
        category: .target,
        selectedWord: CategorizedWord(english: "High", romanised: "Nopunde", category: .target, frequency: 5),
        isDemo: true
    )
    .padding()
}
