import SwiftUI
import SwiftData

/**
 * MainTabCoordinatorView.swift
 * 
 * PURPOSE: Main authenticated user interface with tab-based navigation
 */
struct MainTabCoordinatorView: View {

    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject private var dataServices: DataServices
    @StateObject private var onboardingCoordinator = OnboardingCoordinator()
    @State private var selectedTab = 0
    @State private var showingWhatsNew = false
    @State private var showingMyFeedback = false
    @State private var selectedFeedbackID: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard/Home Tab
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
                .accessibilityIdentifier("navigation-tab-home")

            // Learn Tab
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)
                .accessibilityIdentifier("navigation-tab-learn")

            // Practice Tab
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "figure.martial.arts")
                }
                .tag(2)
                .accessibilityIdentifier("navigation-tab-practice")

            // Progress Tab - using stub due to SwiftData relationship issues
            ProgressViewStub()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
                .accessibilityIdentifier("navigation-tab-progress")

            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
                .accessibilityIdentifier("navigation-tab-profile")
        }
        .id("MainTabCoordinator-\(dataServices.databaseResetId.uuidString)")
        .environmentObject(onboardingCoordinator)
        .accentColor(.blue)
        .onAppear {
            // Check if we should show What's New
            showingWhatsNew = WhatsNewView.shouldShow()
        }
        .sheet(isPresented: $showingWhatsNew) {
            WhatsNewView()
        }
        .sheet(isPresented: $showingMyFeedback) {
            MyFeedbackView(highlightFeedbackID: selectedFeedbackID)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppDelegate.openFeedbackNotification)) { notification in
            // Handle notification tap - open My Feedback view
            if let feedbackID = notification.userInfo?[AppDelegate.feedbackIDKey] as? String {
                print("🔗 MainTabCoordinator: Opening feedback: \(feedbackID)")
                selectedFeedbackID = feedbackID
                showingMyFeedback = true
            }
        }
    }
}

// MARK: - Placeholder Tab Views

struct DashboardView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var userProfile: UserProfile?
    @State private var activeProfileId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Welcome Header
                    if let profile = userProfile {
                        PersonalizedWelcomeCard(profile: profile)
                    } else {
                        // Fallback for no profile
                        VStack(spacing: 16) {
                            Image(systemName: "figure.martial.arts")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Welcome to TKDojang")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Your martial arts journey begins here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }

                    // Quick Action Navigation Cards
                    QuickActionGrid()

                    // Recent Activity Section (if profile exists)
                    if let profile = userProfile {
                        RecentActivityCard(profile: profile)
                    }

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .id("DashboardView-\(activeProfileId?.uuidString ?? "none")")
            .onAppear {
                loadUserProfile()
            }
            .onReceive(dataServices.objectWillChange) { _ in
                // Refresh profile when DataServices changes (e.g., profile switch)
                let newProfileId = dataServices.profileService.getActiveProfile()?.id
                if newProfileId != activeProfileId {
                    activeProfileId = newProfileId
                }
                loadUserProfile()
            }
        }
    }

    private func loadUserProfile() {
        userProfile = dataServices.profileService.getActiveProfile()

        // If no active profile, create/get default
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }

        activeProfileId = userProfile?.id
    }
}

// MARK: - Personalized Welcome Card

