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
    private var hasLoadedProfiles = false
    
    static var shared: DataServices {
        if let instance = _shared {
            return instance
        }
        print("🔑 DataServices.shared: Creating singleton instance for first time - \(Date())")
        let instance = DataServices()
        _shared = instance
        return instance
    }
    
    private var _dataManager: DataManager?
    
    private init() { 
        print("🔑 DataServices.init(): Private initializer called - \(Date())")
    }
    
    private var dataManager: DataManager {
        if let dm = _dataManager {
            return dm
        }
        
        // This is the only place DataManager.shared is accessed
        print("🔑 DataServices: First access to DataManager - about to initialize DataManager.shared - \(Date())")
        let dm = DataManager.shared
        _dataManager = dm
        print("🔑 DataServices: DataManager.shared obtained successfully - \(Date())")
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
    
    func resetAndReloadDatabase() async {
        await dataManager.resetAndReloadDatabase()
    }
    
    var isResettingDatabase: Bool {
        dataManager.isResettingDatabase
    }
    
    var databaseResetId: UUID {
        dataManager.databaseResetId
    }
    
    // MARK: - Shared Profile State Management
    
    /**
     * Loads profile data into shared published properties (called once, not per ProfileSwitcher instance)
     */
    func loadSharedProfileState() {
        guard !hasLoadedProfiles else { 
            print("🔄 DataServices: Profile state already loaded, skipping duplicate load")
            return 
        }
        
        print("🔄 DataServices: Loading shared profile state (first time)")
        
        do {
            allProfiles = try profileService.getAllProfiles()
            activeProfile = profileService.getActiveProfile()
            hasLoadedProfiles = true
            
            print("✅ DataServices: Loaded shared profile state - \(allProfiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        } catch {
            print("❌ DataServices: Failed to load shared profile state: \(error)")
            allProfiles = []
            activeProfile = nil
        }
    }
    
    /**
     * Updates shared profile state after profile operations
     */
    func refreshSharedProfileState() {
        print("🔄 DataServices: Refreshing shared profile state")
        
        do {
            allProfiles = try profileService.getAllProfiles()
            activeProfile = profileService.getActiveProfile()
            
            print("✅ DataServices: Refreshed shared profile state - \(allProfiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        } catch {
            print("❌ DataServices: Failed to refresh shared profile state: \(error)")
        }
    }
    
    /**
     * Switches to profile and updates shared state
     */
    func switchToProfile(_ profile: UserProfile) throws {
        print("🔄 DataServices: Switching to profile: \(profile.name)")
        try profileService.activateProfile(profile)
        refreshSharedProfileState()
        print("✅ DataServices: Profile switch completed")
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