import SwiftUI

/**
 * PracticeFeaturesStepView.swift
 *
 * PURPOSE: Fourth step of onboarding - explain Practice tab features
 *
 * STEP 4 of 6 in initial tour
 *
 * WHY: Users specifically asked for clarity on what each feature does
 * This step explains the 4 main practice features in simple terms
 */

struct PracticeFeaturesStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("Practice Features")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Four ways to master Taekwondo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)

                // Feature Cards
                VStack(spacing: 16) {
                    FeatureCard(
                        icon: "rectangle.stack.badge.play",
                        title: "Flashcards",
                        description: "Learn Korean terminology using spaced repetition. Study new terms or test yourself on what you've learned."
                    )

                    FeatureCard(
                        icon: "checkmark.circle.fill",
                        title: "Multiple Choice Tests",
                        description: "Quiz yourself on terminology, patterns, and theory. Choose comprehensive tests or quick reviews."
                    )

                    FeatureCard(
                        icon: "figure.walk",
                        title: "Patterns",
                        description: "Practice traditional Taekwondo patterns (tul) with step-by-step instructions for each move."
                    )

                    FeatureCard(
                        icon: "figure.2.arms.open",
                        title: "Step Sparring",
                        description: "Master pre-arranged attack, defense, and counter sequences for your belt level."
                    )
                }
                .padding(.horizontal)

                Spacer(minLength: 40)

                // Swipe hint
                VStack(spacing: 8) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.5))
                    Text("Swipe to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Supporting View

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.headline)

                Spacer()
            }

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct PracticeFeaturesStepView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeFeaturesStepView()
    }
}
