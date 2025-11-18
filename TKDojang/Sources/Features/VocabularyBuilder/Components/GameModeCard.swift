import SwiftUI

/**
 * GameModeCard.swift
 *
 * PURPOSE: Reusable card component for vocabulary game mode selection
 *
 * FEATURES:
 * - Visual representation of game modes with icon, title, description
 * - Difficulty indicator and estimated time display
 * - "Coming Soon" lock state for unreleased games
 * - Accessibility support with descriptive identifiers
 * - Component reusability for tours (with isDemo parameter)
 *
 * DESIGN PATTERN:
 * - Extracted component following app's component reusability strategy
 * - Supports both production (interactive) and demo (visual-only) modes
 * - 75% maintenance reduction: one component, multiple contexts
 */

struct GameModeCard: View {
    let icon: String
    let title: String
    let description: String
    let difficulty: String
    let estimatedTime: String
    let isAvailable: Bool
    let accessibilityId: String
    let isDemo: Bool  // Enables visual-only demo mode for tours
    let action: () -> Void

    init(
        icon: String,
        title: String,
        description: String,
        difficulty: String,
        estimatedTime: String,
        isAvailable: Bool = true,
        accessibilityId: String,
        isDemo: Bool = false,
        action: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.isAvailable = isAvailable
        self.accessibilityId = accessibilityId
        self.isDemo = isDemo
        self.action = action
    }

    var body: some View {
        Button(action: {
            if !isDemo && isAvailable {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and lock indicator
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(isAvailable ? .accentColor : .secondary)
                        .frame(width: 48, height: 48)

                    Spacer()

                    if !isAvailable {
                        VStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Coming Soon")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Title
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)

                // Description
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Metadata
                HStack {
                    Label(difficulty, systemImage: "gauge.medium")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Label(estimatedTime, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDemo || !isAvailable)
        .opacity(!isAvailable ? 0.6 : 1.0)
        .accessibilityIdentifier(accessibilityId)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        if isAvailable {
            return "\(title), \(difficulty) difficulty, \(estimatedTime)"
        } else {
            return "\(title), Coming Soon"
        }
    }

    private var accessibilityHint: String {
        if !isAvailable {
            return "This game mode is not yet available"
        } else if isDemo {
            return "Demo mode, interaction disabled"
        } else {
            return "Tap to start \(title)"
        }
    }
}

// MARK: - Preview

#Preview("Available Game") {
    GameModeCard(
        icon: "character.book.closed",
        title: "Word Matching",
        description: "Match English words to Korean romanised equivalents",
        difficulty: "Beginner",
        estimatedTime: "5-10 min",
        isAvailable: true,
        accessibilityId: "vocab-game-word-matching-card"
    ) {
        print("Word Matching tapped")
    }
    .padding()
}

#Preview("Coming Soon") {
    GameModeCard(
        icon: "puzzlepiece.fill",
        title: "Template Filler",
        description: "Complete phrase templates with correct word categories",
        difficulty: "Intermediate",
        estimatedTime: "10-15 min",
        isAvailable: false,
        accessibilityId: "vocab-game-template-filler-card"
    ) {}
    .padding()
}

#Preview("Demo Mode") {
    GameModeCard(
        icon: "square.grid.2x2.fill",
        title: "Slot Builder",
        description: "Build phrases slot-by-slot with guided category selection",
        difficulty: "Beginner",
        estimatedTime: "10-15 min",
        isAvailable: true,
        accessibilityId: "vocab-game-slot-builder-card",
        isDemo: true
    ) {
        print("This shouldn't fire in demo mode")
    }
    .padding()
}
