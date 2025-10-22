import Foundation
import SwiftData

/**
 * EnhancedTerminologyService.swift
 * 
 * PURPOSE: Advanced terminology selection for improved flashcard sessions
 * 
 * FEATURES:
 * - Smart term selection based on learning mode and belt progression
 * - Card repetition and top-up from prior belts when needed
 * - Respects user profile term count settings
 * - Handles both Classic and Leitner learning systems
 * - Ensures minimum term availability through intelligent fallback
 */

@MainActor
class EnhancedTerminologyService {
    private let terminologyService: TerminologyDataService
    private let leitnerService: LeitnerService
    
    init(terminologyService: TerminologyDataService, leitnerService: LeitnerService) {
        self.terminologyService = terminologyService
        self.leitnerService = leitnerService
    }
    
    /**
     * Gets terms for a flashcard session with enhanced logic
     * 
     * FEATURES:
     * - Progression mode: current belt only
     * - Mastery mode: current + prior belts, limited to 50 terms max
     * - Card repetition when insufficient terms available
     * - Top-up from prior belts when needed
     */
    func getTermsForFlashcardSession(
        userProfile: UserProfile,
        requestedCount: Int,
        learningSystem: LearningSystem
    ) -> [TerminologyEntry] {
        
        DebugLogger.data("🎯 Enhanced: Getting \(requestedCount) terms for \(userProfile.name) in \(userProfile.learningMode) mode")
        
        let terms: [TerminologyEntry]
        
        switch userProfile.learningMode {
        case .progression:
            terms = getProgressionModeTerms(
                userProfile: userProfile,
                requestedCount: requestedCount,
                learningSystem: learningSystem
            )
            
        case .mastery:
            terms = getMasteryModeTerms(
                userProfile: userProfile,
                requestedCount: requestedCount,
                learningSystem: learningSystem
            )
        }
        
        DebugLogger.data("✅ Enhanced: Returning \(terms.count) terms for flashcard session")
        return terms
    }
    
    // MARK: - Progression Mode
    
    /**
     * Progression mode: Focus on current belt only
     * If insufficient terms, allow repetition in different directions
     */
    private func getProgressionModeTerms(
        userProfile: UserProfile,
        requestedCount: Int,
        learningSystem: LearningSystem
    ) -> [TerminologyEntry] {
        
        let currentBeltSortOrder = userProfile.currentBeltLevel.sortOrder
        
        // Get terms for current belt only
        var availableTerms = getCurrentBeltTerms(beltSortOrder: currentBeltSortOrder)
        
        DebugLogger.data("📚 Progression: Found \(availableTerms.count) terms for current belt (\(userProfile.currentBeltLevel.shortName))")
        
        // If we don't have enough terms, we'll allow repetition in different directions
        // This is handled by the FlashcardView itself when creating both directions
        
        // For Leitner mode, filter by due dates if enabled
        if learningSystem == .leitner {
            availableTerms = filterTermsForLeitner(terms: availableTerms, userProfile: userProfile)
            DebugLogger.data("🕐 Leitner: Filtered to \(availableTerms.count) due terms")
        }
        
        // Return up to requested count
        let finalTerms = Array(availableTerms.shuffled().prefix(requestedCount))
        
        // If still insufficient and we have some terms, we'll return what we have
        // The FlashcardView will handle repetition by using both directions
        return finalTerms
    }
    
    // MARK: - Mastery Mode
    
