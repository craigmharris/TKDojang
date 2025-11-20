import SwiftUI

/**
 * CommunityHubStepView.swift
 *
 * PURPOSE: Introduce the Community Hub during onboarding
 *
 * STEP 5 of 7 in initial tour (new step before final screen)
 *
 * WHY: Users should know they can:
 * - Submit feedback and bug reports
 * - Vote on feature roadmap
 * - See community insights
 * - Track their submitted feedback
 *
 * DESIGN DECISIONS:
 * - Uses reusable CommunityOptionCard components in demo mode
 * - Shows the actual community options they'll see in the app
 * - Emphasizes collaborative development approach
 */

struct CommunityHubStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("Community Hub")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Shape the future of TKDojang together")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)

                // Community Options (Demo Mode)
                VStack(alignment: .leading, spacing: 16) {
                    Text("What You Can Do")
                        .font(.headline)
                        .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        CommunityOptionCard(
                            icon: "envelope.fill",
                            iconColor: .blue,
                            title: "Send Feedback",
                            subtitle: "Report bugs or share ideas",
                            isDemo: true
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))

                        Divider()
                            .padding(.leading, 56)

                        CommunityOptionCard(
                            icon: "tray.fill",
                            iconColor: .purple,
                            title: "My Feedback",
                            subtitle: "View your submissions and responses",
                            isDemo: true
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))

                        Divider()
                            .padding(.leading, 56)

                        CommunityOptionCard(
                            icon: "map.fill",
                            iconColor: .green,
                            title: "Feature Roadmap",
                            subtitle: "Vote on upcoming features",
                            isDemo: true
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))

                        Divider()
                            .padding(.leading, 56)

                        CommunityOptionCard(
                            icon: "chart.bar.fill",
                            iconColor: .orange,
                            title: "Community Insights",
                            subtitle: "See what the community is learning",
                            isDemo: true
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                    }
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }

                // Explanation
                VStack(spacing: 16) {
                    FeatureHighlight(
                        icon: "megaphone.fill",
                        iconColor: .blue,
                        title: "Your Voice Matters",
                        description: "Submit feedback, report bugs, and suggest new features. I read every submission!"
                    )

                    FeatureHighlight(
                        icon: "hand.thumbsup.fill",
                        iconColor: .green,
                        title: "Vote on Features",
                        description: "Help prioritise development by voting on the roadmap. Popular features get built first."
                    )

                    FeatureHighlight(
                        icon: "bell.badge.fill",
                        iconColor: .red,
                        title: "Get Responses",
                        description: "When I respond to your feedback, you'll get a notification. It's a two-way conversation!"
                    )
                }
                .padding(.horizontal, 24)

                // Access info
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                        Text("Access Community Hub from the")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Profile tab")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 24)
                    .multilineTextAlignment(.center)
                }

                Spacer(minLength: 40)

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
}

// MARK: - Supporting View

struct FeatureHighlight: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CommunityHubStepView()
}
