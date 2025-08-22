import SwiftUI

/**
 * PURPOSE: Interactive quiz view for theory study questions
 * 
 * Provides a focused quiz experience for theory content including:
 * - Sequential question presentation
 * - Immediate answer feedback
 * - Progress tracking through question set
 * - Results summary with performance metrics
 * 
 * Follows the established pattern used in flashcard and testing systems
 * for consistent user experience across learning modes.
 */

struct TheoryQuizView: View {
    let questions: [TheoryQuestion]
    let sectionTitle: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentQuestionIndex = 0
    @State private var showingAnswer = false
    @State private var correctAnswers = 0
    @State private var showingResults = false
    @State private var userAnswered = false
    
    private var currentQuestion: TheoryQuestion {
        questions[currentQuestionIndex]
    }
    
    private var progress: Double {
        Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if !showingResults {
                    quizView
                } else {
                    resultsView
                }
            }
            .padding()
            .navigationTitle("Theory Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var quizView: some View {
        VStack(spacing: 24) {
            // Progress section
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(sectionTitle)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                }
                
                SwiftUI.ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
            }
            
            Spacer()
            
            // Question card
            VStack(alignment: .leading, spacing: 20) {
                Text(currentQuestion.question)
                    .font(.title2.weight(.medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                if showingAnswer {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                        
                        Text("Answer:")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        Text(currentQuestion.answer)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                if !showingAnswer {
                    Button("Reveal Answer") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAnswer = true
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else if !userAnswered {
                    HStack(spacing: 16) {
                        Button("I Got It Wrong") {
                            recordAnswer(correct: false)
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("I Got It Right") {
                            recordAnswer(correct: true)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    Button(currentQuestionIndex < questions.count - 1 ? "Next Question" : "View Results") {
                        nextQuestion()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private var resultsView: some View {
        VStack(spacing: 24) {
            // Results header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Quiz Complete!")
                    .font(.title.weight(.bold))
                
                Text(sectionTitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Performance metrics
            VStack(spacing: 16) {
                ResultMetric(
                    title: "Score",
                    value: "\(correctAnswers)/\(questions.count)",
                    subtitle: "\(Int(Double(correctAnswers) / Double(questions.count) * 100))% correct"
                )
                
                ResultMetric(
                    title: "Questions",
                    value: "\(questions.count)",
                    subtitle: "theoretical knowledge"
                )
            }
            
            Spacer()
            
            // Performance feedback
            VStack(spacing: 8) {
                Text(performanceFeedback)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(studyRecommendation)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Retake Quiz") {
                    restartQuiz()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
    
    private var performanceFeedback: String {
        let percentage = Double(correctAnswers) / Double(questions.count)
        
        switch percentage {
        case 0.9...:
            return "Excellent! You have a strong understanding of this theory."
        case 0.7..<0.9:
            return "Good work! You understand most of the key concepts."
        case 0.5..<0.7:
            return "Fair performance. Review the material and try again."
        default:
            return "More study needed. Focus on understanding the fundamental concepts."
        }
    }
    
    private var studyRecommendation: String {
        let percentage = Double(correctAnswers) / Double(questions.count)
        
        switch percentage {
        case 0.9...:
            return "You're ready to test on this theory at your grading."
        case 0.7..<0.9:
            return "Review the questions you missed, then take the quiz again."
        case 0.5..<0.7:
            return "Re-read the theory section, then practice the quiz again."
        default:
            return "Study the theory thoroughly before attempting the quiz again."
        }
    }
    
    private func recordAnswer(correct: Bool) {
        if correct {
            correctAnswers += 1
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            userAnswered = true
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentQuestionIndex += 1
                showingAnswer = false
                userAnswered = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                showingResults = true
            }
        }
    }
    
    private func restartQuiz() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentQuestionIndex = 0
            showingAnswer = false
            correctAnswers = 0
            showingResults = false
            userAnswered = false
        }
    }
}

// MARK: - Supporting Views

struct ResultMetric: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title.weight(.bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    let sampleQuestions = [
        TheoryQuestion(question: "What does the white belt represent?", answer: "Innocence, as of a beginning student."),
        TheoryQuestion(question: "How many tenets are there?", answer: "Five tenets"),
        TheoryQuestion(question: "When was TAGB founded?", answer: "1983")
    ]
    
    TheoryQuizView(questions: sampleQuestions, sectionTitle: "10th Keup Theory")
}