    /**
     * Mastery mode: Current + prior belts, up to 50 terms max
     * Smart selection prioritizing current belt, then prior belts
     */
    private func getMasteryModeTerms(
        userProfile: UserProfile,
        requestedCount: Int,
        learningSystem: LearningSystem
    ) -> [TerminologyEntry] {
        
        let currentBeltSortOrder = userProfile.currentBeltLevel.sortOrder
        let maxTermsForMastery = min(requestedCount, 50) // Cap at 50 for mastery mode
        
        // Get all terms up to and including current belt
        var availableTerms = getAllTermsUpToBelt(beltSortOrder: currentBeltSortOrder)
        
        DebugLogger.data("📚 Mastery: Found \(availableTerms.count) terms up to current belt")
        
        // For Leitner mode, filter by due dates if enabled
        if learningSystem == .leitner {
            let dueTerms = filterTermsForLeitner(terms: availableTerms, userProfile: userProfile)
            if !dueTerms.isEmpty {
                availableTerms = dueTerms
                DebugLogger.data("🕐 Leitner: Filtered to \(availableTerms.count) due terms")
            }
        }
        
        // Smart selection: prioritize current belt, then fill with prior belts
        let finalTerms = smartSelectForMastery(
            terms: availableTerms,
            currentBeltSortOrder: currentBeltSortOrder,
            maxCount: maxTermsForMastery
        )
        
        return finalTerms
    }
    
    // MARK: - Term Selection Helpers
    
    private func getCurrentBeltTerms(beltSortOrder: Int) -> [TerminologyEntry] {
        // ✅ SAFE - "Fetch All → Filter In-Memory" Pattern
        // WHY: Predicate relationship navigation causes SwiftData model invalidation
        let descriptor = FetchDescriptor<TerminologyEntry>(
            sortBy: [SortDescriptor(\.difficulty), SortDescriptor(\.englishTerm)]
        )

        do {
            let allTerms = try terminologyService.modelContextForLoading.fetch(descriptor)
            // Filter in-memory for safety
            let filteredTerms = allTerms.filter { entry in
                entry.beltLevel.sortOrder == beltSortOrder
            }
            return filteredTerms
        } catch {
            DebugLogger.data("❌ Enhanced: Failed to fetch current belt terms: \(error)")
            return []
        }
    }
    
    private func getAllTermsUpToBelt(beltSortOrder: Int) -> [TerminologyEntry] {
        // ✅ SAFE - "Fetch All → Filter In-Memory" Pattern
        // WHY: Predicate relationship navigation causes SwiftData model invalidation
        let descriptor = FetchDescriptor<TerminologyEntry>(
            sortBy: [SortDescriptor(\.difficulty), SortDescriptor(\.englishTerm)]
        )

        do {
            let allTerms = try terminologyService.modelContextForLoading.fetch(descriptor)
            // Filter in-memory for safety
            let filteredTerms = allTerms.filter { entry in
                entry.beltLevel.sortOrder >= beltSortOrder
            }
            // Sort by belt (current first), then difficulty
            let sortedTerms = filteredTerms.sorted { lhs, rhs in
                if lhs.beltLevel.sortOrder != rhs.beltLevel.sortOrder {
                    return lhs.beltLevel.sortOrder < rhs.beltLevel.sortOrder  // Lower sort order (higher belts) first
                }
                if lhs.difficulty != rhs.difficulty {
                    return lhs.difficulty < rhs.difficulty
                }
                return lhs.englishTerm < rhs.englishTerm
            }
            return sortedTerms
        } catch {
            DebugLogger.data("❌ Enhanced: Failed to fetch mastery terms: \(error)")
            return []
        }
    }
    
    private func filterTermsForLeitner(terms: [TerminologyEntry], userProfile: UserProfile) -> [TerminologyEntry] {
        let dueTerms = leitnerService.getTermsForReview(userProfile: userProfile, limit: terms.count)
        let dueTermIds = Set(dueTerms.map { $0.id })
        
        return terms.filter { dueTermIds.contains($0.id) }
    }
    
