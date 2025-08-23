import SwiftUI
import AVFoundation

/**
 * PURPOSE: Interactive practice view for line work technique sequences
 * 
 * Provides guided practice experience including:
 * - Step-by-step technique guidance
 * - Forward/backward movement direction indicators
 * - Repetition counting and progress tracking
 * - Audio cues for timing (optional)
 * 
 * Follows the established practice view pattern used in patterns and step sparring
 * for consistent user experience across training modes.
 */

struct LineWorkPracticeView: View {
    let set: LineWorkSet
    let practiceNotes: PracticeNotes
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentTechniqueIndex = 0
    @State private var currentDirectionIndex = 0
    @State private var currentRepetition = 1
    @State private var isPaused = false
    @State private var showingInstructions = true
    @State private var completedTechniques: Set<String> = []
    
    private var currentTechnique: LineWorkTechnique {
        return set.techniques[currentTechniqueIndex]
    }
    
    private var currentDirection: DirectionSequence {
        return currentTechnique.directionPattern[currentDirectionIndex]
    }
    
    private var overallProgress: Double {
        let completedCount = completedTechniques.count
        return Double(completedCount) / Double(set.techniques.count)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if showingInstructions {
                    instructionsView
                } else {
                    practiceView
                }
            }
            .navigationTitle("Practice: \(set.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if !showingInstructions {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isPaused ? "Resume" : "Pause") {
                            isPaused.toggle()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var instructionsView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Ready to Practice")
                    .font(.title.weight(.bold))
                
                Text(set.title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Practice Overview")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .foregroundColor(.accentColor)
                        Text("\(set.techniques.count) techniques to practice")
                    }
                    
                    HStack {
                        Image(systemName: "arrow.up.and.down")
                            .foregroundColor(.accentColor)
                        Text("Forward and backward movements")
                    }
                    
                    HStack {
                        Image(systemName: "repeat")
                            .foregroundColor(.accentColor)
                        Text("Multiple repetitions per direction")
                    }
                }
                .font(.body)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Remember")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(practiceNotes.warmup)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
            Spacer()
            
            Button("Begin Practice") {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingInstructions = false
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    @ViewBuilder
    private var practiceView: some View {
        VStack(spacing: 24) {
            // Progress section
            progressSection
            
            Spacer()
            
            // Current technique display
            if !isPaused {
                techniqueDisplaySection
            } else {
                pausedStateSection
            }
            
            Spacer()
            
            // Controls
            if !isPaused {
                controlsSection
            } else {
                resumeSection
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Technique \(currentTechniqueIndex + 1) of \(set.techniques.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(overallProgress * 100))% Complete")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            SwiftUI.ProgressView(value: overallProgress, total: 1.0)
                .progressViewStyle(.linear)
                .tint(.accentColor)
        }
    }
    
    @ViewBuilder
    private var techniqueDisplaySection: some View {
        VStack(spacing: 20) {
            // Technique name
            VStack(spacing: 8) {
                Text(currentTechnique.name)
                    .font(.title.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text(currentTechnique.korean)
                    .font(.title2.italic())
                    .foregroundColor(.secondary)
            }
            
            // Direction indicator
            VStack(spacing: 16) {
                DirectionIndicator(
                    direction: currentDirection.direction,
                    repetition: currentRepetition,
                    totalReps: currentDirection.count
                )
                
                Text(currentDirection.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private var pausedStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "pause.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Practice Paused")
                .font(.title2.weight(.semibold))
            
            Text("Take a moment to review the technique points")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Show current technique key points
            if !currentTechnique.keyPoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Points")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    ForEach(currentTechnique.keyPoints.prefix(3), id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(point)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    @ViewBuilder
    private var controlsSection: some View {
        VStack(spacing: 12) {
            // Next/Complete button
            Button(action: nextAction) {
                Text(nextButtonTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Progress indicator text
            Text(progressText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var resumeSection: some View {
        Button("Resume Practice") {
            isPaused = false
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var nextButtonTitle: String {
        if currentRepetition < currentDirection.count {
            return "Next Rep (\(currentRepetition + 1)/\(currentDirection.count))"
        } else if currentDirectionIndex < currentTechnique.directionPattern.count - 1 {
            return "Next Direction"
        } else if currentTechniqueIndex < set.techniques.count - 1 {
            return "Next Technique"
        } else {
            return "Complete Practice"
        }
    }
    
    private var progressText: String {
        if currentRepetition < currentDirection.count {
            return "\(currentDirection.direction.capitalized) movement - Rep \(currentRepetition) of \(currentDirection.count)"
        } else if currentDirectionIndex < currentTechnique.directionPattern.count - 1 {
            return "Moving to \(currentTechnique.directionPattern[currentDirectionIndex + 1].direction) movement"
        } else if currentTechniqueIndex < set.techniques.count - 1 {
            return "Moving to next technique"
        } else {
            return "Final repetition - you're almost done!"
        }
    }
    
    private func nextAction() {
        if currentRepetition < currentDirection.count {
            // Next repetition in current direction
            withAnimation(.easeInOut(duration: 0.3)) {
                currentRepetition += 1
            }
        } else if currentDirectionIndex < currentTechnique.directionPattern.count - 1 {
            // Next direction in current technique
            withAnimation(.easeInOut(duration: 0.3)) {
                currentDirectionIndex += 1
                currentRepetition = 1
            }
        } else if currentTechniqueIndex < set.techniques.count - 1 {
            // Next technique
            completedTechniques.insert(currentTechnique.id)
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTechniqueIndex += 1
                currentDirectionIndex = 0
                currentRepetition = 1
            }
        } else {
            // Complete practice
            completedTechniques.insert(currentTechnique.id)
            dismiss()
        }
    }
}

struct DirectionIndicator: View {
    let direction: String
    let repetition: Int
    let totalReps: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Direction arrow
            Image(systemName: direction == "forward" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(direction == "forward" ? .green : .blue)
                .animation(.pulse.repeatCount(3, autoreverses: true), value: repetition)
            
            // Direction text
            Text(direction.capitalized)
                .font(.title2.weight(.bold))
                .foregroundColor(direction == "forward" ? .green : .blue)
            
            // Repetition counter
            HStack(spacing: 4) {
                ForEach(1...totalReps, id: \.self) { rep in
                    Circle()
                        .fill(rep <= repetition ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("Rep \(repetition) of \(totalReps)")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
        }
    }
}

extension Animation {
    static var pulse: Animation {
        .easeInOut(duration: 0.6)
    }
}

#Preview {
    let sampleSet = LineWorkSet(
        id: "sample",
        title: "Basic Blocks",
        category: "Blocking",
        description: "Fundamental blocking techniques",
        techniques: []
    )
    
    let sampleNotes = PracticeNotes(
        warmup: "Always warm up thoroughly before practicing line work",
        focusAreas: ["Balance", "Timing", "Coordination"],
        progression: "Start slowly, focus on form"
    )
    
    LineWorkPracticeView(set: sampleSet, practiceNotes: sampleNotes)
}