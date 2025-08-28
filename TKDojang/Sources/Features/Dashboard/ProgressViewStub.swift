import SwiftUI

/**
 * ProgressView.swift
 * 
 * PURPOSE: High-performance progress analytics using cached data
 * 
 * DESIGN DECISIONS:
 * - Cache-first approach for instant loading
 * - No direct SwiftData relationship navigation
 * - Comprehensive analytics with beautiful visualizations
 * - Profile-aware progress tracking
 */
struct ProgressViewStub: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var progressData: ProgressSnapshot?
    @State private var isLoading = false
    @State private var selectedTimeRange: TimeRange = .week
    
    var body: some View {
        NavigationStack {
            Group {
                if let progressData = progressData {
                    ProgressContentView(progressData: progressData, selectedTimeRange: $selectedTimeRange)
                } else if isLoading {
                    ProgressLoadingView()
                } else {
                    ProgressEmptyView()
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadProgressData()
            }
            .refreshable {
                await refreshProgressData()
            }
            .onChange(of: dataServices.profileService.activeProfile) {
                Task {
                    await refreshProgressData()
                }
            }
        }
    }
    
    private func loadProgressData() async {
        guard let activeProfile = dataServices.profileService.getActiveProfile() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        progressData = await dataServices.progressCacheService.getProgressData(for: activeProfile.id)
    }
    
    private func refreshProgressData() async {
        guard let activeProfile = dataServices.profileService.getActiveProfile() else { return }
        
        // Force cache refresh when refreshing progress data
        await dataServices.progressCacheService.refreshCache(for: activeProfile.id)
        progressData = await dataServices.progressCacheService.getProgressData(for: activeProfile.id)
    }
}

// MARK: - Progress Content View

struct ProgressContentView: View {
    let progressData: ProgressSnapshot
    @Binding var selectedTimeRange: TimeRange
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Overview Stats Cards
                OverviewStatsGrid(progressData: progressData)
                
                // Time Range Selector
                TimeRangePicker(selectedTimeRange: $selectedTimeRange)
                
                // Activity Chart
                ActivityChartCard(progressData: progressData, timeRange: selectedTimeRange)
                
                // Learning Breakdown
                LearningBreakdownCard(progressData: progressData)
                
                // Belt Progress
                BeltProgressCard(progressData: progressData)
                
                // Belt Journey
                BeltJourneyCard(beltJourneyData: progressData.beltJourneyStats)
                
                // Belt Timeline
                BeltTimelineCard(beltJourneyData: progressData.beltJourneyStats)
                
                // Recent Activity
                ProgressRecentActivityCard(progressData: progressData)
            }
            .padding()
        }
    }
}

// MARK: - Overview Stats Grid

struct OverviewStatsGrid: View {
    let progressData: ProgressSnapshot
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatsCard(
                title: "Study Time",
                value: progressData.overallStats.formattedStudyTime,
                icon: "clock",
                color: .blue
            )
            
            StatsCard(
                title: "Sessions",
                value: "\(progressData.overallStats.totalSessions)",
                icon: "calendar",
                color: .green
            )
            
            StatsCard(
                title: "Accuracy",
                value: "\(progressData.overallStats.accuracyPercentage)%",
                icon: "target",
                color: .orange
            )
            
            StatsCard(
                title: "Current Streak",
                value: "\(progressData.streakStats.currentStreak) days",
                icon: "flame",
                color: .red
            )
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Time Range Picker

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct TimeRangePicker: View {
    @Binding var selectedTimeRange: TimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
}

// MARK: - Activity Chart Card

struct ActivityChartCard: View {
    let progressData: ProgressSnapshot
    let timeRange: TimeRange
    
