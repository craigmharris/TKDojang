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
 * FEATURES:
 * - Profile-aware filtering respecting learning modes:
 *   * Progression: Shows only current belt content
 *   * Mastery: Shows all content up to and including current belt
 * - Belt-themed icons on theory tiles showing proper belt colors
 * - Content sorted by belt level (descending - highest belt first)
 * - Dynamic category filters based on visible content types
 * - Integration with existing navigation patterns and theming system
 * 
 * RECENT ENHANCEMENTS:
 * - Fixed mastery mode to show all prior belt theory content
 * - Added colored belt icons to theory content tiles
 * - Implemented belt level descending sort order
 * - Made filtering buttons dynamic based on available content
 */

struct TheoryView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var theoryContent: [String: TheoryContent] = [:]
    @State private var isLoading = true
    @State private var selectedCategory: String? = nil
    @State private var availableCategories: [String] = []
    
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
        .onChange(of: dataServices.profileService.activeProfile?.learningMode) { _, _ in
            // Update available categories when learning mode changes
            if let activeProfile = dataServices.profileService.activeProfile {
                let relevantSections = getRelevantTheorySections(for: activeProfile)
                updateAvailableCategories(from: relevantSections)
            }
        }
    }
    
    @ViewBuilder
    private var theoryContentView: some View {
        if let activeProfile = dataServices.profileService.activeProfile {
            let relevantSections = getRelevantTheorySections(for: activeProfile)
            
            if !relevantSections.isEmpty {
                VStack(spacing: 0) {
                    // Category Filter
                    categoryFilterView
                    
                    // Theory Sections
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAndSortedSections(relevantSections)) { sectionWithBelt in
                                NavigationLink(destination: TheoryDetailView(section: sectionWithBelt.section)) {
                                    TheorySectionCard(
                                        section: sectionWithBelt.section,
                                        beltLevel: sectionWithBelt.beltLevel
                                    )
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
        } else {
            ContentUnavailableView(
                "No Profile Selected",
                systemImage: "person.circle",
                description: Text("Please select a profile to view theory content.")
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
    
    // MARK: - Theory Content Processing
    
    /**
     * Helper structure to associate theory sections with their belt levels
     * for proper sorting and belt icon display
     */
    private struct TheorySectionWithBelt: Identifiable {
        let section: TheorySection
        let beltLevel: String
        let beltSortOrder: Int
        
        var id: String { section.id }
    }
    
    /**
     * Get relevant theory sections based on learning mode
     * - Progression: Only current belt content
     * - Mastery: All content up to and including current belt
     */
    private func getRelevantTheorySections(for profile: UserProfile) -> [TheorySectionWithBelt] {
        let currentBeltSortOrder = profile.currentBeltLevel.sortOrder
        var relevantSections: [TheorySectionWithBelt] = []
        
        let beltMapping = createBeltMapping()
        
        for (beltId, theoryContent) in theoryContent {
            if let beltSortOrder = beltMapping[beltId] {
                // Include content based on learning mode
                let shouldInclude: Bool
                switch profile.learningMode {
                case .progression:
                    shouldInclude = beltSortOrder == currentBeltSortOrder
                case .mastery:
                    shouldInclude = beltSortOrder <= currentBeltSortOrder
                }
                
                if shouldInclude {
                    for section in theoryContent.theorySections {
                        relevantSections.append(TheorySectionWithBelt(
                            section: section,
                            beltLevel: theoryContent.beltLevel,
                            beltSortOrder: beltSortOrder
                        ))
                    }
                }
            }
        }
        
        return relevantSections
    }
    
    /**
     * Filter by selected category and sort by belt level (descending)
     */
    private func filteredAndSortedSections(_ sections: [TheorySectionWithBelt]) -> [TheorySectionWithBelt] {
        var filtered = sections
        
        // Apply category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.section.category == selectedCategory }
        }
        
        // Sort by belt level descending (highest belt first)
        filtered.sort { $0.beltSortOrder > $1.beltSortOrder }
        
        return filtered
    }
    
    /**
     * Generate dynamic category list from available theory sections
     */
    private func updateAvailableCategories(from sections: [TheorySectionWithBelt]) {
        let categories = Set(sections.map { $0.section.category })
        availableCategories = Array(categories).sorted()
    }
    
    /**
     * Get belt levels to load based on user's learning mode
     * - Progression: Only current belt
     * - Mastery: Current belt and all lower belts
     */
    private func getBeltLevelsToLoad(for profile: UserProfile) -> [String] {
        let beltIdMapping = BeltUtils.getBeltIdMapping(from: dataServices.modelContext)
        let currentBeltId = BeltUtils.beltLevelToFileId(profile.currentBeltLevel.name)
        
        switch profile.learningMode {
        case .progression:
            return [currentBeltId]
        case .mastery:
            // Load current belt and all lower belts
            let currentSortOrder = profile.currentBeltLevel.sortOrder
            return beltIdMapping.keys.filter { beltId in
                if let sortOrder = beltIdMapping[beltId] {
                    return sortOrder >= currentSortOrder
                }
                return false
            }
        }
    }
    
    /**
     * Create mapping from belt ID to sort order for proper sorting
     */
    private func createBeltMapping() -> [String: Int] {
        return BeltUtils.getBeltIdMapping(from: dataServices.modelContext)
    }
    
    /**
     * Load only relevant theory content based on active profile's learning mode
     * Lazy loading approach - only loads content that will actually be displayed
     */
    private func loadTheoryContent() async {
        guard let activeProfile = dataServices.profileService.activeProfile else {
            print("⚠️ No active profile for theory content loading")
            isLoading = false
            return
        }
        
        print("🔄 Loading theory content for profile: \(activeProfile.name), belt: \(activeProfile.currentBeltLevel.name), mode: \(activeProfile.learningMode)")
        
        // Determine which belt levels to load based on learning mode
        let beltLevelsToLoad = getBeltLevelsToLoad(for: activeProfile)
        var loadedContent: [String: TheoryContent] = [:]
        
        for beltId in beltLevelsToLoad {
            if let content = await TheoryContentLoader.loadTheoryContent(for: beltId) {
                loadedContent[beltId] = content
            }
        }
        
        theoryContent = loadedContent
        print("✅ Loaded theory content for \(loadedContent.count) belt levels (lazy loading)")
        
        // Update available categories based on loaded content
        let relevantSections = getRelevantTheorySections(for: activeProfile)
        updateAvailableCategories(from: relevantSections)
        
        isLoading = false
    }
    
    private func mapBeltLevelToId(_ beltLevel: String) -> String? {
        return BeltUtils.beltLevelToFileId(beltLevel)
    }
}

struct TheorySectionCard: View {
    let section: TheorySection
    let beltLevel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Belt icon with proper coloring
                if let beltLevelObj = getBeltLevelObject(from: beltLevel) {
                    BeltIcon(beltLevel: beltLevelObj)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(section.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.2))
                            .foregroundColor(categoryColor)
                            .clipShape(Capsule())
                        
                        Text(beltLevel)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    
    /**
     * Convert belt level string to BeltLevel object for proper theming
     * Uses correct TAGB belt colors from belt_system.json
     */
    private func getBeltLevelObject(from beltLevelString: String) -> BeltLevel? {
        // Use actual TAGB belt colors matching belt_system.json
        switch beltLevelString {
        case "10th Keup (White Belt)", "10th Keup":
            return createMockBeltLevel(name: "10th Keup", primary: "#F5F5F5", secondary: "#F5F5F5", sort: 15)
        case "9th Keup (White Belt - Yellow Tag)", "9th Keup":
            return createMockBeltLevel(name: "9th Keup", primary: "#F5F5F5", secondary: "#FFD60A", sort: 14)
        case "8th Keup (Yellow Belt)", "8th Keup":
            return createMockBeltLevel(name: "8th Keup", primary: "#FFD60A", secondary: "#FFD60A", sort: 13)
        case "7th Keup (Yellow Belt - Green Tag)", "7th Keup":
            return createMockBeltLevel(name: "7th Keup", primary: "#FFD60A", secondary: "#4CAF50", sort: 12)
        case "6th Keup (Green Belt)", "6th Keup":
            return createMockBeltLevel(name: "6th Keup", primary: "#4CAF50", secondary: "#4CAF50", sort: 11)
        case "5th Keup (Green Belt - Blue Tag)", "5th Keup":
            return createMockBeltLevel(name: "5th Keup", primary: "#4CAF50", secondary: "#2196F3", sort: 10)
        case "4th Keup (Blue Belt)", "4th Keup":
            return createMockBeltLevel(name: "4th Keup", primary: "#2196F3", secondary: "#2196F3", sort: 9)
        case "3rd Keup (Blue Belt - Red Tag)", "3rd Keup":
            return createMockBeltLevel(name: "3rd Keup", primary: "#2196F3", secondary: "#F44336", sort: 8)
        case "2nd Keup (Red Belt)", "2nd Keup":
            return createMockBeltLevel(name: "2nd Keup", primary: "#F44336", secondary: "#F44336", sort: 7)
        case "1st Keup (Red Belt - Black Tag)", "1st Keup":
            return createMockBeltLevel(name: "1st Keup", primary: "#F44336", secondary: "#000000", sort: 6)
        case "1st Dan (Black Belt)", "1st Dan":
            return createMockBeltLevel(name: "1st Dan", primary: "#000000", secondary: "#000000", sort: 5)
        case "2nd Dan (Black Belt)", "2nd Dan":
            return createMockBeltLevel(name: "2nd Dan", primary: "#000000", secondary: "#000000", sort: 4)
        default:
            return nil
        }
    }
    
    private func createMockBeltLevel(name: String, primary: String, secondary: String, sort: Int) -> BeltLevel {
        let belt = BeltLevel(
            name: name,
            shortName: name,
            colorName: name.replacingOccurrences(of: " Keup", with: ""),
            sortOrder: sort,
            isKyup: true
        )
        belt.primaryColor = primary
        belt.secondaryColor = secondary
        return belt
    }
}

/**
 * Belt icon showing belt colors in horizontal stripe format matching existing belt components
 */
struct BeltIcon: View {
    let beltLevel: BeltLevel
    
    var body: some View {
        let theme = BeltTheme(from: beltLevel)
        
        RoundedRectangle(cornerRadius: 4)
            .fill(theme.primaryColor)
            .overlay(
                // Center stripe for tag belts (belts with different primary/secondary colors)
                Group {
                    if theme.secondaryColor != theme.primaryColor {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.secondaryColor)
                            .frame(height: 8) // Center third of 24px height
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
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