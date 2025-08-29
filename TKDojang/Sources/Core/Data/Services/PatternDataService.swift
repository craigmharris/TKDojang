import Foundation
import SwiftData

/**
 * PatternDataService.swift
 * 
 * PURPOSE: Service layer for managing pattern database operations
 * 
 * RESPONSIBILITIES:
 * - Pattern CRUD operations
 * - User progress tracking for patterns
 * - Pattern content loading and management
 * - Integration with belt system and user profiles
 */

@Observable
@MainActor
class PatternDataService {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Pattern Management
    
    /**
     * Creates and saves a new pattern to the database
     */
    func createPattern(
        name: String,
        hangul: String,
        englishMeaning: String,
        significance: String,
        moveCount: Int,
        diagramDescription: String,
        startingStance: String,
        videoURL: String? = nil,
        diagramImageURL: String? = nil,
        beltLevels: [BeltLevel] = [],
        moves: [PatternMove] = []
    ) -> Pattern {
        
        let pattern = Pattern(
            name: name,
            hangul: hangul,
            englishMeaning: englishMeaning,
            significance: significance,
            moveCount: moveCount,
            diagramDescription: diagramDescription,
            startingStance: startingStance,
            videoURL: videoURL,
            diagramImageURL: diagramImageURL
        )
        
        pattern.beltLevels = beltLevels
        pattern.moves = moves
        
        // Set pattern relationship for moves
        moves.forEach { move in
            move.pattern = pattern
        }
        
        modelContext.insert(pattern)
        
        do {
            try modelContext.save()
            print("✅ Created pattern: \(name) with \(moves.count) moves")
        } catch {
            print("❌ Failed to save pattern: \(error)")
        }
        
        return pattern
    }
    
    /**
     * Fetches all patterns available to a user based on their belt level
     */
    func getPatternsForUser(userProfile: UserProfile) -> [Pattern] {
        let _ = userProfile.currentBeltLevel.sortOrder
        
        let descriptor = FetchDescriptor<Pattern>()
        
        do {
            let allPatterns = try modelContext.fetch(descriptor)
            
            // Filter patterns appropriate for user's belt level and sort by belt level
            let filteredPatterns = allPatterns.filter { pattern in
                pattern.isAppropriateFor(beltLevel: userProfile.currentBeltLevel)
            }
            
            // Sort by primary belt level (descending sort order = ascending belt progression)
            return filteredPatterns.sorted { pattern1, pattern2 in
                let belt1SortOrder = pattern1.primaryBeltLevel?.sortOrder ?? Int.max
                let belt2SortOrder = pattern2.primaryBeltLevel?.sortOrder ?? Int.max
                return belt1SortOrder > belt2SortOrder // Higher sort order first (9th keup before 8th keup)
            }
        } catch {
            print("Failed to fetch patterns: \(error)")
            return []
        }
    }
    
    /**
     * Fetches a specific pattern by name
     */
    func getPattern(byName name: String) -> Pattern? {
        let descriptor = FetchDescriptor<Pattern>(
            predicate: #Predicate { pattern in
                pattern.name == name
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to fetch pattern '\(name)': \(error)")
            return nil
        }
    }
    
    /**
     * Fetches all patterns for a specific belt level
     */
    func getPatterns(forBeltLevel beltLevel: BeltLevel) -> [Pattern] {
        let descriptor = FetchDescriptor<Pattern>(
            sortBy: [SortDescriptor(\Pattern.name)]
        )
        
        do {
            let allPatterns = try modelContext.fetch(descriptor)
            return allPatterns.filter { pattern in
                pattern.beltLevels.contains { $0.id == beltLevel.id }
            }
        } catch {
            print("Failed to fetch patterns for belt level: \(error)")
            return []
        }
    }
    
    // MARK: - Move Management
    
