import SwiftUI

/**
 * AboutCommunityHubView.swift
 *
 * PURPOSE: Redesigned About page serving as Community Hub
 *
 * FEATURES:
 * - Community section (Feedback, Roadmap, Suggestions, Insights)
 * - App Information section (version, credits, privacy)
 * - Notification badges for unread developer responses
 * - Navigation to all community features
 *
 * DESIGN DECISIONS:
 * - Two-section design: Community engagement + App info
 * - Visual prominence for community features
 * - Badge notifications for developer responses
 * - Quick access to What's New
 */

struct AboutCommunityHubView: View {
    @State private var feedbackService = CloudKitFeedbackService()
    @State private var showingFeedback = false
    @State private var showingMyFeedback = false
    @State private var showingRoadmap = false
    @State private var showingWhatsNew = false
    @State private var showingInsights = false

    var userProfile: UserProfile?

    var body: some View {
        NavigationStack {
            List {
                // Community Section
                communitySection

                // App Information Section
                appInfoSection
            }
            .navigationTitle("Community Hub")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Load unread response count for badge
                try? await feedbackService.fetchUserFeedback()
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackView(userProfile: userProfile)
            }
            .sheet(isPresented: $showingMyFeedback) {
                MyFeedbackView()
            }
            .sheet(isPresented: $showingRoadmap) {
                RoadmapView()
            }
            .sheet(isPresented: $showingWhatsNew) {
                WhatsNewView()
            }
            .sheet(isPresented: $showingInsights) {
                CommunityInsightsView()
            }
        }
    }

    // MARK: - Community Section

    private var communitySection: some View {
        Section {
            // Send Feedback
            Button {
                showingFeedback = true
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Send Feedback")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Report bugs or share ideas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

            // My Feedback
            Button {
                showingMyFeedback = true
            } label: {
                HStack {
                    Image(systemName: "tray.fill")
                        .foregroundStyle(.purple)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Feedback")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("View your submissions and responses")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Badge for unread responses
                    if feedbackService.unreadResponseCount > 0 {
                        Text("\(feedbackService.unreadResponseCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(10)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Feature Roadmap
            Button {
                showingRoadmap = true
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(.green)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Feature Roadmap")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Vote on upcoming features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Community Insights
            Button {
                showingInsights = true
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community Insights")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("See what the community is learning")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

        } header: {
            Text("Community")
        } footer: {
            Text("Help shape TKDojang's future and connect with other learners")
                .font(.caption)
        }
    }

    // MARK: - App Information Section

    private var appInfoSection: some View {
        Section {
            // What's New
            Button {
                showingWhatsNew = true
            } label: {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("What's New")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Version \(appVersion) release notes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if WhatsNewView.shouldShow() {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Version Info
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Version")
                        .font(.body)
                        .fontWeight(.medium)

                    Text("\(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Developer Info & Contact
            Link(destination: URL(string: "https://github.com/craigmharris/TKDojang")!) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Developer")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("Craig Matthew Harris")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Privacy Link
            Link(destination: URL(string: "https://tkdojang.app/privacy")!) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Privacy Policy")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)

                        Text("How we protect your data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.secondary)
                }
            }

            // Acknowledgments
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Made with ❤️")
                            .font(.body)
                            .fontWeight(.medium)

                        Text("For Taekwondo students everywhere, but above all, for Cath, Rob, Anna, Danielle, Caitlin, and Aneurin. You rock!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Additional Credit ❤️")
                            .font(.body)
                            .fontWeight(.medium)

                        Text("Supporting this build has been my partner Cath with long nights of testing and flawless advice on how to optimise for different learning styles, my instructor Adam, who has been happy to share advice and content, and Dan whose invaluable advice on GenAI made the process significantly safer and faster. Thanks to Cath and the kids for putting up with many nights of me tapping on the laptop, and thanks to Loki for needing enough walks to drag me away from it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

// MARK: - Preview

#Preview {
    AboutCommunityHubView()
}
