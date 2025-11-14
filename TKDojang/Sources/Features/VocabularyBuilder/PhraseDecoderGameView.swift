import SwiftUI
import SwiftData

/**
 * PhraseDecoderGameView.swift
 *
 * PURPOSE: Main game view for Phrase Decoder mode
 *
 * FEATURES:
 * - Display scrambled phrase words
 * - Tap-to-select and tap-to-swap reordering
 * - Visual feedback for correct/incorrect positions
 * - Multiple attempts with partial feedback
 * - Attempt counter
 * - Session completion with results
 *
 * GAME FLOW:
 * 1. Show scrambled words in row
 * 2. User taps first word → highlights
 * 3. User taps second word → swaps positions
 * 4. User taps "Check" button
 * 5. Show which words are in correct position
 * 6. If incorrect, allow retry
 * 7. If correct, move to next phrase
 * 8. After all phrases → show results
 *
 * ARCHITECTURE:
 * - Tap-to-swap instead of drag-drop (better touch UX)
 * - Color-coded feedback (green = correct position)
 * - Integrates with PhraseDecoderService for validation
 */

struct PhraseDecoderGameView: View {
    @ObservedObject var phraseDecoderService: PhraseDecoderService
    @Binding var session: PhraseDecoderSession
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    @State private var currentEnglishWords: [String] = []
    @State private var currentKoreanWords: [String] = []
    @State private var selectedLanguage: PhraseLanguage = .english
    @State private var draggedWordIndex: Int? = nil
    @State private var hoverTargetIndex: Int? = nil  // Index being hovered over during drag
    @State private var dragOffset: CGSize = .zero  // Current drag offset
    @State private var validationResult: DecoderValidationResult?
    @State private var attempts: Int = 0
    @State private var showingResults: Bool = false

    var body: some View {
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
            .navigationTitle("Phrase Decoder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") {
                        dismiss()
                    }
                    .accessibilityIdentifier("phrase-decoder-quit-button")
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

    private func gameView(for challenge: DecoderChallenge) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Instructions
                VStack(spacing: 8) {
                    Text(challenge.displayTitle)
                        .font(.title3)
                        .fontWeight(.semibold)

                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.accentColor)
                            .font(.subheadline)
                        Text("Drag words by the handle (≡) to arrange in correct order")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .multilineTextAlignment(.center)

                    if attempts > 0 {
                        Text("Attempts: \(attempts)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.top)

                // Language Selector
                languageSelector

                // Reference phrase (non-selected language)
                referencePhrase(for: challenge)

                // Word boxes
                wordBoxesView

                // Check button
                if validationResult == nil {
                    checkButton
                }

                // Validation feedback
                if let result = validationResult {
                    validationFeedbackView(result: result)
                }
            }
            .padding()
        }
    }

