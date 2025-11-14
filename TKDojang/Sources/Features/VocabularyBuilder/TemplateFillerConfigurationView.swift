import SwiftUI
import SwiftData

/**
 * TemplateFillerConfigurationView.swift
 *
 * PURPOSE: Configuration screen for Template Filler game mode
 *
 * FEATURES:
 * - Select phrase length (2-5 words)
 * - Configure session count (5-15 phrases)
 * - Preview blank count based on phrase length
 * - Help button with feature tour support
 */

struct TemplateFillerConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var templateFillerService: TemplateFillerService

    @State private var phraseLength: Int = 3
    @State private var phraseCount: Int = 10
    @State private var blanksPerPhrase: Int = 1
    @State private var studyDirection: StudyDirection = .englishToKorean
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingGame = false
    @State private var currentSession: TemplateFillerSession?
    @State private var isGeneratingSession = false // Prevent double-calls

    init(modelContext: ModelContext) {
        _templateFillerService = StateObject(wrappedValue: TemplateFillerService(modelContext: modelContext))
    }

    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    configurationHeader

                    if isLoading {
                        loadingView
                    } else {
                        VStack(spacing: 20) {
                            phraseLengthSection
                            blanksPerPhraseSection
                            studyDirectionSection
                            sessionCountSection
                        }

                        sessionPreviewSection

                        if let error = errorMessage {
                            errorMessageView(error)
                        }

                        startGameButton
                    }
                }
                .padding()
            }
            .navigationTitle("Template Filler Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("template-filler-cancel-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Show help tour
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("template-filler-help-button")
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                if currentSession != nil {
                    TemplateFillerGameView(
                        templateFillerService: templateFillerService,
                        session: Binding(
                            get: { currentSession! },
                            set: { currentSession = $0 }
                        ),
                        onComplete: {
                            showingGame = false
                        }
                    )
                    .onAppear {
                        DebugLogger.ui("✅ TemplateFiller Config: GAME VIEW DISPLAYED - session loaded successfully")
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
                        DebugLogger.ui("❌ TemplateFiller Config: ERROR VIEW DISPLAYED - currentSession is nil despite showingGame = true")
                    }
                }
            }
            .task {
                await loadTechniques()
            }
    }

    // MARK: - Components

    private var configurationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .accessibilityHidden(true)

            Text("Fill in the Blanks")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Complete real technique names by selecting the correct word for each blank. Korean reference phrase shown for learning.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading techniques...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var phraseLengthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhraseLengthPickerComponent(
                phraseLength: $phraseLength
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var blanksPerPhraseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blanks per Phrase")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 16) {
                ForEach(1...3, id: \.self) { count in
                    Button(action: {
                        blanksPerPhrase = count
                    }) {
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(count == 1 ? "blank" : "blanks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(blanksPerPhrase == count ? Color.green : Color(.tertiarySystemGroupedBackground))
                        .foregroundColor(blanksPerPhrase == count ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .accessibilityIdentifier("template-filler-blanks-\(count)-button")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private var studyDirectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Direction")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 12) {
                ForEach(StudyDirection.allCases, id: \.self) { direction in
                    Button(action: {
                        studyDirection = direction
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(direction.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(direction.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if studyDirection == direction {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(studyDirection == direction ? Color.green.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                    .foregroundColor(.primary)
                    .accessibilityIdentifier("template-filler-direction-\(direction.rawValue)-button")
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
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
    }

    private var sessionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Preview")
                .font(.headline)

            VStack(spacing: 8) {
                previewRow(icon: "number.square", label: "Phrase Length", value: "\(phraseLength) words")
                previewRow(icon: "square.dotted", label: "Blanks per Phrase", value: "\(blanksPerPhrase)")
                previewRow(icon: "arrow.left.arrow.right", label: "Direction", value: studyDirection.displayName)
                previewRow(icon: "list.number", label: "Total Phrases", value: "\(phraseCount)")
                previewRow(icon: "gauge.medium", label: "Difficulty", value: difficultyLabel(for: phraseLength, blanks: blanksPerPhrase))
                previewRow(icon: "clock", label: "Est. Time", value: "~\(phraseCount) min")
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func previewRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

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
        .accessibilityIdentifier("template-filler-start-button")
    }

    // MARK: - Helpers

    private func difficultyLabel(for length: Int, blanks: Int) -> String {
        let baseDifficulty: String
        switch length {
        case 2: baseDifficulty = "Beginner"
        case 3: baseDifficulty = "Intermediate"
        case 4: baseDifficulty = "Advanced"
        case 5: baseDifficulty = "Expert"
        default: baseDifficulty = "Unknown"
        }

        // Add modifier for extra blanks
        if blanks >= 3 {
            return "\(baseDifficulty)+"
        }
        return baseDifficulty
    }

    private func loadTechniques() async {
        isLoading = true
        errorMessage = nil

        do {
            try await MainActor.run {
                try templateFillerService.loadTechniques()
            }

            isLoading = false
            DebugLogger.data("✅ TemplateFiller Config: Loaded technique phrases")

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            DebugLogger.data("❌ TemplateFiller Config: Failed to load techniques - \(error)")
        }
    }

    private func startSession() {
        // Prevent double-calls (e.g., double-tap on button)
        guard !isGeneratingSession else {
            DebugLogger.ui("⚠️ TemplateFiller Config: Already generating session, ignoring duplicate call")
            return
        }

        isGeneratingSession = true
        DebugLogger.ui("🎮 Starting Template Filler session: \(phraseCount) templates of \(phraseLength) words, \(blanksPerPhrase) blanks, \(studyDirection.displayName)")

        // Retry logic to handle race conditions with data loading
        Task {
            var lastError: Error?
            let maxAttempts = 3

            for attempt in 1...maxAttempts {
                do {
                    DebugLogger.ui("🔄 TemplateFiller Config: Session generation attempt \(attempt)/\(maxAttempts)")

                    let session = try templateFillerService.generateSession(
                        wordCount: phraseLength,
                        phraseCount: phraseCount,
                        blanksPerPhrase: blanksPerPhrase,
                        direction: studyDirection
                    )

                    DebugLogger.ui("✅ TemplateFiller Config: Session generated - \(session.challenges.count) challenges")

                    // Set session state first
                    await MainActor.run {
                        currentSession = session
                        DebugLogger.ui("📝 TemplateFiller Config: currentSession set")
                    }

                    // CRITICAL: Delay showing game to ensure state propagates
                    // fullScreenCover evaluates immediately when showingGame changes
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

                    await MainActor.run {
                        showingGame = true
                        isGeneratingSession = false // Reset flag on success
                        DebugLogger.ui("🎬 TemplateFiller Config: showingGame = true (after state propagation)")
                    }

                    return // Success - exit retry loop

                } catch {
                    lastError = error
                    DebugLogger.data("⚠️ TemplateFiller Config: Attempt \(attempt) failed - \(error.localizedDescription)")

                    // If not the last attempt, wait before retrying
                    if attempt < maxAttempts {
                        DebugLogger.ui("⏱️ TemplateFiller Config: Waiting 0.25s before retry...")
                        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                    }
                }
            }

            // All attempts failed - show error
            await MainActor.run {
                errorMessage = lastError?.localizedDescription ?? "Failed to generate session after \(maxAttempts) attempts"
                isGeneratingSession = false // Reset flag on failure
                DebugLogger.data("❌ TemplateFiller Config: All \(maxAttempts) attempts failed - \(errorMessage ?? "unknown error")")
            }
        }
    }
}

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    TemplateFillerConfigurationView(modelContext: modelContainer.mainContext)
}
