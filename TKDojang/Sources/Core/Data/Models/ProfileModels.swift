import Foundation
import SwiftData

/**
 * ProfileModels.swift
 * 
 * PURPOSE: Multi-profile system for family-friendly device sharing
 * 
 * DESIGN DECISIONS:
 * - Device-local only (no cloud storage for privacy)
 * - Up to 6 profiles per device for families
 * - Child-friendly avatars and themes
 * - Complete data isolation between profiles
 * - Seamless switching without data loss
 */

// MARK: - User Profile

/**
 * Represents an individual user profile on the device
 * Each profile maintains separate progress across all learning systems
 */
@Model
final class UserProfile {
    var id: UUID = UUID() // Default to new UUID
    var name: String = "User" // Default name
    var avatar: ProfileAvatar = ProfileAvatar.student1 // Default avatar
    var colorTheme: ProfileColorTheme = ProfileColorTheme.blue // Default theme
    var currentBeltLevel: BeltLevel // Required belt level
    var learningMode: LearningMode = LearningMode.progression // Default learning mode
    var isActive: Bool = false // Currently selected profile
    
    // Profile metadata
    var createdAt: Date = Date() // Default to current date
    var lastActiveAt: Date = Date() // Default to current date
    var updatedAt: Date = Date() // Default to current date
    var totalStudyTime: TimeInterval = 0 // Default to zero
    var profileOrder: Int = 0 // Default to zero
    
    // User preferences (for backward compatibility)
    var dailyStudyGoal: Int = 20 // Default to 20
    
    // Profile statistics (computed from related data)
    var streakDays: Int = 0 // Default to zero
    var totalFlashcardsSeen: Int = 0 // Default to zero
    var totalTestsTaken: Int = 0 // Default to zero
    var totalPatternsLearned: Int = 0 // Default to zero

    // Onboarding state (per-profile tour completion)
    // WHY: Track which feature tours this profile has seen for household sharing
    // Initial tour is device-level (@AppStorage), but feature tours are per-profile
    var hasCompletedInitialTour: Bool = false
    var completedFeatureTours: [String] = [] // ["flashcards", "multipleChoice", "patterns", "stepSparring"]

    // Relationships (one-to-many)
    @Relationship(deleteRule: .cascade, inverse: \UserTerminologyProgress.userProfile)
    var terminologyProgress: [UserTerminologyProgress] = []
    
    @Relationship(deleteRule: .cascade, inverse: \UserPatternProgress.userProfile)  
    var patternProgress: [UserPatternProgress] = []
    
    // TestSession relationship ready for future multi-profile testing architecture
    // @Relationship(deleteRule: .cascade, inverse: \TestSession.userProfile)
    // var testSessions: [TestSession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \StudySession.userProfile)
    var studySessions: [StudySession] = []
    
    @Relationship(deleteRule: .cascade, inverse: \UserStepSparringProgress.userProfile)
    var stepSparringProgress: [UserStepSparringProgress] = []
    
    @Relationship(deleteRule: .cascade, inverse: \GradingRecord.userProfile)
    var gradingHistory: [GradingRecord] = []
    
    init(
        name: String,
        avatar: ProfileAvatar = .student1,
        colorTheme: ProfileColorTheme = .blue,
        currentBeltLevel: BeltLevel,
        learningMode: LearningMode = .mastery
    ) {
        self.id = UUID()
        self.name = name
        self.avatar = avatar
        self.colorTheme = colorTheme
        self.currentBeltLevel = currentBeltLevel
        self.learningMode = learningMode
        self.isActive = false
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.updatedAt = Date()
        self.totalStudyTime = 0
        self.profileOrder = 0
        self.dailyStudyGoal = 20
        self.streakDays = 0
        self.totalFlashcardsSeen = 0
        self.totalTestsTaken = 0
        self.totalPatternsLearned = 0
    }
    
    /**
     * Updates profile activity and statistics
     */
    func recordActivity(studyTime: TimeInterval = 0) {
        lastActiveAt = Date()
        updatedAt = Date()
        totalStudyTime += studyTime
        updateStreakDays(withStudyTime: studyTime)
    }

