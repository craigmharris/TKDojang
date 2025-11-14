import SwiftUI
import SwiftData

/**
 * PhraseDecoderConfigurationView.swift
 *
 * PURPOSE: Configuration screen for Phrase Decoder game mode
 *
 * FEATURES:
 * - Select phrase length (2-5 words)
 * - Configure session count (5-15 phrases)
 * - Preview session parameters
 * - Help button with feature tour support
 *
 * ARCHITECTURE:
 * - Reuses PhraseLengthPickerComponent from Slot Builder
 * - Follows standard configuration pattern
 */

struct PhraseDecoderConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var phraseDecoderService: PhraseDecoderService

    @State private var phraseLength: Int = 3 // Start with intermediate
    @State private var phraseCount: Int = 10
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingGame = false
    @State private var currentSession: PhraseDecoderSession?
    @State private var isGeneratingSession = false // Prevent double-calls

    init(modelContext: ModelContext) {
        _phraseDecoderService = StateObject(wrappedValue: PhraseDecoderService(modelContext: modelContext))
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
            .navigationTitle("Phrase Decoder Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("phrase-decoder-cancel-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Show help tour
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("phrase-decoder-help-button")
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                if currentSession != nil {
                    PhraseDecoderGameView(
                        phraseDecoderService: phraseDecoderService,
                        session: Binding(
                            get: { currentSession! },
                            set: { currentSession = $0 }
                        ),
                        onComplete: {
                            showingGame = false
                        }
                    )
                    .onAppear {
                        DebugLogger.ui("✅ PhraseDecoder Config: GAME VIEW DISPLAYED - session loaded successfully")
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Error: No session available")
                            .foregroundColor(.red)
                        Button("Close") {
                            showingGame = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .onAppear {
                        DebugLogger.ui("❌ PhraseDecoder Config: ERROR VIEW DISPLAYED - currentSession is nil despite showingGame = true")
                    }
                }
            }
            .task {
                await loadTechniques()
            }
    }

    // MARK: - Header

    private var configurationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .accessibilityHidden(true)

            Text("Decode Real Technique Names")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Unscramble authentic Korean Taekwondo technique names. Learn the exact terminology used in training.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
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
        .accessibilityIdentifier("phrase-decoder-phrase-length-section")
    }

    private var sessionCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Number of Phrases")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack {
                Button {
                    phraseCount = max(5, phraseCount - 5)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                }
                .disabled(phraseCount <= 5)
                .accessibilityIdentifier("phrase-decoder-decrease-count")

                Text("\(phraseCount)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                    .accessibilityIdentifier("phrase-decoder-count-display")

                Button {
                    phraseCount = min(15, phraseCount + 5)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(phraseCount >= 15)
                .accessibilityIdentifier("phrase-decoder-increase-count")
            }

            Text("5-15 phrases recommended")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("phrase-decoder-session-count-section")
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
        .accessibilityIdentifier("phrase-decoder-session-preview")
    }

    private func previewRow(icon: String, label: String, value: String) -> some View {
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
    }

    // MARK: - Start Button

    private var startGameButton: some View {
        Button(action: startSession) {
            HStack {
                Image(systemName: "play.fill")
                Text(isLoading ? "Loading..." : isGeneratingSession ? "Starting..." : "Start Session")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading || isGeneratingSession || errorMessage != nil ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading || isGeneratingSession || errorMessage != nil)
        .accessibilityIdentifier("phrase-decoder-start-button")
    }

    // MARK: - Helpers

    private var estimatedTime: String {
        let minutes = phraseCount * 1 // ~1 min per phrase
        return "~\(minutes) min"
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

    private func loadTechniques() async {
        isLoading = true
        errorMessage = nil

        do {
            try await MainActor.run {
                try phraseDecoderService.loadTechniques()
            }

            isLoading = false
            DebugLogger.data("✅ PhraseDecoder Config: Loaded technique phrases")

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            DebugLogger.data("❌ PhraseDecoder Config: Failed to load techniques - \(error)")
        }
    }

    private func startSession() {
        // Prevent double-calls (e.g., double-tap on button)
        guard !isGeneratingSession else {
            DebugLogger.ui("⚠️ PhraseDecoder Config: Already generating session, ignoring duplicate call")
            return
        }

        isGeneratingSession = true
        DebugLogger.ui("🎮 Starting Phrase Decoder session: \(phraseCount) phrases of \(phraseLength) words")

        // Retry logic to handle race conditions with data loading
        Task {
            var lastError: Error?
            let maxAttempts = 3

            for attempt in 1...maxAttempts {
                do {
                    DebugLogger.ui("🔄 PhraseDecoder Config: Session generation attempt \(attempt)/\(maxAttempts)")

                    let session = try phraseDecoderService.generateSession(
                        wordCount: phraseLength,
                        phraseCount: phraseCount
                    )

                    DebugLogger.ui("✅ PhraseDecoder Config: Session generated - \(session.challenges.count) challenges")

                    // Set session state first
                    await MainActor.run {
                        currentSession = session
                        DebugLogger.ui("📝 PhraseDecoder Config: currentSession set")
                    }

                    // CRITICAL: Delay showing game to ensure state propagates
                    // fullScreenCover evaluates immediately when showingGame changes
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

                    await MainActor.run {
                        showingGame = true
                        isGeneratingSession = false // Reset flag on success
                        DebugLogger.ui("🎬 PhraseDecoder Config: showingGame = true (after state propagation)")
                    }

                    return // Success - exit retry loop

                } catch {
                    lastError = error
                    DebugLogger.data("⚠️ PhraseDecoder Config: Attempt \(attempt) failed - \(error.localizedDescription)")

                    // If not the last attempt, wait before retrying
                    if attempt < maxAttempts {
                        DebugLogger.ui("⏱️ PhraseDecoder Config: Waiting 0.25s before retry...")
                        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                    }
                }
            }

            // All attempts failed - show error
            await MainActor.run {
                errorMessage = lastError?.localizedDescription ?? "Failed to generate session after \(maxAttempts) attempts"
                isGeneratingSession = false // Reset flag on failure
                DebugLogger.data("❌ PhraseDecoder Config: All \(maxAttempts) attempts failed - \(errorMessage ?? "unknown error")")
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

    PhraseDecoderConfigurationView(modelContext: modelContainer.mainContext)
}
