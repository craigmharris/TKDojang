import SwiftUI

/**
 * PhraseBuildingView.swift
 *
 * PURPOSE: Phrase Building learning mode - construct phrases by arranging word tiles
 *
 * FEATURES:
 * - Show English phrase target
 * - Provide shuffled Korean word tiles
 * - Drag-and-drop to arrange in correct order
 * - Immediate validation feedback
 *
 * LEARNING APPROACH:
 * - Apply vocabulary knowledge to phrase construction
 * - Learn word order in Korean
 * - Build from simple (2-word) to complex (6-word) phrases
 */

struct PhraseBuildingView: View {
    @ObservedObject var vocabularyService: VocabularyBuilderService

    @Environment(\.dismiss) private var dismiss

    @State private var phrases: [TerminologyPhrase] = []
    @State private var currentIndex = 0
    @State private var arrangedWords: [String] = []
    @State private var availableWords: [String] = []
    @State private var isCorrect: Bool?
    @State private var showingResults = false
    @State private var correctCount = 0

    // Configuration
    @State private var wordCount = 2
    @State private var phraseCount = 10
    @State private var isConfiguring = true

    var body: some View {
        ZStack {
            if isConfiguring {
                configurationView
            } else if showingResults {
                resultsView
            } else {
                buildingView
            }
        }
        .navigationTitle("Phrase Building")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!isConfiguring)
        .toolbar {
            if !isConfiguring && !showingResults {
                ToolbarItem(placement: .principal) {
                    Text("Phrase \(currentIndex + 1) of \(phrases.count)")
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
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)

                    Text("Phrase Building")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Arrange word tiles to construct Korean phrases")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)

                VStack(spacing: 24) {
                    // Word Count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phrase Length")
                            .font(.headline)

                        Picker("Words per phrase", selection: $wordCount) {
                            Text("2 words").tag(2)
                            Text("3 words").tag(3)
                            Text("4 words").tag(4)
                            Text("5 words").tag(5)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityIdentifier("phrase-word-count-picker")

                        difficultyNote
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Phrase Count
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Number of Phrases")
                            .font(.headline)

                        HStack {
                            Button {
                                phraseCount = max(5, phraseCount - 5)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(phraseCount <= 5)

                            Text("\(phraseCount)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 50)

                            Button {
                                phraseCount = min(20, phraseCount + 5)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            .disabled(phraseCount >= 20)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    startSession()
                } label: {
                    Text("Start Building")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .accessibilityIdentifier("phrase-start-session-button")

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var difficultyNote: some View {
        switch wordCount {
        case 2:
            Text("Beginner - Start with simple phrases")
        case 3:
            Text("Intermediate - Build confidence")
        case 4:
            Text("Advanced - Complex phrases")
        default:
            Text("Expert - Full terminology phrases")
        }
    }

    // MARK: - Building View

    private var buildingView: some View {
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

            ScrollView {
                if currentIndex < phrases.count {
                    let currentPhrase = phrases[currentIndex]

                    VStack(spacing: 32) {
                        // Target phrase
                        VStack(spacing: 8) {
                            Text("Build this phrase:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(currentPhrase.english)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        // Arranged words area
                        VStack(spacing: 12) {
                            Text("Your answer:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack(spacing: 8) {
                                ForEach(arrangedWords, id: \.self) { word in
                                    WordTile(
                                        word: word,
                                        isPlaced: true,
                                        isCorrect: isCorrect
                                    ) {
                                        removeWord(word)
                                    }
                                }

                                if arrangedWords.count < currentPhrase.wordCount {
                                    EmptySlot()
                                }
                            }
                            .frame(minHeight: 60)
                        }
                        .padding(.horizontal)

                        Divider()

                        // Available words
                        VStack(spacing: 12) {
                            Text("Available words:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(availableWords, id: \.self) { word in
                                    WordTile(
                                        word: word,
                                        isPlaced: false,
                                        isCorrect: nil
                                    ) {
                                        addWord(word)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Check answer button
                        if arrangedWords.count == currentPhrase.wordCount && isCorrect == nil {
                            Button {
                                checkAnswer()
                            } label: {
                                Text("Check Answer")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .accessibilityIdentifier("phrase-check-answer-button")
                        }

                        // Feedback
                        if let correct = isCorrect {
                            HStack(spacing: 12) {
                                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(correct ? .green : .red)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(correct ? "Correct!" : "Not quite...")
                                        .font(.headline)
                                        .foregroundColor(correct ? .green : .red)

                                    if !correct {
                                        Text("Correct: \(currentPhrase.romanized)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(correct ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            )
                            .padding(.horizontal)
                        }

                        // Next button
                        if isCorrect != nil {
                            Button {
                                nextPhrase()
                            } label: {
                                Text("Next Phrase")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 24)
                            .accessibilityIdentifier("phrase-next-button")
                        }
                    }
                }
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

                Text("\(correctCount) out of \(phrases.count) correct")
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
            }

            Spacer()
        }
    }

    // MARK: - Helper Methods

    private var progress: CGFloat {
        guard !phrases.isEmpty else { return 0 }
        return CGFloat(currentIndex) / CGFloat(phrases.count)
    }

    private var accuracyPercentage: Int {
        guard !phrases.isEmpty else { return 0 }
        return Int((Double(correctCount) / Double(phrases.count)) * 100)
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
        Task {
            do {
                phrases = try vocabularyService.getPhrasesForBuilding(
                    wordCount: wordCount,
                    maxPhrases: phraseCount
                )

                if phrases.isEmpty {
                    // No phrases available for this word count
                    print("No phrases found for \(wordCount) words")
                    return
                }

                currentIndex = 0
                correctCount = 0
                isConfiguring = false
                loadCurrentPhrase()
            } catch {
                print("Error loading phrases: \(error)")
            }
        }
    }

    private func loadCurrentPhrase() {
        guard currentIndex < phrases.count else { return }

        let phrase = phrases[currentIndex]
        availableWords = phrase.words.shuffled()
        arrangedWords = []
        isCorrect = nil
    }

    private func addWord(_ word: String) {
        guard !arrangedWords.contains(word) else { return }
        arrangedWords.append(word)
        availableWords.removeAll { $0 == word }
    }

    private func removeWord(_ word: String) {
        arrangedWords.removeAll { $0 == word }
        availableWords.append(word)
    }

    private func checkAnswer() {
        let userAnswer = arrangedWords.joined(separator: " ")
        let correctAnswer = phrases[currentIndex].romanized

        isCorrect = userAnswer == correctAnswer
        if isCorrect == true {
            correctCount += 1
        }
    }

    private func nextPhrase() {
        if currentIndex < phrases.count - 1 {
            currentIndex += 1
            loadCurrentPhrase()
        } else {
            showingResults = true
        }
    }

    private func restartSession() {
        isConfiguring = true
        showingResults = false
        currentIndex = 0
        correctCount = 0
    }
}

// MARK: - Components

private struct WordTile: View {
    let word: String
    let isPlaced: Bool
    let isCorrect: Bool?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .foregroundColor(textColor)
                .cornerRadius(8)
        }
    }

    private var backgroundColor: Color {
        if let correct = isCorrect {
            return correct ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        }
        return isPlaced ? Color.accentColor.opacity(0.2) : Color(.systemGray5)
    }

    private var textColor: Color {
        isPlaced ? .accentColor : .primary
    }
}

private struct EmptySlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
            .foregroundColor(.gray)
            .frame(width: 80, height: 44)
    }
}

// FlowLayout is defined in TechniqueDetailView.swift and reused here
