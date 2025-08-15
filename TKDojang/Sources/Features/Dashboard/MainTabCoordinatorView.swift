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
            
            // Korean Terms Tab
            FlashcardView()
                .tabItem {
                    Label("Korean", systemImage: "textformat.abc")
                }
                .tag(1)
            
            // Training Tab
            TrainingView()
                .tabItem {
                    Label("Training", systemImage: "heart.circle")
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
        NavigationView {
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
        NavigationView {
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

struct TrainingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Training Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Structured workouts, forms practice, and skill development sessions.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Training")
        }
    }
}

struct ProgressView: View {
    var body: some View {
        NavigationView {
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

struct ProfileView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Environment(DataManager.self) private var dataManager
    @State private var showingSettings = false
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationView {
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