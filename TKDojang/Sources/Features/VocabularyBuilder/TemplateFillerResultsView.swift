import SwiftUI

/**
 * TemplateFillerResultsView.swift
 *
 * PURPOSE: Results screen for Template Filler game completion
 *
 * FEATURES:
 * - Display accuracy metrics
 * - Star rating based on performance
 * - Celebration UI
 * - Return to menu option
 */

struct TemplateFillerResultsView: View {
    let session: TemplateFillerSession
    let metrics: TemplateMetrics
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                completionHeader
                statsSection
                actionButtons

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session Complete!")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private var completionHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < metrics.stars ? "star.fill" : "star")
                        .font(.title)
                        .foregroundColor(index < metrics.stars ? .yellow : .gray.opacity(0.3))
                }
            }
            .accessibilityLabel("\(metrics.stars) out of 3 stars")

            Text(performanceMessage)
                .font(.title2)
                .fontWeight(.semibold)

            Text("All \(metrics.totalChallenges) templates completed!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var performanceMessage: String {
        switch metrics.stars {
        case 3: return "Pattern Master!"
        case 2: return "Great Work!"
        default: return "Well Done!"
        }
    }

    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                statRow(icon: "checkmark.circle.fill", label: "Correct", value: "\(metrics.correctChallenges)/\(metrics.totalChallenges)")
                statRow(icon: "percent", label: "Accuracy", value: "\(metrics.accuracyPercentage)%")
                statRow(icon: "clock", label: "Time", value: metrics.formattedDuration)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
    }

    private var actionButtons: some View {
        Button(action: onDismiss) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Done")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .accessibilityIdentifier("template-filler-done-button")
    }
}

#Preview {
    NavigationStack {
        TemplateFillerResultsView(
            session: TemplateFillerSession(
                wordCount: 3,
                totalChallenges: 10,
                challenges: [],
                blanksPerPhrase: 1,
                direction: .englishToKorean,
                startTime: Date().addingTimeInterval(-300)
            ),
            metrics: TemplateMetrics(
                totalChallenges: 10,
                correctChallenges: 9,
                accuracy: 0.9,
                duration: 300,
                stars: 3
            ),
            onDismiss: {}
        )
    }
}
