import SwiftUI

/**
 * PURPOSE: Main line work practice view for grading technique requirements
 * 
 * Displays organized line work technique sets including:
 * - Stance work moving forward/backward
 * - Blocking techniques in line formation
 * - Striking techniques with coordinated footwork
 * - Practice sequences with repetition patterns
 * 
 * Uses profile-aware filtering to show relevant techniques for user's current belt level.
 * Integrates with existing navigation patterns and theming system.
 */

struct LineWorkView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var lineWorkContent: [String: LineWorkContent] = [:]
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    
    private let availableCategories = ["Stances", "Blocking", "Striking", "Kicking"]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading Line Work Content...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    lineWorkContentView
                }
            }
            .navigationTitle("Line Work")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileSwitcher()
                }
            }
        }
        .task {
            await loadLineWorkContent()
        }
    }
    
    @ViewBuilder
    private var lineWorkContentView: some View {
        if let activeProfile = dataManager.profileService.activeProfile,
           let beltId = mapBeltLevelToId(activeProfile.currentBeltLevel.shortName),
           let content = lineWorkContent[beltId] {
            
            VStack(spacing: 0) {
                // Category Filter
                categoryFilterView
                
                // Line Work Sets
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredSets(from: content)) { set in
                            NavigationLink(destination: LineWorkSetDetailView(set: set, practiceNotes: content.practiceNotes)) {
                                LineWorkSetCard(set: set)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Practice notes section
                        PracticeNotesCard(notes: content.practiceNotes)
                    }
                    .padding()
                }
            }
            
        } else {
            ContentUnavailableView(
                "No Line Work Content",
                systemImage: "figure.walk",
                description: Text("Line work techniques are not available for your current belt level.")
            )
        }
    }
    
    @ViewBuilder
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                LineWorkCategoryFilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(availableCategories, id: \.self) { category in
                    LineWorkCategoryFilterChip(
                        title: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    private func filteredSets(from content: LineWorkContent) -> [LineWorkSet] {
        if let selectedCategory = selectedCategory {
            return content.lineWorkSets.filter { $0.category == selectedCategory }
        }
        return content.lineWorkSets
    }
    
    private func loadLineWorkContent() async {
        lineWorkContent = await LineWorkContentLoader.loadAllLineWorkContent()
        isLoading = false
    }
    
    private func mapBeltLevelToId(_ beltLevel: String) -> String? {
        let mapping = [
            "10th Keup": "10th_keup",
            "9th Keup": "9th_keup", 
            "8th Keup": "8th_keup",
            "7th Keup": "7th_keup",
            "6th Keup": "6th_keup",
            "5th Keup": "5th_keup",
            "4th Keup": "4th_keup",
            "3rd Keup": "3rd_keup",
            "2nd Keup": "2nd_keup",
            "1st Keup": "1st_keup"
        ]
        return mapping[beltLevel]
    }
}

struct LineWorkSetCard: View {
    let set: LineWorkSet
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(set.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(set.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(set.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Technique count and preview
            HStack {
                Image(systemName: "figure.walk.motion")
                    .font(.caption)
                Text("\(set.techniques.count) techniques")
                    .font(.caption)
                
                Spacer()
                
                if let firstTechnique = set.techniques.first {
                    Text(firstTechnique.korean)
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

struct PracticeNotesCard: View {
    let notes: PracticeNotes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                Text("Practice Guidelines")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Warmup
                VStack(alignment: .leading, spacing: 4) {
                    Text("Warmup")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(notes.warmup)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Focus areas
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Focus Areas")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(notes.focusAreas, id: \.self) { area in
                            HStack(alignment: .top) {
                                Text("•")
                                    .foregroundColor(.accentColor)
                                Text(area)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Progression
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progression")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                    
                    Text(notes.progression)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct LineWorkCategoryFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    LineWorkView()
        .environment(DataManager.shared)
}