    /**
     * Adds a move to an existing pattern
     */
    func addMove(
        to pattern: Pattern,
        moveNumber: Int,
        stance: String,
        technique: String,
        direction: String,
        target: String? = nil,
        keyPoints: String,
        commonMistakes: String? = nil,
        executionNotes: String? = nil,
        imageURL: String? = nil
    ) -> PatternMove {
        
        let move = PatternMove(
            moveNumber: moveNumber,
            stance: stance,
            technique: technique,
            direction: direction,
            target: target,
            keyPoints: keyPoints,
            commonMistakes: commonMistakes,
            executionNotes: executionNotes,
            imageURL: imageURL
        )
        
        move.pattern = pattern
        pattern.moves.append(move)
        pattern.updatedAt = Date()
        
        modelContext.insert(move)
        
        do {
            try modelContext.save()
            print("✅ Added move \(moveNumber) to pattern \(pattern.name)")
        } catch {
            print("❌ Failed to save move: \(error)")
        }
        
        return move
    }
    
    // MARK: - User Progress Tracking
    
    /**
     * Gets or creates user progress for a specific pattern
     */
    func getUserProgress(for pattern: Pattern, userProfile: UserProfile) -> UserPatternProgress {
        let profileId = userProfile.id
        let patternId = pattern.id
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && progress.pattern.id == patternId
            }
        )
        
        do {
            if let existingProgress = try modelContext.fetch(descriptor).first {
                return existingProgress
            } else {
                let newProgress = UserPatternProgress(userProfile: userProfile, pattern: pattern)
                modelContext.insert(newProgress)
                try modelContext.save()
                return newProgress
            }
        } catch {
            print("Failed to get user progress: \(error)")
            let newProgress = UserPatternProgress(userProfile: userProfile, pattern: pattern)
            modelContext.insert(newProgress)
            return newProgress
        }
    }
    
    /**
     * Records a practice session for a pattern
     */
    func recordPracticeSession(
        pattern: Pattern,
        userProfile: UserProfile,
        accuracy: Double,
        practiceTime: TimeInterval,
        strugglingMoves: [Int] = []
    ) {
        let progress = getUserProgress(for: pattern, userProfile: userProfile)
        progress.recordPracticeSession(
            accuracy: accuracy,
            practiceTime: practiceTime,
            strugglingMoveNumbers: strugglingMoves
        )
        
        do {
            try modelContext.save()
            print("✅ Recorded practice session for \(pattern.name): \(Int(accuracy * 100))% accuracy")
        } catch {
            print("❌ Failed to save practice session: \(error)")
        }
    }
    
    /**
     * Gets all patterns due for review for a user
     */
    func getPatternsDueForReview(userProfile: UserProfile) -> [UserPatternProgress] {
        let profileId = userProfile.id
        let now = Date()
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId && progress.nextReviewDate <= now
            },
            sortBy: [SortDescriptor(\UserPatternProgress.nextReviewDate)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch patterns due for review: \(error)")
            return []
        }
    }
    
    /**
     * Gets user's pattern learning statistics
     */
    func getUserPatternStatistics(userProfile: UserProfile) -> PatternStatistics {
        let profileId = userProfile.id
        
        let descriptor = FetchDescriptor<UserPatternProgress>(
            predicate: #Predicate { progress in
                progress.userProfile.id == profileId
            }
        )
        
        do {
            let progressEntries = try modelContext.fetch(descriptor)
            
            let totalPatterns = progressEntries.count
            let masteredPatterns = progressEntries.filter { $0.masteryLevel == .mastered }.count
            let totalPracticeTime = progressEntries.reduce(0) { $0 + $1.totalPracticeTime }
            let totalSessions = progressEntries.reduce(0) { $0 + $1.practiceCount }
            let averageAccuracy = totalPatterns > 0 ? 
                progressEntries.reduce(0) { $0 + $1.averageAccuracy } / Double(totalPatterns) : 0.0
            
            return PatternStatistics(
                totalPatterns: totalPatterns,
                masteredPatterns: masteredPatterns,
                totalPracticeTime: totalPracticeTime,
                totalSessions: totalSessions,
                averageAccuracy: averageAccuracy
            )
        } catch {
            print("Failed to fetch pattern statistics: \(error)")
            return PatternStatistics()
        }
    }
    
    // MARK: - Content Loading
    
    /**
     * Development helper: Force reload patterns from JSON (use with caution)
     */
    func forceReloadPatternsFromJSON() {
        print("⚠️ DEVELOPMENT: Force reloading patterns from JSON files...")
        loadPatternsFromJSON()
    }
    
    /**
     * Seeds the database with initial pattern content from JSON files
     */
    func seedInitialPatterns(beltLevels: [BeltLevel]) {
        // Check if patterns already exist
        let descriptor = FetchDescriptor<Pattern>()
        
        do {
            let existingPatterns = try modelContext.fetch(descriptor)
            if !existingPatterns.isEmpty {
                print("📚 Patterns already exist, skipping seeding")
                print("   Found \(existingPatterns.count) existing patterns")
                
                // Debug: Check which patterns have no belt levels (this could be the issue!)
                let patternsWithoutBelts = existingPatterns.filter { $0.beltLevels.isEmpty }
                if !patternsWithoutBelts.isEmpty {
                    print("⚠️ WARNING: \(patternsWithoutBelts.count) patterns have NO belt levels!")
                    print("   Patterns without belts: \(patternsWithoutBelts.map { $0.name })")
                }
                
                let patternsWithBelts = existingPatterns.filter { !$0.beltLevels.isEmpty }
                print("   Patterns with belt levels: \(patternsWithBelts.count)")
                if !patternsWithBelts.isEmpty {
                    print("   Belt levels: \(Array(Set(patternsWithBelts.compactMap { $0.beltLevels.first?.shortName })).sorted())")
                }
                return
            }
        } catch {
            print("Failed to check existing patterns: \(error)")
        }
        
        // Load patterns from JSON files
        loadPatternsFromJSON()
        
        print("✅ Seeded initial patterns from JSON files")
    }
    
    /**
     * Loads all patterns from JSON files using PatternContentLoader
     */
    private func loadPatternsFromJSON() {
        print("🌱 Loading patterns from JSON files...")
        
        let contentLoader = PatternContentLoader(patternService: self)
        
        // Use Task to handle the @MainActor requirement
        Task { @MainActor in
            contentLoader.loadAllContent()
            print("✅ Completed loading patterns from JSON files")
        }
    }
    
    /**
     * Inserts a pattern into the model context
     */
    func insertPattern(_ pattern: Pattern) {
        modelContext.insert(pattern)
        
        // Insert all moves separately to ensure proper relationships
        pattern.moves.forEach { move in
            modelContext.insert(move)
        }
    }
    
    /**
     * Saves the model context
     */
    func saveContext() throws {
        try modelContext.save()
    }
    
    /**
     * Clears all patterns and reloads from JSON
     */
    func clearAndReloadPatterns() {
        // Delete all existing patterns
        do {
            try modelContext.delete(model: Pattern.self)
            try modelContext.delete(model: PatternMove.self)
            try modelContext.save()
            print("🔄 Cleared all patterns from database")
            
            // Reload patterns from JSON
            let loader = PatternContentLoader(patternService: self)
            loader.loadAllContent()
            print("🔄 Reloaded patterns from JSON")
            
        } catch {
            print("❌ Failed to clear and reload patterns: \(error)")
        }
    }
    
    /**
     * Gets all belt levels for pattern association
     */
    func getAllBeltLevels() -> [BeltLevel] {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\BeltLevel.sortOrder, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to fetch belt levels: \(error)")
            return []
        }
    }
    
    // MARK: - Legacy Pattern Creation (Replaced by JSON loading)
    // The following methods are kept for reference but are no longer used
    // All pattern content is now loaded from JSON files via PatternContentLoader
    
    /**
     * Creates the Chon-Ji pattern with full move breakdown
     */
    private func createChonJiPattern(beltLevels: [BeltLevel]) {
        // Find 9th Keup belt level for Chon-Ji
        guard let ninthKeup = beltLevels.first(where: { $0.shortName.contains("9th Keup") }) else {
            print("❌ Could not find 9th Keup belt level for Chon-Ji")
            return
        }
        
        // Create Chon-Ji pattern moves
        let moves = createChonJiMoves()
        
        let _ = createPattern(
            name: "Chon-Ji",
            hangul: "천지",
            englishMeaning: "Heaven and Earth",
            significance: "In the Orient, it is interpreted as the creation of the world or the beginning of human history. Therefore, it is the initial pattern played by the beginner. This pattern consists of two similar parts; one representing Heaven and the other the Earth.",
            moveCount: 19,
            diagramDescription: "Plus sign (+)",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/chon-ji.mp4", // Dummy URL for now
            diagramImageURL: "https://example.com/diagrams/chon-ji-diagram.jpg", // Dummy URL for now
            beltLevels: [ninthKeup],
            moves: moves
        )
        
        print("✅ Created Chon-Ji pattern with \(moves.count) moves")
    }
    
    /**
     * Creates all 19 moves for the Chon-Ji pattern
     */
    private func createChonJiMoves() -> [PatternMove] {
        let movesData: [(Int, String, String, String, String?, String, String?, String?)] = [
            (1, "Left walking stance", "Low block", "West", "Lower section", "Keep shoulders square, bend knees properly", "Lifting block too high", "https://example.com/moves/chon-ji-1.jpg"),
            (2, "Right walking stance", "Middle punch", "West", "Solar plexus", "Twist fist on impact, keep elbow close", "Punching with bent wrist", "https://example.com/moves/chon-ji-2.jpg"),
            (3, "Right walking stance", "Low block", "East", "Lower section", "Mirror image of move 1", "Not turning body fully", "https://example.com/moves/chon-ji-3.jpg"),
            (4, "Left walking stance", "Middle punch", "East", "Solar plexus", "Same technique as move 2", "Incomplete hip rotation", "https://example.com/moves/chon-ji-4.jpg"),
            (5, "Left walking stance", "Low block", "North", "Lower section", "Turn 90 degrees left", "Rushing the turn", "https://example.com/moves/chon-ji-5.jpg"),
            (6, "Right walking stance", "High punch", "North", "Head level", "Step forward with power", "Punching without stepping", "https://example.com/moves/chon-ji-6.jpg"),
            (7, "Right walking stance", "High punch", "North", "Head level", "Continue forward momentum", "Weak follow-through", "https://example.com/moves/chon-ji-7.jpg"),
            (8, "Left walking stance", "High punch", "North", "Head level", "Maintain steady rhythm", "Breaking timing", "https://example.com/moves/chon-ji-8.jpg"),
            (9, "Right walking stance", "High punch", "North", "Head level", "Full extension on punch", "Partial extension", "https://example.com/moves/chon-ji-9.jpg"),
            (10, "Left walking stance", "Low block", "South", "Lower section", "Turn 180 degrees", "Incomplete turn", "https://example.com/moves/chon-ji-10.jpg"),
            (11, "Right walking stance", "High punch", "South", "Head level", "Same as northern sequence", "Inconsistent technique", "https://example.com/moves/chon-ji-11.jpg"),
            (12, "Right walking stance", "High punch", "South", "Head level", "Maintain form under fatigue", "Sloppy technique", "https://example.com/moves/chon-ji-12.jpg"),
            (13, "Left walking stance", "High punch", "South", "Head level", "Keep shoulders level", "Dropping guard", "https://example.com/moves/chon-ji-13.jpg"),
            (14, "Right walking stance", "High punch", "South", "Head level", "Strong finishing sequence", "Weak ending", "https://example.com/moves/chon-ji-14.jpg"),
            (15, "Left walking stance", "Low block", "West", "Lower section", "Turn 90 degrees right", "Losing balance on turn", "https://example.com/moves/chon-ji-15.jpg"),
            (16, "Right walking stance", "Middle punch", "West", "Solar plexus", "Return to middle level", "Wrong target level", "https://example.com/moves/chon-ji-16.jpg"),
            (17, "Right walking stance", "Low block", "East", "Lower section", "Final direction change", "Anticipating finish", "https://example.com/moves/chon-ji-17.jpg"),
            (18, "Left walking stance", "Middle punch", "East", "Solar plexus", "Maintain power to end", "Relaxing too early", "https://example.com/moves/chon-ji-18.jpg"),
            (19, "Parallel ready stance", "Return to ready", "North", nil, "Sharp return to attention", "Sloppy return", "https://example.com/moves/chon-ji-19.jpg")
        ]
        
        return movesData.map { (moveNumber, stance, technique, direction, target, keyPoints, commonMistakes, imageURL) in
            PatternMove(
                moveNumber: moveNumber,
                stance: stance,
                technique: technique,
                direction: direction,
                target: target,
                keyPoints: keyPoints,
                commonMistakes: commonMistakes,
                executionNotes: nil,
                imageURL: imageURL
            )
        }
    }
    
    /**
     * Creates basic moves for Dan-Gun pattern (placeholder implementation)
     */
    private func createDanGunMoves() -> [PatternMove] {
        let movesData: [(Int, String, String, String, String?, String, String?, String?)] = [
            (1, "Left walking stance", "High block", "West", "Upper section", "Keep elbows in correct position", "Block too low", "https://example.com/moves/dan-gun-1.jpg"),
            (2, "Right walking stance", "High punch", "West", "Head level", "Full hip rotation", "Weak follow-through", "https://example.com/moves/dan-gun-2.jpg"),
            (3, "Right walking stance", "High block", "East", "Upper section", "Mirror first movement", "Inconsistent form", "https://example.com/moves/dan-gun-3.jpg"),
            (4, "Left walking stance", "High punch", "East", "Head level", "Maintain power", "Dropping guard", "https://example.com/moves/dan-gun-4.jpg"),
            (5, "Left walking stance", "Twin forearm block", "North", "Middle section", "Both arms move together", "Uneven arm position", "https://example.com/moves/dan-gun-5.jpg"),
            (6, "Right walking stance", "High punch", "North", "Head level", "Step with conviction", "Hesitant movement", "https://example.com/moves/dan-gun-6.jpg"),
            (7, "Right walking stance", "High punch", "North", "Head level", "Continue momentum", "Breaking rhythm", "https://example.com/moves/dan-gun-7.jpg"),
            (8, "Left walking stance", "High punch", "North", "Head level", "Consistent technique", "Rushing moves", "https://example.com/moves/dan-gun-8.jpg"),
            (9, "Right walking stance", "High punch", "North", "Head level", "Strong finish", "Weak ending", "https://example.com/moves/dan-gun-9.jpg"),
            (10, "Left walking stance", "Twin forearm block", "South", "Middle section", "Turn with control", "Sloppy turn", "https://example.com/moves/dan-gun-10.jpg"),
            (11, "Right walking stance", "High punch", "South", "Head level", "Reset technique", "Inconsistent power", "https://example.com/moves/dan-gun-11.jpg"),
            (12, "Right walking stance", "High punch", "South", "Head level", "Maintain form", "Technique breakdown", "https://example.com/moves/dan-gun-12.jpg"),
            (13, "Left walking stance", "High punch", "South", "Head level", "Keep shoulders level", "Uneven stance", "https://example.com/moves/dan-gun-13.jpg"),
            (14, "Right walking stance", "High punch", "South", "Head level", "Finish strong", "Premature relaxation", "https://example.com/moves/dan-gun-14.jpg"),
            (15, "Left walking stance", "High block", "West", "Upper section", "Return to blocking", "Wrong technique", "https://example.com/moves/dan-gun-15.jpg"),
            (16, "Right walking stance", "High punch", "West", "Head level", "Coordinate movement", "Poor timing", "https://example.com/moves/dan-gun-16.jpg"),
            (17, "Right walking stance", "High block", "East", "Upper section", "Final direction change", "Anticipating end", "https://example.com/moves/dan-gun-17.jpg"),
            (18, "Left walking stance", "High punch", "East", "Head level", "Finish with power", "Weak conclusion", "https://example.com/moves/dan-gun-18.jpg"),
            (19, "Left walking stance", "High block", "North", "Upper section", "Prepare for close", "Losing focus", "https://example.com/moves/dan-gun-19.jpg"),
            (20, "Right walking stance", "High punch", "North", "Head level", "Penultimate move", "Rushing to finish", "https://example.com/moves/dan-gun-20.jpg"),
            (21, "Parallel ready stance", "Return to ready", "North", nil, "Sharp return to attention", "Sloppy conclusion", "https://example.com/moves/dan-gun-21.jpg")
        ]
        
        return movesData.map { (moveNumber, stance, technique, direction, target, keyPoints, commonMistakes, imageURL) in
            PatternMove(
                moveNumber: moveNumber,
                stance: stance,
                technique: technique,
                direction: direction,
                target: target,
                keyPoints: keyPoints,
                commonMistakes: commonMistakes,
                executionNotes: nil,
                imageURL: imageURL
            )
        }
    }
    
    /**
     * Creates basic placeholder moves for patterns (for development/testing)
     */
    private func createBasicPatternMoves(count: Int, patternName: String) -> [PatternMove] {
        let stances = ["Left walking stance", "Right walking stance", "Left back stance", "Right back stance"]
        let techniques = ["Low block", "Middle punch", "High punch", "High block", "Knife hand strike", "Front kick"]
        let directions = ["North", "South", "East", "West", "Northeast", "Northwest", "Southeast", "Southwest"]
        let targets = ["Lower section", "Middle section", "Upper section", "Solar plexus", "Head level"]
        
        var moves: [PatternMove] = []
        
        for i in 1...count {
            let stance = stances[(i - 1) % stances.count]
            let technique = techniques[(i - 1) % techniques.count]
            let direction = directions[(i - 1) % directions.count]
            let target = i == count ? nil : targets[(i - 1) % targets.count]
            
            let move = PatternMove(
                moveNumber: i,
                stance: i == count ? "Parallel ready stance" : stance,
                technique: i == count ? "Return to ready" : technique,
                direction: direction,
                target: target,
                keyPoints: "Maintain proper form and technique",
                commonMistakes: "Rushing the movement",
                executionNotes: nil,
                imageURL: "https://example.com/moves/\(patternName.lowercased())-\(i).jpg"
            )
            
            moves.append(move)
        }
        
        return moves
    }
    
    // MARK: - Additional Pattern Creation Functions
    
    private func createDanGunPattern(beltLevels: [BeltLevel]) {
        guard let eighthKeup = beltLevels.first(where: { $0.shortName.contains("8th Keup") }) else {
            print("❌ Could not find 8th Keup belt level for Dan-Gun")
            return
        }
        
        // Create Dan-Gun pattern moves
        let moves = createDanGunMoves()
        
        let _ = createPattern(
            name: "Dan-Gun",
            hangul: "단군",
            englishMeaning: "Holy Dan-Gun",
            significance: "Named after the legendary founder of Korea, Dan-Gun, in the year 2333 B.C. The 21 movements represent the year 2333 B.C.",
            moveCount: 21,
            diagramDescription: "I-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/dan-gun.mp4",
            diagramImageURL: "https://example.com/diagrams/dan-gun-diagram.jpg",
            beltLevels: [eighthKeup],
            moves: moves
        )
        
        print("✅ Created Dan-Gun pattern with \(moves.count) moves")
    }
    
    private func createDoSanPattern(beltLevels: [BeltLevel]) {
        guard let seventhKeup = beltLevels.first(where: { $0.shortName.contains("7th Keup") }) else {
            print("❌ Could not find 7th Keup belt level for Do-San")
            return
        }
        
        // Create placeholder moves for Do-San
        let moves = createBasicPatternMoves(count: 24, patternName: "Do-San")
        
        let _ = createPattern(
            name: "Do-San",
            hangul: "도산",
            englishMeaning: "Island Mountain",
            significance: "Named after the patriot Ahn Chang-Ho (1876-1938) whose pen name was Do-San. He devoted his entire life to furthering the education of Korea and its independence movement. The 24 movements represent his life of 24 years of service to his country.",
            moveCount: 24,
            diagramDescription: "Mountain-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/do-san.mp4",
            diagramImageURL: "https://example.com/diagrams/do-san-diagram.jpg",
            beltLevels: [seventhKeup],
            moves: moves
        )
        
        print("✅ Created Do-San pattern with \(moves.count) moves")
    }
    
    private func createWonHyoPattern(beltLevels: [BeltLevel]) {
        guard let sixthKeup = beltLevels.first(where: { $0.shortName.contains("6th Keup") }) else {
            print("❌ Could not find 6th Keup belt level for Won-Hyo")
            return
        }
        
        let moves = createBasicPatternMoves(count: 28, patternName: "Won-Hyo")
        
        let _ = createPattern(
            name: "Won-Hyo",
            hangul: "원효",
            englishMeaning: "Daybreak",
            significance: "Named after the noted monk Won-Hyo who introduced Buddhism to the Silla Dynasty in the year 686 A.D. The 28 movements refer to his life of 28 years devoted to the propagation of Buddhism.",
            moveCount: 28,
            diagramDescription: "I-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/won-hyo.mp4",
            diagramImageURL: "https://example.com/diagrams/won-hyo-diagram.jpg",
            beltLevels: [sixthKeup],
            moves: moves
        )
        
        print("✅ Created Won-Hyo pattern with \(moves.count) moves")
    }
    
    private func createYulGokPattern(beltLevels: [BeltLevel]) {
        guard let fifthKeup = beltLevels.first(where: { $0.shortName.contains("5th Keup") }) else {
            print("❌ Could not find 5th Keup belt level for Yul-Gok")
            return
        }
        
        let moves = createBasicPatternMoves(count: 38, patternName: "Yul-Gok")
        
        let _ = createPattern(
            name: "Yul-Gok",
            hangul: "율곡",
            englishMeaning: "Chestnut Valley",
            significance: "Named after the great philosopher and scholar Yi I (1536-1584 A.D.) nicknamed the 'Confucius of Korea'. The 38 movements of this pattern refer to his birthplace on the 38th latitude and the diagram represents 'scholar'.",
            moveCount: 38,
            diagramDescription: "Scholar symbol",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/yul-gok.mp4",
            diagramImageURL: "https://example.com/diagrams/yul-gok-diagram.jpg",
            beltLevels: [fifthKeup],
            moves: moves
        )
        
        print("✅ Created Yul-Gok pattern with \(moves.count) moves")
    }
    
    private func createJoongGunPattern(beltLevels: [BeltLevel]) {
        guard let fourthKeup = beltLevels.first(where: { $0.shortName.contains("4th Keup") }) else {
            print("❌ Could not find 4th Keup belt level for Joong-Gun")
            return
        }
        
        let moves = createBasicPatternMoves(count: 32, patternName: "Joong-Gun")
        
        let _ = createPattern(
            name: "Joong-Gun",
            hangul: "중근",
            englishMeaning: "Heavy Roots",
            significance: "Named after the patriot Ahn Joong-Gun who assassinated Hiro-Bumi Ito, the first Japanese governor-general of Korea, known as the man who played the leading part in the Korea-Japan merger. The 32 movements in this pattern represent Mr. Ahn's age when he was executed at Lui-Shung prison in 1910.",
            moveCount: 32,
            diagramDescription: "I-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/joong-gun.mp4",
            diagramImageURL: "https://example.com/diagrams/joong-gun-diagram.jpg",
            beltLevels: [fourthKeup],
            moves: moves
        )
        
        print("✅ Created Joong-Gun pattern with \(moves.count) moves")
    }
    
    private func createToiGyePattern(beltLevels: [BeltLevel]) {
        guard let thirdKeup = beltLevels.first(where: { $0.shortName.contains("3rd Keup") }) else {
            print("❌ Could not find 3rd Keup belt level for Toi-Gye")
            return
        }
        
        let moves = createBasicPatternMoves(count: 37, patternName: "Toi-Gye")
        
        let _ = createPattern(
            name: "Toi-Gye",
            hangul: "퇴계",
            englishMeaning: "Retreating Stream",
            significance: "Named after the noted scholar Yi Hwang (16th century), an authority on neo-Confucianism. The 37 movements of the pattern refer to his birthplace on 37th latitude, the diagram represents 'scholar'.",
            moveCount: 37,
            diagramDescription: "Scholar symbol",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/toi-gye.mp4",
            diagramImageURL: "https://example.com/diagrams/toi-gye-diagram.jpg",
            beltLevels: [thirdKeup],
            moves: moves
        )
        
        print("✅ Created Toi-Gye pattern with \(moves.count) moves")
    }
    
    private func createHwaRangPattern(beltLevels: [BeltLevel]) {
        guard let secondKeup = beltLevels.first(where: { $0.shortName.contains("2nd Keup") }) else {
            print("❌ Could not find 2nd Keup belt level for Hwa-Rang")
            return
        }
        
        let moves = createBasicPatternMoves(count: 29, patternName: "Hwa-Rang")
        
        let _ = createPattern(
            name: "Hwa-Rang",
            hangul: "화랑",
            englishMeaning: "Flowering Youth",
            significance: "Named after the Hwa-Rang youth group which originated in the Silla Dynasty in the early 7th century. The 29 movements refer to the 29th Infantry Division, where Taekwondo developed into maturity.",
            moveCount: 29,
            diagramDescription: "I-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/hwa-rang.mp4",
            diagramImageURL: "https://example.com/diagrams/hwa-rang-diagram.jpg",
            beltLevels: [secondKeup],
            moves: moves
        )
        
        print("✅ Created Hwa-Rang pattern with \(moves.count) moves")
    }
    
    private func createChungMuPattern(beltLevels: [BeltLevel]) {
        guard let firstKeup = beltLevels.first(where: { $0.shortName.contains("1st Keup") }) else {
            print("❌ Could not find 1st Keup belt level for Chung-Mu")
            return
        }
        
        let moves = createBasicPatternMoves(count: 30, patternName: "Chung-Mu")
        
        let _ = createPattern(
            name: "Chung-Mu",
            hangul: "충무",
            englishMeaning: "Martial Loyalty",
            significance: "Named after the late Admiral Yi Sun-Sin of the Lee Dynasty. He was reputed to have invented the first armoured battleship (Kobukson) in 1592, which is said to be the precursor of the present day submarine. The reason why this pattern ends with a left hand attack is to symbolize his regrettable death, having no chance to show his unrestrained potentiality checked by the forced reservation of his loyalty to the king.",
            moveCount: 30,
            diagramDescription: "I-shaped pattern",
            startingStance: "Parallel ready stance",
            videoURL: "https://example.com/patterns/chung-mu.mp4",
            diagramImageURL: "https://example.com/diagrams/chung-mu-diagram.jpg",
            beltLevels: [firstKeup],
            moves: moves
        )
        
        print("✅ Created Chung-Mu pattern with \(moves.count) moves")
    }
}

// MARK: - Supporting Data Structures

/**
 * User pattern learning statistics for display in UI
 */
struct PatternStatistics {
    let totalPatterns: Int
    let masteredPatterns: Int
    let totalPracticeTime: TimeInterval
    let totalSessions: Int
    let averageAccuracy: Double
    
    init(
        totalPatterns: Int = 0,
        masteredPatterns: Int = 0,
        totalPracticeTime: TimeInterval = 0,
        totalSessions: Int = 0,
        averageAccuracy: Double = 0.0
    ) {
        self.totalPatterns = totalPatterns
        self.masteredPatterns = masteredPatterns
        self.totalPracticeTime = totalPracticeTime
        self.totalSessions = totalSessions
        self.averageAccuracy = averageAccuracy
    }
    
    var masteryPercentage: Double {
        guard totalPatterns > 0 else { return 0.0 }
        return Double(masteredPatterns) / Double(totalPatterns) * 100.0
    }
    
    var averageAccuracyPercentage: Int {
        return Int(averageAccuracy * 100)
    }
    
    var formattedPracticeTime: String {
        let hours = Int(totalPracticeTime / 3600)
        let minutes = Int((totalPracticeTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}