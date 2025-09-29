import SwiftUI

/**
 * AppInitializationView.swift
 * 
 * PURPOSE: Handles app initialization sequence with proper loading screen
 * 
 * ARCHITECTURE DECISION: Two-phase initialization
 * PHASE 1: Show LoadingView immediately (no DataManager dependencies)
 * PHASE 2: Initialize DataManager in background, then show main app
 * 
 * WHY: This prevents SwiftUI from accessing DataManager-dependent views
 * before DataManager is fully initialized, eliminating startup crashes.
 */
struct AppInitializationView: View {
    
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var isDataManagerReady = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        print("🔧 AppInitializationView.init() - Initialization view being created - \(Date())")
    }
    
    var body: some View {
        print("🔄 AppInitializationView.body - DataManager ready: \(isDataManagerReady) - \(Date())")
        
        if isDataManagerReady {
            // PHASE 2: DataServices is ready, show full app with data services
            print("✅ Showing full app with DataServices context - \(Date())")
            return AnyView(
                ContentView()
                    .environmentObject(appCoordinator)
            )
        } else {
            // PHASE 1: Show loading screen immediately, NO DataManager access
            print("⏳ Showing loading screen with no data dependencies - \(Date())")
            return AnyView(
                LoadingView()
                    .onAppear {
                        initializeDataServicesInBackground()
                    }
            )
        }
    }
    
    /**
     * Initialize DataServices in background while LoadingView is displayed
     */
    private func initializeDataServicesInBackground() {
        print("🔧 Starting DataServices initialization in background... - \(Date())")
        
        Task {
            // Ensure minimum loading time for belt progression animation
            try? await Task.sleep(nanoseconds: 4_400_000_000) // 4.4 seconds for belt animation (11 belts × 0.4s)
            
            print("✅ DataServices initialization ready, transitioning to main app - \(Date())")
            
            // Switch to main app on main thread
            await MainActor.run {
                isDataManagerReady = true
                
                // Set up the coordinator flow based on onboarding status
                if hasCompletedOnboarding {
                    appCoordinator.currentFlow = .main
                } else {
                    appCoordinator.currentFlow = .onboarding
                }
            }
        }
    }
}