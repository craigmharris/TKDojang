import SwiftUI
import SwiftData

/**
 * SlotBuilderGameView.swift
 *
 * PURPOSE: Main game view for Slot Builder mode
 *
 * FEATURES:
 * - Slot-by-slot phrase construction
 * - Progress tracking (current challenge / total)
 * - Current slot highlighting
 * - Word selection from category choices
 * - Phrase validation with immediate feedback
 * - Session completion with results
 *
 * GAME FLOW:
 * 1. Show current challenge with empty slots
 * 2. User selects first slot → word choices appear
 * 3. User picks word → fills slot, advances to next
 * 4. Repeat until all slots filled
 * 5. Auto-validate complete phrase
 * 6. Show feedback → Continue to next challenge
 * 7. After all challenges → Show results view
 *
 * ARCHITECTURE:
 * - Composes extracted components (PhraseSlotComponent, WordCategoryPickerComponent, PhraseValidationComponent)
 * - Integrates with SlotBuilderService for session management and validation
 */

struct SlotBuilderGameView: View {
    @ObservedObject var slotBuilderService: SlotBuilderService
    @Binding var session: SlotBuilderSession
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    @State private var currentSlotIndex: Int = 0
    @State private var selectedWords: [CategorizedWord?] = []
    @State private var showingValidation: Bool = false
    @State private var validationResult: PhraseValidationResult?
    @State private var showingResults: Bool = false

    var body: some View {
        let _ = DebugLogger.ui("🎮 SlotBuilderGameView.body: session has \(session.challenges.count) challenges, currentIndex: \(session.currentChallengeIndex)")

        NavigationStack {
            ZStack {
                if showingResults {
                    resultsView
                } else if let challenge = session.currentChallenge {
                    gameView(for: challenge)
                } else {
                    Text("No challenge available")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Slot Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") {
                        dismiss()
                    }
                    .accessibilityIdentifier("slot-builder-quit-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    progressIndicator
                }
            }
        }
        .onAppear {
            initializeChallenge()
        }
    }

    // MARK: - Game View

