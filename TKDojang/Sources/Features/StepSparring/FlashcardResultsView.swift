import SwiftUI

/**
 * FlashcardResultsView.swift
 * 
 * PURPOSE: Results screen for flashcard study sessions
 * 
 * FEATURES:
 * - Session performance summary with accuracy metrics
 * - Study recommendations based on performance
 * - Action buttons to continue learning or retry weak terms
 * - Visual feedback with performance indicators
 */

struct FlashcardResultsView: View {
    let sessionStats: SessionStats
    let terms: [TerminologyEntry]
    let incorrectTerms: [TerminologyEntry]
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewSession = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Session Summary
                    VStack(spacing: 16) {
                        // Session Performance Icon
                        Image(systemName: performanceIcon)
                            .font(.system(size: 60))
                            .foregroundColor(performanceColor)
                        
                        Text("Session Complete!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        // Score Display
                        VStack(spacing: 8) {
                            Text("\(sessionStats.correctCount)/\(sessionStats.totalCount)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("\(sessionStats.accuracyPercentage)% Accuracy")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        // Performance Indicator
                        PerformanceIndicator(accuracy: Double(sessionStats.accuracyPercentage))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Study Recommendations
                    FlashcardStudyRecommendationsCard(sessionStats: sessionStats, totalTerms: terms.count)
                    
                    // Session Details
                    FlashcardSessionDetailsCard(sessionStats: sessionStats, totalTerms: terms.count)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Review incorrect terms (if any)
                        if !incorrectTerms.isEmpty {
                            NavigationLink(destination: FlashcardConfigurationView(specificTerms: incorrectTerms)) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Review Missed Terms (\(incorrectTerms.count))")
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Start new flashcard session
                        Button("New Flashcard Session") {
                            showingNewSession = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Return to Learn menu
                        Button("Return to Learn") {
                            dismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Flashcard Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingNewSession) {
                FlashcardConfigurationView(specificTerms: nil)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var performanceIcon: String {
        switch sessionStats.accuracyPercentage {
        case 90...100: return "star.fill"
        case 70..<90: return "checkmark.circle.fill"
        case 50..<70: return "minus.circle.fill"
        default: return "exclamationmark.circle.fill"
        }
    }
    
    private var performanceColor: Color {
        switch sessionStats.accuracyPercentage {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
}

// MARK: - Study Recommendations Card

struct FlashcardStudyRecommendationsCard: View {
    let sessionStats: SessionStats
    let totalTerms: Int
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        if sessionStats.accuracyPercentage >= 90 {
            recs.append("Excellent work! You're mastering these terms.")
            recs.append("Try increasing difficulty or adding more advanced terms.")
            recs.append("Consider taking a comprehensive test to validate your knowledge.")
        } else if sessionStats.accuracyPercentage >= 70 {
            recs.append("Good progress! Focus on the terms you missed.")
            recs.append("Review missed terms with flashcards again.")
            recs.append("Practice Korean-to-English direction for better recognition.")
        } else if sessionStats.accuracyPercentage >= 50 {
            recs.append("Keep practicing! Repetition is key to memorization.")
            recs.append("Focus on one belt level at a time to build confidence.")
            recs.append("Use learn mode to review term definitions thoroughly.")
        } else {
            recs.append("Don't give up! Learning Korean terms takes time and practice.")
            recs.append("Start with learn mode to familiarize yourself with the terms.")
            recs.append("Focus on 5-10 terms at a time for better retention.")
        }
        
        if sessionStats.incorrectCount > 0 {
            recs.append("Review the \(sessionStats.incorrectCount) missed terms before moving on.")
        }
        
        return Array(recs.prefix(3)) // Limit to 3 recommendations
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Study Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(recommendations.enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Session Details Card

struct FlashcardSessionDetailsCard: View {
    let sessionStats: SessionStats
    let totalTerms: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Session Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(spacing: 12) {
                FlashcardSessionDetailRow(
                    title: "Terms Studied",
                    value: "\(totalTerms)",
                    icon: "books.vertical"
                )
                
                FlashcardSessionDetailRow(
                    title: "Correct Answers",
                    value: "\(sessionStats.correctCount)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                FlashcardSessionDetailRow(
                    title: "Incorrect Answers",
                    value: "\(sessionStats.incorrectCount)",
                    icon: "xmark.circle",
                    color: .red
                )
                
                FlashcardSessionDetailRow(
                    title: "Final Accuracy",
                    value: "\(sessionStats.accuracyPercentage)%",
                    icon: "target",
                    color: sessionStats.accuracyPercentage >= 70 ? .blue : .orange
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Session Detail Row

struct FlashcardSessionDetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    init(title: String, value: String, icon: String, color: Color = .primary) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

struct FlashcardResultsView_Previews: PreviewProvider {
    static var previews: some View {
        // Can't directly create mock SessionStats due to private setters, so create a test view
        Text("FlashcardResultsView Preview")
    }
}