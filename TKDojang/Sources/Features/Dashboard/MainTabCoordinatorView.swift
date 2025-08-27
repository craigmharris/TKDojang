import SwiftUI
import SwiftData

/**
 * MainTabCoordinatorView.swift
 * 
 * PURPOSE: Main authenticated user interface with tab-based navigation
 */
struct MainTabCoordinatorView: View {
    
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard/Home Tab
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            // Learn Tab
            LearnView()
                .tabItem {
                    Label("Learn", systemImage: "book.fill")
                }
                .tag(1)
            
            // Practice Tab
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "figure.martial.arts")
                }
                .tag(2)
            
            // Progress Tab - using stub due to SwiftData relationship issues
            ProgressViewStub()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

// MARK: - Placeholder Tab Views

struct DashboardView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var userProfile: UserProfile?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Personalized Welcome Header
                    if let profile = userProfile {
                        PersonalizedWelcomeCard(profile: profile)
                    } else {
                        // Fallback for no profile
                        VStack(spacing: 16) {
                            Image(systemName: "figure.martial.arts")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Welcome to TKDojang")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Your martial arts journey begins here")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                    
                    // Quick Action Navigation Cards
                    QuickActionGrid()
                    
                    // Recent Activity Section (if profile exists)
                    if let profile = userProfile {
                        RecentActivityCard(profile: profile)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher()
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .onChange(of: dataManager.profileService.activeProfile) {
                loadUserProfile()
            }
        }
    }
    
    private func loadUserProfile() {
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, create/get default
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
    }
}

// MARK: - Personalized Welcome Card

struct PersonalizedWelcomeCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Header
            HStack(spacing: 16) {
                // Avatar
                Image(systemName: profile.avatar.rawValue)
                    .font(.system(size: 50))
                    .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                    )
                
                // Welcome Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Belt Level Badge
                    HStack(spacing: 8) {
                        Text(profile.currentBeltLevel.shortName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(profile.colorTheme.primarySwiftUIColor)
                            )
                        
                        if profile.streakDays > 0 {
                            Text("🔥 \(profile.streakDays) day streak")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Progress Summary
            HStack(spacing: 20) {
                ProgressStat(title: "Flashcards", value: profile.totalFlashcardsSeen, color: .blue)
                ProgressStat(title: "Tests Taken", value: profile.totalTestsTaken, color: .green)
                ProgressStat(title: "Patterns", value: profile.totalPatternsLearned, color: .purple)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Progress Stat Component

struct ProgressStat: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Action Grid

struct QuickActionGrid: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                
                QuickActionCard(
                    title: "Learn",
                    subtitle: "Flashcards, Tests & Theory",
                    icon: "book.fill",
                    color: .blue,
                    destination: AnyView(LearnView())
                )
                
                QuickActionCard(
                    title: "Practice",
                    subtitle: "Patterns, Sparring & Line Work",
                    icon: "figure.martial.arts",
                    color: .red,
                    destination: AnyView(PracticeView())
                )
                
                QuickActionCard(
                    title: "Progress",
                    subtitle: "Track your improvement",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green,
                    destination: AnyView(ProgressView())
                )
                
                QuickActionCard(
                    title: "Profile",
                    subtitle: "Manage your settings",
                    icon: "person.circle",
                    color: .purple,
                    destination: AnyView(ProfileView())
                )
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Card

struct RecentActivityCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "clock", 
                    text: "Last active \(timeAgoText(from: profile.lastActiveAt))",
                    color: .blue
                )
                
                if profile.totalFlashcardsSeen > 0 {
                    ActivityRow(
                        icon: "rectangle.on.rectangle",
                        text: "\(profile.totalFlashcardsSeen) flashcards studied",
                        color: .green
                    )
                }
                
                if profile.totalTestsTaken > 0 {
                    ActivityRow(
                        icon: "checkmark.circle",
                        text: "\(profile.totalTestsTaken) tests completed",
                        color: .orange
                    )
                }
                
                if profile.totalPatternsLearned > 0 {
                    ActivityRow(
                        icon: "square.grid.3x3",
                        text: "\(profile.totalPatternsLearned) patterns learned",
                        color: .purple
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
    }
    
    private func timeAgoText(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") ago"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            return "recently"
        }
    }
}

// MARK: - Activity Row

struct ActivityRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct TechniquesView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Technique Library")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Learn kicks, blocks, strikes, and forms with step-by-step video guides.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Techniques")
        }
    }
}

