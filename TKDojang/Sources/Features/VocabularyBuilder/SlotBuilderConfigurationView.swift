import SwiftUI
import SwiftData

/**
 * SlotBuilderConfigurationView.swift
 *
 * PURPOSE: Configuration screen for Slot Builder game mode
 *
 * FEATURES:
 * - Select phrase length (2-5 words) with difficulty indicators
 * - Configure session count (5-20 phrases)
 * - Preview session parameters before starting
 * - Help button with feature tour support
 * - Automatic vocabulary loading and validation
 *
 * ARCHITECTURE:
 * - Composes 2 extracted components (PhraseLengthPickerComponent, SessionCountPickerComponent)
 * - Components reusable in tours with isDemo parameter
 * - Follows MultipleChoiceConfiguration pattern for consistency
 * - Integrates with SlotBuilderService for session generation
 */

struct SlotBuilderConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var slotBuilderService: SlotBuilderService
    @StateObject private var vocabularyService: VocabularyBuilderService

    @State private var phraseLength: Int = 2 // Start with beginner difficulty
    @State private var phraseCount: Int = 10
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingGame = false
    @State private var currentSession: SlotBuilderSession?
    @State private var vocabularyWords: [VocabularyWord] = []

    init(modelContext: ModelContext) {
        _slotBuilderService = StateObject(wrappedValue: SlotBuilderService(modelContext: modelContext))
        _vocabularyService = StateObject(wrappedValue: VocabularyBuilderService(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Header
                    configurationHeader

                    if isLoading {
                        loadingView
                    } else {
                        // Configuration Options
                        VStack(spacing: 20) {
                            phraseLengthSection
                            sessionCountSection
                        }

                        // Session Preview
                        sessionPreviewSection

                        // Error message if any
                        if let error = errorMessage {
                            errorMessageView(error)
                        }

                        // Start Button
                        startGameButton
                    }
                }
                .padding()
            }
            .navigationTitle("Slot Builder Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("slot-builder-cancel-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Show help tour in future phase
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("slot-builder-help-button")
                    .accessibilityLabel("Show slot builder tour")
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                let _ = DebugLogger.ui("🎬 fullScreenCover evaluating - currentSession is \(currentSession == nil ? "NIL" : "SET")")

                if currentSession != nil {
                    SlotBuilderGameView(
                        slotBuilderService: slotBuilderService,
                        session: Binding(
                            get: { currentSession! },
                            set: { currentSession = $0 }
                        ),
                        onComplete: {
                            showingGame = false
                        }
                    )
                } else {
                    VStack(spacing: 16) {
                        Text("Error: No session available")
                            .foregroundColor(.red)
                            .font(.headline)

                        Button("Close") {
                            showingGame = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .task {
                await loadVocabulary()
            }
    }

    // MARK: - Header

    private var configurationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Build Phrases Slot-by-Slot")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Learn phrase grammar by constructing techniques word-by-word with guided category selection.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Slot Builder: Build phrases slot-by-slot. Learn phrase grammar by constructing techniques word-by-word with guided category selection.")
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading vocabulary...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Configuration Sections

    private var phraseLengthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhraseLengthPickerComponent(
                phraseLength: $phraseLength
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("slot-builder-phrase-length-section")
    }

    private var sessionCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SessionCountPickerComponent(
                phraseCount: $phraseCount
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("slot-builder-session-count-section")
    }

    // MARK: - Session Preview

    private var sessionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Preview")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 8) {
                previewRow(
                    icon: "number.square",
                    label: "Phrase Length",
                    value: "\(phraseLength) words"
                )

                previewRow(
                    icon: "list.number",
                    label: "Total Phrases",
                    value: "\(phraseCount)"
                )

                previewRow(
                    icon: "gauge.medium",
                    label: "Difficulty",
                    value: difficultyLabel(for: phraseLength)
                )

                previewRow(
                    icon: "clock",
                    label: "Est. Time",
                    value: estimatedTime
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session preview: \(phraseCount) phrases of \(phraseLength) words, \(difficultyLabel(for: phraseLength)) difficulty, estimated time \(estimatedTime)")
        .accessibilityIdentifier("slot-builder-session-preview")
    }

    private func previewRow(icon: String, label: String, value: String) -> some View {
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
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Error View

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(message)")
    }

    // MARK: - Start Button

    private var startGameButton: some View {
        Button(action: startSession) {
            HStack {
                Image(systemName: "play.fill")
                Text(isLoading ? "Loading..." : "Start Session")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading || errorMessage != nil ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading || errorMessage != nil || vocabularyWords.isEmpty)
        .accessibilityIdentifier("slot-builder-start-button")
        .accessibilityLabel("Start slot builder session")
        .accessibilityHint("\(phraseCount) phrases of \(phraseLength) words")
    }

    // MARK: - Helpers

    private var estimatedTime: String {
        let minutes = phraseCount * 1 // ~1 minute per phrase
        return minutes <= 10 ? "~\(minutes) min" : "~\(minutes) min"
    }

    private func difficultyLabel(for length: Int) -> String {
        switch length {
        case 2: return "Beginner"
        case 3: return "Intermediate"
        case 4: return "Advanced"
        case 5: return "Expert"
        default: return "Unknown"
        }
    }

    // MARK: - Data Loading

    private func loadVocabulary() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load vocabulary words
            vocabularyWords = try vocabularyService.loadVocabularyWords()

            // Load and categorize for slot builder
            try await MainActor.run {
                try slotBuilderService.loadVocabulary()
            }

            // Validate sufficient words for starting phrase length
            let hasSufficientWords = slotBuilderService.hasSufficientWords(for: phraseLength)
            if !hasSufficientWords {
                errorMessage = "Insufficient categorized words for \(phraseLength)-word phrases"
            }

            isLoading = false
            DebugLogger.data("✅ SlotBuilder Config: Loaded \(vocabularyWords.count) words")

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            DebugLogger.data("❌ SlotBuilder Config: Failed to load vocabulary - \(error)")
        }
    }

    private func startSession() {
        DebugLogger.ui("🎮 Starting Slot Builder session: \(phraseCount) phrases of \(phraseLength) words")

        do {
            // Generate session
            let session = try slotBuilderService.generateSession(
                wordCount: phraseLength,
                phraseCount: phraseCount
            )

            DebugLogger.ui("✅ SlotBuilder Config: Session generated successfully - \(session.challenges.count) challenges")

            // Set session first, then show game on next run loop
            currentSession = session
            DebugLogger.ui("📝 SlotBuilder Config: currentSession set, showing game")

            DispatchQueue.main.async {
                DebugLogger.ui("🎬 SlotBuilder Config: Setting showingGame = true")
                showingGame = true
            }

        } catch {
            errorMessage = error.localizedDescription
            DebugLogger.data("❌ SlotBuilder Config: Session generation failed - \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    SlotBuilderConfigurationView(modelContext: modelContainer.mainContext)
}
