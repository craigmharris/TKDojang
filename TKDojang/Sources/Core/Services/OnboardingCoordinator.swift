import Foundation
import SwiftUI

/**
 * OnboardingCoordinator.swift
 *
 * PURPOSE: Manages onboarding state and tour progression for initial and per-feature tours
 *
 * ARCHITECTURE DECISION: Hybrid state management (device + profile level)
 * WHY:
 * - Initial tour is device-level (@AppStorage) - happens before profile exists
 * - Feature tours are profile-level (UserProfile model) - different users see different tours
 * - This prevents re-showing initial tour after profile switch, while allowing
 *   per-user feature tour tracking for multi-profile households
 *
 * RESPONSIBILITIES:
 * - Track initial tour completion/skip state
 * - Track per-feature tour state for each profile
 * - Provide shouldShow/complete/skip/replay logic
 * - Define tour steps and content
 */

@MainActor
class OnboardingCoordinator: ObservableObject {

    // MARK: - Device-Level State (Initial Tour)

    /// Whether user has seen the initial welcome tour
    /// WHY: Device-level because it happens before any profile exists
    @AppStorage("hasSeenInitialTour") private var hasSeenInitial = false

    /// Date when user skipped the tour (for analytics/debugging)
    @AppStorage("tourSkippedDate") private var tourSkippedDate: TimeInterval = 0

    // MARK: - Current State

    /// Whether the initial tour is currently being shown
    @Published var showingInitialTour = false

    /// Current step in the initial tour (0-indexed)
    @Published var currentTourStep = 0

    /// Total number of steps in the initial tour
    let totalTourSteps = 6

    // MARK: - Feature Tour Types

    /**
     * Enumeration of features that have contextual tours
     *
     * WHY: Only complex features need full tours. Theory/Techniques get simple help sheets.
     */
    enum FeatureTour: String, CaseIterable {
        case flashcards = "flashcards"
        case multipleChoice = "multipleChoice"
        case patterns = "patterns"
        case stepSparring = "stepSparring"
        case patternTest = "patternTest"
        case vocabularyBuilder = "vocabularyBuilder"

        /// Display name for the tour
        var title: String {
            switch self {
            case .flashcards: return "Flashcard Learning"
            case .multipleChoice: return "Multiple Choice Testing"
            case .patterns: return "Pattern Practice"
            case .stepSparring: return "Step Sparring"
            case .patternTest: return "Pattern Test"
            case .vocabularyBuilder: return "Vocabulary Builder"
            }
        }

        /// Short description shown in help buttons
        var description: String {
            switch self {
            case .flashcards:
                return "Learn Taekwondo terminology using spaced repetition flashcards"
            case .multipleChoice:
                return "Test your knowledge with customizable multiple choice quizzes"
            case .patterns:
                return "Practice traditional patterns with step-by-step guidance"
            case .stepSparring:
                return "Master attack, defense, and counter sequences"
            case .patternTest:
                return "Test pattern sequencing and memory recall with interactive move selection"
            case .vocabularyBuilder:
                return "Master Korean phrase grammar through 6 interactive game modes"
            }
        }
    }

    // MARK: - Initial Tour Management

    /**
     * Check if initial tour should be shown
     *
     * Returns true if user has never seen or completed the tour
     */
    func shouldShowInitialTour() -> Bool {
        return !hasSeenInitial
    }

    /**
     * Start the initial tour
     *
     * Sets state to show tour from step 0
     */
    func startInitialTour() {
        showingInitialTour = true
        currentTourStep = 0
        DebugLogger.ui("🎯 Starting initial onboarding tour")
    }

    /**
     * Skip the initial tour
     *
     * WHY: Users should be able to skip and only replay manually
     * Marks as seen so it won't auto-show again
     */
    func skipInitialTour() {
        hasSeenInitial = true
        tourSkippedDate = Date().timeIntervalSince1970
        showingInitialTour = false
        DebugLogger.ui("⏭️ User skipped initial tour")
    }

    /**
     * Complete the initial tour
     *
     * Called when user finishes all steps
     */
    func completeInitialTour() {
        hasSeenInitial = true
        showingInitialTour = false

        // Also mark main onboarding as complete
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")

        DebugLogger.ui("✅ Initial tour completed")
    }

    /**
     * Replay the initial tour
     *
     * WHY: Users can trigger this from Profile screen to see tour again
     * Resets state to show tour from beginning
     */
    func replayInitialTour() {
        hasSeenInitial = false
        showingInitialTour = true
        currentTourStep = 0
        DebugLogger.ui("🔄 Replaying initial tour")
    }

    /**
     * Advance to next tour step
     *
     * Returns false if already on last step
     */
    func nextStep() -> Bool {
        guard currentTourStep < totalTourSteps - 1 else {
            return false
        }
        currentTourStep += 1
        return true
    }

    /**
     * Go to previous tour step
     *
     * Returns false if already on first step
     */
    func previousStep() -> Bool {
        guard currentTourStep > 0 else {
            return false
        }
        currentTourStep -= 1
        return true
    }

    // MARK: - Feature Tour Management

    /**
     * Check if a feature tour should be shown for a profile
     *
     * WHY: Per-profile tracking allows different household members to see
     * tours independently based on their own usage
     *
     * - Parameter feature: The feature to check
     * - Parameter profile: The user profile to check for
     * - Returns: true if this profile hasn't completed this feature tour
     */
    func shouldShowFeatureTour(_ feature: FeatureTour, profile: UserProfile) -> Bool {
        return !profile.completedFeatureTours.contains(feature.rawValue)
    }

    /**
     * Mark a feature tour as complete for a profile
     *
     * WHY: Persists to UserProfile model so state survives app restarts
     * and is tracked per-profile
     *
     * - Parameter feature: The feature tour completed
     * - Parameter profile: The user profile that completed it
     */
    func completeFeatureTour(_ feature: FeatureTour, profile: UserProfile) {
        guard !profile.completedFeatureTours.contains(feature.rawValue) else {
            return // Already completed
        }

        profile.completedFeatureTours.append(feature.rawValue)
        DebugLogger.ui("✅ Feature tour '\(feature.title)' completed for \(profile.name)")
    }

    /**
     * Reset all feature tours for a profile (for testing or user request)
     *
     * WHY: Allows users to re-watch tours if needed
     *
     * - Parameter profile: The profile to reset tours for
     */
    func resetFeatureTours(for profile: UserProfile) {
        profile.completedFeatureTours.removeAll()
        DebugLogger.ui("🔄 Reset all feature tours for \(profile.name)")
    }

    /**
     * Reset a specific feature tour for a profile
     *
     * - Parameter feature: The feature tour to reset
     * - Parameter profile: The profile to reset it for
     */
    func resetFeatureTour(_ feature: FeatureTour, for profile: UserProfile) {
        if let index = profile.completedFeatureTours.firstIndex(of: feature.rawValue) {
            profile.completedFeatureTours.remove(at: index)
            DebugLogger.ui("🔄 Reset '\(feature.title)' tour for \(profile.name)")
        }
    }
}

// MARK: - Tour Step Definition

/**
 * Represents a single step in a tour
 *
 * WHY: Reusable structure for both initial and feature tours
 */
struct TourStep: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let imageName: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        imageName: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.imageName = imageName
        self.action = action
    }
}
