import SwiftUI

/**
 * FeatureSuggestionView.swift
 *
 * PURPOSE: Submit and browse community feature suggestions
 *
 * FEATURES:
 * - Submit new feature suggestions
 * - Browse community suggestions sorted by upvotes
 * - Upvote suggestions (one vote per user)
 * - Track user's own suggestions with status updates
 * - Notification when suggestion is promoted to roadmap
 *
 * DESIGN DECISIONS:
 * - Separate from official roadmap (user-submitted vs developer-curated)
 * - Anonymous submissions via CloudKit
 * - Community upvoting to surface popular ideas
 * - Status workflow: Pending → UnderReview → AddedToRoadmap/Declined
 */

struct FeatureSuggestionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var suggestionService = CloudKitSuggestionService()

    @State private var selectedTab: SuggestionTab = .community
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    @State private var showingSubmitForm = false

    enum SuggestionTab: String, CaseIterable {
        case community = "Community Ideas"
        case mySuggestions = "My Suggestions"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    ForEach(SuggestionTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Content
                Group {
                    switch selectedTab {
                    case .community:
                        communitySuggestionsView
                    case .mySuggestions:
                        mySuggestionsView
                    }
                }
            }
            .navigationTitle("Feature Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSubmitForm = true
                    } label: {
                        Label("Suggest", systemImage: "plus.circle.fill")
                    }
                }
            }
            .refreshable {
                await loadSuggestions()
            }
            .task {
                await loadSuggestions()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingSubmitForm) {
                SubmitSuggestionView(suggestionService: suggestionService)
            }
        }
    }

    // MARK: - Community Suggestions

    private var communitySuggestionsView: some View {
        Group {
            if suggestionService.communitySuggestions.isEmpty {
                communityEmptyStateView
            } else {
                List {
                    Section {
                        Text("Upvote suggestions you'd like to see. Top ideas may be added to the official roadmap.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(suggestionService.topSuggestions(limit: 50)) { suggestion in
                        SuggestionRow(
                            suggestion: suggestion,
                            hasUpvoted: suggestionService.hasUserUpvoted(suggestionID: suggestion.id)
                        ) {
                            await upvoteSuggestion(suggestion)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var communityEmptyStateView: some View {
        ContentUnavailableView {
            Label("No Suggestions Yet", systemImage: "lightbulb")
        } description: {
            Text("Be the first to suggest a feature!")
        }
    }

    // MARK: - My Suggestions

    private var mySuggestionsView: some View {
        Group {
            if suggestionService.userSuggestions.isEmpty {
                myEmptyStateView
            } else {
                List {
                    ForEach(suggestionService.userSuggestions) { suggestion in
                        MySuggestionRow(suggestion: suggestion)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var myEmptyStateView: some View {
        ContentUnavailableView {
            Label("No Suggestions Submitted", systemImage: "lightbulb.slash")
        } description: {
            Text("Tap the + button to suggest a feature")
        }
    }

    // MARK: - Actions

    private func loadSuggestions() async {
        isLoading = true
        do {
            async let community = suggestionService.fetchCommunitySuggestions()
            async let user = suggestionService.fetchUserSuggestions()
            try await (community, user)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to load suggestions: \(error.localizedDescription)"
            showingError = true
        }
    }

    private func upvoteSuggestion(_ suggestion: FeatureSuggestion) async {
        do {
            try await suggestionService.upvoteSuggestion(suggestionID: suggestion.id)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Suggestion Row

struct SuggestionRow: View {
    let suggestion: FeatureSuggestion
    let hasUpvoted: Bool
    var onUpvote: (() async -> Void)?

    @State private var isUpvoting = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.title)
                        .font(.headline)

                    Text(suggestion.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }

                Spacer()

                upvoteButton
            }

            // Show More/Less
            if suggestion.description.count > 100 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }

            // Footer
            HStack {
                Text(suggestion.submittedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if suggestion.isPromoted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Added to Roadmap")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .opacity(isUpvoting ? 0.5 : 1.0)
    }

    private var upvoteButton: some View {
        Button {
            guard let onUpvote = onUpvote else { return }
            Task {
                isUpvoting = true
                await onUpvote()
                isUpvoting = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: hasUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.title3)

                Text("\(suggestion.upvoteCount)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(hasUpvoted ? .green : .gray)
        }
        .disabled(hasUpvoted || isUpvoting)
    }
}

// MARK: - My Suggestion Row

struct MySuggestionRow: View {
    let suggestion: FeatureSuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(suggestion.title)
                    .font(.headline)

                Spacer()

                statusBadge
            }

            Text(suggestion.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label("\(suggestion.upvoteCount) upvotes", systemImage: "arrow.up.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(suggestion.submittedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if suggestion.isPromoted {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Your suggestion was added to the roadmap!")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: suggestion.status.icon)
            Text(suggestion.status.displayName)
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(Color(suggestion.status.color))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(suggestion.status.color).opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Submit Suggestion View

struct SubmitSuggestionView: View {
    @Environment(\.dismiss) private var dismiss
    let suggestionService: CloudKitSuggestionService

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var showingError = false
    @State private var errorMessage: String = ""

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Feature Title", text: $title)

                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Describe your feature idea in detail...")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("Your Idea")
                } footer: {
                    Text("Be specific! Explain what the feature should do and why it would be valuable.")
                        .font(.caption)
                }
            }
            .navigationTitle("Suggest Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            await submitSuggestion()
                        }
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isSubmitting)
        }
    }

    private func submitSuggestion() async {
        guard canSubmit else { return }

        isSubmitting = true

        do {
            _ = try await suggestionService.submitSuggestion(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            isSubmitting = false
            dismiss()

        } catch {
            isSubmitting = false
            errorMessage = "Failed to submit suggestion: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Preview

#Preview {
    FeatureSuggestionView()
}
