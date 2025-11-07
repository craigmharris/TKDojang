import SwiftUI

/**
 * BeltScopeToggle.swift
 *
 * PURPOSE: Reusable toggle component for selecting belt scope (current only vs all up to current)
 *
 * USAGE CONTEXTS:
 * 1. Production: MultipleChoiceConfigurationView (live user interaction)
 * 2. Testing: Component tests with ViewInspector
 * 3. Tours: Live demo in feature tour (disabled mode)
 *
 * ARCHITECTURE: Extracted component to enable reuse in tours
 * WHY: Component can be embedded in tour with .disabled(true) for demo
 */

struct BeltScopeToggle: View {

    // MARK: - Properties

    @Binding var beltScope: TestUIConfig.BeltScope
    var isDemo: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Question Belt Levels")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Toggle options
            VStack(spacing: 12) {
                ForEach(TestUIConfig.BeltScope.allCases, id: \.self) { scope in
                    BeltScopeOption(
                        scope: scope,
                        isSelected: beltScope == scope,
                        onSelect: {
                            if !isDemo {
                                beltScope = scope
                            }
                        }
                    )
                }
            }
        }
        .opacity(isDemo ? 0.7 : 1.0)
    }
}

// MARK: - Belt Scope Option Card

private struct BeltScopeOption: View {
    let scope: TestUIConfig.BeltScope
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .secondary)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(scope.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("test-config-beltscope-\(scope.rawValue)")
        .accessibilityLabel(scope.displayName)
        .accessibilityHint(scope.description)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Preview

#Preview("Interactive") {
    VStack(spacing: 32) {
        Text("Interactive Mode")
            .font(.headline)

        BeltScopeToggle(
            beltScope: .constant(.currentOnly)
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

        BeltScopeToggle(
            beltScope: .constant(.allUpToCurrent),
            isDemo: true
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}

#Preview("All Selected") {
    VStack(spacing: 32) {
        Text("All Belts Up to Current")
            .font(.headline)

        BeltScopeToggle(
            beltScope: .constant(.allUpToCurrent)
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    .padding()
}
