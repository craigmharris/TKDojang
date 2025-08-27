import SwiftUI

/**
 * TestTakingView.swift
 * 
 * PURPOSE: Main interface for taking multiple choice tests
 * 
 * FEATURES:
 * - 4-option CTA layout with smart text sizing
 * - Visual feedback system (green/red highlights)
 * - Auto-advance after 1 second
 * - Progress tracking
 * - Responsive design for text-heavy Korean content
 */

struct TestTakingView: View {
    let testSession: TestSession
    @Environment(\.dismiss) private var dismiss
    @Environment(DataManager.self) private var dataManager
    @State private var testingService: TestingService?
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: Int?
    @State private var showingFeedback = false
    @State private var feedbackTimer: Timer?
    @State private var showingResults = false
    @State private var userProfile: UserProfile?
    
    var currentQuestion: TestQuestion? {
        guard currentQuestionIndex < testSession.questions.count else { return nil }
        return testSession.questions[currentQuestionIndex]
    }
    
    var progressPercentage: Double {
        guard !testSession.questions.isEmpty else { return 0 }
        return Double(min(currentQuestionIndex, testSession.questions.count)) / Double(testSession.questions.count) * 100
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Question \(min(currentQuestionIndex + 1, testSession.questions.count)) of \(testSession.questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(testSession.testType.displayName)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * (progressPercentage / 100.0), height: 4)
                        }
                    }
                    .frame(height: 4)
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                if let question = currentQuestion {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question Text
                            VStack(spacing: 16) {
                                Text(question.questionText)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                                    .padding(.horizontal)
                                
                                // Show term prominently for both question types
                                if let entry = question.terminologyEntry {
                                    VStack(spacing: 8) {
                                        if question.questionType == .koreanToEnglish {
                                            Text(entry.romanizedPronunciation)
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                            
                                            Text(entry.koreanHangul)
                                                .font(.title)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.center)
                                        } else {
                                            Text(entry.englishTerm)
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.top)
                            
                            // Answer Options
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                                    AnswerOptionButton(
                                        text: option,
                                        index: index,
                                        isSelected: selectedAnswer == index,
                                        isCorrect: index == question.correctAnswerIndex,
                                        showingFeedback: showingFeedback,
                                        action: { answerSelected(index) }
                                    )
                                    .disabled(showingFeedback)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 100) // Space for safe area
                    }
                } else {
                    // Test completed
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Test Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Processing your results...")
                            .foregroundColor(.secondary)
                    }
                    .onAppear {
                        completeTest()
                    }
                }
            }
            .navigationTitle("Test")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(showingFeedback)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ProfileSwitcher()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showingFeedback {
                        Button("Exit") {
                            dismiss()
                        }
                    }
                }
            }
        }
        .onAppear {
            if testingService == nil {
                testingService = TestingService(
                    modelContext: dataManager.modelContext,
                    terminologyService: dataManager.terminologyService
                )
            }
            
            // Load the active profile
            userProfile = dataManager.profileService.getActiveProfile()
            
            // Mark first question as presented
            if let firstQuestion = currentQuestion {
                firstQuestion.markAsPresented()
            }
        }
        .onChange(of: dataManager.profileService.activeProfile) {
            userProfile = dataManager.profileService.getActiveProfile()
        }
        .navigationDestination(isPresented: $showingResults) {
            if let result = testSession.result {
                TestResultsView(testSession: testSession, result: result)
            }
        }
    }
    
    private func answerSelected(_ index: Int) {
        guard let question = currentQuestion, !showingFeedback else { return }
        
        selectedAnswer = index
        showingFeedback = true
        
        // Record the answer
        if let service = testingService {
            do {
                try service.recordAnswer(for: question, answerIndex: index)
            } catch {
                print("Failed to record answer: \\(error)")
            }
        }
        
        // Auto-advance after 1 second
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            advanceToNextQuestion()
        }
    }
    
    private func advanceToNextQuestion() {
        selectedAnswer = nil
        showingFeedback = false
        currentQuestionIndex += 1
        
        // Mark next question as presented
        if let nextQuestion = currentQuestion {
            nextQuestion.markAsPresented()
        }
    }
    
    private func completeTest() {
        guard let service = testingService else { return }
        
        do {
            let result = try service.completeTest(session: testSession, for: userProfile)
            // Ensure the result is set on the session for navigation
            testSession.result = result
            
            // Record study session for analytics
            recordTestSession(result: result)
            
            showingResults = true
        } catch {
            print("Failed to complete test: \(error)")
        }
    }
    
    private func recordTestSession(result: TestResult) {
        let totalQuestions = testSession.questions.count
        let correctAnswers = testSession.questions.filter { $0.isCorrect }.count
        
        do {
            try dataManager.profileService.recordStudySession(
                sessionType: .testing,
                itemsStudied: totalQuestions,
                correctAnswers: correctAnswers,
                focusAreas: [testSession.testType.displayName]
            )
        } catch {
            print("❌ Failed to record test session: \(error)")
        }
    }
}

// MARK: - Answer Option Button

struct AnswerOptionButton: View {
    let text: String
    let index: Int
    let isSelected: Bool
    let isCorrect: Bool
    let showingFeedback: Bool
    let action: () -> Void
    
    private var backgroundColor: Color {
        if showingFeedback {
            if isSelected && !isCorrect {
                return .red.opacity(0.3) // Transparent red for wrong answer
            } else if isCorrect {
                return .green.opacity(0.3) // Transparent green for correct answer
            }
        }
        return Color(.systemBackground)
    }
    
    private var borderColor: Color {
        if showingFeedback {
            if isSelected && !isCorrect {
                return .red
            } else if isCorrect {
                return .green
            }
        }
        return Color(.systemGray4)
    }
    
    private var textColor: Color {
        if showingFeedback {
            if isCorrect {
                return .green
            } else if isSelected && !isCorrect {
                return .red
            }
        }
        return .primary
    }
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity, minHeight: 80)
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: showingFeedback ? 2 : 1)
                )
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: showingFeedback)
    }
}

// MARK: - Preview

struct TestTakingView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with mock data would go here
        Text("TestTakingView Preview")
    }
}