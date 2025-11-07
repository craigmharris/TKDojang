import SwiftUI

/**
 * TheoryHelpSheet.swift
 *
 * PURPOSE: Simple explanation overlay for Theory knowledge base
 *
 * WHY: Theory is straightforward browsing - doesn't need multi-step walkthrough
 * APPROACH: Single overlay with key features explained
 */

struct TheoryHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Theory Knowledge Base")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Comprehensive Taekwondo theory organized by belt level")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Content Sections
                    helpSection(
                        icon: "figure.martial.arts",
                        title: "Belt-Level Organization",
                        description: "Theory content is organized by belt level, ensuring you learn material appropriate for your current training stage.",
                        tips: [
                            "Progression mode shows only your current belt's theory",
                            "Mastery mode shows all theory up to and including your belt",
                            "Switch learning modes in your profile settings"
                        ]
                    )

                    helpSection(
                        icon: "list.bullet.rectangle",
                        title: "Content Categories",
                        description: "Theory covers essential Taekwondo knowledge including:",
                        tips: [
                            "Belt meanings and significance",
                            "Taekwondo tenets and philosophy",
                            "Korean terminology and culture",
                            "Grading requirements by belt level",
                            "TAGB organizational history"
                        ]
                    )

                    helpSection(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "Filtering & Navigation",
                        description: "Use filters to focus on specific content types or belt levels.",
                        tips: [
                            "Tap the filter icon to access belt and category filters",
                            "Category filters show only available content types",
                            "Belt filters let you review previous belt theory",
                            "Tap any theory card to read the full content"
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

                        tipRow("Review theory content regularly before grading")
                        tipRow("Use Mastery mode to refresh knowledge from previous belts")
                        tipRow("Theory complements physical practice - both are essential")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Theory Help")
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
    TheoryHelpSheet()
}
