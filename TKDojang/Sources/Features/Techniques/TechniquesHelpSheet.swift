import SwiftUI

/**
 * TechniquesHelpSheet.swift
 *
 * PURPOSE: Simple explanation overlay for Techniques reference system
 *
 * WHY: Techniques is a searchable reference - doesn't need multi-step walkthrough
 * APPROACH: Single overlay with key features explained
 */

struct TechniquesHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Technique Reference")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Comprehensive searchable reference for all ITF Taekwondo techniques")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Content Sections
                    helpSection(
                        icon: "magnifyingglass",
                        title: "Search Functionality",
                        description: "Quickly find techniques using the search bar. Search works across all technique properties including names, Korean terms, and descriptions.",
                        tips: [
                            "Type any keyword to search (e.g., 'kick', 'punch', 'ap')",
                            "Search finds matches in English and Korean names",
                            "Clear search to browse all techniques again",
                            "Combine search with filters for precise results"
                        ]
                    )

                    helpSection(
                        icon: "square.grid.2x2.fill",
                        title: "Category Browsing",
                        description: "Techniques are organised into logical categories for easy exploration:",
                        tips: [
                            "Blocks: Defensive movements (makgi)",
                            "Kicks: All kicking techniques (chagi)",
                            "Punches & Strikes: Hand techniques (jirugi, taerigi)",
                            "Stances: Foundational positions (sogi)",
                            "Plus specialised categories like throws and dodges"
                        ]
                    )

                    helpSection(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "Advanced Filtering",
                        description: "Use filters to refine your technique search by multiple dimensions:",
                        tips: [
                            "Belt Level: See techniques required for specific belts",
                            "Difficulty: Filter by beginner, intermediate, or advanced",
                            "Tags: Find techniques by characteristics (aerial, spinning, etc.)",
                            "Combine multiple filters for precise results"
                        ]
                    )

                    helpSection(
                        icon: "info.circle.fill",
                        title: "Technique Details",
                        description: "Tap any technique card to view comprehensive information:",
                        tips: [
                            "Detailed execution instructions step-by-step",
                            "Korean terminology with romanisation",
                            "Belt level requirements and difficulty ratings",
                            "Target areas and typical applications",
                            "Related techniques and variations"
                        ]
                    )

                    // Quick Tips
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text("Quick Tips")
                                .font(.headline)
                        }

                        tipRow("Use search when you know what you're looking for")
                        tipRow("Browse categories to discover new techniques")
                        tipRow("Filter by your belt level to focus on current requirements")
                        tipRow("This is a reference tool - complement with hands-on practice")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Techniques Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func helpSection(icon: String, title: String, description: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 32)

                Text(title)
                    .font(.headline)
            }

            Text(description)
                .font(.body)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    TechniquesHelpSheet()
}
