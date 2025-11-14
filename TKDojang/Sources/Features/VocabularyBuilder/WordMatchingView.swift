import SwiftUI
import SwiftData

/**
 * WordMatchingView.swift
 *
 * PURPOSE: Word Matching learning mode - match English words to Korean romanized equivalents
 *
 * FEATURES:
 * - Show English word, present 4 Korean options
 * - Immediate feedback (correct/incorrect)
 * - Progress tracking through session
 * - Configurable difficulty and word count
 *
 * LEARNING APPROACH:
 * - Start with most frequent words (easier)
 * - Build vocabulary recognition
 * - Foundation for phrase construction
 */

struct WordMatchingView: View {
    @ObservedObject var vocabularyService: VocabularyBuilderService
    let words: [VocabularyWord]

    @Environment(\.dismiss) private var dismiss

    @State private var sessionWords: [VocabularyWord] = []
    @State private var currentIndex = 0
    @State private var currentAnswerOptions: [String] = []  // Cache options for current question
    @State private var selectedAnswer: String?
    @State private var correctAnswers = 0
    @State private var showingResults = false
    @State private var difficulty: WordDifficulty = .beginner
    @State private var wordCount = 10
    @State private var isConfiguring = true

    var body: some View {
        ZStack {
            if isConfiguring {
                configurationView
            } else if showingResults {
                resultsView
            } else {
                matchingView
            }
        }
        .navigationTitle("Word Matching")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!isConfiguring)
        .toolbar {
            if !isConfiguring && !showingResults {
                ToolbarItem(placement: .principal) {
                    Text("Word \(currentIndex + 1) of \(sessionWords.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Configuration View

    private var configurationView: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)

                    Text("Word Matching")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Match English words to their Korean romanized equivalents")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 24) {
                    // Word Count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Number of Words")
                            .font(.headline)

                        HStack {
                            Button {
                                wordCount = max(5, wordCount - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(wordCount <= 5)
                            .accessibilityIdentifier("vocabulary-decrease-count")

                            Text("\(wordCount)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 50)
                                .accessibilityIdentifier("vocabulary-count-display")

                            Button {
                                wordCount = min(words.count, wordCount + 5)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(wordCount >= words.count)
                            .accessibilityIdentifier("vocabulary-increase-count")
                        }

                        Text("\(words.count) words available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Difficulty
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Difficulty")
                            .font(.headline)

                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(WordDifficulty.allCases, id: \.self) { level in
                                Text(level.rawValue).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("vocabulary-difficulty-picker")

                        difficultyDescription
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    startSession()
                } label: {
                    Text("Start Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .accessibilityIdentifier("vocabulary-start-session-button")

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var difficultyDescription: some View {
        switch difficulty {
        case .beginner:
            Text("Most common words (Block, Stance, Kick, etc.)")
        case .intermediate:
            Text("Medium frequency words")
        case .advanced:
            Text("Random selection from all words")
        }
    }

    // MARK: - Matching View

    private var matchingView: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 4)

            Spacer()

            if currentIndex < sessionWords.count {
                let currentWord = sessionWords[currentIndex]

                VStack(spacing: 48) {
                    // English word to match
                    VStack(spacing: 16) {
                        Text("Match this word:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(currentWord.english)
                            .font(.system(size: 44, weight: .bold))
                            .multilineTextAlignment(.center)
                    }

                    // Answer options
                    VStack(spacing: 16) {
                        ForEach(currentAnswerOptions, id: \.self) { option in
                            answerButton(option: option, correct: currentWord.romanized)
                        }
                    }
                    .padding(.horizontal, 24)
                    .onAppear {
                        // Generate options once when question appears
                        if currentAnswerOptions.isEmpty {
                            currentAnswerOptions = answerOptions(for: currentWord)
                        }
                    }
                }
            }

            Spacer()
        }
    }

    private func answerButton(option: String, correct: String) -> some View {
        Button {
            selectAnswer(option, correct: correct)
        } label: {
            HStack {
                Text(option)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(buttonTextColor(for: option, correct: correct))

                Spacer()

                if selectedAnswer != nil {
                    if option == correct {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if option == selectedAnswer {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .background(buttonBackground(for: option, correct: correct))
            .cornerRadius(12)
        }
        .disabled(selectedAnswer != nil)
        .accessibilityIdentifier("vocabulary-answer-\(option)")
    }

    private func buttonTextColor(for option: String, correct: String) -> Color {
        guard let selected = selectedAnswer else { return .primary }

        if option == correct {
            return .white
        } else if option == selected {
            return .white
        }
        return .secondary
    }

    private func buttonBackground(for option: String, correct: String) -> some View {
        Group {
            if let selected = selectedAnswer {
                if option == correct {
                    Color.green
                } else if option == selected {
                    Color.red
                } else {
                    Color(.systemGray5)
                }
            } else {
                Color(.systemGray6)
            }
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: resultIcon)
                    .font(.system(size: 80))
                    .foregroundColor(resultColor)

                Text("Session Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(correctAnswers) out of \(sessionWords.count) correct")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text("\(accuracyPercentage)% accuracy")
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }

            VStack(spacing: 16) {
                Button {
                    restartSession()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .accessibilityIdentifier("vocabulary-try-again-button")

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .accessibilityIdentifier("vocabulary-done-button")
            }

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private var progress: CGFloat {
        guard !sessionWords.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(sessionWords.count)
    }

    private var accuracyPercentage: Int {
        guard !sessionWords.isEmpty else { return 0 }
        return Int((Double(correctAnswers) / Double(sessionWords.count)) * 100)
    }

    private var resultIcon: String {
        if accuracyPercentage >= 90 { return "star.fill" }
        if accuracyPercentage >= 70 { return "hand.thumbsup.fill" }
        return "checkmark.circle.fill"
    }

    private var resultColor: Color {
        if accuracyPercentage >= 90 { return .yellow }
        if accuracyPercentage >= 70 { return .green }
        return .blue
    }

    private func startSession() {
        do {
            sessionWords = try vocabularyService.getWordsForMatching(count: wordCount, difficulty: difficulty)
            currentIndex = 0
            correctAnswers = 0
            selectedAnswer = nil
            isConfiguring = false

            // Generate options for first question
            if let firstWord = sessionWords.first {
                currentAnswerOptions = answerOptions(for: firstWord)
            }
        } catch {
            // Handle error
            print("Error loading words: \(error)")
        }
    }

    private func restartSession() {
        isConfiguring = true
        showingResults = false
        currentIndex = 0
        correctAnswers = 0
        selectedAnswer = nil
    }

    private func answerOptions(for word: VocabularyWord) -> [String] {
        var options = [word.romanized]

        // Add 3 random incorrect options
        let otherWords = sessionWords.filter { $0.id != word.id }.shuffled()
        for otherWord in otherWords.prefix(3) {
            options.append(otherWord.romanized)
        }

        return options.shuffled()
    }

    private func selectAnswer(_ answer: String, correct: String) {
        selectedAnswer = answer

        if answer == correct {
            correctAnswers += 1
        }

        // Move to next question after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if currentIndex < sessionWords.count - 1 {
                currentIndex += 1
                selectedAnswer = nil

                // Generate new options for next question
                let nextWord = sessionWords[currentIndex]
                currentAnswerOptions = answerOptions(for: nextWord)
            } else {
                showingResults = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let service = VocabularyBuilderService(modelContext: modelContainer.mainContext)
    let sampleWords = [
        VocabularyWord(english: "Block", romanized: "Makgi", hangul: nil, frequency: 27),
        VocabularyWord(english: "Kick", romanized: "Chagi", hangul: nil, frequency: 14),
        VocabularyWord(english: "Punch", romanized: "Jirugi", hangul: nil, frequency: 9)
    ]

    NavigationStack {
        WordMatchingView(vocabularyService: service, words: sampleWords)
    }
}
