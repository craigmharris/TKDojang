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
    private(set) var progressCacheService: ProgressCacheService
    private(set) var profileExportService: ProfileExportService
    private(set) var leitnerService: LeitnerService
    private(set) var techniquesService: TechniquesDataService
    
    // Track database reset state to trigger UI refresh
    private(set) var databaseResetId = UUID()
    private(set) var isResettingDatabase = false
    
    var modelContext: ModelContext {
        return modelContainer.mainContext
    }
    
    private init() {
        print("🏗️ Initializing DataManager... - \(Date())")
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
                UserStepSparringProgress.self,
                GradingRecord.self
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
            self.progressCacheService = ProgressCacheService(modelContext: container.mainContext)
            self.profileService = ProfileService(modelContext: container.mainContext)
            self.stepSparringService = StepSparringDataService(modelContext: container.mainContext)
            self.profileExportService = ProfileExportService(modelContext: container.mainContext)
            self.leitnerService = LeitnerService(modelContext: container.mainContext)
            self.techniquesService = TechniquesDataService()
            
            // Connect ProfileService to ProgressCacheService for cache updates
            self.profileService.progressCacheService = self.progressCacheService
            
            // Connect ProfileService to ProfileExportService for automatic backups
            self.profileService.exportService = self.profileExportService
            
            // Note: Initial data setup will be handled by AppCoordinator
            print("✅ DataManager initialization complete - \(Date())")
            
        } catch {
            print("❌ Failed to create model container: \(error)")
            fatalError("Failed to create model container: \(error). Please use 'Reset Database & Reload Content' from User Settings.")
        }
    }
    
    /**
     * Sets up initial data and ensures content is synchronized with JSON files
     * 
     * PURPOSE: Ensures the app has up-to-date content from JSON files
     */
    func setupInitialData() async {
        print("DEBUG: 🔍 setupInitialData() called - \(Date())")
        // Check if we need to seed initial data
        let descriptor = FetchDescriptor<BeltLevel>()
        
        do {
            let existingBeltLevels = try modelContainer.mainContext.fetch(descriptor)
            
            if existingBeltLevels.isEmpty {
                print("🗃️ Database is empty, loading all content from JSON...")
                
                // Load belt levels and terminology
                let modularLoader = ModularContentLoader(dataService: terminologyService)
                modularLoader.loadCompleteSystem()
                
                // Load patterns from JSON
                print("🥋 Loading patterns from JSON...")
                let patternLoader = PatternContentLoader(patternService: patternService)
                patternLoader.loadAllContent()
                
                // Load step sparring from JSON  
                print("🥊 Loading step sparring from JSON...")
                let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
                stepSparringLoader.loadAllContent()
                
                print("✅ All JSON content loaded successfully")
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
                
            }
            
            // ALWAYS ensure patterns and step sparring are synchronized, regardless of belt level existence
            print("DEBUG: 🥋 Starting pattern synchronization...")
            await ensurePatternsAreSynchronized()
            
            print("DEBUG: 🥊 Starting step sparring synchronization...")
            await ensureStepSparringIsSynchronized()
            
            print("DEBUG: ✅ setupInitialData() completed successfully - \(Date())")
        } catch {
            print("DEBUG: ❌ setupInitialData() failed: \\(error) - \(Date())")
        }
    }
    
    /**
     * Ensures patterns are properly synchronized with JSON content
     */
    private func ensurePatternsAreSynchronized() async {
        let patternDescriptor = FetchDescriptor<Pattern>()
        
        do {
            let existingPatterns = try modelContainer.mainContext.fetch(patternDescriptor)
            
            // Dynamically scan JSON files to determine what patterns should exist
            let jsonPatternNames = getExpectedPatternNames()
            let expectedPatternCount = jsonPatternNames.count
            
            // Check if we need to reload patterns
            let existingNames = Set(existingPatterns.map { $0.name })
            let missingPatterns = jsonPatternNames.subtracting(existingNames)
            let extraPatterns = existingNames.subtracting(jsonPatternNames)
            
            if existingPatterns.count != expectedPatternCount || !missingPatterns.isEmpty || !extraPatterns.isEmpty {
                if !missingPatterns.isEmpty {
                    print("📚 Missing patterns: \(missingPatterns.sorted()) - reloading from JSON...")
                }
                if !extraPatterns.isEmpty {
                    print("📚 Extra patterns: \(extraPatterns.sorted()) - reloading from JSON...")
                }
                if existingPatterns.count != expectedPatternCount {
                    print("📚 Pattern count mismatch: \(existingPatterns.count) vs \(expectedPatternCount) expected - reloading...")
                }
                
                patternService.clearAndReloadPatterns()
            } else {
                print("✅ Complete pattern set synchronized (\(existingPatterns.count) patterns)")
                for pattern in existingPatterns.prefix(3) {
                    print("   \(pattern.name): \(pattern.moves.count) moves")
                }
            }
        } catch {
            print("❌ Failed to check pattern synchronization: \(error)")
        }
    }
    
    /**
     * Dynamically scans all pattern JSON files to get expected pattern names
     */
    private func getExpectedPatternNames() -> Set<String> {
        var expectedNames = Set<String>()
        
        // List of all pattern JSON files to scan
        let patternFiles = [
            "9th_keup_patterns", "8th_keup_patterns", "7th_keup_patterns", "6th_keup_patterns", 
            "5th_keup_patterns", "4th_keup_patterns", "3rd_keup_patterns", "2nd_keup_patterns", 
            "1st_keup_patterns", "1st_dan_patterns", "2nd_dan_patterns"
        ]
        
        for filename in patternFiles {
            // Try multiple bundle locations (same as PatternContentLoader)
            if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Patterns") ??
                         Bundle.main.url(forResource: filename, withExtension: "json") ??
                         Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Core/Data/Content/Patterns") {
                
                do {
                    let data = try Data(contentsOf: url)
                    let contentData = try JSONDecoder().decode(PatternContentData.self, from: data)
                    
                    // Add all pattern names from this file
                    for pattern in contentData.patterns {
                        expectedNames.insert(pattern.name)
                    }
                } catch {
                    print("⚠️ Failed to read pattern names from \(filename): \(error)")
                }
            } else {
                print("⚠️ Could not find \(filename).json in bundle")
            }
        }
        
        print("📋 Expected patterns from JSON: \(expectedNames.sorted())")
        return expectedNames
    }
    
    /**
     * Dynamically scans all step sparring JSON files to get expected sequence identifiers
     */
    private func getExpectedStepSparringSequences() -> Set<String> {
        var expectedSequences = Set<String>()
        
        // Scan bundle for step sparring JSON files (they're copied to bundle root, not subdirectory)
        guard let bundlePath = Bundle.main.resourcePath else {
            print("❌ Could not get bundle resource path for step sparring")
            return expectedSequences
        }
        
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
            let stepSparringFiles = contents.filter { 
                $0.hasSuffix(".json") && ($0.contains("step") || $0.contains("sparring"))
            }
            
            print("DEBUG: 📁 Found step sparring JSON files in bundle root: \(stepSparringFiles)")
            
            for jsonFile in stepSparringFiles {
                let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                
                // Try to load and parse each JSON file from bundle root
                if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
                    do {
                        let data = try Data(contentsOf: url)
                        let contentData = try JSONDecoder().decode(StepSparringContentData.self, from: data)
                        
                        // Add all sequence identifiers from this file
                        for sequence in contentData.sequences {
                            let sequenceId = "\(contentData.type)_\(sequence.sequenceNumber)"
                            expectedSequences.insert(sequenceId)
                        }
                    } catch {
                        print("⚠️ Failed to read step sparring sequences from \(filename): \(error)")
                    }
                }
            }
        } catch {
            print("❌ Failed to scan StepSparring directory: \(error)")
        }
        
        print("DEBUG: 📋 Expected step sparring sequences from JSON: \(expectedSequences.sorted())")
        return expectedSequences
    }
    
    /**
     * Ensures step sparring sequences are properly synchronized with JSON content
     */
    private func ensureStepSparringIsSynchronized() async {
        let stepSparringDescriptor = FetchDescriptor<StepSparringSequence>()
        
        do {
            let existingSequences = try modelContainer.mainContext.fetch(stepSparringDescriptor)
            
            // Dynamically scan JSON files to determine what sequences should exist
            let jsonSequenceIds = getExpectedStepSparringSequences()
            let expectedSequenceCount = jsonSequenceIds.count
            
            // Check if we need to reload sequences
            let existingIds = Set(existingSequences.map { "\($0.type.rawValue)_\($0.sequenceNumber)" })
            let missingSequences = jsonSequenceIds.subtracting(existingIds)
            let extraSequences = existingIds.subtracting(jsonSequenceIds)
            
            // Also check if existing sequences have proper JSON belt level data
            let sequencesWithBeltData = existingSequences.filter { !$0.applicableBeltLevelIds.isEmpty }
            let missingBeltData = sequencesWithBeltData.count != existingSequences.count
            
            print("DEBUG: 🔍 Step sparring sync check - existing: \(existingSequences.count), expected: \(expectedSequenceCount), missing belt data: \(missingBeltData)")
            print("DEBUG: 🔍 Missing sequences: \(missingSequences), Extra sequences: \(extraSequences)")
            
            if existingSequences.count != expectedSequenceCount || !missingSequences.isEmpty || !extraSequences.isEmpty || missingBeltData {
                if !missingSequences.isEmpty {
                    print("DEBUG: 🥊 Missing step sparring sequences: \(missingSequences.sorted()) - reloading from JSON...")
                }
                if !extraSequences.isEmpty {
                    print("DEBUG: 🥊 Extra step sparring sequences: \(extraSequences.sorted()) - reloading from JSON...")
                }
                if existingSequences.count != expectedSequenceCount {
                    print("DEBUG: 🥊 Step sparring count mismatch: \(existingSequences.count) vs \(expectedSequenceCount) expected - reloading...")
                }
                if missingBeltData {
                    print("DEBUG: 🥊 Step sparring sequences missing JSON belt level data - reloading...")
                }
                
                print("DEBUG: 🔄 Triggering step sparring reload...")
                stepSparringService.clearAndReloadStepSparring()
                print("DEBUG: ✅ Step sparring reload completed")
            } else {
                print("DEBUG: ✅ Complete step sparring set synchronized (\(existingSequences.count) sequences)")
                for sequence in existingSequences.prefix(3) {
                    print("DEBUG:    \(sequence.name): \(sequence.steps.count) steps, JSON belts: \(sequence.applicableBeltLevelIds)")
                }
            }
        } catch {
            print("❌ Failed to check step sparring synchronization: \(error)")
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
     * Resets entire database and exits the app for clean restart
     * Use this to force reload when content structure changes
     * 
     * CRITICAL: This deletes the database file and exits the app for maximum safety
     */
    func resetAndReloadDatabase() async {
        do {
            // Set resetting flag to prevent any profile access
            isResettingDatabase = true
            
            print("🔄 Starting database reset - will exit app for clean restart...")
            
            // CRITICAL: Clear ProfileService active profile reference
            profileService.clearActiveProfileForReset()
            
            // Delete the database files completely
            let appSupportDir = URL.applicationSupportDirectory
            let dbURL = appSupportDir.appending(path: "Model.sqlite")
            let dbSHMURL = appSupportDir.appending(path: "Model.sqlite-shm")
            let dbWALURL = appSupportDir.appending(path: "Model.sqlite-wal")
            
            try? FileManager.default.removeItem(at: dbURL)
            try? FileManager.default.removeItem(at: dbSHMURL)
            try? FileManager.default.removeItem(at: dbWALURL)
            
            print("🗑️ Database files deleted - app will exit for clean restart")
            
            // Show final message to user
            await MainActor.run {
                // Show alert then exit
                let alert = UIAlertController(
                    title: "Database Reset Complete", 
                    message: "The app will now restart with a fresh database. Please reopen the app.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    exit(0) // Clean app exit
                })
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(alert, animated: true)
                } else {
                    // Fallback: exit immediately if we can't show alert
                    exit(0)
                }
            }
        } catch {
            print("❌ Failed to reset database: \\(error)")
            // Clear resetting flag on error
            isResettingDatabase = false
            
            // On error, still show message and exit to prevent crashes
            await MainActor.run {
                let alert = UIAlertController(
                    title: "Reset Error", 
                    message: "Database reset failed. App will exit to prevent crashes. Please restart manually.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    exit(1) // Exit with error code
                })
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    rootVC.present(alert, animated: true)
                } else {
                    exit(1)
                }
            }
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

// MARK: - SwiftUI Environment Integration - DEPRECATED
// This section is no longer used - we use DataServices instead to avoid static initialization

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

// MARK: - View Modifier for Data Context - DEPRECATED
// This section is no longer used - we use DataServicesModifier instead to avoid static initialization
