import SwiftUI
import SwiftData

/**
 * TemplateFillerGameView.swift
 *
 * PURPOSE: Main game view for Template Filler mode
 *
 * FEATURES:
 * - Display phrase with blanks (____)
 * - Show multiple-choice options for each blank
 * - Validate selections
 * - Show feedback with Continue button
 */

struct TemplateFillerGameView: View {
    @ObservedObject var templateFillerService: TemplateFillerService
    @Binding var session: TemplateFillerSession
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    @State private var userSelections: [Int: String] = [:] // position -> selected word
    @State private var validationResult: TemplateValidationResult?
    @State private var showingResults: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                if showingResults {
                    resultsView
                } else if let challenge = session.currentChallenge {
                    gameView(for: challenge)
                }
            }
            .navigationTitle("Template Filler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") { dismiss() }
                        .accessibilityIdentifier("template-filler-quit-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.caption)
                        Text("\(session.currentChallengeIndex + 1)/\(session.totalChallenges)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onAppear {
            initializeChallenge()
        }
    }

    private func gameView(for challenge: TemplateChallenge) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(challenge.displayTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top)

                // Phrase with blanks
                phraseDisplay(for: challenge)

                // Blank selectors
                ForEach(challenge.blanks) { blank in
                    blankSelector(for: blank)
                }

                if validationResult == nil && allBlanksSelected(challenge: challenge) {
                    checkButton
                }

                if let result = validationResult {
                    validationFeedback(result: result)
                }
            }
            .padding()
        }
    }

    private func phraseDisplay(for challenge: TemplateChallenge) -> some View {
        VStack(spacing: 16) {
            // Reference phrase (complete, always shown)
            VStack(spacing: 8) {
                Text(challenge.direction == .englishToKorean ? "Korean Reference" : "English Reference")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(challenge.referencePhrase)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            Divider()

            // Target phrase with blanks to fill
            VStack(spacing: 8) {
                Text(challenge.direction == .englishToKorean ? "Complete in English:" : "Complete in Korean:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(0..<challenge.targetPhrase.count, id: \.self) { index in
                        if let blank = challenge.blanks.first(where: { $0.position == index }) {
                            // Blank - show selection or underscore
                            if let selected = userSelections[index] {
                                Text(selected)
                                    .font(.headline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                            } else {
                                Text("____")
                                    .font(.headline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        } else {
                            // Regular word (not a blank)
                            Text(challenge.targetPhrase[index])
                                .font(.headline)
                        }
                    }
                }
                .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func blankSelector(for blank: TemplateBlank) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blank \(blank.blankNumber): Select word")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(spacing: 8) {
                ForEach(Array(blank.choices.enumerated()), id: \.offset) { index, word in
                    Button {
                        if validationResult == nil {
                            userSelections[blank.position] = word
                        }
                    } label: {
                        HStack {
                            Text(word)
                                .font(.body)
                                .foregroundColor(.primary)

                            Spacer()

                            if userSelections[blank.position] == word {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding()
                        .background(
                            userSelections[blank.position] == word ?
                            Color.accentColor.opacity(0.1) : Color(.tertiarySystemGroupedBackground)
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var checkButton: some View {
        Button(action: checkSelections) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Check Answer")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private func validationFeedback(result: TemplateValidationResult) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(result.isCorrect ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isCorrect ? "Correct!" : "Not quite...")
                        .font(.headline)
                        .foregroundColor(result.isCorrect ? .green : .orange)

                    Text(result.feedback)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(result.isCorrect ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            )

            Button(action: handleContinue) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    private var resultsView: some View {
        TemplateFillerResultsView(
            session: session,
            metrics: templateFillerService.calculateMetrics(session: session),
            onDismiss: {
                onComplete()
                dismiss()
            }
        )
    }

    // MARK: - Logic

    private func initializeChallenge() {
        userSelections = [:]
        validationResult = nil
    }

    private func allBlanksSelected(challenge: TemplateChallenge) -> Bool {
        return challenge.blanks.allSatisfy { userSelections[$0.position] != nil }
    }

    private func checkSelections() {
        guard let challenge = session.currentChallenge else { return }

        let result = templateFillerService.validateSelections(
            userSelections: userSelections,
            challenge: challenge
        )

        withAnimation {
            validationResult = result
        }

        let completedChallenge = CompletedTemplateChallenge(
            challenge: challenge,
            userSelections: userSelections,
            isCorrect: result.isCorrect,
            completionTime: Date()
        )
        session.completedChallenges.append(completedChallenge)
    }

    private func handleContinue() {
        session.currentChallengeIndex += 1

        if session.isComplete {
            withAnimation {
                showingResults = true
            }
        } else {
            withAnimation {
                initializeChallenge()
            }
        }
    }
}

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    @Previewable @State var session = TemplateFillerSession(
        wordCount: 3,
        totalChallenges: 5,
        challenges: [
            TemplateChallenge(
                challengeNumber: 1,
                technique: TechniquePhrase(
                    id: "preview-technique",
                    english: "Outer Forearm Block",
                    koreanRomanized: "Bakat Palmok Makgi",
                    category: .blocks
                ),
                englishWords: ["Outer", "Forearm", "Block"],
                koreanWords: ["Bakat", "Palmok", "Makgi"],
                blanks: [
                    TemplateBlank(
                        blankNumber: 1,
                        position: 1,
                        correctWord: "Forearm",
                        correctKorean: "Palmok",
                        choices: ["Forearm", "Fist", "Knife Hand", "Palm"]
                    )
                ],
                direction: .englishToKorean
            )
        ],
        blanksPerPhrase: 1,
        direction: .englishToKorean,
        startTime: Date()
    )

    let service = TemplateFillerService(modelContext: modelContainer.mainContext)

    TemplateFillerGameView(
        templateFillerService: service,
        session: $session,
        onComplete: {}
    )
}