struct LearnView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "book.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Learning Center")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Master Korean terminology, theory knowledge, and test your understanding")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 16) {
                    NavigationLink(destination: FlashcardView()) {
                        HStack {
                            Image(systemName: "rectangle.on.rectangle")
                                .frame(width: 24)
                            Text("Flashcards")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TestSelectionView()) {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .frame(width: 24)
                            Text("Tests")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: TheoryView()) {
                        HStack {
                            Image(systemName: "graduationcap")
                                .frame(width: 24)
                            Text("Theory")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Learn")
        }
    }
}

struct PracticeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Practice Sessions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Master your techniques with structured practice sessions")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Spacer()
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    
                    PracticeMenuCard(
                        title: "Patterns/Tul",
                        description: "Traditional forms with step-by-step guidance",
                        icon: "square.grid.3x3.fill",
                        color: .blue,
                        destination: AnyView(PatternsView())
                    )
                    
                    PracticeMenuCard(
                        title: "Step Sparring",
                        description: "3, 2, and 1-step sparring techniques",
                        icon: "figure.2.arms.open",
                        color: .orange,
                        destination: AnyView(StepSparringView())
                    )
                    
                    PracticeMenuCard(
                        title: "Line Work",
                        description: "Forward/backward technique drills",
                        icon: "arrow.left.and.right",
                        color: .green,
                        destination: AnyView(LineWorkView())
                    )
                    
                    PracticeMenuCard(
                        title: "Technique How-To",
                        description: "Detailed breakdowns of every technique",
                        icon: "magnifyingglass.circle.fill",
                        color: .purple,
                        destination: AnyView(TechniqueGuideView())
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Practice")
        }
    }
}

