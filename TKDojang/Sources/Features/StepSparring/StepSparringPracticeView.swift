import SwiftUI

/**
 * StepSparringPracticeView.swift
 * 
 * PURPOSE: Interactive step-by-step sparring practice interface
 * 
 * FEATURES:
 * - Step-by-step progression through attack/defense sequences
 * - Detailed technique breakdowns with Korean terminology
 * - Visual progress tracking within sequence
 * - Practice session recording and progress updates
 * - Support for imagery and future video content
 */

struct StepSparringPracticeView: View {
    let sequence: StepSparringSequence
    
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStepIndex = 0
    // Removed showingAttack - now displaying both attack and defense simultaneously
    @State private var userProfile: UserProfile?
    @State private var progress: UserStepSparringProgress?
    @State private var practiceStartTime = Date()
    @State private var showingCompletion = false
    @State private var sessionCompleted = false
    
    private var currentStep: StepSparringStep? {
        guard currentStepIndex < sequence.steps.count else { return nil }
        return sequence.steps[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        currentStepIndex >= sequence.steps.count - 1
    }
    
    private var hasCounterAttack: Bool {
        currentStep?.counterAction != nil
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            practiceHeader
            
            // Main content area
            ScrollView {
                VStack(spacing: 24) {
                    // Current technique display
                    if let step = currentStep {
                        techniqueDisplayCard(for: step)
                    }
                    
                    // Navigation controls
                    navigationControls
                    
                    // Step summary (key points and common mistakes)
                    if let step = currentStep {
                        stepGuidanceCard(for: step)
                    }
                }
                .padding()
            }
            
            // Bottom action bar
            bottomActionBar
        }
        .navigationTitle(sequence.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Exit") {
                    if !sessionCompleted {
                        recordPracticeSession()
                    }
                    dismiss()
                }
                .foregroundColor(.primary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileSwitcher()
            }
        }
        .sheet(isPresented: $showingCompletion) {
            PracticeCompletionView(
                sequence: sequence,
                practiceTime: Date().timeIntervalSince(practiceStartTime),
                onDismiss: {
                    showingCompletion = false
                    dismiss()
                }
            )
        }
        .task {
            loadUserData()
        }
    }
    
    // MARK: - Header
    
    private var practiceHeader: some View {
        VStack(spacing: 12) {
            // Progress indicator
            HStack {
                Text("Step \(currentStepIndex + 1) of \(sequence.steps.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Attack & Defense")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
            }
            
            // Step progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * progressPercentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    private var progressPercentage: Double {
        let totalSteps = sequence.steps.count
        let completedSteps = currentStepIndex + 1 // Current step is considered in progress
        
        return totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0.0
    }
    
    // MARK: - Technique Display
    
    private func techniqueDisplayCard(for step: StepSparringStep) -> some View {
        return VStack(spacing: 16) {
            // Attack card (full width, red highlighting)
            TechniqueCard(action: step.attackAction, role: "Attack")
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 2)
                )
            
            // Defense card (full width, blue highlighting)
            TechniqueCard(action: step.defenseAction, role: "Defense")
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 2)
                )
            
            // Counter-attack card (full width, different blue shade) - counters only exist in final steps per JSON structure
            if let counter = step.counterAction {
                TechniqueCard(action: counter, role: "Counter-Attack")
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.7), lineWidth: 2)
                    )
            }
        }
    }
    
    // MARK: - Navigation Controls
    
    private var navigationControls: some View {
        VStack(spacing: 16) {
            // Step counter (centered, prominent)
            Text("Step \(currentStepIndex + 1) of \(sequence.totalSteps)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
            
            // Navigation buttons (equal width)
            HStack(spacing: 12) {
                // Previous button
                Button("Previous Step") {
                    goToPreviousStep()
                }
                .buttonStyle(.bordered)
                .disabled(currentStepIndex == 0)
                .frame(maxWidth: .infinity)
                
                // Next step or complete button
                if currentStepIndex < sequence.totalSteps - 1 {
                    Button("Next Step") {
                        goToNextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Complete") {
                        completeSequence()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var nextActionTitle: String {
        return isLastStep ? "Complete" : "Next Step"
    }
    
    // MARK: - Step Guidance
    
    private func stepGuidanceCard(for step: StepSparringStep) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Step \(step.stepNumber) Guidance")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Timing
            if !step.timing.isEmpty {
                GuidanceSection(title: "Timing", content: step.timing, icon: "clock")
            }
            
            // Key points
            if !step.keyPoints.isEmpty {
                GuidanceSection(title: "Key Points", content: step.keyPoints, icon: "star")
            }
            
            // Common mistakes
            if !step.commonMistakes.isEmpty {
                GuidanceSection(title: "Common Mistakes", content: step.commonMistakes, icon: "exclamationmark.triangle")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Bottom Action Bar
    
    private var bottomActionBar: some View {
        HStack {
            // Reset button
            Button("Restart") {
                restartSequence()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // Quick stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("Practice Time")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(formatPracticeTime())
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
    }
    
    // MARK: - Navigation Logic
    
    private func goToPreviousStep() {
        if currentStepIndex > 0 {
            currentStepIndex -= 1
        }
    }
    
    private func goToNextStep() {
        if currentStepIndex < sequence.totalSteps - 1 {
            currentStepIndex += 1
        }
    }
    
    private func completeSequence() {
        recordPracticeSession()
        sessionCompleted = true
        showingCompletion = true
    }
    
    private func restartSequence() {
        currentStepIndex = 0
        practiceStartTime = Date()
    }
    
    // MARK: - Data Management
    
    private func loadUserData() {
        // Clear existing data to prevent holding stale references
        userProfile = nil
        progress = nil
        
        userProfile = dataManager.profileService.getActiveProfile()
        if userProfile == nil {
            userProfile = dataManager.getOrCreateDefaultUserProfile()
        }
        
        if let profile = userProfile {
            do {
                progress = dataManager.stepSparringService.getUserProgress(for: sequence, userProfile: profile)
            } catch {
                print("❌ Failed to load user progress: \(error)")
                progress = nil
            }
        }
    }
    
    private func recordPracticeSession() {
        guard let profile = userProfile else { return }
        
        let duration = Date().timeIntervalSince(practiceStartTime)
        let stepsCompleted = sessionCompleted ? sequence.totalSteps : currentStepIndex
        
        dataManager.stepSparringService.recordPracticeSession(
            sequence: sequence,
            userProfile: profile,
            duration: duration,
            stepsCompleted: stepsCompleted
        )
    }
    
    private func formatPracticeTime() -> String {
        let duration = Date().timeIntervalSince(practiceStartTime)
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Components

struct TechniqueCard: View {
    let action: StepSparringAction
    let role: String
    
    private var roleColor: Color {
        switch role {
        case "Attack": return .red
        case "Defense": return .blue
        case "Counter-Attack": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(role)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(roleColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(roleColor.opacity(0.1))
                    .cornerRadius(16)
                
                Spacer()
            }
            
            // Technique name
            VStack(alignment: .leading, spacing: 8) {
                Text(action.technique)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !action.koreanName.isEmpty {
                    Text(action.koreanName)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            // Technical details (simplified)
            if !action.execution.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Execution")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(action.execution)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            // Description
            if !action.actionDescription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(action.actionDescription)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(roleColor.opacity(0.3), lineWidth: 2)
        )
    }
}

struct TechniqueDetail: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct GuidanceSection: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Completion View

struct PracticeCompletionView: View {
    let sequence: StepSparringSequence
    let practiceTime: TimeInterval
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                // Completion message
                VStack(spacing: 12) {
                    Text("Sequence Complete!")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("You've completed \(sequence.name)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Session stats
                VStack(spacing: 16) {
                    StatRow(label: "Practice Time", value: formatTime(practiceTime))
                    StatRow(label: "Steps Completed", value: "\(sequence.totalSteps)")
                    StatRow(label: "Sequence Type", value: sequence.type.displayName)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Practice Again") {
                        onDismiss()
                        // This will restart the sequence
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Continue Training") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .navigationTitle("Well Done!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}