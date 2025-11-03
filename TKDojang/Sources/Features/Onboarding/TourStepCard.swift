import SwiftUI

/**
 * TourStepCard.swift
 *
 * PURPOSE: Reusable card component for displaying tour steps
 *
 * WHY: Consistent design across all tour steps (initial and feature tours)
 * Makes it easy to maintain visual style and layout
 */

struct TourStepCard: View {
    let step: TourStep

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon/Image
            if let imageName = step.imageName {
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)
            }

            // Title
            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            // Message
            Text(step.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            // Action button if provided
            if let action = step.action {
                Button(action: action) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Preview

struct TourStepCard_Previews: PreviewProvider {
    static var previews: some View {
        TourStepCard(
            step: TourStep(
                title: "Welcome to TKDojang",
                message: "Master Taekwondo with structured lessons and personalized progress tracking.",
                imageName: "figure.martial.arts"
            )
        )
    }
}
