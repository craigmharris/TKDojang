import SwiftUI

/**
 * PhraseValidationComponent.swift
 *
 * PURPOSE: Reusable component for displaying phrase validation feedback in Slot Builder
 *
 * FEATURES:
 * - Success/error visual states
 * - Feedback message explanation
 * - Template name display
 * - Constructed phrase display (English + romanized)
 * - Continue button for next challenge
 * - Accessibility support with semantic labels
 *
 * USAGE CONTEXTS:
 * 1. Production: SlotBuilderGameView (validation feedback after phrase submission)
 * 2. Tours: Demo mode showing example feedback
 *
 * ARCHITECTURE: Extracted component for reusability and tour integration
 */

struct PhraseValidationComponent: View {

    // MARK: - Properties

    /// Validation result from service
    let validationResult: PhraseValidationResult

    /// User-constructed phrase
    let userPhrase: [CategorizedWord]

    /// Whether this component is in demo mode (for tours)
    var isDemo: Bool = false

    /// Action when continue button is tapped
    var onContinue: (() -> Void)?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            // Result icon
            Image(systemName: validationResult.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(validationResult.isCorrect ? .green : .red)
                .accessibilityHidden(true)

            // Result message
            VStack(spacing: 8) {
                Text(validationResult.isCorrect ? "Correct!" : "Not Quite")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(validationResult.isCorrect ? .green : .red)

                Text(validationResult.feedback)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Constructed phrase display
            VStack(spacing: 12) {
                Text("Your Phrase:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // English phrase
                Text(englishPhrase)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                // Romanized phrase
                Text(romanizedPhrase)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            // Template info
            VStack(spacing: 4) {
                Text("Template:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(validationResult.correctTemplate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

            // Continue button
            Button(action: {
                if !isDemo {
                    onContinue?()
                }
            }) {
                HStack {
                    Text("Continue")
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(validationResult.isCorrect ? Color.green : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isDemo)
            .accessibilityIdentifier("slot-builder-continue-button")
            .accessibilityLabel("Continue to next challenge")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helpers

    private var englishPhrase: String {
        userPhrase.map { $0.english }.joined(separator: " ")
    }

    private var romanizedPhrase: String {
        userPhrase.map { $0.romanized }.joined(separator: " ")
    }

    private var accessibilityLabel: String {
        let result = validationResult.isCorrect ? "Correct" : "Incorrect"
        return "\(result). \(validationResult.feedback). Your phrase: \(englishPhrase). Romanized: \(romanizedPhrase). Template: \(validationResult.correctTemplate)"
    }
}

// MARK: - Preview

#Preview("Correct Answer") {
    PhraseValidationComponent(
        validationResult: PhraseValidationResult(
            isCorrect: true,
            feedback: "You built a valid Direction + Tool + Action phrase.",
            correctTemplate: "Direction + Tool + Action"
        ),
        userPhrase: [
            CategorizedWord(english: "Outer", romanized: "Bakat", category: .direction, frequency: 10),
            CategorizedWord(english: "Forearm", romanized: "Palmok", category: .tool, frequency: 18),
            CategorizedWord(english: "Block", romanized: "Makgi", category: .action, frequency: 27)
        ]
    )
    .padding()
}

#Preview("Incorrect Answer") {
    PhraseValidationComponent(
        validationResult: PhraseValidationResult(
            isCorrect: false,
            feedback: "Position 2 should be Tool, but got Action: 'Block'",
            correctTemplate: "Direction + Tool + Action"
        ),
        userPhrase: [
            CategorizedWord(english: "Outer", romanized: "Bakat", category: .direction, frequency: 10),
            CategorizedWord(english: "Block", romanized: "Makgi", category: .action, frequency: 27),
            CategorizedWord(english: "Forearm", romanized: "Palmok", category: .tool, frequency: 18)
        ]
    )
    .padding()
}

#Preview("Correct 2-Word Phrase") {
    PhraseValidationComponent(
        validationResult: PhraseValidationResult(
            isCorrect: true,
            feedback: "Correct! You built a valid Tool + Action phrase.",
            correctTemplate: "Tool + Action"
        ),
        userPhrase: [
            CategorizedWord(english: "Fist", romanized: "Joomuk", category: .tool, frequency: 11),
            CategorizedWord(english: "Punch", romanized: "Jirugi", category: .action, frequency: 9)
        ]
    )
    .padding()
}

#Preview("Correct 5-Word Phrase") {
    PhraseValidationComponent(
        validationResult: PhraseValidationResult(
            isCorrect: true,
            feedback: "Excellent! You built a complete phrase with all elements.",
            correctTemplate: "Modifier + Direction + Tool + Section + Action"
        ),
        userPhrase: [
            CategorizedWord(english: "Twin", romanized: "Sang", category: .techniqueModifier, frequency: 6),
            CategorizedWord(english: "Outer", romanized: "Bakat", category: .position, frequency: 10),
            CategorizedWord(english: "Forearm", romanized: "Palmok", category: .tool, frequency: 18),
            CategorizedWord(english: "High", romanized: "Nopunde", category: .target, frequency: 5),
            CategorizedWord(english: "Block", romanized: "Makgi", category: .action, frequency: 27)
        ]
    )
    .padding()
}

#Preview("Demo Mode") {
    PhraseValidationComponent(
        validationResult: PhraseValidationResult(
            isCorrect: true,
            feedback: "Correct! You built a valid Tool + Action phrase.",
            correctTemplate: "Tool + Action"
        ),
        userPhrase: [
            CategorizedWord(english: "Knife", romanized: "Sonkal", category: .tool, frequency: 13),
            CategorizedWord(english: "Strike", romanized: "Taerigi", category: .action, frequency: 11)
        ],
        isDemo: true
    )
    .padding()
}
