import SwiftUI

/**
 * ContentView.swift
 * 
 * PURPOSE: Root view that manages the overall app navigation flow
 * 
 * ARCHITECTURE DECISION: Uses coordinator pattern for navigation
 * WHY: Separates navigation logic from view logic, making the app more
 * testable and easier to modify navigation flows.
 * 
 * RESPONSIBILITIES:
 * - Display the appropriate view based on app state
 * - Handle navigation transitions between major app flows
 * - Manage loading states and error handling
 */
struct ContentView: View {
    
    /**
     * App coordinator that determines which view to show
     * 
     * WHY: @EnvironmentObject allows this coordinator to be shared
     * throughout the app hierarchy without prop drilling
     */
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    /**
     * Data manager for tracking database resets
     * Forces complete UI refresh when database is recreated
     */
    @Environment(DataManager.self) private var dataManager
    
    var body: some View {
        Group {
            if dataManager.isResettingDatabase {
                // Show loading screen during database reset to prevent any profile access
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2.0)
                    Text("Resetting Database...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            } else {
                switch appCoordinator.currentFlow {
                case .loading:
                    LoadingView()
                        .transition(.opacity)
                    
                case .onboarding:
                    OnboardingCoordinatorView()
                        .transition(.move(edge: .trailing))
                    
                case .main:
                    MainTabCoordinatorView()
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appCoordinator.currentFlow)
        .animation(.easeInOut(duration: 0.3), value: dataManager.isResettingDatabase)
        .id(dataManager.databaseResetId) // Force complete refresh when database is reset
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppCoordinator.previewLoading)
    }
}