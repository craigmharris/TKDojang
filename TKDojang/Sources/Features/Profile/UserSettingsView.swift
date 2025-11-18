import SwiftUI
import SwiftData

/**
 * UserSettingsView.swift
 * 
 * PURPOSE: Allows users to configure their belt level and learning preferences
 */

struct UserSettingsView: View {
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \BeltLevel.sortOrder, order: .reverse) private var beltLevels: [BeltLevel]
    @Query(sort: \TerminologyCategory.sortOrder) private var categories: [TerminologyCategory]

    @State private var userProfile: UserProfile?
    @State private var selectedBeltLevelId: UUID?
    @State private var selectedLearningMode: LearningMode = .progression
    @State private var dailyStudyGoal: Int = 20
    @State private var isRefreshing = false

    @StateObject private var notificationManager = NotificationPermissionManager()
    
    var body: some View {
        NavigationStack {
            if isRefreshing {
                VStack {
                    ProgressView()
                    Text("Loading settings...")
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Form {
                Section("Current Level") {
                    Picker("Your Belt Level", selection: $selectedBeltLevelId) {
                        ForEach(sortedBeltLevels, id: \.id) { belt in
                            Text(belt.name)
                                .tag(belt.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Learning Focus") {
                    Picker("Learning Mode", selection: $selectedLearningMode) {
                        ForEach(LearningMode.allCases, id: \.self) { mode in
                            Text(mode.displayName)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Description for selected mode
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedLearningMode.description)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text(learningModeExplanation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }
                
                Section("Study Preferences") {
                    Stepper("Daily Goal: \(dailyStudyGoal) terms", value: $dailyStudyGoal, in: 5...50, step: 5)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Leitner Box Spaced Repetition", isOn: Binding(
                            get: { dataServices.leitnerService.isLeitnerModeEnabled },
                            set: { newValue in 
                                dataServices.leitnerService.isLeitnerModeEnabled = newValue
                                if newValue, let profile = userProfile {
                                    dataServices.leitnerService.migrateToLeitnerMode(userProfile: profile)
                                }
                            }
                        ))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dataServices.leitnerService.currentModeDisplayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(dataServices.leitnerService.currentModeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if dataServices.leitnerService.isLeitnerModeEnabled, let profile = userProfile {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Learning Statistics:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Terms Due for Review:")
                                    Spacer()
                                    Text("\(dataServices.leitnerService.getTermsDueCount(userProfile: profile))")
                                        .foregroundColor(.blue)
                                }
                                .font(.caption)
                                
                                Text("Box Distribution:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                let distribution = dataServices.leitnerService.getBoxDistribution(userProfile: profile)
                                ForEach(1...5, id: \.self) { box in
                                    HStack {
                                        Text("Box \(box):")
                                        Spacer()
                                        Text("\(distribution[box] ?? 0) terms")
                                            .foregroundColor(.secondary)
                                    }
                                    .font(.caption2)
                                    .padding(.leading, 8)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                } header: {
                    Text("Advanced Features")
                } footer: {
                    Text("Leitner Box uses spaced repetition to optimize learning. Terms are scheduled for review based on how well you know them.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Feedback Response Notifications")
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text(notificationStatusDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            notificationStatusIcon
                        }

                        if notificationManager.permissionStatus == .denied {
                            Button(action: {
                                notificationManager.openAppSettings()
                            }) {
                                Label("Open Settings", systemImage: "gear")
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text(notificationManager.permissionExplanation)
                }

                Section("Data Management") {
                    NavigationLink("Manage Profile Data", destination: SafeDataManagementView())
                        .foregroundColor(.primary)


                    Text("Delete profiles, reset progress, or export data. Family-safe options with confirmations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Current Settings Summary") {
                    if let belt = selectedBeltLevel {
                        HStack {
                            Text("Current Belt:")
                            Spacer()
                            Text(belt.shortName)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Learning Mode:")
                            Spacer()
                            Text(selectedLearningMode.displayName)
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Content Focus:")
                            Spacer()
                            Text(contentFocusDescription)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("Learning Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        }
        .modelContainer(dataServices.modelContainer) // Needed for @Query properties
        .onAppear {
            loadCurrentSettings()
        }
        .onReceive(dataServices.objectWillChange) { _ in
            // Refresh when the data services change (e.g., profile switch)
            loadCurrentSettings()
        }
    }
    
    // MARK: - Computed Properties

    private var notificationStatusDescription: String {
        switch notificationManager.permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return "Enabled - You'll receive updates on feedback responses"
        case .denied:
            return "Disabled - Enable in Settings to get notified"
        case .notDetermined:
            return "Not configured - Submit feedback to enable"
        @unknown default:
            return "Status unknown"
        }
    }

    private var notificationStatusIcon: some View {
        Group {
            switch notificationManager.permissionStatus {
            case .authorized, .provisional, .ephemeral:
                Image(systemName: "bell.fill")
                    .foregroundColor(.green)
            case .denied:
                Image(systemName: "bell.slash.fill")
                    .foregroundColor(.orange)
            case .notDetermined:
                Image(systemName: "bell")
                    .foregroundColor(.gray)
            @unknown default:
                Image(systemName: "bell.badge.questionmark")
                    .foregroundColor(.gray)
            }
        }
        .font(.title2)
    }

    private var sortedBeltLevels: [BeltLevel] {
        // Use @Query first, but fall back to service if empty
        if !beltLevels.isEmpty {
            let sorted = beltLevels.sorted { $0.sortOrder > $1.sortOrder } // Higher sortOrder first (10th Keup -> 1st Dan)
            DebugLogger.profile("🔧 DEBUG: sortedBeltLevels from @Query count: \(sorted.count)")
            return sorted
        } else {
            // Fallback: Load belt levels directly from service
            let serviceBelts = dataServices.patternService.getAllBeltLevels()
            let sorted = serviceBelts.sorted { $0.sortOrder > $1.sortOrder }
            DebugLogger.profile("🔧 DEBUG: sortedBeltLevels from service count: \(sorted.count)")
            return sorted
        }
    }
    
    private var selectedBeltLevel: BeltLevel? {
        guard let id = selectedBeltLevelId else { return nil }
        
        // Try @Query results first, then fallback to service
        if let belt = beltLevels.first(where: { $0.id == id }) {
            return belt
        } else {
            // Fallback: Search in service results
            return sortedBeltLevels.first { $0.id == id }
        }
    }
    
    private var learningModeExplanation: String {
        guard let belt = selectedBeltLevel else { return "" }
        
        switch selectedLearningMode {
        case .progression:
            let nextBelt = getNextBelt(from: belt)
            return "Focus on learning material for \(nextBelt?.shortName ?? "next level")"
        case .mastery:
            return "Review all material from White Belt through \(belt.shortName)"
        }
    }
    
    private var contentFocusDescription: String {
        guard let belt = selectedBeltLevel else { return "No belt selected" }
        
        switch selectedLearningMode {
        case .progression:
            let nextBelt = getNextBelt(from: belt)
            return nextBelt?.shortName ?? "Advanced"
        case .mastery:
            return "White Belt - \(belt.shortName)"
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentSettings() {
        DebugLogger.profile("🔧 DEBUG: UserSettingsView loading current settings")
        isRefreshing = true
        
        // Use ProfileService to get the active profile instead of cached method
        userProfile = dataServices.profileService.getActiveProfile()
        DebugLogger.profile("🔧 DEBUG: Active profile from service: \(userProfile?.name ?? "nil")")
        
        // If no active profile, create one using the DataManager method
        if userProfile == nil {
            DebugLogger.profile("🔧 DEBUG: No active profile, creating default")
            userProfile = dataServices.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            DebugLogger.profile("🔧 DEBUG: Profile loaded: \(profile.name), belt: \(profile.currentBeltLevel.shortName)")
            selectedBeltLevelId = profile.currentBeltLevel.id
            selectedLearningMode = profile.learningMode
            dailyStudyGoal = profile.dailyStudyGoal
        } else {
            DebugLogger.profile("🔧 DEBUG: Still no profile after attempting creation")
        }
        
        isRefreshing = false
    }
    
    private func saveSettings() {
        guard let profile = userProfile,
              let belt = selectedBeltLevel else { return }
        
        profile.currentBeltLevel = belt
        profile.learningMode = selectedLearningMode
        profile.dailyStudyGoal = dailyStudyGoal
        profile.updatedAt = Date()
        
        do {
            try dataServices.modelContainer.mainContext.save()
            dismiss()
        } catch {
            DebugLogger.profile("Failed to save settings: \(error)")
        }
    }
    
    private func getNextBelt(from currentBelt: BeltLevel) -> BeltLevel? {
        let nextSortOrder = currentBelt.sortOrder - 1
        return beltLevels.first { $0.sortOrder == nextSortOrder }
    }
}

// MARK: - Preview

struct UserSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingsView()
            
    }
}