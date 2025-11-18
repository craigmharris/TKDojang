import SwiftUI

/**
 * RoadmapView.swift
 *
 * PURPOSE: Display development roadmap with community voting
 *
 * FEATURES:
 * - 9 priority roadmap items (developer-curated)
 * - Real-time vote counts from CloudKit
 * - One vote per user per item (double-vote prevention)
 * - Status tracking (Planned, InProgress, Released)
 * - Separate section for user feature suggestions
 *
 * DESIGN DECISIONS:
 * - Priority order determined by developer (not vote sorting)
 * - Anonymous voting via CloudKit user IDs
 * - Visual indicators for items user has voted for
 * - Pull-to-refresh for latest vote counts
 * - Links to feature suggestion submission
 */

struct RoadmapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var roadmapService = CloudKitRoadmapService()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    @State private var showingSuggestions = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && roadmapService.roadmapItems.isEmpty {
                    loadingView
                } else {
                    roadmapListView
                }
            }
            .navigationTitle("Feature Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await loadRoadmap()
            }
            .task {
                await loadRoadmap()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSuggestions) {
                FeatureSuggestionView()
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading roadmap...")
                .foregroundStyle(.secondary)
        }
    }

    private var roadmapListView: some View {
        List {
            // Header Section
            headerSection

            // Planned Items (sorted by priority)
            if !roadmapService.plannedItems.isEmpty {
                Section {
                    ForEach(roadmapService.itemsByPriority.filter { $0.status == .planned }) { item in
                        RoadmapItemRow(
                            item: item,
                            hasVoted: roadmapService.hasUserVoted(itemID: item.id)
                        ) {
                            await voteForItem(item)
                        }
                    }
                } header: {
                    Text("Coming Soon")
                        .font(.headline)
                }
            }

            // In Progress Items
            if !roadmapService.inProgressItems.isEmpty {
                Section {
                    ForEach(roadmapService.inProgressItems) { item in
                        RoadmapItemRow(
                            item: item,
                            hasVoted: roadmapService.hasUserVoted(itemID: item.id),
                            showProgress: true
                        ) {
                            await voteForItem(item)
                        }
                    }
                } header: {
                    Text("In Development")
                        .font(.headline)
                }
            }

            // Recently Released
            if !roadmapService.recentlyReleasedItems.isEmpty {
                Section {
                    ForEach(roadmapService.recentlyReleasedItems) { item in
                        RoadmapItemRow(item: item, hasVoted: false, isReleased: true)
                    }
                } header: {
                    Text("Recently Added")
                        .font(.headline)
                }
            }

            // Feature Suggestions Link
            featureSuggestionsSection
        }
        .listStyle(.insetGrouped)
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "map")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    Text("What We're Building")
                        .font(.headline)
                }

                Text("Vote on features you want most. Your votes help us prioritize development.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    legendItem(icon: "circle", color: .orange, text: "Planned")
                    legendItem(icon: "hammer", color: .blue, text: "In Progress")
                    legendItem(icon: "checkmark.circle.fill", color: .green, text: "Released")
                }
                .font(.caption)
            }
            .padding(.vertical, 8)
        }
    }

    private var featureSuggestionsSection: some View {
        Section {
            Button {
                showingSuggestions = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Suggest a Feature", systemImage: "lightbulb")
                            .font(.body)
                            .fontWeight(.medium)

                        Text("Don't see your idea? Submit a suggestion")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Community suggestions are reviewed periodically and may be added to the official roadmap.")
                .font(.caption)
        }
    }

    private func legendItem(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(text)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func loadRoadmap() async {
        isLoading = true
        do {
            try await roadmapService.fetchRoadmapItems()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = CloudKitErrorHandler.userFriendlyMessage(for: error)
            showingError = true
        }
    }

    private func voteForItem(_ item: RoadmapItem) async {
        do {
            try await roadmapService.voteForItem(itemID: item.id)
        } catch {
            errorMessage = CloudKitErrorHandler.userFriendlyMessage(for: error)
            showingError = true
        }
    }
}

// MARK: - Roadmap Item Row

struct RoadmapItemRow: View {
    let item: RoadmapItem
    let hasVoted: Bool
    var showProgress: Bool = false
    var isReleased: Bool = false
    var onVote: (() async -> Void)?

    @State private var isVoting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        categoryBadge

                        if item.isNew {
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .cornerRadius(4)
                        }
                    }

                    Text(item.title)
                        .font(.headline)

                    Text(item.estimatedRelease)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !isReleased {
                    voteButton
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }

            // Description
            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Progress Bar (for InProgress items)
            if showProgress, let progress = item.completionPercentage {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(height: 4)

                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * progress, height: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .opacity(isVoting ? 0.5 : 1.0)
    }

    private var categoryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.category.icon)
            Text(item.category.rawValue)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.blue)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    private var voteButton: some View {
        Button {
            guard let onVote = onVote else { return }
            Task {
                isVoting = true
                await onVote()
                isVoting = false
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: hasVoted ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .font(.body)

                Text("\(item.voteCount)")
                    .font(.callout)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(hasVoted ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(hasVoted ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .disabled(hasVoted || isVoting)
    }
}

// MARK: - Preview

#Preview {
    RoadmapView()
}
