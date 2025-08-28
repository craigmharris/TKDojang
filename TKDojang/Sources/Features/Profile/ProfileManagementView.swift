import SwiftUI
import SwiftData

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
                                .background(Color.white.clipShape(Circle()))
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

#Preview {
    ProfileManagementView()
        
}