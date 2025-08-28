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
    private var _dataManager: DataManager?
    
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
}

// MARK: - View Modifier

struct DataServicesModifier: ViewModifier {
    // Lazy initialization - DataServices is only created when body is evaluated
    @MainActor private var dataServices: DataServices {
        DataServices()
    }
    
    func body(content: Content) -> some View {
        content
            .environmentObject(dataServices)
            // Note: modelContainer is accessed through dataServices when views need it
            // This avoids triggering DataManager initialization during view setup
    }
}

extension View {
    func withDataServices() -> some View {
        modifier(DataServicesModifier())
    }
}