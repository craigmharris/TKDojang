import SwiftUI

/**
 * LineWorkHelpSheet.swift
 *
 * PURPOSE: Simple explanation overlay for Line Work exercises
 *
 * WHY: Line Work is straightforward browsing with filtering - doesn't need multi-step walkthrough
 * APPROACH: Single overlay with key features explained
 */

struct LineWorkHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)

                        Text("Line Work Exercises")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Traditional exercise sequences for developing fundamental techniques")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Content Sections
                    helpSection(
                        icon: "figure.martial.arts",
                        title: "Exercise Sequences",
                        description: "Line work presents complete training exercises as movement sequences, showing how techniques connect and flow together.",
                        tips: [
                            "Each exercise shows all moves in the sequence",
                            "Exercises are organised by belt level and movement type",
                            "Practice sequences to build muscle memory and technique flow",
                            "Exercises complement pattern and technique practice"
                        ]
                    )

                    helpSection(
                        icon: "arrow.left.and.right",
                        title: "Movement Types",
                        description: "Exercises are categorised by how you move through the sequence:",
                        tips: [
                            "STATIC: Performed in place without traveling",
                            "FORWARD: Moving forward with each technique",
                            "BACKWARD: Moving backward with each technique",
                            "FWD & BWD: Combining forward and backward movement",
                            "ALTERNATING: Switching sides or directions"
                        ]
                    )

                    helpSection(
                        icon: "line.3.horizontal.decrease.circle",
                        title: "Filtering Options",
                        description: "Use filters to focus on specific types of exercises or categories:",
                        tips: [
                            "Movement Type: Filter by how you travel during the sequence",
                            "Category: Focus on Stances, Blocking, Striking, or Kicking",
                            "Belt Level: Content filtered based on your learning mode",
                            "Clear filters to see all available exercises"
                        ]
                    )

                    helpSection(
                        icon: "graduationcap.fill",
                        title: "Learning Modes",
                        description: "Content visibility adapts to your selected learning mode:",
                        tips: [
                            "Progression mode: Shows only your next belt level exercises",
                            "Mastery mode: Shows all exercises up to and including next belt",
                            "Exercises ordered by belt level (most advanced first)",
                            "Change learning mode in your profile settings"
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

                        tipRow("Practice exercises in order - they build progressively")
                        tipRow("Focus on proper form before adding speed")
                        tipRow("Use movement type filters to practice specific footwork patterns")
                        tipRow("Line work develops the foundations for patterns and sparring")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Line Work Help")
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
    LineWorkHelpSheet()
}
