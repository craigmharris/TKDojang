import SwiftUI
import SwiftData

/**
 * ProfileSwitcher.swift
 * 
 * PURPOSE: Compact profile switching interface for app navigation
 * 
 * FEATURES:
 * - Quick profile switching from any screen
 * - Current profile display with avatar and name
 * - Access to full profile management
 * - Compact design suitable for toolbars/navigation
 * 
 * DESIGN DECISIONS:
 * - Menu-style interface for space efficiency
 * - Visual profile indicators with avatars
 * - Quick access to profile management
 * - Consistent with system design patterns
 */

struct ProfileSwitcher: View {
    @EnvironmentObject private var dataServices: DataServices
    
    @State private var profiles: [UserProfile] = []
    @State private var activeProfile: UserProfile?
    @State private var showingProfileManagement = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    var body: some View {
        let _ = print("🔄 ProfileSwitcher: Rendering menu with \(profiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        
        Menu {
            // All Profiles with Current Selection Indicator
            Section("Family Profiles") {
                ForEach(profiles) { profile in
                    Button(action: {
                        let isCurrentlyActive = (activeProfile?.id == profile.id)
                        print("🔍 ProfileSwitcher: Tapped profile \(profile.name), isCurrentlyActive: \(isCurrentlyActive)")
                        if !isCurrentlyActive {
                            switchToProfile(profile)
                        } else {
                            print("⚠️ ProfileSwitcher: Profile \(profile.name) is already active, ignoring tap")
                        }
                    }) {
                        HStack {
                            Label {
                                VStack(alignment: .leading) {
                                    Text(profile.name)
                                        .fontWeight((activeProfile?.id == profile.id) ? .semibold : .regular)
                                    Text(profile.currentBeltLevel.shortName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: profile.avatar.rawValue)
                                    .foregroundColor(profile.colorTheme.primarySwiftUIColor)
                            }
                            
                            Spacer()
                            
                            // Current selection indicator
                            if activeProfile?.id == profile.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Profile Management
            Section {
                Button {
                    showingProfileManagement = true
                } label: {
                    Label("Manage Profiles", systemImage: "person.2.fill")
                }
            }
            
        } label: {
            ProfileSwitcherButton(activeProfile: activeProfile)
        }
        .onAppear {
            loadProfiles()
        }
        .onReceive(dataServices.objectWillChange) { _ in
            loadProfiles()
        }
        .sheet(isPresented: $showingProfileManagement) {
            ProfileManagementView()
                .onDisappear {
                    loadProfiles()
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
    
    private func loadProfiles() {
        do {
            profiles = try dataServices.profileService.getAllProfiles()
            activeProfile = dataServices.profileService.getActiveProfile()
            print("🔄 ProfileSwitcher: Loaded \(profiles.count) profiles, active: \(activeProfile?.name ?? "none")")
        } catch {
            errorMessage = "Failed to load profiles: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func switchToProfile(_ profile: UserProfile) {
        do {
            print("🔄 ProfileSwitcher: Switching to profile: \(profile.name)")
            try dataServices.profileService.activateProfile(profile)
            
            // Immediately update local state
            loadProfiles()
            
            // Notify other views
            dataServices.objectWillChange.send()
            print("✅ ProfileSwitcher: Profile switch completed")
        } catch {
            print("❌ ProfileSwitcher: Failed to switch profile: \(error)")
            errorMessage = "Failed to switch profile: \(error.localizedDescription)"
            showingError = true
        }
    }
}

// MARK: - Profile Switcher Button

struct ProfileSwitcherButton: View {
    let activeProfile: UserProfile?
    
    var body: some View {
        HStack(spacing: 8) {
            if let profile = activeProfile {
                // Profile Avatar
                Circle()
                    .fill(profile.colorTheme.primarySwiftUIColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: profile.avatar.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Profile Name (on larger screens)
                if UIDevice.current.userInterfaceIdiom != .phone {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(profile.currentBeltLevel.shortName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Default/Loading state
                Circle()
                    .fill(Color.gray)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    )
            }
            
            // Dropdown indicator
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .overlay(
                    // Subtle active indicator border
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(activeProfile?.colorTheme.primarySwiftUIColor.opacity(0.3) ?? Color.clear, lineWidth: 1)
                )
        )
    }
}

// MARK: - Compact Profile Card (for menus)

struct CompactProfileCard: View {
    let profile: UserProfile
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(profile.colorTheme.primarySwiftUIColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: profile.avatar.rawValue)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                )
            
            // Profile Info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(profile.currentBeltLevel.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active indicator
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        VStack {
            Text("Sample Screen")
                .navigationTitle("TKDojang")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProfileSwitcher()
                    }
                }
        }
    }
}