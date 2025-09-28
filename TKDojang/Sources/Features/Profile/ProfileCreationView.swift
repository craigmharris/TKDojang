import SwiftUI
import SwiftData

/**
 * ProfileCreationView.swift
 * 
 * PURPOSE: Create new user profiles with personalization options
 * 
 * FEATURES:
 * - Name input with validation
 * - Avatar selection from martial arts themed options
 * - Color theme selection with preview
 * - Belt level selection
 * - Real-time profile preview
 * - Form validation and error handling
 * 
 * DESIGN DECISIONS:
 * - Step-by-step creation flow for better UX
 * - Visual preview of profile as it's being created
 * - Family-friendly avatar and theme options
 * - Clear validation messages and constraints
 */

struct ProfileCreationView: View {
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedAvatar: ProfileAvatar = .student1
    @State private var selectedColorTheme: ProfileColorTheme = .blue
    @State private var selectedBeltLevel: BeltLevel?
    @State private var availableBeltLevels: [BeltLevel] = []
    
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Preview
                    ProfilePreview(
                        name: name.isEmpty ? "New Profile" : name,
                        avatar: selectedAvatar,
                        colorTheme: selectedColorTheme,
                        beltLevel: selectedBeltLevel
                    )
                    
                    // Creation Form
                    VStack(alignment: .leading, spacing: 20) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile Name")
                                .font(.headline)
                            
                            TextField("Enter name", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocorrectionDisabled()
                            
                            Text("Choose a name for this profile (up to 20 characters)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Avatar Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Avatar")
                                .font(.headline)
                            
                            ProfileAvatarPicker(
                                selectedAvatar: $selectedAvatar,
                                colorTheme: selectedColorTheme
                            )
                        }
                        
                        Divider()
                        
                        // Color Theme Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Theme")
                                .font(.headline)
                            
                            ProfileColorThemePicker(
                                selectedTheme: $selectedColorTheme
                            )
                        }
                        
                        Divider()
                        
                        // Belt Level Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Current Belt Level")
                                .font(.headline)
                            
                            if availableBeltLevels.isEmpty {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else {
                                BeltLevelPicker(
                                    selectedBeltLevel: $selectedBeltLevel,
                                    availableBeltLevels: availableBeltLevels
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createProfile()
                    }
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                loadBeltLevels()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .disabled(isCreating)
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        name.count <= 20 &&
        selectedBeltLevel != nil &&
        !isCreating
    }
    
    private func loadBeltLevels() {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        
        do {
            availableBeltLevels = try dataServices.modelContext.fetch(descriptor)
            // Default to white belt (10th Keup) - should now be first in the list
            selectedBeltLevel = availableBeltLevels.first { $0.shortName.contains("10th Keup") } ?? availableBeltLevels.first
        } catch {
            errorMessage = "Failed to load belt levels: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func createProfile() {
        guard let beltLevel = selectedBeltLevel else {
            errorMessage = "Please select a belt level"
            showingError = true
            return
        }
        
        isCreating = true
        
        do {
            _ = try dataServices.profileService.createProfile(
                name: name.trimmingCharacters(in: .whitespaces),
                avatar: selectedAvatar,
                colorTheme: selectedColorTheme,
                beltLevel: beltLevel
            )
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isCreating = false
        }
    }
}

// MARK: - Profile Preview Component

struct ProfilePreview: View {
    let name: String
    let avatar: ProfileAvatar
    let colorTheme: ProfileColorTheme
    let beltLevel: BeltLevel?
    
    var body: some View {
        VStack(spacing: 16) {
            // Large Avatar
            ZStack {
                Circle()
                    .fill(colorTheme.primarySwiftUIColor)
                    .frame(width: 120, height: 120)
                
                Image(systemName: avatar.rawValue)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Profile Info
            VStack(spacing: 4) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let beltLevel = beltLevel {
                    Text(beltLevel.shortName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(colorTheme.displayName)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(colorTheme.primarySwiftUIColor.opacity(0.2))
                    .foregroundColor(colorTheme.primarySwiftUIColor)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

// MARK: - Avatar Picker Component

struct ProfileAvatarPicker: View {
    @Binding var selectedAvatar: ProfileAvatar
    let colorTheme: ProfileColorTheme
    
    private let avatars = ProfileAvatar.allCases
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(avatars, id: \.self) { avatar in
                AvatarOption(
                    avatar: avatar,
                    colorTheme: colorTheme,
                    isSelected: selectedAvatar == avatar
                ) {
                    selectedAvatar = avatar
                }
            }
        }
    }
}

struct AvatarOption: View {
    let avatar: ProfileAvatar
    let colorTheme: ProfileColorTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(colorTheme.primarySwiftUIColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: avatar.rawValue)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                if isSelected {
                    Circle()
                        .stroke(colorTheme.primarySwiftUIColor, lineWidth: 3)
                        .frame(width: 68, height: 68)
                }
            }
            
            VStack(spacing: 2) {
                Text(avatar.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(avatar.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 32)
        }
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Color Theme Picker Component

struct ProfileColorThemePicker: View {
    @Binding var selectedTheme: ProfileColorTheme
    
    private let themes = ProfileColorTheme.allCases
    private let columns = Array(repeating: GridItem(.flexible()), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(themes, id: \.self) { theme in
                ColorThemeOption(
                    theme: theme,
                    isSelected: selectedTheme == theme
                ) {
                    selectedTheme = theme
                }
            }
        }
    }
}

struct ColorThemeOption: View {
    let theme: ProfileColorTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Primary color circle
                Circle()
                    .fill(theme.primarySwiftUIColor)
                    .frame(width: 48, height: 48)
                
                // Secondary color accent
                Circle()
                    .fill(theme.secondarySwiftUIColor)
                    .frame(width: 16, height: 16)
                    .offset(x: 12, y: -12)
                
                if isSelected {
                    Circle()
                        .stroke(Color.primary, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }
            }
            
            Text(theme.displayName)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .multilineTextAlignment(.center)
        }
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Belt Level Picker Component

struct BeltLevelPicker: View {
    @Binding var selectedBeltLevel: BeltLevel?
    let availableBeltLevels: [BeltLevel]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableBeltLevels, id: \.id) { beltLevel in
                    BeltLevelOption(
                        beltLevel: beltLevel,
                        isSelected: selectedBeltLevel?.id == beltLevel.id
                    ) {
                        selectedBeltLevel = beltLevel
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct BeltLevelOption: View {
    let beltLevel: BeltLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    private var hasTagStripe: Bool {
        let primaryHex = beltLevel.primaryColor ?? "#000000"
        let secondaryHex = beltLevel.secondaryColor ?? "#000000"
        return primaryHex != secondaryHex
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Belt representation with tag stripe
            ZStack {
                // Base belt color
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(beltLevel.primaryColor ?? "#000000"))
                    .frame(width: 60, height: 12)
                
                // Tag stripe if belt has secondary color
                if hasTagStripe {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(beltLevel.secondaryColor ?? "#000000"))
                        .frame(width: 50, height: 4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
            
            Text(beltLevel.shortName)
                .font(.caption2)
                .fontWeight(isSelected ? .semibold : .medium)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
        .onTapGesture {
            onTap()
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ProfileCreationView()
        
}