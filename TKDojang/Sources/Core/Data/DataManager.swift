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
        DebugLogger.data("🏗️ Initializing DataManager... - \(Date())")
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
                PatternTestResult.self,
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
            DebugLogger.data("✅ DataManager initialization complete - \(Date())")
            
        } catch {
            DebugLogger.data("❌ Failed to create model container: \(error)")
            fatalError("Failed to create model container: \(error). Please use 'Reset Database & Reload Content' from User Settings.")
        }
    }
    
    /**
     * Sets up initial data and ensures content is synchronized with JSON files
     * 
     * PURPOSE: Ensures the app has up-to-date content from JSON files
     */
    func setupInitialData() async {
        DebugLogger.data("🔍 setupInitialData() called - \(Date())")
        // Check if we need to seed initial data
        let descriptor = FetchDescriptor<BeltLevel>()
        
        do {
            let existingBeltLevels = try modelContainer.mainContext.fetch(descriptor)
            
            if existingBeltLevels.isEmpty {
                DebugLogger.data("🗃️ Database is empty, loading all content from JSON...")
                
                // Load belt levels and terminology
                let modularLoader = ModularContentLoader(dataService: terminologyService)
                modularLoader.loadCompleteSystem()
                
                // Load patterns from JSON
                DebugLogger.data("🥋 Loading patterns from JSON...")
                let patternLoader = PatternContentLoader(patternService: patternService)
                patternLoader.loadAllContent()
                
                // Load step sparring from JSON  
                DebugLogger.data("🥊 Loading step sparring from JSON...")
                let stepSparringLoader = StepSparringContentLoader(stepSparringService: stepSparringService)
                stepSparringLoader.loadAllContent()
                
                DebugLogger.data("✅ All JSON content loaded successfully")
            } else {
                DebugLogger.data("✅ Database already contains \(existingBeltLevels.count) belt levels")
                // Debug: Check if belt levels have colors
                for belt in existingBeltLevels.prefix(3) {
                    DebugLogger.data("🎨 Belt: \(belt.shortName), Primary Color: \(belt.primaryColor ?? "nil"), Secondary: \(belt.secondaryColor ?? "nil")")
                }
                
                // Check if we have any terminology entries at all
                let termDescriptor = FetchDescriptor<TerminologyEntry>()
                let existingTerms = try modelContainer.mainContext.fetch(termDescriptor)
                DebugLogger.data("📊 Database contains \(existingTerms.count) terminology entries")
                
                if existingTerms.isEmpty {
                    DebugLogger.data("🔄 No terms found - forcing content reload...")
                    let modularLoader = ModularContentLoader(dataService: terminologyService)
                    modularLoader.loadCompleteSystem()
                }
                
            }
            
            // ALWAYS ensure patterns and step sparring are synchronized, regardless of belt level existence
            DebugLogger.data("🥋 Starting pattern synchronization...")
            await ensurePatternsAreSynchronized()
            
            DebugLogger.data("🥊 Starting step sparring synchronization...")
            await ensureStepSparringIsSynchronized()
            
            DebugLogger.data("✅ setupInitialData() completed successfully - \(Date())")
        } catch {
            DebugLogger.data("❌ setupInitialData() failed: \\(error) - \(Date())")
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
                    DebugLogger.data("📚 Missing patterns: \(missingPatterns.sorted()) - reloading from JSON...")
                }
                if !extraPatterns.isEmpty {
                    DebugLogger.data("📚 Extra patterns: \(extraPatterns.sorted()) - reloading from JSON...")
                }
                if existingPatterns.count != expectedPatternCount {
                    DebugLogger.data("📚 Pattern count mismatch: \(existingPatterns.count) vs \(expectedPatternCount) expected - reloading...")
                }
                
                patternService.clearAndReloadPatterns()
            } else {
                DebugLogger.data("✅ Complete pattern set synchronized (\(existingPatterns.count) patterns)")
                for pattern in existingPatterns.prefix(3) {
                    DebugLogger.data("   \(pattern.name): \(pattern.moves.count) moves")
                }
            }
        } catch {
            DebugLogger.data("❌ Failed to check pattern synchronization: \(error)")
        }
    }
    
    /**
     * Dynamically discovers pattern names from pattern JSON files
     */
    private func getExpectedPatternNames() -> Set<String> {
        var expectedNames = Set<String>()
        
        // Dynamic discovery of pattern files (consistent with PatternContentLoader)
        let patternFiles = discoverPatternFiles()
        
        DebugLogger.data("📁 Dynamically discovered \(patternFiles.count) pattern JSON files: \(patternFiles)")
        
        for filename in patternFiles {
            // Try subdirectory first, then fallback to bundle root
            var url: URL?
            url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Patterns")
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "json")
            }
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Core/Data/Content/Patterns")
            }
            
            if let url = url {
                do {
                    let data = try Data(contentsOf: url)
                    let contentData = try JSONDecoder().decode(PatternContentData.self, from: data)
                    
                    // Add all pattern names from this file
                    for pattern in contentData.patterns {
                        expectedNames.insert(pattern.name)
                    }
                } catch {
                    DebugLogger.data("⚠️ Failed to read pattern names from \(filename): \(error)")
                }
            } else {
                DebugLogger.data("⚠️ Could not find \(filename).json in bundle")
            }
        }
        
        DebugLogger.data("📋 Expected patterns from JSON: \(expectedNames.sorted())")
        return expectedNames
    }
    
    /**
     * Dynamically discovers pattern files from Patterns subdirectory
     */
    private func discoverPatternFiles() -> [String] {
        var foundFiles: [String] = []
        
        // First try: Scan Patterns subdirectory for any JSON files ending with "_patterns"
        if let patternsPath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "Patterns") {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: patternsPath)
                let patternFiles = contents.filter { filename in
                    filename.hasSuffix(".json") && filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan Patterns subdirectory: \(error)")
            }
        }
        
        // Fallback: Try bundle root for files containing pattern patterns
        if foundFiles.isEmpty, let bundlePath = Bundle.main.resourcePath {
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let patternFiles = contents.filter { filename in
                    guard filename.hasSuffix(".json") else { return false }
                    // Look for files that match pattern naming conventions
                    return filename.contains("_patterns")
                }
                
                for jsonFile in patternFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan bundle root: \(error)")
            }
        }
        
        return foundFiles.sorted()
    }
    
    /**
     * Dynamically discovers step sparring sequence identifiers from StepSparring subdirectory
     */
    private func getExpectedStepSparringSequences() -> Set<String> {
        var expectedSequences = Set<String>()
        
        // Dynamic discovery of step sparring files (consistent with StepSparringContentLoader)
        let stepSparringFiles = discoverStepSparringFiles()
        
        DebugLogger.data("📁 Dynamically discovered \(stepSparringFiles.count) step sparring JSON files: \(stepSparringFiles)")
        
        for filename in stepSparringFiles {
            // Try subdirectory first, then fallback to bundle root
            var url: URL?
            url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "StepSparring")
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "json")
            }
            
            if let url = url {
                do {
                    let data = try Data(contentsOf: url)
                    let contentData = try JSONDecoder().decode(StepSparringContentData.self, from: data)
                    
                    DebugLogger.data("✅ Found step sparring file: \(filename).json with \(contentData.sequences.count) sequences")
                    
                    // Add all sequence identifiers from this file
                    for sequence in contentData.sequences {
                        let sequenceId = "\(contentData.type)_\(sequence.sequenceNumber)"
                        expectedSequences.insert(sequenceId)
                    }
                } catch {
                    DebugLogger.data("⚠️ Failed to read step sparring sequences from \(filename): \(error)")
                }
            } else {
                DebugLogger.data("⚠️ Step sparring file not found: \(filename).json")
            }
        }
        
        DebugLogger.data("📋 Expected step sparring sequences from JSON: \(expectedSequences.sorted())")
        return expectedSequences
    }
    
    /**
     * Dynamically discovers step sparring files from StepSparring subdirectory
     */
    private func discoverStepSparringFiles() -> [String] {
        var foundFiles: [String] = []
        
        // First try: Scan StepSparring subdirectory for any JSON files
        if let stepSparringPath = Bundle.main.path(forResource: nil, ofType: nil, inDirectory: "StepSparring") {
            DebugLogger.data("📁 Scanning StepSparring subdirectory: \(stepSparringPath)")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: stepSparringPath)
                let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                
                for jsonFile in jsonFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan StepSparring subdirectory: \(error)")
            }
        }
        
        // Fallback: Try bundle root for files containing step sparring patterns
        if foundFiles.isEmpty, let bundlePath = Bundle.main.resourcePath {
            DebugLogger.data("📁 StepSparring subdirectory not found, scanning bundle root for step sparring files...")
            
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let stepSparringFiles = contents.filter { filename in
                    guard filename.hasSuffix(".json") else { return false }
                    // Look for files that match step sparring patterns
                    return filename.contains("_step") || filename.contains("semi_free")
                }
                
                for jsonFile in stepSparringFiles {
                    let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                    foundFiles.append(filename)
                }
            } catch {
                DebugLogger.data("⚠️ Failed to scan bundle root: \(error)")
            }
        }
        
        return foundFiles.sorted()
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
            
            DebugLogger.data("🔍 Step sparring sync check - existing: \(existingSequences.count), expected: \(expectedSequenceCount), missing belt data: \(missingBeltData)")
            DebugLogger.data("🔍 Missing sequences: \(missingSequences), Extra sequences: \(extraSequences)")
            
            if existingSequences.count != expectedSequenceCount || !missingSequences.isEmpty || !extraSequences.isEmpty || missingBeltData {
                if !missingSequences.isEmpty {
                    DebugLogger.data("🥊 Missing step sparring sequences: \(missingSequences.sorted()) - reloading from JSON...")
                }
                if !extraSequences.isEmpty {
                    DebugLogger.data("🥊 Extra step sparring sequences: \(extraSequences.sorted()) - reloading from JSON...")
                }
                if existingSequences.count != expectedSequenceCount {
                    DebugLogger.data("🥊 Step sparring count mismatch: \(existingSequences.count) vs \(expectedSequenceCount) expected - reloading...")
                }
                if missingBeltData {
                    DebugLogger.data("🥊 Step sparring sequences missing JSON belt level data - reloading...")
                }
                
                DebugLogger.data("🔄 Triggering step sparring reload...")
                stepSparringService.clearAndReloadStepSparring()
                DebugLogger.data("✅ Step sparring reload completed")
            } else {
                DebugLogger.data("✅ Complete step sparring set synchronized (\(existingSequences.count) sequences)")
                for sequence in existingSequences.prefix(3) {
                    DebugLogger.data("   \(sequence.name): \(sequence.steps.count) steps, JSON belts: \(sequence.applicableBeltLevelIds)")
                }
            }
        } catch {
            DebugLogger.data("❌ Failed to check step sparring synchronization: \(error)")
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
            DebugLogger.data("✅ User progress reset successfully")
        } catch {
            DebugLogger.data("❌ Failed to reset user progress: \\(error)")
        }
    }
    
    /**
     * Resets entire database and reinitializes container
     * Use this to force reload when content structure changes
     * 
     * IMPROVED: Graceful in-process reset instead of nuclear exit(0) approach
     */
    func resetAndReloadDatabase() async throws {
        DebugLogger.data("🔄 Starting graceful database reset...")
        
        // Set resetting flag to prevent any profile access during reset
        isResettingDatabase = true
        
        // Notify observers that reset is starting
        NotificationCenter.default.post(name: .databaseResetStarting, object: nil)
        
        // CRITICAL: Clear ProfileService active profile reference
        profileService.clearActiveProfileForReset()

        // Save the current model container reference (for cleanup if needed)
        _ = modelContainer

        do {
            // Delete the database files completely
            let appSupportDir = URL.applicationSupportDirectory
            let dbURL = appSupportDir.appending(path: "Model.sqlite")
            let dbSHMURL = appSupportDir.appending(path: "Model.sqlite-shm")
            let dbWALURL = appSupportDir.appending(path: "Model.sqlite-wal")
            
            try? FileManager.default.removeItem(at: dbURL)
            try? FileManager.default.removeItem(at: dbSHMURL)
            try? FileManager.default.removeItem(at: dbWALURL)
            
            DebugLogger.data("🗑️ Database files deleted successfully")
            
            // Create new model container with same configuration
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
                PatternTestResult.self,
                StudySession.self,
                StepSparringSequence.self,
                StepSparringStep.self,
                StepSparringAction.self,
                UserStepSparringProgress.self,
                GradingRecord.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            
            let newContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Update all service references with new container
            self.modelContainer = newContainer
            self.terminologyService = TerminologyDataService(modelContext: newContainer.mainContext)
            self.patternService = PatternDataService(modelContext: newContainer.mainContext)
            self.progressCacheService = ProgressCacheService(modelContext: newContainer.mainContext)
            self.profileService = ProfileService(modelContext: newContainer.mainContext)
            self.stepSparringService = StepSparringDataService(modelContext: newContainer.mainContext)
            self.profileExportService = ProfileExportService(modelContext: newContainer.mainContext)
            self.leitnerService = LeitnerService(modelContext: newContainer.mainContext)
            self.techniquesService = TechniquesDataService()
            
            // Reconnect service dependencies
            self.profileService.progressCacheService = self.progressCacheService
            self.profileService.exportService = self.profileExportService
            
            // Generate new reset ID to trigger UI refresh
            databaseResetId = UUID()
            isResettingDatabase = false
            
            DebugLogger.data("✅ Database container recreated successfully")
            
            // Reload all content from JSON
            await setupInitialData()
            
            DebugLogger.data("✅ Database reset and reload completed successfully")
            
        } catch {
            DebugLogger.data("❌ Database reset failed: \(error)")
            isResettingDatabase = false
            throw error
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
