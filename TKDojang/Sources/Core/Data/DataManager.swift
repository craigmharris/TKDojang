import Foundation
import SwiftData
import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let databaseResetStarting = Notification.Name("databaseResetStarting")
    static let forceAppReset = Notification.Name("forceAppReset")
}

/**
 * DataManager.swift
 * 
 * PURPOSE: Central data management for TKDojang app
 * 
 * RESPONSIBILITIES:
 * - SwiftData model container configuration
 * - Database initialization and migration
 * - Dependency injection for data services
 */

@Observable
@MainActor
class DataManager {
    static let shared = DataManager()
    
    private(set) var modelContainer: ModelContainer
    private(set) var terminologyService: TerminologyDataService
    private(set) var patternService: PatternDataService
    private(set) var profileService: ProfileService
    private(set) var stepSparringService: StepSparringDataService
    
    // Track database reset state to trigger UI refresh
    private(set) var databaseResetId = UUID()
    private(set) var isResettingDatabase = false
    
    var modelContext: ModelContext {
        return modelContainer.mainContext
    }
    
    private init() {
        print("🏗️ Initializing DataManager...")
        do {
            // Configure the SwiftData model container
            let schema = Schema([
                BeltLevel.self,
                TerminologyCategory.self,
                TerminologyEntry.self,
                UserProfile.self,
                UserTerminologyProgress.self,
                TestSession.self,
                TestConfiguration.self,
                TestQuestion.self,
                TestResult.self,
                CategoryPerformance.self,
                BeltLevelPerformance.self,
                TestPerformance.self,
                Pattern.self,
                PatternMove.self,
                UserPatternProgress.self,
                StudySession.self,
                StepSparringSequence.self,
                StepSparringStep.self,
                StepSparringAction.self,
                UserStepSparringProgress.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false, // Set to true for testing
                cloudKitDatabase: .none     // Set to .automatic for CloudKit sync in future
            )
            
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Initialize all properties
            self.modelContainer = container
            self.terminologyService = TerminologyDataService(modelContext: container.mainContext)
            self.patternService = PatternDataService(modelContext: container.mainContext)
            self.profileService = ProfileService(modelContext: container.mainContext)
            self.stepSparringService = StepSparringDataService(modelContext: container.mainContext)
            
            // Perform initial setup if needed
            print("🔍 DEBUG: DataManager init - about to call setupInitialData()")
            Task {
                await setupInitialData()
            }
            
        } catch {
            print("❌ Failed to create model container: \(error)")
            fatalError("Failed to create model container: \(error). Please use 'Reset Database & Reload Content' from User Settings.")
        }
    }
    
    /**
     * Sets up initial data if the database is empty
     * 
     * PURPOSE: Ensures the app has content to work with on first launch
     */
    private func setupInitialData() async {
        print("🔍 DEBUG: setupInitialData() called")
        // Check if we need to seed initial data
        let descriptor = FetchDescriptor<BeltLevel>()
        
        do {
            let existingBeltLevels = try modelContainer.mainContext.fetch(descriptor)
            
            if existingBeltLevels.isEmpty {
                print("🗃️ Database is empty, loading modular TAGB content...")
                let modularLoader = ModularContentLoader(dataService: terminologyService)
                modularLoader.loadCompleteSystem()
                
                // Load initial patterns after belt levels are created
                let allBelts = try modelContainer.mainContext.fetch(FetchDescriptor<BeltLevel>())
                patternService.seedInitialPatterns(beltLevels: allBelts)
                
                // Load initial step sparring sequences
                print("🥊 Loading initial step sparring sequences...")
                stepSparringService.seedInitialSequences()
                
                // Verify sequences were created
                let stepSparringDescriptor = FetchDescriptor<StepSparringSequence>()
                let newSequences = try modelContainer.mainContext.fetch(stepSparringDescriptor)
                print("✅ Loaded \(newSequences.count) step sparring sequences on initial setup")
            } else {
                print("✅ Database already contains \(existingBeltLevels.count) belt levels")
                // Debug: Check if belt levels have colors
                for belt in existingBeltLevels.prefix(3) {
                    print("🎨 Belt: \(belt.shortName), Primary Color: \(belt.primaryColor ?? "nil"), Secondary: \(belt.secondaryColor ?? "nil")")
                }
                
                // Check if we have any terminology entries at all
                let termDescriptor = FetchDescriptor<TerminologyEntry>()
                let existingTerms = try modelContainer.mainContext.fetch(termDescriptor)
                print("📊 Database contains \(existingTerms.count) terminology entries")
                
                if existingTerms.isEmpty {
                    print("🔄 No terms found - forcing content reload...")
                    let modularLoader = ModularContentLoader(dataService: terminologyService)
                    modularLoader.loadCompleteSystem()
                }
                
                // Check if patterns exist, load if needed
                let patternDescriptor = FetchDescriptor<Pattern>()
                let existingPatterns = try modelContainer.mainContext.fetch(patternDescriptor)
                if existingPatterns.isEmpty {
                    print("🥋 No patterns found - loading initial patterns...")
                    patternService.seedInitialPatterns(beltLevels: existingBeltLevels)
                } else {
                    print("✅ Database contains \(existingPatterns.count) patterns")
                }
                
                print("🔍 DEBUG: About to check step sparring sequences...")
                
                // Check if step sparring sequences exist, load if needed
                let stepSparringDescriptor = FetchDescriptor<StepSparringSequence>()
                let existingSequences = try modelContainer.mainContext.fetch(stepSparringDescriptor)
                
                print("🔍 DEBUG: DataManager found \(existingSequences.count) existing step sparring sequences in database")
                
                // TEMPORARY: Force reload to debug belt matching issue
                if !existingSequences.isEmpty {
                    print("🔄 TEMP DEBUG: Deleting existing sequences to force fresh load with debug logging")
                    for sequence in existingSequences {
                        modelContainer.mainContext.delete(sequence)
                    }
                    try modelContainer.mainContext.save()
                }
                
                if existingSequences.isEmpty || true { // Force reload
                    print("🥊 DEBUG: No step sparring sequences found - calling stepSparringService.seedInitialSequences()...")
                    stepSparringService.seedInitialSequences()
                    
                    // Verify sequences were created
                    let newSequences = try modelContainer.mainContext.fetch(stepSparringDescriptor)
                    print("✅ DEBUG: DataManager reports \(newSequences.count) step sparring sequences after seeding")
                } else {
                    print("✅ DEBUG: DataManager reports database contains \(existingSequences.count) step sparring sequences")
                    
                    // Debug: Check belt level associations of existing sequences
                    for sequence in existingSequences {
                        let beltNames = sequence.beltLevels.map { $0.shortName }
                        print("🔍 DEBUG: Sequence '\(sequence.name)' (#\(sequence.sequenceNumber)) has \(sequence.beltLevels.count) belts: \(beltNames)")
                    }
                }
            }
        } catch {
            print("❌ Failed to check existing data: \\(error)")
        }
    }
    
    /**
     * Creates or retrieves the active user profile
     * 
     * PURPOSE: Ensures there's always an active profile for the app to work with
     * Uses the new multi-profile system with ProfileService
     */
    func getOrCreateDefaultUserProfile() -> UserProfile {
        // Try to get active profile first
        if let activeProfile = profileService.getActiveProfile() {
            return activeProfile
        }
        
        // No active profile, try to get any existing profile
        do {
            let existingProfiles = try profileService.getAllProfiles()
            if let firstProfile = existingProfiles.first {
                try profileService.activateProfile(firstProfile)
                return firstProfile
            }
            
            // No profiles exist, create default profile
            let beltDescriptor = FetchDescriptor<BeltLevel>()
            let allBelts = try modelContainer.mainContext.fetch(beltDescriptor)
            let whiteBelt = allBelts.first { $0.shortName.contains("10th Keup") } ?? allBelts.first!
            
            let defaultProfile = try profileService.createProfile(
                name: "Student",
                avatar: .student1,
                colorTheme: .blue,
                beltLevel: whiteBelt
            )
            
            return defaultProfile
        } catch {
            fatalError("Failed to create user profile: \\(error)")
        }
    }
    
    /**
     * Resets all user progress (for testing or user request)
     */
    func resetUserProgress() {
        do {
            let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
            let allProgress = try modelContainer.mainContext.fetch(progressDescriptor)
            
            allProgress.forEach { progress in
                modelContainer.mainContext.delete(progress)
            }
            
            try modelContainer.mainContext.save()
            print("✅ User progress reset successfully")
        } catch {
            print("❌ Failed to reset user progress: \\(error)")
        }
    }
    
    /**
     * Resets entire database and reloads with new modular content
     * Use this to force reload when content structure changes
     * 
     * CRITICAL: This recreates the entire ModelContainer to prevent SwiftData crashes
     */
    func resetAndReloadDatabase() async {
        do {
            // Set resetting flag to prevent any profile access
            isResettingDatabase = true
            
            print("🔄 Starting database reset - recreating ModelContainer...")
            
            // CRITICAL: Clear ProfileService active profile reference to prevent SwiftData crashes
            profileService.clearActiveProfileForReset()
            
            // Step 1: Clear current container data
            let currentContext = modelContainer.mainContext
            currentContext.rollback()
            
            // Step 2: Delete the database file and recreate container
            let url = URL.applicationSupportDirectory.appending(path: "Model.sqlite")
            try? FileManager.default.removeItem(at: url)
            
            // Step 3: Recreate ModelContainer (this invalidates all existing SwiftData references)
            let schema = Schema([
                BeltLevel.self,
                TerminologyCategory.self,
                TerminologyEntry.self,
                UserProfile.self,
                UserTerminologyProgress.self,
                Pattern.self,
                PatternMove.self,
                UserPatternProgress.self,
                StepSparringSequence.self,
                StepSparringStep.self,
                StepSparringAction.self,
                UserStepSparringProgress.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            let newContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Step 4: Update all services with new container
            self.modelContainer = newContainer
            self.terminologyService = TerminologyDataService(modelContext: newContainer.mainContext)
            self.patternService = PatternDataService(modelContext: newContainer.mainContext)
            self.profileService = ProfileService(modelContext: newContainer.mainContext)
            
            // Step 5: Trigger complete UI refresh by changing the reset ID
            self.databaseResetId = UUID()
            
            // Clear resetting flag
            isResettingDatabase = false
            
            print("🗑️ Database container recreated successfully - UI refresh triggered")
            
            // Small delay to ensure database operations complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    // Reload with new modular system
                    let modularLoader = ModularContentLoader(dataService: self.terminologyService)
                    modularLoader.loadCompleteSystem()
                    
                    // Reload patterns after belt levels are created
                    let allBelts = try self.modelContainer.mainContext.fetch(FetchDescriptor<BeltLevel>())
                    await MainActor.run {
                        self.patternService.seedInitialPatterns(beltLevels: allBelts)
                    }
                }
            }
            
        } catch {
            print("❌ Failed to reset database: \\(error)")
            // Clear resetting flag on error
            isResettingDatabase = false
            // If reset fails, try creating a new context
            modelContainer.mainContext.rollback()
        }
    }
    
    /**
     * Exports user data for backup or transfer
     */
    func exportUserData() -> UserDataExport? {
        // Implementation for exporting user progress
        // Useful for backup, device transfer, or debugging
        return nil
    }
    
    /**
     * Imports user data from backup
     */
    func importUserData(_ exportData: UserDataExport) -> Bool {
        // Implementation for importing user progress
        return false
    }
    
}

// MARK: - SwiftUI Environment Integration

/**
 * SwiftUI Environment key for DataManager
 */
struct DataManagerKey: EnvironmentKey {
    nonisolated static let defaultValue = DataManager.shared
}

extension EnvironmentValues {
    var dataManager: DataManager {
        get { self[DataManagerKey.self] }
        set { self[DataManagerKey.self] = newValue }
    }
}

// MARK: - Supporting Types

/**
 * Structure for exporting/importing user data
 */
struct UserDataExport: Codable {
    let exportDate: Date
    let userProfile: UserProfileExport
    let progress: [UserProgressExport]
}

struct UserProfileExport: Codable {
    let currentBeltLevel: String
    let learningMode: String
    let preferredCategories: [String]
    let dailyStudyGoal: Int
}

struct UserProgressExport: Codable {
    let terminologyId: UUID
    let currentBox: Int
    let correctCount: Int
    let incorrectCount: Int
    let consecutiveCorrect: Int
    let masteryLevel: String
    let lastReviewedAt: Date?
    let nextReviewDate: Date
}

// MARK: - View Modifier for Data Context

/**
 * View modifier to inject data context into SwiftUI views
 */
struct DataContextModifier: ViewModifier {
    @MainActor let dataManager = DataManager.shared
    
    func body(content: Content) -> some View {
        content
            .modelContainer(dataManager.modelContainer)
            .environment(dataManager)
    }
}

extension View {
    /**
     * Convenience method to add data context to any view
     */
    func withDataContext() -> some View {
        modifier(DataContextModifier())
    }
}
