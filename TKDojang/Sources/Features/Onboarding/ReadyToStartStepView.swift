import SwiftUI

/**
 * ReadyToStartStepView.swift
 *
 * PURPOSE: Sixth and final step of onboarding - confirmation and completion
 *
 * STEP 6 of 6 in initial tour
 *
 * WHY: Provides clear call-to-action to complete onboarding and
 * start using the app. Creates excitement for learning journey.
 */

struct ReadyToStartStepView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Success Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .accessibilityHidden(true)
            }

            // Title
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text("Ready to begin your Taekwondo learning journey?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Quick Tips
            VStack(alignment: .leading, spacing: 12) {
                QuickTipRow(
                    icon: "questionmark.circle",
                    text: "Look for (?) icons for feature-specific help"
                )

                QuickTipRow(
                    icon: "person.circle",
                    text: "You can replay this tour from your Profile"
                )

                QuickTipRow(
                    icon: "figure.walk",
                    text: "Start with vocabulary builder to learn terminology"
                )
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            // Complete Button
            Button(action: onComplete) {
                HStack {
                    Text("Let's Go!")
                        .font(.headline)

                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.05), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Supporting View

struct QuickTipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

struct ReadyToStartStepView_Previews: PreviewProvider {
    static var previews: some View {
        ReadyToStartStepView(onComplete: {})
    }
}
