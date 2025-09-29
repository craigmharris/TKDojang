import Foundation
import SwiftData
import UniformTypeIdentifiers
import UIKit

// Import all model types needed by the export service
// Note: In a typical project, these would be consolidated into a single Models module

/**
 * ProfileExportService.swift
 * 
 * PURPOSE: Handles export/import of user profile data for device migration and backup
 * 
 * FEATURES:
 * - Local file export/import (JSON format)
 * - iCloud Document storage integration  
 * - Data validation and error handling
 * - Automatic backup on profile changes
 * - Cross-device synchronization support
 */

// MARK: - Export Data Models

/**
 * JSON-serializable version of user profile data for export/import
 * Excludes SwiftData relationships and includes all user progress
 */
struct ExportableProfile: Codable {
    // Profile metadata
    let id: UUID
    let name: String
    let avatar: String // ProfileAvatar raw value
    let colorTheme: String // ProfileColorTheme raw value  
    let currentBeltLevel: String // BeltLevel title
    let learningMode: String // LearningMode raw value
    let createdAt: Date
    let lastActiveAt: Date
    let totalStudyTime: TimeInterval
    let dailyStudyGoal: Int
    
    // Profile statistics
    let streakDays: Int
    let totalFlashcardsSeen: Int
    let totalTestsTaken: Int
    let totalPatternsLearned: Int
    
    // Progress data
    let terminologyProgress: [ExportableTerminologyProgress]
    let patternProgress: [ExportablePatternProgress] 
    let studySessions: [ExportableStudySession]
    let stepSparringProgress: [ExportableStepSparringProgress]
    let gradingHistory: [ExportableGradingRecord]
    
    // Export metadata
    let exportedAt: Date
    let appVersion: String
    let exportVersion: String
    
    static let currentExportVersion = "1.0"
}

struct ExportableTerminologyProgress: Codable {
    let id: UUID
    let terminologyEntryID: UUID
    let masteryLevel: String
    let correctCount: Int
    let incorrectCount: Int
    let lastReviewedAt: Date?
    let nextReviewAt: Date?
    let createdAt: Date
}

struct ExportablePatternProgress: Codable {
    let id: UUID
    let patternName: String
    let masteryLevel: String
    let practiceCount: Int
    let lastPracticedAt: Date?
    let createdAt: Date
}

struct ExportableStudySession: Codable {
    let id: UUID
    let sessionType: String
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date?
    let itemsStudied: Int
    let accuracy: Double?
    let notes: String?
}

struct ExportableStepSparringProgress: Codable {
    let id: UUID
    let sequenceType: String
    let sequenceNumber: Int
    let masteryLevel: String
    let practiceCount: Int
    let lastPracticedAt: Date?
    let createdAt: Date
}

struct ExportableGradingRecord: Codable {
    let id: UUID
    let beltTested: String
    let beltAchieved: String
    let gradingDate: Date
    let gradingType: String
    let passGrade: String
    let examiner: String
    let club: String
    let notes: String
    let preparationTime: TimeInterval
    let passed: Bool
    let createdAt: Date
}

/**
 * Container for multiple profile exports
 */
struct ProfileExportContainer: Codable {
    let profiles: [ExportableProfile]
    let exportedAt: Date
    let deviceName: String
    let appVersion: String
    let exportVersion: String
    
    static let currentExportVersion = "1.0"
}

// MARK: - Export Service

