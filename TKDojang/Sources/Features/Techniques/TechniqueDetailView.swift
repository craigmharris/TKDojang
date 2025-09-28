import SwiftUI

/**
 * TechniqueDetailView.swift
 * 
 * PURPOSE: Comprehensive detailed view for individual techniques
 * 
 * FEATURES:
 * - Multi-language name display (Korean, Romanized, English, IPA)
 * - Detailed execution instructions with step-by-step breakdown
 * - Belt level requirements and progression information
 * - Target areas and applicable stances
 * - Variations and related techniques
 * - Common mistakes and corrections
 * - Visual placeholder areas for technique images
 * - Skills developed and training benefits
 */

struct TechniqueDetailView: View {
    let technique: Technique
    @State private var selectedImageIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // Technique Header
                techniqueHeader
                
                // Image Gallery
                if !technique.images.isEmpty {
                    imageGallery
                }
                
                // Execution Instructions
                if let execution = technique.execution {
                    executionSection(execution)
                }
                
                // Technique Details Grid
                techniqueDetailsGrid
                
                // Related Information
                relatedInformationSection
                
                // Common Mistakes
                if !technique.commonMistakes.isEmpty {
                    commonMistakesSection
                }
                
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle(technique.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    
    private var techniqueHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Names Section
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Korean")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(technique.koreanName)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Romanized")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(technique.names.koreanRomanized)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                }
                
                // IPA Pronunciation
                HStack(spacing: 8) {
                    Text("Pronunciation:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(technique.phoneticName)
                        .font(.body.monospaced())
                        .foregroundColor(.blue)
                }
            }
            
            // Description
            Text(technique.description)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            // Metadata badges
            HStack(spacing: 8) {
                MetadataBadge(
                    title: technique.category.replacingOccurrences(of: "_", with: " ").capitalized,
                    color: categoryColor(for: technique.category)
                )
                
                MetadataBadge(
                    title: technique.difficulty.capitalized,
                    color: difficultyColor(for: technique.difficulty)
                )
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Image Gallery
    
    private var imageGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Visual Reference")
                .font(.headline)
                .fontWeight(.semibold)
            
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(technique.images.enumerated()), id: \.offset) { index, imageName in
                    ImagePlaceholder(imageName: imageName, description: imageDescription(for: index))
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .frame(height: 200)
            .cornerRadius(12)
            
            // Image descriptions
            if selectedImageIndex < technique.images.count {
                Text(imageDescription(for: selectedImageIndex))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Execution Section
    
    private func executionSection(_ execution: TechniqueExecution) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Execution")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                if let chamber = execution.chamber {
                    ExecutionStep(title: "Chamber", description: chamber, icon: "1.circle.fill", color: .blue)
                }
                
                if let strike = execution.strike {
                    ExecutionStep(title: "Strike", description: strike, icon: "2.circle.fill", color: .red)
                } else if let block = execution.block {
                    ExecutionStep(title: "Block", description: block, icon: "2.circle.fill", color: .green)
                } else if let kick = execution.kick {
                    ExecutionStep(title: "Kick", description: kick, icon: "2.circle.fill", color: .orange)
                }
                
                if let retraction = execution.retraction {
                    ExecutionStep(title: "Recovery", description: retraction, icon: "3.circle.fill", color: .purple)
                } else if let recovery = execution.recovery {
                    ExecutionStep(title: "Recovery", description: recovery, icon: "3.circle.fill", color: .purple)
                }
                
                // Additional execution details
                if let setup = execution.setup {
                    ExecutionStep(title: "Setup", description: setup, icon: "gear.circle.fill", color: .gray)
                }
                
                if let pattern = execution.pattern {
                    ExecutionStep(title: "Pattern", description: pattern, icon: "arrow.triangle.2.circlepath", color: .indigo)
                }
                
                if let sequence = execution.sequence {
                    ExecutionStep(title: "Sequence", description: sequence, icon: "list.number", color: .brown)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Technique Details Grid
    
    private var techniqueDetailsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                // First Row: Belt Levels and Stances
                HStack(spacing: 16) {
                    DetailCard(
                        title: "Belt Levels",
                        icon: "medal.fill",
                        color: .yellow
                    ) {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(technique.beltLevels.prefix(6), id: \.self) { beltLevel in
                                HStack(spacing: 8) {
                                    BeltLevelBadge(beltLevel: beltLevel)
                                    Spacer()
                                }
                            }
                            
                            if technique.beltLevels.count > 6 {
                                Text("+ \(technique.beltLevels.count - 6) more levels")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if let stances = technique.applicableStances, !stances.isEmpty {
                        DetailCard(
                            title: "Stances",
                            icon: "figure.stand",
                            color: .orange
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(stances.prefix(4), id: \.self) { stance in
                                    Text("• \(stance.replacingOccurrences(of: "_", with: " ").capitalized)")
                                        .font(.caption)
                                }
                                
                                if stances.count > 4 {
                                    Text("+ \(stances.count - 4) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
                
                // Second Row: Target Areas and Skills
                HStack(spacing: 16) {
                    if let targets = technique.targetAreas, !targets.isEmpty {
                        DetailCard(
                            title: "Target Areas",
                            icon: "target",
                            color: .red
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(targets.prefix(4), id: \.self) { target in
                                    Text("• \(target.replacingOccurrences(of: "_", with: " ").capitalized)")
                                        .font(.caption)
                                }
                                
                                if targets.count > 4 {
                                    Text("+ \(targets.count - 4) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                    
                    if let skills = technique.skillsDeveloped, !skills.isEmpty {
                        DetailCard(
                            title: "Skills Developed",
                            icon: "brain.head.profile",
                            color: .green
                        ) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(skills.prefix(4), id: \.self) { skill in
                                    Text("• \(skill.replacingOccurrences(of: "_", with: " ").capitalized)")
                                        .font(.caption)
                                }
                                
                                if skills.count > 4 {
                                    Text("+ \(skills.count - 4) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 120)
            }
        }
    }
    
    // MARK: - Related Information
    
    private var relatedInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Related Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Variations
                if let variations = technique.variations, !variations.isEmpty {
                    RelatedSection(
                        title: "Variations",
                        icon: "arrow.branch",
                        items: variations,
                        color: .blue
                    )
                }
                
                // Transitions
                if let transitions = technique.transitionsTo, !transitions.isEmpty {
                    RelatedSection(
                        title: "Transitions To",
                        icon: "arrow.right.circle",
                        items: transitions,
                        color: .green
                    )
                }
                
                // Tags
                if !technique.tags.isEmpty {
                    TagsSection(tags: technique.tags)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Common Mistakes Section
    
    private var commonMistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Common Mistakes")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(technique.commonMistakes.enumerated()), id: \.offset) { index, mistake in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(mistake)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
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
    
    private func imageDescription(for index: Int) -> String {
        let baseName = technique.images[index].replacingOccurrences(of: ".jpg", with: "")
        let components = baseName.components(separatedBy: "_")
        
        if let lastComponent = components.last {
            switch lastComponent {
            case "chamber": return "Chambering position"
            case "execution", "strike", "kick", "block": return "Technique execution"
            case "finish", "recovery": return "Finishing position"
            case "setup": return "Initial setup"
            case "sequence": return "Movement sequence"
            case "detail": return "Technical detail"
            case "contact", "impact": return "Point of contact"
            default: return "Technique demonstration"
            }
        }
        
        return "Step \(index + 1) of technique"
    }
}

// MARK: - Supporting Views

struct MetadataBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct ImagePlaceholder: View {
    let imageName: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text(imageName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                )
        }
    }
}

struct ExecutionStep: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            content
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
}

struct RelatedSection: View {
    let title: String
    let icon: String
    let items: [String]
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(items.prefix(5), id: \.self) { item in
                        Text("• \(item.replacingOccurrences(of: "_", with: " ").capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if items.count > 5 {
                        Text("+ \(items.count - 5) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct TagsSection: View {
    let tags: [String]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "tag.fill")
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        let maxWidth = proposal.width ?? 0
        let totalHeight = rows.reduce(0) { result, row in
            result + row.maxHeight + spacing
        } - spacing
        
        return CGSize(width: maxWidth, height: max(0, totalHeight))
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        var yOffset = bounds.minY
        for row in rows {
            var xOffset = bounds.minX
            
            for subview in row.subviews {
                subview.place(
                    at: CGPoint(x: xOffset, y: yOffset),
                    proposal: ProposedViewSize(width: subview.sizeThatFits(.unspecified).width, height: row.maxHeight)
                )
                xOffset += subview.sizeThatFits(.unspecified).width + spacing
            }
            
            yOffset += row.maxHeight + spacing
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentRow.width + subviewSize.width + spacing > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
            }
            
            currentRow.add(subview: subview, width: subviewSize.width, height: subviewSize.height)
        }
        
        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    struct Row {
        var subviews: [LayoutSubview] = []
        var width: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        mutating func add(subview: LayoutSubview, width: CGFloat, height: CGFloat) {
            subviews.append(subview)
            self.width += width
            self.maxHeight = max(maxHeight, height)
            
            if !subviews.isEmpty {
                self.width += 8 // spacing
            }
        }
    }
}

#Preview {
    let sampleTechnique = Technique(
        id: "ap_chagi",
        names: TechniqueNames(
            korean: "앞차기",
            koreanRomanized: "Ap Chagi",
            english: "Front Kick",
            phonetic: "/ap.tʃʰa.ɡi/"
        ),
        description: "A linear kick delivered straight forward using the ball of the foot or heel, targeting the opponent's midsection or lower body.",
        category: "kicks",
        beltLevels: ["10th_keup", "9th_keup", "8th_keup"],
        difficulty: "basic",
        tags: ["linear", "fundamental", "basic", "leg"],
        images: ["ap_chagi_chamber.jpg", "ap_chagi_execution.jpg", "ap_chagi_contact.jpg"],
        commonMistakes: ["Poor chamber position", "Wrong striking surface", "Loss of balance"],
        execution: TechniqueExecution(
            chamber: "Lift knee high, foot pulled back toward hip",
            strike: "Drive foot straight forward, contact with ball of foot or heel",
            block: nil,
            retraction: "Pull foot back to chamber then return to stance",
            setup: nil,
            kick: nil,
            recovery: nil,
            pattern: nil,
            sequence: nil,
            technique: nil,
            footPosition: nil,
            weightDistribution: nil,
            bodyPosture: nil
        ),
        strikingTool: TechniqueNames(
            korean: "앞꿈치",
            koreanRomanized: "Apkumchi",
            english: "Ball of Foot",
            phonetic: "/ap.kɯm.tʃʰi/"
        ),
        blockingTool: nil,
        targetAreas: ["solar plexus", "abdomen", "groin"],
        applicableStances: ["gunnun_sogi", "narani_junbi_sogi"],
        variations: ["twimyo_ap_chagi", "naeryo_ap_chagi"],
        skillsDeveloped: ["balance", "leg_strength", "timing", "distance"],
        characteristics: nil,
        transitionsTo: ["dollyo_chagi", "yeop_chagi"],
        sparringType: nil,
        participants: nil,
        attackPattern: nil,
        defensePattern: nil,
        sequence: nil,
        combinationType: nil,
        totalMovements: nil,
        setupTechniques: nil,
        followUpOptions: nil,
        colorSignificance: nil,
        minimumTrainingTime: nil,
        requiredTechniques: nil,
        requiredFitness: nil,
        theoryRequirements: nil,
        pattern: nil,
        sparring: nil,
        breaking: nil,
        exerciseType: nil,
        movements: nil,
        footUsed: nil,
        primaryPurpose: nil,
        timing: nil
    )
    
    NavigationStack {
        TechniqueDetailView(technique: sampleTechnique)
    }
}