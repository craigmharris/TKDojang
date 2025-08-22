import SwiftUI

/**
 * PURPOSE: Detailed view for individual line work technique sets
 * 
 * Displays comprehensive technique information including:
 * - Individual technique breakdowns with Korean names
 * - Forward/backward movement patterns
 * - Key execution points and common mistakes
 * - Interactive practice mode with direction guidance
 * 
 * Provides structured practice experience for grading technique requirements
 * following established UI patterns from other feature areas.
 */

struct LineWorkSetDetailView: View {
    let set: LineWorkSet
    let practiceNotes: PracticeNotes
    
    @State private var selectedTechnique: LineWorkTechnique? = nil
    @State private var showingPracticeMode = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header section
                headerSection
                
                // Techniques list
                techniquesSection
                
                // Practice guidance
                practiceGuidanceSection
            }
            .padding()
        }
        .navigationTitle(set.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Practice") {
                    showingPracticeMode = true
                }
                .disabled(set.techniques.isEmpty)
            }
        }
        .sheet(isPresented: $showingPracticeMode) {
            LineWorkPracticeView(set: set, practiceNotes: practiceNotes)
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(set.category)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .clipShape(Capsule())
            
            Text(set.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "figure.walk.motion")
                    .foregroundColor(.accentColor)
                Text("\(set.techniques.count) techniques to master")
                    .font(.subheadline.weight(.medium))
            }
        }
    }
    
    @ViewBuilder
    private var techniquesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Techniques")
                .font(.title2.weight(.bold))
            
            ForEach(set.techniques) { technique in
                LineWorkTechniqueCard(
                    technique: technique,
                    isExpanded: selectedTechnique?.id == technique.id,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTechnique = selectedTechnique?.id == technique.id ? nil : technique
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var practiceGuidanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Practice Guidance")
                .font(.title2.weight(.bold))
            
            PracticeGuidanceCard(practiceNotes: practiceNotes)
        }
    }
    
    private var categoryColor: Color {
        switch set.category {
        case "Stances": return .blue
        case "Blocking": return .green
        case "Striking": return .red
        case "Kicking": return .purple
        default: return .gray
        }
    }
}

struct LineWorkTechniqueCard: View {
    let technique: LineWorkTechnique
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Technique header
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(technique.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(technique.korean)
                            .font(.subheadline.italic())
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // Direction pattern
                    DirectionPatternView(directions: technique.directionPattern)
                    
                    // Key points
                    if !technique.keyPoints.isEmpty {
                        KeyPointsView(keyPoints: technique.keyPoints)
                    }
                    
                    // Common mistakes
                    if !technique.commonMistakes.isEmpty {
                        CommonMistakesView(mistakes: technique.commonMistakes)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.3), value: isExpanded)
    }
}

struct DirectionPatternView: View {
    let directions: [DirectionSequence]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Movement Pattern")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 8) {
                ForEach(directions) { direction in
                    HStack(spacing: 12) {
                        // Direction icon
                        Image(systemName: direction.direction == "forward" ? "arrow.up" : "arrow.down")
                            .font(.caption)
                            .foregroundColor(direction.direction == "forward" ? .green : .blue)
                            .frame(width: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(direction.direction.capitalized)
                                    .font(.body.weight(.medium))
                                
                                Spacer()
                                
                                Text("x\(direction.count)")
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            
                            Text(direction.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if direction != directions.last {
                        Divider()
                            .padding(.leading, 32)
                    }
                }
            }
        }
    }
}

struct KeyPointsView: View {
    let keyPoints: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key Points")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(point)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct CommonMistakesView: View {
    let mistakes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Common Mistakes")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(mistakes, id: \.self) { mistake in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text(mistake)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct PracticeGuidanceCard: View {
    let practiceNotes: PracticeNotes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Important Guidelines")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Warmup reminder
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "flame")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Warmup Required")
                            .font(.body.weight(.medium))
                        Text(practiceNotes.warmup)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Progression advice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Progression")
                            .font(.body.weight(.medium))
                        Text(practiceNotes.progression)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    let sampleSet = LineWorkSet(
        id: "sample_set",
        title: "Basic Stances",
        category: "Stances",
        description: "Fundamental stance work",
        techniques: []
    )
    
    let sampleNotes = PracticeNotes(
        warmup: "Always warm up thoroughly",
        focusAreas: ["Balance", "Timing"],
        progression: "Start slowly"
    )
    
    NavigationView {
        LineWorkSetDetailView(set: sampleSet, practiceNotes: sampleNotes)
    }
}