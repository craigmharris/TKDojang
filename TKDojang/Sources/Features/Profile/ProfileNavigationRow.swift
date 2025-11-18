import SwiftUI

/**
 * ProfileNavigationRow.swift
 *
 * PURPOSE: Reusable navigation row component for Profile screen
 *
 * DESIGN DECISIONS:
 * - Consistent iOS-native List style across all Profile navigation
 * - Icon + title + optional subtitle pattern
 * - Optional badge for notifications/counts
 * - Chevron for navigation affordance
 *
 * WHY: Provides visual consistency and reduces code duplication while
 * maintaining a clean, minimalistic interface that users understand intuitively
 */

struct ProfileNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let badge: Int?
    let action: () -> Void

    init(
        icon: String,
        iconColor: Color = .blue,
        title: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)
                    .font(.system(size: 18, weight: .medium))

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Badge (if present)
                if let badgeCount = badge, badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .clipShape(Capsule())
                }

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - NavigationLink Variant

/**
 * ProfileNavigationLink: NavigationLink wrapper for ProfileNavigationRow
 *
 * WHY: Allows direct NavigationLink usage while maintaining consistent styling
 */
struct ProfileNavigationLink<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let badge: Int?
    let destination: Destination

    init(
        icon: String,
        iconColor: Color = .blue,
        title: String,
        subtitle: String? = nil,
        badge: Int? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.destination = destination()
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 28, alignment: .center)
                    .font(.system(size: 18, weight: .medium))

                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Badge (if present)
                if let badgeCount = badge, badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        List {
            Section("Example Rows") {
                ProfileNavigationRow(
                    icon: "gearshape.fill",
                    iconColor: .blue,
                    title: "Settings",
                    subtitle: "Manage your preferences"
                ) {}

                ProfileNavigationRow(
                    icon: "envelope.fill",
                    iconColor: .green,
                    title: "Feedback",
                    subtitle: "Share your thoughts",
                    badge: 3
                ) {}

                ProfileNavigationLink(
                    icon: "info.circle.fill",
                    iconColor: .orange,
                    title: "About",
                    subtitle: "App information"
                ) {
                    Text("About View")
                }
            }
        }
        .navigationTitle("Profile")
    }
}
