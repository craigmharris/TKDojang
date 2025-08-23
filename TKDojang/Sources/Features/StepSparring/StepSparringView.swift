import SwiftUI

/**
 * StepSparringView.swift
 * 
 * PURPOSE: Main step sparring interface with type selection tiles
 * 
 * FEATURES:
 * - Tile-based selection for different sparring types
 * - Belt-level appropriate content filtering
 * - Progress indication for each sparring type
 * - Seamless navigation to specific sparring sequences
 */

struct StepSparringView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var userProfile: UserProfile?
    @State private var progressSummary: StepSparringProgressSummary?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "figure.2.arms.open")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Step Sparring")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Master attack and defense combinations with structured sparring practice")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading step sparring content...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                // Progress Overview (if user has started any sequences)
                if let summary = progressSummary, summary.totalSequences > 0 {
                    StepSparringProgressOverview(summary: summary)
                }
                
                // Type Selection Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    
                    ForEach(StepSparringType.allCases, id: \.rawValue) { type in
                        StepSparringTypeCard(
                            type: type,
                            userProfile: userProfile,
                            progressSummary: progressSummary
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Step Sparring")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileSwitcher()
            }
        }
        .task {
            await loadContent()
        }
        .onChange(of: dataManager.profileService.activeProfile) {
            Task {
                await loadContent()
            }
        }
    }
    
    @MainActor
    private func loadContent() async {
        isLoading = true
        
        // Clear existing data to prevent holding stale references
        userProfile = nil
        progressSummary = nil
        
        // Get the active profile
        userProfile = dataManager.profileService.getActiveProfile()
        
        // If no active profile, create default
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        // Load progress summary with error handling
        if let profile = userProfile {
            do {
                progressSummary = dataManager.stepSparringService.getProgressSummary(userProfile: profile)
                print("✅ Loaded step sparring progress summary")
            } catch {
                print("❌ Failed to load progress summary: \(error)")
                progressSummary = nil
            }
        }
        
        isLoading = false
    }
}

// MARK: - Progress Overview Component

struct StepSparringProgressOverview: View {
    let summary: StepSparringProgressSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(summary.overallCompletionPercentage))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * (summary.overallCompletionPercentage / 100.0), height: 6)
                }
            }
            .frame(height: 6)
            
            // Quick stats
            HStack(spacing: 16) {
                StatBadge(title: "Mastered", value: "\(summary.mastered)")
                StatBadge(title: "Sessions", value: "\(summary.totalPracticeSessions)")
                StatBadge(title: "Time", value: formatTime(summary.totalPracticeTime))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }
}

// MARK: - Type Selection Card

struct StepSparringTypeCard: View {
    let type: StepSparringType
    let userProfile: UserProfile?
    let progressSummary: StepSparringProgressSummary?
    
    @Environment(DataManager.self) private var dataManager
    
    private var progressForType: [UserStepSparringProgress] {
        guard let summary = progressSummary else { return [] }
        
        switch type {
        case .threeStep:
            return summary.threeStepProgress
        case .twoStep:
            return summary.twoStepProgress
        case .oneStep:
            return summary.oneStepProgress
        case .semiFree:
            return summary.semiFreeProgress
        }
    }
    
    private var completionPercentage: Double {
        let progress = progressForType
        guard !progress.isEmpty else { return 0.0 }
        
        let mastered = progress.filter { $0.masteryLevel == .mastered }.count
        return Double(mastered) / Double(progress.count) * 100.0
    }
    
    private var typeColor: Color {
        switch type {
        case .threeStep: return .blue
        case .twoStep: return .green
        case .oneStep: return .orange
        case .semiFree: return .purple
        }
    }
    
