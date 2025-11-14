import SwiftUI

/**
 * PhraseDecoderResultsView.swift
 *
 * PURPOSE: Results screen for Phrase Decoder game completion
 *
 * FEATURES:
 * - Display performance metrics (attempts, time)
 * - Star rating based on average attempts
 * - Celebration for completion
 * - Options to return to menu
 *
 * ARCHITECTURE:
 * - Follows standard results view pattern
 * - Read-only view of session metrics
 */

struct PhraseDecoderResultsView: View {
    let session: PhraseDecoderSession
    let metrics: DecoderMetrics
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Completion header
                completionHeader

                // Stats
                statsSection

                // Actions
                actionButtons

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session Complete!")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var completionHeader: some View {
        VStack(spacing: 16) {
            // Trophy icon
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            // Star rating
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < metrics.stars ? "star.fill" : "star")
                        .font(.title)
                        .foregroundColor(index < metrics.stars ? .yellow : .gray.opacity(0.3))
                }
            }
            .accessibilityLabel("\(metrics.stars) out of 3 stars")
            .accessibilityIdentifier("phrase-decoder-star-rating")

            // Performance message
            Text(performanceMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("All \(metrics.totalChallenges) phrases decoded!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var performanceMessage: String {
        switch metrics.stars {
        case 3:
            return "Grammar Master!"
        case 2:
            return "Well Done!"
        default:
            return "Good Job!"
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                statRow(
                    icon: "arrow.triangle.2.circlepath",
                    label: "Total Attempts",
                    value: "\(metrics.totalAttempts)",
                    detail: nil
                )

                statRow(
                    icon: "chart.bar.fill",
                    label: "Avg Attempts/Phrase",
                    value: metrics.formattedAverageAttempts,
                    detail: attemptsDescription
                )

                statRow(
                    icon: "clock",
                    label: "Time",
                    value: metrics.formattedDuration,
                    detail: nil
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .accessibilityIdentifier("phrase-decoder-stats-section")
    }

    private func statRow(icon: String, label: String, value: String, detail: String?) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                    .frame(width: 24)
                    .accessibilityHidden(true)

                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)" + (detail.map { ", \($0)" } ?? ""))
    }

    private var attemptsDescription: String {
        if metrics.averageAttempts <= 1.5 {
            return "Excellent! Mostly first try"
        } else if metrics.averageAttempts <= 2.5 {
            return "Good performance"
        } else {
            return "Room for improvement"
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
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
            .accessibilityIdentifier("phrase-decoder-done-button")

            Text("Great work on mastering word order!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PhraseDecoderResultsView(
            session: PhraseDecoderSession(
                wordCount: 3,
                totalChallenges: 10,
                challenges: [],
                startTime: Date().addingTimeInterval(-300)
            ),
            metrics: DecoderMetrics(
                totalChallenges: 10,
                totalAttempts: 15,
                averageAttempts: 1.5,
                duration: 300,
                stars: 3
            ),
            onDismiss: {}
        )
    }
}

#Preview("Average Performance") {
    NavigationStack {
        PhraseDecoderResultsView(
            session: PhraseDecoderSession(
                wordCount: 4,
                totalChallenges: 10,
                challenges: [],
                startTime: Date().addingTimeInterval(-400)
            ),
            metrics: DecoderMetrics(
                totalChallenges: 10,
                totalAttempts: 25,
                averageAttempts: 2.5,
                duration: 400,
                stars: 2
            ),
            onDismiss: {}
        )
    }
}