    /**
     * Calculates current streak based on daily activity
     *
     * WHY: Distinguishes between profile activation (studyTime = 0) and real study (studyTime > 0)
     * BEHAVIOR: Only increments streak when actual study activity occurs
     */
    private func updateStreakDays(withStudyTime studyTime: TimeInterval) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActiveAt)

        // SPECIAL CASE: First real activity after profile creation
        // WHY: Profile creation auto-activates and calls recordActivity() with studyTime=0
        // We only want to start streak on ACTUAL study activity (studyTime > 0)
        if streakDays == 0 {
            // Only increment streak if this is real study activity, not just activation
            if studyTime > 0 {
                streakDays = 1
            }
            return
        }

        let daysSinceActive = calendar.dateComponents([.day], from: lastActive, to: today).day ?? 0

        if daysSinceActive <= 1 {
            // Active today or yesterday, maintain/increment streak
            if daysSinceActive == 0 && calendar.isDate(lastActiveAt, inSameDayAs: Date()) {
                // Already updated today, don't increment
                return
            } else {
                streakDays += 1
            }
        } else {
            // Gap in activity, reset streak
            streakDays = 1
        }
    }
}

// MARK: - Study Session Tracking

/**
 * Tracks individual study sessions for detailed analytics
 */
@Model
final class StudySession {
    var id: UUID
    var userProfile: UserProfile
    var sessionType: StudySessionType
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval
    
    // Session metrics
    var itemsStudied: Int
    var correctAnswers: Int
    var accuracy: Double
    var focusAreas: String // Comma-separated for SwiftData compatibility
    
    // Metadata
    var createdAt: Date
    
    init(userProfile: UserProfile, sessionType: StudySessionType) {
        self.id = UUID()
        self.userProfile = userProfile
        self.sessionType = sessionType
        self.startTime = Date()
        self.duration = 0
        self.itemsStudied = 0
        self.correctAnswers = 0
        self.accuracy = 0.0
        self.focusAreas = ""
        self.createdAt = Date()
    }
    
    /**
     * Completes the study session with final metrics
     */
    func complete(itemsStudied: Int, correctAnswers: Int, focusAreas: [String] = []) {
        self.endTime = Date()
        self.duration = endTime?.timeIntervalSince(startTime) ?? 0
        self.itemsStudied = itemsStudied
        self.correctAnswers = correctAnswers
        self.accuracy = itemsStudied > 0 ? Double(correctAnswers) / Double(itemsStudied) : 0.0
        self.focusAreas = focusAreas.joined(separator: ",")
    }
    
    var focusAreasArray: [String] {
        focusAreas.isEmpty ? [] : focusAreas.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
    }
}

// MARK: - Grading Record

/**
 * Represents an official Taekwondo grading/examination record
 * 
 * PURPOSE: Track actual belt testing results and progression history
 * SUPPORTS: Multiple grading types, elevated passes, historical progression tracking
 */
@Model
final class GradingRecord {
    var id: UUID = UUID()
    var userProfile: UserProfile // Required relationship to profile
    var gradingDate: Date // Date of the grading/examination
    var beltTested: BeltLevel // The belt level being tested for
    var beltAchieved: BeltLevel // The belt actually awarded (may differ for skipped belts)
    var gradingType: GradingType // Regular, skip, retest, etc.
    var passGrade: PassGrade // Standard, A, Plus, Distinction, etc.
    var examiner: String // Name of examining instructor/master
    var club: String // Testing club/dojang name
    var notes: String // Additional notes about the grading
    var preparationTime: TimeInterval // Days of preparation leading up to grading
    var passed: Bool // Whether the grading was successful
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init(
        userProfile: UserProfile,
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
    ) {
        self.id = UUID()
        self.userProfile = userProfile
        self.gradingDate = gradingDate
        self.beltTested = beltTested
        self.beltAchieved = beltAchieved
        self.gradingType = gradingType
        self.passGrade = passGrade
        self.examiner = examiner
        self.club = club
        self.notes = notes
        self.preparationTime = preparationTime
        self.passed = passed
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /**
     * Updates the grading record information
     */
    func update(
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
    ) {
        if let gradingDate = gradingDate { self.gradingDate = gradingDate }
        if let beltTested = beltTested { self.beltTested = beltTested }
        if let beltAchieved = beltAchieved { self.beltAchieved = beltAchieved }
        if let gradingType = gradingType { self.gradingType = gradingType }
        if let passGrade = passGrade { self.passGrade = passGrade }
        if let examiner = examiner { self.examiner = examiner }
        if let club = club { self.club = club }
        if let notes = notes { self.notes = notes }
        if let preparationTime = preparationTime { self.preparationTime = preparationTime }
        if let passed = passed { self.passed = passed }
        self.updatedAt = Date()
    }
}

/**
 * Types of Taekwondo gradings
 */
enum GradingType: String, CaseIterable, Codable {
    case regular = "regular"           // Standard belt progression
    case skip = "skip"                 // Skipping a belt level
    case retest = "retest"            // Retaking a failed grading
    case honorary = "honorary"         // Honorary promotion
    case transfer = "transfer"         // Transfer from another organization
    