    private var languageSelector: some View {
        Picker("Language", selection: $selectedLanguage) {
            ForEach(PhraseLanguage.allCases, id: \.self) { language in
                Text(language.displayName).tag(language)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .accessibilityIdentifier("phrase-decoder-language-picker")
        .disabled(validationResult != nil)
    }

    private func referencePhrase(for challenge: DecoderChallenge) -> some View {
        let referenceWords = selectedLanguage == .english ? challenge.correctKorean : challenge.correctEnglish
        let referenceLabel = selectedLanguage == .english ? "Korean" : "English"

        return VStack(spacing: 8) {
            Text("\(referenceLabel) Reference")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(referenceWords.joined(separator: " "))
                .font(.headline)
                .foregroundColor(.orange)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    private var wordBoxesView: some View {
        let currentWords = selectedLanguage == .english ? currentEnglishWords : currentKoreanWords

        return ZStack(alignment: .top) {
            // Main list with placeholders
            VStack(spacing: 12) {
                ForEach(0..<currentWords.count, id: \.self) { index in
                    let isBeingDragged = draggedWordIndex == index

                    // Show placeholder gap BEFORE this position if hover target is here
                    if let hoverIdx = hoverTargetIndex,
                       let draggedIdx = draggedWordIndex,
                       hoverIdx == index,
                       draggedIdx != index {
                        PlaceholderBoxView(position: index + 1)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Show the actual word box
                    WordBoxView(
                        word: currentWords[index],
                        position: index + 1,
                        isDragging: false,
                        isCorrect: validationResult?.correctPositions.contains(index),
                        isDropTarget: false
                    )
                    .opacity(isBeingDragged ? 0.0 : 1.0)  // Completely hide if being dragged
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if draggedWordIndex == nil {
                                    draggedWordIndex = index
                                    hoverTargetIndex = index
                                    DebugLogger.ui("🎯 Started dragging word at index \(index)")
                                }

                                dragOffset = value.translation

                                // Calculate hover position - must drag past ENTIRE placeholder gap (84px) to change
                                let itemHeight: CGFloat = 72
                                let itemSpacing: CGFloat = 12
                                let totalItemHeight = itemHeight + itemSpacing  // 84px per slot

                                // Calculate which slot we're over (rounds to nearest full item)
                                let displacement = Int((value.translation.height / totalItemHeight).rounded())
                                var newHoverIndex = index + displacement

                                // Clamp to valid range
                                newHoverIndex = max(0, min(currentWords.count - 1, newHoverIndex))

                                if newHoverIndex != hoverTargetIndex {
                                    DebugLogger.ui("🎯 Hover target: \(hoverTargetIndex ?? -1) → \(newHoverIndex) (offset: \(Int(value.translation.height))px)")
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        hoverTargetIndex = newHoverIndex
                                    }
                                }
                            }
                            .onEnded { value in
                                DebugLogger.ui("🏁 Drag ended: from=\(draggedWordIndex ?? -1), to=\(hoverTargetIndex ?? -1)")

                                if let fromIndex = draggedWordIndex,
                                   let toIndex = hoverTargetIndex,
                                   fromIndex != toIndex {
                                    handleDrop(fromIndex: fromIndex, toIndex: toIndex)
                                }

                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    draggedWordIndex = nil
                                    hoverTargetIndex = nil
                                    dragOffset = .zero
                                }
                            }
                    )
                    .disabled(validationResult != nil)
                }

                // Placeholder at end if dragging to last position
                if let hoverIdx = hoverTargetIndex,
                   hoverIdx == currentWords.count - 1,
                   let draggedIdx = draggedWordIndex,
                   draggedIdx != currentWords.count - 1 {
                    PlaceholderBoxView(position: currentWords.count)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Dragged item overlay - follows finger
            if let draggedIdx = draggedWordIndex,
               draggedIdx < currentWords.count {
                WordBoxView(
                    word: currentWords[draggedIdx],
                    position: draggedIdx + 1,
                    isDragging: true,
                    isCorrect: validationResult?.correctPositions.contains(draggedIdx),
                    isDropTarget: false
                )
                .offset(y: dragOffset.height)
                .opacity(0.95)
                .shadow(color: .black.opacity(0.3), radius: 12, y: 8)
                .allowsHitTesting(false)  // Pass touches through to underlying items
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("phrase-decoder-word-boxes")
        .onChange(of: selectedLanguage) { oldValue, newValue in
            // Reset validation when language changes
            validationResult = nil
            draggedWordIndex = nil
            hoverTargetIndex = nil
            dragOffset = .zero
        }
    }


    private var checkButton: some View {
        Button(action: checkPhrase) {
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
        .accessibilityIdentifier("phrase-decoder-check-button")
    }

    private func validationFeedbackView(result: DecoderValidationResult) -> some View {
        VStack(spacing: 16) {
            // Feedback card
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

            // Continue or retry button
            if result.isCorrect {
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
                .accessibilityIdentifier("phrase-decoder-continue-button")
            } else {
                Button(action: tryAgain) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Try Again")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .accessibilityIdentifier("phrase-decoder-retry-button")
            }
        }
        .transition(.scale.combined(with: .opacity))
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
        .accessibilityIdentifier("phrase-decoder-progress")
    }

    // MARK: - Results View

    private var resultsView: some View {
        PhraseDecoderResultsView(
            session: session,
            metrics: phraseDecoderService.calculateMetrics(session: session),
            onDismiss: {
                onComplete()
                dismiss()
            }
        )
    }

    // MARK: - Game Logic

    private func initializeChallenge() {
        guard let challenge = session.currentChallenge else { return }

        currentEnglishWords = challenge.scrambledEnglish
        currentKoreanWords = challenge.scrambledKorean
        draggedWordIndex = nil
        hoverTargetIndex = nil
        dragOffset = .zero
        validationResult = nil
        attempts = 0
        selectedLanguage = .english // Default to English

        DebugLogger.ui("🎮 PhraseDecoder: Initialized challenge \(challenge.challengeNumber)")
    }

    private func handleDrop(fromIndex: Int, toIndex: Int) {
        // Ignore drops if validation is showing
        guard validationResult == nil else { return }

        // Don't do anything if dropped on itself
        guard fromIndex != toIndex else {
            draggedWordIndex = nil
            return
        }

        // Bounds check to prevent crash
        guard fromIndex >= 0 && fromIndex < currentEnglishWords.count &&
              toIndex >= 0 && toIndex < currentEnglishWords.count else {
            DebugLogger.ui("⚠️ PhraseDecoder: Invalid indices - from: \(fromIndex), to: \(toIndex), count: \(currentEnglishWords.count)")
            draggedWordIndex = nil
            return
        }

        // Perform the move on both language arrays to keep them synchronized
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Remove items
            let englishWord = currentEnglishWords.remove(at: fromIndex)
            let koreanWord = currentKoreanWords.remove(at: fromIndex)

            // Calculate correct insertion index after removal
            // If moving down (toIndex > fromIndex), the index shifts down by 1 after removal
            let adjustedToIndex = toIndex > fromIndex ? toIndex - 1 : toIndex

            // Insert at adjusted index
            currentEnglishWords.insert(englishWord, at: adjustedToIndex)
            currentKoreanWords.insert(koreanWord, at: adjustedToIndex)

            draggedWordIndex = nil
        }

        DebugLogger.ui("🔄 PhraseDecoder: Moved word from position \(fromIndex) to \(toIndex)")
    }

    private func checkPhrase() {
        guard let challenge = session.currentChallenge else { return }

        attempts += 1

        let userWords = selectedLanguage == .english ? currentEnglishWords : currentKoreanWords

        let result = phraseDecoderService.validatePhrase(
            userWords: userWords,
            challenge: challenge,
            language: selectedLanguage
        )

        withAnimation {
            validationResult = result
        }

        DebugLogger.ui("✅ PhraseDecoder: Validation - \(result.isCorrect ? "Correct" : "Incorrect") (attempt \(attempts))")

        // Record completion if correct
        if result.isCorrect {
            let completedChallenge = CompletedDecoderChallenge(
                challenge: challenge,
                attempts: attempts,
                finalEnglishWords: currentEnglishWords,
                finalKoreanWords: currentKoreanWords,
                completionTime: Date()
            )
            session.completedChallenges.append(completedChallenge)
        }
    }

    private func tryAgain() {
        withAnimation {
            validationResult = nil
            draggedWordIndex = nil
            hoverTargetIndex = nil
            dragOffset = .zero
        }
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

// MARK: - Placeholder Box View

private struct PlaceholderBoxView: View {
    let position: Int

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle icon (dimmed)
            Image(systemName: "line.3.horizontal")
                .font(.body)
                .foregroundColor(.gray.opacity(0.3))
                .frame(width: 24)

            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary.opacity(0.5))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                )

            // Placeholder text
            Text("Drop here")
                .font(.headline)
                .foregroundColor(.accentColor.opacity(0.6))

            Spacer()

            // Drop zone indicator
            Image(systemName: "arrow.down.circle")
                .foregroundColor(.accentColor.opacity(0.6))
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundColor(.accentColor.opacity(0.4))
        )
        .accessibilityLabel("Drop zone at position \(position)")
    }
}

// MARK: - Word Box View

private struct WordBoxView: View {
    let word: String
    let position: Int
    let isDragging: Bool
    let isCorrect: Bool?
    let isDropTarget: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Drag handle icon (≡)
            Image(systemName: "line.3.horizontal")
                .font(.body)
                .foregroundColor(dragHandleColor)
                .frame(width: 24)
                .accessibilityHidden(true)

            // Position number
            Text("\(position)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )

            // Word text
            Text(word)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // Status indicator
            if let correct = isCorrect {
                Image(systemName: correct ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(correct ? .green : .gray.opacity(0.3))
                    .font(.title3)
            } else if isDropTarget {
                // Drop zone indicator
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
                    .opacity(0.6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: shadowColor, radius: shadowRadius, y: shadowOffset)
        .opacity(isDragging ? 0.5 : 1.0)
        .scaleEffect(isDropTarget ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        .accessibilityIdentifier("phrase-decoder-word-\(position)")
        .accessibilityLabel("\(word), position \(position)")
        .accessibilityHint("Drag to reorder")
    }

    private var dragHandleColor: Color {
        if isDragging {
            return .accentColor
        } else if isDropTarget {
            return .accentColor.opacity(0.8)
        } else {
            return .gray.opacity(0.5)
        }
    }

    private var backgroundColor: Color {
        if let correct = isCorrect, correct {
            return Color.green.opacity(0.1)
        } else if isDragging {
            return Color.accentColor.opacity(0.1)
        } else if isDropTarget {
            return Color.accentColor.opacity(0.05)
        } else {
            return Color(.secondarySystemGroupedBackground)
        }
    }

    private var borderColor: Color {
        if let correct = isCorrect, correct {
            return .green
        } else if isDragging {
            return .accentColor
        } else if isDropTarget {
            return .accentColor.opacity(0.6)
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var borderWidth: CGFloat {
        if isDragging {
            return 3
        } else if isDropTarget {
            return 2.5
        } else {
            return 1
        }
    }

    private var shadowColor: Color {
        if isDragging || isDropTarget {
            return .accentColor.opacity(0.3)
        } else {
            return .clear
        }
    }

    private var shadowRadius: CGFloat {
        if isDragging {
            return 8
        } else if isDropTarget {
            return 6
        } else {
            return 0
        }
    }

    private var shadowOffset: CGFloat {
        isDragging ? 4 : 2
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    @Previewable @State var session = PhraseDecoderSession(
        wordCount: 3,
        totalChallenges: 5,
        challenges: [
            DecoderChallenge(
                challengeNumber: 1,
                technique: TechniquePhrase(
                    id: "preview-technique",
                    english: "Outer Forearm Block",
                    koreanRomanized: "Bakat Palmok Makgi",
                    category: .blocks
                ),
                correctEnglish: ["Outer", "Forearm", "Block"],
                correctKorean: ["Bakat", "Palmok", "Makgi"],
                scrambledEnglish: ["Block", "Forearm", "Outer"],
                scrambledKorean: ["Makgi", "Palmok", "Bakat"]
            )
        ],
        startTime: Date()
    )

    let service = PhraseDecoderService(modelContext: modelContainer.mainContext)

    PhraseDecoderGameView(
        phraseDecoderService: service,
        session: $session,
        onComplete: {}
    )
}
