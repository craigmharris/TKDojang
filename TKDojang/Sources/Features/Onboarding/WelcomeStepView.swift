import SwiftUI

/**
 * WelcomeStepView.swift
 *
 * PURPOSE: First step of onboarding - welcome message and app purpose
 *
 * STEP 1 of 6 in initial tour
 */

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            // Title
            Text("Welcome to TKDojang")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)

            // Description
            Text("Master the ancient art of Taekwondo with structured lessons, technique demonstrations, and personalized progress tracking.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

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
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Preview

struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeStepView()
    }
}
