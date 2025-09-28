import SwiftUI

/**
 * TKDojangApp.swift
 * 
 * PURPOSE: Main entry point for the TKDojang App
 * 
 * ARCHITECTURE DECISION: Using SwiftUI App lifecycle (iOS 14+)
 * WHY: Provides modern declarative app structure, automatic scene management,
 * and better integration with SwiftUI views throughout the app.
 * 
 * RESPONSIBILITIES:
 * - Initialize app-wide dependencies
 * - Configure global app state
 * - Set up the root coordinator pattern
 * - Handle app lifecycle events
 */
@main
struct TKDojangApp: App {
    
    init() {
        print("🏁 TKDojangApp.init() - App struct being created - \(Date())")
        print("🚀 TKDojang App Starting... - \(Date())")
    }
    
    // MARK: - Properties
    
    /**
     * App coordinator that manages navigation flow throughout the entire application
     * 
     * WHY: Coordinator pattern separates navigation logic from view controllers,
     * making the app more testable and navigation flow easier to modify
     */
    @StateObject private var appCoordinator = {
        print("📋 Creating AppCoordinator... - \(Date())")
        return AppCoordinator()
    }()
    
    
    /**
     * User settings that persist across app launches
     * 
     * WHY: Using @AppStorage for simple user preferences provides automatic
     * UserDefaults integration with SwiftUI's reactive updates
     */
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("preferredLanguage") private var preferredLanguage = "en"
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            AppInitializationView()
                .environmentObject(appCoordinator)
                .environmentObject(DataServices.shared)
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Configures the app's initial state when it first appears
     * 
     * PURPOSE: Centralizes app initialization logic that needs to run once
     * when the app starts, such as checking authentication status,
     * setting up analytics, or restoring user preferences.
     */
    private func setupInitialState() {
        print("📱 Setting up initial state...")
        
        // TODO: Check authentication status
        // TODO: Initialize analytics
        // TODO: Load user preferences
        // TODO: Check for pending data synchronization
        
        // Navigate to appropriate initial screen based on onboarding status
        if hasCompletedOnboarding {
            print("✅ User has completed onboarding, showing main flow")
            appCoordinator.showMainFlow()
        } else {
            print("🎯 User needs onboarding, showing onboarding flow")
            appCoordinator.showOnboarding()
        }
    }
}