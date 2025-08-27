import Foundation
import SwiftData

/**
 * ProgressCacheService.swift
 * 
 * PURPOSE: High-performance progress tracking through intelligent caching
 * 
 * ARCHITECTURE DECISIONS:
 * - Cache-first approach for instant UI performance
 * - Simple SwiftData queries avoid relationship navigation hangs
 * - Background cache updates prevent UI blocking
 * - Extensible structure supports advanced analytics
 * 
 * SOLVES SWIFTDATA ISSUES:
 * - No direct relationship navigation (profile.studySessions)
 * - Simple predicate queries instead of complex joins
 * - Pre-computed aggregations for fast chart rendering
 * - Thread-safe cache updates with MainActor coordination
 */

@Observable
@MainActor
class ProgressCacheService {
    private var modelContext: ModelContext
    private var cache: [UUID: ProgressSnapshot] = [:]
    private var cacheTimestamps: [UUID: Date] = [:]
    private let cacheExpiryInterval: TimeInterval = 300 // 5 minutes
    
    // Cache status tracking
    var isCacheValid: Bool = false
    var isUpdatingCache: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public API
    
    /**
     * Gets progress data for a profile - instant cache retrieval
     */
    func getProgressData(for profileId: UUID) async -> ProgressSnapshot? {
        // Check cache first
        if let cached = cache[profileId], isCacheStillValid(for: profileId) {
            return cached
        }
        
        // Generate fresh cache in background
        return await updateCache(for: profileId)
    }
    
    /**
     * Forces cache refresh for a profile after learning session
     */
    func refreshCache(for profileId: UUID) async {
        await updateCache(for: profileId)
    }
    
    /**
     * Refreshes all profile caches - use sparingly
     */
    func refreshAllCaches() async {
        isUpdatingCache = true
        defer { isUpdatingCache = false }
        
        do {
            let profiles = try await getAllProfileIds()
            await withTaskGroup(of: Void.self) { group in
                for profileId in profiles {
                    group.addTask {
                        await self.updateCache(for: profileId)
                    }
                }
            }
        } catch {
            print("❌ Failed to refresh all caches: \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    private func isCacheStillValid(for profileId: UUID) -> Bool {
        guard let timestamp = cacheTimestamps[profileId] else { return false }
        return Date().timeIntervalSince(timestamp) < cacheExpiryInterval
    }
    
    @discardableResult
    private func updateCache(for profileId: UUID) async -> ProgressSnapshot? {
        do {
            // Use simple queries - NO relationship navigation
            let snapshot = try await generateProgressSnapshot(for: profileId)
            
            // Update cache
            cache[profileId] = snapshot
            cacheTimestamps[profileId] = Date()
            isCacheValid = true
            
            return snapshot
        } catch {
            print("❌ Failed to update cache for profile \(profileId): \(error)")
            return nil
        }
    }
    
    // MARK: - Progress Data Generation
    
    /**
     * Generates comprehensive progress snapshot using simple SwiftData queries
     * CRITICAL: Avoids all relationship navigation to prevent SwiftData hangs
     */
    private func generateProgressSnapshot(for profileId: UUID) async throws -> ProgressSnapshot {
        // Simple individual queries - no joins, no relationship navigation
        let studySessions = try await getStudySessions(for: profileId)
        let terminologyProgress = try await getTerminologyProgress(for: profileId)
        let patternProgress = try await getPatternProgress(for: profileId)
        let gradingRecords = try await getGradingRecords(for: profileId)
        
        // Compute all statistics in memory from simple data
        let stats = computeProgressStats(
            sessions: studySessions,
            terminologyProgress: terminologyProgress,
            patternProgress: patternProgress,
            gradingRecords: gradingRecords
        )
        
        return ProgressSnapshot(
            profileId: profileId,
            generatedAt: Date(),
            overallStats: stats.overall,
            flashcardStats: stats.flashcard,
            testingStats: stats.testing,
            patternStats: stats.pattern,
            streakStats: stats.streak,
            beltProgressStats: stats.beltProgress,
            recentActivity: stats.recentActivity,
            weeklyData: stats.weeklyData,
            monthlyData: stats.monthlyData
        )
    }
    
    // MARK: - Simple SwiftData Queries
    
    /**
     * Gets study sessions for a profile using simple predicate
     * NO relationship navigation - direct query only
     */
    private func getStudySessions(for profileId: UUID) async throws -> [StudySession] {
        let predicate = #Predicate<StudySession> { session in
            session.userProfile.id == profileId
        }
        
        let descriptor = FetchDescriptor<StudySession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets terminology progress using simple query
     */
    private func getTerminologyProgress(for profileId: UUID) async throws -> [UserTerminologyProgress] {
        let predicate = #Predicate<UserTerminologyProgress> { progress in
            progress.userProfile.id == profileId
        }
        
        let descriptor = FetchDescriptor<UserTerminologyProgress>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets pattern progress using simple query
     */
    private func getPatternProgress(for profileId: UUID) async throws -> [UserPatternProgress] {
        let predicate = #Predicate<UserPatternProgress> { progress in
            progress.userProfile.id == profileId
        }
        
        let descriptor = FetchDescriptor<UserPatternProgress>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets grading records using simple query
     */
    private func getGradingRecords(for profileId: UUID) async throws -> [GradingRecord] {
        let predicate = #Predicate<GradingRecord> { record in
            record.userProfile.id == profileId
        }
        
        let descriptor = FetchDescriptor<GradingRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.gradingDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets all profile IDs for cache management
     */
    private func getAllProfileIds() async throws -> [UUID] {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.profileOrder)]
        )
        