    var chartData: [DailyProgressData] {
        switch timeRange {
        case .week:
            return Array(progressData.weeklyData.suffix(7))
        case .month:
            return Array(progressData.monthlyData.suffix(30))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Study Activity")
                .font(.headline)
                .padding(.horizontal)
            
            SimpleBarChart(data: chartData)
                .frame(height: 200)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Simple Bar Chart

struct SimpleBarChart: View {
    let data: [DailyProgressData]
    
    var maxValue: Double {
        data.map { $0.studyTime }.max() ?? 1
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, dayData in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(dayData.studyTime > 0 ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: max(4, (dayData.studyTime / maxValue) * 160))
                        .cornerRadius(2)
                    
                    Text(dayData.dayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .animation(.easeInOut, value: data)
    }
}

// MARK: - Learning Breakdown Card

struct LearningBreakdownCard: View {
    let progressData: ProgressSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Breakdown")
                .font(.headline)
            
            VStack(spacing: 12) {
                LearningRow(
                    title: "Flashcards",
                    value: "\(progressData.flashcardStats.totalCardsSeen)",
                    subtitle: "\(progressData.flashcardStats.accuracyPercentage)% accuracy",
                    icon: "rectangle.on.rectangle",
                    color: .blue
                )
                
                LearningRow(
                    title: "Tests",
                    value: "\(progressData.testingStats.totalTestsTaken)",
                    subtitle: "\(progressData.testingStats.averageScorePercentage)% average",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                LearningRow(
                    title: "Patterns",
                    value: "\(progressData.patternStats.totalPatternsLearned)",
                    subtitle: "\(progressData.patternStats.practiceSessionsCompleted) sessions",
                    icon: "square.grid.3x3",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct LearningRow: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Belt Progress Card

struct BeltProgressCard: View {
    let progressData: ProgressSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Belt Progress")
                .font(.headline)
            
            VStack(spacing: 12) {
                ProgressBar(
                    title: "Terminology",
                    progress: progressData.beltProgressStats.terminologyMastery,
                    color: .blue
                )
                
                ProgressBar(
                    title: "Patterns",
                    progress: progressData.beltProgressStats.patternMastery,
                    color: .green
                )
                
                ProgressBar(
                    title: "Overall",
                    progress: progressData.beltProgressStats.overallMastery,
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct ProgressBar: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Progress Recent Activity Card

struct ProgressRecentActivityCard: View {
    let progressData: ProgressSnapshot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.headline)
            
            VStack(spacing: 12) {
                RecentActivityRow(
                    title: "Study Time",
                    value: progressData.recentActivity.formattedWeeklyStudyTime,
                    icon: "clock"
                )
                
                RecentActivityRow(
                    title: "Accuracy",
                    value: "\(progressData.recentActivity.weeklyAccuracyPercentage)%",
                    icon: "target"
                )
                
                RecentActivityRow(
                    title: "Sessions",
                    value: "\(progressData.recentActivity.sessionsThisWeek)",
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct RecentActivityRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Loading and Empty States

struct ProgressLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading your progress...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProgressEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No Progress Data")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Complete some learning sessions to see your progress here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Belt Journey Components

struct BeltJourneyCard: View {
    let beltJourneyData: BeltJourneyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Belt Journey")
                .font(.headline)
            
            VStack(spacing: 16) {
                // Current Belt Display
                CurrentBeltDisplay(currentBelt: beltJourneyData.currentBelt, studyingBelt: beltJourneyData.studyingBelt)
                
                // Belt Mismatch Warning (if applicable)
                if beltJourneyData.hasBeltMismatch, let mismatchMessage = beltJourneyData.beltMismatchMessage {
                    BeltMismatchWarning(message: mismatchMessage)
                }
                
                // Next Belt Progress
                if let nextBelt = beltJourneyData.nextBelt,
                   let requirements = beltJourneyData.nextBeltRequirements {
                    NextBeltProgress(nextBelt: nextBelt, requirements: requirements)
                }
                
                // Belt Journey Stats
                BeltJourneyStatsRow(beltJourneyData: beltJourneyData)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

struct CurrentBeltDisplay: View {
    let currentBelt: BeltInfo
    let studyingBelt: BeltInfo
    
    var body: some View {
        VStack(spacing: 12) {
            // Current Achieved Belt
            HStack(spacing: 12) {
                BeltVisualIndicator(
                    primaryColor: currentBelt.primaryColor ?? "#000000",
                    secondaryColor: currentBelt.secondaryColor,
                    width: 40,
                    height: 40
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Belt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(currentBelt.shortName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(currentBelt.colorName + " Belt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "medal.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: currentBelt.primaryColor ?? "#000000"))
            }
            
            // Studying Belt (if different from current)
            if currentBelt.id != studyingBelt.id {
                Divider()
                
                HStack(spacing: 12) {
                    BeltVisualIndicator(
                        primaryColor: studyingBelt.primaryColor ?? "#000000",
                        secondaryColor: studyingBelt.secondaryColor,
                        width: 32,
                        height: 32
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Studying")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(studyingBelt.shortName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Learning \(studyingBelt.colorName.lowercased()) belt content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "book.fill")
                        .font(.title3)
                        .foregroundColor(Color(hex: studyingBelt.primaryColor ?? "#000000"))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

// MARK: - Belt Visual Indicator

struct BeltVisualIndicator: View {
    let primaryColor: String
    let secondaryColor: String?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Main belt color
            Rectangle()
                .fill(Color(hex: primaryColor))
                .frame(width: width, height: height)
                .cornerRadius(height / 8)
            
            // Secondary color stripe (horizontal through the middle)
            if let secondaryColorHex = secondaryColor, !secondaryColorHex.isEmpty {
                Rectangle()
                    .fill(Color(hex: secondaryColorHex))
                    .frame(width: width, height: height / 3)
                    .cornerRadius(height / 24)
            }
        }
        .overlay(
            // Subtle shadow/depth effect
            RoundedRectangle(cornerRadius: height / 8)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Belt Mismatch Warning

struct BeltMismatchWarning: View {
    @EnvironmentObject private var dataServices: DataServices
    let message: String
    @State private var showingProfileSettings = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Study Level Mismatch")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Button("Update", systemImage: "gear") {
                showingProfileSettings = true
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingProfileSettings) {
            if let activeProfile = dataServices.profileService.getActiveProfile() {
                ProfileEditView(profile: activeProfile)
            }
        }
    }
}

struct NextBeltProgress: View {
    let nextBelt: BeltInfo
    let requirements: BeltRequirements
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Next: \(nextBelt.shortName)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(requirements.readinessPercentage)% Ready")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(requirements.isReady ? .green : .orange)
            }
            
            VStack(spacing: 8) {
                RequirementProgressBar(
                    title: "Terminology",
                    progress: requirements.terminologyProgress,
                    color: .blue
                )
                
                RequirementProgressBar(
                    title: "Patterns",
                    progress: requirements.patternProgress,
                    color: .green
                )
                
                RequirementProgressBar(
                    title: "Study Time",
                    progress: requirements.studyTimeProgress,
                    color: .orange
                )
            }
            
            if let readinessDate = requirements.estimatedReadinessDate {
                Text("Estimated readiness: \(readinessDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
}

struct RequirementProgressBar: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .cornerRadius(2)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct BeltJourneyStatsRow: View {
    let beltJourneyData: BeltJourneyStats
    
    var body: some View {
        HStack {
            BeltStatItem(
                title: "Belts Earned",
                value: "\(beltJourneyData.beltProgression.totalBeltsEarned)",
                icon: "star.fill"
            )
            
            Spacer()
            
            BeltStatItem(
                title: "Pass Rate",
                value: "\(Int(beltJourneyData.passRate * 100))%",
                icon: "checkmark.circle.fill"
            )
            
            Spacer()
            
            BeltStatItem(
                title: "Journey Time",
                value: beltJourneyData.beltProgression.formattedJourneyTime,
                icon: "clock.fill"
            )
        }
    }
}

struct BeltStatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 60)
    }
}

struct BeltTimelineCard: View {
    let beltJourneyData: BeltJourneyStats
    @EnvironmentObject private var dataServices: DataServices
    @State private var showingGradingManagement = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Grading History")
                    .font(.headline)
                
                Spacer()
                
                // Add button to manage gradings
                Button("Manage", systemImage: "pencil") {
                    showingGradingManagement = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
            
            if beltJourneyData.gradingHistory.isEmpty {
                EmptyTimelineView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(beltJourneyData.gradingHistory.enumerated()), id: \.offset) { index, grading in
                            TimelineItem(grading: grading, isFirst: index == 0, isLast: index == beltJourneyData.gradingHistory.count - 1)
                                .onTapGesture {
                                    showingGradingManagement = true
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .sheet(isPresented: $showingGradingManagement) {
            if let activeProfile = dataServices.profileService.getActiveProfile() {
                GradingHistoryManagementView(profile: activeProfile)
            }
        }
    }
}

struct TimelineItem: View {
    let grading: GradingHistoryEntry
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Belt indicator with actual belt colors
            BeltVisualIndicator(
                primaryColor: grading.beltAchieved.primaryColor ?? "#000000",
                secondaryColor: grading.beltAchieved.secondaryColor,
                width: 20,
                height: 20
            )
            .overlay(
                Image(systemName: grading.passed ? "checkmark" : "xmark")
                    .font(.caption)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            )
            
            // Belt info
            VStack(spacing: 4) {
                Text(grading.beltAchieved.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(grading.formattedGradingDate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                if !grading.examiner.isEmpty {
                    Text(grading.examiner)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 80)
        }
        .padding(.vertical, 8)
    }
}

struct EmptyTimelineView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var showingGradingManagement = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Grading History")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("Add your belt gradings to track your journey and unlock detailed progress analytics.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add Grading History", systemImage: "plus") {
                showingGradingManagement = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
        .sheet(isPresented: $showingGradingManagement) {
            if let activeProfile = dataServices.profileService.getActiveProfile() {
                GradingHistoryManagementView(profile: activeProfile)
            }
        }
    }
}

