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
            .frame(maxWidth: .infinity, minHeight: 120)
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
    var body: some View {
        VStack {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Patterns/Tul")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Traditional Taekwondo forms with detailed guidance")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Patterns")
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
                        
                        Text("Learning Mode: \\(profile.learningMode.displayName)")
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