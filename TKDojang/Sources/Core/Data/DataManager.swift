import Foundation
import SwiftData
import SwiftUI

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
                UserPatternProgress.self
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
            
            // Perform initial setup if needed
            Task {
                await setupInitialData()
            }
            
        } catch {
            fatalError("Failed to create model container: \\(error)")
        }
    }
    
    /**
     * Sets up initial data if the database is empty
     * 
     * PURPOSE: Ensures the app has content to work with on first launch
     */
    private func setupInitialData() async {
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
            }
        } catch {
            print("❌ Failed to check existing data: \\(error)")
        }
    }
    
    /**
     * Creates or retrieves the default user profile
     * 
     * PURPOSE: Ensures there's always a user profile for the app to work with
     * In a multi-user app, this would be more sophisticated
     */
    func getOrCreateDefaultUserProfile() -> UserProfile {
        let descriptor = FetchDescriptor<UserProfile>()
        
        do {
            let existingProfiles = try modelContainer.mainContext.fetch(descriptor)
            
            if let existing = existingProfiles.first {
                return existing
            } else {
                // Create default profile with White Belt
                let beltDescriptor = FetchDescriptor<BeltLevel>()
                let allBelts = try modelContainer.mainContext.fetch(beltDescriptor)
                let whiteBelt = allBelts.first { $0.shortName.contains("10th Keup") } ?? allBelts.first!
                let profile = UserProfile(currentBeltLevel: whiteBelt, learningMode: .mastery)
                
                modelContainer.mainContext.insert(profile)
                try modelContainer.mainContext.save()
                
                return profile
            }
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
     */
    func resetAndReloadDatabase() {
        do {
            // Clear any pending changes first
            modelContainer.mainContext.rollback()
            
            // Delete all existing data in reverse dependency order
            let progressDescriptor = FetchDescriptor<UserTerminologyProgress>()
            let entryDescriptor = FetchDescriptor<TerminologyEntry>()
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let categoryDescriptor = FetchDescriptor<TerminologyCategory>()
            let beltDescriptor = FetchDescriptor<BeltLevel>()
            
            // Delete in order to avoid relationship conflicts
            let progress = try modelContainer.mainContext.fetch(progressDescriptor)
            progress.forEach { modelContainer.mainContext.delete($0) }
            
            let entries = try modelContainer.mainContext.fetch(entryDescriptor)
            entries.forEach { modelContainer.mainContext.delete($0) }
            
            let profiles = try modelContainer.mainContext.fetch(profileDescriptor)
            profiles.forEach { modelContainer.mainContext.delete($0) }
            
            let categories = try modelContainer.mainContext.fetch(categoryDescriptor)
            categories.forEach { modelContainer.mainContext.delete($0) }
            
            let belts = try modelContainer.mainContext.fetch(beltDescriptor)
            belts.forEach { modelContainer.mainContext.delete($0) }
            
            try modelContainer.mainContext.save()
            print("🗑️ Database cleared successfully")
            
            // Small delay to ensure database operations complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    // Reload with new modular system
                    let modularLoader = ModularContentLoader(dataService: self.terminologyService)
                    modularLoader.loadCompleteSystem()
                }
            }
            
        } catch {
            print("❌ Failed to reset database: \\(error)")
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
    @MainActor static let defaultValue = DataManager.shared
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