struct PersonalizedWelcomeCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Header
            HStack(spacing: 16) {
                // Avatar
                Image(systemName: profile.avatar.rawValue)
                    .font(.system(size: 50))
                    .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                    )
                
                // Welcome Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Belt Level Badge
                    HStack(spacing: 8) {
                        Text(profile.currentBeltLevel.shortName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(profile.colorTheme.primarySwiftUIColor)
                            )
                        
                        if profile.streakDays > 0 {
                            Text("🔥 \(profile.streakDays) day streak")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Progress Summary
            HStack(spacing: 20) {
                ProgressStat(title: "Flashcards", value: profile.totalFlashcardsSeen, color: .blue)
                ProgressStat(title: "Tests Taken", value: profile.totalTestsTaken, color: .green)
                ProgressStat(title: "Patterns", value: profile.totalPatternsLearned, color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Progress Stat Component

struct ProgressStat: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Grid

struct QuickActionGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                
                QuickActionCard(
                    title: "Learn",
                    subtitle: "Flashcards, Tests & Theory",
                    icon: "book.fill",
                    color: .blue,
                    destination: AnyView(LearnView())
                )
                
                QuickActionCard(
                    title: "Practice",
                    subtitle: "Patterns, Sparring & Line Work",
                    icon: "figure.martial.arts",
                    color: .red,
                    destination: AnyView(PracticeView())
                )
                
                QuickActionCard(
                    title: "Progress",
                    subtitle: "Track your improvement",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    destination: AnyView(ProgressViewStub())
                )
                
                QuickActionCard(
                    title: "Profile",
                    subtitle: "Manage your settings",
                    icon: "person.circle",
                    color: .purple,
                    destination: AnyView(ProfileView())
                )
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "clock", 
                    text: "Last active \(timeAgoText(from: profile.lastActiveAt))",
                    color: .blue
                )
                
                if profile.totalFlashcardsSeen > 0 {
                    ActivityRow(
                        icon: "rectangle.on.rectangle",
                        text: "\(profile.totalFlashcardsSeen) flashcards studied",
                        color: .green
                    )
                }
                
                if profile.totalTestsTaken > 0 {
                    ActivityRow(
                        icon: "checkmark.circle",
                        text: "\(profile.totalTestsTaken) tests completed",
                        color: .orange
                    )
                }
                
                if profile.totalPatternsLearned > 0 {
                    ActivityRow(
                        icon: "square.grid.3x3",
                        text: "\(profile.totalPatternsLearned) patterns learned",
                        color: .purple
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }
    
    private func timeAgoText(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "recently"
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct TechniquesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Technique Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Learn kicks, blocks, strikes, and forms with step-by-step video guides.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Techniques")
        }
    }
}

struct LearnView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var dataServices: DataServices
    @State private var userProfile: UserProfile?
    @State private var activeProfileId: UUID?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Learning Center")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Master Korean terminology, theory knowledge, and test your understanding")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // 2x2 Grid Layout
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    // Row 1: Vocabulary Builder, Flashcards
                    if let profile = userProfile {
                        LearnMenuCard(
                            title: "Vocabulary Builder",
                            description: "Interactive games for phrase grammar",
                            icon: "character.book.closed",
                            color: .orange,
                            destination: AnyView(VocabularyBuilderView(modelContext: modelContext, userProfile: profile))
                        )
                    }

                    LearnMenuCard(
                        title: "Flashcards",
                        description: "Study Korean terminology",
                        icon: "rectangle.on.rectangle",
                        color: .blue,
                        destination: AnyView(FlashcardConfigurationView(specificTerms: nil))
                    )

                    // Row 2: Tests, Theory
                    LearnMenuCard(
                        title: "Tests",
                        description: "Multiple choice assessments",
                        icon: "checkmark.circle",
                        color: .green,
                        destination: AnyView(MultipleChoiceConfigurationView())
                    )

                    LearnMenuCard(
                        title: "Theory",
                        description: "Belt-specific knowledge",
                        icon: "graduationcap",
                        color: .purple,
                        destination: AnyView(TheoryView())
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Learn")
            .id("LearnView-\(activeProfileId?.uuidString ?? "none")")
            .onAppear {
                loadUserProfile()
            }
            .onReceive(dataServices.objectWillChange) { _ in
                // Refresh profile when DataServices changes (e.g., profile switch)
                let newProfileId = dataServices.profileService.getActiveProfile()?.id
                if newProfileId != activeProfileId {
                    activeProfileId = newProfileId
                    loadUserProfile()
                }
            }
        }
    }

    private func loadUserProfile() {
        userProfile = dataServices.profileService.getActiveProfile()
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }
        activeProfileId = userProfile?.id
    }
}

