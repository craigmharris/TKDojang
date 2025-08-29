import SwiftUI

/**
 * FlashcardModeGuideView.swift
 * 
 * PURPOSE: Comprehensive guide explaining flashcard modes and systems
 * 
 * FEATURES:
 * - Learning System explanations (Classic vs Leitner)
 * - Study Mode explanations (Learn vs Test)
 * - Direction options explanation
 * - Visual examples and recommendations
 */

struct FlashcardModeGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // Learning Systems Tab
                learningSystemsGuide
                    .tabItem {
                        Label("Learning Systems", systemImage: "brain.head.profile")
                    }
                    .tag(0)
                
                // Study Modes Tab  
                studyModesGuide
                    .tabItem {
                        Label("Study Modes", systemImage: "book.fill")
                    }
                    .tag(1)
                
                // Directions Tab
                directionsGuide
                    .tabItem {
                        Label("Directions", systemImage: "arrow.left.arrow.right")
                    }
                    .tag(2)
            }
            .navigationTitle("Flashcard Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Learning Systems Guide
    
    private var learningSystemsGuide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Learning Systems")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Choose the learning algorithm that works best for you")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Classic Mode
                GuideCard(
                    title: "Classic Mode",
                    icon: "book.fill",
                    iconColor: .orange,
                    description: "Simple and straightforward flashcard learning",
                    features: [
                        "All cards available every session",
                        "Simple correct/incorrect tracking",
                        "Progress based on accuracy percentage",
                        "Great for beginners and casual learning",
                        "No complex scheduling or timing"
                    ],
                    whenToUse: "Perfect for getting started, reviewing before tests, or when you want immediate access to all terms without scheduling delays."
                )
                
                // Leitner Mode
                GuideCard(
                    title: "Leitner Mode",
                    icon: "calendar.badge.clock",
                    iconColor: .blue,
                    description: "Advanced spaced repetition for optimal memory retention",
                    features: [
                        "5-box scheduling system",
                        "Cards appear based on review schedule",
                        "Difficult cards reviewed more frequently",
                        "Mastered cards reviewed less often",
                        "Scientifically proven for long-term retention"
                    ],
                    whenToUse: "Ideal for serious study, long-term retention, and building strong foundations. Requires consistent daily practice for best results."
                )
                
                // Comparison
                ComparisonCard()
                
                // Getting Started
                GettingStartedCard()
            }
            .padding()
        }
    }
    
    // MARK: - Study Modes Guide
    
    private var studyModesGuide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Study Modes")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Different ways to study your Korean terminology")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Learn Mode
                GuideCard(
                    title: "Learn Mode",
                    icon: "eyes",
                    iconColor: .green,
                    description: "Study mode showing all information at once",
                    features: [
                        "See English, Korean (Hangul), and pronunciation together",
                        "View definitions and explanations",
                        "No pressure - just absorb the information", 
                        "Navigate at your own pace",
                        "Perfect for first exposure to new terms"
                    ],
                    whenToUse: "Use when learning new terminology, reviewing definitions, or when you want to study without the pressure of testing yourself."
                )
                
                // Test Mode
                GuideCard(
                    title: "Test Mode", 
                    icon: "questionmark.circle",
                    iconColor: .orange,
                    description: "Self-testing with flashcard flipping and progress tracking",
                    features: [
                        "Question on one side, answer on the other",
                        "Tap to flip and reveal the answer",
                        "Mark yourself correct or incorrect",
                        "Builds active recall and memory strength",
                        "Tracks accuracy and identifies weak areas"
                    ],
                    whenToUse: "Use for active practice, self-testing, and when you want to challenge your memory and track your progress."
                )
                
                // Study Strategy
                StudyStrategyCard()
            }
            .padding()
        }
    }
    
    // MARK: - Directions Guide
    
    private var directionsGuide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("Study Directions")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("Practice translation in different directions for complete mastery")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // English to Korean
                GuideCard(
                    title: "English → Korean",
                    icon: "arrow.right",
                    iconColor: .blue,
                    description: "See English terms, recall Korean",
                    features: [
                        "Shows English term and definition",
                        "You recall Korean Hangul and pronunciation",
                        "Tests production skills",
                        "Builds vocabulary for speaking Korean",
                        "More challenging for most learners"
                    ],
                    whenToUse: "Practice this when preparing to speak Korean or when you want to strengthen your active vocabulary production."
                )
                
                // Korean to English
                GuideCard(
                    title: "Korean → English",
                    icon: "arrow.left",
                    iconColor: .green,
                    description: "See Korean terms, recall English meaning",
                    features: [
                        "Shows Korean Hangul and pronunciation", 
                        "You recall English meaning and usage",
                        "Tests comprehension skills",
                        "Builds vocabulary for understanding Korean",
                        "Usually easier for English speakers"
                    ],
                    whenToUse: "Practice this when learning to understand Korean speech or reading, and for building recognition skills."
                )
                
                // Both Directions (Recommended)
                GuideCard(
                    title: "Both Directions ⭐️",
                    icon: "arrow.left.arrow.right",
                    iconColor: .purple,
                    description: "Random mix of both directions for complete mastery",
                    features: [
                        "Randomly shows either English or Korean first",
                        "Builds both production and comprehension",
                        "Most effective for complete fluency",
                        "Prevents pattern memorization",
                        "Recommended default setting"
                    ],
                    whenToUse: "Use this as your default for the most comprehensive and effective language learning experience."
                )
                
                // Direction Strategy
                DirectionStrategyCard()
            }
            .padding()
        }
    }
}

