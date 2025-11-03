import SwiftUI
import SwiftData

/**
 * OnboardingCoordinatorView.swift
 *
 * PURPOSE: Manages the first-time user experience with interactive 6-step tour
 *
 * ARCHITECTURE DECISION: TabView with page-style navigation
 * WHY: Native iOS pattern that users understand intuitively
 * Swipe gesture feels natural and provides clear progress indication
 *
 * RESPONSIBILITIES:
 * - Guide users through app features
 * - Customize default "Student" profile
 * - Explain learning modes and navigation
 * - Complete onboarding and transition to main app
 */

struct OnboardingCoordinatorView: View {

    @EnvironmentObject var appCoordinator: AppCoordinator
    @EnvironmentObject private var dataServices: DataServices

    @StateObject private var onboardingCoordinator = OnboardingCoordinator()

    @State private var currentStep = 0
    @State private var profileName = "Student"
    @State private var selectedBelt: BeltLevel?
    @State private var selectedLearningMode: LearningMode = .mastery
    @State private var availableBelts: [BeltLevel] = []

    var body: some View {
        ZStack(alignment: .top) {
            // Main Tour Content
            TabView(selection: $currentStep) {
                // Step 1: Welcome
                WelcomeStepView()
                    .tag(0)

                // Step 2: Profile Customization
                ProfileCustomizationStepView(
                    name: $profileName,
                    selectedBelt: $selectedBelt,
                    selectedLearningMode: $selectedLearningMode,
                    availableBelts: availableBelts
                )
                .tag(1)

                // Step 3: Navigation Tabs
                NavigationTabsStepView()
                    .tag(2)

                // Step 4: Practice Features
                PracticeFeaturesStepView()
                    .tag(3)

                // Step 5: Learning Modes
                LearningModesStepView()
                    .tag(4)

                // Step 6: Ready to Start
                ReadyToStartStepView(onComplete: completeOnboarding)
                    .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip Button (visible on steps 0-4)
            if currentStep < 5 {
                HStack {
                    Spacer()

                    Button {
                        skipTour()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(20)
                    }
                    .padding(.trailing)
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            loadBeltLevels()
            onboardingCoordinator.startInitialTour()
        }
    }

    // MARK: - Actions

    /**
     * Complete the onboarding tour
     *
     * WHY: Updates default profile with user's choices, marks onboarding
     * complete, and transitions to main app
     */
    private func completeOnboarding() {
        // Update default "Student" profile if it exists
        updateDefaultProfile()

        // Mark onboarding complete
        onboardingCoordinator.completeInitialTour()

        // Transition to main app
        appCoordinator.showMainFlow()

        DebugLogger.ui("✅ Onboarding completed successfully")
    }

    /**
     * Skip the tour
     *
     * WHY: Users should be able to skip if they prefer
     * Marks as seen so it won't auto-show again
     */
    private func skipTour() {
        onboardingCoordinator.skipInitialTour()
        appCoordinator.showMainFlow()
        DebugLogger.ui("⏭️ User skipped onboarding tour")
    }

    /**
     * Update default profile with user's customizations
     *
     * WHY: Personalizes the automatically-created "Student" profile
     * with user's chosen name, belt, and learning mode
     */
    private func updateDefaultProfile() {
        let profileService = dataServices.profileService

        do {
            let profiles = try profileService.getAllProfiles()

            // Find the default "Student" profile or the first profile
            if let studentProfile = profiles.first(where: { $0.name == "Student" }) ?? profiles.first {
                // Update with user's choices
                try profileService.updateProfile(
                    studentProfile,
                    name: profileName.isEmpty ? "Student" : profileName,
                    beltLevel: selectedBelt ?? studentProfile.currentBeltLevel,
                    learningMode: selectedLearningMode
                )

                DebugLogger.ui("✅ Updated profile: \(studentProfile.name) → \(profileName)")
            }
        } catch {
            DebugLogger.ui("❌ Failed to update default profile: \(error)")
        }
    }

    /**
     * Load available belt levels from database
     *
     * WHY: Needed for belt selection picker in profile customization
     */
    private func loadBeltLevels() {
        let modelContext = dataServices.modelContext
        let allBelts = BeltUtils.fetchAllBeltLevels(from: modelContext)

        availableBelts = allBelts

        // Set default selection to white belt (10th keup)
        if selectedBelt == nil {
            selectedBelt = BeltLevel.findStartingBelt(from: allBelts)
        }
    }
}

// MARK: - Preview

struct OnboardingCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCoordinatorView()
            .environmentObject(AppCoordinator.previewOnboarding)
            .environmentObject(DataServices.shared)
    }
}