        let profiles = try modelContext.fetch(descriptor)
        return profiles.map { $0.id }
    }
    
    // MARK: - Statistics Computation
    
    /**
     * Computes all progress statistics from raw data
     * This is where the magic happens - complex analytics from simple data
     */
    private func computeProgressStats(
        sessions: [StudySession],
        terminologyProgress: [UserTerminologyProgress],
        patternProgress: [UserPatternProgress],
        gradingRecords: [GradingRecord]
    ) -> ProgressStatsCollection {
        
        let now = Date()
        let calendar = Calendar.current
        
        // Time periods for analysis
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        // Filter sessions by time periods
        let recentSessions = sessions.filter { $0.startTime >= weekAgo }
        let monthlySessions = sessions.filter { $0.startTime >= monthAgo }
        
        // Compute statistics
        return ProgressStatsCollection(
            overall: computeOverallStats(sessions: sessions),
            flashcard: computeFlashcardStats(sessions: sessions),
            testing: computeTestingStats(sessions: sessions),
            pattern: computePatternStats(sessions: sessions, patternProgress: patternProgress),
            streak: computeStreakStats(sessions: sessions),
            beltProgress: computeBeltProgressStats(terminologyProgress: terminologyProgress, patternProgress: patternProgress),
            recentActivity: computeRecentActivityStats(recentSessions: recentSessions),
            weeklyData: computeWeeklyData(sessions: recentSessions),
            monthlyData: computeMonthlyData(sessions: monthlySessions)
        )
    }
    
    private func computeOverallStats(sessions: [StudySession]) -> OverallProgressStats {
        let totalTime = sessions.reduce(0) { $0 + $1.duration }
        let totalSessions = sessions.count
        let averageAccuracy = sessions.isEmpty ? 0.0 : 
            sessions.reduce(0) { $0 + $1.accuracy } / Double(sessions.count)
        
        return OverallProgressStats(
            totalStudyTime: totalTime,
            totalSessions: totalSessions,
            averageAccuracy: averageAccuracy,
            totalItemsStudied: sessions.reduce(0) { $0 + $1.itemsStudied }
        )
    }
    
    private func computeFlashcardStats(sessions: [StudySession]) -> FlashcardProgressStats {
        let flashcardSessions = sessions.filter { $0.sessionType == .flashcards }
        let totalCards = flashcardSessions.reduce(0) { $0 + $1.itemsStudied }
        let correctCards = flashcardSessions.reduce(0) { $0 + $1.correctAnswers }
        
        return FlashcardProgressStats(
            totalCardsSeen: totalCards,
            totalCorrect: correctCards,
            averageAccuracy: totalCards > 0 ? Double(correctCards) / Double(totalCards) : 0.0,
            sessionsCompleted: flashcardSessions.count,
            averageSessionTime: flashcardSessions.isEmpty ? 0.0 : 
                flashcardSessions.reduce(0) { $0 + $1.duration } / Double(flashcardSessions.count)
        )
    }
    
    private func computeTestingStats(sessions: [StudySession]) -> TestingProgressStats {
        let testSessions = sessions.filter { $0.sessionType == .testing }
        
        return TestingProgressStats(
            totalTestsTaken: testSessions.count,
            averageScore: testSessions.isEmpty ? 0.0 :
                testSessions.reduce(0) { $0 + $1.accuracy } / Double(testSessions.count),
            totalQuestionsAnswered: testSessions.reduce(0) { $0 + $1.itemsStudied },
            bestScore: testSessions.map { $0.accuracy }.max() ?? 0.0
        )
    }
    
    private func computePatternStats(sessions: [StudySession], patternProgress: [UserPatternProgress]) -> PatternProgressStats {
        let patternSessions = sessions.filter { $0.sessionType == .patterns }
        let masteredPatterns = patternProgress.filter { $0.masteryLevel == .mastered }.count
        
        return PatternProgressStats(
            totalPatternsLearned: masteredPatterns,
            practiceSessionsCompleted: patternSessions.count,
            averagePracticeTime: patternSessions.isEmpty ? 0.0 :
                patternSessions.reduce(0) { $0 + $1.duration } / Double(patternSessions.count)
        )
    }
    
    private func computeStreakStats(sessions: [StudySession]) -> StreakProgressStats {
        // Calculate current streak from session dates
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Group sessions by day
        let sessionsByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        
        let studyDays = Array(sessionsByDay.keys).sorted(by: >)
        
        // Calculate current streak
        var currentStreak = 0
        var checkDate = today
        
        for studyDay in studyDays {
            if studyDay == checkDate {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if studyDay < checkDate {
                // Gap found, break
                break
            }
        }
        
        return StreakProgressStats(
            currentStreak: currentStreak,
            longestStreak: calculateLongestStreak(studyDays: studyDays),
            totalActiveDays: studyDays.count
        )
    }
    
    private func computeBeltProgressStats(terminologyProgress: [UserTerminologyProgress], patternProgress: [UserPatternProgress]) -> BeltProgressStats {
        let masteredTerminology = terminologyProgress.filter { $0.masteryLevel == .mastered }.count
        let totalTerminology = terminologyProgress.count
        
        let masteredPatterns = patternProgress.filter { $0.masteryLevel == .mastered }.count
        let totalPatterns = patternProgress.count
        
        let overallMastery = (totalTerminology + totalPatterns) > 0 ? 
            Double(masteredTerminology + masteredPatterns) / Double(totalTerminology + totalPatterns) : 0.0
        
        return BeltProgressStats(
            terminologyMastery: totalTerminology > 0 ? Double(masteredTerminology) / Double(totalTerminology) : 0.0,
            patternMastery: totalPatterns > 0 ? Double(masteredPatterns) / Double(totalPatterns) : 0.0,
            overallMastery: overallMastery
        )
    }
    
    private func computeRecentActivityStats(recentSessions: [StudySession]) -> RecentActivityStats {
        return RecentActivityStats(
            weeklyStudyTime: recentSessions.reduce(0) { $0 + $1.duration },
            weeklyAccuracy: recentSessions.isEmpty ? 0.0 :
                recentSessions.reduce(0) { $0 + $1.accuracy } / Double(recentSessions.count),
            sessionsThisWeek: recentSessions.count
        )
    }
    
    private func computeWeeklyData(sessions: [StudySession]) -> [DailyProgressData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyProgressData] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let daySessions = sessions.filter { 
                $0.startTime >= dayStart && $0.startTime < dayEnd 
            }
            
            weeklyData.append(DailyProgressData(
                date: date,
                studyTime: daySessions.reduce(0) { $0 + $1.duration },
                sessionsCompleted: daySessions.count,
                averageAccuracy: daySessions.isEmpty ? 0.0 :
                    daySessions.reduce(0) { $0 + $1.accuracy } / Double(daySessions.count)
            ))
        }
        
        return weeklyData.reversed() // Oldest first
    }
    
    private func computeMonthlyData(sessions: [StudySession]) -> [DailyProgressData] {
        let calendar = Calendar.current
        let today = Date()
        var monthlyData: [DailyProgressData] = []
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let daySessions = sessions.filter { 
                $0.startTime >= dayStart && $0.startTime < dayEnd 
            }
            
            monthlyData.append(DailyProgressData(
                date: date,
                studyTime: daySessions.reduce(0) { $0 + $1.duration },
                sessionsCompleted: daySessions.count,
                averageAccuracy: daySessions.isEmpty ? 0.0 :
                    daySessions.reduce(0) { $0 + $1.accuracy } / Double(daySessions.count)
            ))
        }
        
        return monthlyData.reversed() // Oldest first
    }
    
    private func calculateLongestStreak(studyDays: [Date]) -> Int {
        guard !studyDays.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDays = studyDays.sorted()
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDays.count {
            let prevDay = sortedDays[i-1]
            let currentDay = sortedDays[i]
            
            if calendar.dateComponents([.day], from: prevDay, to: currentDay).day == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
}

// MARK: - Data Structures

/**
 * Complete progress snapshot for a profile
 * This structure is optimized for UI consumption and chart rendering
 */
struct ProgressSnapshot: Codable {
    let profileId: UUID
    let generatedAt: Date
    
    // Core statistics
    let overallStats: OverallProgressStats
    let flashcardStats: FlashcardProgressStats
    let testingStats: TestingProgressStats
    let patternStats: PatternProgressStats
    let streakStats: StreakProgressStats
    let beltProgressStats: BeltProgressStats
    let recentActivity: RecentActivityStats
    
    // Time-series data for charts
    let weeklyData: [DailyProgressData]
    let monthlyData: [DailyProgressData]
}

/**
 * Internal collection of all computed statistics
 */
private struct ProgressStatsCollection {
    let overall: OverallProgressStats
    let flashcard: FlashcardProgressStats
    let testing: TestingProgressStats
    let pattern: PatternProgressStats
    let streak: StreakProgressStats
    let beltProgress: BeltProgressStats
    let recentActivity: RecentActivityStats
    let weeklyData: [DailyProgressData]
    let monthlyData: [DailyProgressData]
}

// MARK: - Statistics Structures

struct OverallProgressStats: Codable {
    let totalStudyTime: TimeInterval
    let totalSessions: Int
    let averageAccuracy: Double
    let totalItemsStudied: Int
    
    var formattedStudyTime: String {
        let hours = Int(totalStudyTime / 3600)
        let minutes = Int((totalStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var accuracyPercentage: Int {
        return Int(averageAccuracy * 100)
    }
}

struct FlashcardProgressStats: Codable {
    let totalCardsSeen: Int
    let totalCorrect: Int
    let averageAccuracy: Double
    let sessionsCompleted: Int
    let averageSessionTime: TimeInterval
    
    var accuracyPercentage: Int {
        return Int(averageAccuracy * 100)
    }
    
    var formattedAverageSessionTime: String {
        let minutes = Int(averageSessionTime / 60)
        return "\(minutes)m"
    }
}

struct TestingProgressStats: Codable {
    let totalTestsTaken: Int
    let averageScore: Double
    let totalQuestionsAnswered: Int
    let bestScore: Double
    
    var averageScorePercentage: Int {
        return Int(averageScore * 100)
    }
    
    var bestScorePercentage: Int {
        return Int(bestScore * 100)
    }
}

struct PatternProgressStats: Codable {
    let totalPatternsLearned: Int
    let practiceSessionsCompleted: Int
    let averagePracticeTime: TimeInterval
    
    var formattedAveragePracticeTime: String {
        let minutes = Int(averagePracticeTime / 60)
        return "\(minutes)m"
    }
}

struct StreakProgressStats: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let totalActiveDays: Int
}

struct BeltProgressStats: Codable {
    let terminologyMastery: Double
    let patternMastery: Double
    let overallMastery: Double
    
    var terminologyPercentage: Int {
        return Int(terminologyMastery * 100)
    }
    
    var patternPercentage: Int {
        return Int(patternMastery * 100)
    }
    
    var overallPercentage: Int {
        return Int(overallMastery * 100)
    }
}

struct RecentActivityStats: Codable {
    let weeklyStudyTime: TimeInterval
    let weeklyAccuracy: Double
    let sessionsThisWeek: Int
    
    var formattedWeeklyStudyTime: String {
        let hours = Int(weeklyStudyTime / 3600)
        let minutes = Int((weeklyStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
    
    var weeklyAccuracyPercentage: Int {
        return Int(weeklyAccuracy * 100)
    }
}

struct DailyProgressData: Codable, Equatable {
    let date: Date
    let studyTime: TimeInterval
    let sessionsCompleted: Int
    let averageAccuracy: Double
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Mon, Tue, etc.
        return formatter.string(from: date)
    }
    
    var studyMinutes: Int {
        return Int(studyTime / 60)
    }
    
    var accuracyPercentage: Int {
        return Int(averageAccuracy * 100)
    }
}