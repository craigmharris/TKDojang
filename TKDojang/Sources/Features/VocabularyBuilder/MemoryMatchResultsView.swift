import SwiftUI

/**
 * MemoryMatchResultsView.swift
 *
 * PURPOSE: Results screen for Memory Match game completion
 *
 * FEATURES:
 * - Display performance metrics (moves, time, efficiency)
 * - Star rating (1-3 stars based on performance)
 * - Celebratory UI for completion
 * - Options to play again or return to menu
 *
 * ARCHITECTURE:
 * - Follows SlotBuilderResultsView pattern
 * - Read-only view of session metrics
 */

struct MemoryMatchResultsView: View {
    let session: MemoryMatchSession
    let metrics: MemoryMatchMetrics
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Completion icon and stars
                completionHeader

                // Stats
                statsSection

                // Actions
                actionButtons

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Game Complete!")
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
            .accessibilityIdentifier("memory-match-star-rating")

            // Performance message
            Text(performanceMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("All \(metrics.totalPairs) pairs matched!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var performanceMessage: String {
        switch metrics.stars {
        case 3:
            return "Outstanding Memory!"
        case 2:
            return "Great Job!"
        default:
            return "Well Done!"
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
                    label: "Moves",
                    value: "\(metrics.moves)",
                    detail: optimalMovesComparison
                )

                statRow(
                    icon: "clock",
                    label: "Time",
                    value: metrics.formattedDuration,
                    detail: nil
                )

                statRow(
                    icon: "gauge.medium",
                    label: "Efficiency",
                    value: "\(metrics.efficiencyPercentage)%",
                    detail: efficiencyDescription
                )
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .accessibilityIdentifier("memory-match-stats-section")
    }

    private func statRow(icon: String, label: String, value: String, detail: String?) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
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

    private var optimalMovesComparison: String {
        let optimal = metrics.totalPairs
        let extra = metrics.moves - optimal

        if extra == 0 {
            return "Perfect! No extra moves"
        } else if extra > 0 {
            return "\(extra) more than optimal (\(optimal))"
        } else {
            return "Optimal: \(optimal) moves"
        }
    }

    private var efficiencyDescription: String {
        switch metrics.efficiencyPercentage {
        case 90...100:
            return "Excellent efficiency!"
        case 70..<90:
            return "Good efficiency"
        case 50..<70:
            return "Room for improvement"
        default:
            return "Keep practicing"
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
            .accessibilityIdentifier("memory-match-done-button")

            Text("Want to improve your score? Try again!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MemoryMatchResultsView(
            session: MemoryMatchSession(
                pairCount: 8,
                totalPairs: 8,
                cards: [],
                startTime: Date().addingTimeInterval(-180), // 3 minutes ago
                moveCount: 12,
                matchedPairs: 8
            ),
            metrics: MemoryMatchMetrics(
                totalPairs: 8,
                moves: 12,
                duration: 180,
                efficiency: 0.67,
                stars: 2
            ),
            onDismiss: {}
        )
    }
}

#Preview("Perfect Score") {
    NavigationStack {
        MemoryMatchResultsView(
            session: MemoryMatchSession(
                pairCount: 6,
                totalPairs: 6,
                cards: [],
                startTime: Date().addingTimeInterval(-120),
                moveCount: 6,
                matchedPairs: 6
            ),
            metrics: MemoryMatchMetrics(
                totalPairs: 6,
                moves: 6,
                duration: 120,
                efficiency: 1.0,
                stars: 3
            ),
            onDismiss: {}
        )
    }
}
