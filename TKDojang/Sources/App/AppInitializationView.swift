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
        DebugLogger.ui("🔧 AppInitializationView.init() - Initialization view being created - \(Date())")
    }
    
    var body: some View {
        DebugLogger.ui("🔄 AppInitializationView.body - DataManager ready: \(isDataManagerReady) - \(Date())")
        
        if isDataManagerReady {
            // PHASE 2: DataServices is ready, show full app with data services
            DebugLogger.ui("✅ Showing full app with DataServices context - \(Date())")
            return AnyView(
                ContentView()
                    .environmentObject(appCoordinator)
            )
        } else {
            // PHASE 1: Show loading screen immediately, NO DataManager access
            DebugLogger.ui("⏳ Showing loading screen with no data dependencies - \(Date())")
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
        DebugLogger.ui("🔧 Starting DataServices initialization in background... - \(Date())")

        Task {
            // UI Testing: Create test profiles FIRST (synchronously)
            await createTestProfilesIfNeeded()

            // THEN ensure minimum loading time for belt progression animation
            try? await Task.sleep(nanoseconds: 4_400_000_000) // 4.4 seconds for belt animation (11 belts × 0.4s)

            DebugLogger.ui("✅ DataServices initialization ready, transitioning to main app - \(Date())")

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

    /**
     * Creates test profiles for UI testing if requested via launch argument
     *
     * PURPOSE: UI tests need multiple profiles with different belts to test
     * profile switching and data isolation. Creating them programmatically
     * avoids fragile UI navigation during test setup.
     */
    private func createTestProfilesIfNeeded() async {
        // Check if running in UI test mode with profile creation request
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("UI-Testing"),
              arguments.contains("CreateTestProfiles") else {
            return
        }

        print("🧪 UI Testing: Creating test profiles...")
        DebugLogger.ui("🧪 UI Testing: Creating test profiles...")

        await MainActor.run {
            let profileService = DataServices.shared.profileService
            let modelContext = DataServices.shared.modelContext

            do {
                // Check how many profiles exist
                let existingProfiles = try profileService.getAllProfiles()
                print("🧪 Found \(existingProfiles.count) existing profile(s)")

                if existingProfiles.count < 2 {
                    print("🧪 Creating additional test profiles (current count: \(existingProfiles.count))")
                    DebugLogger.ui("🧪 Creating additional test profiles (current count: \(existingProfiles.count))")

                    // Fetch belt levels from database
                    let allBelts = BeltUtils.fetchAllBeltLevels(from: modelContext)
                    print("🧪 Fetched \(allBelts.count) belt levels from database")

                    // Find specific belt levels
                    guard let sixthKeup = allBelts.first(where: { $0.shortName == "6th Keup" }),
                          let secondKeup = allBelts.first(where: { $0.shortName == "2nd Keup" }),
                          let firstDan = allBelts.first(where: { $0.shortName == "1st Dan" }) else {
                        print("❌ Could not find required belt levels in database")
                        DebugLogger.ui("❌ Could not find required belt levels in database")
                        return
                    }

                    print("✅ Found required belt levels")

                    // Create profiles with different belt levels for testing
                    let testProfiles: [(name: String, beltLevel: BeltLevel)] = [
                        ("Test Student", sixthKeup),      // 6th Keup - fewer patterns available
                        ("Advanced Student", secondKeup),  // 2nd Keup - more patterns available
                        ("Black Belt", firstDan)
                    ]

                    for (index, profileData) in testProfiles.enumerated() {
                        // Skip if we already have enough profiles
                        if existingProfiles.count + index >= 3 {
                            break
                        }

                        do {
                            let profile = try profileService.createProfile(
                                name: profileData.name,
                                beltLevel: profileData.beltLevel
                            )
                            print("✅ Created test profile: \(profile.name) (\(profile.currentBeltLevel.shortName))")
                            DebugLogger.ui("✅ Created test profile: \(profile.name) (\(profile.currentBeltLevel.shortName))")
                        } catch {
                            print("❌ Failed to create test profile: \(error)")
                            DebugLogger.ui("❌ Failed to create test profile: \(error)")
                        }
                    }

                    let finalCount = try profileService.getAllProfiles().count
                    print("🧪 Test profile creation complete (total: \(finalCount) profiles)")
                    DebugLogger.ui("🧪 Test profile creation complete (total: \(finalCount) profiles)")
                } else {
                    print("🧪 Sufficient profiles exist (\(existingProfiles.count)), skipping creation")
                    DebugLogger.ui("🧪 Sufficient profiles exist (\(existingProfiles.count)), skipping creation")
                }
            } catch {
                print("❌ Failed to get or create test profiles: \(error)")
                DebugLogger.ui("❌ Failed to get or create test profiles: \(error)")
            }
        }
    }
}