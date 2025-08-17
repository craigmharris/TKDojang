import SwiftUI

/**
 * TestResultsView.swift
 * 
 * PURPOSE: Results screen focused on learning and improvement
 * 
 * FEATURES:
 * - Learning-focused tone with score as secondary
 * - Detailed performance breakdown by category and belt level
 * - Actionable study recommendations
 * - Direct links to review flashcards for missed terms
 * - Achievement recognition while emphasizing growth
 */

struct TestResultsView: View {
    let testSession: TestSession
    let result: TestResult
    @Environment(\.dismiss) private var dismiss
    @State private var showingTestSelection = false
    
    var incorrectTerms: [TerminologyEntry] {
        return testSession.questions
            .filter { !$0.isCorrect && $0.terminologyEntry != nil }
            .compactMap { $0.terminologyEntry }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with Score and Achievement
                    VStack(spacing: 16) {
                        // Achievement Badge (if any)
                        if let achievement = result.achievement {
                            Text(achievement)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(20)
                        }
                        
                        // Score Display
                        VStack(spacing: 8) {
                            Text("\(result.correctAnswers)/\(result.totalQuestions)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("\(Int(result.accuracy))% Correct")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        
                        // Performance Indicator
                        PerformanceIndicator(accuracy: result.accuracy)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(16)
                    
                    // Study Recommendations (Primary Focus)
                    if !result.studyRecommendations.isEmpty {
                        StudyRecommendationsCard(recommendations: result.studyRecommendations)
                    }
                    
                    // Weak Areas to Focus On
                    if !result.weakAreas.isEmpty {
                        WeakAreasCard(weakAreas: result.weakAreas)
                    }
                    
                    // Performance Breakdown
                    PerformanceBreakdownCard(
                        categoryPerformance: result.categoryPerformance,
                        beltLevelPerformance: result.beltLevelPerformance
                    )
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        NavigationLink(destination: FlashcardView(specificTerms: incorrectTerms)) {
                            HStack {
                                Image(systemName: "rectangle.on.rectangle")
                                Text("Review with Flashcards")
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("Take Another Test") {
                            showingTestSelection = true
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        
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
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(isPresented: $showingTestSelection) {
                TestSelectionView()
            }
        }
    }
}

// MARK: - Performance Indicator

struct PerformanceIndicator: View {
    let accuracy: Double
    
    private var performanceLevel: (title: String, color: Color, message: String) {
        switch accuracy {
        case 90...100:
            return ("Excellent", .green, "Outstanding understanding!")
        case 80..<90:
            return ("Good", .blue, "Strong foundation with room to grow")
        case 70..<80:
            return ("Fair", .orange, "Good progress, keep practicing")
        default:
            return ("Needs Work", .red, "Focus on review and practice")
        }
    }
    
    var body: some View {
        let level = performanceLevel
        
        VStack(spacing: 8) {
            Text(level.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(level.color)
            
            Text(level.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Study Recommendations Card

struct StudyRecommendationsCard: View {
    let recommendations: [String]
    
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

// MARK: - Weak Areas Card

struct WeakAreasCard: View {
    let weakAreas: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                Text("Areas to Focus On")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(weakAreas, id: \.self) { area in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text(area)
                            .font(.subheadline)
                        
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
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Performance Breakdown Card

struct PerformanceBreakdownCard: View {
    let categoryPerformance: [CategoryPerformance]
    let beltLevelPerformance: [BeltLevelPerformance]
    
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Performance Breakdown")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Tab Selector
            Picker("Breakdown Type", selection: $selectedTab) {
                Text("Categories").tag(0)
                Text("Belt Levels").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if selectedTab == 0 {
                // Category Performance
                VStack(spacing: 12) {
                    ForEach(categoryPerformance.sorted(by: { $0.category < $1.category }), id: \.category) { category in
                        PerformanceRow(
                            title: category.category.capitalized,
                            correct: category.correctAnswers,
                            total: category.totalQuestions,
                            accuracy: category.accuracy
                        )
                    }
                }
            } else {
                // Belt Level Performance
                VStack(spacing: 12) {
                    ForEach(beltLevelPerformance.sorted(by: { $0.beltLevel < $1.beltLevel }), id: \.beltLevel) { belt in
                        PerformanceRow(
                            title: belt.beltLevel,
                            correct: belt.correctAnswers,
                            total: belt.totalQuestions,
                            accuracy: belt.accuracy
                        )
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
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Performance Row

struct PerformanceRow: View {
    let title: String
    let correct: Int
    let total: Int
    let accuracy: Double
    
    private var progressColor: Color {
        switch accuracy {
        case 90...100: return .green
        case 70..<90: return .blue
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(correct)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(Int(accuracy))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(progressColor)
                    .frame(width: 40, alignment: .trailing)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * (accuracy / 100.0), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Preview

struct TestResultsView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with mock data would go here
        Text("TestResultsView Preview")
    }
}