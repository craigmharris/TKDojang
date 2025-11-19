import SwiftUI

/**
 * StepSparringHelpSheet.swift
 *
 * PURPOSE: Simple explanation overlay for Step Sparring selection interface
 *
 * WHY: Users need to understand how to select sparring types and what sequences are available
 * APPROACH: Single overlay explaining type selection, belt levels, and learning mode filtering
 */

struct StepSparringHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "figure.2.arms.open")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Step Sparring Selection")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Choose step sparring types to practise attack and defence combinations")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Content Sections
                    helpSection(
                        icon: "square.grid.2x2.fill",
                        title: "Sparring Types",
                        description: "Step sparring sequences are organised by type. Each tile shows available sequences for that category:",
                        tips: [
                            "3-Step Sparring: Three-move attack and defence sequences",
                            "2-Step Sparring: Two-move combinations for intermediate students",
                            "1-Step Sparring: Single-move exchanges for advanced students",
                            "Free Sparring: Unstructured practice for higher belt levels",
                            "Tap any type tile to view available sequences"
                        ]
                    )

                    helpSection(
                        icon: "hand.tap.fill",
                        title: "Selecting Sequences",
                        description: "Browse and select specific sparring sequences to practice:",
                        tips: [
                            "Each type tile shows the number of available sequences",
                            "Sequences are filtered by your belt level",
                            "Tap a type to see detailed sequence list",
                            "Sequence cards show attack, defence, and counter moves",
                            "Progress indicators track your practice history"
                        ]
                    )

                    helpSection(
                        icon: "graduationcap.fill",
                        title: "Learning Modes",
                        description: "Your learning mode determines which sequences are visible:",
                        tips: [
                            "Progression mode: Shows only sequences for your next belt level",
                            "Mastery mode: Shows all sequences up to and including your next belt",
                            "Step sparring is essential grading content for each belt",
                            "Change learning mode in your profile settings"
                        ]
                    )

                    helpSection(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Progress Tracking",
                        description: "Track your step sparring practice progress:",
                        tips: [
                            "Overall progress shows completion across all sequences",
                            "Mastered count indicates fully learned sequences",
                            "Session count tracks total practice sessions",
                            "Practice time shows cumulative training duration",
                            "Progress is tracked per profile for family sharing"
                        ]
                    )

                    helpSection(
                        icon: "info.circle.fill",
                        title: "Sequence Content",
                        description: "Each sequence provides comprehensive practice guidance:",
                        tips: [
                            "Step-by-step attack and defence moves",
                            "Counter techniques where applicable",
                            "Korean terminology with romanisation",
                            "Execution details and key points",
                            "Common mistakes and practice tips"
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

                        tipRow("Start with 3-Step Sparring for foundational skills")
                        tipRow("Practice sequences slowly before adding speed")
                        tipRow("Focus on proper form for both attack and defence")
                        tipRow("Step sparring builds reaction time and technique flow")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Step Sparring Help")
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
                    .foregroundColor(.orange)
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
    StepSparringHelpSheet()
}