    var displayName: String {
        switch self {
        case .regular: return "Regular Grading"
        case .skip: return "Skip Grading"
        case .retest: return "Retest"
        case .honorary: return "Honorary Promotion"
        case .transfer: return "Transfer"
        }
    }
    
    var description: String {
        switch self {
        case .regular: return "Standard progression to next belt level"
        case .skip: return "Advanced promotion skipping one belt level"
        case .retest: return "Retaking a previously failed grading"
        case .honorary: return "Honorary promotion without formal testing"
        case .transfer: return "Belt recognition from another martial arts organization"
        }
    }
}

/**
 * Grading pass grades and distinctions
 */
enum PassGrade: String, CaseIterable, Codable {
    case fail = "fail"
    case standard = "standard"         // Basic pass
    case a = "a"                      // A grade pass (high performance)
    case plus = "plus"                // Plus pass (exceptional performance)
    case distinction = "distinction"   // Distinction (outstanding performance)
    
    var displayName: String {
        switch self {
        case .fail: return "Fail"
        case .standard: return "Pass"
        case .a: return "A Grade"
        case .plus: return "Plus"
        case .distinction: return "Distinction"
        }
    }
    
    var description: String {
        switch self {
        case .fail: return "Did not meet requirements for belt advancement"
        case .standard: return "Met all requirements for belt advancement"
        case .a: return "High performance demonstrating excellent technique and knowledge"
        case .plus: return "Exceptional performance showing advanced skills and understanding"
        case .distinction: return "Outstanding performance demonstrating mastery beyond belt requirements"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .fail: return 0
        case .standard: return 1
        case .a: return 2
        case .plus: return 3
        case .distinction: return 4
        }
    }
}

// MARK: - Grading Statistics

/**
 * Summary statistics for grading history
 */
struct GradingStatistics {
    let totalGradings: Int
    let passedGradings: Int
    let failedGradings: Int
    let passRate: Double
    let averagePreparationTime: TimeInterval
    let mostRecentGrading: GradingRecord?
    let nextExpectedGrading: Date?
    let gradingsByType: [GradingType: Int]
    let gradingsByPassGrade: [PassGrade: Int]
    let averageTimeBetweenGradings: TimeInterval
    let currentBeltTenure: TimeInterval // Time since last successful grading
}

// MARK: - Profile Configuration Enums

/**
 * Available avatar options for profiles
 */
enum ProfileAvatar: String, CaseIterable, Codable {
    case student1 = "figure.martial.arts"
    case student2 = "figure.kickboxing"
    case instructor = "figure.boxing"
    case master = "figure.mind.and.body"
    case ninja = "figure.fencing"
    case champion = "trophy.fill"
    
    // Legacy case for backwards compatibility (not included in allCases)
    case ninjaLegacy = "person.fill.questionmark"
    
    // Custom allCases to exclude legacy cases
    static var allCases: [ProfileAvatar] {
        return [.student1, .student2, .instructor, .master, .ninja, .champion]
    }
    
    // Custom initializer to handle legacy values
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Handle legacy ninja icon
        if rawValue == "person.fill.questionmark" {
            self = .ninja // Convert legacy to new ninja icon
        } else if let avatar = ProfileAvatar(rawValue: rawValue) {
            self = avatar
        } else {
            // Fallback to student1 if unknown value
            self = .student1
        }
    }
    
    // Custom encoder to always use current values
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        // Never encode the legacy value, always use current rawValue
        let valueToEncode = (self == .ninjaLegacy) ? ProfileAvatar.ninja.rawValue : self.rawValue
        try container.encode(valueToEncode)
    }
    
    var displayName: String {
        switch self {
        case .student1: return "Student"
        case .student2: return "Practitioner"
        case .instructor: return "Instructor"
        case .master: return "Master"
        case .ninja, .ninjaLegacy: return "Ninja"
        case .champion: return "Champion"
        }
    }
    
    var description: String {
        switch self {
        case .student1: return "Perfect for beginners"
        case .student2: return "For dedicated learners"
        case .instructor: return "Teaching and guiding"
        case .master: return "Wisdom and experience"
        case .ninja, .ninjaLegacy: return "Stealth and precision"
        case .champion: return "Victory and achievement"
        }
    }
}

