import SwiftUI
import Combine

/**
 * AppCoordinator.swift
 * 
 * PURPOSE: Central navigation coordinator that manages app-wide navigation flow
 * 
 * ARCHITECTURE PATTERN: Coordinator Pattern
 * WHY: Separates navigation logic from view controllers, making navigation
 * more testable, reusable, and easier to modify. Prevents tight coupling
 * between views and reduces massive view controller problem.
 */
class AppCoordinator: ObservableObject {
    
    // MARK: - Types
    
    /**
     * Enumeration of major application flows
     */
    enum AppFlow {
        case loading        // Initial app launch, checking authentication
        case onboarding     // First-time user experience
        case authentication // Login/signup flow
        case main          // Authenticated user's main app experience
    }
    
    // MARK: - Published Properties
    
    /**
     * Current application flow state
     */
    @Published var currentFlow: AppFlow = .loading
    
    /**
     * Global loading state for operations that affect the entire app
     */
    @Published var isLoading = false
    
    /**
     * Global error state for displaying app-wide errors
     */
    @Published var globalError: AppError?
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        determineInitialFlow()
    }
    
    // MARK: - Public Methods
    
    /**
     * Navigate to onboarding flow
     */
    func showOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .onboarding
        }
    }
    
    /**
     * Navigate to authentication flow
     */
    func showAuthentication() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .authentication
        }
    }
    
    /**
     * Navigate to main app flow
     */
    func showMainFlow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .main
        }
    }
    
    /**
     * Handle user logout
     */
    func logout() {
        isLoading = true
        
        // Simulate logout process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.showAuthentication()
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Determine the initial flow when app starts
     */
    private func determineInitialFlow() {
        // For now, start with onboarding
        // In a real app, you'd check UserDefaults for onboarding completion
        // and authentication status
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showOnboarding()
        }
    }
}

// MARK: - Preview Helpers

extension AppCoordinator {
    /**
     * Preview coordinator in onboarding state
     */
    static var previewOnboarding: AppCoordinator {
        let coordinator = AppCoordinator()
        coordinator.currentFlow = .onboarding
        return coordinator
    }
    
    /**
     * Preview coordinator in main flow state
     */
    static var previewMainFlow: AppCoordinator {
        let coordinator = AppCoordinator()
        coordinator.currentFlow = .main
        return coordinator
    }
    
    /**
     * Preview coordinator in loading state
     */
    static var previewLoading: AppCoordinator {
        let coordinator = AppCoordinator()
        coordinator.currentFlow = .loading
        return coordinator
    }
}

// MARK: - Temporary Error Type

/**
 * Placeholder error type - will be replaced with full implementation
 */
enum AppError: Error {
    case unknown
}