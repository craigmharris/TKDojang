import SwiftUI
import SwiftData

/**
 * DataServices.swift
 * 
 * PURPOSE: Service locator for data access without static initialization
 * 
 * This provides access to DataManager services without triggering
 * DataManager.shared during static initialization, allowing the UI
 * to appear before heavy data loading begins.
 */

/**
 * Service locator that provides access to data services
 * Only initializes when explicitly requested
 */
@MainActor
class DataServices: ObservableObject {
    private static var _shared: DataServices?
    
    // MARK: - Published Profile State (for ProfileSwitcher optimization)

    @Published var allProfiles: [UserProfile] = []
    @Published var activeProfile: UserProfile?
    @Published var databaseResetId: UUID = UUID()
    @Published var isResetting: Bool = false  // Local flag to avoid accessing DataManager during reset
    private var hasLoadedProfiles = false
    
    static var shared: DataServices {
        if let instance = _shared {
            return instance
        }
        DebugLogger.data("🔑 DataServices.shared: Creating singleton instance for first time - \(Date())")
        let instance = DataServices()
        _shared = instance
        return instance
    }
    
    private var _dataManager: DataManager?
    
    private init() { 
        DebugLogger.data("🔑 DataServices.init(): Private initializer called - \(Date())")
    }
    
    private var dataManager: DataManager {
        if let dm = _dataManager {
            return dm
        }
        
        // This is the only place DataManager.shared is accessed
        DebugLogger.data("🔑 DataServices: First access to DataManager - about to initialize DataManager.shared - \(Date())")
        let dm = DataManager.shared
        _dataManager = dm
        DebugLogger.data("🔑 DataServices: DataManager.shared obtained successfully - \(Date())")
        return dm
    }
    
    // MARK: - Service Access
    
    var modelContainer: ModelContainer {
        return dataManager.modelContainer
    }
    
    var modelContext: ModelContext {
        return dataManager.modelContext
    }
    
    var terminologyService: TerminologyDataService {
        return dataManager.terminologyService
    }
    
    var patternService: PatternDataService {
        return dataManager.patternService
    }
    
    var profileService: ProfileService {
        return dataManager.profileService
    }
    
    var stepSparringService: StepSparringDataService {
        return dataManager.stepSparringService
    }
    
    var progressCacheService: ProgressCacheService {
        return dataManager.progressCacheService
    }
    
    var profileExportService: ProfileExportService {
        return dataManager.profileExportService
    }
    
    var leitnerService: LeitnerService {
        return dataManager.leitnerService
    }
    
    var techniquesService: TechniquesDataService {
        return dataManager.techniquesService
    }
    
    // MARK: - DataManager Methods
    
    func getOrCreateDefaultUserProfile() -> UserProfile {
        dataManager.getOrCreateDefaultUserProfile()
    }
    
    func resetUserProgress() {
        dataManager.resetUserProgress()
    }
    
    func resetAndReloadDatabase() async throws {
        DebugLogger.data("🚨🚨🚨 NEW CODE: DataServices.resetAndReloadDatabase() ENTRY POINT 🚨🚨🚨")

        // CRITICAL: Set local flag FIRST to prevent UI from accessing DataManager
        isResetting = true

        // CRITICAL: Clear profile state BEFORE reset to prevent UI crashes
        // This must happen FIRST, before DataManager nils out services
        allProfiles = []
        activeProfile = nil
        hasLoadedProfiles = false

        DebugLogger.data("✅ NEW CODE: Cleared profile state and set isResetting flag")

        // Now trigger the actual reset
        try await dataManager.resetAndReloadDatabase()

        // Update databaseResetId to force UI recreation
        databaseResetId = UUID()
        isResetting = false
    }

    var isResettingDatabase: Bool {
        // Use local flag instead of accessing DataManager to avoid crashes
        isResetting
    }
    
    // MARK: - Shared Profile State Management
    
    /**
     * Loads profile data into shared published properties (called once, not per ProfileSwitcher instance)
     */
    func loadSharedProfileState() {
        guard !hasLoadedProfiles else { 
            DebugLogger.data("🔄 DataServices: Profile state already loaded, skipping duplicate load")
            return 
        }
        
        DebugLogger.data("🔄 DataServices: Loading shared profile state (first time)")
        
        do {
            allProfiles = try profileService.getAllProfiles()
            activeProfile = profileService.getActiveProfile()
            hasLoadedProfiles = true
            
            DebugLogger.data("✅ DataServices: Loaded shared profile state - \(allProfiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        } catch {
            DebugLogger.data("❌ DataServices: Failed to load shared profile state: \(error)")
            allProfiles = []
            activeProfile = nil
        }
    }
    
    /**
     * Updates shared profile state after profile operations
     */
    func refreshSharedProfileState() {
        DebugLogger.data("🔄 DataServices: Refreshing shared profile state")
        
        do {
            allProfiles = try profileService.getAllProfiles()
            activeProfile = profileService.getActiveProfile()
            
            DebugLogger.data("✅ DataServices: Refreshed shared profile state - \(allProfiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        } catch {
            DebugLogger.data("❌ DataServices: Failed to refresh shared profile state: \(error)")
        }
    }
    
    /**
     * Switches to profile and updates shared state
     */
    func switchToProfile(_ profile: UserProfile) throws {
        DebugLogger.data("🔄 DataServices: Switching to profile: \(profile.name)")
        try profileService.activateProfile(profile)
        refreshSharedProfileState()
        DebugLogger.data("✅ DataServices: Profile switch completed")
    }
}

// MARK: - View Modifier

struct DataServicesModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environmentObject(DataServices.shared)
            // Note: modelContainer is accessed through dataServices when views need it
            // This avoids triggering DataManager initialization during view setup
    }
}

extension View {
    func withDataServices() -> some View {
        modifier(DataServicesModifier())
    }
}