// MARK: - Supporting Components

struct GuideCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let description: String
    let features: [String]
    let whenToUse: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                Text("Features:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(iconColor)
                            .frame(width: 16)
                        
                        Text(feature)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
            
            // When to Use
            VStack(alignment: .leading, spacing: 6) {
                Text("When to Use:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(whenToUse)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ComparisonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scale.3d")
                    .foregroundColor(.gray)
                Text("Quick Comparison")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 8) {
                ComparisonRow(aspect: "Learning Curve", classic: "Easy", leitner: "Moderate")
                ComparisonRow(aspect: "Time Commitment", classic: "Flexible", leitner: "Daily Practice")
                ComparisonRow(aspect: "Long-term Retention", classic: "Good", leitner: "Excellent")
                ComparisonRow(aspect: "Immediate Access", classic: "All Terms", leitner: "Scheduled Terms")
                ComparisonRow(aspect: "Best For", classic: "Casual Learning", leitner: "Serious Study")
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ComparisonRow: View {
    let aspect: String
    let classic: String
    let leitner: String
    
    var body: some View {
        HStack {
            Text(aspect)
                .font(.caption)
                .frame(width: 100, alignment: .leading)
            
            Text(classic)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
                .frame(width: 80)
            
            Text("vs")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(leitner)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(width: 80)
            
            Spacer()
        }
    }
}

struct GettingStartedCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Getting Started Recommendation")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("New to Korean terminology? Start with Classic Mode using Learn Mode to familiarize yourself with the terms. Once comfortable, switch to Test Mode to practice active recall. When you're ready for serious long-term learning, enable Leitner Mode for optimal retention.")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StudyStrategyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.blue)
                Text("Effective Study Strategy")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                StrategyStep(number: 1, text: "Start with Learn Mode to see all information")
                StrategyStep(number: 2, text: "Switch to Test Mode when ready to practice")
                StrategyStep(number: 3, text: "Focus on terms you get wrong")
                StrategyStep(number: 4, text: "Mix directions for complete mastery")
                StrategyStep(number: 5, text: "Regular short sessions beat long cramming")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StrategyStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct DirectionStrategyCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.purple)
                Text("Direction Strategy")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("Both Directions is recommended as the default because it provides the most comprehensive learning experience. However, you can focus on specific directions based on your goals:")
                .font(.subheadline)
            
            VStack(alignment: .leading, spacing: 6) {
                DirectionGoal(goal: "Speaking Korean", direction: "English → Korean")
                DirectionGoal(goal: "Understanding Korean", direction: "Korean → English") 
                DirectionGoal(goal: "Complete Fluency", direction: "Both Directions")
                DirectionGoal(goal: "Test Preparation", direction: "Both Directions")
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct DirectionGoal: View {
    let goal: String
    let direction: String
    
    var body: some View {
        HStack {
            Text("•")
                .foregroundColor(.purple)
                .fontWeight(.bold)
            
            Text(goal + ":")
                .font(.caption)
                .fontWeight(.medium)
            
            Text(direction)
                .font(.caption)
                .foregroundColor(.purple)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct FlashcardModeGuideView_Previews: PreviewProvider {
    static var previews: some View {
        FlashcardModeGuideView()
    }
}