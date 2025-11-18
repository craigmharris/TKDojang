import SwiftUI
import UIKit

/**
 * MyFeedbackView.swift
 *
 * PURPOSE: Display user's feedback history with developer responses
 *
 * FEATURES:
 * - List of all feedback submitted by user
 * - Developer responses shown inline
 * - Badge notification for unread responses
 * - Status indicators (Pending, Responded, Implemented)
 * - Pull-to-refresh for CloudKit sync
 *
 * DESIGN DECISIONS:
 * - Chronological order (most recent first)
 * - Expandable cards for full feedback text
 * - Color-coded status badges
 * - Automatic refresh on appear
 */

struct MyFeedbackView: View {
    @State private var feedbackService = CloudKitFeedbackService()
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage: String = ""

    /// Optional feedback ID to scroll to and highlight (from notification tap)
    var highlightFeedbackID: String? = nil

    var body: some View {
        NavigationStack {
            Group {
                if feedbackService.userFeedbackItems.isEmpty {
                    emptyStateView
                } else {
                    feedbackListView
                }
            }
            .navigationTitle("My Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await loadFeedback()
            }
            .task {
                await loadFeedback()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Views

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Feedback Yet", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Your feedback submissions will appear here. Tap the feedback button to share your thoughts.")
        }
    }

    private var feedbackListView: some View {
        ScrollViewReader { proxy in
            List {
                if feedbackService.unreadResponseCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.orange)
                            Text("\(feedbackService.unreadResponseCount) new response\(feedbackService.unreadResponseCount == 1 ? "" : "s")")
                                .fontWeight(.semibold)
                        }
                    }
                }

                ForEach(feedbackService.userFeedbackItems) { item in
                    FeedbackItemRow(
                        item: item,
                        isHighlighted: highlightFeedbackID == item.id
                    ) {
                        feedbackService.markResponseAsRead(feedbackID: item.id)
                        // Update badge count when response is read
                        updateBadgeCount()
                    }
                    .id(item.id) // For ScrollViewReader
                }
            }
            .listStyle(.insetGrouped)
            .onAppear {
                // Scroll to highlighted feedback if specified
                if let highlightID = highlightFeedbackID {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(highlightID, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func updateBadgeCount() {
        Task { @MainActor in
            // Set badge to number of unread responses
            UIApplication.shared.applicationIconBadgeNumber = feedbackService.unreadResponseCount
        }
    }

    private func loadFeedback() async {
        isLoading = true
        do {
            try await feedbackService.fetchUserFeedback()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = CloudKitErrorHandler.userFriendlyMessage(for: error)
            showingError = true
        }
    }
}

// MARK: - Feedback Item Row

struct FeedbackItemRow: View {
    let item: FeedbackItem
    let isHighlighted: Bool
    let onRead: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label(item.category.rawValue, systemImage: item.category.icon)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                statusBadge
            }

            // Feedback Text
            Text(item.text)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)

            // Show More/Less
            if item.text.count > 150 {
                Button(isExpanded ? "Show Less" : "Show More") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }

            // Timestamp
            Text(item.timestamp, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Developer Response
            if let response = item.developerResponse {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundStyle(.blue)
                        Text("Developer Response")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        if let responseTimestamp = item.responseTimestamp {
                            Text(responseTimestamp, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(response)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let targetVersion = item.targetVersion {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundStyle(.green)
                            Text("Planned for \(targetVersion)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onAppear {
                    onRead()
                }
            }
        }
        .padding(.vertical, 8)
        .background(isHighlighted ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
    }

    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(item.responseStatus.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }

    private var statusColor: Color {
        switch item.responseStatus {
        case .pending:
            return .orange
        case .responded:
            return .blue
        case .implemented:
            return .green
        }
    }
}

// MARK: - Preview

#Preview {
    MyFeedbackView()
}
