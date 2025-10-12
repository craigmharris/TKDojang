import SwiftUI
import SwiftData

/**
 * FlashcardConfigurationView.swift
 * 
 * PURPOSE: Intermediate configuration screen for flashcard sessions
 * 
 * FEATURES:
 * - Configure study mode, direction, and number of terms
 * - Show current settings with ability to modify for session
 * - Provide mode explanations and help access
 * - Preview session parameters before starting
 */

struct FlashcardConfigurationView: View {
    let specificTerms: [TerminologyEntry]? // For review sessions
    
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var userProfile: UserProfile?
    @State private var studyMode: StudyMode = .test
    @State private var cardDirection: CardDirection = .bothDirections
    @State private var numberOfTerms: Int = 20
    @State private var learningSystem: LearningSystem = .classic
    @State private var showingModeGuide = false
    @State private var availableTermsCount = 0
    @State private var isLoading = true
    
    var isReviewSession: Bool {
        specificTerms != nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    configurationHeader
                    
                    if isLoading {
                        loadingView
                    } else {
                        // Configuration Options
                        VStack(spacing: 20) {
                            studyModeSection
                            cardDirectionSection
                            
                            if !isReviewSession {
                                learningSystemSection
                                numberOfTermsSection
                            }
                        }
                        
                        // Session Preview
                        sessionPreviewSection
                        
                        // Start Button
                        startSessionButton
                    }
                }
                .padding()
            }
            .navigationTitle(isReviewSession ? "Review Configuration" : "Flashcard Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Help") {
                        showingModeGuide = true
                    }
                }
            }
            .sheet(isPresented: $showingModeGuide) {
                FlashcardModeGuideView()
            }
            .task {
                await loadConfiguration()
            }
        }
    }
    
    // MARK: - Header
    
    private var configurationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: isReviewSession ? "arrow.clockwise" : "graduationcap.fill")
                .font(.system(size: 50))
                .foregroundColor(isReviewSession ? .orange : .blue)
            
            Text(isReviewSession ? "Review Session" : "New Flashcard Session")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(isReviewSession ? 
                 "Configure how you'd like to review these terms" :
                 "Customize your flashcard session settings"
            )
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading configuration...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }
    
    // MARK: - Study Mode Section
    
    private var studyModeSection: some View {
        ConfigurationSection(
            title: "Study Mode",
            icon: "book.fill",
            iconColor: .green
        ) {
            VStack(spacing: 12) {
                ForEach(StudyMode.allCases, id: \.rawValue) { mode in
                    StudyModeCard(
                        mode: mode,
                        isSelected: studyMode == mode,
                        onSelect: { studyMode = mode }
                    )
                }
            }
        }
    }
    
    // MARK: - Card Direction Section
    
    private var cardDirectionSection: some View {
        ConfigurationSection(
            title: "Study Direction",
            icon: "arrow.left.arrow.right",
            iconColor: .purple
        ) {
            VStack(spacing: 12) {
                ForEach(CardDirection.allCases, id: \.rawValue) { direction in
                    CardDirectionCard(
                        direction: direction,
                        isSelected: cardDirection == direction,
                        onSelect: { cardDirection = direction }
                    )
                }
            }
        }
    }
    
    // MARK: - Learning System Section
    
    private var learningSystemSection: some View {
        ConfigurationSection(
            title: "Learning System",
            icon: "brain.head.profile",
            iconColor: .blue
        ) {
            VStack(spacing: 12) {
                ForEach(LearningSystem.allCases, id: \.rawValue) { system in
                    LearningSystemCard(
                        system: system,
                        isSelected: learningSystem == system,
                        onSelect: { learningSystem = system }
                    )
                }
            }
        }
    }
    
    // MARK: - Number of Terms Section
    
    private var numberOfTermsSection: some View {
        ConfigurationSection(
            title: "Number of Terms",
            icon: "number.circle.fill",
            iconColor: .orange
        ) {
            VStack(spacing: 16) {
                // Current selection display
                HStack {
                    Text("Terms in session:")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(numberOfTerms)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                // Slider
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Double(numberOfTerms) },
                            set: { numberOfTerms = Int($0) }
                        ),
                        in: 5...min(50, Double(max(availableTermsCount, 5))),
                        step: 5
                    )
                    .tint(.orange)
                    
                    HStack {
                        Text("5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(min(50, max(availableTermsCount, 5)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Available terms info
                if availableTermsCount > 0 {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("\(availableTermsCount) terms available for your current settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Session Preview
    
    private var sessionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                PreviewRow(
                    icon: "book.fill",
                    title: "Study Mode",
                    value: studyMode.displayName,
                    color: .green
                )
                
                PreviewRow(
                    icon: "arrow.left.arrow.right",
                    title: "Direction",
                    value: cardDirection.displayName,
                    color: .purple
                )
                
                if !isReviewSession {
                    PreviewRow(
                        icon: "brain.head.profile",
                        title: "Learning System",
                        value: learningSystem.displayName,
                        color: .blue
                    )
                    
                    PreviewRow(
                        icon: "number.circle.fill",
                        title: "Number of Terms",
                        value: "\(numberOfTerms) terms",
                        color: .orange
                    )
                }
                
                if isReviewSession, let terms = specificTerms {
                    PreviewRow(
                        icon: "arrow.clockwise",
                        title: "Review Terms",
                        value: "\(terms.count) terms",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Start Button
    
    private var startSessionButton: some View {
        NavigationLink(destination: createFlashcardView()) {
            HStack {
                Image(systemName: "play.fill")
                Text(isReviewSession ? "Start Review" : "Start Session")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isReviewSession ? Color.orange : Color.blue)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading || (!isReviewSession && availableTermsCount == 0))
    }
    
    // MARK: - Actions
    
    @MainActor
    private func loadConfiguration() async {
        isLoading = true
        
        userProfile = dataServices.profileService.getActiveProfile()
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            // Load user preferences
            numberOfTerms = profile.dailyStudyGoal
            learningSystem = dataServices.leitnerService.isLeitnerModeEnabled ? .leitner : .classic
            
            // Calculate available terms if not a review session
            if !isReviewSession {
                availableTermsCount = getAvailableTermsCount(for: profile)
                
                // Adjust numberOfTerms if it exceeds available terms
                if numberOfTerms > availableTermsCount && availableTermsCount > 0 {
                    numberOfTerms = min(numberOfTerms, availableTermsCount)
                }
            }
        }
        
        isLoading = false
    }
    
    private func getAvailableTermsCount(for profile: UserProfile) -> Int {
        // FIXED: Aug 29, 2025 - Optimized term counting to reduce debug noise
        // ISSUE: Previously called enhanced service with 1000 terms just to count available terms
        // SOLUTION: Use direct database queries to count terms without enhanced service overhead
        let currentBeltSortOrder = profile.currentBeltLevel.sortOrder
        
        let descriptor: FetchDescriptor<TerminologyEntry>
        
        switch profile.learningMode {
        case .progression:
            // Current belt only
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate<TerminologyEntry> { entry in
                    entry.beltLevel.sortOrder == currentBeltSortOrder
                }
            )
            
        case .mastery:
            // Current + prior belts
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate<TerminologyEntry> { entry in
                    entry.beltLevel.sortOrder >= currentBeltSortOrder
                }
            )
        }
        
        do {
            let terms = try dataServices.terminologyService.modelContextForLoading.fetch(descriptor)
            return min(terms.count, profile.learningMode == .mastery ? 50 : terms.count)
        } catch {
            DebugLogger.data("❌ Config: Failed to count available terms: \(error)")
            return 0
        }
    }
    
    private func createFlashcardView() -> FlashcardView {
        // FIXED: Aug 29, 2025 - Removed redundant LeitnerService mode setting
        // ISSUE: Both configuration and FlashcardView were setting learning system mode
        // SOLUTION: Let FlashcardView handle the learning system setting to avoid double-setting
        let flashcardView = FlashcardView(
            specificTerms: specificTerms,
            initialConfiguration: FlashcardConfiguration(
                studyMode: studyMode,
                cardDirection: cardDirection,
                numberOfTerms: isReviewSession ? (specificTerms?.count ?? 20) : numberOfTerms,
                learningSystem: learningSystem
            )
        )
        
        return flashcardView
    }
}

// MARK: - Learning System Enum

enum LearningSystem: String, CaseIterable {
    case classic = "classic"
    case leitner = "leitner"
    
    var displayName: String {
        switch self {
        case .classic: return "Classic Mode"
        case .leitner: return "Leitner Mode"
        }
    }
    
    var description: String {
        switch self {
        case .classic: return "Simple flashcards with basic progress tracking"
        case .leitner: return "Advanced spaced repetition with 5-box scheduling"
        }
    }
}

// MARK: - Flashcard Configuration

struct FlashcardConfiguration {
    let studyMode: StudyMode
    let cardDirection: CardDirection
    let numberOfTerms: Int
    let learningSystem: LearningSystem
}

// MARK: - Supporting Components

struct ConfigurationSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            content()
        }
    }
}

struct StudyModeCard: View {
    let mode: StudyMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CardDirectionCard: View {
    let direction: CardDirection
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var isRecommended: Bool {
        direction == .bothDirections
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(direction.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        if isRecommended {
                            Text("⭐️")
                                .font(.caption)
                        }
                    }
                    
                    Text(direction.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.purple)
                }
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LearningSystemCard: View {
    let system: LearningSystem
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(system.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PreviewRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Extended Enums

extension StudyMode {
    var description: String {
        switch self {
        case .learn: return "Study all information together - no pressure, just learning"
        case .test: return "Test yourself with flashcard flipping - build active recall"
        }
    }
}

extension CardDirection {
    var description: String {
        switch self {
        case .englishToKorean: return "See English, recall Korean - builds production skills"
        case .koreanToEnglish: return "See Korean, recall English - builds comprehension"
        case .bothDirections: return "Random mix of both directions - most comprehensive"
        }
    }
}

// MARK: - Preview

struct FlashcardConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardConfigurationView(specificTerms: nil)
    }
}