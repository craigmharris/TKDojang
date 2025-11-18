import SwiftUI

/**
 * PURPOSE: Exercise-based LineWork view for traditional Taekwondo training
 *
 * Displays complete training exercises structured as movement sequences rather than
 * isolated techniques. Shows exercise sequences organized by movement type
 * (STATIC/FWD/BWD/FWD & BWD/ALTERNATING) with filtering capabilities.
 *
 * Progression Mode: Shows only next belt level exercises
 * Mastery Mode: Shows all prior belts + next belt level exercises
 * Ordered by descending belt level (1st keup → 10th keup)
 */

struct LineWorkView: View {
    @EnvironmentObject private var dataServices: DataServices
    @State private var lineWorkContent: [String: LineWorkContent] = [:]
    @State private var isLoading = true
    @State private var selectedMovementType: MovementType? = nil
    @State private var selectedCategory: String? = nil
    @State private var showingHelp = false

    private let availableCategories = ["Stances", "Blocking", "Striking", "Kicking"]
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading LineWork Content...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    exerciseContentView
                }
            }
            .navigationTitle("Line Work")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: { showingHelp = true }) {
                        Label("Help", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("linework-help-button")
                    .accessibilityLabel("Show line work help")
                }
            }
            .sheet(isPresented: $showingHelp) {
                LineWorkHelpSheet()
            }
        }
        .task {
            await loadLineWorkContent()
        }
    }
    
    @ViewBuilder
    private var exerciseContentView: some View {
        if let activeProfile = dataServices.profileService.activeProfile {
            let relevantContent = getRelevantContent(for: activeProfile)
            
            if !relevantContent.isEmpty {
                VStack(spacing: 0) {
                    // Filter Controls
                    filterControlsView
                    
                    // Exercise List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Belt Level Sections
                            ForEach(relevantContent, id: \.beltId) { content in
                                beltSectionView(content: content)
                            }
                        }
                        .padding()
                    }
                }
            } else {
                ContentUnavailableView(
                    "No LineWork Content",
                    systemImage: "figure.walk",
                    description: Text("LineWork exercises are not available for your current progression level.")
                )
            }
        } else {
            ContentUnavailableView(
                "No Profile Selected",
                systemImage: "person.circle",
                description: Text("Please select a profile to view LineWork exercises.")
            )
        }
    }
    
    @ViewBuilder
    private var filterControlsView: some View {
        VStack(spacing: 8) {
            // Movement Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All Types",
                        isSelected: selectedMovementType == nil,
                        action: { selectedMovementType = nil }
                    )
                    
                    ForEach(MovementType.allCases, id: \.self) { movementType in
                        FilterChip(
                            title: movementType.displayName,
                            icon: movementType.icon,
                            isSelected: selectedMovementType == movementType,
                            action: { selectedMovementType = movementType }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All Categories",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    ForEach(availableCategories, id: \.self) { category in
                        FilterChip(
                            title: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }
    
    /**
     * PURPOSE: Get relevant content based on profile progression mode
     *
     * Progression Mode: Only next belt level
     * Mastery Mode: All prior belts + next belt level
     * Ordered by descending belt level (1st keup → 10th keup)
     */
    private func getRelevantContent(for profile: UserProfile) -> [LineWorkContent] {
        let currentBeltLevel = profile.currentBeltLevel
        let modelContext = dataServices.modelContext
        let allBeltLevels = BeltUtils.fetchAllBeltLevels(from: modelContext)
        
        var relevantBeltLevels: [BeltLevel] = []
        
        if profile.learningMode == .progression {
            // Progression mode: only next belt
            if let nextBelt = BeltLevel.findNextBelt(after: currentBeltLevel, in: allBeltLevels) {
                relevantBeltLevels = [nextBelt]
            }
        } else {
            // Mastery mode: all prior belts + next belt
            // Get all belts with sort order greater than current (higher ranks earned)
            let priorBelts = allBeltLevels.filter { $0.sortOrder > currentBeltLevel.sortOrder }
            relevantBeltLevels.append(contentsOf: priorBelts)
            
            // Add next belt if available
            if let nextBelt = BeltLevel.findNextBelt(after: currentBeltLevel, in: allBeltLevels) {
                relevantBeltLevels.append(nextBelt)
            }
        }
        
        // Convert to content and filter
        var relevantContent: [LineWorkContent] = []
        
        for beltLevel in relevantBeltLevels {
            if let beltId = mapBeltLevelToId(beltLevel.shortName),
               let content = lineWorkContent[beltId] {
                relevantContent.append(content)
            }
        }
        
        // Sort by belt progression (1st keup first, 10th keup last)
        return relevantContent.sorted { content1, content2 in
            let sortOrder1 = BeltUtils.getSortOrder(for: content1.beltId, from: modelContext)
            let sortOrder2 = BeltUtils.getSortOrder(for: content2.beltId, from: modelContext)
            return sortOrder1 < sortOrder2
        }
    }
    
    private func extractBeltFromId(_ beltId: String) -> String {
        // Convert "1st_keup" → "1st keup"
        return beltId.replacingOccurrences(of: "_", with: " ")
    }
    
    private func filteredExercises(from exercises: [LineWorkExercise]) -> [LineWorkExercise] {
        var filtered = exercises
        
        // Filter by movement type
        if let selectedMovementType = selectedMovementType {
            filtered = filtered.filter { $0.movementType == selectedMovementType }
        }
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.categories.contains(selectedCategory) }
        }
        
        return filtered.sorted { $0.order < $1.order }
    }
    
    @ViewBuilder
    private func beltSectionView(content: LineWorkContent) -> some View {
        VStack(spacing: 12) {
            // Belt Header
            beltHeaderView(content: content)
            
            // Exercise Banners
            ForEach(filteredExercises(from: content.lineWorkExercises)) { exercise in
                NavigationLink(destination: LineWorkExerciseDetailView(exercise: exercise, beltContent: content)) {
                    LineWorkExerciseBanner(exercise: exercise, beltLevel: content.beltLevel)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        }
    }
    
    @ViewBuilder
    private func beltHeaderView(content: LineWorkContent) -> some View {
        HStack {
            // Belt-themed icon matching theory elements design
            BeltIconCircle(beltLevel: getBeltLevelFromContent(content))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(content.beltLevel)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                
                Text("\(content.totalExercises) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private func beltColor(_ colorName: String) -> Color {
        let colors = BeltUtils.getBeltColorsLegacy(for: colorName.lowercased())
        return colors.first ?? .gray
    }
    
    private func loadLineWorkContent() async {
        lineWorkContent = await LineWorkContentLoader.loadAllLineWorkContent()
        isLoading = false
    }
    
    private func mapBeltLevelToId(_ beltLevel: String) -> String? {
        return BeltUtils.beltLevelToFileId(beltLevel)
    }
    
    /**
     * Convert LineWorkContent to BeltLevel for theming
     */
    private func getBeltLevelFromContent(_ content: LineWorkContent) -> BeltLevel {
        // Use actual TAGB belt colors matching belt_system.json
        switch content.beltLevel {
        case let level where level.contains("10th Keup"):
            return createMockBeltLevel(name: "10th Keup", primary: "#F5F5F5", secondary: "#F5F5F5")
        case let level where level.contains("9th Keup"):
            return createMockBeltLevel(name: "9th Keup", primary: "#F5F5F5", secondary: "#FFD60A")
        case let level where level.contains("8th Keup"):
            return createMockBeltLevel(name: "8th Keup", primary: "#FFD60A", secondary: "#FFD60A")
        case let level where level.contains("7th Keup"):
            return createMockBeltLevel(name: "7th Keup", primary: "#FFD60A", secondary: "#4CAF50")
        case let level where level.contains("6th Keup"):
            return createMockBeltLevel(name: "6th Keup", primary: "#4CAF50", secondary: "#4CAF50")
        case let level where level.contains("5th Keup"):
            return createMockBeltLevel(name: "5th Keup", primary: "#4CAF50", secondary: "#2196F3")
        case let level where level.contains("4th Keup"):
            return createMockBeltLevel(name: "4th Keup", primary: "#2196F3", secondary: "#2196F3")
        case let level where level.contains("3rd Keup"):
            return createMockBeltLevel(name: "3rd Keup", primary: "#2196F3", secondary: "#F44336")
        case let level where level.contains("2nd Keup"):
            return createMockBeltLevel(name: "2nd Keup", primary: "#F44336", secondary: "#F44336")
        case let level where level.contains("1st Keup"):
            return createMockBeltLevel(name: "1st Keup", primary: "#F44336", secondary: "#000000")
        default:
            return createMockBeltLevel(name: "Default", primary: "#6C757D", secondary: "#6C757D")
        }
    }
    
    private func createMockBeltLevel(name: String, primary: String, secondary: String) -> BeltLevel {
        let belt = BeltLevel(
            name: name,
            shortName: name,
            colorName: name,
            sortOrder: 0,
            isKyup: true
        )
        belt.primaryColor = primary
        belt.secondaryColor = secondary
        return belt
    }
}

// MARK: - Supporting Views

struct LineWorkExerciseBanner: View {
    let exercise: LineWorkExercise
    let beltLevel: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Movement Direction Indicator
            VStack(spacing: 4) {
                Image(systemName: exercise.movementType.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(exercise.movementType.displayName)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.accentColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 60)
            
            // Exercise Details
            VStack(alignment: .leading, spacing: 6) {
                // Exercise Name
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Frequency/Repetitions
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption)
                        Text("\(exercise.execution.repetitions)x")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                    
                    // Categories badges
                    HStack(spacing: 4) {
                        ForEach(exercise.categories.prefix(2), id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(categoryColor(category).opacity(0.2))
                                .foregroundColor(categoryColor(category))
                                .clipShape(Capsule())
                        }
                        
                        if exercise.categories.count > 2 {
                            Text("+\(exercise.categories.count - 2)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func categoryColor(_ category: String) -> Color {
        guard let lineWorkCategory = LineWorkCategory(rawValue: category) else { return .gray }
        return Color(lineWorkCategory.color)
    }
}


struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}


/**
 * PURPOSE: Comprehensive LineWork exercise detail view with multilingual content
 *
 * Features complete technique breakdown with English/Romanised/Hangul translations,
 * execution details, movement patterns, and practice guidance.
 */
struct LineWorkExerciseDetailView: View {
    let exercise: LineWorkExercise
    let beltContent: LineWorkContent
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Section
                exerciseHeaderView
                
                // Movement Type & Categories
                movementInfoView
                
                // Techniques Breakdown
                techniquesBreakdownView
                
                // Execution Details
                executionDetailsView
                
                // Practice Guidance
                practiceGuidanceView
            }
            .padding()
        }
        .navigationTitle("Exercise Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var exerciseHeaderView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(exercise.name)
                .font(.title2.weight(.bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 4) {
                Text("Belt Level:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(beltContent.beltLevel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(beltColor(beltContent.beltColor).opacity(0.2))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Movement Info
    @ViewBuilder
    private var movementInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderView(title: "Movement Information", icon: "arrow.triangle.2.circlepath")
            
            HStack(spacing: 16) {
                // Movement Type
                VStack(spacing: 8) {
                    Image(systemName: exercise.movementType.icon)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text(exercise.movementType.displayName)
                        .font(.caption.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Categories & Repetitions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.caption)
                        Text("\(exercise.execution.repetitions) repetitions")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(exercise.categories, id: \.self) { category in
                            Text(category)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(categoryColor(category).opacity(0.2))
                                .foregroundColor(categoryColor(category))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Techniques Breakdown
    @ViewBuilder
    private var techniquesBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderView(title: "Techniques", icon: "figure.martial.arts")
            
            ForEach(exercise.techniques) { technique in
                techniqueDetailCard(technique: technique)
            }
        }
    }
    
    @ViewBuilder
    private func techniqueDetailCard(technique: LineWorkTechniqueDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Technique Name
            Text(technique.english)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Multilingual Content
            VStack(alignment: .leading, spacing: 8) {
                languageRow(label: "English", text: technique.english)
                languageRow(label: "Romanised", text: technique.romanised)
                languageRow(label: "Hangul", text: technique.hangul)
            }
            
            // Technical Details
            if technique.targetArea != nil || technique.description != nil {
                VStack(alignment: .leading, spacing: 6) {
                    if let targetArea = technique.targetArea {
                        detailRow(icon: "target", label: "Target Area", text: targetArea)
                    }
                    
                    if let description = technique.description {
                        detailRow(icon: "info.circle", label: "Description", text: description)
                    }
                    
                    detailRow(icon: "tag", label: "Category", text: technique.category)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func languageRow(label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label + ":")
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)

            if label == "Hangul" {
                Text(text)
                    .koreanFont(size: 20)
                    .foregroundColor(.primary)
            } else {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
            }

            Spacer()
        }
    }
    
    @ViewBuilder
    private func detailRow(icon: String, label: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.accentColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // MARK: - Execution Details
    @ViewBuilder
    private var executionDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderView(title: "Execution Details", icon: "gearshape")
            
            VStack(alignment: .leading, spacing: 12) {
                // Movement Pattern (full width, if available)
                if let movementPattern = exercise.execution.movementPattern {
                    fullWidthDetailCard(
                        title: "Movement Pattern",
                        icon: "arrow.right.circle",
                        content: movementPattern
                    )
                }
                
                // Sequence Notes (full width, if available)
                if let sequenceNotes = exercise.execution.sequenceNotes {
                    fullWidthDetailCard(
                        title: "Sequence Notes",
                        icon: "note.text",
                        content: sequenceNotes
                    )
                }
                
                // Key Points (full width)
                fullWidthListCard(
                    title: "Key Points",
                    icon: "star.circle",
                    items: exercise.execution.keyPoints,
                    color: .blue
                )
                
                // Common Mistakes & Execution Tips (half width side-by-side)
                HStack(alignment: .top, spacing: 12) {
                    if let commonMistakes = exercise.execution.commonMistakes, !commonMistakes.isEmpty {
                        listSectionCard(
                            title: "Common Mistakes",
                            icon: "exclamationmark.triangle",
                            items: commonMistakes,
                            color: .red
                        )
                    }
                    
                    if let executionTips = exercise.execution.executionTips, !executionTips.isEmpty {
                        listSectionCard(
                            title: "Execution Tips",
                            icon: "lightbulb",
                            items: executionTips,
                            color: .orange
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailSectionCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    @ViewBuilder
    private func fullWidthDetailCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    @ViewBuilder
    private func fullWidthListCard(title: String, icon: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    @ViewBuilder
    private func listSectionCard(title: String, icon: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Practice Guidance
    @ViewBuilder
    private var practiceGuidanceView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeaderView(title: "Practice Guidance", icon: "figure.walk")
            
            VStack(alignment: .leading, spacing: 12) {
                // Direction & Repetitions
                HStack(spacing: 16) {
                    practiceInfoCard(
                        title: "Direction",
                        value: exercise.execution.direction.capitalized,
                        icon: "compass"
                    )
                    
                    practiceInfoCard(
                        title: "Repetitions",
                        value: "\(exercise.execution.repetitions)x",
                        icon: "repeat"
                    )
                }
                
                // Skill Focus (from belt content)
                skillFocusCard()
            }
        }
    }
    
    @ViewBuilder
    private func practiceInfoCard(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func skillFocusCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .foregroundColor(.purple)
                Text("Skill Focus Areas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(beltContent.skillFocus, id: \.self) { focus in
                    Text(focus)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func sectionHeaderView(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Utility Functions
    private func categoryColor(_ category: String) -> Color {
        guard let lineWorkCategory = LineWorkCategory(rawValue: category) else { return .gray }
        return Color(lineWorkCategory.color)
    }
    
    private func beltColor(_ colorName: String) -> Color {
        let colors = BeltUtils.getBeltColorsLegacy(for: colorName.lowercased())
        return colors.first ?? .gray
    }
}

/**
 * Belt icon showing belt colors in circular format with white border, matching theory elements
 */
struct BeltIconCircle: View {
    let beltLevel: BeltLevel
    
    var body: some View {
        let theme = BeltTheme(from: beltLevel)
        
        Circle()
            .fill(theme.primaryColor)
            .overlay(
                // Center stripe for tag belts (belts with different primary/secondary colors)
                Group {
                    if theme.secondaryColor != theme.primaryColor {
                        // Horizontal stripe across the center for tag belt representation
                        Rectangle()
                            .fill(theme.secondaryColor)
                            .frame(height: 10)
                            .clipShape(Circle())
                    }
                }
            )
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
            )
    }
}

#Preview {
    LineWorkView()
        .environmentObject(DataServices.shared)
}