// MARK: - Learn Menu Card Component

struct LearnMenuCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView
    var accessibilityId: String {
        "learn-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-button"
    }

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(description)
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
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(accessibilityId)
    }
}

struct PracticeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Practice Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Master your techniques with structured practice sessions")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    
                    PracticeMenuCard(
                        title: "Patterns/Tul",
                        description: "Traditional forms with step-by-step guidance",
                        icon: "square.grid.3x3.fill",
                        color: .blue,
                        destination: AnyView(PatternsView())
                    )
                    
                    PracticeMenuCard(
                        title: "Step Sparring",
                        description: "3, 2, and 1-step sparring techniques",
                        icon: "figure.2.arms.open",
                        color: .orange,
                        destination: AnyView(StepSparringView())
                    )
                    
                    PracticeMenuCard(
                        title: "Line Work",
                        description: "Forward/backward technique drills",
                        icon: "arrow.left.and.right",
                        color: .green,
                        destination: AnyView(LineWorkView())
                    )
                    
                    PracticeMenuCard(
                        title: "Techniques",
                        description: "Comprehensive technique reference",
                        icon: "books.vertical.fill",
                        color: .purple,
                        destination: AnyView(TechniquesView())
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Practice")
        }
    }
}

// MARK: - Practice Menu Components

struct PracticeMenuCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(description)
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
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Practice Section Placeholder Views

struct PatternsView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var patterns: [Pattern] = []
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var activeProfileId: UUID?
    @State private var showingHelp = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Patterns/Tul")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Traditional Taekwondo forms with detailed guidance")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading patterns...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                    .frame(maxHeight: .infinity)
            } else if patterns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No patterns available")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Patterns will be available based on your current belt level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Pattern list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(patterns, id: \.id) { pattern in
                            PatternCard(pattern: pattern, userProfile: userProfile)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Patterns")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: { showingHelp = true }) {
                    Label("Help", systemImage: "questionmark.circle")
                }
                .accessibilityIdentifier("patterns-help-button")
                .accessibilityLabel("Show pattern selection help")
            }
        }
        .sheet(isPresented: $showingHelp) {
            PatternsHelpSheet()
        }
        .id("PatternsView-\(activeProfileId?.uuidString ?? "none")")
        .task(id: activeProfileId) {
            // Reload patterns whenever active profile ID changes
            await loadPatterns()
        }
        .onAppear {
            // Update profile ID to trigger task reload
            activeProfileId = dataServices.profileService.getActiveProfile()?.id
        }
        .onReceive(dataServices.objectWillChange) { _ in
            // Force reload when DataServices changes (profile switch)
            let newProfileId = dataServices.profileService.getActiveProfile()?.id
            if newProfileId != activeProfileId {
                activeProfileId = newProfileId
            }
        }
    }
    
    @MainActor
    private func loadPatterns() async {
        isLoading = true
        
        // Get the active profile from ProfileService
        userProfile = dataServices.profileService.getActiveProfile()
        
        // If no active profile, ensure we have at least one profile
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            patterns = dataServices.patternService.getPatternsForUser(userProfile: profile)
            DebugLogger.data("🥋 Loaded \(patterns.count) patterns for user \(profile.name)")
        }
        
        isLoading = false
    }
}

// MARK: - Pattern Card Component

struct PatternCard: View {
    let pattern: Pattern
    let userProfile: UserProfile?
    @EnvironmentObject private var dataServices: DataServices
    @State private var userProgress: UserPatternProgress?
    
