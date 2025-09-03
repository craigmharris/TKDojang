import SwiftUI

/**
 * TechniqueFiltersView.swift
 * 
 * PURPOSE: Advanced filtering interface for technique reference system
 * 
 * FEATURES:
 * - Multi-select tag filtering with visual chips
 * - Belt level filtering with visual belt indicators
 * - Difficulty level selection
 * - Clear filter options
 * - Real-time filter application
 */

struct TechniqueFiltersView: View {
    let filterOptions: TechniqueFilterOptions
    @Binding var selectedBeltFilter: String?
    @Binding var selectedDifficulty: String?
    @Binding var selectedTags: Set<String>
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Belt Level Filter
                    FilterSection(title: "Belt Level", icon: "medal.fill") {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(filterOptions.beltLevels, id: \.self) { beltLevel in
                                BeltFilterChip(
                                    beltLevel: beltLevel,
                                    isSelected: selectedBeltFilter == beltLevel,
                                    action: {
                                        selectedBeltFilter = selectedBeltFilter == beltLevel ? nil : beltLevel
                                    }
                                )
                            }
                        }
                    }
                    
                    // Difficulty Filter
                    FilterSection(title: "Difficulty", icon: "chart.bar.fill") {
                        HStack(spacing: 8) {
                            ForEach(filterOptions.difficulties, id: \.self) { difficulty in
                                DifficultyFilterChip(
                                    difficulty: difficulty,
                                    isSelected: selectedDifficulty == difficulty,
                                    action: {
                                        selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                                    }
                                )
                            }
                            Spacer()
                        }
                    }
                    
                    // Tag Filters
                    FilterSection(title: "Tags", icon: "tag.fill") {
                        TagFilterGrid(
                            tags: filterOptions.tags,
                            selectedTags: $selectedTags
                        )
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Filter Techniques")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearAllFilters()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func clearAllFilters() {
        selectedBeltFilter = nil
        selectedDifficulty = nil
        selectedTags.removeAll()
    }
}

// MARK: - Filter Section

struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            content
        }
    }
}

// MARK: - Belt Filter Chip

struct BeltFilterChip: View {
    let beltLevel: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Belt visual
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: getBeltColors(for: beltLevel),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black.opacity(0.2), lineWidth: 0.5)
                    )
                
                Text(beltDisplayName(for: beltLevel))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getBeltColors(for beltLevel: String) -> [Color] {
        return BeltUtils.getBeltColorsLegacy(for: beltLevel)
    }
    
    private func beltDisplayName(for beltLevel: String) -> String {
        return BeltUtils.fileIdToBeltLevel(beltLevel)
    }
}

// MARK: - Difficulty Filter Chip

struct DifficultyFilterChip: View {
    let difficulty: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: difficultyIcon(for: difficulty))
                    .font(.caption)
                
                Text(difficulty.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? difficultyColor(for: difficulty) : Color(.tertiarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : difficultyColor(for: difficulty).opacity(0.5), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty {
        case "basic": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        case "expert": return .purple
        default: return .gray
        }
    }
    
    private func difficultyIcon(for difficulty: String) -> String {
        switch difficulty {
        case "basic": return "1.circle.fill"
        case "intermediate": return "2.circle.fill"
        case "advanced": return "3.circle.fill"
        case "expert": return "star.circle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Tag Filter Grid

struct TagFilterGrid: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        FlexibleTagGrid(tags: tags, selectedTags: $selectedTags)
    }
}

// MARK: - Flexible Tag Grid

struct FlexibleTagGrid: View {
    let tags: [String]
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tagRows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        TagFilterChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            action: {
                                if selectedTags.contains(tag) {
                                    selectedTags.remove(tag)
                                } else {
                                    selectedTags.insert(tag)
                                }
                            }
                        )
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var tagRows: [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentRowWidth: CGFloat = 0
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 64 // Account for padding
        
        for tag in tags {
            let tagWidth = estimatedTagWidth(for: tag)
            
            if currentRowWidth + tagWidth > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [tag]
                currentRowWidth = tagWidth
            } else {
                currentRow.append(tag)
                currentRowWidth += tagWidth
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private func estimatedTagWidth(for tag: String) -> CGFloat {
        // Rough estimation: 8 points per character + padding
        return CGFloat(tag.count * 8 + 24)
    }
}

// MARK: - Tag Filter Chip

struct TagFilterChip: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.quaternarySystemFill))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TechniqueFiltersView(
        filterOptions: TechniqueFilterOptions(
            categories: ["kicks", "strikes", "blocks"],
            beltLevels: ["10th_keup", "9th_keup", "8th_keup"],
            difficulties: ["basic", "intermediate", "advanced"],
            tags: ["fundamental", "linear", "circular", "defensive"]
        ),
        selectedBeltFilter: .constant(nil),
        selectedDifficulty: .constant(nil),
        selectedTags: .constant([])
    )
}