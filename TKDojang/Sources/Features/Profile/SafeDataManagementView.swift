import SwiftUI
import SwiftData

/**
 * SafeDataManagementView.swift
 * 
 * PURPOSE: Provides safe, granular data management options for multi-profile families
 * 
 * FEATURES:
 * - Individual profile deletion with safeguards
 * - Granular progress reset options per profile
 * - Multiple confirmation dialogs for destructive actions
 * - Data export/backup options
 * - Advanced system reset (heavily protected)
 */

struct SafeDataManagementView: View {
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var profiles: [UserProfile] = []
    @State private var showingDeleteProfileAlert = false
    @State private var showingResetProgressAlert = false
    @State private var showingSystemResetAlert = false
    @State private var selectedProfile: UserProfile?
    @State private var resetType: ProgressResetType = .all
    @State private var systemResetConfirmation = ""
    @State private var profileDeleteConfirmation = ""
    
    var body: some View {
        NavigationView {
            List {
                // Profile Management Section
                Section("Profile Management") {
                    ForEach(profiles) { profile in
                        ProfileManagementRow(
                            profile: profile,
                            canDelete: profiles.count > 1,
                            onDelete: {
                                selectedProfile = profile
                                showingDeleteProfileAlert = true
                            },
                            onResetProgress: {
                                selectedProfile = profile
                                showingResetProgressAlert = true
                            }
                        )
                    }
                }
                
                // Data Export Section
                Section("Data Backup") {
                    Button("Export All Profiles") {
                        exportAllProfilesData()
                    }
                    .foregroundColor(.blue)
                    
                    Text("Export profile data for backup or transfer to another device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Advanced System Management (Dangerous)
                Section("Advanced System Management") {
                    DisclosureGroup("⚠️ Dangerous Operations") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("These operations affect ALL profiles and are irreversible!")
                                .font(.caption)
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                            
                            Button("Reset Entire System") {
                                showingSystemResetAlert = true
                            }
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfiles()
            }
            
            // Profile Deletion Alert
            .alert("Delete Profile", isPresented: $showingDeleteProfileAlert) {
                TextField("Type profile name to confirm", text: $profileDeleteConfirmation)
                Button("Cancel", role: .cancel) {
                    profileDeleteConfirmation = ""
                    selectedProfile = nil
                }
                Button("Delete", role: .destructive) {
                    if profileDeleteConfirmation == selectedProfile?.name {
                        deleteProfile()
                    }
                }
                .disabled(profileDeleteConfirmation != selectedProfile?.name)
            } message: {
                if let profile = selectedProfile {
                    Text("This will permanently delete '\(profile.name)' and ALL their progress data.\n\nType '\(profile.name)' to confirm deletion.")
                }
            }
            
            // Progress Reset Alert
            .alert("Reset Progress", isPresented: $showingResetProgressAlert) {
                Button("Cancel", role: .cancel) {
                    selectedProfile = nil
                    resetType = .all
                }
                Button("Reset", role: .destructive) {
                    resetProfileProgress()
                }
            } message: {
                if let profile = selectedProfile {
                    Text("Reset \(resetType.description.lowercased()) for '\(profile.name)'?\n\nThis action cannot be undone.")
                }
            }
            
            // System Reset Alert (Multiple Confirmations)
            .alert("⚠️ SYSTEM RESET WARNING", isPresented: $showingSystemResetAlert) {
                TextField("Type 'DELETE ALL DATA' to confirm", text: $systemResetConfirmation)
                Button("Cancel", role: .cancel) {
                    systemResetConfirmation = ""
                }
                Button("RESET SYSTEM", role: .destructive) {
                    if systemResetConfirmation == "DELETE ALL DATA" {
                        performSystemReset()
                    }
                }
                .disabled(systemResetConfirmation != "DELETE ALL DATA")
            } message: {
                Text("⚠️ THIS WILL DELETE ALL PROFILES AND ALL PROGRESS DATA!\n\n• All family members will lose their progress\n• All test results will be deleted\n• All pattern progress will be lost\n• This action cannot be undone\n\nType 'DELETE ALL DATA' to confirm.")
            }
        }
    }
    
    // MARK: - Data Operations
    
    private func loadProfiles() {
        do {
            let descriptor = FetchDescriptor<UserProfile>(
                sortBy: [SortDescriptor(\.name)]
            )
            profiles = try dataServices.modelContext.fetch(descriptor)
        } catch {
            DebugLogger.profile("❌ Failed to load profiles: \(error)")
        }
    }
    
    private func deleteProfile() {
        guard let profile = selectedProfile,
              profiles.count > 1 else { return }
        
        do {
            dataServices.modelContext.delete(profile)
            try dataServices.modelContext.save()
            
            // If we deleted the active profile, set another as active
            if dataServices.profileService.getActiveProfile()?.id == profile.id {
                let remainingProfiles = profiles.filter { $0.id != profile.id }
                if let newActiveProfile = remainingProfiles.first {
                    try? dataServices.profileService.activateProfile(newActiveProfile)
                }
            }
            
            loadProfiles()
            DebugLogger.profile("✅ Profile deleted successfully")
        } catch {
            DebugLogger.profile("❌ Failed to delete profile: \(error)")
        }
        
        profileDeleteConfirmation = ""
        selectedProfile = nil
    }
    
    private func resetProfileProgress() {
        guard let profile = selectedProfile else { return }
        
        do {
            switch resetType {
            case .all:
                resetAllProgress(for: profile)
            case .terminology:
                resetTerminologyProgress(for: profile)
            case .patterns:
                resetPatternProgress(for: profile)
            case .stepSparring:
                resetStepSparringProgress(for: profile)
            case .tests:
                resetTestResults(for: profile)
            }
            
            try dataServices.modelContext.save()
            DebugLogger.profile("✅ Progress reset successfully")
        } catch {
            DebugLogger.profile("❌ Failed to reset progress: \(error)")
        }
        
        selectedProfile = nil
    }
    
    private func resetAllProgress(for profile: UserProfile) {
        // Reset all progress types
        resetTerminologyProgress(for: profile)
        resetPatternProgress(for: profile)
        resetStepSparringProgress(for: profile)
        resetTestResults(for: profile)
        
        // Reset profile statistics
        profile.totalStudyTime = 0
        profile.streakDays = 0
        profile.totalFlashcardsSeen = 0
        profile.totalTestsTaken = 0
        profile.totalPatternsLearned = 0
        profile.updatedAt = Date()
    }
    
    private func resetTerminologyProgress(for profile: UserProfile) {
        profile.terminologyProgress.forEach { progress in
            dataServices.modelContext.delete(progress)
        }
    }
    
    private func resetPatternProgress(for profile: UserProfile) {
        profile.patternProgress.forEach { progress in
            dataServices.modelContext.delete(progress)
        }
    }
    
    private func resetStepSparringProgress(for profile: UserProfile) {
        profile.stepSparringProgress.forEach { progress in
            dataServices.modelContext.delete(progress)
        }
    }
    
    private func resetTestResults(for profile: UserProfile) {
        // This would reset test sessions when that model supports multi-profile
        // For now, this is a placeholder
        DebugLogger.profile("⚠️ Test result reset not yet implemented for multi-profile")
    }
    
    private func exportAllProfilesData() {
        // Export all profile data for backup using ProfileExportService
        DebugLogger.data("📤 Exporting all profile data...")
        
        // Use the existing ProfileExportService through DataServices
        Task {
            do {
                let data = try dataServices.profileExportService.exportAllProfiles()
                DebugLogger.data("✅ All profiles exported successfully (\(data.count) bytes)")
            } catch {
                DebugLogger.data("❌ Profile export failed: \(error)")
            }
        }
    }
    
    private func performSystemReset() {
        // This is the dangerous nuclear option - only for extreme cases
        
        // Clear confirmation and dismiss this view immediately
        systemResetConfirmation = ""
        dismiss()
        
        // Start database reset immediately - the isResettingDatabase flag will
        // trigger the loading screen in ContentView to prevent any profile access
        Task {
            do {
                try await dataServices.resetAndReloadDatabase()
                DebugLogger.data("✅ Database reset completed successfully")
            } catch {
                DebugLogger.data("❌ Database reset failed: \(error)")
                // Show error to user through UI notification
                DispatchQueue.main.async {
                    // Could implement error notification system here
                    DebugLogger.ui("❌ Database reset failed - user should be notified")
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum ProgressResetType: CaseIterable {
    case all
    case terminology
    case patterns
    case stepSparring
    case tests
    
    var displayName: String {
        switch self {
        case .all: return "All Progress"
        case .terminology: return "Terminology Progress"
        case .patterns: return "Pattern Progress"
        case .stepSparring: return "Step Sparring Progress"
        case .tests: return "Test Results"
        }
    }
    
    var description: String {
        switch self {
        case .all: return "ALL progress data"
        case .terminology: return "terminology/flashcard progress"
        case .patterns: return "pattern learning progress"
        case .stepSparring: return "step sparring progress"
        case .tests: return "test results and scores"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "trash.fill"
        case .terminology: return "book.fill"
        case .patterns: return "figure.martial.arts"
        case .stepSparring: return "figure.2.arms.open"
        case .tests: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Profile Management Row

struct ProfileManagementRow: View {
    let profile: UserProfile
    let canDelete: Bool
    let onDelete: () -> Void
    let onResetProgress: () -> Void
    
    @State private var showingProgressResetOptions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile Header
            HStack {
                Image(systemName: profile.avatar.rawValue)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(profile.currentBeltLevel.shortName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if profile.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
            
            // Progress Summary
            HStack(spacing: 16) {
                ProfileStatView(
                    icon: "book.fill",
                    value: profile.totalFlashcardsSeen,
                    label: "Cards"
                )
                
                ProfileStatView(
                    icon: "checkmark.circle.fill", 
                    value: profile.totalTestsTaken,
                    label: "Tests"
                )
                
                ProfileStatView(
                    icon: "flame.fill",
                    value: profile.streakDays,
                    label: "Streak"
                )
            }
            .font(.caption)
            
            // Action Buttons
            HStack(spacing: 12) {
                // Progress Reset Options
                Button("Reset Progress...") {
                    showingProgressResetOptions = true
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                
                Spacer()
                
                // Delete Profile (if allowed)
                if canDelete {
                    Button("Delete Profile") {
                        onDelete()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                } else {
                    Text("Cannot delete only profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .actionSheet(isPresented: $showingProgressResetOptions) {
            ActionSheet(
                title: Text("Reset Progress for \(profile.name)"),
                message: Text("What would you like to reset?"),
                buttons: [
                    .destructive(Text("All Progress")) {
                        // This would trigger the main alert with resetType = .all
                        onResetProgress()
                    },
                    .destructive(Text("Terminology Only")) {
                        // resetType = .terminology and trigger alert
                    },
                    .destructive(Text("Patterns Only")) {
                        // resetType = .patterns and trigger alert
                    },
                    .destructive(Text("Step Sparring Only")) {
                        // resetType = .stepSparring and trigger alert  
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct ProfileStatView: View {
    let icon: String
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text("\(value)")
                    .fontWeight(.medium)
            }
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}