struct ProgressView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var userProfile: UserProfile?
    @State private var studySessions: [StudySession] = []
    @State private var gradingHistory: [GradingRecord] = []
    @State private var gradingStatistics: GradingStatistics?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasLoadedData = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let profile = userProfile {
                        // Progress Overview Cards
                        progressOverviewSection(profile: profile)
                        
                        // Study Activity Section
                        studyActivitySection
                        
                        // Belt Progression Section
                        beltProgressionSection
                        
                        // Grading History Section (if any gradings exist)
                        if !gradingHistory.isEmpty {
                            gradingHistorySection
                        }
                        
                        Spacer(minLength: 20)
                    } else {
                        noProfileView
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher()
                }
            }
            .refreshable {
                await loadProgressData()
            }
            .onAppear {
                // Only load data when user actually navigates to Progress tab
                if !hasLoadedData {
                    Task {
                        await loadProgressData()
                        hasLoadedData = true
                    }
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - No Profile View
    private var noProfileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Profile Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please select or create a profile to view progress.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Progress Overview Section
    private func progressOverviewSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Progress Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProgressStat(
                    title: "Study Hours",
                    value: Int(profile.totalStudyTime / 3600),
                    color: .blue
                )
                
                ProgressStat(
                    title: "Current Streak",
                    value: profile.streakDays,
                    color: .orange
                )
                
                ProgressStat(
                    title: "Flashcards",
                    value: profile.totalFlashcardsSeen,
                    color: .purple
                )
                
                ProgressStat(
                    title: "Tests Taken",
                    value: profile.totalTestsTaken,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Study Activity Section
    private var studyActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if studySessions.isEmpty {
                Text("No study sessions recorded yet")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(studySessions.prefix(5)), id: \.id) { session in
                    StudySessionRow(session: session)
                }
                
                if studySessions.count > 5 {
                    Text("+ \(studySessions.count - 5) more sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Belt Progression Section
    private var beltProgressionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Belt Progression")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if let profile = userProfile {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Belt:")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(profile.currentBeltLevel.name)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    
                    // Show next belt if not at highest level
                    if profile.currentBeltLevel.sortOrder > 1 {
                        HStack {
                            Text("Next Goal:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(getNextBeltName(currentBelt: profile.currentBeltLevel))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Time at current belt
                    if let mostRecentGrading = gradingHistory.first {
                        let timeAtBelt = Date().timeIntervalSince(mostRecentGrading.gradingDate)
                        HStack {
                            Text("Time at Current Belt:")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTimeInterval(timeAtBelt))
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Grading History Section
    private var gradingHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundColor(.gold)
                
                Text("Grading History")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let stats = gradingStatistics {
                    Text("\(stats.passedGradings) / \(stats.totalGradings) passed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ForEach(Array(gradingHistory.prefix(3)), id: \.id) { grading in
                GradingRecordRow(grading: grading)
            }
            
            if gradingHistory.count > 3 {
                Text("+ \(gradingHistory.count - 3) more gradings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Data Loading
    @MainActor
    private func loadProgressData() async {
        isLoading = true
        errorMessage = nil
        
        // Get active profile first (this should be fast)
        userProfile = dataManager.profileService.getActiveProfile()
        
        guard let profile = userProfile else {
            isLoading = false
            return
        }
        
        do {
            // Add a small delay to let UI show loading state
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Load study sessions
            studySessions = try dataManager.profileService.getStudySessions(for: profile)
                .sorted { $0.startTime > $1.startTime }
            
            // Load grading history
            gradingHistory = try dataManager.profileService.getGradingHistory(for: profile)
            
            // Load grading statistics (only if there are gradings)
            if !gradingHistory.isEmpty {
                gradingStatistics = try dataManager.profileService.getGradingStatistics(for: profile)
            } else {
                gradingStatistics = nil
            }
            
        } catch {
            print("❌ Failed to load progress data: \(error)")
            errorMessage = "Failed to load progress data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Functions
    
    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval / 86400)
        let months = days / 30
        
        if months > 0 {
            return "\(months) month\(months == 1 ? "" : "s")"
        } else if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s")"
        } else {
            return "Less than a day"
        }
    }
    
    private func getNextBeltName(currentBelt: BeltLevel) -> String {
        // This is a simplified approach - in a real app you'd query for the next belt
        // based on sortOrder being currentBelt.sortOrder - 1
        return "Next Belt Level" // Placeholder
    }
}

// MARK: - Supporting Views

struct StudySessionRow: View {
    let session: StudySession
    
    var body: some View {
        HStack {
            Image(systemName: session.sessionType.icon)
                .font(.body)
                .foregroundColor(colorForSessionType(session.sessionType))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.sessionType.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatSessionDate(session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.accuracy * 100))%")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForAccuracy(session.accuracy))
                
                Text("\(session.itemsStudied) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func colorForSessionType(_ type: StudySessionType) -> Color {
        switch type {
        case .flashcards: return .blue
        case .testing: return .green
        case .patterns: return .purple
        case .mixed: return .orange
        }
    }
    
    private func colorForAccuracy(_ accuracy: Double) -> Color {
        if accuracy >= 0.9 { return .green }
        else if accuracy >= 0.7 { return .orange }
        else { return .red }
    }
    
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct GradingRecordRow: View {
    let grading: GradingRecord
    
    var body: some View {
        HStack {
            Image(systemName: grading.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.body)
                .foregroundColor(grading.passed ? .green : .red)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(grading.beltAchieved.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatGradingDate(grading.gradingDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(grading.passGrade.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForPassGrade(grading.passGrade))
                
                Text(grading.gradingType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func colorForPassGrade(_ grade: PassGrade) -> Color {
        switch grade {
        case .fail: return .red
        case .standard: return .blue
        case .a: return .green
        case .plus: return .orange
        case .distinction: return .purple
        }
    }
    
    private func formatGradingDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Practice Menu Components

struct PracticeMenuCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Practice Section Placeholder Views

struct PatternsView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var patterns: [Pattern] = []
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Patterns/Tul")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Traditional Taekwondo forms with detailed guidance")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading patterns...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                    .frame(maxHeight: .infinity)
            } else if patterns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.square.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No patterns available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Patterns will be available based on your current belt level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Pattern list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(patterns, id: \.id) { pattern in
                            PatternCard(pattern: pattern, userProfile: userProfile)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Patterns")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileSwitcher()
            }
        }
        .task {
            await loadPatterns()
        }
        .onChange(of: dataManager.profileService.activeProfile) {
            Task {
                await loadPatterns()
            }
        }
    }
    
    @MainActor
    private func loadPatterns() async {
        isLoading = true
        
        // Get the active profile from ProfileService
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, ensure we have at least one profile
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            patterns = dataManager.patternService.getPatternsForUser(userProfile: profile)
            print("🥋 Loaded \(patterns.count) patterns for user \(profile.name)")
        }
        
        isLoading = false
    }
}

// MARK: - Pattern Card Component

struct PatternCard: View {
    let pattern: Pattern
    let userProfile: UserProfile?
    @Environment(DataManager.self) private var dataManager
    @State private var userProgress: UserPatternProgress?
    
    var body: some View {
        NavigationLink(destination: PatternDetailView(pattern: pattern)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with pattern name and meaning
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pattern.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(pattern.englishMeaning)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Move count badge
                    Text("\(pattern.moveCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                // Progress indicator if user has started this pattern
                if let progress = userProgress {
                    PatternProgressIndicator(progress: progress)
                }
                
                // Belt level indicator
                HStack {
                    ForEach(pattern.orderedBeltLevels.prefix(3), id: \.id) { belt in
                        Text(belt.shortName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if pattern.beltLevels.count > 3 {
                        Text("+\(pattern.beltLevels.count - 3)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            loadUserProgress()
        }
    }
    
    private func loadUserProgress() {
        guard let profile = userProfile else { return }
        userProgress = dataManager.patternService.getUserProgress(for: pattern, userProfile: profile)
    }
}

// MARK: - Pattern Progress Indicator

struct PatternProgressIndicator: View {
    let progress: UserPatternProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress: \(Int(progress.progressPercentage))%")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(progress.masteryLevel.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorForMastery(progress.masteryLevel))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(colorForMastery(progress.masteryLevel))
                        .frame(width: geometry.size.width * (progress.progressPercentage / 100.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
    
    private func colorForMastery(_ level: PatternMasteryLevel) -> Color {
        switch level {
        case .learning: return .red
        case .familiar: return .orange
        case .proficient: return .blue
        case .mastered: return .green
        }
    }
}

// MARK: - Pattern Detail View (Placeholder)

struct PatternDetailView: View {
    let pattern: Pattern
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Pattern header
                VStack(alignment: .center, spacing: 12) {
                    Text(pattern.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.hangul)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.englishMeaning)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(pattern.significance)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                }
                
                Divider()
                
                // Pattern details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Moves:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text("\(pattern.moveCount)")
                            .font(.subheadline)
                    }
                    
                    HStack {
                        Text("Ready Position:")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(pattern.startingStance)
                            .font(.subheadline)
                    }
                }
                
                // Diagram section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pattern Diagram")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(pattern.diagramDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Diagram image if available
                    if let diagramURL = pattern.diagramImageURL, !diagramURL.isEmpty {
                        AsyncImage(url: URL(string: diagramURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.gray)
                                        Text("Diagram Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay(
                                VStack {
                                    Image(systemName: "square.grid.3x3")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                    Text("Diagram Coming Soon")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            )
                            .cornerRadius(12)
                    }
                }
                
                // Practice Interface Button
                NavigationLink(destination: PatternPracticeView(pattern: pattern)) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start Practice")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Interactive step-by-step guidance")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(pattern.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

// StepSparringView is now defined in StepSparring/StepSparringView.swift

// LineWorkView is now defined in LineWork/LineWorkView.swift

struct TechniqueGuideView: View {
    var body: some View {
        VStack {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("Technique Guide")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Detailed breakdowns of every technique and stance")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .navigationTitle("Technique Guide")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TestSelectionView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var isStartingTest = false
    @State private var testSession: TestSession?
    @State private var showingTest = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Test Your Knowledge")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Comprehensive tests to validate your learning progress")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("Comprehensive Test") {
                    startComprehensiveTest()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isStartingTest)
                
                Button("Quick Test (5-10 questions)") {
                    startQuickTest()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .disabled(isStartingTest)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
            }
            .padding(.horizontal)
            
            if isStartingTest {
                VStack {
                    ProgressView()
                    Text("Preparing your test...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            Spacer()
        }
        .navigationTitle("Tests")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(isPresented: $showingTest) {
            if let session = testSession {
                TestTakingView(testSession: session)
            }
        }
    }
    
    private func startComprehensiveTest() {
        // Get the active profile from ProfileService
        guard let userProfile = dataManager.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataManager.modelContext,
                    terminologyService: dataManager.terminologyService
                )
                
                let session = try testingService.createComprehensiveTest(for: userProfile)
                self.testSession = session
                self.showingTest = true
            } catch {
                self.errorMessage = "Failed to create test: \(error.localizedDescription)"
            }
            
            self.isStartingTest = false
        }
    }
    
    private func startQuickTest() {
        // Get the active profile from ProfileService
        guard let userProfile = dataManager.profileService.getActiveProfile() else {
            errorMessage = "No active profile found. Please create a profile first."
            return
        }
        
        isStartingTest = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                let testingService = TestingService(
                    modelContext: dataManager.modelContext,
                    terminologyService: dataManager.terminologyService
                )
                
                let session = try testingService.createQuickTest(for: userProfile)
                self.testSession = session
                self.showingTest = true
            } catch {
                self.errorMessage = "Failed to create test: \(error.localizedDescription)"
            }
            
            self.isStartingTest = false
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    @Environment(DataManager.self) private var dataManager
    @State private var showingProfileManagement = false
    @State private var showingSettings = false
    @State private var userProfile: UserProfile?
    @State private var allProfiles: [UserProfile] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Profile Header
                    if let profile = userProfile {
                        ProfileHeaderCard(profile: profile)
                    }
                    
                    // Profile Management Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Family Profiles")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(allProfiles.count)/6")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProfileGridView(profiles: allProfiles, currentProfile: userProfile)
                        
                        if allProfiles.count < 6 {
                            Button("Add New Profile") {
                                showingProfileManagement = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    // Settings & Actions
                    VStack(spacing: 12) {
                        NavigationLink("Learning Settings") {
                            UserSettingsView()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                        
                        Button("Manage All Profiles") {
                            showingProfileManagement = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadProfiles()
            }
            .onChange(of: dataManager.profileService.activeProfile) {
                loadProfiles()
            }
            .sheet(isPresented: $showingProfileManagement) {
                ProfileManagementView()
            }
        }
    }
    
    private func loadProfiles() {
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, create default
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        // Load all profiles
        do {
            allProfiles = try dataManager.profileService.getAllProfiles()
        } catch {
            print("❌ Failed to load profiles: \(error)")
            allProfiles = []
        }
    }
}

// MARK: - Profile Header Card

struct ProfileHeaderCard: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Image(systemName: profile.avatar.rawValue)
                .font(.system(size: 50))
                .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                .frame(width: 70, height: 70)
                .background(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                .clipShape(Circle())
            
            // Profile Info
            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Text(profile.currentBeltLevel.shortName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(profile.colorTheme.primarySwiftUIColor.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(profile.learningMode.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quick Stats
                HStack(spacing: 16) {
                    StatBadge(title: "Streak", value: "\(profile.streakDays)")
                    StatBadge(title: "Flashcards", value: "\(profile.totalFlashcardsSeen)")
                    StatBadge(title: "Tests", value: "\(profile.totalTestsTaken)")
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Profile Grid View

struct ProfileGridView: View {
    let profiles: [UserProfile]
    let currentProfile: UserProfile?
    @Environment(DataManager.self) private var dataManager
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(profiles, id: \.id) { profile in
                ProfileGridCard(
                    profile: profile,
                    isActive: profile.id == currentProfile?.id,
                    onTap: { switchToProfile(profile) }
                )
            }
        }
    }
    
    private func switchToProfile(_ profile: UserProfile) {
        do {
            try dataManager.profileService.activateProfile(profile)
        } catch {
            print("❌ Failed to switch profile: \(error)")
        }
    }
}

// MARK: - Profile Grid Card

struct ProfileGridCard: View {
    let profile: UserProfile
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Avatar with active indicator
                ZStack {
                    Image(systemName: profile.avatar.rawValue)
                        .font(.system(size: 24))
                        .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                        .frame(width: 50, height: 50)
                        .background(profile.colorTheme.primarySwiftUIColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    if isActive {
                        Circle()
                            .stroke(profile.colorTheme.primarySwiftUIColor, lineWidth: 3)
                            .frame(width: 58, height: 58)
                    }
                }
                
                Text(profile.name)
                    .font(.caption)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive ? profile.colorTheme.primarySwiftUIColor : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(profile.currentBeltLevel.shortName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? profile.colorTheme.primarySwiftUIColor.opacity(0.1) : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? profile.colorTheme.primarySwiftUIColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
    }
}

struct MainTabCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabCoordinatorView()
            .environmentObject(AppCoordinator.previewMainFlow)
    }
}