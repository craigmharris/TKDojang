import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/**
 * ProfileManagementView.swift
 * 
 * PURPOSE: Main interface for managing multiple user profiles
 * 
 * FEATURES:
 * - Display all existing profiles with avatars and themes
 * - Profile selection and activation
 * - Profile creation, editing, and deletion
 * - Visual profile cards with statistics
 * - Family-friendly interface design
 * 
 * DESIGN DECISIONS:
 * - Card-based layout for visual appeal and easy selection
 * - Avatar and color theme prominently displayed
 * - Quick stats to show engagement per profile
 * - Maximum 6 profiles enforced with clear visual feedback
 */

struct ProfileManagementView: View {
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var profiles: [UserProfile] = []
    @State private var showingCreateProfile = false
    @State private var profileToEdit: UserProfile?
    @State private var profileToDelete: UserProfile?
    @State private var showingDeleteAlert = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    // Export/Import state
    @State private var showingExportOptions = false
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    @State private var fileToShare: URL?
    @State private var importResult: ImportResult?
    @State private var showingImportResult = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 20) {
                    ForEach(profiles) { profile in
                        ProfileCard(
                            profile: profile,
                            isActive: profile.isActive,
                            canDelete: !profile.isActive && profiles.count > 1,
                            onTap: {
                                activateProfile(profile)
                            },
                            onEdit: {
                                profileToEdit = profile
                            },
                            onDelete: {
                                profileToDelete = profile
                                showingDeleteAlert = true
                            }
                        )
                    }
                    
                    // Add New Profile Card
                    if profiles.count < 6 {
                        AddProfileCard {
                            showingCreateProfile = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Family Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showingImportPicker = true }) {
                            Label("Import Profiles", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { showingExportOptions = true }) {
                            Label("Export Profiles", systemImage: "square.and.arrow.up")
                        }
                        
                        // iCloud features - hidden when feature flag is disabled
                        if FeatureFlags.isiCloudEnabled {
                            Divider()
                            
                            Button(action: { exportToiCloud() }) {
                                Label("Backup to iCloud", systemImage: "icloud.and.arrow.up")
                            }
                            
                            Button(action: { showAvailableiCloudBackups() }) {
                                Label("Restore from iCloud", systemImage: "icloud.and.arrow.down")
                            }
                        }
                        
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export/Import")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfiles()
            }
            .onChange(of: dataServices.profileService.activeProfile) {
                loadProfiles()
            }
            .sheet(isPresented: $showingCreateProfile) {
                ProfileCreationView()
                    .onDisappear {
                        // Refresh profiles after the sheet disappears
                        loadProfiles()
                    }
            }
            .sheet(item: $profileToEdit) { profile in
                ProfileEditView(profile: profile)
                    .onDisappear {
                        // Refresh profiles after editing
                        loadProfiles()
                    }
            }
            .alert("Delete Profile", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        deleteProfile(profile)
                    }
                }
            } message: {
                if let profile = profileToDelete {
                    Text("Are you sure you want to delete '\(profile.name)'? This action cannot be undone and will remove all progress data.")
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            // Export/Import Sheets
            .confirmationDialog("Export Profiles", isPresented: $showingExportOptions) {
                Button("Export All Profiles") {
                    exportAllProfiles()
                }
                Button("Export Active Profile Only") {
                    if let activeProfile = dataServices.profileService.activeProfile {
                        exportSingleProfile(activeProfile)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [UTType(filenameExtension: "tkdprofile")!, UTType(filenameExtension: "tkdbackup")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let fileToShare = fileToShare {
                    ShareSheet(items: [fileToShare])
                }
            }
            .alert("Import Results", isPresented: $showingImportResult) {
                Button("OK") { }
            } message: {
                if let result = importResult {
                    Text(result.summary)
                }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
    
    private func loadProfiles() {
        do {
            profiles = try dataServices.profileService.getAllProfiles()
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func activateProfile(_ profile: UserProfile) {
        do {
            try dataServices.profileService.activateProfile(profile)
            loadProfiles() // Refresh to show active state
            
            // Dismiss after a short delay to show selection feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        } catch {
            errorMessage = "Failed to activate profile: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Export/Import Functions
    
    private func exportAllProfiles() {
        Task {
            do {
                let fileURL = try dataServices.profileExportService.saveAllProfilesToFile()
                DebugLogger.profile("✅ All profiles exported successfully to: \(fileURL.path)")
                DebugLogger.profile("📱 File ready for sharing - simulator file sharing may show errors but file creation succeeded")
                await MainActor.run {
                    self.fileToShare = fileURL
                    self.showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to export profiles: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func exportSingleProfile(_ profile: UserProfile) {
        Task {
            do {
                let fileURL = try dataServices.profileExportService.saveProfileToFile(profile)
                DebugLogger.profile("✅ Single profile exported successfully to: \(fileURL.path)")
                DebugLogger.profile("📱 File ready for sharing - simulator file sharing may show errors but file creation succeeded")
                await MainActor.run {
                    self.fileToShare = fileURL
                    self.showingShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to export profile: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        Task {
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                
                do {
                    let result = try dataServices.profileExportService.importProfileFromFile(fileURL, replaceExisting: false)
                    await MainActor.run {
                        self.importResult = result
                        self.showingImportResult = true
                        self.loadProfiles() // Refresh the profile list
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Failed to import profiles: \(error.localizedDescription)"
                        self.showingError = true
                    }
                }
                
            case .failure(let error):
                await MainActor.run {
                    self.errorMessage = "Failed to select file: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func exportToiCloud() {
        Task {
            do {
                _ = try dataServices.profileExportService.saveAllToiCloud()
                await MainActor.run {
                    // Show success message
                    self.errorMessage = "Successfully backed up all profiles to iCloud!"
                    self.showingError = true // Reusing error alert for success message
                }
            } catch {
                await MainActor.run {
                    if error is ProfileImportError && error.localizedDescription.contains("iCloud") {
                        self.errorMessage = "iCloud backup requires setup in Xcode project settings. See console for instructions."
                    } else {
                        self.errorMessage = "Failed to backup to iCloud: \(error.localizedDescription)"
                    }
                    self.showingError = true
                }
            }
        }
    }
    
    private func showAvailableiCloudBackups() {
        Task {
            do {
                let backups = try dataServices.profileExportService.listiCloudBackups()
                if backups.isEmpty {
                    await MainActor.run {
                        self.errorMessage = "No backups found in iCloud."
                        self.showingError = true
                    }
                } else {
                    // For now, restore the most recent backup
                    let mostRecentBackup = backups[0]
                    let result = try dataServices.profileExportService.importProfileFromFile(mostRecentBackup, replaceExisting: false)
                    await MainActor.run {
                        self.importResult = result
                        self.showingImportResult = true
                        self.loadProfiles()
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to access iCloud backups: \(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }
    
    private func deleteProfile(_ profile: UserProfile) {
        do {
            try dataServices.profileService.deleteProfile(profile)
            loadProfiles()
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
            showingError = true
        }
        profileToDelete = nil
    }
}

// MARK: - Profile Card Component

struct ProfileCard: View {
    let profile: UserProfile
    let isActive: Bool
    let canDelete: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar and Active Indicator
            ZStack {
                Circle()
                    .fill(profile.colorTheme.primarySwiftUIColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: profile.avatar.rawValue)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
                
                if isActive {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .background(Color(UIColor.systemBackground).clipShape(Circle()))
                        }
                    }
                }
            }
            
            // Profile Info
            VStack(spacing: 4) {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(profile.currentBeltLevel.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Quick Stats
                HStack(spacing: 12) {
                    StatItem(
                        icon: "flame.fill",
                        value: "\(profile.streakDays)",
                        label: "day streak",
                        color: .orange
                    )
                    
                    StatItem(
                        icon: "clock.fill",
                        value: profile.recentActivity.formattedWeeklyStudyTime,
                        label: "this week",
                        color: .blue
                    )
                }
                .font(.caption2)
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                if canDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isActive ? profile.colorTheme.primarySwiftUIColor.opacity(0.3) : Color.black.opacity(0.1),
                    radius: isActive ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? profile.colorTheme.primarySwiftUIColor : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isActive ? 1.02 : 1.0)
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Add Profile Card Component

struct AddProfileCard: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [8]))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                )
            
            VStack(spacing: 4) {
                Text("Add Profile")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("Up to 6 profiles")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(height: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Stat Item Component

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .fontWeight(.medium)
            }
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - ShareSheet Component

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Handle iOS Simulator limitations gracefully
        #if targetEnvironment(simulator)
        controller.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let error = error {
                DebugLogger.profile("⚠️ Simulator sharing error (expected): \(error.localizedDescription)")
            } else {
                DebugLogger.profile("✅ Export file created successfully - Simulator sharing limitations are normal")
            }
        }
        #endif
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    ProfileManagementView()
        
}