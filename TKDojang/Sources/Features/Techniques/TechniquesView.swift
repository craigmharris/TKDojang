import SwiftUI

/**
 * TechniquesView.swift
 * 
 * PURPOSE: Comprehensive technique reference system with advanced filtering and search
 * 
 * FEATURES:
 * - Hierarchical browsing by category with subcategory organization
 * - Multi-dimension filtering (belt level, difficulty, category, tags)
 * - Real-time search across all technique properties
 * - Visual technique cards with belt level indicators
 * - Detailed technique views with execution instructions
 * - Target area reference guides
 * - Belt requirement breakdowns
 * 
 * DESIGN PHILOSOPHY: Knowledge base rather than learning tool - comprehensive,
 * searchable reference for detailed technique information
 */

struct TechniquesView: View {
    @EnvironmentObject private var dataServices: DataServices
    @StateObject private var viewModel = TechniquesViewModel()
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedCategory: String?
    @State private var selectedBeltFilter: String?
    @State private var selectedDifficulty: String?
    @State private var selectedTags: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Bar
                searchAndFilterBar
                
                // Main Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContentView
                }
            }
            .navigationTitle("Technique Reference")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileSwitcher()
                }
            }
            .sheet(isPresented: $showingFilters) {
                TechniqueFiltersView(
                    filterOptions: viewModel.filterOptions,
                    selectedBeltFilter: $selectedBeltFilter,
                    selectedDifficulty: $selectedDifficulty,
                    selectedTags: $selectedTags
                )
            }
        }
        .task {
            await viewModel.loadTechniques(dataService: dataServices.techniquesService)
        }
        .onChange(of: searchText) { _, newValue in
            updateFilteredTechniques()
        }
        .onChange(of: selectedCategory) { _, _ in
            updateFilteredTechniques()
        }
        .onChange(of: selectedBeltFilter) { _, _ in
            updateFilteredTechniques()
        }
        .onChange(of: selectedDifficulty) { _, _ in
            updateFilteredTechniques()
        }
        .onChange(of: selectedTags) { _, _ in
            updateFilteredTechniques()
        }
    }
    
    // MARK: - Search and Filter Bar
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search techniques...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(10)
            
            // Category and Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Filter Button (moved to start for immediate visibility)
                    Button(action: { showingFilters = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filters")
                            if hasActiveFilters {
                                Text("(\(activeFilterCount))")
                                    .font(.caption)
                            }
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(hasActiveFilters ? Color.blue : Color(.quaternarySystemFill))
                        .foregroundColor(hasActiveFilters ? .white : .primary)
                        .cornerRadius(20)
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    // Categories
                    CategoryChip(
                        title: "All Categories",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(viewModel.categories, id: \.id) { category in
                        CategoryChip(
                            title: category.name,
                            isSelected: selectedCategory == category.id,
                            action: { selectedCategory = category.id }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Main Content Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading technique database...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if selectedCategory != nil || !searchText.isEmpty || hasActiveFilters {
            // Filtered/Search Results View
            filteredTechniquesView
        } else {
            // Category Overview View
            categoryOverviewView
        }
    }
    
    private var categoryOverviewView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Overview header
                VStack(spacing: 12) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Technique Reference")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Comprehensive database of \(viewModel.totalTechniques) TAGB Taekwondo techniques")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Category Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.categories, id: \.id) { category in
                        CategoryCard(
                            category: category,
                            onTap: { selectedCategory = category.id }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
    }
    
    private var filteredTechniquesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results Header
                HStack {
                    Text("\(viewModel.filteredTechniques.count) technique\(viewModel.filteredTechniques.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if selectedCategory != nil || hasActiveFilters {
                        Button("Clear All") {
                            clearAllFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Technique List
                ForEach(viewModel.filteredTechniques, id: \.id) { technique in
                    NavigationLink(destination: TechniqueDetailView(technique: technique)) {
                        TechniqueRowCard(technique: technique)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer(minLength: 20)
            }
            .padding(.top)
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasActiveFilters: Bool {
        selectedBeltFilter != nil || selectedDifficulty != nil || !selectedTags.isEmpty
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if selectedBeltFilter != nil { count += 1 }
        if selectedDifficulty != nil { count += 1 }
        count += selectedTags.count
        return count
    }
    
    // MARK: - Helper Methods
    
    private func updateFilteredTechniques() {
        viewModel.applyFilters(
            searchQuery: searchText,
            category: selectedCategory,
            beltLevel: selectedBeltFilter,
            difficulty: selectedDifficulty,
            tags: Array(selectedTags)
        )
    }
    
    private func clearAllFilters() {
        selectedCategory = nil
        selectedBeltFilter = nil
        selectedDifficulty = nil
        selectedTags.removeAll()
        searchText = ""
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.quaternarySystemFill))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: TechniqueCategory
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Category Icon
                Text(category.icon)
                    .font(.system(size: 40))
                
                VStack(spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(category.korean)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("\(category.techniqueCount) techniques")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Subcategory preview
                if let subcategories = category.subcategories, !subcategories.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(subcategories.prefix(2), id: \.name) { subcategory in
                            Text("• \(subcategory.name)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        if subcategories.count > 2 {
                            Text("+ \(subcategories.count - 2) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Technique Row Card

struct TechniqueRowCard: View {
    let technique: Technique
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and belt level
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(technique.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(technique.koreanName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(technique.names.koreanRomanized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Belt level indicator
                if let minBelt = technique.minimumBeltLevel {
                    BeltLevelBadge(beltLevel: minBelt)
                }
            }
            
            // Description
            Text(technique.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Tags and metadata
            HStack {
                // Category tag
                Text(technique.category.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(for: technique.category).opacity(0.2))
                    .foregroundColor(categoryColor(for: technique.category))
                    .cornerRadius(8)
                
                // Difficulty
                Text(technique.difficulty.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: technique.difficulty).opacity(0.2))
                    .foregroundColor(difficultyColor(for: technique.difficulty))
                    .cornerRadius(8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "kicks": return .blue
        case "strikes": return .red
        case "blocks": return .green
        case "stances": return .orange
        case "hand_techniques": return .purple
        case "sparring": return .pink
        case "fundamentals": return .brown
        case "combinations": return .indigo
        case "footwork": return .cyan
        case "belt_requirements": return .yellow
        default: return .gray
        }
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
}

// MARK: - Belt Level Badge

struct BeltLevelBadge: View {
    let beltLevel: String
    
    var body: some View {
        let colors = getBeltColors(for: beltLevel)
        
        HStack(spacing: 4) {
            // Belt stripe visual
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: colors.count > 1 ? colors : [colors.first ?? .gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20, height: 8)
            
            Text(beltDisplayName(for: beltLevel))
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.quaternarySystemFill))
        .cornerRadius(8)
    }
    
    private func getBeltColors(for beltLevel: String) -> [Color] {
        return BeltUtils.getBeltColorsLegacy(for: beltLevel)
    }
    
    private func beltDisplayName(for beltLevel: String) -> String {
        return BeltUtils.fileIdToBeltLevel(beltLevel)
    }
}

// MARK: - Techniques View Model

@MainActor
class TechniquesViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var categories: [TechniqueCategory] = []
    @Published var allTechniques: [Technique] = []
    @Published var filteredTechniques: [Technique] = []
    @Published var filterOptions = TechniqueFilterOptions(categories: [], beltLevels: [], difficulties: [], tags: [])
    @Published var loadingError: Error?
    
    var totalTechniques: Int {
        return allTechniques.count
    }
    
    func loadTechniques(dataService: TechniquesDataService) async {
        isLoading = true
        loadingError = nil
        
        await dataService.loadAllTechniques()
        
        if let error = dataService.loadingError {
            loadingError = error
        } else {
            categories = dataService.getCategories()
            allTechniques = dataService.getAllTechniques()
            filteredTechniques = allTechniques
            filterOptions = dataService.getFilterOptions()
        }
        
        isLoading = false
    }
    
    func applyFilters(
        searchQuery: String,
        category: String?,
        beltLevel: String?,
        difficulty: String?,
        tags: [String]
    ) {
        var filtered = allTechniques
        
        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { technique in
                let query = searchQuery.lowercased()
                return technique.names.english.lowercased().contains(query) ||
                       technique.names.korean.contains(query) ||
                       technique.names.koreanRomanized.lowercased().contains(query) ||
                       technique.description.lowercased().contains(query) ||
                       technique.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        // Apply category filter
        if let category = category {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Apply belt level filter
        if let beltLevel = beltLevel {
            filtered = filtered.filter { $0.beltLevels.contains(beltLevel) }
        }
        
        // Apply difficulty filter
        if let difficulty = difficulty {
            filtered = filtered.filter { $0.difficulty == difficulty }
        }
        
        // Apply tag filters
        if !tags.isEmpty {
            filtered = filtered.filter { technique in
                tags.allSatisfy { tag in technique.tags.contains(tag) }
            }
        }
        
        // Sort by minimum belt level (advanced to basic) then by name
        filtered.sort { lhs, rhs in
            let defaultBelt = BeltUtils.beltLevelToFileId("10th Keup")
            let lhsBelt = BeltUtils.getLegacySortOrder(for: lhs.minimumBeltLevel ?? defaultBelt)
            let rhsBelt = BeltUtils.getLegacySortOrder(for: rhs.minimumBeltLevel ?? defaultBelt)
            
            if lhsBelt != rhsBelt {
                return lhsBelt < rhsBelt // Lower sort order = higher belt level
            }
            
            return lhs.displayName < rhs.displayName
        }
        
        filteredTechniques = filtered
    }
}

#Preview {
    TechniquesView()
        .withDataServices()
}