    var body: some View {
        NavigationLink(destination: PatternDetailView(pattern: pattern)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with pattern name and meaning
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(pattern.englishMeaning)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Move count badge
                    Text("\(pattern.moveCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                // Pattern diagram thumbnail - prominent and centered
                if let diagramURL = pattern.diagramImageURL, !diagramURL.isEmpty {
                    HStack {
                        Spacer()
                        Image(diagramURL)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 80)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .clipped()
                            .onAppear {
                                DebugLogger.ui("🖼️ Loading pattern diagram: '\(diagramURL)' for pattern \(pattern.name)")
                            }
                        Spacer()
                    }
                }
                
                // Progress indicator if user has started this pattern
                if let progress = userProgress {
                    PatternProgressIndicator(progress: progress, pattern: pattern)
                }
                
                // Belt level indicator
                HStack {
                    ForEach(pattern.orderedBeltLevels.prefix(3), id: \.id) { belt in
                        Text(belt.shortName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if pattern.beltLevels.count > 3 {
                        Text("+\(pattern.beltLevels.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("pattern-card-\(pattern.id)")
        .task {
            loadUserProgress()
        }
    }
    
    private func loadUserProgress() {
        guard let profile = userProfile else { return }
        userProgress = dataServices.patternService.getUserProgress(for: pattern, userProfile: profile)
    }
}

// MARK: - Pattern Progress Indicator

/**
 * PatternProgressIndicator: Belt-themed progress display for pattern list
 * 
 * FEATURES:
 * - Shows "Completed" in green when pattern reaches 100% progress
 * - Uses BeltProgressBar with proper belt colors and tag belt striping
 * - Consistent visual design with PatternPracticeView progress display
 */
struct PatternProgressIndicator: View {
    let progress: UserPatternProgress
    let pattern: Pattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress: \(Int(progress.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(progress.progressPercentage >= 100.0 ? "Completed" : progress.masteryLevel.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progress.progressPercentage >= 100.0 ? .green : colorForMastery(progress.masteryLevel))
            }
            
            BeltProgressBar(
                progress: progress.progressPercentage / 100.0,
                theme: BeltTheme(from: pattern.primaryBeltLevel ?? pattern.beltLevels.first!)
            )
            .frame(height: 6)
        }
    }
    
    private func colorForMastery(_ level: PatternMasteryLevel) -> Color {
        switch level {
        case .learning: return .red
        case .familiar: return .orange
        case .proficient: return .blue
        case .mastered: return .green
        }
    }
}

// MARK: - Pattern Detail View (Placeholder)

struct PatternDetailView: View {
    let pattern: Pattern
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Pattern header
                VStack(alignment: .center, spacing: 12) {
                    Text(pattern.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.hangul)
                        .koreanFont(size: 22)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.englishMeaning)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.significance)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                }
                
                Divider()
                
                // Pattern details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Moves:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("\(pattern.moveCount)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Ready Position:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(pattern.startingStance)
                            .font(.subheadline)
                    }
                }
                
                // Starting Move section
                if let startingMoveURL = pattern.startingMoveImageURL, !startingMoveURL.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Starting Move")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(startingMoveURL)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onAppear {
                                DebugLogger.ui("🖼️ Loading starting move image: '\(startingMoveURL)' for pattern \(pattern.name)")
                            }
                    }
                }
                
                // Practice Interface Button
                NavigationLink(destination: PatternPracticeView(pattern: pattern)) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Practice")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Interactive step-by-step guidance")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("pattern-practice-button")
                
                // Test Interface Button
                NavigationLink(destination: PatternTestView(pattern: pattern)) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Test Knowledge")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Test sequence and technique memory")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// StepSparringView is now defined in StepSparring/StepSparringView.swift

// LineWorkView is now defined in LineWork/LineWorkView.swift

