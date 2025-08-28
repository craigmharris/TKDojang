import SwiftUI
import SwiftData

/**
 * GradingHistoryManagementView.swift
 * 
 * PURPOSE: Allow users to add, edit, and manage their grading history records
 * 
 * FEATURES:
 * - Add new grading records with full details
 * - Edit existing grading records
 * - Delete grading records with confirmation
 * - Proper belt level selection and validation
 * - Integration with ProgressCacheService for automatic cache updates
 */

struct GradingHistoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager
    
    let profile: UserProfile
    
    @State private var gradingRecords: [GradingRecord] = []
    @State private var isLoading = true
    @State private var showingAddGrading = false
    @State private var selectedGrading: GradingRecord?
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading grading history...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if gradingRecords.isEmpty {
                    EmptyGradingHistoryView {
                        showingAddGrading = true
                    }
                } else {
                    GradingHistoryList(
                        gradingRecords: gradingRecords,
                        onEdit: { grading in
                            selectedGrading = grading
                        },
                        onDelete: { grading in
                            deleteGrading(grading)
                        }
                    )
                }
            }
            .navigationTitle("Grading History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Grading", systemImage: "plus") {
                        showingAddGrading = true
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadGradingRecords()
            }
            .sheet(isPresented: $showingAddGrading) {
                GradingEntryView(
                    profile: profile,
                    onSave: { newGrading in
                        gradingRecords.append(newGrading)
                        gradingRecords.sort { $0.gradingDate > $1.gradingDate }
                        Task {
                            await refreshProgressCache()
                        }
                    }
                )
            }
            .sheet(item: $selectedGrading) { grading in
                GradingEntryView(
                    profile: profile,
                    existingGrading: grading,
                    onSave: { updatedGrading in
                        if let index = gradingRecords.firstIndex(where: { $0.id == updatedGrading.id }) {
                            gradingRecords[index] = updatedGrading
                        }
                        gradingRecords.sort { $0.gradingDate > $1.gradingDate }
                        Task {
                            await refreshProgressCache()
                        }
                    }
                )
            }
        }
    }
    
    private func loadGradingRecords() async {
        do {
            let profileId = profile.id
            let predicate = #Predicate<GradingRecord> { record in
                record.userProfile.id == profileId
            }
            
            let descriptor = FetchDescriptor<GradingRecord>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.gradingDate, order: .reverse)]
            )
            
            gradingRecords = try dataManager.modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            print("❌ Failed to load grading records: \(error)")
            isLoading = false
        }
    }
    
    private func deleteGrading(_ grading: GradingRecord) {
        dataManager.modelContext.delete(grading)
        
        do {
            try dataManager.modelContext.save()
            gradingRecords.removeAll { $0.id == grading.id }
            Task {
                await refreshProgressCache()
            }
        } catch {
            print("❌ Failed to delete grading record: \(error)")
        }
    }
    
    private func refreshProgressCache() async {
        await dataManager.progressCacheService.refreshCache(for: profile.id)
    }
}

// MARK: - Empty State

