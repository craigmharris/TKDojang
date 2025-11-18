import SwiftUI
import SwiftData

/**
 * VocabularyBuilderView.swift
 *
 * PURPOSE: Game launcher dashboard for Vocabulary Builder feature
 *
 * FEATURES:
 * - 6 complementary game modes teaching Korean phrase grammar (ALL AVAILABLE)
 * - Word Matching: Vocabulary recognition
 * - Slot Builder: Guided phrase construction
 * - Template Filler: Pattern learning with fill-in-the-blank
 * - Phrase Decoder: Word order practice with scrambled phrases
 * - Memory Match: Visual/spatial association with card pairs
 * - Creative Sandbox: Free exploration and experimentation
 *
 * PEDAGOGY:
 * - Teaches phrase **grammar** (word categories, construction patterns)
 * - NOT phrase memorization - encourages creative construction
 * - Multiple game types reinforce same core skill from different angles
 * - Progressive difficulty: Beginner → Intermediate → Advanced
 *
 * INTEGRATION:
 * - Accessed from Learn module
 * - Navigates to specific game mode views
 * - Complete feature with all 6 games implemented
 */

struct VocabularyBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var onboardingCoordinator: OnboardingCoordinator
    @StateObject private var vocabularyService: VocabularyBuilderService

    let userProfile: UserProfile

    @State private var selectedMode: VocabularyGameMode?
    @State private var vocabularyWords: [VocabularyWord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingTour = false

    init(modelContext: ModelContext, userProfile: UserProfile) {
        _vocabularyService = StateObject(wrappedValue: VocabularyBuilderService(modelContext: modelContext))
        self.userProfile = userProfile
    }

    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading vocabulary...")
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)

                    Text("Error Loading Vocabulary")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Try Again") {
                        loadVocabulary()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                modeSelectionView
            }
        }
        .navigationTitle("Vocabulary Builder")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingTour = true
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .accessibilityIdentifier("vocabularyBuilder-help-button")
                .accessibilityLabel("Show Vocabulary Builder tour")
            }
        }
        .sheet(isPresented: $showingTour) {
            FeatureTourView(
                feature: .vocabularyBuilder,
                onComplete: {
                    onboardingCoordinator.completeFeatureTour(.vocabularyBuilder, profile: userProfile)
                    showingTour = false
                },
                onSkip: {
                    onboardingCoordinator.completeFeatureTour(.vocabularyBuilder, profile: userProfile)
                    showingTour = false
                }
            )
        }
        .onAppear {
            loadVocabulary()
        }
        .task {
            checkAndShowTour()
        }
    }

    private var modeSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Master Korean Phrase Grammar")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("\(vocabularyWords.count) vocabulary words • 6 game modes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Game modes in 2x3 grid layout
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Row 1: Word Matching, Slot Builder
                    VocabularyGameTile(
                        mode: .wordMatching,
                        action: { selectedMode = .wordMatching }
                    )

                    VocabularyGameTile(
                        mode: .slotBuilder,
                        action: { selectedMode = .slotBuilder }
                    )

                    // Row 2: Template Filler, Phrase Decoder
                    VocabularyGameTile(
                        mode: .templateFiller,
                        action: { selectedMode = .templateFiller }
                    )

                    VocabularyGameTile(
                        mode: .phraseDecoder,
                        action: { selectedMode = .phraseDecoder }
                    )

                    // Row 3: Memory Match, Creative Sandbox
                    VocabularyGameTile(
                        mode: .memoryMatch,
                        action: { selectedMode = .memoryMatch }
                    )

                    VocabularyGameTile(
                        mode: .creativeSandbox,
                        action: { selectedMode = .creativeSandbox }
                    )
                }
                .padding(.horizontal)
            }
        }
        .navigationDestination(item: $selectedMode) { mode in
            modeDetailView(for: mode)
        }
    }

    @ViewBuilder
    private func modeDetailView(for mode: VocabularyGameMode) -> some View {
        switch mode {
        case .wordMatching:
            WordMatchingView(
                vocabularyService: vocabularyService,
                words: vocabularyWords
            )

        case .slotBuilder:
            SlotBuilderConfigurationView(modelContext: modelContext)

        case .memoryMatch:
            MemoryMatchConfigurationView(modelContext: modelContext)

        case .templateFiller:
            TemplateFillerConfigurationView(modelContext: modelContext)

        case .phraseDecoder:
            PhraseDecoderConfigurationView(modelContext: modelContext)

        case .creativeSandbox:
            CreativeSandboxView(modelContext: modelContext)
        }
    }

    private func loadVocabulary() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                vocabularyWords = try vocabularyService.loadVocabularyWords()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func checkAndShowTour() {
        if onboardingCoordinator.shouldShowFeatureTour(.vocabularyBuilder, profile: userProfile) {
            showingTour = true
        }
    }
}

