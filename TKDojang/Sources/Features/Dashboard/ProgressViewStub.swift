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
    @Environment(\.dataManager) private var dataManager
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
        }
    }
    
    private func loadProgressData() async {
        guard let activeProfile = dataManager.profileService.getActiveProfile() else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        progressData = await dataManager.progressCacheService.getProgressData(for: activeProfile.id)
    }
    
    private func refreshProgressData() async {
        guard let activeProfile = dataManager.profileService.getActiveProfile() else { return }
        
        progressData = await dataManager.progressCacheService.getProgressData(for: activeProfile.id)
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