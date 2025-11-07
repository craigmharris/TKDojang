import SwiftUI

/**
 * TourStepCard.swift
 *
 * PURPOSE: Reusable card component for displaying tour steps
 *
 * WHY: Consistent design across all tour steps (initial and feature tours)
 * Makes it easy to maintain visual style and layout
 *
 * ARCHITECTURE: Supports both TourStep (Phase 1) and FeatureTourStep (Phase 2)
 * - TourStep: Simple text + icon for initial onboarding
 * - FeatureTourStep: Enhanced with live component demos and tips
 */

struct TourStepCard: View {
    private let content: CardContent

    // MARK: - Initializers

    /// Initialize with TourStep (Phase 1 - initial onboarding)
    init(step: TourStep) {
        self.content = .basicStep(step)
    }

    /// Initialize with FeatureTourStep (Phase 2 - feature tours)
    init(step: FeatureTourStep) {
        self.content = .featureStep(step)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Icon/Image
                iconView
                    .accessibilityHidden(true)

                // Title
                titleView

                // Description/Message
                descriptionView

                // Live Component Demo (Feature tours only)
                if case .featureStep(let step) = content,
                   let liveComponent = step.liveComponent {
                    liveComponentView(liveComponent)
                }

                // Tip Text (Feature tours only)
                if case .featureStep(let step) = content,
                   let tipText = step.tipText {
                    tipView(tipText)
                }

                Spacer(minLength: 40)

                // Action button (Basic tours only)
                if case .basicStep(let step) = content,
                   let action = step.action {
                    actionButton(action)
                }
            }
            .padding()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var iconView: some View {
        switch content {
        case .basicStep(let step):
            if let imageName = step.imageName {
                Image(systemName: imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
            }
        case .featureStep(let step):
            Image(systemName: step.icon)
                .font(.system(size: 80))
                .foregroundColor(.blue)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        switch content {
        case .basicStep(let step):
            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        case .featureStep(let step):
            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        switch content {
        case .basicStep(let step):
            Text(step.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        case .featureStep(let step):
            Text(step.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func liveComponentView(_ component: AnyView) -> some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)

            Text("Live Demo")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            component
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .padding(.horizontal)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Component demonstration")
    }

    @ViewBuilder
    private func tipView(_ tipText: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            Text(tipText)
                .font(.callout)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip: \(tipText)")
    }

    @ViewBuilder
    private func actionButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text("Continue")
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal)
    }

    // MARK: - Content Type

    private enum CardContent {
        case basicStep(TourStep)
        case featureStep(FeatureTourStep)
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
