import SwiftUI

/**
 * PURPOSE: Detailed view for individual theory sections
 * 
 * Displays comprehensive theory content including:
 * - Rich structured content (meanings, tenets, history)
 * - Interactive study questions
 * - Korean terminology with pronunciation
 * - Key points and detailed explanations
 * 
 * Provides an educational reading experience with quiz functionality
 * for reinforcing theoretical knowledge required for belt grading.
 */

struct TheoryDetailView: View {
    let section: TheorySection
    @State private var showingQuestions = false
    @State private var selectedQuestionIndex: Int? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Content sections based on category
                contentSection
                
                // Study questions
                if !section.questions.isEmpty {
                    questionsSection
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Quiz") {
                    showingQuestions.toggle()
                }
                .disabled(section.questions.isEmpty)
            }
        }
        .sheet(isPresented: $showingQuestions) {
            TheoryQuizView(questions: section.questions, sectionTitle: section.title)
        }
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.category)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.2))
                .foregroundColor(categoryColor)
                .clipShape(Capsule())
            
            if let overview = section.content.getString("overview") {
                Text(overview)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        switch section.category {
        case "Belt Knowledge":
            beltKnowledgeContent
        case "Philosophy":
            philosophyContent
        case "Organization":
            organizationContent
        case "Language":
            languageContent
        default:
            genericContent
        }
    }
    
    @ViewBuilder
    private var beltKnowledgeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let meaning = section.content.getString("meaning") {
                ContentCard(title: "Belt Meaning", icon: "medal") {
                    Text(meaning)
                        .font(.body)
                }
            }
            
            if let significance = section.content.getString("significance") {
                ContentCard(title: "Significance", icon: "star.circle") {
                    Text(significance)
                        .font(.body)
                }
            }
        }
    }
    
    @ViewBuilder
    private var philosophyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tenets = section.content.getArray("tenets", as: TenetInfo.self) {
                ContentCard(title: "The Five Tenets", icon: "hand.raised") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(tenets.enumerated()), id: \.offset) { index, tenet in
                            TenetRow(number: index + 1, tenet: tenet)
                            if index < tenets.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder 
    private var organizationContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let founding = section.content.getObject("founding", as: FoundingInfo.self) {
                ContentCard(title: "TAGB Founding", icon: "building.2") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Founded:")
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(founding.year)
                                .font(.body)
                        }
                        
                        HStack {
                            Text("Founder:")
                                .font(.body.weight(.medium))
                            Spacer()
                            Text(founding.founder)
                                .font(.body)
                        }
                        
                        Text("Purpose")
                            .font(.body.weight(.medium))
                            .padding(.top, 8)
                        
                        Text(founding.purpose)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let development = section.content.getString("development") {
                ContentCard(title: "Development", icon: "chart.line.uptrend.xyaxis") {
                    Text(development)
                        .font(.body)
                }
            }
        }
    }
    
    @ViewBuilder
    private var languageContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let greetingTerms = section.content.getArray("greeting_terms", as: KoreanTerm.self) {
                ContentCard(title: "Greetings", icon: "hand.wave") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(greetingTerms.enumerated()), id: \.offset) { index, term in
                            KoreanTermRow(term: term)
                            if index < greetingTerms.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
            
            if let dojangTerms = section.content.getArray("dojang_terms", as: KoreanTerm.self) {
                ContentCard(title: "Dojang Terms", icon: "house") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(dojangTerms.enumerated()), id: \.offset) { index, term in
                            KoreanTermRow(term: term)
                            if index < dojangTerms.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var genericContent: some View {
        ContentCard(title: "Content", icon: "doc.text") {
            Text("Generic content display for: \(section.category)")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var questionsSection: some View {
        ContentCard(title: "Study Questions", icon: "questionmark.circle") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(section.questions.enumerated()), id: \.offset) { index, question in
                    QuestionRow(
                        question: question,
                        isSelected: selectedQuestionIndex == index,
                        action: {
                            selectedQuestionIndex = selectedQuestionIndex == index ? nil : index
                        }
                    )
                }
            }
        }
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

// MARK: - Supporting Models

struct TenetInfo: Codable {
    let name: String
    let korean: String
    let description: String
}

struct FoundingInfo: Codable {
    let year: String
    let founder: String
    let purpose: String
}

struct KoreanTerm: Codable {
    let english: String
    let korean: String
    let usage: String
}

// MARK: - Supporting Views

struct ContentCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TenetRow: View {
    let number: Int
    let tenet: TenetInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(number).")
                    .font(.body.weight(.bold))
                    .foregroundColor(.accentColor)
                
                Text(tenet.name)
                    .font(.body.weight(.semibold))
                
                Spacer()
                
                Text(tenet.korean)
                    .font(.caption.italic())
                    .foregroundColor(.secondary)
            }
            
            Text(tenet.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct KoreanTermRow: View {
    let term: KoreanTerm
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(term.english)
                    .font(.body.weight(.medium))
                
                Spacer()
                
                Text(term.korean)
                    .font(.body.italic())
                    .foregroundColor(.accentColor)
            }
            
            Text(term.usage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuestionRow: View {
    let question: TheoryQuestion
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                HStack {
                    Text(question.question)
                        .font(.body.weight(.medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isSelected {
                Text(question.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    NavigationView {
        Text("Theory Detail Preview")
    }
}