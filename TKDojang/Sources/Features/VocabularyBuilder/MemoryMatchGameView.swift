import SwiftUI
import SwiftData

/**
 * MemoryMatchGameView.swift
 *
 * PURPOSE: Main game view for Memory Match mode
 *
 * FEATURES:
 * - Grid layout of face-down cards
 * - Tap to flip cards with animation
 * - Automatic match checking when 2 cards flipped
 * - Matched pairs stay face-up
 * - Non-matches flip back after delay
 * - Move counter and completion detection
 *
 * GAME FLOW:
 * 1. Show grid of face-down cards
 * 2. User taps card → flips face-up
 * 3. User taps second card → flips face-up
 * 4. Check if match (same word, different language)
 * 5. If match: keep both face-up, increment matched pairs
 * 6. If no match: delay, then flip both back
 * 7. Increment move counter
 * 8. Repeat until all pairs matched
 * 9. Show results view
 *
 * ARCHITECTURE:
 * - Follows SlotBuilderGameView pattern
 * - Integrates with MemoryMatchService for validation
 */

struct MemoryMatchGameView: View {
    @ObservedObject var memoryMatchService: MemoryMatchService
    @Binding var session: MemoryMatchSession
    let userBeltLevel: BeltLevel
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    @State private var showingResults: Bool = false
    @State private var needsReset: Bool = false // True when 2 unmatched cards showing, any tap resets them