@MainActor
class ProfileExportService: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Export Functions
    
    /**
     * Exports a single profile to JSON data
     */
    func exportProfile(_ profile: UserProfile) throws -> Data {
        let exportableProfile = try convertToExportable(profile)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(exportableProfile)
    }
    
    /**
     * Exports all profiles to a container JSON
     */
    func exportAllProfiles() throws -> Data {
        let request = FetchDescriptor<UserProfile>(sortBy: [SortDescriptor(\.profileOrder)])
        let profiles = try modelContext.fetch(request)
        
        let exportableProfiles = try profiles.map { try convertToExportable($0) }
        
        let container = ProfileExportContainer(
            profiles: exportableProfiles,
            exportedAt: Date(),
            deviceName: getDeviceName(),
            appVersion: getAppVersion(),
            exportVersion: ProfileExportContainer.currentExportVersion
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(container)
    }
    
    /**
     * Saves profile export to local file
     */
    func saveProfileToFile(_ profile: UserProfile) throws -> URL {
        let data = try exportProfile(profile)
        let filename = "TKDojang_\(profile.name)_\(formatDateForFilename(Date())).tkdprofile"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    /**
     * Saves all profiles export to local file
     */
    func saveAllProfilesToFile() throws -> URL {
        let data = try exportAllProfiles()
        let filename = "TKDojang_AllProfiles_\(formatDateForFilename(Date())).tkdbackup"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Import Functions
    
    /**
     * Imports profile from JSON data
     */
    func importProfile(from data: Data, replaceExisting: Bool = false) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportableProfile = try decoder.decode(ExportableProfile.self, from: data)
        
        // Check if profile already exists
        let existingRequest = FetchDescriptor<UserProfile>(
            predicate: #Predicate<UserProfile> { $0.id == exportableProfile.id }
        )
        let existingProfiles = try modelContext.fetch(existingRequest)
        
        if !existingProfiles.isEmpty && !replaceExisting {
            throw ProfileImportError.profileAlreadyExists(name: exportableProfile.name)
        }
        
        // Remove existing profile if replacing
        if let existingProfile = existingProfiles.first, replaceExisting {
            modelContext.delete(existingProfile)
        }
        
        // Convert and insert new profile
        try importExportableProfile(exportableProfile)
        try modelContext.save()
    }
    
    /**
     * Imports profiles from container JSON data
     */
    func importProfiles(from data: Data, replaceExisting: Bool = false) throws -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let container = try decoder.decode(ProfileExportContainer.self, from: data)
        
        var imported = 0
        var skipped = 0
        var errors: [String] = []
        
        for exportableProfile in container.profiles {
            do {
                // Check if profile exists
                let existingRequest = FetchDescriptor<UserProfile>(
                    predicate: #Predicate<UserProfile> { $0.id == exportableProfile.id }
                )
                let existingProfiles = try modelContext.fetch(existingRequest)
                
                if !existingProfiles.isEmpty && !replaceExisting {
                    skipped += 1
                    continue
                }
                
                // Remove existing if replacing
                if let existing = existingProfiles.first, replaceExisting {
                    modelContext.delete(existing)
                }
                
                try importExportableProfile(exportableProfile)
                imported += 1
                
            } catch {
                errors.append("Failed to import \(exportableProfile.name): \(error.localizedDescription)")
            }
        }
        
        try modelContext.save()
        
        return ImportResult(
            imported: imported,
            skipped: skipped, 
            errors: errors,
            totalProfiles: container.profiles.count
        )
    }
    
    /**
     * Imports profile from local file URL
     */
    func importProfileFromFile(_ fileURL: URL, replaceExisting: Bool = false) throws -> ImportResult {
        let data = try Data(contentsOf: fileURL)
        
        // Try container format first
        do {
            return try importProfiles(from: data, replaceExisting: replaceExisting)
        } catch {
            // Try single profile format
            try importProfile(from: data, replaceExisting: replaceExisting)
            return ImportResult(imported: 1, skipped: 0, errors: [], totalProfiles: 1)
        }
    }
    
    // MARK: - iCloud Integration
    
    /**
     * Saves profile backup to iCloud Documents
     */
    func saveToiCloud(_ profile: UserProfile) throws -> URL {
        let data = try exportProfile(profile)
        let filename = "TKDojang_\(profile.name)_Backup.tkdprofile"
        let iCloudURL = try getiCloudDocumentsURL()
        let fileURL = iCloudURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        
        // Set file to be stored in iCloud
        try (fileURL as NSURL).setResourceValue(true, forKey: .hasHiddenExtensionKey)
        
        return fileURL
    }
    
    /**
     * Saves all profiles backup to iCloud Documents
     */
    func saveAllToiCloud() throws -> URL {
        let data = try exportAllProfiles()
        let filename = "TKDojang_AllProfiles_Backup.tkdbackup"
        let iCloudURL = try getiCloudDocumentsURL()
        let fileURL = iCloudURL.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    /**
     * Lists available backups in iCloud Documents
     */
    func listiCloudBackups() throws -> [URL] {
        let iCloudURL = try getiCloudDocumentsURL()
        let contents = try FileManager.default.contentsOfDirectory(
            at: iCloudURL,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        )
        
        return contents.filter { url in
            url.pathExtension == "tkdprofile" || url.pathExtension == "tkdbackup"
        }.sorted { url1, url2 in
            let date1 = try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate
            let date2 = try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate
            return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
        }
    }
    
    // MARK: - Automatic Backup
    
    /**
     * Automatically backs up profile changes to iCloud (if available)
     */
    func autoBackupProfile(_ profile: UserProfile) {
        Task {
            do {
                _ = try saveToiCloud(profile)
                print("✅ Profile \(profile.name) automatically backed up to iCloud")
            } catch {
                print("⚠️ Failed to auto-backup profile to iCloud: \(error)")
                // Silent failure - automatic backup shouldn't interrupt user flow
            }
        }
    }
    
    // MARK: - Safe Loading Methods (Direct Queries)
    
    private func convertToExportable(_ profile: UserProfile) throws -> ExportableProfile {
        // CRITICAL: Extract all primitive data FIRST to prevent SwiftData invalidation
        let profileId = profile.id
        let profileName = profile.name
        let avatarRawValue = profile.avatar.rawValue
        let colorThemeRawValue = profile.colorTheme.rawValue
        let currentBeltShortName = profile.currentBeltLevel.shortName
        let learningModeRawValue = profile.learningMode.rawValue
        let createdAtDate = profile.createdAt
        let lastActiveAtDate = profile.lastActiveAt
        let totalStudyTimeValue = profile.totalStudyTime
        let dailyStudyGoalValue = profile.dailyStudyGoal
        let streakDaysValue = profile.streakDays
        let totalFlashcardsSeenValue = profile.totalFlashcardsSeen
        let totalTestsTakenValue = profile.totalTestsTaken
        let totalPatternsLearnedValue = profile.totalPatternsLearned
        
        // Use individual queries instead of relationship navigation to avoid crashes
        let terminologyProgressData = try loadTerminologyProgressSafely(profileId: profileId)
        let patternProgressData = try loadPatternProgressSafely(profileId: profileId)
        let studySessionsData = try loadStudySessionsSafely(profileId: profileId)
        let gradingHistoryData = try loadGradingHistorySafely(profileId: profileId)
        
        return ExportableProfile(
            id: profileId,
            name: profileName,
            avatar: avatarRawValue,
            colorTheme: colorThemeRawValue,
            currentBeltLevel: currentBeltShortName,
            learningMode: learningModeRawValue,
            createdAt: createdAtDate,
            lastActiveAt: lastActiveAtDate,
            totalStudyTime: totalStudyTimeValue,
            dailyStudyGoal: dailyStudyGoalValue,
            streakDays: streakDaysValue,
            totalFlashcardsSeen: totalFlashcardsSeenValue,
            totalTestsTaken: totalTestsTakenValue,
            totalPatternsLearned: totalPatternsLearnedValue,
            terminologyProgress: terminologyProgressData,
            patternProgress: patternProgressData,
            studySessions: studySessionsData,
            stepSparringProgress: [], // TEMPORARILY EMPTY: Skip step sparring to prevent SwiftData crashes
            gradingHistory: gradingHistoryData,
            exportedAt: Date(),
            appVersion: getAppVersion(),
            exportVersion: ExportableProfile.currentExportVersion
        )
    }
    
    /**
     * Load terminology progress using direct query instead of relationship navigation
     */
    private func loadTerminologyProgressSafely(profileId: UUID) throws -> [ExportableTerminologyProgress] {
        let request = FetchDescriptor<UserTerminologyProgress>(
            predicate: #Predicate<UserTerminologyProgress> { progress in
                progress.userProfile.id == profileId
            }
        )
        let progressArray = try modelContext.fetch(request)
        
        return progressArray.compactMap { progress in
            do {
                return try convertToExportableTerminology(progress)
            } catch {
                print("⚠️ Skipping invalidated terminology progress: \(error)")
                return nil
            }
        }
    }
    
    /**
     * Load pattern progress using direct query instead of relationship navigation
     */
    private func loadPatternProgressSafely(profileId: UUID) throws -> [ExportablePatternProgress] {
        let request = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate<UserPatternProgress> { progress in
                progress.userProfile.id == profileId
            }
        )
        let progressArray = try modelContext.fetch(request)
        
        return progressArray.compactMap { progress in
            do {
                return try convertToExportablePattern(progress)
            } catch {
                print("⚠️ Skipping invalidated pattern progress: \(error)")
                return nil
            }
        }
    }
    
    /**
     * Load study sessions using direct query instead of relationship navigation
     */
    private func loadStudySessionsSafely(profileId: UUID) throws -> [ExportableStudySession] {
        let request = FetchDescriptor<StudySession>(
            predicate: #Predicate<StudySession> { session in
                session.userProfile.id == profileId
            }
        )
        let sessionsArray = try modelContext.fetch(request)
        
        return sessionsArray.compactMap { session in
            // Extract primitive data immediately to prevent invalidation
            let sessionId = session.id
            let sessionTypeRawValue = session.sessionType.rawValue
            let sessionDuration = session.duration
            let sessionStartTime = session.startTime
            let sessionEndTime = session.endTime
            let sessionItemsStudied = session.itemsStudied
            let sessionAccuracy = session.accuracy
            
            return ExportableStudySession(
                id: sessionId,
                sessionType: sessionTypeRawValue,
                duration: sessionDuration,
                startTime: sessionStartTime,
                endTime: sessionEndTime,
                itemsStudied: sessionItemsStudied,
                accuracy: sessionAccuracy,
                notes: nil
            )
        }
    }
    
    /**
     * Load grading history using direct query instead of relationship navigation
     */
    private func loadGradingHistorySafely(profileId: UUID) throws -> [ExportableGradingRecord] {
        let request = FetchDescriptor<GradingRecord>(
            predicate: #Predicate<GradingRecord> { record in
                record.userProfile.id == profileId
            }
        )
        let recordsArray = try modelContext.fetch(request)
        
        return recordsArray.compactMap { record in
            // Extract primitive data immediately to prevent invalidation
            let recordId = record.id
            let beltTestedShortName = record.beltTested.shortName
            let beltAchievedShortName = record.beltAchieved.shortName
            let recordGradingDate = record.gradingDate
            let gradingTypeRawValue = record.gradingType.rawValue
            let passGradeRawValue = record.passGrade.rawValue
            let recordExaminer = record.examiner
            let recordClub = record.club
            let recordNotes = record.notes
            let recordPreparationTime = record.preparationTime
            let recordPassed = record.passed
            let recordCreatedAt = record.createdAt
            
            return ExportableGradingRecord(
                id: recordId,
                beltTested: beltTestedShortName,
                beltAchieved: beltAchievedShortName,
                gradingDate: recordGradingDate,
                gradingType: gradingTypeRawValue,
                passGrade: passGradeRawValue,
                examiner: recordExaminer,
                club: recordClub,
                notes: recordNotes,
                preparationTime: recordPreparationTime,
                passed: recordPassed,
                createdAt: recordCreatedAt
            )
        }
    }
    
    /**
     * Safely converts terminology progress, handling potential relationship invalidations
     */
    private func safeConvertTerminologyProgress(_ progressArray: [UserTerminologyProgress]) -> [ExportableTerminologyProgress] {
        var validProgress: [ExportableTerminologyProgress] = []
        
        for progress in progressArray {
            do {
                let exportable = try convertToExportableTerminology(progress)
                validProgress.append(exportable)
            } catch {
                print("⚠️ Skipping invalidated terminology progress: \(error)")
            }
        }
        
        return validProgress
    }
    
    private func convertToExportableTerminology(_ progress: UserTerminologyProgress) throws -> ExportableTerminologyProgress {
        // Safely extract terminology entry ID
        let entryID = progress.terminologyEntry.id
        
        return ExportableTerminologyProgress(
            id: progress.id,
            terminologyEntryID: entryID,
            masteryLevel: progress.masteryLevel.rawValue,
            correctCount: progress.correctCount,
            incorrectCount: progress.incorrectCount,
            lastReviewedAt: progress.lastReviewedAt,
            nextReviewAt: progress.nextReviewDate,
            createdAt: progress.createdAt
        )
    }
    
    /**
     * Safely converts pattern progress, handling potential relationship invalidations
     */
    private func safeConvertPatternProgress(_ progressArray: [UserPatternProgress]) -> [ExportablePatternProgress] {
        var validProgress: [ExportablePatternProgress] = []
        
        for progress in progressArray {
            do {
                let exportable = try convertToExportablePattern(progress)
                validProgress.append(exportable)
            } catch {
                print("⚠️ Skipping invalidated pattern progress: \(error)")
            }
        }
        
        return validProgress
    }
    
    private func convertToExportablePattern(_ progress: UserPatternProgress) throws -> ExportablePatternProgress {
        // Safely extract pattern name
        let patternName = progress.pattern.name
        
        return ExportablePatternProgress(
            id: progress.id,
            patternName: patternName,
            masteryLevel: progress.masteryLevel.rawValue,
            practiceCount: progress.practiceCount,
            lastPracticedAt: progress.lastPracticedAt,
            createdAt: progress.createdAt
        )
    }
    
    private func convertToExportable(_ session: StudySession) -> ExportableStudySession {
        ExportableStudySession(
            id: session.id,
            sessionType: session.sessionType.rawValue,
            duration: session.duration,
            startTime: session.startTime,
            endTime: session.endTime,
            itemsStudied: session.itemsStudied,
            accuracy: session.accuracy,
            notes: nil
        )
    }
    
    /**
     * Safely converts step sparring progress, filtering out any invalidated objects
     * Uses defensive programming to prevent SwiftData crashes during export
     */
    private func safeConvertStepSparringProgress(_ progressArray: [UserStepSparringProgress]) -> [ExportableStepSparringProgress] {
        var validProgress: [ExportableStepSparringProgress] = []
        
        for progress in progressArray {
            do {
                // Safely extract sequence data before object can be invalidated
                let exportable = try convertToExportableStepSparring(progress)
                validProgress.append(exportable)
            } catch {
                print("⚠️ Skipping invalidated step sparring progress: \(error)")
                // Continue with other progress objects
            }
        }
        
        return validProgress
    }
    
    private func convertToExportableStepSparring(_ progress: UserStepSparringProgress) throws -> ExportableStepSparringProgress {
        // CRITICAL: Extract primitive data immediately to avoid SwiftData invalidation
        let sequenceTypeRaw = progress.sequence.type.rawValue  
        let sequenceNum = progress.sequence.sequenceNumber
        
        return ExportableStepSparringProgress(
            id: progress.id,
            sequenceType: sequenceTypeRaw,
            sequenceNumber: sequenceNum,
            masteryLevel: progress.masteryLevel.rawValue,
            practiceCount: progress.practiceCount,
            lastPracticedAt: progress.lastPracticed,
            createdAt: progress.createdAt
        )
    }
    
    private func convertToExportable(_ record: GradingRecord) -> ExportableGradingRecord {
        ExportableGradingRecord(
            id: record.id,
            beltTested: record.beltTested.shortName,
            beltAchieved: record.beltAchieved.shortName,
            gradingDate: record.gradingDate,
            gradingType: record.gradingType.rawValue,
            passGrade: record.passGrade.rawValue,
            examiner: record.examiner,
            club: record.club,
            notes: record.notes,
            preparationTime: record.preparationTime,
            passed: record.passed,
            createdAt: record.createdAt
        )
    }
    
    private func importExportableProfile(_ exportable: ExportableProfile) throws {
        // Create new UserProfile (SwiftData will handle the conversion)
        let profile = UserProfile(
            name: exportable.name,
            avatar: ProfileAvatar(rawValue: exportable.avatar) ?? .student1,
            colorTheme: ProfileColorTheme(rawValue: exportable.colorTheme) ?? .blue,
            currentBeltLevel: findBeltLevel(shortName: exportable.currentBeltLevel) ?? createDefaultBeltLevel(),
            learningMode: LearningMode(rawValue: exportable.learningMode) ?? .progression
        )
        
        // Set imported metadata
        profile.id = exportable.id
        profile.createdAt = exportable.createdAt
        profile.lastActiveAt = exportable.lastActiveAt
        profile.totalStudyTime = exportable.totalStudyTime
        profile.dailyStudyGoal = exportable.dailyStudyGoal
        profile.streakDays = exportable.streakDays
        profile.totalFlashcardsSeen = exportable.totalFlashcardsSeen
        profile.totalTestsTaken = exportable.totalTestsTaken
        profile.totalPatternsLearned = exportable.totalPatternsLearned
        
        modelContext.insert(profile)
        
        // Import related data
        for terminologyData in exportable.terminologyProgress {
            try importTerminologyProgress(terminologyData, profile: profile)
        }
        
        for patternData in exportable.patternProgress {
            importPatternProgress(patternData, profile: profile)
        }
        
        for sessionData in exportable.studySessions {
            importStudySession(sessionData, profile: profile)
        }
        
        for stepSparringData in exportable.stepSparringProgress {
            importStepSparringProgress(stepSparringData, profile: profile)
        }
        
        for gradingData in exportable.gradingHistory {
            importGradingRecord(gradingData, profile: profile)
        }
    }
    
    private func importTerminologyProgress(_ data: ExportableTerminologyProgress, profile: UserProfile) throws {
        // Find the terminology entry
        let entryRequest = FetchDescriptor<TerminologyEntry>(
            predicate: #Predicate<TerminologyEntry> { $0.id == data.terminologyEntryID }
        )
        let entries = try modelContext.fetch(entryRequest)
        
        guard let terminologyEntry = entries.first else {
            print("⚠️ Terminology entry not found for ID: \(data.terminologyEntryID)")
            return
        }
        
        let progress = UserTerminologyProgress(
            terminologyEntry: terminologyEntry,
            userProfile: profile
        )
        progress.id = data.id
        progress.masteryLevel = MasteryLevel(rawValue: data.masteryLevel) ?? .learning
        progress.correctCount = data.correctCount
        progress.incorrectCount = data.incorrectCount
        progress.lastReviewedAt = data.lastReviewedAt
        progress.nextReviewDate = data.nextReviewAt ?? Date()
        progress.createdAt = data.createdAt
        
        modelContext.insert(progress)
    }
    
    private func importPatternProgress(_ data: ExportablePatternProgress, profile: UserProfile) {
        // Find the pattern by name
        let patternRequest = FetchDescriptor<Pattern>(
            predicate: #Predicate<Pattern> { $0.name == data.patternName }
        )
        
        guard let pattern = try? modelContext.fetch(patternRequest).first else {
            print("⚠️ Pattern not found for name: \(data.patternName)")
            return
        }
        
        let progress = UserPatternProgress(
            userProfile: profile,
            pattern: pattern
        )
        progress.id = data.id
        progress.masteryLevel = PatternMasteryLevel(rawValue: data.masteryLevel) ?? .learning
        progress.practiceCount = data.practiceCount
        progress.lastPracticedAt = data.lastPracticedAt
        progress.createdAt = data.createdAt
        
        modelContext.insert(progress)
    }
    
    private func importStudySession(_ data: ExportableStudySession, profile: UserProfile) {
        let session = StudySession(
            userProfile: profile,
            sessionType: StudySessionType(rawValue: data.sessionType) ?? .mixed
        )
        session.id = data.id
        session.duration = data.duration
        session.startTime = data.startTime
        session.endTime = data.endTime
        session.itemsStudied = data.itemsStudied
        session.accuracy = data.accuracy ?? 0.0
        // Notes field doesn't exist in StudySession model
        
        modelContext.insert(session)
    }
    
    private func importStepSparringProgress(_ data: ExportableStepSparringProgress, profile: UserProfile) {
        // Find the step sparring sequence by type and number
        let sequenceRequest = FetchDescriptor<StepSparringSequence>(
            predicate: #Predicate<StepSparringSequence> { sequence in
                sequence.type.rawValue == data.sequenceType && sequence.sequenceNumber == data.sequenceNumber
            }
        )
        
        guard let sequence = try? modelContext.fetch(sequenceRequest).first else {
            print("⚠️ Step sparring sequence not found for type: \(data.sequenceType), number: \(data.sequenceNumber)")
            return
        }
        
        let progress = UserStepSparringProgress(
            userProfile: profile,
            sequence: sequence
        )
        progress.id = data.id
        progress.masteryLevel = StepSparringMasteryLevel(rawValue: data.masteryLevel) ?? .learning
        progress.practiceCount = data.practiceCount
        progress.lastPracticed = data.lastPracticedAt
        progress.createdAt = data.createdAt
        
        modelContext.insert(progress)
    }
    
    private func importGradingRecord(_ data: ExportableGradingRecord, profile: UserProfile) {
        let beltTested = findBeltLevel(shortName: data.beltTested) ?? createDefaultBeltLevel()
        let beltAchieved = findBeltLevel(shortName: data.beltAchieved) ?? createDefaultBeltLevel()
        
        let record = GradingRecord(
            userProfile: profile,
            gradingDate: data.gradingDate,
            beltTested: beltTested,
            beltAchieved: beltAchieved,
            gradingType: GradingType(rawValue: data.gradingType) ?? .regular,
            passGrade: PassGrade(rawValue: data.passGrade) ?? .standard,
            examiner: data.examiner,
            club: data.club,
            notes: data.notes,
            preparationTime: data.preparationTime,
            passed: data.passed
        )
        record.id = data.id
        record.createdAt = data.createdAt
        
        modelContext.insert(record)
    }
    
    private func findBeltLevel(shortName: String) -> BeltLevel? {
        let request = FetchDescriptor<BeltLevel>(
            predicate: #Predicate<BeltLevel> { $0.shortName == shortName }
        )
        return try? modelContext.fetch(request).first
    }
    
    private func createDefaultBeltLevel() -> BeltLevel {
        // Try to fetch existing belt levels from database
        let descriptor = FetchDescriptor<BeltLevel>()
        
        do {
            let allBelts = try modelContext.fetch(descriptor)
            if let startingBelt = BeltLevel.findStartingBelt(from: allBelts) {
                return startingBelt
            }
        } catch {
            print("❌ ProfileExportService: Failed to fetch belt levels: \(error)")
        }
        
        // Fallback to creating a basic white belt if no belts exist
        return BeltLevel(name: "10th Keup (White Belt)", shortName: "10th Keup", colorName: "White", sortOrder: 15, isKyup: true)
    }
    
    private func getiCloudDocumentsURL() throws -> URL {
        // Check if iCloud is available and properly configured
        guard FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil else {
            print("❌ iCloud Documents not available - App needs iCloud capability in Xcode project settings")
            print("💡 To fix: In Xcode, go to target settings → Signing & Capabilities → + Capability → iCloud → Documents")
            throw ProfileImportError.iCloudNotAvailable
        }
        
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents") else {
            throw ProfileImportError.iCloudNotAvailable
        }
        
        // Create directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
            print("✅ iCloud Documents directory ready: \(iCloudURL.path)")
        } catch {
            print("❌ Failed to create iCloud Documents directory: \(error)")
            throw error
        }
        
        return iCloudURL
    }
    
    private func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]
    let totalProfiles: Int
    
    var wasSuccessful: Bool {
        return errors.isEmpty && imported > 0
    }
    
    var summary: String {
        if errors.isEmpty {
            return "Successfully imported \(imported) profile(s). Skipped \(skipped) existing profile(s)."
        } else {
            return "Imported \(imported) profile(s) with \(errors.count) error(s). Skipped \(skipped) existing profile(s)."
        }
    }
}

enum ProfileImportError: LocalizedError {
    case profileAlreadyExists(name: String)
    case invalidFileFormat
    case iCloudNotAvailable
    case unsupportedVersion(version: String)
    case missingRequiredData(field: String)
    
    var errorDescription: String? {
        switch self {
        case .profileAlreadyExists(let name):
            return "A profile named '\(name)' already exists. Choose 'Replace Existing' to overwrite."
        case .invalidFileFormat:
            return "The selected file is not a valid TKDojang backup file."
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud and try again."
        case .unsupportedVersion(let version):
            return "This backup file version (\(version)) is not supported by this app version."
        case .missingRequiredData(let field):
            return "Required data is missing: \(field)"
        }
    }
}