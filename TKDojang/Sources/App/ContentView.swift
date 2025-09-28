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
    
    init() {
        print("📄 ContentView.init() - ContentView being created - \(Date())")
    }
    
    /**
     * App coordinator that determines which view to show
     * 
     * WHY: @EnvironmentObject allows this coordinator to be shared
     * throughout the app hierarchy without prop drilling
     */
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    // DataManager is intentionally not accessed here to prevent blocking during initial app launch
    // It will be added via  only when needed (e.g., main flow)
    
    var body: some View {
        print("🔄 ContentView.body - Flow is: \(appCoordinator.currentFlow) - \(Date())")
        // NOTE: No DataManager access in this view to prevent blocking during app launch
        return Group {
            switch appCoordinator.currentFlow {
            case .loading:
                print("⏳ Creating LoadingView...")
                return AnyView(LoadingView()
                    .transition(.opacity))
                
            case .onboarding:
                print("🎯 Creating OnboardingCoordinatorView...")
                return AnyView(OnboardingCoordinatorView()
                    .transition(.move(edge: .trailing)))
                
            case .main:
                print("🏠 Creating MainTabCoordinatorView with DataServices... - \(Date())")
                return AnyView(MainTabCoordinatorView()
                    .transition(.move(edge: .bottom)))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppCoordinator.previewLoading)
    }
}