    // Belt theme for card styling
    private var beltTheme: BeltTheme {
        BeltTheme(from: userBeltLevel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if showingResults {
                    resultsView
                } else {
                    gameView
                }
            }
            .navigationTitle("Memory Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Quit") {
                        dismiss()
                    }
                    .accessibilityIdentifier("memory-match-quit-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Matched pairs indicator
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .accessibilityHidden(true)

                            Text("\(session.matchedPairs)/\(session.totalPairs)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .accessibilityLabel("\(session.matchedPairs) of \(session.totalPairs) pairs matched")

                        // Moves counter
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .accessibilityHidden(true)

                            Text("\(session.moveCount)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .accessibilityLabel("\(session.moveCount) moves")
                    }
                    .accessibilityIdentifier("memory-match-stats")
                }
            }
        }
    }

    // MARK: - Game View

    private var gameView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Instructions
                Text(needsReset ? "Tap any card to continue" : "Tap cards to find matching pairs")
                    .font(.subheadline)
                    .foregroundColor(needsReset ? .orange : .secondary)
                    .padding(.top)

                // Card grid
                cardGrid
                    .padding(.horizontal)
            }
        }
    }

    private var cardGrid: some View {
        let columns = gridColumns(for: session.cards.count)

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(session.cards) { card in
                MemoryCardView(
                    session: $session,
                    cardID: card.id,
                    beltTheme: beltTheme,
                    onTap: {
                        handleCardTap(card)
                    }
                )
                .aspectRatio(2.0/3.0, contentMode: .fit)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("memory-match-card-grid")
    }

    private func gridColumns(for cardCount: Int) -> [GridItem] {
        let columnsCount: Int
        switch cardCount {
        case 12: columnsCount = 3 // 3×4
        case 16: columnsCount = 4 // 4×4
        case 20: columnsCount = 4 // 4×5
        case 24: columnsCount = 4 // 4×6
        default: columnsCount = 4
        }

        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columnsCount)
    }

    // MARK: - Results View

    private var resultsView: some View {
        MemoryMatchResultsView(
            session: session,
            metrics: memoryMatchService.calculateMetrics(session: session),
            onDismiss: {
                onComplete()
                dismiss()
            }
        )
    }

    // MARK: - Game Logic

    private func handleCardTap(_ card: MemoryCard) {
        // If we need to reset, any tap resets
        if needsReset {
            resetUnmatchedCards()
            needsReset = false
            logState()
            return
        }

        // Don't allow > 2 unmatched cards flipped
        let flippedUnmatched = session.cards.filter { $0.isFlipped && !$0.isMatched }
        guard flippedUnmatched.count < 2 else { return }

        // Don't flip already flipped/matched cards
        guard let currentCard = session.cards.first(where: { $0.id == card.id }) else { return }
        guard !currentCard.isFlipped && !currentCard.isMatched else { return }

        // Flip the card
        flipCard(card)
        logState()

        // Check if we now have 2 flipped unmatched cards
        let nowFlipped = session.cards.filter { $0.isFlipped && !$0.isMatched }
        if nowFlipped.count == 2 {
            checkForMatch()
        }
    }

    private func flipCard(_ card: MemoryCard) {
        guard let index = session.cards.firstIndex(where: { $0.id == card.id }) else { return }

        var cards = session.cards
        cards[index].isFlipped = true

        // Create new session struct to trigger binding update
        var newSession = session
        newSession.cards = cards
        newSession.version += 1  // Force SwiftUI to detect change
        session = newSession

        DebugLogger.ui("🃏 Flipped: \(card.displayText)")
    }

    private func checkForMatch() {
        let flippedUnmatched = session.cards.filter { $0.isFlipped && !$0.isMatched }
        guard flippedUnmatched.count == 2 else { return }

        let card1 = flippedUnmatched[0]
        let card2 = flippedUnmatched[1]

        let isMatch = memoryMatchService.checkMatch(card1: card1, card2: card2)

        session.moveCount += 1

        if isMatch {
            markCardsAsMatched(card1, card2)
            session.matchedPairs += 1

            DebugLogger.ui("✅ Match: \(card1.word.english)")
            logState()

            // Check for completion
            if session.isComplete {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        showingResults = true
                    }
                }
            }

        } else {
            // No match - next tap will reset
            needsReset = true

            DebugLogger.ui("❌ No match")
            logState()
        }
    }

    private func resetUnmatchedCards() {
        var cards = session.cards
        for index in cards.indices where cards[index].isFlipped && !cards[index].isMatched {
            cards[index].isFlipped = false
        }

        // Create new session struct to trigger binding update
        var newSession = session
        newSession.cards = cards
        newSession.version += 1  // Force SwiftUI to detect change
        session = newSession

        DebugLogger.ui("🔄 Reset unmatched cards")
    }

    private func markCardsAsMatched(_ card1: MemoryCard, _ card2: MemoryCard) {
        var cards = session.cards
        if let index1 = cards.firstIndex(where: { $0.id == card1.id }) {
            cards[index1].isMatched = true
        }
        if let index2 = cards.firstIndex(where: { $0.id == card2.id }) {
            cards[index2].isMatched = true
        }

        // Create new session struct to trigger binding update
        var newSession = session
        newSession.cards = cards
        newSession.version += 1  // Force SwiftUI to detect change
        session = newSession
    }

    // MARK: - State Logging

    private func logState() {
        let flipped = session.cards.filter { $0.isFlipped && !$0.isMatched }.count
        let back = session.cards.filter { !$0.isFlipped && !$0.isMatched }.count
        let matched = session.cards.filter { $0.isMatched }.count

        DebugLogger.ui("📊 State: \(flipped) front, \(back) back, \(matched) matched [v\(session.version)]")
    }
}

// MARK: - Memory Card View

private struct MemoryCardView: View {
    @Binding var session: MemoryMatchSession
    let cardID: UUID
    let beltTheme: BeltTheme
    let onTap: () -> Void

    // Look up current card state from session on EACH render
    private var card: MemoryCard {
        let found = session.cards.first(where: { $0.id == cardID })
        print("🔎 Lookup \(found?.displayText ?? "??"): isFlipped=\(found?.isFlipped ?? false), flipped in array=\(session.cards.filter { $0.isFlipped }.count), session v\(session.version)")
        return found ?? MemoryCard(
            word: VocabularyWord(english: "", romanized: "", hangul: nil, frequency: 0),
            language: .english,
            position: 0
        )
    }

