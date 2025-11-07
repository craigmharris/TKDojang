import SwiftUI
import SwiftData

/**
 * MultipleChoiceConfigurationView.swift
 *
 * PURPOSE: Configuration screen for multiple choice tests
 *
 * FEATURES:
 * - Select test type (Quick, Custom, Comprehensive)
 * - Configure question count (Custom only, 10-25 in steps of 5)
 * - Configure belt scope (Current only vs All up to current)
 * - Preview session parameters before starting
 * - Help button with automatic tour display on first visit
 *
 * ARCHITECTURE:
 * - Composes 3 extracted components (TestTypeCard, QuestionCountSlider, BeltScopeToggle)
 * - Components reusable in tours with isDemo parameter
 * - Follows Flashcard configuration pattern for consistency
 */

struct MultipleChoiceConfigurationView: View {
    @EnvironmentObject private var dataServices: DataServices
    @EnvironmentObject private var onboardingCoordinator: OnboardingCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var userProfile: UserProfile?
    @State private var testType: TestType = .quick
    @State private var questionCount: Int = 15
    @State private var beltScope: TestUIConfig.BeltScope = .currentOnly
    @State private var showingTour = false
    @State private var availableQuestionsCount = 0
    @State private var isLoading = true
    @State private var testSession: TestSession?
    @State private var showingTest = false
    @State private var errorMessage: String?