    var body: some View {
        NavigationLink(destination: StepSparringSequenceListView(type: type)) {
            VStack(spacing: 12) {
                // Icon and progress indicator
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 28))
                        .foregroundColor(typeColor)
                    
                    // Progress ring for types with progress
                    if !progressForType.isEmpty && completionPercentage > 0 {
                        Circle()
                            .trim(from: 0, to: completionPercentage / 100.0)
                            .stroke(typeColor, lineWidth: 3)
                            .frame(width: 66, height: 66)
                            .rotationEffect(.degrees(-90))
                    }
                }
                
                // Title and description
                Text(type.shortName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(type.description)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Progress indicator
                if !progressForType.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(typeColor)
                        Text("\(progressForType.filter { $0.masteryLevel == .mastered }.count)/\(progressForType.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(typeColor)
                    }
                } else {
                    Text("Get Started")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 180)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(typeColor.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sequence List View

struct StepSparringSequenceListView: View {
    let type: StepSparringType
    
    @Environment(DataManager.self) private var dataManager
    @State private var sequences: [StepSparringSequence] = []
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Loading sequences...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if sequences.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: type.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No sequences available")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Sequences for your belt level will appear here when available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(sequences, id: \.id) { sequence in
                            StepSparringSequenceCard(
                                sequence: sequence,
                                userProfile: userProfile
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(type.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileSwitcher()
            }
        }
        .task {
            await loadSequences()
        }
        .onChange(of: dataManager.profileService.activeProfile) {
            Task {
                await loadSequences()
            }
        }
    }
    
    @MainActor
    private func loadSequences() async {
        isLoading = true
        
        // Clear existing sequences to prevent holding stale references
        sequences = []
        
        userProfile = dataManager.profileService.getActiveProfile()
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            do {
                // Use a fresh fetch each time to avoid invalidated object issues
                sequences = dataManager.stepSparringService.getSequences(for: type, userProfile: profile)
                print("✅ Loaded \(sequences.count) sequences for \(type.displayName)")
            } catch {
                print("❌ Failed to load sequences: \(error)")
                sequences = []
            }
        }
        
        isLoading = false
    }
}

// MARK: - Sequence Card Component

struct StepSparringSequenceCard: View {
    let sequence: StepSparringSequence
    let userProfile: UserProfile?
    
    @Environment(DataManager.self) private var dataManager
    @State private var progress: UserStepSparringProgress?
    
    var body: some View {
        NavigationLink(destination: StepSparringPracticeView(sequence: sequence)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sequence.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(sequence.sequenceDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Step count badge
                    HStack(spacing: 4) {
                        Image(systemName: "figure.2.arms.open")
                            .font(.caption)
                        Text("\(sequence.totalSteps) steps")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor)
                    .cornerRadius(8)
                }
                
                // Progress indicator if user has started
                if let progress = progress {
                    StepSparringProgressIndicator(progress: progress)
                }
                
                // Difficulty and key points
                HStack {
                    // Difficulty stars
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= sequence.difficulty ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundColor(star <= sequence.difficulty ? .yellow : .gray.opacity(0.3))
                        }
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
                    .stroke(typeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .task {
            loadProgress()
        }
    }
    
    private var typeColor: Color {
        switch sequence.type {
        case .threeStep: return .blue
        case .twoStep: return .green
        case .oneStep: return .orange
        case .semiFree: return .purple
        }
    }
    
    private func loadProgress() {
        guard let profile = userProfile else { 
            progress = nil
            return 
        }
        
        do {
            progress = dataManager.stepSparringService.getUserProgress(for: sequence, userProfile: profile)
        } catch {
            print("❌ Failed to load progress for sequence \(sequence.name): \(error)")
            progress = nil
        }
    }
}

// MARK: - Progress Indicator Component

struct StepSparringProgressIndicator: View {
    let progress: UserStepSparringProgress
    
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
    
    private func colorForMastery(_ level: StepSparringMasteryLevel) -> Color {
        switch level {
        case .learning: return .red
        case .familiar: return .orange
        case .proficient: return .blue
        case .mastered: return .green
        }
    }
}