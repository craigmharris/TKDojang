import SwiftUI

/**
 * QuestionCountSlider.swift
 *
 * PURPOSE: Reusable slider component for selecting number of test questions
 *
 * USAGE CONTEXTS:
 * 1. Production: MultipleChoiceConfigurationView (live user interaction)
 * 2. Testing: Component tests with ViewInspector
 * 3. Tours: Live demo in feature tour (disabled mode)
 *
 * ARCHITECTURE: Extracted component to enable reuse in tours
 * WHY: Component can be embedded in tour with .disabled(true) for demo
 */

struct QuestionCountSlider: View {

    // MARK: - Properties

    @Binding var questionCount: Int
    let availableQuestionsCount: Int
    var isDemo: Bool = false

    // MARK: - Computed Properties

    /**
     * Dynamic minimum based on available questions
     * WHY: When very few questions available (< 15), starting at 10 creates invalid slider range
     * SOLUTION: Use smaller min (5) for small datasets
     */
    private var minQuestions: Int {
        if availableQuestionsCount < 15 {
            return min(5, availableQuestionsCount)
        }
        return 10
    }

    /**
     * Dynamic maximum capped at 25
     * WHY: Ensure max is always >= min to create valid slider range
     */
    private var maxQuestions: Int {
        min(25, max(availableQuestionsCount, minQuestions))
    }

    /**
     * Dynamic step size based on available questions
     * WHY: Small datasets need fine-grained control (step: 1), large datasets use step: 5
     * CRITICAL: Step must be smaller than range width to avoid "max stride must be positive" crash
     */
    private var stepSize: Double {
        if availableQuestionsCount < 15 {
            return 1  // Fine-grained control for small datasets
        }
        return 5  // Standard step for normal datasets
    }

    private var sliderRange: ClosedRange<Double> {
        Double(minQuestions)...Double(maxQuestions)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Current selection displayNo worries - have a great weekend!
            
            HStack {
                Text("Number of questions:")
                    .font(.subheadline)
                    .accessibilityIdentifier("test-config-questioncount-label")

                Spacer()

                Text("\(questionCount)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .accessibilityIdentifier("test-config-questioncount-value")
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Number of questions: \(questionCount)")

            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { Double(questionCount) },
                        set: { questionCount = Int($0) }
                    ),
                    in: sliderRange,
                    step: stepSize
                )
                .tint(.blue)
                .disabled(isDemo)
                .accessibilityIdentifier("test-config-questioncount-slider")
                .accessibilityLabel("Number of questions slider")
                .accessibilityValue("\(questionCount) questions")
                .accessibilityHint("Adjusts between \(minQuestions) and \(maxQuestions) questions in steps of \(Int(stepSize))")

                // Min/Max labels
                HStack {
                    Text("\(minQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)

                    Spacer()

                    Text("\(maxQuestions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
            }

            // Available questions info
            if availableQuestionsCount > 0 {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("\(availableQuestionsCount) questions available for your current settings")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(availableQuestionsCount) questions available")
                .accessibilityIdentifier("test-config-questioncount-available-info")
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

        QuestionCountSlider(
            questionCount: .constant(20),
            availableQuestionsCount: 50
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

        QuestionCountSlider(
            questionCount: .constant(15),
            availableQuestionsCount: 50,
            isDemo: true
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("Limited Questions (12)") {
    VStack(spacing: 32) {
        Text("Limited Available Questions")
            .font(.headline)

        QuestionCountSlider(
            questionCount: .constant(10),
            availableQuestionsCount: 12
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}
