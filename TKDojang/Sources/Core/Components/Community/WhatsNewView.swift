import SwiftUI

/**
 * WhatsNewView.swift
 *
 * PURPOSE: Display version history and release notes
 *
 * FEATURES:
 * - Changelog for each version
 * - Auto-show on first launch after update
 * - Archive of all previous releases
 * - Highlights user-requested features that were implemented
 *
 * DESIGN DECISIONS:
 * - Chronological order (newest first)
 * - Categorized updates (New, Improved, Fixed)
 * - Acknowledgment of user feedback
 * - Version-gated display via UserDefaults
 */

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    headerView

                    // v1.0 Release Notes
                    ReleaseSection(
                        version: "1.0",
                        date: "November 2025",
                        title: "Foundation Edition Launch 🎉",
                        icon: "sparkles",
                        accentColor: .blue,
                        items: [
                            ReleaseItem(
                                category: .new,
                                icon: "gamecontroller.fill",
                                title: "6 Interactive Vocabulary Games",
                                description: "Word Match, Slot Builder, Template Filler, Phrase Decoder, Memory Match, Creative Sandbox"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "figure.martial.arts",
                                title: "11 Traditional Patterns",
                                description: "Chon-Ji through Choong-Moo with step-by-step diagrams and Korean terminology"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "person.3.fill",
                                title: "Multi-Profile Family Learning",
                                description: "6 device-local profiles with complete data isolation and individual progress tracking"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "brain.head.profile",
                                title: "Leitner Spaced Repetition",
                                description: "Scientifically-proven flashcard system for optimal retention"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "map",
                                title: "Community Roadmap & Voting",
                                description: "Vote on upcoming features and help shape TKDojang's future"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "bubble.left.and.bubble.right",
                                title: "Feedback System",
                                description: "Submit feedback and get notified when developers respond"
                            ),
                            ReleaseItem(
                                category: .new,
                                icon: "wifi.slash",
                                title: "Complete Offline Support",
                                description: "All content stored locally - no internet required after download"
                            )
                        ]
                    )

                    // Future versions will be added here
                }
                .padding()
            }
            .navigationTitle("What's New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        markVersionAsSeen()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            markVersionAsSeen()
        }
    }

    // MARK: - Views

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading) {
                    Text("Welcome to TKDojang")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Version \(currentVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Your complete digital Taekwondo companion")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical)
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    // MARK: - Actions

    private func markVersionAsSeen() {
        lastSeenVersion = currentVersion
    }

    // MARK: - Helper to Check if Should Show

    static func shouldShow() -> Bool {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let lastSeen = UserDefaults.standard.string(forKey: "lastSeenVersion") ?? ""
        return currentVersion != lastSeen
    }
}

// MARK: - Release Section

struct ReleaseSection: View {
    let version: String
    let date: String
    let title: String
    let icon: String
    let accentColor: Color
    let items: [ReleaseItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Version \(version)")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(accentColor)

            Divider()

            // Items grouped by category
            let newItems = items.filter { $0.category == .new }
            let improvedItems = items.filter { $0.category == .improved }
            let fixedItems = items.filter { $0.category == .fixed }

            if !newItems.isEmpty {
                CategoryGroup(category: .new, items: newItems)
            }

            if !improvedItems.isEmpty {
                CategoryGroup(category: .improved, items: improvedItems)
            }

            if !fixedItems.isEmpty {
                CategoryGroup(category: .fixed, items: fixedItems)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

// MARK: - Category Group

struct CategoryGroup: View {
    let category: ReleaseCategory
    let items: [ReleaseItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .foregroundStyle(category.color)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(category.color)
            }

            ForEach(items) { item in
                ReleaseItemRow(item: item)
            }
        }
    }
}

// MARK: - Release Item Row

struct ReleaseItemRow: View {
    let item: ReleaseItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.icon)
                .font(.title3)
                .foregroundStyle(item.category.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.body)
                    .fontWeight(.semibold)

                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let userRequested = item.userRequested, userRequested {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Community Requested")
                    }
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                    .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

enum ReleaseCategory {
    case new
    case improved
    case fixed

    var displayName: String {
        switch self {
        case .new: return "New"
        case .improved: return "Improved"
        case .fixed: return "Fixed"
        }
    }

    var icon: String {
        switch self {
        case .new: return "sparkles"
        case .improved: return "arrow.up.circle.fill"
        case .fixed: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .new: return .blue
        case .improved: return .green
        case .fixed: return .orange
        }
    }
}

struct ReleaseItem: Identifiable {
    let id = UUID()
    let category: ReleaseCategory
    let icon: String
    let title: String
    let description: String
    let userRequested: Bool?

    init(category: ReleaseCategory, icon: String, title: String, description: String, userRequested: Bool? = nil) {
        self.category = category
        self.icon = icon
        self.title = title
        self.description = description
        self.userRequested = userRequested
    }
}

// MARK: - Preview

#Preview {
    WhatsNewView()
}
