import SwiftUI

/**
 * PURPOSE: Main theory knowledge base view for belt-specific learning content
 * 
 * Displays organized theory sections including:
 * - Belt meanings and significance
 * - Taekwondo tenets and philosophy
 * - TAGB organizational history
 * - Korean terminology
 * - Grading theory requirements
 * 
 * Uses profile-aware filtering to show relevant content for user's current belt level.
 * Integrates with existing navigation patterns and theming system.
 */

struct TheoryView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var theoryContent: [String: TheoryContent] = [:]
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    
    private let availableCategories = ["Belt Knowledge", "Philosophy", "Organization", "Language"]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading Theory Content...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    theoryContentView
                }
            }
            .navigationTitle("Theory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileSwitcher()
                }
            }
        }
        .task {
            await loadTheoryContent()
        }
    }
    
    @ViewBuilder
    private var theoryContentView: some View {
        if let activeProfile = dataManager.profileService.activeProfile,
           let beltId = mapBeltLevelToId(activeProfile.currentBeltLevel.shortName),
           let content = theoryContent[beltId] {
            
            VStack(spacing: 0) {
                // Category Filter
                categoryFilterView
                
                // Theory Sections
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredSections(from: content)) { section in
                            NavigationLink(destination: TheoryDetailView(section: section)) {
                                TheorySectionCard(section: section)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            
        } else {
            ContentUnavailableView(
                "No Theory Content",
                systemImage: "book.closed",
                description: Text("Theory content is not available for your current belt level.")
            )
        }
    }
    
    @ViewBuilder
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                TheoryCategoryFilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                ForEach(availableCategories, id: \.self) { category in
                    TheoryCategoryFilterChip(
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
    
    private func filteredSections(from content: TheoryContent) -> [TheorySection] {
        if let selectedCategory = selectedCategory {
            return content.theorySections.filter { $0.category == selectedCategory }
        }
        return content.theorySections
    }
    
    private func loadTheoryContent() async {
        theoryContent = await TheoryContentLoader.loadAllTheoryContent()
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

struct TheorySectionCard: View {
    let section: TheorySection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(section.category)
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
            
            // Content preview
            if let overview = section.content.getString("overview") {
                Text(overview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Question count
            HStack {
                Image(systemName: "questionmark.circle")
                    .font(.caption)
                Text("\(section.questions.count) study questions")
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var categoryColor: Color {
        switch section.category {
        case "Belt Knowledge": return .blue
        case "Philosophy": return .purple
        case "Organization": return .green
        case "Language": return .orange
        default: return .gray
        }
    }
}

struct TheoryCategoryFilterChip: View {
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
    TheoryView()
        .environment(DataManager.shared)
}