import SwiftUI
import SwiftData

/**
 * CreativeSandboxView.swift
 *
 * PURPOSE: Free-form phrase construction playground
 *
 * FEATURES:
 * - Browse all vocabulary words by category
 * - Tap words to add to phrase
 * - Tap phrase words to remove them
 * - No validation or scoring - pure exploration
 * - See English and Korean romanization
 * - Clear phrase and start over
 *
 * PEDAGOGY:
 * - Encourages experimentation without fear of failure
 * - Discover word combinations organically
 * - Learn category relationships through play
 * - Advanced mode for confident learners
 */

struct CreativeSandboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sandboxService: CreativeSandboxService

    @State private var constructedPhrase: [CategorizedWord] = []
    @State private var selectedCategory: WordCategory = .action
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showClearAlert = false

    init(modelContext: ModelContext) {
        _sandboxService = StateObject(wrappedValue: CreativeSandboxService(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    sandboxContent
                }
            }
            .navigationTitle("Creative Sandbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("creative-sandbox-done-button")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        if constructedPhrase.isEmpty {
                            return
                        }
                        showClearAlert = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(constructedPhrase.isEmpty)
                    .accessibilityIdentifier("creative-sandbox-clear-button")
                }
            }
            .alert("Clear Phrase?", isPresented: $showClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    withAnimation {
                        constructedPhrase.removeAll()
                    }
                }
            } message: {
                Text("This will remove all words from your current phrase.")
            }
        }
        .task {
            await loadVocabulary()
        }
    }

    // MARK: - Loading & Error Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading vocabulary...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Error Loading Vocabulary")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Try Again") {
                Task {
                    await loadVocabulary()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Sandbox Content

    private var sandboxContent: some View {
        VStack(spacing: 0) {
            // Constructed phrase area
            constructedPhraseSection

            Divider()

            // Category selector
            categorySelector

            // Word selection area
            ScrollView {
                wordSelectionGrid
                    .padding()
            }
        }
    }

    // MARK: - Constructed Phrase

    private var constructedPhraseSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Phrase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if !constructedPhrase.isEmpty {
                    Text("\(constructedPhrase.count) words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if constructedPhrase.isEmpty {
                emptyPhrasePrompt
            } else {
                phraseDisplay
            }
        }
        .padding()
        .frame(minHeight: 120)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var emptyPhrasePrompt: some View {
        VStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Tap words below to build a phrase")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var phraseDisplay: some View {
        VStack(spacing: 16) {
            // English phrase
            SandboxFlowLayout(spacing: 8) {
                ForEach(Array(constructedPhrase.enumerated()), id: \.element.id) { index, word in
                    Button {
                        let indexToRemove = index
                        _ = withAnimation {
                            constructedPhrase.remove(at: indexToRemove)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(word.english)
                                .font(.headline)

                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(categoryColor(for: word.category).opacity(0.2))
                        .foregroundColor(categoryColor(for: word.category))
                        .cornerRadius(8)
                    }
                    .accessibilityIdentifier("constructed-word-\(index)")
                }
            }

            // Korean romanization
            Text(romanizedPhrase)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var romanizedPhrase: String {
        constructedPhrase.map { $0.romanized }.joined(separator: " ")
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(sandboxService.allCategories(), id: \.self) { category in
                    CategoryPill(
                        category: category,
                        isSelected: selectedCategory == category,
                        wordCount: sandboxService.words(for: category).count
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Word Selection

    private var wordSelectionGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedCategory.displayName)
                .font(.title3)
                .fontWeight(.semibold)

            let words = sandboxService.words(for: selectedCategory)

            if words.isEmpty {
                Text("No words available in this category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                SandboxFlowLayout(spacing: 12) {
                    ForEach(words) { word in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                constructedPhrase.append(word)
                            }
                            DebugLogger.ui("➕ CreativeSandbox: Added '\(word.english)' to phrase")
                        } label: {
                            VStack(spacing: 4) {
                                Text(word.english)
                                    .font(.headline)
                                Text(word.romanized)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(categoryColor(for: word.category), lineWidth: 2)
                            )
                        }
                        .accessibilityIdentifier("word-\(word.english.lowercased())")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func categoryColor(for category: WordCategory) -> Color {
        switch category {
        case .action: return .red
        case .tool: return .blue
        case .direction: return .green
        case .target: return .orange
        case .techniqueModifier: return .purple
        case .position: return .cyan
        case .execution: return .yellow
        }
    }

    private func loadVocabulary() async {
        isLoading = true
        errorMessage = nil

        do {
            try sandboxService.loadVocabulary()

            // Set initial category to first available
            if let firstCategory = sandboxService.allCategories().first {
                selectedCategory = firstCategory
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            DebugLogger.data("❌ CreativeSandbox: Failed to load vocabulary - \(error)")
        }
    }
}

// MARK: - Category Pill

private struct CategoryPill: View {
    let category: WordCategory
    let isSelected: Bool
    let wordCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(wordCount)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? categoryColor.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? categoryColor : .primary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 2)
            )
        }
        .accessibilityIdentifier("category-pill-\(category.rawValue)")
    }

    private var categoryColor: Color {
        switch category {
        case .action: return .red
        case .tool: return .blue
        case .direction: return .green
        case .target: return .orange
        case .techniqueModifier: return .purple
        case .position: return .cyan
        case .execution: return .yellow
        }
    }
}

// MARK: - Flow Layout (Wrapping Layout)

private struct SandboxFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var modelContainer = try! ModelContainer(
        for: UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    CreativeSandboxView(modelContext: modelContainer.mainContext)
}
