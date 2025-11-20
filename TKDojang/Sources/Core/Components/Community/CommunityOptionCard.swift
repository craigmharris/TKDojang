import SwiftUI

/**
 * CommunityOptionCard.swift
 *
 * PURPOSE: Reusable component for community feature options
 *
 * DESIGN DECISIONS:
 * - Extracted from AboutCommunityHubView for reusability in onboarding tours
 * - Supports both interactive (button) and demo (display-only) modes
 * - Consistent styling with proper accessibility
 */

struct CommunityOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badgeCount: Int?
    let isDemo: Bool
    let action: (() -> Void)?

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        badgeCount: Int? = nil,
        isDemo: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badgeCount = badgeCount
        self.isDemo = isDemo
        self.action = action
    }

    var body: some View {
        if isDemo {
            // Demo mode - display only, no interaction
            cardContent
                .opacity(1.0)
        } else {
            // Interactive mode - button with action
            Button(action: { action?() }) {
                cardContent
            }
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Badge for unread count (if applicable)
            if let count = badgeCount, count > 0 {
                Text("\(count)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(10)
                    .accessibilityLabel("\(count) unread")
            }

            if !isDemo {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)")
        .accessibilityHint(isDemo ? "" : "Double-tap to open")
    }
}

// MARK: - Preview

#Preview("Interactive Mode") {
    List {
        CommunityOptionCard(
            icon: "envelope.fill",
            iconColor: .blue,
            title: "Send Feedback",
            subtitle: "Report bugs or share ideas",
            isDemo: false,
            action: { print("Feedback tapped") }
        )

        CommunityOptionCard(
            icon: "tray.fill",
            iconColor: .purple,
            title: "My Feedback",
            subtitle: "View your submissions and responses",
            badgeCount: 3,
            isDemo: false,
            action: { print("My Feedback tapped") }
        )
    }
}

#Preview("Demo Mode") {
    VStack(spacing: 16) {
        CommunityOptionCard(
            icon: "envelope.fill",
            iconColor: .blue,
            title: "Send Feedback",
            subtitle: "Report bugs or share ideas",
            isDemo: true
        )

        CommunityOptionCard(
            icon: "map.fill",
            iconColor: .green,
            title: "Feature Roadmap",
            subtitle: "Vote on upcoming features",
            isDemo: true
        )
    }
    .padding()
}
