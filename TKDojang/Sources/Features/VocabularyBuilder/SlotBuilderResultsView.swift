import SwiftUI

/**
 * SlotBuilderResultsView.swift
 *
 * PURPOSE: Results screen shown after completing a Slot Builder session
 *
 * FEATURES:
 * - Session statistics (accuracy, correct/total, time)
 * - Performance feedback with visual indicators
 * - List of completed challenges with correctness
 * - Done button to return to Learn
 * - Accessibility support with semantic labels
 *
 * ARCHITECTURE:
 * - Receives completed SlotBuilderSession
 * - Calculates and displays performance metrics
 * - Follows app's results view pattern (like TestResultsView)
 */

struct SlotBuilderResultsView: View {

    // MARK: - Properties

    let session: SlotBuilderSession
    var onDismiss: () -> Void

    // MARK: - Computed Properties

    private var correctCount: Int {
        session.completedChallenges.filter { $0.isCorrect }.count
    }

    private var totalCount: Int {
        session.completedChallenges.count
    }

    private var accuracy: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(correctCount) / Double(totalCount) * 100
    }

    private var sessionDuration: TimeInterval {
        Date().timeIntervalSince(session.startTime)
    }

    private var performanceLevel: PerformanceLevel {
        switch accuracy {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        default: return .needsPractice
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                resultsHeader

                // Statistics cards
                statisticsSection

                // Performance feedback
                performanceFeedback

                // Challenge breakdown
                challengeBreakdown

                // Done button
                doneButton
            }
            .padding()
        }
        .navigationTitle("Session Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Header

    private var resultsHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: performanceLevel.icon)
                .font(.system(size: 60))
                .foregroundColor(performanceLevel.color)
                .accessibilityHidden(true)

            Text(performanceLevel.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(performanceLevel.color)

            Text(performanceLevel.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(performanceLevel.title). \(performanceLevel.message)")
    }

    // MARK: - Statistics

    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                statisticCard(
                    icon: "percent",
                    label: "Accuracy",
                    value: String(format: "%.0f%%", accuracy),
                    color: performanceLevel.color
                )

                statisticCard(
                    icon: "checkmark.circle",
                    label: "Correct",
                    value: "\(correctCount)/\(totalCount)",
                    color: .green
                )
            }

            HStack(spacing: 16) {
                statisticCard(
                    icon: "square.grid.2x2",
                    label: "Phrase Length",
                    value: "\(session.wordCount) words",
                    color: .blue
                )

                statisticCard(
                    icon: "clock",
                    label: "Time",
                    value: formattedDuration,
                    color: .orange
                )
            }
        }
    }

    private func statisticCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Performance Feedback

    private var performanceFeedback: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 8) {
                Text(performanceLevel.detailedFeedback)
                    .font(.body)
                    .foregroundColor(.secondary)

                if accuracy < 70 {
                    Text("💡 Tip: Try starting with 2-word phrases to build confidence with basic patterns.")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    // MARK: - Challenge Breakdown

    private var challengeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Challenges")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                ForEach(Array(session.completedChallenges.enumerated()), id: \.offset) { index, completed in
                    challengeRow(number: index + 1, completed: completed)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func challengeRow(number: Int, completed: CompletedChallenge) -> some View {
        HStack(spacing: 12) {
            // Challenge number
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(completed.isCorrect ? Color.green : Color.red))

            // User phrase
            VStack(alignment: .leading, spacing: 2) {
                Text(completed.userPhrase.map { $0.english }.joined(separator: " "))
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(completed.userPhrase.map { $0.romanized }.joined(separator: " "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Result icon
            Image(systemName: completed.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(completed.isCorrect ? .green : .red)
                .accessibilityLabel(completed.isCorrect ? "Correct" : "Incorrect")
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Challenge \(number): \(completed.userPhrase.map { $0.english }.joined(separator: " ")). \(completed.isCorrect ? "Correct" : "Incorrect")")
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: onDismiss) {
            HStack {
                Text("Done")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .accessibilityIdentifier("slot-builder-done-button")
        .accessibilityLabel("Done, return to Vocabulary Builder")
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let minutes = Int(sessionDuration) / 60
        let seconds = Int(sessionDuration) % 60
        return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
    }
}

// MARK: - Performance Level

private enum PerformanceLevel {
    case excellent
    case good
    case fair
    case needsPractice

    var title: String {
        switch self {
        case .excellent: return "Excellent!"
        case .good: return "Well Done!"
        case .fair: return "Good Effort"
        case .needsPractice: return "Keep Practicing"
        }
    }

    var message: String {
        switch self {
        case .excellent: return "You've mastered phrase construction!"
        case .good: return "You're building strong grammar skills."
        case .fair: return "You're making progress with phrase patterns."
        case .needsPractice: return "Practice makes perfect!"
        }
    }

    var detailedFeedback: String {
        switch self {
        case .excellent:
            return "Outstanding work! You've demonstrated excellent understanding of phrase grammar patterns. Try increasing to longer phrases for more challenge."
        case .good:
            return "Great job! You're showing solid understanding of how words combine into phrases. Keep practicing to reinforce these patterns."
        case .fair:
            return "Good start! You're beginning to understand phrase construction. Focus on learning the common patterns like Direction + Tool + Action."
        case .needsPractice:
            return "Don't worry - phrase grammar takes practice! Focus on 2-word phrases first (Tool + Action) to build a strong foundation."
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.circle.fill"
        case .good: return "hand.thumbsup.circle.fill"
        case .fair: return "checkmark.circle.fill"
        case .needsPractice: return "arrow.clockwise.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .excellent: return .yellow
        case .good: return .green
        case .fair: return .blue
        case .needsPractice: return .orange
        }
    }
}

// MARK: - Preview

#Preview("Excellent Performance") {
    NavigationStack {
        SlotBuilderResultsView(
            session: SlotBuilderSession(
                wordCount: 3,
                totalChallenges: 10,
                challenges: [],
                startTime: Date().addingTimeInterval(-600), // 10 minutes ago
                currentChallengeIndex: 10,
                completedChallenges: (1...10).map { i in
                    CompletedChallenge(
                        challenge: PhraseChallenge(
                            challengeNumber: i,
                            template: PhraseGrammar.templates(for: 3)[0],
                            slotChoices: []
                        ),
                        userPhrase: [
                            CategorizedWord(english: "Outer", romanized: "Bakat", category: .direction, frequency: 10),
                            CategorizedWord(english: "Forearm", romanized: "Palmok", category: .tool, frequency: 18),
                            CategorizedWord(english: "Block", romanized: "Makgi", category: .action, frequency: 27)
                        ],
                        isCorrect: i <= 9, // 90% accuracy
                        feedback: "Correct!",
                        attemptTime: Date()
                    )
                }
            ),
            onDismiss: {}
        )
    }
}

#Preview("Needs Practice") {
    NavigationStack {
        SlotBuilderResultsView(
            session: SlotBuilderSession(
                wordCount: 2,
                totalChallenges: 5,
                challenges: [],
                startTime: Date().addingTimeInterval(-300),
                currentChallengeIndex: 5,
                completedChallenges: (1...5).map { i in
                    CompletedChallenge(
                        challenge: PhraseChallenge(
                            challengeNumber: i,
                            template: PhraseGrammar.templates(for: 2)[0],
                            slotChoices: []
                        ),
                        userPhrase: [
                            CategorizedWord(english: "Fist", romanized: "Joomuk", category: .tool, frequency: 11),
                            CategorizedWord(english: "Punch", romanized: "Jirugi", category: .action, frequency: 9)
                        ],
                        isCorrect: i <= 2, // 40% accuracy
                        feedback: i <= 2 ? "Correct!" : "Incorrect",
                        attemptTime: Date()
                    )
                }
            ),
            onDismiss: {}
        )
    }
}
