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
        .task {
            await loadPatterns()
        }
    }
    
    @MainActor
    private func loadPatterns() async {
        isLoading = true
        userProfile = dataManager.getOrCreateDefaultUserProfile()
        
        if let profile = userProfile {
            patterns = dataManager.patternService.getPatternsForUser(userProfile: profile)
            print("🥋 Loaded \(patterns.count) patterns for user")
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
                
                // TODO: Add pattern practice interface
                Text("Pattern practice interface coming soon...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StepSparringView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.2.arms.open")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Step Sparring")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Practice 3, 2, and 1-step sparring sequences")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Step Sparring")
        .navigationBarTitleDisplayMode(.large)
    }
}

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
        let userProfile = dataManager.getOrCreateDefaultUserProfile()
        
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
        let userProfile = dataManager.getOrCreateDefaultUserProfile()
        
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
    @State private var showingSettings = false
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Your Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("TKDojang Student")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let profile = userProfile {
                        Text(profile.currentBeltLevel.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)
                        
                        Text("Learning Mode: \(profile.learningMode.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Learning Settings") {
                        showingSettings = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Sign Out") {
                        appCoordinator.logout()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
            .onAppear {
                loadUserProfile()
            }
            .sheet(isPresented: $showingSettings) {
                UserSettingsView()
            }
        }
    }
    
    private func loadUserProfile() {
        userProfile = dataManager.getOrCreateDefaultUserProfile()
    }
}

struct MainTabCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabCoordinatorView()
            .environmentObject(AppCoordinator.previewMainFlow)
    }
}