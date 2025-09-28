import SwiftUI

/**
 * PatternTestView.swift
 * 
 * PURPOSE: Interactive pattern sequence testing interface
 * 
 * FEATURES:
 * - Test pattern sequencing and memory recall
 * - Show 0-2 previous moves and next 5 moves to complete
 * - Three test categories: Stances, Techniques, Movement
 * - Distractor generation with same-pattern priority
 * - Results screen with detailed accuracy breakdown
 * 
 * ARCHITECTURE:
 * - Uses PatternTestService for test logic and distractor generation
 * - Follows established MVVM patterns with service delegation
 * - SwiftData integration for test result storage
 */

struct PatternTestView: View {
    let pattern: Pattern
    @EnvironmentObject private var dataServices: DataServices
    @Environment(\.dismiss) private var dismiss
    
    @State private var patternTest: PatternTest?
    @State private var currentMoveIndex = 0
    @State private var responses: [TestResponse] = []
    @State private var userProfile: UserProfile?
    @State private var testStartTime = Date()
    @State private var showingResults = false
    @State private var testSubmissionResult: TestSubmissionResult?
    @State private var selectedStance = ""
    @State private var selectedTechnique = ""
    @State private var selectedMovement = ""
    @State private var stanceOptions: [String] = []
    @State private var techniqueOptions: [String] = []
    @State private var movementOptions: [String] = []
    
    private var testService: PatternTestService {
        PatternTestService(patternDataService: dataServices.patternService)
    }
    
    private var currentTestMove: PatternTestMove? {
        guard let test = patternTest,
              currentMoveIndex < test.moves.count else { return nil }
        return test.moves[currentMoveIndex]
    }
    
    private var isLastMove: Bool {
        guard let test = patternTest else { return false }
        return currentMoveIndex >= test.moves.count - 1
    }
    
    private var progressPercentage: Double {
        guard let test = patternTest, test.moves.count > 0 else { return 0 }
        return Double(currentMoveIndex + 1) / Double(test.moves.count)
    }
    
