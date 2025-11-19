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

    private(set) var modelContainer: ModelContainer!
    private(set) var terminologyService: TerminologyDataService!
    private(set) var patternService: PatternDataService!
    private(set) var profileService: ProfileService!
    private(set) var stepSparringService: StepSparringDataService!
    private(set) var progressCacheService: ProgressCacheService!
    private(set) var profileExportService: ProfileExportService!
    private(set) var leitnerService: LeitnerService!
    private(set) var techniquesService: TechniquesDataService!
    
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
    
    // MARK: - Content Version Tracking (Hash-Based)

    private static let lastTerminologyHashKey = "TKDojang_LastTerminologyHash"
    private static let lastPatternsHashKey = "TKDojang_LastPatternsHash"
    private static let lastStepSparringHashKey = "TKDojang_LastStepSparringHash"
    private static let lastBeltSystemHashKey = "TKDojang_LastBeltSystemHash"
    private static let lastContentSyncDateKey = "TKDojang_LastContentSyncDate"

    /**
     * Checks if terminology content has changed since last launch
     * Uses SHA-256 hash of all terminology JSON files
     */
    private func hasTerminologyContentChanged() -> Bool {
        let currentHash = ContentVersion.terminologyHash
        let lastHash = UserDefaults.standard.string(forKey: Self.lastTerminologyHashKey)

        if lastHash == nil {
            DebugLogger.data("📚 First launch - no previous terminology hash recorded")
            return true
        }

        let changed = currentHash != lastHash
        if changed {
            DebugLogger.data("📚 Terminology content changed (hash mismatch)")
            DebugLogger.data("   Old: \(lastHash?.prefix(16) ?? "none")...")
            DebugLogger.data("   New: \(currentHash.prefix(16))...")
        }

        return changed
    }

    /**
     * Checks if belt system content has changed since last launch
     */
    private func hasBeltSystemContentChanged() -> Bool {
        let currentHash = ContentVersion.beltSystemHash
        let lastHash = UserDefaults.standard.string(forKey: Self.lastBeltSystemHashKey)

        if lastHash == nil {
            DebugLogger.data("📋 First launch - no previous belt system hash recorded")
            return true
        }

        let changed = currentHash != lastHash
        if changed {
            DebugLogger.data("📋 Belt system content changed (hash mismatch)")
        }

        return changed
    }

    /**
     * Checks if pattern content has changed since last launch
     * Uses SHA-256 hash of all pattern JSON files
     */
    private func hasPatternsContentChanged() -> Bool {
        let currentHash = ContentVersion.patternsHash
        let lastHash = UserDefaults.standard.string(forKey: Self.lastPatternsHashKey)

        if lastHash == nil {
            DebugLogger.data("🥋 First launch - no previous patterns hash recorded")
            return true
        }

        let changed = currentHash != lastHash
        if changed {
            DebugLogger.data("🥋 Pattern content changed (hash mismatch)")
            DebugLogger.data("   Old: \(lastHash?.prefix(16) ?? "none")...")
            DebugLogger.data("   New: \(currentHash.prefix(16))...")
        }

        return changed
    }

    /**
     * Checks if step sparring content has changed since last launch
     * Uses SHA-256 hash of all step sparring JSON files
     */
    private func hasStepSparringContentChanged() -> Bool {
        let currentHash = ContentVersion.stepSparringHash
        let lastHash = UserDefaults.standard.string(forKey: Self.lastStepSparringHashKey)

        if lastHash == nil {
            DebugLogger.data("🥊 First launch - no previous step sparring hash recorded")
            return true
        }

        let changed = currentHash != lastHash
        if changed {
            DebugLogger.data("🥊 Step sparring content changed (hash mismatch)")
            DebugLogger.data("   Old: \(lastHash?.prefix(16) ?? "none")...")
            DebugLogger.data("   New: \(currentHash.prefix(16))...")
        }

        return changed
    }

    /**
     * Saves current content hashes to UserDefaults after successful sync
     */
    private func saveCurrentContentHashes() {
        UserDefaults.standard.set(ContentVersion.terminologyHash, forKey: Self.lastTerminologyHashKey)
        UserDefaults.standard.set(ContentVersion.patternsHash, forKey: Self.lastPatternsHashKey)
        UserDefaults.standard.set(ContentVersion.stepSparringHash, forKey: Self.lastStepSparringHashKey)
        UserDefaults.standard.set(ContentVersion.beltSystemHash, forKey: Self.lastBeltSystemHashKey)
        UserDefaults.standard.set(Date(), forKey: Self.lastContentSyncDateKey)

        DebugLogger.data("💾 Saved content hashes:")
        DebugLogger.data("   Terminology: \(ContentVersion.terminologyHash.prefix(16))...")
        DebugLogger.data("   Patterns:    \(ContentVersion.patternsHash.prefix(16))...")
        DebugLogger.data("   StepSpar:    \(ContentVersion.stepSparringHash.prefix(16))...")
        DebugLogger.data("   BeltSystem:  \(ContentVersion.beltSystemHash.prefix(16))...")
    }

    /**
     * Sets up initial data and ensures content is synchronized with JSON files
     *
     * PURPOSE: Ensures the app has up-to-date content from JSON files
     * Uses content hashes to detect when JSON files have changed
     */
    func setupInitialData() async {
        DebugLogger.data("🔍 setupInitialData() called - \(Date())")
        DebugLogger.data("📦 Content hashes from build: \(ContentVersion.generatedAt)")

        // Check if content has changed using hashes (NOT app version)
        let terminologyContentChanged = hasTerminologyContentChanged()
        let beltSystemContentChanged = hasBeltSystemContentChanged()
        let patternsContentChanged = hasPatternsContentChanged()
        let stepSparringContentChanged = hasStepSparringContentChanged()

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
            await ensurePatternsAreSynchronized(forceReload: patternsContentChanged)

            DebugLogger.data("🥊 Starting step sparring synchronization...")
            await ensureStepSparringIsSynchronized(forceReload: stepSparringContentChanged)

            DebugLogger.data("📚 Starting terminology synchronization...")
            await ensureTerminologyIsSynchronized(forceReload: terminologyContentChanged)

            DebugLogger.data("📋 Starting belt system synchronization...")
            await ensureBeltSystemIsSynchronized(forceReload: beltSystemContentChanged)

            // Save current content hashes after successful sync
            saveCurrentContentHashes()

            DebugLogger.data("✅ setupInitialData() completed successfully - \(Date())")
        } catch {
            DebugLogger.data("❌ setupInitialData() failed: \\(error) - \(Date())")
        }
    }
    
    /**
     * Ensures patterns are properly synchronized with JSON content
     *
     * PARAMETERS:
     * - forceReload: If true, reloads patterns regardless of count match (when hash changed)
     */
    private func ensurePatternsAreSynchronized(forceReload: Bool = false) async {
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

            DebugLogger.data("🔍 Pattern sync check - existing: \(existingPatterns.count), expected: \(expectedPatternCount), forceReload: \(forceReload)")

            if forceReload {
                DebugLogger.data("🥋 Pattern content changed - forcing pattern reload...")
                patternService.clearAndReloadPatterns()
                DebugLogger.data("✅ Pattern reload completed")
            } else if existingPatterns.count != expectedPatternCount || !missingPatterns.isEmpty || !extraPatterns.isEmpty {
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
     *
     * PARAMETERS:
     * - forceReload: If true, reloads step sparring regardless of count match (when hash changed)
     */
    private func ensureStepSparringIsSynchronized(forceReload: Bool = false) async {
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

            DebugLogger.data("🔍 Step sparring sync check - existing: \(existingSequences.count), expected: \(expectedSequenceCount), forceReload: \(forceReload)")

            if forceReload {
                DebugLogger.data("🥊 Step sparring content changed - forcing step sparring reload...")
                stepSparringService.clearAndReloadStepSparring()
                DebugLogger.data("✅ Step sparring reload completed")
            } else if existingSequences.count != expectedSequenceCount || !missingSequences.isEmpty || !extraSequences.isEmpty || missingBeltData {
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
     * Ensures terminology entries are properly synchronized with JSON content
     *
     * PURPOSE: Auto-updates terminology when JSON files change (e.g., spelling corrections)
     * Compares expected term count from JSON files vs database
     *
     * PARAMETERS:
     * - forceReload: If true, reloads terminology regardless of count match (e.g., on version change)
     */
    private func ensureTerminologyIsSynchronized(forceReload: Bool = false) async {
        let terminologyDescriptor = FetchDescriptor<TerminologyEntry>()

        do {
            let existingEntries = try modelContainer.mainContext.fetch(terminologyDescriptor)

            // Get expected term count from JSON files
            let expectedCount = getExpectedTerminologyCount()

            DebugLogger.data("🔍 Terminology sync check - existing: \(existingEntries.count), expected: \(expectedCount), forceReload: \(forceReload)")

            if forceReload {
                DebugLogger.data("📚 App version changed - forcing terminology reload to ensure content updates...")
                terminologyService.clearAndReloadTerminology()
                DebugLogger.data("✅ Terminology reload completed")
            } else if existingEntries.count != expectedCount {
                DebugLogger.data("📚 Terminology count mismatch: \(existingEntries.count) vs \(expectedCount) expected - reloading...")
                terminologyService.clearAndReloadTerminology()
                DebugLogger.data("✅ Terminology reload completed")
            } else {
                DebugLogger.data("✅ Terminology synchronized (\(existingEntries.count) entries)")
            }
        } catch {
            DebugLogger.data("❌ Failed to check terminology synchronization: \(error)")
        }
    }

    /**
     * Counts total terminology entries across all JSON files
     *
     * PURPOSE: Determines how many terminology entries SHOULD exist based on JSON files
     */
    private func getExpectedTerminologyCount() -> Int {
        var totalCount = 0

        // Get all belt level JSON files
        let terminologyFiles = discoverTerminologyFiles()

        DebugLogger.data("📁 Discovered \(terminologyFiles.count) terminology JSON files")

        for filename in terminologyFiles {
            var url: URL?

            // Try standard paths
            url = Bundle.main.url(forResource: filename, withExtension: "json")
            if url == nil {
                url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Content")
            }

            if let url = url {
                do {
                    let data = try Data(contentsOf: url)
                    let content = try JSONDecoder().decode(CategoryContent.self, from: data)
                    totalCount += content.terminology.count
                } catch {
                    DebugLogger.data("⚠️ Failed to count terms in \(filename): \(error)")
                }
            }
        }

        DebugLogger.data("📋 Expected terminology total: \(totalCount) entries")
        return totalCount
    }

    /**
     * Dynamically discovers terminology JSON files
     *
     * Pattern: {belt_id}_{category}.json (e.g., "10th_keup_basics.json")
     */
    private func discoverTerminologyFiles() -> [String] {
        var foundFiles: [String] = []

        guard let bundlePath = Bundle.main.resourcePath else {
            DebugLogger.data("⚠️ Could not access bundle resource path")
            return foundFiles
        }

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)

            // Find files matching terminology patterns
            // Valid categories: basics, numbers, techniques
            let validCategories = ["_basics.json", "_numbers.json", "_techniques.json"]
            let terminologyFiles = contents.filter { filename in
                guard filename.hasSuffix(".json") else { return false }
                guard filename.contains("_keup_") || filename.contains("_dan_") else { return false }

                // Only match actual terminology categories (not patterns, theory, linework, step sparring)
                return validCategories.contains { filename.hasSuffix($0) }
            }

            for jsonFile in terminologyFiles {
                let filename = jsonFile.replacingOccurrences(of: ".json", with: "")
                foundFiles.append(filename)
            }
        } catch {
            DebugLogger.data("⚠️ Failed to scan bundle for terminology files: \(error)")
        }

        return foundFiles.sorted()
    }

    /**
     * Ensures belt system metadata is synchronized with JSON content
     *
     * PURPOSE: Updates belt colors, names, requirements when belt_system.json changes
     * SAFETY: Never deletes/recreates BeltLevel records (preserves user FK relationships)
     *
     * PARAMETERS:
     * - forceReload: If true, reloads belt metadata regardless (when hash changed)
     */
    private func ensureBeltSystemIsSynchronized(forceReload: Bool = false) async {
        do {
            // Load belt system configuration from JSON
            guard let url = Bundle.main.url(forResource: "belt_system", withExtension: "json") else {
                DebugLogger.data("⚠️ belt_system.json not found")
                return
            }

            let data = try Data(contentsOf: url)
            let config = try JSONDecoder().decode(BeltSystemConfig.self, from: data)

            // Fetch existing belt levels from database
            let beltDescriptor = FetchDescriptor<BeltLevel>()
            let existingBelts = try modelContainer.mainContext.fetch(beltDescriptor)

            // DATA QUALITY CHECK: Always run corruption detection (not just on hash change)
            let expectedCount = config.beltSystem.belts.count
            if existingBelts.count != expectedCount {
                DebugLogger.data("⚠️ DATABASE CORRUPTION DETECTED:")
                DebugLogger.data("   Expected belt count: \(expectedCount)")
                DebugLogger.data("   Actual belt count: \(existingBelts.count)")
                DebugLogger.data("   This suggests duplicate or orphaned belt records.")
                DebugLogger.data("   📱 SOLUTION: Use 'Reset Database & Reload Content' from User Settings.")
            }

            // Check for empty/null shortName values
            let invalidBelts = existingBelts.filter { $0.shortName.isEmpty }
            if !invalidBelts.isEmpty {
                DebugLogger.data("⚠️ Found \(invalidBelts.count) belt records with empty shortName:")
                for belt in invalidBelts.prefix(5) {
                    DebugLogger.data("   - ID: \(belt.id), name: \(belt.name)")
                }
                DebugLogger.data("   📱 SOLUTION: Use 'Reset Database & Reload Content' from User Settings.")
            }

            // Create a map of existing belts by short name (our stable key)
            var beltMap: [String: BeltLevel] = [:]
            var duplicateCount = 0
            for belt in existingBelts {
                guard !belt.shortName.isEmpty else {
                    continue // Skip belts with corrupt shortName
                }

                if beltMap[belt.shortName] != nil {
                    duplicateCount += 1
                    DebugLogger.data("⚠️ Duplicate shortName detected: '\(belt.shortName)' - keeping first occurrence")
                } else {
                    beltMap[belt.shortName] = belt
                }
            }

            if duplicateCount > 0 {
                DebugLogger.data("⚠️ Found \(duplicateCount) duplicate belt records in database")
                DebugLogger.data("   📱 SOLUTION: Use 'Reset Database & Reload Content' from User Settings.")
            }

            // Only update metadata if hash changed
            guard forceReload else {
                DebugLogger.data("✅ Belt system unchanged (hash match)")
                return
            }

            DebugLogger.data("📋 Belt system content changed - updating metadata...")

            // Update each belt's metadata (NEVER delete/recreate - preserves FKs)
            var updatedCount = 0
            for beltConfig in config.beltSystem.belts {
                if let existingBelt = beltMap[beltConfig.shortName] {
                    // Update metadata fields (safe to change)
                    existingBelt.name = beltConfig.name
                    existingBelt.colorName = beltConfig.colorName
                    existingBelt.requirements = beltConfig.description
                    existingBelt.primaryColor = beltConfig.primaryColor
                    existingBelt.secondaryColor = beltConfig.secondaryColor
                    existingBelt.textColor = beltConfig.textColor
                    existingBelt.borderColor = beltConfig.borderColor
                    existingBelt.sortOrder = beltConfig.sortOrder
                    existingBelt.isKyup = beltConfig.isKeup

                    updatedCount += 1
                } else {
                    DebugLogger.data("⚠️ Belt level not found in database: \(beltConfig.shortName) - skipping")
                }
            }

            try modelContainer.mainContext.save()
            DebugLogger.data("✅ Belt system metadata updated (\(updatedCount) belts)")

        } catch {
            DebugLogger.data("❌ Failed to sync belt system: \(error)")
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

        DebugLogger.data("DEBUG: About to set isResettingDatabase = true")
        // Set resetting flag to prevent any profile access during reset
        isResettingDatabase = true
        DebugLogger.data("DEBUG: Set isResettingDatabase = true COMPLETED")

        DebugLogger.data("DEBUG: About to post notification")
        // Notify observers that reset is starting
        NotificationCenter.default.post(name: .databaseResetStarting, object: nil)
        DebugLogger.data("DEBUG: Notification posted COMPLETED")

        do {
            terminologyService = nil
            patternService = nil
            stepSparringService = nil
            progressCacheService = nil
            profileService = nil
            profileExportService = nil
            leitnerService = nil
            techniquesService = nil
            modelContainer = nil

            DebugLogger.data("DEBUG: Services nil'd, about to get appSupportDir")
            // Delete the database files completely
            let appSupportDir = URL.applicationSupportDirectory
            DebugLogger.data("DEBUG: Got appSupportDir, creating URLs")
            let dbURL = appSupportDir.appending(path: "Model.sqlite")
            let dbSHMURL = appSupportDir.appending(path: "Model.sqlite-shm")
            let dbWALURL = appSupportDir.appending(path: "Model.sqlite-wal")

            DebugLogger.data("DEBUG: About to delete database files")
            // Try to delete files and log any errors
            do {
                try FileManager.default.removeItem(at: dbURL)
                DebugLogger.data("✅ Deleted Model.sqlite")
            } catch {
                DebugLogger.data("⚠️ Could not delete Model.sqlite: \(error.localizedDescription)")
            }

            do {
                try FileManager.default.removeItem(at: dbSHMURL)
                DebugLogger.data("✅ Deleted Model.sqlite-shm")
            } catch {
                DebugLogger.data("⚠️ Could not delete Model.sqlite-shm: \(error.localizedDescription)")
            }

            do {
                try FileManager.default.removeItem(at: dbWALURL)
                DebugLogger.data("✅ Deleted Model.sqlite-wal")
            } catch {
                DebugLogger.data("⚠️ Could not delete Model.sqlite-wal: \(error.localizedDescription)")
            }

            DebugLogger.data("DEBUG: File deletion completed, about to create schema")

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

            DebugLogger.data("DEBUG: Schema created, about to create ModelConfiguration")

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            DebugLogger.data("DEBUG: ModelConfiguration created, about to create ModelContainer")

            let newContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            DebugLogger.data("DEBUG: New ModelContainer created, about to update services")

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

            DebugLogger.data("DEBUG: Services updated, about to reconnect dependencies")

            // Reconnect service dependencies
            self.profileService.progressCacheService = self.progressCacheService
            self.profileService.exportService = self.profileExportService

            DebugLogger.data("DEBUG: Dependencies reconnected, about to update reset flags")

            // Generate new reset ID to trigger UI refresh
            databaseResetId = UUID()
            isResettingDatabase = false

            DebugLogger.data("✅ Database container recreated successfully")

            DebugLogger.data("DEBUG: About to call setupInitialData()")
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
