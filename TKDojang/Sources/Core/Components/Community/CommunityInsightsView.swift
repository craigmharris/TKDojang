import SwiftUI

/**
 * CommunityInsightsView.swift
 *
 * PURPOSE: Display aggregate community demographics and engagement
 *
 * FEATURES:
 * - Belt level distribution across community
 * - Learning mode preferences (Progression vs Mastery)
 * - Most requested features
 * - Community size and growth
 *
 * DESIGN DECISIONS:
 * - Anonymous aggregation via CloudKit queries
 * - No individual user data exposed
 * - Visual charts for quick insights
 * - Privacy-preserving analytics
 *
 * NOTE: This view shows aggregate statistics from optional demographic data
 * that users chose to share when submitting feedback
 */

struct CommunityInsightsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var totalFeedbackCount: Int = 0
    @State private var beltDistribution: [String: Int] = [:]
    @State private var learningModeDistribution: [String: Int] = [:]
    @State private var topFeatureRequests: [String: Int] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else {
                    insightsListView
                }
            }
            .navigationTitle("Community Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadInsights()
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Analyzing community data...")
                .foregroundStyle(.secondary)
        }
    }

    private var insightsListView: some View {
        List {
            // Overview Section
            overviewSection

            // Belt Distribution
            if !beltDistribution.isEmpty {
                beltDistributionSection
            }

            // Learning Mode Preferences
            if !learningModeDistribution.isEmpty {
                learningModeSection
            }

            // Top Feature Requests
            if !topFeatureRequests.isEmpty {
                topRequestsSection
            }

            // Privacy Notice
            privacyNoticeSection
        }
        .listStyle(.insetGrouped)
    }

    private var overviewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading) {
                        Text("Community Feedback")
                            .font(.headline)

                        Text("\(totalFeedbackCount) submissions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Insights based on anonymous data shared by users who opted in when submitting feedback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var beltDistributionSection: some View {
        Section {
            ForEach(beltDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { belt, count in
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(beltColor(for: belt))
                            .frame(width: 12, height: 12)

                        Text(belt)
                            .font(.body)
                    }

                    Spacer()

                    Text("\(count)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    // Progress bar
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(beltColor(for: belt).opacity(0.3))
                            .frame(width: progressWidth(count: count, total: totalFeedbackCount, maxWidth: 60))
                            .cornerRadius(4)
                    }
                    .frame(width: 60, height: 8)
                }
            }
        } header: {
            Text("Belt Level Distribution")
        } footer: {
            Text("Shows belt levels of users who shared demographic data")
                .font(.caption)
        }
    }

    private var learningModeSection: some View {
        Section {
            ForEach(learningModeDistribution.sorted(by: { $0.value > $1.value }), id: \.key) { mode, count in
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: mode == "Progression Mode" ? "arrow.up.circle.fill" : "brain.head.profile")
                            .foregroundStyle(.blue)

                        Text(mode)
                            .font(.body)
                    }

                    Spacer()

                    Text("\(count)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    // Progress bar
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: progressWidth(count: count, total: totalFeedbackCount, maxWidth: 60))
                            .cornerRadius(4)
                    }
                    .frame(width: 60, height: 8)
                }
            }
        } header: {
            Text("Learning Mode Preferences")
        } footer: {
            Text("How users prefer to learn")
                .font(.caption)
        }
    }

    private var topRequestsSection: some View {
        Section {
            ForEach(topFeatureRequests.sorted(by: { $0.value > $1.value }).prefix(5), id: \.key) { feature, count in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(feature)
                            .font(.body)

                        Text("\(count) request\(count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        } header: {
            Text("Top Feature Requests")
        } footer: {
            Text("Most mentioned features in feedback submissions")
                .font(.caption)
        }
    }

    private var privacyNoticeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundStyle(.blue)

                    Text("Privacy Preserving")
                        .font(.headline)
                }

                Text("All data is anonymous and aggregated. Individual users cannot be identified. Only users who opted in to share demographics when submitting feedback are included in these statistics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helpers

    private func progressWidth(count: Int, total: Int, maxWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        let percentage = CGFloat(count) / CGFloat(total)
        return maxWidth * percentage
    }

    private func beltColor(for belt: String) -> Color {
        // Simplified belt color mapping
        if belt.contains("10th") || belt.contains("9th") {
            return .white
        } else if belt.contains("8th") || belt.contains("7th") {
            return .yellow
        } else if belt.contains("6th") || belt.contains("5th") {
            return .green
        } else if belt.contains("4th") || belt.contains("3rd") {
            return .blue
        } else if belt.contains("2nd") || belt.contains("1st") {
            return .brown
        } else {
            return .black
        }
    }

    // MARK: - Data Loading

    private func loadInsights() async {
        isLoading = true

        // Simulate loading aggregate data
        // In production, this would use CloudKit aggregation queries
        // For now, we'll show placeholder data structure

        // Example of how CloudKit aggregation would work:
        // 1. Query all Feedback records with demographics
        // 2. Count occurrences of each belt level
        // 3. Count occurrences of each learning mode
        // 4. Parse feature requests from feedback text

        await Task.sleep(1_000_000_000) // 1 second delay for demo

        // Placeholder data (in production, this would come from CloudKit queries)
        totalFeedbackCount = 0 // Will be populated from actual feedback
        beltDistribution = [:] // Will be populated from CloudKit
        learningModeDistribution = [:] // Will be populated from CloudKit
        topFeatureRequests = [:] // Will be populated from feedback text analysis

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    CommunityInsightsView()
}
