import SwiftUI
import Combine
import SwiftData

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
        case loading        // Initial app launch, loading data
        case onboarding     // First-time user experience
        case main          // Main app experience with profiles
    }
    
    // MARK: - Published Properties
    
    /**
     * Current application flow state
     */
    @Published var currentFlow: AppFlow = .loading {
        didSet {
            DebugLogger.ui("🔀 AppCoordinator: currentFlow changed from \(oldValue) to \(currentFlow) - \(Date())")
        }
    }
    
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
     * Navigate to main app flow
     */
    func showMainFlow() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentFlow = .main
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * Determine the initial flow when app starts
     * SIMPLE APPROACH: Always start with loading screen first
     */
    private func determineInitialFlow() {
        DebugLogger.ui("🔍 AppCoordinator: Starting with loading screen... - \(Date())")
        
        // ALWAYS start with loading screen to show Korean animation
        currentFlow = .loading
        
        // After a short delay, determine and transition to appropriate flow
        Task {
            // Show loading screen for minimum 1 second for smooth UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Initialize data while still showing loading screen
            DebugLogger.data("🔍 Starting background data initialization... - \(Date())")
            await initializeAppData()
            DebugLogger.data("✅ Background data initialization complete - \(Date())")
            
            // Now determine the appropriate flow
            await MainActor.run {
                let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                
                if hasCompletedOnboarding {
                    DebugLogger.ui("✅ User has completed onboarding, showing main flow - \(Date())")
                    self.showMainFlow()
                } else {
                    DebugLogger.ui("🎯 User needs onboarding, showing onboarding flow")
                    self.showOnboarding()
                }
            }
        }
    }
    
    /**
     * Helper to run async operations with timeout
     */
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /**
     * Initialize app data if needed
     */
    @MainActor
    private func initializeAppData() async {
        DebugLogger.data("🔍 AppCoordinator: Initializing app data... - \(Date())")
        
        // Always ensure content is synchronized with JSON files
        do {
            let descriptor = FetchDescriptor<BeltLevel>()
            let existingBeltLevels = try DataManager.shared.modelContainer.mainContext.fetch(descriptor)
            
            if existingBeltLevels.isEmpty {
                DebugLogger.data("🗃️ Database is empty, loading all initial content from JSON...")
                
                // Load terminology and belt data
                let modularLoader = ModularContentLoader(dataService: DataManager.shared.terminologyService)
                modularLoader.loadCompleteSystem()
                DebugLogger.data("✅ Terminology and belt data loaded")
            } else {
                DebugLogger.data("✅ Database already has \(existingBeltLevels.count) belt levels, running content synchronization...")
            }
            
            // Always ensure content is synchronized
            await DataManager.shared.setupInitialData()
            DebugLogger.data("✅ Content synchronization complete")
            
            // Load shared profile state for ProfileSwitcher optimization
            DataServices.shared.loadSharedProfileState()
            DebugLogger.data("✅ Shared profile state loaded for ProfileSwitcher optimization")
        } catch {
            DebugLogger.data("❌ Failed to initialize app data: \(error)")
            // Continue anyway - app can still function with empty database
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

/**
 * Error thrown when operations exceed timeout
 */
struct TimeoutError: Error {
    let message: String
    
    init(_ message: String = "Operation timed out") {
        self.message = message
    }
}
