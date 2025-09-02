import Foundation
import SwiftData

/**
 * StepSparringContentLoader.swift
 * 
 * PURPOSE: Loads step sparring content from JSON files into SwiftData models
 * 
 * FEATURES:
 * - JSON-based content loading for step sparring sequences
 * - Belt level association and filtering
 * - Structured attack/defense/counter data
 * - Korean terminology integration
 */

struct StepSparringContentLoader {
    private let stepSparringService: StepSparringDataService
    
    init(stepSparringService: StepSparringDataService) {
        self.stepSparringService = stepSparringService
    }
    
    /**
     * Loads all step sparring content from JSON files - DYNAMIC SCANNING
     * Scans StepSparring directory and loads all JSON files based on their content type
     */
    func loadAllContent() {
        // Dynamically scan for all step sparring JSON files
        let stepSparringFiles = getStepSparringJsonFiles()
        
        print("DEBUG: 🔍 Found \(stepSparringFiles.count) step sparring JSON files to load: \(stepSparringFiles)")
        
        for filename in stepSparringFiles {
            loadContentFromFile(filename: filename)
        }
    }
    
    /**
     * Dynamically scans all step sparring JSON files in bundle
     */
    private func getStepSparringJsonFiles() -> [String] {
        var foundFiles: [String] = []
        
        // Check bundle root for step sparring files (Xcode copies them to root, not subdirectory)
        guard let bundlePath = Bundle.main.resourcePath else {
            print("❌ Could not get bundle resource path")
            return []
        }
        
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
            let stepSparringFiles = contents.filter { 
                $0.hasSuffix(".json") && ($0.contains("step") || $0.contains("sparring"))
            }
            foundFiles = stepSparringFiles.map { $0.replacingOccurrences(of: ".json", with: "") }
            print("DEBUG: 📁 Found \(stepSparringFiles.count) step sparring JSON files in bundle root: \(stepSparringFiles)")
        } catch {
            print("❌ Failed to scan bundle root for step sparring files: \(error)")
        }
        