// MARK: - Game Modes

enum VocabularyGameMode: String, CaseIterable, Identifiable {
    case wordMatching = "word-matching"
    case slotBuilder = "slot-builder"
    case templateFiller = "template-filler"
    case phraseDecoder = "phrase-decoder"
    case memoryMatch = "memory-match"
    case creativeSandbox = "creative-sandbox"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wordMatching: return "Word Matching"
        case .slotBuilder: return "Slot Builder"
        case .templateFiller: return "Template Filler"
        case .phraseDecoder: return "Phrase Decoder"
        case .memoryMatch: return "Memory Match"
        case .creativeSandbox: return "Creative Sandbox"
        }
    }

    var icon: String {
        switch self {
        case .wordMatching: return "character.book.closed"
        case .slotBuilder: return "square.grid.2x2.fill"
        case .templateFiller: return "doc.text.fill"
        case .phraseDecoder: return "arrow.left.arrow.right"
        case .memoryMatch: return "square.grid.3x3.fill"
        case .creativeSandbox: return "paintbrush.fill"
        }
    }

    var description: String {
        switch self {
        case .wordMatching:
            return "Match English words to Korean romanised equivalents. Build vocabulary recognition."
        case .slotBuilder:
            return "Build phrases slot-by-slot with guided category selection. Learn phrase structure step by step."
        case .templateFiller:
            return "Complete phrase templates by selecting the right word categories. Master common patterns."
        case .phraseDecoder:
            return "Decode scrambled phrases by arranging words in correct order. Practice word sequencing."
        case .memoryMatch:
            return "Match English-Korean word pairs in a memory card game. Strengthen visual associations."
        case .creativeSandbox:
            return "Freely construct phrases using any combination of available words. Experiment and explore."
        }
    }

    var difficulty: String {
        switch self {
        case .wordMatching: return "Beginner"
        case .slotBuilder: return "Beginner"
        case .templateFiller: return "Intermediate"
        case .phraseDecoder: return "Intermediate"
        case .memoryMatch: return "Intermediate"
        case .creativeSandbox: return "Advanced"
        }
    }

    var estimatedTime: String {
        switch self {
        case .wordMatching: return "5-10 min"
        case .slotBuilder: return "10-15 min"
        case .templateFiller: return "10-15 min"
        case .phraseDecoder: return "10-15 min"
        case .memoryMatch: return "15-20 min"
        case .creativeSandbox: return "Open-ended"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .wordMatching: return true
        case .slotBuilder: return true
        case .memoryMatch: return true
        case .templateFiller: return true
        case .phraseDecoder: return true
        case .creativeSandbox: return true  // All games complete!
        }
    }
}

// MARK: - Coming Soon View

private struct ComingSoonView: View {
    let gameMode: VocabularyGameMode
    let message: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: gameMode.icon)
                .font(.system(size: 72))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                Text(gameMode.displayName)
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming Soon")
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .navigationTitle(gameMode.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Vocabulary Game Tile Component

struct VocabularyGameTile: View {
    let mode: VocabularyGameMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 32))
                    .foregroundColor(tileColor)

                Text(mode.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(mode.shortDescription)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tileColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("vocab-game-\(mode.rawValue)-tile")
    }

    private var tileColor: Color {
        switch mode {
        case .wordMatching: return .blue
        case .slotBuilder: return .orange
        case .templateFiller: return .green
        case .phraseDecoder: return .purple
        case .memoryMatch: return .pink
        case .creativeSandbox: return .indigo
        }
    }
}

extension VocabularyGameMode {
    var shortDescription: String {
        switch self {
        case .wordMatching:
            return "Match English to Korean"
        case .slotBuilder:
            return "Build phrases step-by-step"
        case .templateFiller:
            return "Complete phrase patterns"
        case .phraseDecoder:
            return "Arrange scrambled words"
        case .memoryMatch:
            return "Match word pairs"
        case .creativeSandbox:
            return "Explore freely"
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Vocabulary Builder Preview")
        .navigationTitle("Vocabulary Builder")
}
