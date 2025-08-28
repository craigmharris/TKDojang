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
    let specificTerms: [TerminologyEntry]?
    
    @EnvironmentObject private var dataServices: DataServices
    
    @State private var currentTermIndex = 0
    @State private var isShowingAnswer = false
    @State private var terms: [TerminologyEntry] = []
    @State private var userProfile: UserProfile?
    @State private var sessionStats = SessionStats()
    @State private var isLoading = true
    @State private var studyMode: StudyMode = .test
    @State private var cardDirection: CardDirection = .englishToKorean
    @State private var currentCardDirection: CardDirection = .englishToKorean // For random direction
    @State private var sessionStartTime: Date?
    @State private var sessionItemsStudied = 0
    @State private var showingResults = false
    @State private var incorrectTerms: [TerminologyEntry] = []
    
    init(specificTerms: [TerminologyEntry]? = nil) {
        self.specificTerms = specificTerms
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: studyMode == .learn ? 12 : 16) {
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
                    
                    // Session stats - add padding to avoid navigation bar
                    statsView
                        .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationTitle("Korean Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileSwitcher()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Section("Study Mode") {
                            Button(action: { studyMode = .learn }) {
                                Label("Learn Mode", systemImage: studyMode == .learn ? "checkmark" : "")
                            }
                            Button(action: { studyMode = .test }) {
                                Label("Test Mode", systemImage: studyMode == .test ? "checkmark" : "")
                            }
                        }
                        
                        Section("Direction") {
                            Button(action: { 
                                cardDirection = .englishToKorean
                                currentCardDirection = .englishToKorean
                            }) {
                                Label("English → Korean", systemImage: cardDirection == .englishToKorean ? "checkmark" : "")
                            }
                            Button(action: { 
                                cardDirection = .koreanToEnglish
                                currentCardDirection = .koreanToEnglish
                            }) {
                                Label("Korean → English", systemImage: cardDirection == .koreanToEnglish ? "checkmark" : "")
                            }
                            Button(action: { 
                                cardDirection = .bothDirections
                                randomizeDirection()
                            }) {
                                Label("Both Directions", systemImage: cardDirection == .bothDirections ? "checkmark" : "")
                            }
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .task {
                await loadUserData()
                sessionStartTime = Date()
            }
            .onChange(of: dataServices.profileService.activeProfile) {
                Task {
                    await loadUserData()
                    sessionStartTime = Date() // Reset session time on profile change
                    sessionItemsStudied = 0
                }
            }
            .onDisappear {
                if !showingResults {
                    recordStudySession()
                }
            }
            .navigationDestination(isPresented: $showingResults) {
                FlashcardResultsView(
                    sessionStats: sessionStats,
                    terms: terms,
                    incorrectTerms: incorrectTerms
                )
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // User profile section
            if let profile = userProfile {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(profile.currentBeltLevel.shortName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(profile.learningMode.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.8)
                }
                .padding(.bottom, 4)
            }
            
            // Progress section
            if !terms.isEmpty && currentTermIndex < terms.count {
                let currentTheme = BeltTheme(from: terms[currentTermIndex].beltLevel)
                
                VStack(spacing: 8) {
                    // Belt-themed progress bar
                    BeltProgressBar(
                        progress: Double(currentTermIndex + 1) / Double(terms.count),
                        theme: currentTheme
                    )
                    
                    Text("\(currentTermIndex + 1) of \(terms.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Flashcard Content
    
    private var flashcardContent: some View {
        let currentTerm = terms[currentTermIndex]
        let theme = BeltTheme(from: currentTerm.beltLevel)
        
        return VStack {
            // Card with belt-themed styling
            ZStack {
                BeltCardBackground(theme: theme)
                    .frame(height: studyMode == .learn ? 400 : 320)
                
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
                    
                    if studyMode == .learn {
                        // Learn mode - show all information
                        learnModeContent(for: currentTerm)
                    } else if !isShowingAnswer {
                        // Test mode - Question side
                        testModeQuestionContent(for: currentTerm)
                    } else {
                        // Test mode - Answer side
                        testModeAnswerContent(for: currentTerm)
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
                if studyMode == .test {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isShowingAnswer.toggle()
                    }
                }
            }
            
            // Flip hint (only for test mode)
            if studyMode == .test && !isShowingAnswer {
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
            if studyMode == .learn {
                // Learn mode - navigation only
                Button("Previous") {
                    previousCard()
                }
                .buttonStyle(.bordered)
                .disabled(currentTermIndex == 0)
                
                if currentTermIndex >= terms.count - 1 {
                    Button("Complete Session") {
                        completeLearnSession()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button("Next") {
                        nextCard()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
            } else if isShowingAnswer {
                // Test mode - answer feedback buttons
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
                // Test mode - navigation buttons
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
            statItem("Accuracy", value: "\(sessionStats.accuracyPercentage)%", color: .blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func statItem(_ label: String, value: Any, color: Color) -> some View {
        VStack {
            Text("\(value)")
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
        
        // Get the active profile from ProfileService
        userProfile = dataServices.profileService.getActiveProfile()
        
        // If no active profile, ensure we have at least one profile
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            print("👤 Active profile: \(profile.name) - Belt=\(profile.currentBeltLevel.shortName), Mode=\(profile.learningMode)")
            
            if let specificTerms = specificTerms {
                terms = specificTerms
                print("📚 Using specific terms from test: \(terms.count) terms")
            } else {
                terms = dataServices.terminologyService.getTerminologyForUser(userProfile: profile, limit: 50)
                print("📚 Loaded \(terms.count) terms for user \(profile.name)")
            }
            
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
    
    private func recordStudySession() {
        guard let profile = userProfile,
              sessionStartTime != nil,
              sessionItemsStudied > 0 else { return }
        
        do {
            try dataServices.profileService.recordStudySession(
                sessionType: .flashcards,
                itemsStudied: sessionItemsStudied,
                correctAnswers: sessionStats.correctCount,
                focusAreas: [profile.currentBeltLevel.shortName]
            )
            
            print("📈 Recorded flashcard session for \(profile.name): \(sessionItemsStudied) items, \(sessionStats.correctCount) correct")
        } catch {
            print("❌ Failed to record study session: \(error)")
        }
    }
    
    private func nextCard() {
        if currentTermIndex < terms.count - 1 {
            withAnimation {
                currentTermIndex += 1
                isShowingAnswer = false
                if cardDirection == .bothDirections {
                    randomizeDirection()
                }
            }
        } else if studyMode == .test && sessionStats.totalCount > 0 {
            // Session is complete - show results
            recordStudySession()
            showingResults = true
        }
    }
    
    private func completeLearnSession() {
        // For learn mode, create a perfect score since there are no incorrect answers
        sessionStats.correctCount = terms.count
        sessionStats.incorrectCount = 0
        sessionItemsStudied = terms.count
        
        // Record the study session
        recordStudySession()
        
        // Show results
        showingResults = true
    }
    
    private func previousCard() {
        if currentTermIndex > 0 {
            withAnimation {
                currentTermIndex -= 1
                isShowingAnswer = false
                if cardDirection == .bothDirections {
                    randomizeDirection()
                }
            }
        }
    }
    
    private func randomizeDirection() {
        currentCardDirection = Bool.random() ? .englishToKorean : .koreanToEnglish
    }
    
    private func recordAnswer(isCorrect: Bool) {
        guard let profile = userProfile,
              currentTermIndex < terms.count else { return }
        
        let currentTerm = terms[currentTermIndex]
        
        // Record in database
        dataServices.terminologyService.recordUserAnswer(
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
            // Track incorrect terms for review
            if !incorrectTerms.contains(where: { $0.id == currentTerm.id }) {
                incorrectTerms.append(currentTerm)
            }
        }
        
        sessionItemsStudied += 1
        
        // Update profile activity
        profile.recordActivity()
        profile.totalFlashcardsSeen += 1
        
        // Save profile updates
        do {
            try dataServices.modelContext.save()
        } catch {
            print("❌ Failed to save profile updates: \(error)")
        }
        
        // Move to next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            nextCard()
        }
    }
    
    // MARK: - Content Methods
    
    private func learnModeContent(for term: TerminologyEntry) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // English term
                VStack(spacing: 6) {
                    Text("English")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(term.englishTerm)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.8)
                        .lineLimit(2)
                }
                
                Divider()
                
                // Korean information
                VStack(spacing: 10) {
                    Text("Korean")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(term.koreanHangul)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text(term.romanizedPronunciation)
                        .font(.title3)
                        .foregroundColor(.primary)
                        .italic()
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    
                    if let phonetic = term.phoneticPronunciation {
                        Text("[\(phonetic)]")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                }
                
                // Definition if available
                if let definition = term.definition, !definition.isEmpty {
                    Divider()
                    VStack(spacing: 6) {
                        Text("Definition")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(definition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.8)
                            .lineLimit(3)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 340)
    }
    
    private func testModeQuestionContent(for term: TerminologyEntry) -> some View {
        VStack(spacing: 16) {
            Text(currentCardDirection == .englishToKorean ? "What is this in Korean?" : "What is this in English?")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if currentCardDirection == .englishToKorean {
                Text(term.englishTerm)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let definition = term.definition {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                // Korean to English
                VStack(spacing: 12) {
                    Text(term.koreanHangul)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(term.romanizedPronunciation)
                        .font(.title2)
                        .foregroundColor(.primary)
                        .italic()
                    
                    if let phonetic = term.phoneticPronunciation {
                        Text("[\(phonetic)]")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func testModeAnswerContent(for term: TerminologyEntry) -> some View {
        VStack(spacing: 16) {
            if currentCardDirection == .englishToKorean {
                // Show Korean answer
                Text(term.koreanHangul)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(term.romanizedPronunciation)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .italic()
                
                if let phonetic = term.phoneticPronunciation {
                    Text("[\(phonetic)]")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // Show English answer
                Text(term.englishTerm)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                if let definition = term.definition {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum StudyMode: String, CaseIterable {
    case learn = "learn"
    case test = "test"
    
    var displayName: String {
        switch self {
        case .learn: return "Learn Mode"
        case .test: return "Test Mode"
        }
    }
}

enum CardDirection: String, CaseIterable {
    case englishToKorean = "en_to_ko"
    case koreanToEnglish = "ko_to_en"
    case bothDirections = "both"
    
    var displayName: String {
        switch self {
        case .englishToKorean: return "English → Korean"
        case .koreanToEnglish: return "Korean → English"
        case .bothDirections: return "Both Directions"
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
            
    }
}