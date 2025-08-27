import SwiftUI

/**
 * PatternPracticeView.swift
 * 
 * PURPOSE: Interactive pattern practice interface with step-by-step guidance
 * 
 * FEATURES:
 * - Step-by-step move navigation
 * - Move descriptions and key points
 * - Progress tracking through the pattern
 * - Visual feedback for current position
 * - Integration with user progress system
 */

struct PatternPracticeView: View {
    let pattern: Pattern
    @Environment(DataManager.self) private var dataManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentMoveIndex = 0
    @State private var isPracticing = false
    @State private var userProfile: UserProfile?
    @State private var practiceStartTime = Date()
    @State private var showingCompleteDialog = false
    @State private var practiceAccuracy: Double = 0.0
    
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
            
            // Main content
            if let move = currentMove {
                ScrollView {
                    VStack(spacing: 24) {
                        // Move overview card
                        moveOverviewCard(move: move)
                        
                        // Move image (if available)
                        moveImageSection(move: move)
                        
                        // Detailed instructions
                        moveInstructionsSection(move: move)
                        
                        // Navigation and practice controls
                        practiceControls
                    }
                    .padding()
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
                
                if isPracticing {
                    Button("Pause") {
                        isPracticing = false
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
            
            // Visual progress
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progressPercentage, height: 6)
                }
            }
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
    
    // MARK: - Move Image Section
    
    private func moveImageSection(move: PatternMove) -> some View {
        Group {
            if let imageURL = move.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Loading move image...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        )
                }
                .frame(maxHeight: 250)
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "figure.martial.arts")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("Move Image Coming Soon")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Move Instructions Section
    
    private func moveInstructionsSection(move: PatternMove) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Key points
            instructionCard(
                title: "Key Points",
                content: move.keyPoints,
                icon: "target",
                color: .blue
            )
            
            // Common mistakes (if available)
            if let mistakes = move.commonMistakes, !mistakes.isEmpty {
                instructionCard(
                    title: "Common Mistakes",
                    content: mistakes,
                    icon: "exclamationmark.triangle",
                    color: .orange
                )
            }
            
            // Execution notes (if available)
            if let notes = move.executionNotes, !notes.isEmpty {
                instructionCard(
                    title: "Execution Notes",
                    content: notes,
                    icon: "lightbulb",
                    color: .green
                )
            }
        }
    }
    
    private func instructionCard(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Practice Controls
    
    private var practiceControls: some View {
        VStack(spacing: 16) {
            // Primary action button
            if !isPracticing {
                Button("Start Practice") {
                    startPractice()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .cornerRadius(12)
            }
            
            // Navigation buttons
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
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Next Move") {
                        nextMove()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
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
        userProfile = dataManager.getOrCreateDefaultUserProfile()
    }
    
    private func startPractice() {
        isPracticing = true
        practiceStartTime = Date()
    }
    
    private func nextMove() {
        if currentMoveIndex < pattern.orderedMoves.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMoveIndex += 1
            }
        }
    }
    
    private func previousMove() {
        if currentMoveIndex > 0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentMoveIndex -= 1
            }
        }
    }
    
    private func completePattern() {
        showingCompleteDialog = true
    }
    
    private func restartPractice() {
        currentMoveIndex = 0
        isPracticing = false
        practiceStartTime = Date()
        showingCompleteDialog = false
    }
    
    private func endPractice() {
        dismiss()
    }
    
    private func recordPracticeSession() {
        let practiceTime = Date().timeIntervalSince(practiceStartTime)
        let movesCompleted = currentMoveIndex + 1
        let totalMoves = pattern.orderedMoves.count
        
        do {
            try dataManager.profileService.recordStudySession(
                sessionType: .patterns,
                itemsStudied: totalMoves,
                correctAnswers: movesCompleted,
                focusAreas: [pattern.name]
            )
        } catch {
            print("❌ Failed to record pattern practice session: \(error)")
        }
    }
}

// MARK: - Preview

struct PatternPracticeView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview would need mock data
        Text("PatternPracticeView Preview")
    }
}