    var body: some View {
        Group {
            if patternTest == nil {
                // Loading or error state
                loadingView
            } else if showingResults {
                // Results screen
                testResultsView
            } else {
                // Main test interface
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Test content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Context section - show previous and upcoming moves
                            testContextSection
                            
                            // Answer selection section
                            answerSelectionSection
                            
                            // Navigation controls
                            testNavigationControls
                                .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle("Test \(pattern.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Test") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
        }
        .onAppear {
            DebugLogger.ui("🧪 PatternTestView appeared for pattern: \(pattern.name)")
        }
        .onDisappear {
            DebugLogger.ui("🧪 PatternTestView disappeared for pattern: \(pattern.name)")
        }
        .task {
            DebugLogger.ui("🧪 PatternTestView task starting for pattern: \(pattern.name)")
            setupTest()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Preparing Test")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Analyzing \(pattern.name) pattern...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 12) {
            // Bold, centered move number
            Text("Move \(currentMoveIndex + 1)")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Progress bar
            SwiftUI.ProgressView(value: progressPercentage, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Test Context Section
    
    private var testContextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sequence Context")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Show previous moves (scrollable) - all completed moves, positioned to show recent ones
            if currentMoveIndex > 0 {
                Text("Previous Moves:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            // Show ALL completed moves (0 to currentMoveIndex-1)
                            ForEach(0..<currentMoveIndex, id: \.self) { index in
                                if let test = patternTest, index < test.moves.count {
                                    previousMoveCard(move: test.moves[index], index: index)
                                        .id("move_\(index)")
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 140) // Height for ~4-5 recent moves visible
                    .onAppear {
                        // Scroll to show most recent moves by default
                        if currentMoveIndex > 4 {
                            // If more than 4 completed moves, scroll to show the most recent ones
                            let targetMove = max(0, currentMoveIndex - 4)
                            proxy.scrollTo("move_\(targetMove)", anchor: .top)
                        }
                    }
                    .onChange(of: currentMoveIndex) { _, newIndex in
                        // Auto-scroll to keep recent moves visible when advancing
                        if newIndex > 4 {
                            let targetMove = max(0, newIndex - 4)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("move_\(targetMove)", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // Show upcoming moves (next 2-3)
            if let test = patternTest, currentMoveIndex < test.moves.count - 1 {
                Text("Upcoming Moves:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                let startIndex = currentMoveIndex + 1
                let endIndex = min(test.moves.count, currentMoveIndex + 4) // Next 3 upcoming moves
                
                ForEach(startIndex..<endIndex, id: \.self) { index in
                    upcomingMoveCard(moveNumber: index + 1)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func previousMoveCard(move: PatternTestMove, index: Int) -> some View {
        HStack {
            Text("\(move.moveNumber).")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                // Show user's selected answers if available, otherwise show correct answers
                if let userResponse = responses.first(where: { $0.moveNumber == move.moveNumber }) {
                    // User has answered this move - show their selections
                    Text("\(userResponse.selectedStance ?? "?") → \(userResponse.selectedTechnique ?? "?")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(userResponse.isStanceCorrect && userResponse.isTechniqueCorrect ? .primary : .orange)
                    
                    Text(userResponse.selectedMovement ?? "?")
                        .font(.caption)
                        .foregroundColor(userResponse.isMovementCorrect ? .secondary : .orange)
                } else {
                    // No user response yet - show correct answers in lighter text
                    Text("\(move.correctStance) → \(move.correctTechnique)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.secondary.opacity(0.6))
                    
                    Text(move.correctMovement)
                        .font(.caption)
                        .foregroundColor(Color.secondary.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Show completion indicator
            if let userResponse = responses.first(where: { $0.moveNumber == move.moveNumber }) {
                Image(systemName: userResponse.isCompletelyCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(userResponse.isCompletelyCorrect ? .green : .orange)
                    .padding(.trailing, 8)
            }
            
            // Edit button to jump to this move
            Button {
                jumpToMove(index: index)
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
    }
    
    private func upcomingMoveCard(moveNumber: Int) -> some View {
        HStack {
            Text("\(moveNumber).")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                // Show user's selected answers if available for future moves
                if let userResponse = responses.first(where: { $0.moveNumber == moveNumber }) {
                    // User has already answered this future move - show their selections
                    Text("\(userResponse.selectedStance ?? "?") → \(userResponse.selectedTechnique ?? "?")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(userResponse.isStanceCorrect && userResponse.isTechniqueCorrect ? .primary : .orange)
                    
                    Text(userResponse.selectedMovement ?? "?")
                        .font(.caption)
                        .foregroundColor(userResponse.isMovementCorrect ? .secondary : .orange)
                } else {
                    // No user response yet - show placeholder
                    Text("?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Show completion indicator for future moves if they have responses
            if let userResponse = responses.first(where: { $0.moveNumber == moveNumber }) {
                Image(systemName: userResponse.isCompletelyCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(userResponse.isCompletelyCorrect ? .green : .orange)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Current Question Section
    
    // Removed - using space for more compact layout
    
    // MARK: - Answer Selection Section
    
    private var answerSelectionSection: some View {
        VStack(spacing: 12) {
            // Movement selection - move in the direction first
            answerCategory("Movement", selectedValue: $selectedMovement, options: movementOptions)
            
            // Stance selection - establish stance after moving
            answerCategory("Stance", selectedValue: $selectedStance, options: stanceOptions)
            
            // Technique selection - execute technique from stance
            answerCategory("Technique", selectedValue: $selectedTechnique, options: techniqueOptions)
        }
    }
    
    private func answerCategory(_ title: String, selectedValue: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 6) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selectedValue.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedValue.wrappedValue == option ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44) // Fixed height for consistency
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedValue.wrappedValue == option ? Color.blue : Color(.systemGray6))
                            )
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    // MARK: - Navigation Controls
    
    private var testNavigationControls: some View {
        HStack(spacing: 16) {
            Button("Previous") {
                previousQuestion()
            }
            .disabled(currentMoveIndex == 0)
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            if isLastMove {
                Button("Submit Test") {
                    submitTest()
                }
                .disabled(!allAnswersSelected)
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(maxWidth: .infinity)
            } else {
                Button("Next") {
                    nextQuestion()
                }
                .disabled(!allAnswersSelected)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var allAnswersSelected: Bool {
        !selectedStance.isEmpty && !selectedTechnique.isEmpty && !selectedMovement.isEmpty
    }
    
    // MARK: - Test Results View
    
    private var testResultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Results header
                VStack(spacing: 12) {
                    Image(systemName: testSubmissionResult?.overallAccuracy ?? 0 >= 0.8 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(testSubmissionResult?.overallAccuracy ?? 0 >= 0.8 ? .green : .orange)
                    
                    Text("Test Complete!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let result = testSubmissionResult {
                        Text("\(Int(result.overallAccuracy * 100))% Overall Accuracy")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(result.overallAccuracy >= 0.8 ? .green : .orange)
                    }
                }
                
                // Detailed results
                if let result = testSubmissionResult {
                    VStack(spacing: 16) {
                        Text("Category Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        accuracyCard("Stances", accuracy: result.stanceAccuracy)
                        accuracyCard("Techniques", accuracy: result.techniqueAccuracy)
                        accuracyCard("Movement", accuracy: result.movementAccuracy)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button("Test Another Pattern") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    
                    Button("Practice This Pattern") {
                        dismiss()
                        // TODO: Navigate to practice view
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                }
                .padding(.top)
            }
            .padding()
        }
    }
    
    private func accuracyCard(_ title: String, accuracy: Double) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text("\(Int(accuracy * 100))%")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(accuracy >= 0.8 ? .green : accuracy >= 0.6 ? .orange : .red)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Test Logic
    
    private func setupTest() {
        DebugLogger.ui("🧪 Setting up test for pattern: \(pattern.name)")
        
        userProfile = dataServices.getOrCreateDefaultUserProfile()
        DebugLogger.ui("🧪 User profile loaded: \(userProfile?.name ?? "nil")")
        
        // Create test from pattern
        let test = testService.createTest(for: pattern)
        DebugLogger.ui("🧪 Test creation result: \(test != nil ? "success" : "failed")")
        
        patternTest = test
        
        if let patternTest = patternTest {
            DebugLogger.ui("🧪 Test created with \(patternTest.moves.count) moves")
            loadQuestionOptions()
        } else {
            DebugLogger.ui("❌ Failed to create test for pattern: \(pattern.name)")
        }
    }
    
    private func loadQuestionOptions() {
        guard let move = currentTestMove else { return }
        
        // Generate distractors for each category
        stanceOptions = generateOptionsForCategory(.stance, move: move)
        techniqueOptions = generateOptionsForCategory(.technique, move: move)
        movementOptions = generateOptionsForCategory(.movement, move: move)
    }
    
    private func generateOptionsForCategory(_ category: TestCategory, move: PatternTestMove) -> [String] {
        let correctAnswer: String
        switch category {
        case .stance: correctAnswer = move.correctStance
        case .technique: correctAnswer = move.correctTechnique
        case .movement: correctAnswer = move.correctMovement
        }
        
        // Get 3 distractors
        let distractors = testService.generateDistractors(
            for: move,
            category: category,
            fromPattern: pattern,
            count: 3
        )
        
        // Combine correct answer with distractors and shuffle
        var options = [correctAnswer] + distractors
        options.shuffle()
        
        return options
    }
    
    private func nextQuestion() {
        saveCurrentResponse()
        
        if currentMoveIndex < (patternTest?.moves.count ?? 0) - 1 {
            currentMoveIndex += 1
            loadStoredResponseOrClear()
            loadQuestionOptions()
        }
    }
    
    private func previousQuestion() {
        saveCurrentResponse()
        
        if currentMoveIndex > 0 {
            currentMoveIndex -= 1
            loadStoredResponseOrClear()
            loadQuestionOptions()
        }
    }
    
    private func saveCurrentResponse() {
        guard let move = currentTestMove else { return }
        
        // Update or create response for current move
        let response = TestResponse(
            moveNumber: move.moveNumber,
            selectedStance: selectedStance.isEmpty ? nil : selectedStance,
            selectedTechnique: selectedTechnique.isEmpty ? nil : selectedTechnique,
            selectedMovement: selectedMovement.isEmpty ? nil : selectedMovement,
            correctStance: move.correctStance,
            correctTechnique: move.correctTechnique,
            correctMovement: move.correctMovement
        )
        
        // Replace existing response or append new one
        if let existingIndex = responses.firstIndex(where: { $0.moveNumber == move.moveNumber }) {
            responses[existingIndex] = response
        } else {
            responses.append(response)
        }
    }
    
    private func loadStoredResponseOrClear() {
        guard let move = currentTestMove else { return }
        
        if let storedResponse = responses.first(where: { $0.moveNumber == move.moveNumber }) {
            selectedStance = storedResponse.selectedStance ?? ""
            selectedTechnique = storedResponse.selectedTechnique ?? ""
            selectedMovement = storedResponse.selectedMovement ?? ""
        } else {
            selectedStance = ""
            selectedTechnique = ""
            selectedMovement = ""
        }
    }
    
    private func submitTest() {
        guard let profile = userProfile else { return }
        
        // Save current response
        saveCurrentResponse()
        
        // Submit test through service
        testSubmissionResult = testService.submitTest(
            responses: responses,
            for: pattern,
            userProfile: profile
        )
        
        // Show results
        showingResults = true
    }
    
    private func jumpToMove(index: Int) {
        // Save current response before jumping
        saveCurrentResponse()
        
        // Jump to the selected move
        currentMoveIndex = index
        loadStoredResponseOrClear()
        loadQuestionOptions()
    }
}

// MARK: - Preview

struct PatternTestView_Previews: PreviewProvider {
    static var previews: some View {
        Text("PatternTestView Preview")
    }
}