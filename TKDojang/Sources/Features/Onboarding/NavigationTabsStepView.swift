import SwiftUI

/**
 * NavigationTabsStepView.swift
 *
 * PURPOSE: Third step of onboarding - introduce main navigation tabs
 *
 * STEP 3 of 6 in initial tour
 *
 * WHY: Users need to understand the app's primary navigation structure
 * before they can effectively use features
 */

struct NavigationTabsStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text("Navigate TKDojang")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Three main sections to explore")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Tab Explanations
            VStack(spacing: 20) {
                NavigationTabCard(
                    icon: "book.fill",
                    title: "Learn",
                    description: "Theory, techniques, and belt requirements",
                    color: .green
                )

                NavigationTabCard(
                    icon: "play.circle.fill",
                    title: "Practice",
                    description: "Flashcards, patterns, step sparring, and testing",
                    color: .blue
                )

                NavigationTabCard(
                    icon: "chart.bar.fill",
                    title: "Progress",
                    description: "Track progress and view stats",
                    color: .purple
                )

                NavigationTabCard(
                    icon: "person.circle.fill",
                    title: "Profile",
                    description: "Manage your profile(s) and access community features like roadmap, suggestions, and feedback",
                    color: .orange
                )
            }
            .padding(.horizontal)

            Spacer()

            // Swipe hint
            VStack(spacing: 8) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue.opacity(0.5))
                Text("Swipe to continue")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Supporting View

struct NavigationTabCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct NavigationTabsStepView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationTabsStepView()
    }
}
