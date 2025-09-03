import Foundation
import SwiftData

/**
 * ProfileService.swift
 * 
 * PURPOSE: Service layer for managing user profiles and profile switching
 * 
 * RESPONSIBILITIES:
 * - Profile creation, editing, deletion
 * - Profile switching and session management
 * - Profile data isolation and migration
 * - Activity tracking across profiles
 * - Profile validation and constraints
 * 
 * DESIGN DECISIONS:
 * - Maximum 6 profiles per device (family-friendly limit)
 * - Automatic profile activation on creation/selection
 * - Graceful handling of profile deletion with data preservation options
 * - Thread-safe profile switching with proper data context management
 */

@Observable
@MainActor
class ProfileService {
    private var modelContext: ModelContext
    private let maxProfiles = 6
    
    // Current active profile (cached for performance)
    // Made internal to ensure proper @Observable triggering
    var activeProfile: UserProfile?
    
    // Export service for automatic backups
    var exportService: ProfileExportService?
    
    // Progress cache service for automatic cache updates
    weak var progressCacheService: ProgressCacheService?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadActiveProfile()
    }
    
    // MARK: - Profile Management
    
    /**
     * Creates a new user profile with validation
     */
    func createProfile(
        name: String,
        avatar: ProfileAvatar = .student1,
        colorTheme: ProfileColorTheme = .blue,
        beltLevel: BeltLevel
    ) throws -> UserProfile {
        // Validate profile count limit
        let existingProfiles = try getAllProfiles()
        guard existingProfiles.count < maxProfiles else {
            throw ProfileError.profileLimitReached(max: maxProfiles)
        }
        
        // Validate name uniqueness
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !existingProfiles.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame }) else {
            throw ProfileError.nameAlreadyExists(name: trimmedName)
        }
        
        // Validate name length
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ProfileError.invalidName("Name cannot be empty")
        }
        
        guard name.count <= 20 else {
            throw ProfileError.invalidName("Name must be 20 characters or less")
        }
        
        // Create profile
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            avatar: avatar,
            colorTheme: colorTheme,
            currentBeltLevel: beltLevel,
            learningMode: .mastery
        )
        
        // Set display order
        profile.profileOrder = existingProfiles.count
        
        // Insert and save
        modelContext.insert(profile)
        try modelContext.save()
        
        // TEMPORARILY DISABLED: Auto-backup to prevent SwiftData crashes during testing
        // exportService?.autoBackupProfile(profile)
        
        // Activate if this is the first profile or if requested
        if existingProfiles.isEmpty {
            try activateProfile(profile)
        }
        
        print("✅ Created profile: \(name) with \(avatar.displayName) avatar")
        return profile
    }
    
    /**
     * Updates an existing profile
     */
    func updateProfile(
        _ profile: UserProfile,
        name: String? = nil,
        avatar: ProfileAvatar? = nil,
        colorTheme: ProfileColorTheme? = nil,
        beltLevel: BeltLevel? = nil,
        learningMode: LearningMode? = nil
    ) throws {
        // Validate name if provided
        if let newName = name {
            let trimmedName = newName.trimmingCharacters(in: .whitespaces)
            guard !trimmedName.isEmpty else {
                throw ProfileError.invalidName("Name cannot be empty")
            }
            
            guard trimmedName.count <= 20 else {
                throw ProfileError.invalidName("Name must be 20 characters or less")
            }
            
            // Check uniqueness (excluding current profile)
            let existingProfiles = try getAllProfiles()
            guard !existingProfiles.contains(where: { 
                $0.id != profile.id && $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
            }) else {
                throw ProfileError.nameAlreadyExists(name: trimmedName)
            }
            
            profile.name = trimmedName
        }
        
        // Update other properties
        if let newAvatar = avatar { profile.avatar = newAvatar }
        if let newColorTheme = colorTheme { profile.colorTheme = newColorTheme }
        if let newBeltLevel = beltLevel { profile.currentBeltLevel = newBeltLevel }
        if let newLearningMode = learningMode { profile.learningMode = newLearningMode }
        
        try modelContext.save()
        
        // TEMPORARILY DISABLED: Auto-backup to prevent SwiftData crashes during testing
        // exportService?.autoBackupProfile(profile)
        
        print("✅ Updated profile: \(profile.name)")
    }
    
    /**
     * Deletes a profile with optional data preservation
     */
    func deleteProfile(_ profile: UserProfile, preserveData: Bool = false) throws {
        let profiles = try getAllProfiles()
        
        // Prevent deletion of last profile
        guard profiles.count > 1 else {
            throw ProfileError.cannotDeleteLastProfile
        }
        
        let wasActive = profile.isActive
        
        // If preserveData is false, SwiftData cascade delete will handle related data
        // If preserveData is true, we could implement data export/backup here
        
        modelContext.delete(profile)
        try modelContext.save()
        
        // If this was the active profile, activate another one
        if wasActive {
            let remainingProfiles = try getAllProfiles()
            if let firstProfile = remainingProfiles.first {
                try activateProfile(firstProfile)
            }
        }
        
        // Reorder remaining profiles
        try reorderProfiles()
        
        print("✅ Deleted profile: \(profile.name)")
    }
    
    /**
     * Activates a profile (switches current user context)
     */
    func activateProfile(_ profile: UserProfile) throws {
        // Deactivate current profile
        if let currentActive = activeProfile {
            currentActive.isActive = false
        }
        
        // Activate new profile
        profile.isActive = true
        profile.recordActivity() // Update last active time
        
        // Update cached active profile
        activeProfile = profile
        
        try modelContext.save()
        
        // Trigger change notifications for UI updates
        Task { @MainActor in
            // Update progress cache if profile changed
            await progressCacheService?.refreshCache(for: profile.id)
        }
        
        // TEMPORARILY DISABLED: Auto-backup to prevent SwiftData crashes during testing
        // exportService?.autoBackupProfile(profile)
        
        print("🔄 Activated profile: \(profile.name)")
    }
    
    // MARK: - Profile Queries
    
    /**
     * Gets all profiles ordered by creation/preference
     */
    func getAllProfiles() throws -> [UserProfile] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.profileOrder)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets the currently active profile
     */
    func getActiveProfile() -> UserProfile? {
        return activeProfile
    }
    
    /**
     * Finds a profile by name
     */
    func getProfile(byName name: String) throws -> UserProfile? {
        let allProfiles = try getAllProfiles()
        return allProfiles.first { profile in
            profile.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }
    
    /**
     * Gets profiles by belt level (for comparative analytics)
     */
    func getProfiles(atBeltLevel beltLevel: BeltLevel) throws -> [UserProfile] {
        let allProfiles = try getAllProfiles()
        return allProfiles.filter { profile in
            profile.currentBeltLevel.id == beltLevel.id
        }
    }
    
    // MARK: - Profile Analytics
    
    /**
     * Gets comprehensive statistics across all profiles
     */
    func getSystemStatistics() throws -> SystemStatistics {
        let allProfiles = try getAllProfiles()
        
        let totalStudyTime = allProfiles.reduce(0) { $0 + $1.totalStudyTime }
        let totalSessions = allProfiles.reduce(0) { $0 + $1.studySessions.count }
        let averageStreak = allProfiles.isEmpty ? 0 : 
            Double(allProfiles.reduce(0) { $0 + $1.streakDays }) / Double(allProfiles.count)
        
        return SystemStatistics(
            totalProfiles: allProfiles.count,
            totalStudyTime: totalStudyTime,
            totalSessions: totalSessions,
            averageStreak: averageStreak,
            mostActiveProfile: allProfiles.max { $0.totalStudyTime < $1.totalStudyTime },
            profileCreationDates: allProfiles.map { $0.createdAt }
        )
    }
    
    /**
     * Records a study session for the active profile
     */
    func recordStudySession(
        sessionType: StudySessionType,
        itemsStudied: Int,
        correctAnswers: Int,
        focusAreas: [String] = []
    ) throws {
        guard let active = activeProfile else {
            throw ProfileError.noActiveProfile
        }
        
        let session = StudySession(userProfile: active, sessionType: sessionType)
        session.complete(
            itemsStudied: itemsStudied,
            correctAnswers: correctAnswers,
            focusAreas: focusAreas
        )
        
        modelContext.insert(session)
        active.recordActivity(studyTime: session.duration)
        
        try modelContext.save()
        
        // TEMPORARILY DISABLED: Auto-backup after study session to prevent SwiftData crashes
        // TODO: Re-enable once SwiftData relationship invalidation issues are resolved
        // exportService?.autoBackupProfile(active)
        
        // FIXED: Re-enabled progress cache refresh after fixing predicate relationship navigation
        Task {
            await progressCacheService?.refreshCache(for: active.id)
        }
        
        print("📊 Recorded \(sessionType.displayName) session for \(active.name)")
    }
    
    // MARK: - Profile Migration and Setup
    
    /**
     * Migrates existing single-user data to first profile
     */
    func migrateExistingData(to profile: UserProfile) throws {
        // This would be called during app upgrade to handle existing user data
        // Implementation would depend on existing data structure
        print("🔄 Migrating existing data to profile: \(profile.name)")
        
        // For now, this is a placeholder for future implementation
        // when we need to handle existing installations
    }
    
    /**
     * Creates default profiles for quick setup
     */
    func createDefaultProfiles(beltLevels: [BeltLevel]) throws {
        guard let whiteBelt = BeltLevel.findStartingBelt(from: beltLevels) else {
            throw ProfileError.invalidBeltLevel
        }
        
        // Create a default profile if none exist
        let existingProfiles = try getAllProfiles()
        if existingProfiles.isEmpty {
            _ = try createProfile(
                name: "Student",
                avatar: .student1,
                colorTheme: .blue,
                beltLevel: whiteBelt
            )
        }
    }
    
    // MARK: - Private Helpers
    
    /**
     * Clears active profile reference for safe database reset
     * CRITICAL: This prevents SwiftData crashes when profiles are deleted
     */
    func clearActiveProfileForReset() {
        print("🔄 Clearing active profile reference for database reset")
        activeProfile = nil
    }
    
    private func loadActiveProfile() {
        do {
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { profile in profile.isActive == true }
            )
            
            activeProfile = try modelContext.fetch(descriptor).first
            
            // If no active profile but profiles exist, activate the first one
            if activeProfile == nil {
                let allProfiles = try getAllProfiles()
                if let firstProfile = allProfiles.first {
                    try activateProfile(firstProfile)
                }
            }
        } catch {
            print("❌ Failed to load active profile: \(error)")
        }
    }
    
    private func reorderProfiles() throws {
        let profiles = try getAllProfiles()
        for (index, profile) in profiles.enumerated() {
            profile.profileOrder = index
        }
        try modelContext.save()
    }
    
    // MARK: - Study Session Analytics
    
    /**
     * Gets study sessions for the active profile
     */
    func getStudySessions() throws -> [StudySession] {
        guard let profile = activeProfile else {
            throw ProfileServiceError.noActiveProfile
        }
        
        return try getStudySessions(for: profile)
    }
    
    /**
     * Gets study sessions for a specific profile
     * 
     * NOTE: This method causes app freezes when accessing profile.studySessions directly
     * SwiftData relationship traversal hangs on main thread - needs investigation
     */
    func getStudySessions(for profile: UserProfile) throws -> [StudySession] {
        // TEMPORARY: Return empty array to prevent freezes
        // TODO: Implement proper SwiftData query without relationship access
        return []
    }
    
    // MARK: - Grading Record Management
    
    /**
     * Records a new grading result for the active profile
     */
    func recordGrading(
        gradingDate: Date,
        beltTested: BeltLevel,
        beltAchieved: BeltLevel,
        gradingType: GradingType = .regular,
        passGrade: PassGrade = .standard,
        examiner: String = "",
        club: String = "",
        notes: String = "",
        preparationTime: TimeInterval = 0,
        passed: Bool = true
    ) throws {
        guard let profile = activeProfile else {
            throw ProfileServiceError.noActiveProfile
        }
        
        let gradingRecord = GradingRecord(
            userProfile: profile,
            gradingDate: gradingDate,
            beltTested: beltTested,
            beltAchieved: beltAchieved,
            gradingType: gradingType,
            passGrade: passGrade,
            examiner: examiner,
            club: club,
            notes: notes,
            preparationTime: preparationTime,
            passed: passed
        )
        
        modelContext.insert(gradingRecord)
        
        // Update profile's current belt level if grading was successful and achieved higher belt
        if passed && beltAchieved.sortOrder < profile.currentBeltLevel.sortOrder {
            profile.currentBeltLevel = beltAchieved
            profile.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    /**
     * Gets all grading records for the active profile
     */
    func getGradingHistory() throws -> [GradingRecord] {
        guard let profile = activeProfile else {
            throw ProfileServiceError.noActiveProfile
        }
        
        return try getGradingHistory(for: profile)
    }
    
    /**
     * Gets grading history for a specific profile
     * 
     * NOTE: This method causes app freezes when accessing profile.gradingHistory directly
     * SwiftData relationship traversal hangs on main thread - needs investigation
     */
    func getGradingHistory(for profile: UserProfile) throws -> [GradingRecord] {
        // TEMPORARY: Return empty array to prevent freezes
        // TODO: Implement proper SwiftData query without relationship access
        return []
    }
    
    /**
     * Updates an existing grading record
     */
    func updateGradingRecord(
        _ record: GradingRecord,
        gradingDate: Date? = nil,
        beltTested: BeltLevel? = nil,
        beltAchieved: BeltLevel? = nil,
        gradingType: GradingType? = nil,
        passGrade: PassGrade? = nil,
        examiner: String? = nil,
        club: String? = nil,
        notes: String? = nil,
        preparationTime: TimeInterval? = nil,
        passed: Bool? = nil
    ) throws {
        record.update(
            gradingDate: gradingDate,
            beltTested: beltTested,
            beltAchieved: beltAchieved,
            gradingType: gradingType,
            passGrade: passGrade,
            examiner: examiner,
            club: club,
            notes: notes,
            preparationTime: preparationTime,
            passed: passed
        )
        
        try modelContext.save()
    }
    
    /**
     * Deletes a grading record
     */
    func deleteGradingRecord(_ record: GradingRecord) throws {
        modelContext.delete(record)
        try modelContext.save()
    }
    
    /**
     * Gets comprehensive grading statistics for the active profile
     */
    func getGradingStatistics() throws -> GradingStatistics {
        guard let profile = activeProfile else {
            throw ProfileServiceError.noActiveProfile
        }
        
        return try getGradingStatistics(for: profile)
    }
    
    /**
     * Gets comprehensive grading statistics for a specific profile
     */
    func getGradingStatistics(for profile: UserProfile) throws -> GradingStatistics {
        let gradingHistory = try getGradingHistory(for: profile)
        
        let totalGradings = gradingHistory.count
        let passedGradings = gradingHistory.filter { $0.passed }.count
        let failedGradings = totalGradings - passedGradings
        let passRate = totalGradings > 0 ? Double(passedGradings) / Double(totalGradings) : 0.0
        
        let averagePreparationTime = totalGradings > 0 ? 
            gradingHistory.reduce(0) { $0 + $1.preparationTime } / Double(totalGradings) : 0
        
        let mostRecentGrading = gradingHistory.first
        
        // Calculate average time between gradings
        var averageTimeBetweenGradings: TimeInterval = 0
        if gradingHistory.count >= 2 {
            let sortedByDate = gradingHistory.sorted { $0.gradingDate < $1.gradingDate }
            var totalInterval: TimeInterval = 0
            for i in 1..<sortedByDate.count {
                totalInterval += sortedByDate[i].gradingDate.timeIntervalSince(sortedByDate[i-1].gradingDate)
            }
            averageTimeBetweenGradings = totalInterval / Double(sortedByDate.count - 1)
        }
        
        // Calculate current belt tenure
        let currentBeltTenure = mostRecentGrading?.gradingDate.timeIntervalSinceNow.magnitude ?? 0
        
        // Group gradings by type and pass grade
        let gradingsByType = Dictionary(grouping: gradingHistory) { $0.gradingType }
            .mapValues { $0.count }
        let gradingsByPassGrade = Dictionary(grouping: gradingHistory) { $0.passGrade }
            .mapValues { $0.count }
        
        // Estimate next grading date (if there's a pattern)
        let nextExpectedGrading: Date?
        if averageTimeBetweenGradings > 0, let lastGrading = mostRecentGrading {
            nextExpectedGrading = lastGrading.gradingDate.addingTimeInterval(averageTimeBetweenGradings)
        } else {
            nextExpectedGrading = nil
        }
        
        return GradingStatistics(
            totalGradings: totalGradings,
            passedGradings: passedGradings,
            failedGradings: failedGradings,
            passRate: passRate,
            averagePreparationTime: averagePreparationTime,
            mostRecentGrading: mostRecentGrading,
            nextExpectedGrading: nextExpectedGrading,
            gradingsByType: gradingsByType,
            gradingsByPassGrade: gradingsByPassGrade,
            averageTimeBetweenGradings: averageTimeBetweenGradings,
            currentBeltTenure: currentBeltTenure
        )
    }
}

// MARK: - Profile Errors

enum ProfileError: LocalizedError {
    case profileLimitReached(max: Int)
    case nameAlreadyExists(name: String)
    case invalidName(String)
    case cannotDeleteLastProfile
    case noActiveProfile
    case invalidBeltLevel
    
    var errorDescription: String? {
        switch self {
        case .profileLimitReached(let max):
            return "Cannot create more than \(max) profiles on this device"
        case .nameAlreadyExists(let name):
            return "A profile with the name '\(name)' already exists"
        case .invalidName(let reason):
            return reason
        case .cannotDeleteLastProfile:
            return "Cannot delete the last remaining profile"
        case .noActiveProfile:
            return "No active profile found"
        case .invalidBeltLevel:
            return "Invalid belt level provided"
        }
    }
}

// MARK: - ProfileService Errors

enum ProfileServiceError: LocalizedError {
    case noActiveProfile
    
    var errorDescription: String? {
        switch self {
        case .noActiveProfile:
            return "No active profile found"
        }
    }
}

// MARK: - Supporting Data Structures

/**
 * System-wide statistics across all profiles
 */
struct SystemStatistics {
    let totalProfiles: Int
    let totalStudyTime: TimeInterval
    let totalSessions: Int
    let averageStreak: Double
    let mostActiveProfile: UserProfile?
    let profileCreationDates: [Date]
    
    var formattedTotalStudyTime: String {
        let hours = Int(totalStudyTime / 3600)
        return "\(hours) hours"
    }
    
    var averageStreakDays: Int {
        return Int(averageStreak.rounded())
    }
}
