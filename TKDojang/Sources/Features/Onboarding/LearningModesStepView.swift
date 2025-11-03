import SwiftUI

/**
 * LearningModesStepView.swift
 *
 * PURPOSE: Fifth step of onboarding - explain Progression vs Mastery modes
 *
 * STEP 5 of 6 in initial tour
 *
 * WHY: Users need to understand the two learning approaches to make
 * an informed choice during profile customization
 */

struct LearningModesStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("Learning Modes")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Choose your learning approach")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)

                // Mode Comparison
                VStack(spacing: 20) {
                    LearningModeCard(
                        title: "Progression Mode",
                        icon: "arrow.up.circle.fill",
                        color: .blue,
                        description: "Focus on learning belt-specific content in order. Perfect for students preparing for their next grading.",
                        features: [
                            "Content organized by belt level",
                            "Learn what you need for your rank",
                            "Track progress towards next belt"
                        ]
                    )

                    Divider()
                        .padding(.horizontal)

                    LearningModeCard(
                        title: "Mastery Mode",
                        icon: "star.circle.fill",
                        color: .orange,
                        description: "Study all content using spaced repetition. Ideal for deepening knowledge and long-term retention.",
                        features: [
                            "Access all content regardless of belt",
                            "Spaced repetition for memorization",
                            "Master material at your own pace"
                        ]
                    )
                }
                .padding(.horizontal)

                // Reassurance
                Text("Don't worry - you can change this anytime in your profile settings!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer(minLength: 40)

                // Swipe hint
                VStack(spacing: 8) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.5))
                    Text("Swipe to finish")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Supporting View

struct LearningModeCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let features: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)

                Spacer()
            }

            // Description
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(color)
                            .font(.caption)
                            .frame(width: 16)
                            .accessibilityHidden(true)

                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct LearningModesStepView_Previews: PreviewProvider {
    static var previews: some View {
        LearningModesStepView()
    }
}