struct TechniqueGuideView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Technique Guide")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Detailed breakdowns of every technique and stance")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Technique Guide")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TestSelectionView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var isStartingTest = false
    @State private var testSession: TestSession?
    @State private var showingTest = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Test Your Knowledge")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Comprehensive tests to validate your learning progress")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("Comprehensive Test") {
                    startComprehensiveTest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isStartingTest)
                
                Button("Quick Test (5-10 questions)") {
                    startQuickTest()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isStartingTest)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
            }
            .padding(.horizontal)
            
            if isStartingTest {
                VStack {
                    ProgressView()
                    Text("Preparing your test...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Tests")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingTest) {
            if let session = testSession {
                TestTakingView(
                    testSession: session,
                    dismissToLearn: {
                        // This is already in the Learn tab, so just dismiss the test view
                        showingTest = false
                    }
                )
            }
        }
    }
    
    private func startComprehensiveTest() {
        // Get the active profile from ProfileService
        guard let userProfile = dataServices.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataServices.modelContext,
                    terminologyService: dataServices.terminologyService
                )
                
                let session = try testingService.createComprehensiveTest(for: userProfile)
                self.testSession = session
                self.showingTest = true
            } catch {
                self.errorMessage = "Failed to create test: \(error.localizedDescription)"
            }
            
            self.isStartingTest = false
        }
    }
    
    private func startQuickTest() {
        // Get the active profile from ProfileService
        guard let userProfile = dataServices.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataServices.modelContext,
                    terminologyService: dataServices.terminologyService
                )
                
                let session = try testingService.createQuickTest(for: userProfile)
                self.testSession = session
                self.showingTest = true
            } catch {
                self.errorMessage = "Failed to create test: \(error.localizedDescription)"
            }
            
            self.isStartingTest = false
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject private var dataServices: DataServices
    @State private var showingProfileManagement = false
    @State private var showingSettings = false
    @State private var userProfile: UserProfile?
    @State private var allProfiles: [UserProfile] = []
    @State private var activeProfileId: UUID?

    var body: some View {
        NavigationStack {
            List {
                // Current Profile Header
                if let profile = userProfile {
                    Section {
                        ProfileHeaderCard(profile: profile)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }

                // Profile Management Section
                Section {
                    HStack {
                        Text("Family Profiles")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(allProfiles.count)/6")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Family Profiles, \(allProfiles.count) of 6")

                    ProfileGridView(profiles: allProfiles, currentProfile: userProfile, onProfileSwitch: switchToProfile)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .accessibilityIdentifier("profile-grid")

                    if allProfiles.count < 6 {
                        Button {
                            showingProfileManagement = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .accessibilityHidden(true)
                                Text("Add New Profile")
                                Spacer()
                            }
                            .foregroundStyle(.blue)
                        }
                        .accessibilityLabel("Add New Profile")
                        .accessibilityHint("Double tap to create a new family profile")
                        .accessibilityIdentifier("profile-add-new")
                    }

                    ProfileNavigationRow(
                        icon: "person.2.fill",
                        iconColor: .purple,
                        title: "Manage All Profiles",
                        subtitle: "Edit, delete, or switch profiles"
                    ) {
                        showingProfileManagement = true
                    }
                }

                // Settings Section
                Section("Settings") {
                    ProfileNavigationLink(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        title: "Learning Settings",
                        subtitle: "Customize your learning experience"
                    ) {
                        UserSettingsView()
                    }
                }

                // Community Section
                Section("Community") {
                    ProfileNavigationLink(
                        icon: "person.3.fill",
                        iconColor: .blue,
                        title: "Community Hub",
                        subtitle: "Feedback, roadmap, and insights"
                    ) {
                        AboutCommunityHubView(userProfile: userProfile)
                    }
                }

                // About Section
                Section("About") {
                    ProfileNavigationLink(
                        icon: "info.circle.fill",
                        iconColor: .orange,
                        title: "About TKDojang",
                        subtitle: "Mission, credits, and privacy"
                    ) {
                        AboutView()
                    }

                    ProfileNavigationRow(
                        icon: "arrow.clockwise.circle.fill",
                        iconColor: .green,
                        title: "Replay Welcome Tour",
                        subtitle: "See the onboarding tutorial again"
                    ) {
                        replayWelcomeTour()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .id("ProfileView-\(activeProfileId?.uuidString ?? "none")")
            .onAppear {
                loadProfiles()
            }
            .onReceive(dataServices.objectWillChange) { _ in
                // Refresh profiles when DataServices changes (e.g., profile switch)
                let newProfileId = dataServices.profileService.getActiveProfile()?.id
                if newProfileId != activeProfileId {
                    activeProfileId = newProfileId
                }
                loadProfiles()
            }
            .sheet(isPresented: $showingProfileManagement) {
                ProfileManagementView()
                    .environmentObject(appCoordinator)
            }
        }
    }

    private func loadProfiles() {
        userProfile = dataServices.profileService.getActiveProfile()

        // If no active profile, create default
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }

        activeProfileId = userProfile?.id

        // Load all profiles
        do {
            allProfiles = try dataServices.profileService.getAllProfiles()
        } catch {
            DebugLogger.data("❌ Failed to load profiles: \(error)")
            allProfiles = []
        }
    }

    private func switchToProfile(_ profile: UserProfile) {
        do {
            DebugLogger.profile("🔄 ProfileGridView: Switching to profile: \(profile.name)")
            try dataServices.profileService.activateProfile(profile)

            // Immediately refresh the parent view's data
            loadProfiles()

            // Notify other views of the change
            dataServices.objectWillChange.send()

            DebugLogger.profile("✅ ProfileGridView: Profile switch completed, UI should update")
        } catch {
            DebugLogger.data("❌ Failed to switch profile: \(error)")
        }
    }

    /**
     * Replay the welcome tour
     *
     * WHY: Users may want to see the onboarding tour again after skipping it
     * or to refresh their understanding of app features
     */
    private func replayWelcomeTour() {
        // Create onboarding coordinator and trigger replay
        let onboardingCoordinator = OnboardingCoordinator()
        onboardingCoordinator.replayInitialTour()

        // Navigate to onboarding flow
        appCoordinator.currentFlow = .onboarding

        DebugLogger.ui("🔄 User triggered welcome tour replay from profile screen")
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Image(systemName: profile.avatar.rawValue)
                .font(.system(size: 50))
                .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                .frame(width: 70, height: 70)
                .background(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                .clipShape(Circle())
            
            // Profile Info
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text(profile.currentBeltLevel.shortName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(profile.colorTheme.primarySwiftUIColor.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(profile.learningMode.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatBadge(title: "Streak", value: "\(profile.streakDays)")
                    StatBadge(title: "Flashcards", value: "\(profile.totalFlashcardsSeen)")
                    StatBadge(title: "Tests", value: "\(profile.totalTestsTaken)")
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Profile Grid View

struct ProfileGridView: View {
    let profiles: [UserProfile]
    let currentProfile: UserProfile?
    let onProfileSwitch: (UserProfile) -> Void
    @EnvironmentObject private var dataServices: DataServices
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(profiles, id: \.id) { profile in
                ProfileGridCard(
                    profile: profile,
                    isActive: profile.id == currentProfile?.id,
                    onTap: { onProfileSwitch(profile) }
                )
            }
        }
    }
}

// MARK: - Profile Grid Card

struct ProfileGridCard: View {
    let profile: UserProfile
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Avatar with active indicator
                ZStack {
                    Image(systemName: profile.avatar.rawValue)
                        .font(.system(size: 24))
                        .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                        .frame(width: 50, height: 50)
                        .background(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    if isActive {
                        Circle()
                            .stroke(profile.colorTheme.primarySwiftUIColor, lineWidth: 3)
                            .frame(width: 58, height: 58)
                    }
                }
                
                Text(profile.name)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? profile.colorTheme.primarySwiftUIColor : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(profile.currentBeltLevel.shortName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? profile.colorTheme.primarySwiftUIColor.opacity(0.1) : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? profile.colorTheme.primarySwiftUIColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
    }
}


struct MainTabCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabCoordinatorView()
            .environmentObject(AppCoordinator.previewMainFlow)
    }
}