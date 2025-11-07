import SwiftUI

/**
 * PatternsHelpSheet.swift
 *
 * PURPOSE: Simple explanation overlay for Pattern selection interface
 *
 * WHY: Users need to understand how to select patterns and what content is visible
 * APPROACH: Single overlay explaining selection, belt levels, and learning mode filtering
 */

struct PatternsHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Pattern Selection")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Choose traditional Taekwondo patterns for practice and testing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Content Sections
                    helpSection(
                        icon: "hand.tap.fill",
                        title: "Selecting a Pattern",
                        description: "Browse available patterns and tap any card to view details and start practice:",
                        tips: [
                            "Each pattern card shows the name, Korean name, and meaning",
                            "Move count badge indicates pattern complexity",
                            "Pattern diagram provides a visual reference",
                            "Progress indicator shows your practice history (if started)",
                            "Belt level badges show which belts require this pattern"
                        ]
                    )

                    helpSection(
                        icon: "graduationcap.fill",
                        title: "Learning Modes",
                        description: "Your learning mode determines which patterns are visible:",
                        tips: [
                            "Progression mode: Shows only patterns for your next belt level",
                            "Mastery mode: Shows all patterns up to and including your next belt",
                            "Patterns are essential grading requirements for each belt",
                            "Change learning mode in your profile settings"
                        ]
                    )

                    helpSection(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Tracking",
                        description: "Track your practice progress for each pattern:",
                        tips: [
                            "Progress percentage shows how much you've practiced",
                            "Mastery levels: Learning → Familiar → Proficient → Mastered",
                            "Belt-themed progress bars match the pattern's belt level",
                            "Completed patterns display in green",
                            "Progress is tracked per profile for family sharing"
                        ]
                    )

                    helpSection(
                        icon: "info.circle.fill",
                        title: "Pattern Information",
                        description: "Each pattern provides comprehensive learning content:",
                        tips: [
                            "Historical significance and meaning",
                            "Complete move-by-move breakdown",
                            "Korean terminology with Hangul and romanization",
                            "Visual pattern diagram showing movement flow",
                            "Practice guidance and common mistakes"
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

                        tipRow("Start with patterns for your current belt level")
                        tipRow("Review pattern details before beginning practice")
                        tipRow("Use Mastery mode to refresh previously learned patterns")
                        tipRow("Patterns are required knowledge for belt grading")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Pattern Selection Help")
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
    PatternsHelpSheet()
}