        return foundFiles.sorted()
    }
    
    /**
     * Maps JSON type string to StepSparringType enum
     */
    private func getStepSparringType(from jsonType: String) -> StepSparringType {
        switch jsonType {
        case "three_step":
            return .threeStep
        case "two_step":
            return .twoStep
        case "one_step":
            return .oneStep
        case "semi_free":
            return .semiFree
        default:
            print("⚠️ Unknown step sparring type '\(jsonType)' - defaulting to three_step")
            return .threeStep
        }
    }
    
    /**
     * Generic method to load content from any step sparring JSON file
     * Automatically detects type from JSON content
     */
    private func loadContentFromFile(filename: String) {
        // Use the same pattern as ModularContentLoader for consistency
        var url: URL?
        
        print("DEBUG: 🔍 Searching for \(filename).json...")
        
        // Try main bundle root first (where Xcode copies the files)
        url = Bundle.main.url(forResource: filename, withExtension: "json")
        if url != nil {
            print("DEBUG: ✅ Found \(filename).json in main bundle root")
        } else {
            print("DEBUG: ❌ Not found in main bundle root")
        }
        
        guard let fileUrl = url else {
            print("❌ Could not find \(filename).json in any location")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let contentData = try JSONDecoder().decode(StepSparringContentData.self, from: data)
            
            // Detect type from JSON content
            let sparringType = getStepSparringType(from: contentData.type)
            
            print("DEBUG: 📚 Loading \(contentData.sequences.count) \(sparringType.displayName) sparring sequences from \(filename)")
            
            // Create sequences from JSON data
            for sequenceData in contentData.sequences {
                let sequence = createSequence(from: sequenceData, type: sparringType)
                stepSparringService.modelContext.insert(sequence)
                
                // Save immediately after each sequence to prevent relationship corruption
                do {
                    try stepSparringService.modelContext.save()
                    print("DEBUG: ✅ Saved sequence #\(sequenceData.sequenceNumber)")
                } catch {
                    print("DEBUG: ❌ Failed to save sequence #\(sequenceData.sequenceNumber): \(error)")
                }
            }
            print("DEBUG: ✅ Successfully loaded \(contentData.sequences.count) \(sparringType.displayName) sparring sequences from \(filename)")
            
        } catch {
            print("❌ Failed to load sparring content from \(filename): \(error)")
        }
    }
    
    /**
     * Creates a StepSparringSequence from JSON data - NO BELT RELATIONSHIPS
     */
    private func createSequence(from data: StepSparringSequenceData, type: StepSparringType) -> StepSparringSequence {
        let sequence = StepSparringSequence(
            name: data.name,
            type: type,
            sequenceNumber: data.sequenceNumber,
            sequenceDescription: data.description,
            difficulty: data.difficulty,
            keyLearningPoints: data.keyLearningPoints
        )
        
        // Store JSON belt level data without SwiftData relationships
        sequence.applicableBeltLevelIds = data.applicableBeltLevels
        // sequence.beltLevels = [] // Leave empty to avoid relationship crashes
        
        print("🔍 BELT DEBUG: Sequence #\(data.sequenceNumber) '\(data.name)':")
        print("   JSON belt IDs: \(data.applicableBeltLevels)")
        print("   Stored in applicableBeltLevelIds: \(sequence.applicableBeltLevelIds)")
        
        // Create steps and sort by step number to ensure correct order
        sequence.steps = data.steps
            .sorted { $0.stepNumber < $1.stepNumber }
            .map { stepData in
                createStep(from: stepData, sequence: sequence)
            }
        
        return sequence
    }
    
    /**
     * Creates a StepSparringStep from JSON data
     */
    private func createStep(from data: StepSparringStepData, sequence: StepSparringSequence) -> StepSparringStep {
        let attackAction = createAction(from: data.attack)
        let defenseAction = createAction(from: data.defense)
        
        let step = StepSparringStep(
            sequence: sequence,
            stepNumber: data.stepNumber,
            attackAction: attackAction,
            defenseAction: defenseAction,
            timing: data.timing,
            keyPoints: data.keyPoints,
            commonMistakes: data.commonMistakes
        )
        
        // Add counter-attack if present - ONLY FOR FINAL STEP
        if let counterData = data.counter {
            // Validate that counter attacks only appear in the final step
            let totalSteps = sequence.type.stepCount
            if data.stepNumber == totalSteps {
                step.counterAction = createAction(from: counterData)
                print("✅ Added counter attack to final step #\(data.stepNumber) of '\(sequence.name)'")
            } else {
                print("⚠️ WARNING: Counter attack found in step #\(data.stepNumber) of '\(sequence.name)' - should only be in final step #\(totalSteps)")
                // Still add it but log the warning
                step.counterAction = createAction(from: counterData)
            }
        }
        
        return step
    }
    
    /**
     * Creates a StepSparringAction from JSON data
     */
    private func createAction(from data: StepSparringActionData) -> StepSparringAction {
        // Combine stance, hand, and target into execution string
        let execution = "\(data.hand) \(data.stance) to \(data.target)"
        
        return StepSparringAction(
            technique: data.technique,
            koreanName: data.koreanName,
            execution: execution,
            actionDescription: data.description
        )
    }
    
}

// MARK: - JSON Data Models

struct StepSparringContentData: Codable {
    let beltLevel: String
    let category: String
    let type: String
    let description: String
    let sequences: [StepSparringSequenceData]
    
    enum CodingKeys: String, CodingKey {
        case beltLevel = "belt_level"
        case category
        case type
        case description
        case sequences
    }
}

struct StepSparringSequenceData: Codable {
    let name: String
    let sequenceNumber: Int
    let description: String
    let difficulty: Int
    let keyLearningPoints: String
    let applicableBeltLevels: [String]
    let steps: [StepSparringStepData]
    
    enum CodingKeys: String, CodingKey {
        case name
        case sequenceNumber = "sequence_number"
        case description
        case difficulty
        case keyLearningPoints = "key_learning_points"
        case applicableBeltLevels = "applicable_belt_levels"
        case steps
    }
}

struct StepSparringStepData: Codable {
    let stepNumber: Int
    let timing: String
    let keyPoints: String
    let commonMistakes: String
    let attack: StepSparringActionData
    let defense: StepSparringActionData
    let counter: StepSparringActionData?
    
    enum CodingKeys: String, CodingKey {
        case stepNumber = "step_number"
        case timing
        case keyPoints = "key_points"
        case commonMistakes = "common_mistakes"
        case attack
        case defense
        case counter
    }
}

struct StepSparringActionData: Codable {
    let technique: String
    let koreanName: String
    let stance: String
    let target: String
    let hand: String
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case technique
        case koreanName = "korean_name"
        case stance
        case target
        case hand
        case description
    }
}