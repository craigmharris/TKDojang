import SwiftUI

/**
 * MainTabCoordinatorView.swift
 * 
 * PURPOSE: Main authenticated user interface with tab-based navigation
 */
struct MainTabCoordinatorView: View {
    
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard/Home Tab
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Learn Tab
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)
            
            // Practice Tab
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "figure.martial.arts")
                }
                .tag(2)
            
            // Progress Tab
            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Placeholder Tab Views

struct DashboardView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to Your Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your training journey starts here.\nExplore techniques, start training sessions, and track your progress.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    NavigationLink(destination: FlashcardView()) {
                        Text("Study Korean Terms")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Browse Techniques") {
                        // TODO: Navigate to techniques
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher()
                }
            }
        }
    }
}

struct TechniquesView: View {
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
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Learning Center")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Master Korean terminology and test your knowledge")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    NavigationLink(destination: FlashcardView()) {
                        HStack {
                            Image(systemName: "rectangle.on.rectangle")
                                .frame(width: 24)
                            Text("Flashcards")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TestSelectionView()) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .frame(width: 24)
                            Text("Tests")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Learn")
        }
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
                        title: "Technique How-To",
                        description: "Detailed breakdowns of every technique",
                        icon: "magnifyingglass.circle.fill",
                        color: .purple,
                        destination: AnyView(TechniqueGuideView())
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Practice")
        }
    }
}

struct ProgressView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Your Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your training history, skill improvements, and belt progression.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Progress")
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
    @Environment(DataManager.self) private var dataManager
    @State private var patterns: [Pattern] = []
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    
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
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileSwitcher()
            }
        }
        .task {
            await loadPatterns()
        }
        .onChange(of: dataManager.profileService.activeProfile) {
            Task {
                await loadPatterns()
            }
        }
    }
    
    @MainActor
    private func loadPatterns() async {
        isLoading = true
        
        // Get the active profile from ProfileService
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, ensure we have at least one profile
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            patterns = dataManager.patternService.getPatternsForUser(userProfile: profile)
            print("🥋 Loaded \(patterns.count) patterns for user \(profile.name)")
        }
        
        isLoading = false
    }
}

// MARK: - Pattern Card Component

struct PatternCard: View {
    let pattern: Pattern
    let userProfile: UserProfile?
    @Environment(DataManager.self) private var dataManager
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
                
                // Progress indicator if user has started this pattern
                if let progress = userProgress {
                    PatternProgressIndicator(progress: progress)
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
        .task {
            loadUserProgress()
        }
    }
    
    private func loadUserProgress() {
        guard let profile = userProfile else { return }
        userProgress = dataManager.patternService.getUserProgress(for: pattern, userProfile: profile)
    }
}

// MARK: - Pattern Progress Indicator

struct PatternProgressIndicator: View {
    let progress: UserPatternProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress: \(Int(progress.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(progress.masteryLevel.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorForMastery(progress.masteryLevel))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(colorForMastery(progress.masteryLevel))
                        .frame(width: geometry.size.width * (progress.progressPercentage / 100.0), height: 4)
                }
            }
            .frame(height: 4)
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
                        .font(.title2)
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
                
                // Diagram section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pattern Diagram")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(pattern.diagramDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Diagram image if available
                    if let diagramURL = pattern.diagramImageURL, !diagramURL.isEmpty {
                        AsyncImage(url: URL(string: diagramURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("Diagram Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "square.grid.3x3")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Diagram Coming Soon")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .cornerRadius(12)
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
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// StepSparringView is now defined in StepSparring/StepSparringView.swift

struct LineWorkView: View {
    var body: some View {
        VStack {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Line Work")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Forward and backward technique drills")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Line Work")
        .navigationBarTitleDisplayMode(.large)
    }
}

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
    @Environment(DataManager.self) private var dataManager
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
                TestTakingView(testSession: session)
            }
        }
    }
    
    private func startComprehensiveTest() {
        // Get the active profile from ProfileService
        guard let userProfile = dataManager.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataManager.modelContext,
                    terminologyService: dataManager.terminologyService
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
        guard let userProfile = dataManager.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataManager.modelContext,
                    terminologyService: dataManager.terminologyService
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
    @Environment(DataManager.self) private var dataManager
    @State private var showingProfileManagement = false
    @State private var showingSettings = false
    @State private var userProfile: UserProfile?
    @State private var allProfiles: [UserProfile] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Profile Header
                    if let profile = userProfile {
                        ProfileHeaderCard(profile: profile)
                    }
                    
                    // Profile Management Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Family Profiles")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(allProfiles.count)/6")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProfileGridView(profiles: allProfiles, currentProfile: userProfile)
                        
                        if allProfiles.count < 6 {
                            Button("Add New Profile") {
                                showingProfileManagement = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Settings & Actions
                    VStack(spacing: 12) {
                        NavigationLink("Learning Settings") {
                            UserSettingsView()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        
                        Button("Manage All Profiles") {
                            showingProfileManagement = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadProfiles()
            }
            .onChange(of: dataManager.profileService.activeProfile) {
                loadProfiles()
            }
            .sheet(isPresented: $showingProfileManagement) {
                ProfileManagementView()
            }
        }
    }
    
    private func loadProfiles() {
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, create default
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        // Load all profiles
        do {
            allProfiles = try dataManager.profileService.getAllProfiles()
        } catch {
            print("❌ Failed to load profiles: \(error)")
            allProfiles = []
        }
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
    @Environment(DataManager.self) private var dataManager
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(profiles, id: \.id) { profile in
                ProfileGridCard(
                    profile: profile,
                    isActive: profile.id == currentProfile?.id,
                    onTap: { switchToProfile(profile) }
                )
            }
        }
    }
    
    private func switchToProfile(_ profile: UserProfile) {
        do {
            try dataManager.profileService.activateProfile(profile)
        } catch {
            print("❌ Failed to switch profile: \(error)")
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