import SwiftUI

/**
 * TestTypeCard.swift
 *
 * PURPOSE: Reusable card component for selecting test type
 *
 * USAGE CONTEXTS:
 * 1. Production: MultipleChoiceConfigurationView (live user interaction)
 * 2. Testing: Component tests with ViewInspector
 * 3. Tours: Live demo in feature tour (disabled mode)
 *
 * ARCHITECTURE: Extracted component to enable reuse in tours
 * WHY: Component can be embedded in tour with .disabled(true) for demo
 */

struct TestTypeCard: View {

    // MARK: - Properties

    let testType: TestType
    let isSelected: Bool
    let onSelect: () -> Void
    var isDemo: Bool = false

    // MARK: - Computed Properties

    private var icon: String {
        switch testType {
        case .quick:
            return "bolt.fill"
        case .custom:
            return "slider.horizontal.3"
        case .comprehensive:
            return "checkmark.circle.fill"
        }
    }

    private var color: Color {
        switch testType {
        case .quick:
            return .orange
        case .custom:
            return .blue
        case .comprehensive:
            return .green
        }
    }

    private var questionRange: String {
        switch testType {
        case .quick:
            return "5-10 questions"
        case .custom:
            return "10-25 questions"
        case .comprehensive:
            return "All available questions"
        }
    }

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? color : .secondary)

                // Title
                Text(testType.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Question Range
                Text(questionRange)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Description
                Text(testType.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDemo)
        .opacity(isDemo ? 0.7 : 1.0)
        .accessibilityIdentifier("test-config-testtype-\(testType.rawValue)")
        .accessibilityLabel("\(testType.displayName) test")
        .accessibilityHint(testType.description)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("All Test Types") {
    VStack(spacing: 16) {
        TestTypeCard(
            testType: .quick,
            isSelected: false,
            onSelect: {}
        )

        TestTypeCard(
            testType: .custom,
            isSelected: true,
            onSelect: {}
        )

        TestTypeCard(
            testType: .comprehensive,
            isSelected: false,
            onSelect: {}
        )
    }
    .padding()
}

#Preview("Demo Mode (Tour)") {
    VStack(spacing: 16) {
        Text("Demo Mode")
            .font(.headline)

        TestTypeCard(
            testType: .custom,
            isSelected: true,
            onSelect: {},
            isDemo: true
        )
    }
    .padding()
}