    /**
     * Smart selection for mastery mode:
     * 1. Prioritize current belt terms (up to 60% of selection)
     * 2. Fill remainder with prior belt terms
     * 3. Ensure good distribution across difficulty levels
     */
    private func smartSelectForMastery(
        terms: [TerminologyEntry],
        currentBeltSortOrder: Int,
        maxCount: Int
    ) -> [TerminologyEntry] {
        
        // Separate current belt from prior belts
        let currentBeltTerms = terms.filter { $0.beltLevel.sortOrder == currentBeltSortOrder }
        let priorBeltTerms = terms.filter { $0.beltLevel.sortOrder > currentBeltSortOrder }
        
        DebugLogger.data("📊 Smart Select: Current belt: \(currentBeltTerms.count), Prior belts: \(priorBeltTerms.count)")
        
        // Calculate distribution
        let currentBeltAllocation = min(currentBeltTerms.count, Int(Double(maxCount) * 0.6)) // 60% for current belt
        let priorBeltAllocation = maxCount - currentBeltAllocation
        
        // Select terms
        let selectedCurrentBelt = Array(currentBeltTerms.shuffled().prefix(currentBeltAllocation))
        let selectedPriorBelt = Array(priorBeltTerms.shuffled().prefix(priorBeltAllocation))
        
        let finalSelection = (selectedCurrentBelt + selectedPriorBelt).shuffled()
        
        DebugLogger.data("✅ Smart Select: Selected \(selectedCurrentBelt.count) current + \(selectedPriorBelt.count) prior = \(finalSelection.count) total")
        
        return finalSelection
    }
    
    // MARK: - Card Repetition Logic
    
    /**
     * Creates repeated cards for both directions when insufficient unique terms
     * This method is called by FlashcardView when needed
     */
    func createRepeatedCardsForBothDirections(
        terms: [TerminologyEntry],
        targetCount: Int
    ) -> [FlashcardItem] {
        
        var flashcardItems: [FlashcardItem] = []
        
        // Create cards in both directions
        for term in terms {
            flashcardItems.append(FlashcardItem(term: term, direction: .englishToKorean))
            flashcardItems.append(FlashcardItem(term: term, direction: .koreanToEnglish))
        }
        
        // If we still need more cards, add additional repetitions
        while flashcardItems.count < targetCount && !terms.isEmpty {
            let additionalTerm = terms.randomElement()!
            let additionalDirection = CardDirection.allCases.filter { $0 != .bothDirections }.randomElement()!
            flashcardItems.append(FlashcardItem(term: additionalTerm, direction: additionalDirection))
        }
        
        // Shuffle and trim to target count
        let finalItems = Array(flashcardItems.shuffled().prefix(targetCount))
        
        DebugLogger.data("🔄 Card Repetition: Created \(finalItems.count) flashcard items from \(terms.count) unique terms")
        
        return finalItems
    }
    
    /**
     * Gets top-up terms from immediately prior belt when current belt has insufficient terms
     */
    func getTopUpTermsFromPriorBelt(
        currentBeltSortOrder: Int,
        needed: Int
    ) -> [TerminologyEntry] {

        // Find the immediately prior belt (higher sortOrder)
        let priorBeltSortOrder = currentBeltSortOrder + 1

        // ✅ SAFE - "Fetch All → Filter In-Memory" Pattern
        // WHY: Predicate relationship navigation causes SwiftData model invalidation
        let descriptor = FetchDescriptor<TerminologyEntry>(
            sortBy: [SortDescriptor(\.difficulty), SortDescriptor(\.englishTerm)]
        )

        do {
            let allTerms = try terminologyService.modelContextForLoading.fetch(descriptor)
            // Filter in-memory for safety
            let priorTerms = allTerms.filter { entry in
                entry.beltLevel.sortOrder == priorBeltSortOrder
            }
            let topUpTerms = Array(priorTerms.shuffled().prefix(needed))

            DebugLogger.data("⬆️ Top-up: Added \(topUpTerms.count) terms from prior belt")

            return topUpTerms
        } catch {
            DebugLogger.data("❌ Enhanced: Failed to fetch top-up terms: \(error)")
            return []
        }
    }
}

// MARK: - Flashcard Item Model

/**
 * Represents a single flashcard with its associated direction
 * Used for managing card repetition and direction handling
 */
struct FlashcardItem: Identifiable {
    let id = UUID()
    let term: TerminologyEntry
    let direction: CardDirection
    
    var isEnglishToKorean: Bool {
        direction == .englishToKorean
    }
    
    var isKoreanToEnglish: Bool {
        direction == .koreanToEnglish
    }
}

// MARK: - Learning System Compatibility

extension LearningSystem {
    var isLeitnerMode: Bool {
        self == .leitner
    }
    
    var isClassicMode: Bool {
        self == .classic
    }
}