    var body: some View {
        let _ = print("🔍 RENDER: \(card.displayText) - isFlipped=\(card.isFlipped)")

        return Button(action: {
            // Always call onTap - it handles needsReset logic
            if !card.isMatched {
                onTap()
            }
        }) {
            // NO ANIMATION - just test if state propagates
            if card.isFlipped {
                cardFront
            } else {
                cardBack
            }
        }
        .buttonStyle(.plain)
        .disabled(card.isMatched)
        .accessibilityIdentifier("memory-card-\(card.position)")
        .accessibilityLabel(card.isFlipped ? "\(card.displayText) card" : "Face down card")
        .accessibilityHint(card.isMatched ? "Matched" : card.isFlipped ? "Flipped - tap another card to match" : "Tap to flip")
    }

    private var cardBack: some View {
        ZStack {
            // Cream background gradient (matching loading screen)
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0.96, green: 0.92, blue: 0.84), location: 0.0),
                            .init(color: Color(red: 0.94, green: 0.88, blue: 0.78), location: 0.5),
                            .init(color: Color(red: 0.92, green: 0.86, blue: 0.76), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Hangul for Taekwondo (태권도) - Using NanumBrushScript font with fallback
            Text("태권도")
                .font(customKoreanFont(size: 48))
                .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.2).opacity(0.3))
                .rotationEffect(.degrees(-20))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(beltTheme.borderColor, lineWidth: 3) // User's belt color
        )
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    // Helper function for Korean font with fallback (same pattern as LoadingView)
    private func customKoreanFont(size: CGFloat) -> Font {
        // Try font names for NanumBrushScript
        let possibleNames = [
            "NanumBrushScript-Regular",
            "NanumBrushScript",
            "나눔손글씨붓",
            "NanumBrush"
        ]

        // Check if any of the font names work
        for fontName in possibleNames {
            if UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
        }

        // Fallback to system font with serif design
        return .system(size: size, weight: .ultraLight, design: .serif)
    }

    private var cardFront: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                card.isMatched ?
                LinearGradient(
                    colors: [Color.green.opacity(0.2), Color.green.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                VStack(spacing: 8) {
                    // Language indicator
                    Text(card.language == .english ? "EN" : "KO")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(card.language == .english ? Color.blue : Color.orange)
                        )

                    // Word text
                    Text(card.displayText)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .padding(.horizontal, 8)

                    if card.isMatched {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    }
                }
                .padding(12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(card.isMatched ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    @Previewable @State var session = MemoryMatchSession(
        pairCount: 6,
        totalPairs: 6,
        cards: [
            MemoryCard(
                word: VocabularyWord(english: "Block", romanized: "Makgi", hangul: nil, frequency: 27),
                language: .english,
                position: 0
            ),
            MemoryCard(
                word: VocabularyWord(english: "Block", romanized: "Makgi", hangul: nil, frequency: 27),
                language: .korean,
                position: 1
            ),
            MemoryCard(
                word: VocabularyWord(english: "Kick", romanized: "Chagi", hangul: nil, frequency: 14),
                language: .english,
                position: 2
            ),
            MemoryCard(
                word: VocabularyWord(english: "Kick", romanized: "Chagi", hangul: nil, frequency: 14),
                language: .korean,
                position: 3
            ),
            MemoryCard(
                word: VocabularyWord(english: "Punch", romanized: "Jirugi", hangul: nil, frequency: 9),
                language: .english,
                position: 4
            ),
            MemoryCard(
                word: VocabularyWord(english: "Punch", romanized: "Jirugi", hangul: nil, frequency: 9),
                language: .korean,
                position: 5
            )
        ],
        startTime: Date()
    )

    let service = MemoryMatchService(modelContext: modelContainer.mainContext)

    // Create preview belt level
    let previewBelt = BeltLevel(
        name: "7th Keup (Yellow Belt)",
        shortName: "7th Keup",
        colorName: "Yellow",
        sortOrder: 8,
        isKyup: true
    )

    MemoryMatchGameView(
        memoryMatchService: service,
        session: $session,
        userBeltLevel: previewBelt,
        onComplete: {}
    )
}