    var body: some View {
        let _ = DebugLogger.ui("🔄 Config.body: Evaluating body - showingTest=\(showingTest), testSession=\(testSession?.id.uuidString ?? "NIL")")
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    configurationHeader

                    if isLoading {
                        loadingView
                    } else {
                        // Configuration Options
                        VStack(spacing: 20) {
                            testTypeSection

                            // Custom test options
                            if testType == .custom {
                                questionCountSection
                                beltScopeSection
                            }

                            // Belt scope for comprehensive test
                            if testType == .comprehensive {
                                beltScopeSection
                            }
                        }

                        // Session Preview
                        sessionPreviewSection

                        // Error message if any
                        if let error = errorMessage {
                            errorMessageView(error)
                        }

                        // Start Button
                        startTestButton
                    }
                }
                .padding()
            }
            .navigationTitle("Test Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTour = true
                    } label: {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("multiplechoice-help-button")
                    .accessibilityLabel("Show multiple choice tour")
                }
            }
            .sheet(isPresented: $showingTour) {
                if let profile = userProfile {
                    FeatureTourView(
                        feature: .multipleChoice,
                        onComplete: {
                            onboardingCoordinator.completeFeatureTour(.multipleChoice, profile: profile)
                            showingTour = false
                        },
                        onSkip: {
                            onboardingCoordinator.completeFeatureTour(.multipleChoice, profile: profile)
                            showingTour = false
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingTest) {
                let _ = DebugLogger.ui("🎭 Config: fullScreenCover triggered - showingTest=\(showingTest), testSession=\(testSession?.id.uuidString ?? "NIL")")
                if let session = testSession {
                    let _ = DebugLogger.ui("✅ Config: testSession EXISTS, creating TestTakingView with sessionID=\(session.id)")
                    TestTakingView(
                        testSession: session,
                        dismissToLearn: {
                            DebugLogger.ui("🏠 Dismissing fullScreenCover and configuration view to return to Learn")
                            showingTest = false  // Dismiss fullScreenCover
                            dismiss()  // Pop MultipleChoiceConfigurationView
                        }
                    )
                    .environmentObject(dataServices)
                    .environmentObject(onboardingCoordinator)
                } else {
                    let _ = DebugLogger.ui("❌ Config: testSession is NIL - cannot show TestTakingView!")
                }
            }
            .task {
                await loadConfiguration()
                checkAndShowTour()
            }
            .onChange(of: testType) { _, _ in
                updateAvailableQuestionsCount()
            }
            .onChange(of: beltScope) { _, _ in
                updateAvailableQuestionsCount()
            }
        }
    }

    // MARK: - Header

    private var configurationHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Configure Your Test")
                .font(.title2)
                .fontWeight(.bold)

            Text("Customize your test settings and start when ready")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading configuration...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
    }

    // MARK: - Test Type Section

    private var testTypeSection: some View {
        ConfigurationSection(
            title: "Test Type",
            icon: "doc.text.fill",
            iconColor: .blue
        ) {
            HStack(spacing: 12) {
                ForEach(TestType.allCases, id: \.rawValue) { type in
                    TestTypeCard(
                        testType: type,
                        isSelected: testType == type,
                        onSelect: { testType = type }
                    )
                }
            }
        }
    }

    // MARK: - Question Count Section

    private var questionCountSection: some View {
        ConfigurationSection(
            title: "Number of Questions",
            icon: "number.circle.fill",
            iconColor: .orange
        ) {
            QuestionCountSlider(
                questionCount: $questionCount,
                availableQuestionsCount: availableQuestionsCount
            )
        }
    }

    // MARK: - Belt Scope Section

    private var beltScopeSection: some View {
        ConfigurationSection(
            title: "Question Belt Levels",
            icon: "figure.martial.arts",
            iconColor: .purple
        ) {
            BeltScopeToggle(beltScope: $beltScope)
        }
    }

    // MARK: - Session Preview

    private var sessionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Test Preview")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                PreviewRow(
                    icon: "doc.text.fill",
                    title: "Test Type",
                    value: testType.displayName,
                    color: testTypeColor
                )

                PreviewRow(
                    icon: "number.circle.fill",
                    title: "Questions",
                    value: previewQuestionCount,
                    color: .orange
                )

                PreviewRow(
                    icon: "figure.martial.arts",
                    title: "Belt Scope",
                    value: beltScope.displayName,
                    color: .purple
                )

                PreviewRow(
                    icon: "info.circle.fill",
                    title: "Available Questions",
                    value: "\(availableQuestionsCount) questions",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Error Message

    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Start Button

    private var startTestButton: some View {
        Button {
            startTest()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start Test")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canStartTest ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canStartTest)
        .accessibilityIdentifier("multiplechoice-start-test-button")
    }

    // MARK: - Computed Properties

    private var testTypeColor: Color {
        switch testType {
        case .quick:
            return .orange
        case .custom:
            return .blue
        case .comprehensive:
            return .green
        }
    }

    private var previewQuestionCount: String {
        switch testType {
        case .quick:
            return "5-10 questions"
        case .custom:
            return "\(questionCount) questions"
        case .comprehensive:
            return "All available (\(availableQuestionsCount))"
        }
    }

    private var canStartTest: Bool {
        return !isLoading && availableQuestionsCount > 0
    }

    // MARK: - Actions

    @MainActor
    private func loadConfiguration() async {
        isLoading = true

        userProfile = dataServices.profileService.getActiveProfile()
        if userProfile == nil {
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }

        if userProfile != nil {
            updateAvailableQuestionsCount()
        }

        isLoading = false
    }

    private func updateAvailableQuestionsCount() {
        guard let profile = userProfile else {
            DebugLogger.data("❌ Config: No user profile available")
            availableQuestionsCount = 0
            return
        }

        // Calculate available questions based on belt scope
        let currentBeltSortOrder = profile.currentBeltLevel.sortOrder
        DebugLogger.data("📊 Config: Counting questions for belt=\(profile.currentBeltLevel.shortName) (sortOrder=\(currentBeltSortOrder)), scope=\(beltScope.rawValue)")

        let descriptor: FetchDescriptor<TerminologyEntry>

        switch beltScope {
        case .currentOnly:
            // Current belt only
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate<TerminologyEntry> { entry in
                    entry.beltLevel.sortOrder == currentBeltSortOrder
                }
            )
            DebugLogger.data("🔍 Config: Using predicate: sortOrder == \(currentBeltSortOrder)")

        case .allUpToCurrent:
            // All belts up to current (inclusive)
            descriptor = FetchDescriptor<TerminologyEntry>(
                predicate: #Predicate<TerminologyEntry> { entry in
                    entry.beltLevel.sortOrder >= currentBeltSortOrder
                }
            )
            DebugLogger.data("🔍 Config: Using predicate: sortOrder >= \(currentBeltSortOrder)")
        }

        do {
            let terms = try dataServices.terminologyService.modelContextForLoading.fetch(descriptor)
            availableQuestionsCount = terms.count
            DebugLogger.data("✅ Config: Found \(availableQuestionsCount) available questions")

            // Adjust question count if it exceeds available
            if testType == .custom && questionCount > availableQuestionsCount && availableQuestionsCount > 0 {
                let oldCount = questionCount
                questionCount = min(questionCount, availableQuestionsCount)
                DebugLogger.data("⚠️ Config: Adjusted question count from \(oldCount) to \(questionCount)")
            }
        } catch {
            DebugLogger.data("❌ Config: Failed to count available questions: \(error)")
            availableQuestionsCount = 0
        }
    }

    private func startTest() {
        DebugLogger.data("🎯 Config: START TEST button pressed - testType=\(testType.rawValue), questionCount=\(questionCount), beltScope=\(beltScope.rawValue)")

        guard let profile = userProfile else {
            errorMessage = "No active profile found"
            DebugLogger.data("❌ Config: No user profile available")
            return
        }

        guard availableQuestionsCount > 0 else {
            errorMessage = "No questions available for selected configuration"
            DebugLogger.data("❌ Config: No questions available (count=\(availableQuestionsCount))")
            return
        }

        errorMessage = nil

        // Create test configuration
        let config = TestUIConfig(
            testType: testType,
            questionCount: testType == .custom ? questionCount : nil,
            beltScope: beltScope
        )
        DebugLogger.data("📝 Config: Created TestUIConfig - type=\(config.testType.rawValue), count=\(config.questionCount ?? 0), scope=\(config.beltScope.rawValue)")

        // Create test session via service
        // CRITICAL: Use dataServices.modelContext (same context as TestTakingView)
        // WHY: SwiftData relationships don't load across different ModelContexts
        let testingService = TestingService(
            modelContext: dataServices.modelContext,
            terminologyService: dataServices.terminologyService
        )
        DebugLogger.data("✅ Config: TestingService created with dataServices.modelContext")

        do {
            let session: TestSession
            DebugLogger.data("🔄 Config: About to create test session for type=\(testType.rawValue)")

            switch testType {
            case .quick:
                DebugLogger.data("⚡ Config: Creating QUICK test for profile=\(profile.name)")
                session = try testingService.createQuickTest(for: profile)

            case .custom:
                DebugLogger.data("🎨 Config: Creating CUSTOM test for profile=\(profile.name), questionCount=\(questionCount), beltScope=\(config.beltScope.rawValue)")
                session = try testingService.createCustomTest(
                    for: profile,
                    questionCount: questionCount,
                    beltScope: config.beltScope
                )

            case .comprehensive:
                DebugLogger.data("📚 Config: Creating COMPREHENSIVE test for profile=\(profile.name), beltScope=\(config.beltScope.rawValue)")
                session = try testingService.createComprehensiveTest(
                    for: profile,
                    beltScope: config.beltScope
                )
            }

            DebugLogger.data("✅ Config: Test session created successfully - sessionID=\(session.id), questionCount=\(session.questions.count)")
            testSession = session
            DebugLogger.data("📝 Config: testSession state variable SET to session with ID=\(session.id)")
            showingTest = true
            DebugLogger.data("🚀 Config: Showing test view (showingTest=\(showingTest), testSession=\(testSession?.id.uuidString ?? "NIL"))")

        } catch {
            errorMessage = "Failed to create test: \(error.localizedDescription)"
            DebugLogger.data("❌ Config: Failed to create test: \(error)")
        }
    }

    /**
     * Check if tour should be shown automatically on first visit
     *
     * WHY: Per-profile tracking ensures each user sees tours independently
     * Only shows once per profile to avoid annoyance
     */
    private func checkAndShowTour() {
        guard let profile = userProfile else { return }

        // Check if this profile has completed the multiple choice tour
        if onboardingCoordinator.shouldShowFeatureTour(.multipleChoice, profile: profile) {
            // Small delay to let the view fully appear first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingTour = true
                DebugLogger.ui("🎯 Automatically showing multiple choice tour for \(profile.name) (first visit)")
            }
        }
    }
}

// MARK: - Preview

#Preview("Configuration View") {
    MultipleChoiceConfigurationView()
}
