import SwiftUI

/**
 * PatternPracticeView.swift
 * 
 * PURPOSE: Interactive pattern practice interface with step-by-step guidance
 * 
 * FEATURES:
 * - Step-by-step move navigation with optimized single-screen layout
 * - Move descriptions and key points in compact instruction cards
 * - Belt-themed progress tracking with BeltProgressBar
 * - Visual feedback for current position
 * - Integration with user progress system
 * - Complete Pattern navigation: "Record Progress" returns to list, "Practice Again" restarts
 * 
 * RECENT ENHANCEMENTS:
 * - Replaced plain progress bar with belt-themed design showing proper tag belt colors
 * - Streamlined navigation controls with proper completion dialog behavior
 * - Optimized layout to fit pattern practice on single screen without scrolling
 */

struct PatternPracticeView: View {
    let pattern: Pattern
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentMoveIndex = 0
    @State private var userProfile: UserProfile?
    @State private var practiceStartTime = Date()
    @State private var showingCompleteDialog = false
    @State private var practiceAccuracy: Double = 0.0
    @State private var userProgress: UserPatternProgress?
    
    private var currentMove: PatternMove? {
        guard currentMoveIndex < pattern.orderedMoves.count else { return nil }
        return pattern.orderedMoves[currentMoveIndex]
    }
    
    private var isLastMove: Bool {
        currentMoveIndex >= pattern.orderedMoves.count - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader
            
            // Main content - optimized for single screen viewing
            if let move = currentMove {
                VStack(spacing: 12) {
                    // Move overview card
                    moveOverviewCard(move: move)
                        .padding(.horizontal)
                    
                    // Detailed instructions in compact scrollable layout
                    ScrollView {
                        moveInstructionsSection(move: move)
                            .padding(.horizontal)
                    }
                    
                    // Navigation controls - fixed at bottom
                    practiceControls
                        .padding(.bottom, 8)
                }
            } else {
                // Completion state
                completionView
            }
        }
        .navigationTitle("Practice \(pattern.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Practice") {
                    endPractice()
                }
                .foregroundColor(.red)
            }
        }
        .task {
            loadUserProfile()
        }
        .alert("Practice Complete", isPresented: $showingCompleteDialog) {
            Button("Record Progress") {
                recordPracticeSession()
            }
            Button("Practice Again") {
                restartPractice()
            }
        } message: {
            Text("Congratulations! You've completed the \(pattern.name) pattern.")
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Progress bar
            HStack {
                Text("Move \(currentMoveIndex + 1) of \(pattern.moveCount)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Visual progress - belt-themed design
            BeltProgressBar(
                progress: progressPercentage,
                theme: BeltTheme(from: pattern.primaryBeltLevel ?? pattern.beltLevels.first!)
            )
            .frame(height: 6)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var progressPercentage: Double {
        guard pattern.moveCount > 0 else { return 0 }
        return Double(currentMoveIndex + 1) / Double(pattern.moveCount)
    }
    
    // MARK: - Move Overview Card
    
    private func moveOverviewCard(move: PatternMove) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(move.displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(move.fullDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Move number badge
                Text("\(move.moveNumber)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            
            // Quick info
            HStack(spacing: 20) {
                infoItem("Stance", move.stance)
                infoItem("Direction", move.direction)
                if let target = move.target {
                    infoItem("Target", target)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private func infoItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
    // MARK: - Move Instructions Section
    
    private func moveInstructionsSection(move: PatternMove) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Key points - always shown, compact
            compactInstructionCard(
                title: "Key Points",
                content: move.keyPoints,
                icon: "target",
                color: .blue
            )
            
            // Common mistakes (if available) - compact
            if let mistakes = move.commonMistakes, !mistakes.isEmpty {
                compactInstructionCard(
                    title: "Avoid",
                    content: mistakes,
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
            }
            
            // Execution notes (if available) - compact
            if let notes = move.executionNotes, !notes.isEmpty {
                compactInstructionCard(
                    title: "Tips",
                    content: notes,
                    icon: "lightbulb",
                    color: .green
                )
            }
        }
    }
    
    private func compactInstructionCard(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(content)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
                .minimumScaleFactor(0.9)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    // MARK: - Practice Controls
    
    private var practiceControls: some View {
        HStack(spacing: 16) {
            Button("Previous Move") {
                previousMove()
            }
            .disabled(currentMoveIndex == 0)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            if isLastMove {
                Button("Complete Pattern") {
                    completePattern()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
            } else {
                Button("Next Move") {
                    nextMove()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Pattern Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("You've successfully completed the \(pattern.name) pattern.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Button("Record Progress") {
                    recordPracticeSession()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                
                Button("Practice Again") {
                    restartPractice()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadUserProfile() {
        userProfile = dataServices.getOrCreateDefaultUserProfile()
        if let profile = userProfile {
            // Load or create pattern progress
            userProgress = dataServices.patternService.getUserProgress(for: pattern, userProfile: profile)
            // Set current move index to last practiced position (0-based vs 1-based)
            if let progress = userProgress, progress.currentMove > 1 {
                currentMoveIndex = max(0, progress.currentMove - 1)
            }
        }
    }
    
    
    private func nextMove() {
        if currentMoveIndex < pattern.orderedMoves.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMoveIndex += 1
                // Update pattern progress in database
                updatePatternProgress()
            }
        }
    }
    
    private func previousMove() {
        if currentMoveIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMoveIndex -= 1
                // Update pattern progress in database
                updatePatternProgress()
            }
        }
    }
    
    private func completePattern() {
        showingCompleteDialog = true
    }
    
    private func restartPractice() {
        // Reset to first move (move 1)
        currentMoveIndex = 0
        practiceStartTime = Date()
        showingCompleteDialog = false
        
        // Update pattern progress to reflect restart at move 1
        updatePatternProgress()
    }
    
    private func endPractice() {
        // Save current progress before leaving
        updatePatternProgress()
        dismiss()
    }
    
    private func updatePatternProgress() {
        guard let progress = userProgress else { return }
        
        // Update to current move (1-based indexing in database)
        progress.currentMove = currentMoveIndex + 1
        progress.lastPracticedAt = Date()
        
        // Note: Progress is automatically tracked via SwiftData model changes
    }
    
    private func recordPracticeSession() {
        guard let profile = userProfile else { return }
        
        let practiceTime = Date().timeIntervalSince(practiceStartTime)
        let totalMoves = pattern.orderedMoves.count
        let completionAccuracy = 1.0 // Assume 100% for completing the pattern
        
        // Record in pattern service with proper accuracy and completion
        dataServices.patternService.recordPracticeSession(
            pattern: pattern,
            userProfile: profile,
            accuracy: completionAccuracy,
            practiceTime: practiceTime
        )
        
        // Update pattern progress to show full completion
        if let progress = userProgress {
            progress.currentMove = totalMoves // Mark as fully completed
            
            // Note: Pattern completion is tracked automatically
        }
        
        // Also record in general study session tracking
        do {
            try dataServices.profileService.recordStudySession(
                sessionType: .patterns,
                itemsStudied: totalMoves,
                correctAnswers: totalMoves, // Full pattern completed
                focusAreas: [pattern.name]
            )
        } catch {
            print("❌ Failed to record pattern study session: \(error)")
        }
        
        // Return to pattern list after recording progress
        dismiss()
    }
}

// MARK: - Preview

struct PatternPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview would need mock data
        Text("PatternPracticeView Preview")
    }
}