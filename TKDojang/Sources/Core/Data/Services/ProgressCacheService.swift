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
        let allBeltLevels = try await getAllBeltLevels()
        let currentProfile = try await getProfile(for: profileId)
        
        // Compute all statistics in memory from simple data
        let stats = computeProgressStats(
            sessions: studySessions,
            terminologyProgress: terminologyProgress,
            patternProgress: patternProgress,
            gradingRecords: gradingRecords,
            allBeltLevels: allBeltLevels,
            currentProfile: currentProfile
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
            beltJourneyStats: stats.beltJourney,
            weeklyData: stats.weeklyData,
            monthlyData: stats.monthlyData
        )
    }
    
    // MARK: - Simple SwiftData Queries
    
    /**
     * Gets study sessions for a profile using in-memory filtering
     * FIXED: No predicate relationship navigation to prevent SwiftData model invalidation
     */
    private func getStudySessions(for profileId: UUID) async throws -> [StudySession] {
        // Fetch all sessions and filter in-memory to avoid predicate relationship navigation
        let descriptor = FetchDescriptor<StudySession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        
        let allSessions = try modelContext.fetch(descriptor)
        return allSessions.filter { session in
            session.userProfile.id == profileId
        }
    }
    
    /**
     * Gets terminology progress using in-memory filtering
     * FIXED: No predicate relationship navigation to prevent SwiftData model invalidation
     */
    private func getTerminologyProgress(for profileId: UUID) async throws -> [UserTerminologyProgress] {
        // Fetch all progress and filter in-memory to avoid predicate relationship navigation
        let descriptor = FetchDescriptor<UserTerminologyProgress>()
        
        let allProgress = try modelContext.fetch(descriptor)
        return allProgress.filter { progress in
            progress.userProfile.id == profileId
        }
    }
    
    /**
     * Gets pattern progress using in-memory filtering
     * FIXED: No predicate relationship navigation to prevent SwiftData model invalidation
     */
    private func getPatternProgress(for profileId: UUID) async throws -> [UserPatternProgress] {
        // Fetch all progress and filter in-memory to avoid predicate relationship navigation
        let descriptor = FetchDescriptor<UserPatternProgress>()
        
        let allProgress = try modelContext.fetch(descriptor)
        return allProgress.filter { progress in
            progress.userProfile.id == profileId
        }
    }
    
    /**
     * Gets grading records using in-memory filtering
     * FIXED: No predicate relationship navigation to prevent SwiftData model invalidation
     */
    private func getGradingRecords(for profileId: UUID) async throws -> [GradingRecord] {
        // Fetch all records and filter in-memory to avoid predicate relationship navigation
        let descriptor = FetchDescriptor<GradingRecord>(
            sortBy: [SortDescriptor(\.gradingDate, order: .reverse)]
        )
        
        let allRecords = try modelContext.fetch(descriptor)
        return allRecords.filter { record in
            record.userProfile.id == profileId
        }
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
    
    /**
     * Gets all belt levels for belt journey computation
     */
    private func getAllBeltLevels() async throws -> [BeltLevel] {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /**
     * Gets a specific profile by ID
     */
    private func getProfile(for profileId: UUID) async throws -> UserProfile? {
        let predicate = #Predicate<UserProfile> { profile in
            profile.id == profileId
        }
        
        let descriptor = FetchDescriptor<UserProfile>(predicate: predicate)
        return try modelContext.fetch(descriptor).first
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
        gradingRecords: [GradingRecord],
        allBeltLevels: [BeltLevel],
        currentProfile: UserProfile?
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
            beltJourney: computeBeltJourneyStats(
                gradingRecords: gradingRecords,
                allBeltLevels: allBeltLevels,
                currentProfile: currentProfile,
                terminologyProgress: terminologyProgress,
                patternProgress: patternProgress,
                sessions: sessions
            ),
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
    
    private func computeBeltJourneyStats(
        gradingRecords: [GradingRecord],
        allBeltLevels: [BeltLevel],
        currentProfile: UserProfile?,
        terminologyProgress: [UserTerminologyProgress],
        patternProgress: [UserPatternProgress],
        sessions: [StudySession]
    ) -> BeltJourneyStats {
        
        // Get profile information
        guard let profile = currentProfile else {
            // Return default/empty belt journey if no profile
            return createEmptyBeltJourney(allBeltLevels: allBeltLevels)
        }
        
        // Studying belt = what the user is learning (from profile)
        let studyingBelt = createBeltInfo(from: profile.currentBeltLevel)
        
        // Current belt = highest belt from successful grading records (or studying belt if no records)
        let currentBelt = determineCurrentBelt(
            gradingRecords: gradingRecords,
            studyingBelt: profile.currentBeltLevel,
            allBeltLevels: allBeltLevels
        )
        
        // Find next belt based on studying belt (not current belt)
        let nextBelt = findNextBelt(currentBelt: profile.currentBeltLevel, allBeltLevels: allBeltLevels)
        
        // Check for belt mismatch and generate message
        let beltMismatch = checkBeltMismatch(
            currentBelt: currentBelt,
            studyingBelt: profile.currentBeltLevel,
            gradingRecords: gradingRecords
        )
        
        // Convert grading records to history entries
        let gradingHistory = gradingRecords.map { record in
            createGradingHistoryEntry(from: record)
        }
        
        // Calculate belt progression summary
        let beltProgression = calculateBeltProgression(
            gradingRecords: gradingRecords,
            currentBelt: currentBelt
        )
        
        // Calculate next belt requirements based on studying belt
        let nextBeltRequirements = nextBelt != nil ? calculateBeltRequirements(
            nextBelt: nextBelt!,
            terminologyProgress: terminologyProgress,
            patternProgress: patternProgress,
            sessions: sessions
        ) : nil
        
        // Calculate time at current belt
        let timeAtCurrentBelt = calculateTimeAtCurrentBelt(
            gradingRecords: gradingRecords,
            currentBelt: currentBelt
        )
        
        // Calculate grading statistics
        let totalGradingsTaken = gradingRecords.count
        let passedGradings = gradingRecords.filter { $0.passed }.count
        let passRate = totalGradingsTaken > 0 ? Double(passedGradings) / Double(totalGradingsTaken) : 0.0
        
        return BeltJourneyStats(
            currentBelt: createBeltInfo(from: currentBelt),
            studyingBelt: studyingBelt,
            nextBelt: nextBelt != nil ? createBeltInfo(from: nextBelt!) : nil,
            gradingHistory: gradingHistory,
            beltProgression: beltProgression,
            nextBeltRequirements: nextBeltRequirements,
            timeAtCurrentBelt: timeAtCurrentBelt,
            totalGradingsTaken: totalGradingsTaken,
            passRate: passRate,
            hasBeltMismatch: beltMismatch.hasMismatch,
            beltMismatchMessage: beltMismatch.message
        )
    }
    
    private func createEmptyBeltJourney(allBeltLevels: [BeltLevel]) -> BeltJourneyStats {
        // Find white belt (10th keup) as default
        let whiteBelt = allBeltLevels.first { $0.shortName.contains("10th Keup") } ?? allBeltLevels.last!
        let currentBelt = createBeltInfo(from: whiteBelt)
        let nextBelt = findNextBelt(currentBelt: whiteBelt, allBeltLevels: allBeltLevels)
        
        return BeltJourneyStats(
            currentBelt: currentBelt,
            studyingBelt: currentBelt,
            nextBelt: nextBelt != nil ? createBeltInfo(from: nextBelt!) : nil,
            gradingHistory: [],
            beltProgression: BeltProgressionSummary(
                totalBeltsEarned: 0,
                averageTimeBetweenGradings: 0,
                firstGradingDate: nil,
                mostRecentGradingDate: nil,
                longestPreparationTime: 0,
                shortestPreparationTime: 0,
                favoriteExaminer: nil,
                mostCommonClub: nil
            ),
            nextBeltRequirements: nil,
            timeAtCurrentBelt: 0,
            totalGradingsTaken: 0,
            passRate: 0.0,
            hasBeltMismatch: false,
            beltMismatchMessage: nil
        )
    }
    
    private func createBeltInfo(from beltLevel: BeltLevel) -> BeltInfo {
        return BeltInfo(
            id: beltLevel.id.uuidString,
            name: beltLevel.name,
            shortName: beltLevel.shortName,
            colorName: beltLevel.colorName,
            sortOrder: beltLevel.sortOrder,
            isKyup: beltLevel.isKyup,
            primaryColor: beltLevel.primaryColor,
            secondaryColor: beltLevel.secondaryColor,
            textColor: beltLevel.textColor,
            borderColor: beltLevel.borderColor
        )
    }
    
    private func findNextBelt(currentBelt: BeltLevel, allBeltLevels: [BeltLevel]) -> BeltLevel? {
        // Next belt has a lower sort order (closer to 1st Dan)
        return allBeltLevels.first { $0.sortOrder == currentBelt.sortOrder - 1 }
    }
    
    private func createGradingHistoryEntry(from record: GradingRecord) -> GradingHistoryEntry {
        return GradingHistoryEntry(
            id: record.id.uuidString,
            gradingDate: record.gradingDate,
            beltTested: createBeltInfo(from: record.beltTested),
            beltAchieved: createBeltInfo(from: record.beltAchieved),
            gradingType: record.gradingType.rawValue,
            passGrade: record.passGrade.rawValue,
            passed: record.passed,
            examiner: record.examiner,
            club: record.club,
            notes: record.notes,
            preparationTime: record.preparationTime
        )
    }
    
    private func calculateBeltProgression(
        gradingRecords: [GradingRecord],
        currentBelt: BeltLevel
    ) -> BeltProgressionSummary {
        
        let passedGradings = gradingRecords.filter { $0.passed }.sorted { $0.gradingDate < $1.gradingDate }
        
        let totalBeltsEarned = passedGradings.count
        let firstGrading = passedGradings.first
        let mostRecent = passedGradings.last
        
        // Calculate average time between gradings
        var averageTime: TimeInterval = 0
        if passedGradings.count >= 2 {
            var totalInterval: TimeInterval = 0
            for i in 1..<passedGradings.count {
                totalInterval += passedGradings[i].gradingDate.timeIntervalSince(passedGradings[i-1].gradingDate)
            }
            averageTime = totalInterval / Double(passedGradings.count - 1)
        }
        
        // Find preparation time ranges
        let preparationTimes = gradingRecords.map { $0.preparationTime }
        let longestPrep = preparationTimes.max() ?? 0
        let shortestPrep = preparationTimes.min() ?? 0
        
        // Find most common examiner and club
        let examiners = gradingRecords.filter { !$0.examiner.isEmpty }.map { $0.examiner }
        let clubs = gradingRecords.filter { !$0.club.isEmpty }.map { $0.club }
        
        let favoriteExaminer = mostFrequent(in: examiners)
        let mostCommonClub = mostFrequent(in: clubs)
        
        return BeltProgressionSummary(
            totalBeltsEarned: totalBeltsEarned,
            averageTimeBetweenGradings: averageTime,
            firstGradingDate: firstGrading?.gradingDate,
            mostRecentGradingDate: mostRecent?.gradingDate,
            longestPreparationTime: longestPrep,
            shortestPreparationTime: shortestPrep,
            favoriteExaminer: favoriteExaminer,
            mostCommonClub: mostCommonClub
        )
    }
    
    private func calculateBeltRequirements(
        nextBelt: BeltLevel,
        terminologyProgress: [UserTerminologyProgress],
        patternProgress: [UserPatternProgress],
        sessions: [StudySession]
    ) -> BeltRequirements {
        
        // Standard requirements (can be customized per belt)
        let terminologyRequired: Double = 0.8 // 80% mastery
        let patternRequired: Double = 1.0 // 100% mastery of required patterns
        let minimumStudyTime: TimeInterval = 20 * 3600 // 20 hours
        
        // SIMPLIFIED: Calculate current progress without relationship navigation
        // This avoids SwiftData model invalidation crashes
        
        // Use simple counts of mastered items to avoid relationship access
        let totalTerminologyMastered = terminologyProgress.filter { $0.masteryLevel == .mastered }.count
        let currentTerminologyMastery = terminologyProgress.isEmpty ? 0.0 : 
            Double(totalTerminologyMastered) / Double(terminologyProgress.count)
        
        let totalPatternsMastered = patternProgress.filter { $0.masteryLevel == PatternMasteryLevel.mastered }.count
        let currentPatternMastery = patternProgress.isEmpty ? 0.0 : 
            Double(totalPatternsMastered) / Double(patternProgress.count)
        
        let currentStudyTime = sessions.reduce(0) { $0 + $1.duration }
        
        // Estimate readiness date based on current progress rate
        let overallProgress = (currentTerminologyMastery / terminologyRequired + 
                              currentPatternMastery / patternRequired + 
                              currentStudyTime / minimumStudyTime) / 3.0
        
        let estimatedReadinessDate: Date?
        if overallProgress > 0 && overallProgress < 1.0 {
            let remainingWork = 1.0 - overallProgress
            let recentActivity = sessions.filter { $0.startTime >= Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date() }
            let monthlyProgressRate = recentActivity.isEmpty ? 0.0 : Double(recentActivity.count) / 30.0
            
            if monthlyProgressRate > 0 {
                let estimatedDaysToCompletion = remainingWork * 30.0 / monthlyProgressRate
                estimatedReadinessDate = Calendar.current.date(byAdding: .day, value: Int(estimatedDaysToCompletion), to: Date())
            } else {
                estimatedReadinessDate = nil
            }
        } else {
            estimatedReadinessDate = overallProgress >= 1.0 ? Date() : nil
        }
        
        return BeltRequirements(
            terminologyMasteryRequired: terminologyRequired,
            patternMasteryRequired: patternRequired,
            minimumStudyTime: minimumStudyTime,
            currentTerminologyMastery: currentTerminologyMastery,
            currentPatternMastery: currentPatternMastery,
            currentStudyTime: currentStudyTime,
            estimatedReadinessDate: estimatedReadinessDate
        )
    }
    
    private func calculateTimeAtCurrentBelt(
        gradingRecords: [GradingRecord],
        currentBelt: BeltLevel
    ) -> TimeInterval {
        // Find the most recent successful grading that resulted in current belt
        let relevantGradings = gradingRecords.filter { 
            $0.passed && $0.beltAchieved.sortOrder == currentBelt.sortOrder 
        }.sorted { $0.gradingDate > $1.gradingDate }
        
        if let mostRecentGrading = relevantGradings.first {
            return Date().timeIntervalSince(mostRecentGrading.gradingDate)
        } else {
            // No grading records for current belt, assume they've had it for a long time
            return 365 * 24 * 3600 // 1 year default
        }
    }
    
    private func mostFrequent<T: Hashable>(in array: [T]) -> T? {
        guard !array.isEmpty else { return nil }
        
        let counts = Dictionary(grouping: array) { $0 }.mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key
    }
    
    private func determineCurrentBelt(
        gradingRecords: [GradingRecord],
        studyingBelt: BeltLevel,
        allBeltLevels: [BeltLevel]
    ) -> BeltLevel {
        // Find the highest belt from successful grading records
        let successfulGradings = gradingRecords.filter { $0.passed }
        
        guard !successfulGradings.isEmpty else {
            // No grading records, current belt = studying belt
            return studyingBelt
        }
        
        // Find the highest belt (lowest sort order) from grading records
        let highestBelt = successfulGradings
            .map { $0.beltAchieved }
            .min { $0.sortOrder < $1.sortOrder }
        
        return highestBelt ?? studyingBelt
    }
    
    private func checkBeltMismatch(
        currentBelt: BeltLevel,
        studyingBelt: BeltLevel,
        gradingRecords: [GradingRecord]
    ) -> (hasMismatch: Bool, message: String?) {
        
        // If they match, no mismatch
        if currentBelt.sortOrder == studyingBelt.sortOrder {
            return (false, nil)
        }
        
        let hasGradingRecords = !gradingRecords.filter { $0.passed }.isEmpty
        
        // Generate appropriate message based on the situation
        let message: String
        
        if !hasGradingRecords {
            // No grading records, so studying belt is the de facto current belt
            return (false, nil)
        } else if currentBelt.sortOrder > studyingBelt.sortOrder {
            // Current belt is lower than studying belt (studying ahead)
            message = "You're studying \(studyingBelt.shortName) content, but your highest graded belt is \(currentBelt.shortName). Consider updating your study level or taking your next grading."
        } else {
            // Current belt is higher than studying belt (reviewing lower content)
            message = "You're reviewing \(studyingBelt.shortName) content while having achieved \(currentBelt.shortName). This is great for reinforcing fundamentals!"
        }
        
        return (true, message)
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
    
    // Belt journey data
    let beltJourneyStats: BeltJourneyStats
    
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
    let beltJourney: BeltJourneyStats
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

// MARK: - Belt Journey Statistics

struct BeltJourneyStats: Codable {
    let currentBelt: BeltInfo              // Highest belt from grading records
    let studyingBelt: BeltInfo             // Belt level they're learning (from profile)
    let nextBelt: BeltInfo?                // Next belt to study for
    let gradingHistory: [GradingHistoryEntry]
    let beltProgression: BeltProgressionSummary
    let nextBeltRequirements: BeltRequirements?
    let timeAtCurrentBelt: TimeInterval
    let totalGradingsTaken: Int
    let passRate: Double
    let hasBeltMismatch: Bool              // True if current != studying belt
    let beltMismatchMessage: String?       // Explanation of the mismatch
}

struct BeltInfo: Codable {
    let id: String
    let name: String
    let shortName: String
    let colorName: String
    let sortOrder: Int
    let isKyup: Bool
    let primaryColor: String?
    let secondaryColor: String?
    let textColor: String?
    let borderColor: String?
}

struct GradingHistoryEntry: Codable {
    let id: String
    let gradingDate: Date
    let beltTested: BeltInfo
    let beltAchieved: BeltInfo
    let gradingType: String
    let passGrade: String
    let passed: Bool
    let examiner: String
    let club: String
    let notes: String
    let preparationTime: TimeInterval
    
    var formattedGradingDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: gradingDate)
    }
    
    var formattedPreparationTime: String {
        let days = Int(preparationTime / (24 * 3600))
        return "\(days) days"
    }
}

struct BeltProgressionSummary: Codable {
    let totalBeltsEarned: Int
    let averageTimeBetweenGradings: TimeInterval
    let firstGradingDate: Date?
    let mostRecentGradingDate: Date?
    let longestPreparationTime: TimeInterval
    let shortestPreparationTime: TimeInterval
    let favoriteExaminer: String?
    let mostCommonClub: String?
    
    var formattedAverageTime: String {
        let months = Int(averageTimeBetweenGradings / (30 * 24 * 3600))
        return "\(months) months"
    }
    
    var totalJourneyTime: TimeInterval {
        guard let first = firstGradingDate, let recent = mostRecentGradingDate else { return 0 }
        return recent.timeIntervalSince(first)
    }
    
    var formattedJourneyTime: String {
        let years = Int(totalJourneyTime / (365 * 24 * 3600))
        let remainingMonths = Int((totalJourneyTime.truncatingRemainder(dividingBy: 365 * 24 * 3600)) / (30 * 24 * 3600))
        
        if years > 0 {
            return remainingMonths > 0 ? "\(years)y \(remainingMonths)m" : "\(years) years"
        } else {
            return "\(remainingMonths) months"
        }
    }
}

struct BeltRequirements: Codable {
    let terminologyMasteryRequired: Double
    let patternMasteryRequired: Double
    let minimumStudyTime: TimeInterval
    let currentTerminologyMastery: Double
    let currentPatternMastery: Double
    let currentStudyTime: TimeInterval
    let estimatedReadinessDate: Date?
    
    var terminologyProgress: Double {
        return min(1.0, currentTerminologyMastery / terminologyMasteryRequired)
    }
    
    var patternProgress: Double {
        return min(1.0, currentPatternMastery / patternMasteryRequired)
    }
    
    var studyTimeProgress: Double {
        return min(1.0, currentStudyTime / minimumStudyTime)
    }
    
    var overallReadiness: Double {
        return (terminologyProgress + patternProgress + studyTimeProgress) / 3.0
    }
    
    var readinessPercentage: Int {
        return Int(overallReadiness * 100)
    }
    
    var isReady: Bool {
        return overallReadiness >= 0.8 // 80% readiness threshold
    }
}