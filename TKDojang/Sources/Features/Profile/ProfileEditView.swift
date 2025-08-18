import SwiftUI
import SwiftData

/**
 * ProfileEditView.swift
 * 
 * PURPOSE: Edit existing user profile settings and personalization
 * 
 * FEATURES:
 * - Edit profile name with validation
 * - Change avatar and color theme
 * - Update belt level progression
 * - Adjust learning preferences
 * - Real-time profile preview
 * - Form validation and error handling
 * 
 * DESIGN DECISIONS:
 * - Similar layout to creation view for consistency
 * - Pre-populated with current profile data
 * - Clear indication of unsaved changes
 * - Safe editing with proper validation
 */

struct ProfileEditView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss
    
    let profile: UserProfile
    
    @State private var name: String
    @State private var selectedAvatar: ProfileAvatar
    @State private var selectedColorTheme: ProfileColorTheme
    @State private var selectedBeltLevel: BeltLevel
    @State private var selectedLearningMode: LearningMode
    @State private var dailyStudyGoal: Double
    
    @State private var availableBeltLevels: [BeltLevel] = []
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var isSaving = false
    
    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _selectedAvatar = State(initialValue: profile.avatar)
        _selectedColorTheme = State(initialValue: profile.colorTheme)
        _selectedBeltLevel = State(initialValue: profile.currentBeltLevel)
        _selectedLearningMode = State(initialValue: profile.learningMode)
        _dailyStudyGoal = State(initialValue: Double(profile.dailyStudyGoal))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Preview
                    ProfilePreview(
                        name: name.isEmpty ? "Profile" : name,
                        avatar: selectedAvatar,
                        colorTheme: selectedColorTheme,
                        beltLevel: selectedBeltLevel
                    )
                    
                    // Edit Form
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
                            Text("Avatar")
                                .font(.headline)
                            
                            ProfileAvatarPicker(
                                selectedAvatar: $selectedAvatar,
                                colorTheme: selectedColorTheme
                            )
                        }
                        
                        Divider()
                        
                        // Color Theme Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Color Theme")
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
                                    selectedBeltLevel: Binding(
                                        get: { selectedBeltLevel },
                                        set: { if let newValue = $0 { selectedBeltLevel = newValue } }
                                    ),
                                    availableBeltLevels: availableBeltLevels
                                )
                            }
                            
                            Text("Update your belt level as you progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        // Learning Mode Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Learning Focus")
                                .font(.headline)
                            
                            Picker("Learning Mode", selection: $selectedLearningMode) {
                                ForEach(LearningMode.allCases, id: \.self) { mode in
                                    VStack(alignment: .leading) {
                                        Text(mode.displayName)
                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .tag(mode)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        Divider()
                        
                        // Daily Study Goal
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Study Goal")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Study \(Int(dailyStudyGoal)) terms per day")
                                        .font(.subheadline)
                                    Spacer()
                                }
                                
                                Slider(value: $dailyStudyGoal, in: 5...50, step: 5) {
                                    Text("Terms per day")
                                } minimumValueLabel: {
                                    Text("5")
                                        .font(.caption)
                                } maximumValueLabel: {
                                    Text("50")
                                        .font(.caption)
                                }
                            }
                            
                            Text("Set a realistic daily goal to maintain consistent progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Profile Statistics (Read-only)
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Profile Statistics")
                                .font(.headline)
                            
                            ProfileStatsView(profile: profile)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!isFormValid || !hasChanges)
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
            .disabled(isSaving)
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        name.count <= 20 &&
        !isSaving
    }
    
    private var hasChanges: Bool {
        name != profile.name ||
        selectedAvatar != profile.avatar ||
        selectedColorTheme != profile.colorTheme ||
        selectedBeltLevel.id != profile.currentBeltLevel.id ||
        selectedLearningMode != profile.learningMode ||
        Int(dailyStudyGoal) != profile.dailyStudyGoal
    }
    
    private func loadBeltLevels() {
        let descriptor = FetchDescriptor<BeltLevel>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        
        do {
            availableBeltLevels = try dataManager.modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load belt levels: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        do {
            try dataManager.profileService.updateProfile(
                profile,
                name: name.trimmingCharacters(in: .whitespaces),
                avatar: selectedAvatar,
                colorTheme: selectedColorTheme,
                beltLevel: selectedBeltLevel,
                learningMode: selectedLearningMode
            )
            
            // Update daily study goal directly
            profile.dailyStudyGoal = Int(dailyStudyGoal)
            try dataManager.modelContext.save()
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            isSaving = false
        }
    }
}

// MARK: - Profile Stats Component

struct ProfileStatsView: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 12) {
            // Study Statistics
            HStack {
                StatCard(
                    title: "Study Streak",
                    value: "\(profile.streakDays)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Study Time",
                    value: String(format: "%.1f", profile.totalStudyTime / 3600),
                    subtitle: "hours",
                    icon: "clock.fill",
                    color: .blue
                )
            }
            
            HStack {
                StatCard(
                    title: "Flashcards Seen",
                    value: "\(profile.totalFlashcardsSeen)",
                    subtitle: "terms",
                    icon: "rectangle.on.rectangle",
                    color: .green
                )
                
                StatCard(
                    title: "Tests Taken",
                    value: "\(profile.totalTestsTaken)",
                    subtitle: "tests",
                    icon: "checkmark.circle.fill",
                    color: .purple
                )
            }
            
            // Profile Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Created")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(profile.createdAt, style: .date)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(profile.lastActiveAt, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
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
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let _ = DataManager.shared
    let profile = UserProfile(
        name: "Test User",
        avatar: .student1,
        colorTheme: .blue,
        currentBeltLevel: BeltLevel(name: "10th Keup", shortName: "10th Keup", colorName: "White", sortOrder: 15, isKyup: true),
        learningMode: .mastery
    )
    
    return ProfileEditView(profile: profile)
        .withDataContext()
}