struct EmptyGradingHistoryView: View {
    let onAddGrading: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "medal.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Grading History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your belt gradings to track your Taekwondo journey and see progress analytics.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Add First Grading", systemImage: "plus") {
                onAddGrading()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grading History List

struct GradingHistoryList: View {
    let gradingRecords: [GradingRecord]
    let onEdit: (GradingRecord) -> Void
    let onDelete: (GradingRecord) -> Void
    
    var body: some View {
        List {
            ForEach(gradingRecords, id: \.id) { grading in
                GradingHistoryRow(
                    grading: grading,
                    onEdit: { onEdit(grading) },
                    onDelete: { onDelete(grading) }
                )
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Grading History Row

struct GradingHistoryRow: View {
    let grading: GradingRecord
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: grading.gradingDate)
    }
    
    private var statusColor: Color {
        grading.passed ? .green : .red
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Belt indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(grading.beltAchieved.shortName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(grading.passGrade.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(4)
                    
                    if !grading.examiner.isEmpty {
                        Text("• \(grading.examiner)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if !grading.notes.isEmpty {
                    Text(grading.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button("Edit", systemImage: "pencil") {
                onEdit()
            }
            
            Button("Delete", systemImage: "trash", role: .destructive) {
                onDelete()
            }
        }
        .onTapGesture {
            onEdit()
        }
    }
}

// MARK: - Grading Entry View

struct GradingEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dataManager) private var dataManager
    
    let profile: UserProfile
    let existingGrading: GradingRecord?
    let onSave: (GradingRecord) -> Void
    
    @State private var selectedDate = Date()
    @State private var selectedBeltTested: BeltLevel?
    @State private var selectedBeltAchieved: BeltLevel?
    @State private var gradingType = GradingType.regular
    @State private var passGrade = PassGrade.standard
    @State private var examiner = ""
    @State private var club = ""
    @State private var notes = ""
    @State private var preparationDays = 30
    @State private var passed = true
    
    @State private var availableBelts: [BeltLevel] = []
    @State private var isLoading = true
    
    private var isEditing: Bool {
        existingGrading != nil
    }
    
    private var preparationTime: TimeInterval {
        TimeInterval(preparationDays * 24 * 3600) // Convert days to seconds
    }
    
    init(profile: UserProfile, existingGrading: GradingRecord? = nil, onSave: @escaping (GradingRecord) -> Void) {
        self.profile = profile
        self.existingGrading = existingGrading
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Grading Details") {
                    DatePicker("Grading Date", selection: $selectedDate, displayedComponents: .date)
                    
                    Picker("Belt Tested For", selection: $selectedBeltTested) {
                        ForEach(availableBelts, id: \.id) { belt in
                            Text(belt.shortName).tag(belt as BeltLevel?)
                        }
                    }
                    
                    Picker("Belt Achieved", selection: $selectedBeltAchieved) {
                        ForEach(availableBelts, id: \.id) { belt in
                            Text(belt.shortName).tag(belt as BeltLevel?)
                        }
                    }
                    
                    Toggle("Passed", isOn: $passed)
                }
                
                Section("Grading Type & Grade") {
                    Picker("Grading Type", selection: $gradingType) {
                        ForEach(GradingType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    if passed {
                        Picker("Pass Grade", selection: $passGrade) {
                            ForEach(PassGrade.allCases.filter { $0 != .fail }, id: \.self) { grade in
                                Text(grade.displayName).tag(grade)
                            }
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Examiner", text: $examiner)
                    TextField("Club/Dojang", text: $club)
                    
                    HStack {
                        Text("Preparation Time")
                        Spacer()
                        Stepper("\(preparationDays) days", value: $preparationDays, in: 1...365)
                    }
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Grading" : "Add Grading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGrading()
                    }
                    .disabled(selectedBeltTested == nil || selectedBeltAchieved == nil)
                }
            }
            .task {
                await loadBeltLevels()
                setupExistingGrading()
            }
            .onChange(of: passed) { _, newValue in
                if !newValue {
                    passGrade = .fail
                }
            }
        }
    }
    
    private func loadBeltLevels() async {
        do {
            let descriptor = FetchDescriptor<BeltLevel>(
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            availableBelts = try dataManager.modelContext.fetch(descriptor)
            
            // Set default selections if not editing
            if !isEditing {
                selectedBeltTested = availableBelts.first { $0.id == profile.currentBeltLevel.id }
                selectedBeltAchieved = selectedBeltTested
            }
            
            isLoading = false
        } catch {
            print("❌ Failed to load belt levels: \(error)")
            isLoading = false
        }
    }
    
    private func setupExistingGrading() {
        guard let grading = existingGrading else { return }
        
        selectedDate = grading.gradingDate
        selectedBeltTested = grading.beltTested
        selectedBeltAchieved = grading.beltAchieved
        gradingType = grading.gradingType
        passGrade = grading.passGrade
        examiner = grading.examiner
        club = grading.club
        notes = grading.notes
        preparationDays = Int(grading.preparationTime / (24 * 3600))
        passed = grading.passed
    }
    
    private func saveGrading() {
        guard let beltTested = selectedBeltTested,
              let beltAchieved = selectedBeltAchieved else { return }
        
        if let existing = existingGrading {
            // Update existing grading
            existing.gradingDate = selectedDate
            existing.beltTested = beltTested
            existing.beltAchieved = beltAchieved
            existing.gradingType = gradingType
            existing.passGrade = passed ? passGrade : .fail
            existing.examiner = examiner
            existing.club = club
            existing.notes = notes
            existing.preparationTime = preparationTime
            existing.passed = passed
            existing.updatedAt = Date()
            
            do {
                try dataManager.modelContext.save()
                onSave(existing)
                dismiss()
            } catch {
                print("❌ Failed to update grading record: \(error)")
            }
        } else {
            // Create new grading
            let newGrading = GradingRecord(
                userProfile: profile,
                gradingDate: selectedDate,
                beltTested: beltTested,
                beltAchieved: beltAchieved,
                gradingType: gradingType,
                passGrade: passed ? passGrade : .fail,
                examiner: examiner,
                club: club,
                notes: notes,
                preparationTime: preparationTime,
                passed: passed
            )
            
            dataManager.modelContext.insert(newGrading)
            
            do {
                try dataManager.modelContext.save()
                onSave(newGrading)
                dismiss()
            } catch {
                print("❌ Failed to save grading record: \(error)")
            }
        }
    }
}