/**
 * Color themes for profile personalization
 */
enum ProfileColorTheme: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case red = "red"
    case orange = "orange"
    case purple = "purple"
    case pink = "pink"
    
    var displayName: String {
        switch self {
        case .blue: return "Ocean Blue"
        case .green: return "Forest Green"
        case .red: return "Crimson Red"
        case .orange: return "Sunset Orange"
        case .purple: return "Royal Purple"
        case .pink: return "Cherry Blossom"
        }
    }
    
    var primaryColor: String {
        return rawValue
    }
    
    var secondaryColor: String {
        switch self {
        case .blue: return "lightBlue"
        case .green: return "mint"
        case .red: return "pink"
        case .orange: return "yellow"
        case .purple: return "indigo"
        case .pink: return "purple"
        }
    }
}

/**
 * Types of study sessions for analytics
 */
enum StudySessionType: String, CaseIterable, Codable {
    case flashcards = "flashcards"
    case testing = "testing"
    case patterns = "patterns"
    case step_sparring = "step_sparring"
    case mixed = "mixed"
    
    var displayName: String {
        switch self {
        case .flashcards: return "Flashcard Study"
        case .testing: return "Knowledge Testing"
        case .patterns: return "Pattern Practice"
        case .step_sparring: return "Step Sparring"
        case .mixed: return "Mixed Study"
        }
    }
    
    var icon: String {
        switch self {
        case .flashcards: return "rectangle.on.rectangle"
        case .testing: return "checkmark.circle"
        case .patterns: return "square.grid.3x3"
        case .step_sparring: return "figure.boxing"
        case .mixed: return "star"
        }
    }
}

// MARK: - Extensions

extension UserProfile {
    /**
     * Returns a summary of recent activity for the progress dashboard
     */
    var recentActivity: ProfileActivitySummary {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        // Get recent sessions
        let recentSessions = studySessions.filter { $0.startTime >= sevenDaysAgo }
        let _ = studySessions.filter { $0.startTime >= thirtyDaysAgo }
        
        return ProfileActivitySummary(
            weeklyStudyTime: recentSessions.reduce(0) { $0 + $1.duration },
            weeklyAccuracy: recentSessions.isEmpty ? 0.0 : 
                recentSessions.reduce(0) { $0 + $1.accuracy } / Double(recentSessions.count),
            monthlyTestCount: 0, // Will be implemented with future multi-profile testing system
            currentStreak: streakDays,
            totalStudyHours: totalStudyTime / 3600
        )
    }
    
    /**
     * Checks if profile is eligible for belt advancement
     */
    var isEligibleForAdvancement: Bool {
        // Check terminology mastery for current belt
        let currentBeltProgress = terminologyProgress.filter { 
            $0.terminologyEntry.beltLevel.id == currentBeltLevel.id
        }
        
        let masteredTerms = currentBeltProgress.filter { $0.masteryLevel == .mastered }.count
        let totalTerms = currentBeltProgress.count
        
        // Check pattern mastery (simplified for now - patterns system may not be fully integrated yet)
        let masteredPatterns = patternProgress.filter { $0.masteryLevel == .mastered }.count
        
        // Criteria: 80% terminology mastery + at least 1 mastered pattern
        let terminologyMastery = totalTerms > 0 ? Double(masteredTerms) / Double(totalTerms) : 0.0
        return terminologyMastery >= 0.8 && masteredPatterns >= 1
    }
}

// MARK: - Supporting Data Structures

/**
 * Activity summary for progress dashboard display
 */
struct ProfileActivitySummary {
    let weeklyStudyTime: TimeInterval
    let weeklyAccuracy: Double
    let monthlyTestCount: Int
    let currentStreak: Int
    let totalStudyHours: Double
    
    var formattedWeeklyStudyTime: String {
        let hours = Int(weeklyStudyTime / 3600)
        let minutes = Int((weeklyStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var weeklyAccuracyPercentage: Int {
        return Int(weeklyAccuracy * 100)
    }
}