    private func gameView(for challenge: PhraseChallenge) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Challenge title
                Text(challenge.displayTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("slot-builder-challenge-title")

                // Template description
                Text(challenge.template.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Phrase slots
                phraseSlotsView(for: challenge)

                if showingValidation, let result = validationResult {
                    // Validation feedback
                    PhraseValidationComponent(
                        validationResult: result,
                        userPhrase: selectedWords.compactMap { $0 },
                        onContinue: handleContinue
                    )
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Word choices for current slot
                    if currentSlotIndex < challenge.slotChoices.count {
                        wordChoicesView(for: challenge.slotChoices[currentSlotIndex])
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Phrase Slots

    private func phraseSlotsView(for challenge: PhraseChallenge) -> some View {
        VStack(spacing: 12) {
            ForEach(0..<challenge.template.wordCount, id: \.self) { index in
                let slotChoice = challenge.slotChoices[index]
                PhraseSlotComponent(
                    position: index + 1,
                    categoryLabel: slotChoice.slotLabel,
                    category: slotChoice.allowedCategories.first ?? .action,
                    selectedWord: selectedWords[safe: index] ?? nil,
                    isCurrent: index == currentSlotIndex && !showingValidation,
                    onTap: {
                        if !showingValidation {
                            currentSlotIndex = index
                        }
                    }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("slot-builder-phrase-slots")
    }

    // MARK: - Word Choices

    private func wordChoicesView(for slotChoice: SlotChoices) -> some View {
        WordCategoryPickerComponent(
            wordChoices: slotChoice.wordChoices,
            categoryLabel: slotChoice.slotLabel,
            category: slotChoice.allowedCategories.first ?? .action,
            selectedWord: selectedWords[safe: currentSlotIndex] ?? nil,
            onSelectWord: { word in
                selectWord(word, forSlot: currentSlotIndex)
            }
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "list.number")
                .font(.caption)
                .accessibilityHidden(true)

            Text("\(session.currentChallengeIndex + 1)/\(session.totalChallenges)")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .accessibilityLabel("Challenge \(session.currentChallengeIndex + 1) of \(session.totalChallenges)")
        .accessibilityIdentifier("slot-builder-progress")
    }

    // MARK: - Results View

    private var resultsView: some View {
        SlotBuilderResultsView(
            session: session,
            onDismiss: {
                onComplete()
                dismiss()
            }
        )
    }

    // MARK: - Game Logic

    private func initializeChallenge() {
        guard let challenge = session.currentChallenge else { return }

        // Initialize selected words array
        selectedWords = Array(repeating: nil, count: challenge.template.wordCount)
        currentSlotIndex = 0
        showingValidation = false
        validationResult = nil

        DebugLogger.ui("🎮 SlotBuilder: Initialized challenge \(challenge.challengeNumber)")
    }

    private func selectWord(_ word: CategorizedWord, forSlot index: Int) {
        guard index < selectedWords.count else { return }

        selectedWords[index] = word
        DebugLogger.ui("📝 SlotBuilder: Selected '\(word.english)' for slot \(index + 1)")

        // Auto-advance to next empty slot or validate if all filled
        if let nextEmptySlot = selectedWords.firstIndex(where: { $0 == nil }) {
            withAnimation {
                currentSlotIndex = nextEmptySlot
            }
        } else {
            // All slots filled - auto-validate
            validatePhrase()
        }
    }

    private func validatePhrase() {
        guard let challenge = session.currentChallenge else { return }

        let userPhrase = selectedWords.compactMap { $0 }
        guard userPhrase.count == challenge.template.wordCount else {
            DebugLogger.ui("❌ SlotBuilder: Incomplete phrase - \(userPhrase.count)/\(challenge.template.wordCount) words")
            return
        }

        // Validate with service
        let result = slotBuilderService.validatePhrase(
            userPhrase: userPhrase,
            challenge: challenge
        )

        withAnimation {
            validationResult = result
            showingValidation = true
        }

        // Record completion
        let completedChallenge = CompletedChallenge(
            challenge: challenge,
            userPhrase: userPhrase,
            isCorrect: result.isCorrect,
            feedback: result.feedback,
            attemptTime: Date()
        )
        session.completedChallenges.append(completedChallenge)

        DebugLogger.ui("✅ SlotBuilder: Validation - \(result.isCorrect ? "Correct" : "Incorrect")")
    }

    private func handleContinue() {
        // Move to next challenge
        session.currentChallengeIndex += 1

        if session.isComplete {
            // Show results
            withAnimation {
                showingResults = true
            }
        } else {
            // Initialize next challenge
            withAnimation {
                initializeChallenge()
            }
        }
    }
}

// MARK: - Array Safe Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    @Previewable @State var session = SlotBuilderSession(
        wordCount: 2,
        totalChallenges: 5,
        challenges: [
            PhraseChallenge(
                challengeNumber: 1,
                template: PhraseGrammar.templates(for: 2)[0],
                slotChoices: [
                    SlotChoices(
                        slotPosition: 1,
                        slotLabel: "Tool",
                        allowedCategories: [.tool],
                        wordChoices: [
                            CategorizedWord(english: "Forearm", romanized: "Palmok", category: .tool, frequency: 18),
                            CategorizedWord(english: "Fist", romanized: "Joomuk", category: .tool, frequency: 11),
                            CategorizedWord(english: "Knife", romanized: "Sonkal", category: .tool, frequency: 13),
                            CategorizedWord(english: "Palm", romanized: "Sonbadak", category: .tool, frequency: 10)
                        ]
                    ),
                    SlotChoices(
                        slotPosition: 2,
                        slotLabel: "Action",
                        allowedCategories: [.action],
                        wordChoices: [
                            CategorizedWord(english: "Block", romanized: "Makgi", category: .action, frequency: 27),
                            CategorizedWord(english: "Kick", romanized: "Chagi", category: .action, frequency: 14),
                            CategorizedWord(english: "Punch", romanized: "Jirugi", category: .action, frequency: 9),
                            CategorizedWord(english: "Strike", romanized: "Taerigi", category: .action, frequency: 11)
                        ]
                    )
                ]
            )
        ],
        startTime: Date()
    )

    let service = SlotBuilderService(modelContext: modelContainer.mainContext)

    return SlotBuilderGameView(
        slotBuilderService: service,
        session: $session,
        onComplete: {}
    )
}
