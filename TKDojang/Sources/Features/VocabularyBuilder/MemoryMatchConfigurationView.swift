import SwiftUI
import SwiftData

/**
 * MemoryMatchConfigurationView.swift
 *
 * PURPOSE: Configuration screen for Memory Match game mode
 *
 * FEATURES:
 * - Select difficulty (number of pairs: 6, 8, 10, 12)
 * - Preview grid size and estimated time
 * - Help button with feature tour support
 * - Automatic vocabulary loading and validation
 *
 * ARCHITECTURE:
 * - Follows SlotBuilderConfiguration pattern for consistency
 * - Integrates with MemoryMatchService for session generation
 */

struct MemoryMatchConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var memoryMatchService: MemoryMatchService
    @StateObject private var vocabularyService: VocabularyBuilderService

    @State private var pairCount: Int = 8 // Default: medium difficulty
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingGame = false
    @State private var currentSession: MemoryMatchSession?
    @State private var vocabularyWords: [VocabularyWord] = []
    @State private var userBeltLevel: BeltLevel? = nil // Will be loaded from active profile
    @State private var isGeneratingSession = false // Prevent double-calls

    init(modelContext: ModelContext) {
        _memoryMatchService = StateObject(wrappedValue: MemoryMatchService(modelContext: modelContext))
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
                            difficultySection
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
            .navigationTitle("Memory Match Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("memory-match-cancel-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // TODO: Show help tour in future phase
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("memory-match-help-button")
                    .accessibilityLabel("Show memory match tour")
                }
            }
            .fullScreenCover(isPresented: $showingGame) {
                if currentSession != nil && userBeltLevel != nil {
                    MemoryMatchGameView(
                        memoryMatchService: memoryMatchService,
                        session: Binding(
                            get: { currentSession! },
                            set: { currentSession = $0 }
                        ),
                        userBeltLevel: userBeltLevel!,
                        onComplete: {
                            showingGame = false
                        }
                    )
                    .onAppear {
                        DebugLogger.ui("✅ MemoryMatch: Game view appeared successfully")
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Error: \(currentSession == nil ? "No session available" : "No belt level found")")
                            .foregroundColor(.red)
                            .font(.headline)

                        Button("Close") {
                            showingGame = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .onAppear {
                        DebugLogger.ui("❌ MemoryMatch: ERROR VIEW appeared - session=\(currentSession != nil ? "SET" : "NIL"), beltLevel=\(userBeltLevel != nil ? "SET" : "NIL")")
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
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .accessibilityHidden(true)

            Text("Match Word Pairs")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Flip cards to match English words with their Korean romanised equivalents.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Memory Match: Match word pairs. Flip cards to match English words with their Korean romanised equivalents.")
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

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Difficulty")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text("Number of word pairs to match. More pairs = larger grid.")
                .font(.caption)
                .foregroundColor(.secondary)

            // Difficulty options
            VStack(spacing: 12) {
                ForEach([6, 8, 10, 12], id: \.self) { count in
                    difficultyOption(pairCount: count)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("memory-match-difficulty-section")
    }

    private func difficultyOption(pairCount count: Int) -> some View {
        Button(action: {
            pairCount = count
        }) {
            HStack {
                // Selection indicator
                Image(systemName: pairCount == count ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(pairCount == count ? .accentColor : .secondary)
                    .accessibilityHidden(true)

                // Pair info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(count) Pairs")
                        .font(.body)
                        .fontWeight(pairCount == count ? .semibold : .regular)
                        .foregroundColor(.primary)

                    Text("\(count * 2) cards • \(gridSize(for: count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Difficulty badge
                Text(difficultyLabel(for: count))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: count).opacity(0.2))
                    .foregroundColor(difficultyColor(for: count))
                    .cornerRadius(6)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        pairCount == count ? Color.accentColor : Color.secondary.opacity(0.3),
                        lineWidth: pairCount == count ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("memory-match-difficulty-\(count)")
        .accessibilityLabel("\(count) pairs, \(difficultyLabel(for: count)) difficulty")
        .accessibilityAddTraits(pairCount == count ? .isSelected : [])
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
                    label: "Pairs to Match",
                    value: "\(pairCount)"
                )

                previewRow(
                    icon: "square.grid.3x3",
                    label: "Grid Size",
                    value: gridSize(for: pairCount)
                )

                previewRow(
                    icon: "gauge.medium",
                    label: "Difficulty",
                    value: difficultyLabel(for: pairCount)
                )

                previewRow(
                    icon: "clock",
                    label: "Est. Time",
                    value: estimatedTime(for: pairCount)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Session preview: \(pairCount) pairs, \(gridSize(for: pairCount)) grid, \(difficultyLabel(for: pairCount)) difficulty, estimated time \(estimatedTime(for: pairCount))")
        .accessibilityIdentifier("memory-match-session-preview")
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
                Text(isLoading ? "Loading..." : isGeneratingSession ? "Starting..." : "Start Game")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading || isGeneratingSession || errorMessage != nil ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoading || isGeneratingSession || errorMessage != nil || vocabularyWords.isEmpty)
        .accessibilityIdentifier("memory-match-start-button")
        .accessibilityLabel("Start memory match game")
        .accessibilityHint("\(pairCount) pairs to match")
    }

    // MARK: - Helpers

    private func gridSize(for pairs: Int) -> String {
        let totalCards = pairs * 2
        // Try to make roughly square grid
        switch totalCards {
        case 12: return "3×4"
        case 16: return "4×4"
        case 20: return "4×5"
        case 24: return "4×6"
        default: return "\(totalCards) cards"
        }
    }

    private func difficultyLabel(for pairs: Int) -> String {
        switch pairs {
        case 6: return "Easy"
        case 8: return "Medium"
        case 10: return "Hard"
        case 12: return "Expert"
        default: return "Custom"
        }
    }

    private func difficultyColor(for pairs: Int) -> Color {
        switch pairs {
        case 6: return .green
        case 8: return .blue
        case 10: return .orange
        case 12: return .red
        default: return .gray
        }
    }

    private func estimatedTime(for pairs: Int) -> String {
        let minutes = pairs + 2 // Rough estimate: 1 min per pair + 2 min base
        return "~\(minutes) min"
    }

    // MARK: - Data Loading

    private func loadVocabulary() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get active user's belt level from DataServices shared state
            DebugLogger.ui("🔍 MemoryMatch Config: Getting active profile from DataServices...")

            if let activeProfile = DataServices.shared.activeProfile {
                userBeltLevel = activeProfile.currentBeltLevel
                DebugLogger.ui("✅ MemoryMatch Config: Found active profile '\(activeProfile.name)'")
                DebugLogger.ui("✅ MemoryMatch Config: Belt level - \(activeProfile.currentBeltLevel.shortName) (ID: \(activeProfile.currentBeltLevel.id))")
                DebugLogger.ui("✅ MemoryMatch Config: Belt color - \(activeProfile.currentBeltLevel.colorName)")
            } else {
                DebugLogger.ui("⚠️ MemoryMatch Config: No active profile in DataServices")
                // Try to get any profile as fallback
                let allProfiles = DataServices.shared.allProfiles
                DebugLogger.ui("🔍 MemoryMatch Config: Total profiles in DataServices: \(allProfiles.count)")
                if let firstProfile = allProfiles.first {
                    userBeltLevel = firstProfile.currentBeltLevel
                    DebugLogger.ui("⚠️ MemoryMatch Config: Using first available profile '\(firstProfile.name)' as fallback")
                    DebugLogger.ui("⚠️ MemoryMatch Config: Belt level - \(firstProfile.currentBeltLevel.shortName)")
                } else {
                    DebugLogger.ui("❌ MemoryMatch Config: No profiles found in DataServices at all!")
                }
            }

            // Load vocabulary words
            vocabularyWords = try vocabularyService.loadVocabularyWords()

            // Load for memory match
            try await MainActor.run {
                try memoryMatchService.loadVocabulary()
            }

            // Validate sufficient words
            if vocabularyWords.count < pairCount {
                errorMessage = "Insufficient words: need \(pairCount), have \(vocabularyWords.count)"
            }

            isLoading = false
            DebugLogger.ui("✅ MemoryMatch Config: Loaded \(vocabularyWords.count) words")
            DebugLogger.ui("🎯 MemoryMatch Config: userBeltLevel = \(userBeltLevel != nil ? "SET (\(userBeltLevel!.shortName))" : "NIL")")

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            DebugLogger.data("❌ MemoryMatch Config: Failed to load vocabulary - \(error)")
        }
    }

    private func startSession() {
        // Prevent double-calls (e.g., double-tap on button)
        guard !isGeneratingSession else {
            DebugLogger.ui("⚠️ MemoryMatch Config: Already generating session, ignoring duplicate call")
            return
        }

        isGeneratingSession = true
        DebugLogger.ui("🎮 Starting Memory Match session: \(pairCount) pairs")

        // Retry logic to handle race conditions with data loading
        Task {
            var lastError: Error?
            let maxAttempts = 3

            for attempt in 1...maxAttempts {
                do {
                    DebugLogger.ui("🔄 MemoryMatch Config: Session generation attempt \(attempt)/\(maxAttempts)")

                    // Generate session
                    let session = try memoryMatchService.generateSession(pairCount: pairCount)

                    DebugLogger.ui("✅ MemoryMatch Config: Session generated successfully - \(session.cards.count) cards")

                    // Set session state first
                    await MainActor.run {
                        currentSession = session
                        DebugLogger.ui("📝 MemoryMatch Config: currentSession set")
                        DebugLogger.ui("🎯 MemoryMatch Config: State ready - session=\(currentSession != nil ? "SET" : "NIL"), beltLevel=\(userBeltLevel != nil ? "SET (\(userBeltLevel!.shortName))" : "NIL")")
                    }

                    // CRITICAL: Delay showing game to ensure state propagates
                    // fullScreenCover evaluates immediately when showingGame changes
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

                    await MainActor.run {
                        showingGame = true
                        isGeneratingSession = false // Reset flag on success
                        DebugLogger.ui("🎬 MemoryMatch Config: showingGame = true (after state propagation)")
                    }

                    return // Success - exit retry loop

                } catch {
                    lastError = error
                    DebugLogger.data("⚠️ MemoryMatch Config: Attempt \(attempt) failed - \(error.localizedDescription)")

                    // If not the last attempt, wait before retrying
                    if attempt < maxAttempts {
                        DebugLogger.ui("⏱️ MemoryMatch Config: Waiting 0.25s before retry...")
                        try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
                    }
                }
            }

            // All attempts failed - show error
            await MainActor.run {
                errorMessage = lastError?.localizedDescription ?? "Failed to generate session after \(maxAttempts) attempts"
                isGeneratingSession = false // Reset flag on failure
                DebugLogger.data("❌ MemoryMatch Config: All \(maxAttempts) attempts failed - \(errorMessage ?? "unknown error")")
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

    MemoryMatchConfigurationView(modelContext: modelContainer.mainContext)
}
