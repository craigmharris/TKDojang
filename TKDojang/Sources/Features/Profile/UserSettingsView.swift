import SwiftUI
import SwiftData

/**
 * UserSettingsView.swift
 * 
 * PURPOSE: Allows users to configure their belt level and learning preferences
 */

struct UserSettingsView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss
    @Query private var beltLevels: [BeltLevel]
    @Query private var categories: [TerminologyCategory]
    
    @State private var userProfile: UserProfile?
    @State private var selectedBeltLevel: BeltLevel?
    @State private var selectedLearningMode: LearningMode = .progression
    @State private var dailyStudyGoal: Int = 20
    
    var body: some View {
        NavigationView {
            Form {
                Section("Current Level") {
                    Picker("Your Belt Level", selection: $selectedBeltLevel) {
                        ForEach(sortedBeltLevels, id: \.id) { belt in
                            Text(belt.name)
                                .tag(belt as BeltLevel?)
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
                
                Section("Debug Tools") {
                    Button("Reset Database & Reload Content") {
                        dataManager.resetAndReloadDatabase()
                    }
                    .foregroundColor(.red)
                    
                    Text("Use this if belt colors aren't showing correctly. This will delete all progress and reload content with proper colors.")
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
        .onAppear {
            loadCurrentSettings()
        }
    }
    
    // MARK: - Computed Properties
    
    private var sortedBeltLevels: [BeltLevel] {
        beltLevels.sorted { $0.sortOrder > $1.sortOrder } // Higher sortOrder first (10th Keup -> 1st Dan)
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
        userProfile = dataManager.getOrCreateDefaultUserProfile()
        
        if let profile = userProfile {
            selectedBeltLevel = profile.currentBeltLevel
            selectedLearningMode = profile.learningMode
            dailyStudyGoal = profile.dailyStudyGoal
        }
    }
    
    private func saveSettings() {
        guard let profile = userProfile,
              let belt = selectedBeltLevel else { return }
        
        profile.currentBeltLevel = belt
        profile.learningMode = selectedLearningMode
        profile.dailyStudyGoal = dailyStudyGoal
        profile.updatedAt = Date()
        
        do {
            try dataManager.modelContainer.mainContext.save()
            dismiss()
        } catch {
            print("Failed to save settings: \(error)")
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
            .withDataContext()
    }
}