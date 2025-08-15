import SwiftUI
import SwiftData

/**
 * FlashcardView.swift
 * 
 * PURPOSE: Interactive flashcard interface for Korean terminology learning
 * 
 * FEATURES:
 * - Flip animation to reveal answers
 * - Multiple learning modes (study, test)
 * - Progress tracking with spaced repetition
 * - Swipe gestures for easy navigation
 */

struct FlashcardView: View {
    @Environment(DataManager.self) private var dataManager
    @Query private var userProfiles: [UserProfile]
    
    @State private var currentTermIndex = 0
    @State private var isShowingAnswer = false
    @State private var terms: [TerminologyEntry] = []
    @State private var userProfile: UserProfile?
    @State private var sessionStats = SessionStats()
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header with progress
                    headerView
                    
                    Spacer()
                    
                    // Main flashcard
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading terms...")
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 300)
                    } else if !terms.isEmpty && currentTermIndex < terms.count {
                        flashcardContent
                    } else {
                        emptyStateView
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    controlButtons
                    
                    // Session stats
                    statsView
                }
                .padding()
            }
            .navigationTitle("Korean Terms")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadUserData()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if userProfile != nil {
                HStack {
                    Text("Current Level: \\(userProfile!.currentBeltLevel.shortName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Mode: \\(userProfile!.learningMode.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !terms.isEmpty && currentTermIndex < terms.count {
                let currentTheme = BeltTheme(from: terms[currentTermIndex].beltLevel)
                
                // Belt-themed progress bar
                BeltProgressBar(
                    progress: Double(currentTermIndex + 1) / Double(terms.count),
                    theme: currentTheme
                )
                
                Text("\(currentTermIndex + 1) of \(terms.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Flashcard Content
    
    private var flashcardContent: some View {
        let currentTerm = terms[currentTermIndex]
        let theme = BeltTheme(from: currentTerm.beltLevel)
        
        return VStack {
            // Card with belt-themed styling
            ZStack {
                BeltCardBackground(theme: theme)
                    .frame(height: 300)
                
                VStack(spacing: 20) {
                    // Belt and category badges
                    HStack(spacing: 8) {
                        BeltBadge(beltLevel: currentTerm.beltLevel, theme: theme)
                        
                        Text(currentTerm.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if !isShowingAnswer {
                        // Question side
                        VStack(spacing: 16) {
                            Text("What is this in Korean?")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(currentTerm.englishTerm)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                            
                            if let definition = currentTerm.definition {
                                Text(definition)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                    } else {
                        // Answer side
                        VStack(spacing: 16) {
                            Text(currentTerm.koreanHangul)
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(currentTerm.romanizedPronunciation)
                                .font(.title2)
                                .foregroundColor(.primary)
                                .italic()
                            
                            if let phonetic = currentTerm.phoneticPronunciation {
                                Text("[\(phonetic)]")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .rotation3DEffect(
                .degrees(isShowingAnswer ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )
            .scaleEffect(x: isShowingAnswer ? -1 : 1, y: 1) // Fix mirroring
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isShowingAnswer.toggle()
                }
            }
            
            // Flip hint
            if !isShowingAnswer {
                Text("Tap to reveal answer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: 20) {
            if isShowingAnswer {
                // Answer feedback buttons
                Button("Incorrect") {
                    recordAnswer(isCorrect: false)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button("Correct") {
                    recordAnswer(isCorrect: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                // Navigation buttons
                Button("Previous") {
                    previousCard()
                }
                .buttonStyle(.bordered)
                .disabled(currentTermIndex == 0)
                
                Button("Skip") {
                    nextCard()
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Stats View
    
    private var statsView: some View {
        HStack {
            statItem("Correct", value: sessionStats.correctCount, color: .green)
            statItem("Incorrect", value: sessionStats.incorrectCount, color: .red)
            statItem("Accuracy", value: "\\(sessionStats.accuracyPercentage)%", color: .blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func statItem(_ label: String, value: Any, color: Color) -> some View {
        VStack {
            Text("\\(value)")
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No terms available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Check your belt level and learning mode settings")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    @MainActor
    private func loadUserData() async {
        print("🎯 FlashcardView: Starting loadUserData()")
        isLoading = true
        userProfile = dataManager.getOrCreateDefaultUserProfile()
        
        if let profile = userProfile {
            print("👤 User profile found: Belt=\(profile.currentBeltLevel.shortName), Mode=\(profile.learningMode)")
            terms = dataManager.terminologyService.getTerminologyForUser(userProfile: profile, limit: 50)
            print("📚 Loaded \(terms.count) terms for user")
            
            if terms.isEmpty {
                print("❌ No terms found! This suggests data loading failed.")
            } else {
                print("✅ Sample term: \(terms[0].englishTerm) (\(terms[0].koreanHangul))")
            }
        } else {
            print("❌ No user profile found!")
        }
        isLoading = false
    }
    
    private func nextCard() {
        if currentTermIndex < terms.count - 1 {
            withAnimation {
                currentTermIndex += 1
                isShowingAnswer = false
            }
        }
    }
    
    private func previousCard() {
        if currentTermIndex > 0 {
            withAnimation {
                currentTermIndex -= 1
                isShowingAnswer = false
            }
        }
    }
    
    private func recordAnswer(isCorrect: Bool) {
        guard let profile = userProfile,
              currentTermIndex < terms.count else { return }
        
        let currentTerm = terms[currentTermIndex]
        
        // Record in database
        dataManager.terminologyService.recordUserAnswer(
            userProfile: profile,
            terminologyEntry: currentTerm,
            isCorrect: isCorrect,
            responseTime: 5.0 // TODO: Actually track response time
        )
        
        // Update session stats
        if isCorrect {
            sessionStats.correctCount += 1
        } else {
            sessionStats.incorrectCount += 1
        }
        
        // Move to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            nextCard()
        }
    }
}

// MARK: - Session Statistics

struct SessionStats {
    var correctCount = 0
    var incorrectCount = 0
    
    var totalCount: Int {
        correctCount + incorrectCount
    }
    
    var accuracyPercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount)) * 100)
    }
}

// MARK: - Preview

struct FlashcardView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardView()
            .withDataContext()
    }
}