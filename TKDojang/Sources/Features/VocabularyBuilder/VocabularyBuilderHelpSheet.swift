import SwiftUI

/**
 * VocabularyBuilderHelpSheet.swift
 *
 * PURPOSE: Comprehensive help guide for Vocabulary Builder feature
 *
 * WHY: Users need to understand all 4 game modes and how to use them effectively
 * APPROACH: Single sheet explaining Slot Builder, Memory Match, Phrase Decoder, and Template Filler
 */

struct VocabularyBuilderHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "character.book.closed")
                            .font(.system(size: 48))
                            .foregroundColor(.purple)

                        Text("Vocabulary Builder")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Master Taekwondo terminology through interactive games using real technique names")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)

                    Divider()

                    // Game Mode Sections
                    gameSection(
                        icon: "rectangle.3.group.fill",
                        iconColor: .blue,
                        title: "Slot Builder",
                        description: "Construct complete technique names by filling slots with the correct Korean words:",
                        tips: [
                            "Each slot shows allowed word categories (Action, Tool, Direction, etc.)",
                            "Tap a slot to see available word choices for that position",
                            "Korean romanization shown beneath each word choice",
                            "Complete phrases use authentic technique terminology",
                            "Perfect for learning Korean word order and vocabulary"
                        ]
                    )

                    gameSection(
                        icon: "square.grid.2x2.fill",
                        iconColor: .red,
                        title: "Memory Match",
                        description: "Find matching pairs of English and Korean technique terms:",
                        tips: [
                            "Cards show either English or Korean terminology",
                            "Tap cards to flip and reveal the word",
                            "Selected card shows orange glow indicator",
                            "Match English word with its Korean equivalent",
                            "Tap anywhere to reset unmatched cards",
                            "Card backs feature 태권도 (Taekwondo) in Hangul",
                            "Builds translation skills and vocabulary recognition"
                        ]
                    )

                    gameSection(
                        icon: "arrow.left.arrow.right",
                        iconColor: .orange,
                        title: "Phrase Decoder",
                        description: "Unscramble real technique names by reordering words:",
                        tips: [
                            "Uses authentic techniques from blocks, kicks, and strikes",
                            "Drag and drop words to arrange in correct order",
                            "Choose English or Korean language mode",
                            "Reference phrase shown in alternate language for learning",
                            "Validates word order against real technique names",
                            "Teaches proper technique name structure"
                        ]
                    )

                    gameSection(
                        icon: "doc.text.fill",
                        iconColor: .green,
                        title: "Template Filler",
                        description: "Complete real technique names by filling in missing words:",
                        tips: [
                            "Full Korean reference phrase shown at top",
                            "Fill in 1-3 English word blanks per phrase",
                            "Multiple choice options from same word position",
                            "Uses actual techniques from JSON files, not arbitrary phrases",
                            "Perfect for learning word meanings in context",
                            "Korean reference helps derive the English translation"
                        ]
                    )

                    // Configuration Tips
                    helpSection(
                        icon: "slider.horizontal.3",
                        title: "Configuration Options",
                        description: "Customize each game mode for optimal learning:",
                        tips: [
                            "Phrase length: 2-5 words controls difficulty level",
                            "Session count: 5-15 phrases per game session",
                            "Difficulty adapts automatically based on phrase length",
                            "Estimated time shown in session preview",
                            "Start with shorter phrases (2-3 words) for beginners"
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

                        tipRow("Start with Slot Builder to learn vocabulary")
                        tipRow("Use Memory Match to reinforce English ↔ Korean translation")
                        tipRow("Try Phrase Decoder to master word order")
                        tipRow("Use Template Filler to learn words in context")
                        tipRow("All games use authentic Taekwondo terminology")
                        tipRow("Practice regularly with different phrase lengths")
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Vocabulary Builder Help")
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
    private func gameSection(icon: String, iconColor: Color, title: String, description: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
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
    private func helpSection(icon: String, title: String, description: String, tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.purple)
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
    VocabularyBuilderHelpSheet()
}
