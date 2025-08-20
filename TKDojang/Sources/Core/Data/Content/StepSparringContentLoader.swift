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
     * Loads all step sparring content from JSON files
     */
    func loadAllContent() {
        // Load three-step sparring sequences
        loadThreeStepContent(filename: "8th_keup_three_step")
        loadThreeStepContent(filename: "7th_keup_three_step")
        loadThreeStepContent(filename: "6th_keup_three_step")
        
        // Load two-step sparring sequences
        loadTwoStepContent(filename: "5th_keup_two_step")
        loadTwoStepContent(filename: "4th_keup_two_step")
        
    }
    
    /**
     * Loads three-step sparring content from specified filename
     */
    private func loadThreeStepContent(filename: String) {
        loadContentFromFile(filename: filename, type: .threeStep)
    }
    
    /**
     * Loads two-step sparring content from specified filename
     */
    private func loadTwoStepContent(filename: String) {
        loadContentFromFile(filename: filename, type: .twoStep)
    }
    
    /**
     * Generic method to load content from any step sparring JSON file
     */
    private func loadContentFromFile(filename: String, type: StepSparringType) {
        // Use the same pattern as ModularContentLoader for consistency
        var url: URL?
        
        print("🔍 Searching for \(filename).json...")
        
        // First try: StepSparring subdirectory (matches terminology pattern exactly)
        url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "StepSparring")
        if url != nil {
            print("✅ Found \(filename).json in StepSparring subdirectory")
        } else {
            print("❌ Not found in StepSparring subdirectory")
            
            // Debug: List what IS in the StepSparring subdirectory
            if let bundlePath = Bundle.main.resourcePath {
                let stepSparringPath = "\(bundlePath)/StepSparring"
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: stepSparringPath) {
                    do {
                        let contents = try fileManager.contentsOfDirectory(atPath: stepSparringPath)
                        print("📁 StepSparring directory contents: \(contents)")
                    } catch {
                        print("❌ Failed to list StepSparring contents: \(error)")
                    }
                } else {
                    print("❌ StepSparring directory doesn't exist in bundle")
                }
            }
        }
        
        // Fallback: try main bundle root
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "json")
            if url != nil {
                print("✅ Found \(filename).json in main bundle root")
            } else {
                print("❌ Not found in main bundle root")
            }
        }
        
        // Fallback: try Core/Data/Content/StepSparring path
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Core/Data/Content/StepSparring")
            if url != nil {
                print("✅ Found \(filename).json in Core/Data/Content/StepSparring")
            } else {
                print("❌ Not found in Core/Data/Content/StepSparring")
            }
        }
        
        guard let fileUrl = url else {
            print("❌ Could not find \(filename).json in any location")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let contentData = try JSONDecoder().decode(StepSparringContentData.self, from: data)
            
            print("📚 Loading \(contentData.sequences.count) \(type.displayName) sparring sequences from \(filename)")
            
            // Create sequences from JSON data
            for sequenceData in contentData.sequences {
                let sequence = createSequence(from: sequenceData, type: type)
                stepSparringService.modelContext.insert(sequence)
                
                // Save immediately after each sequence to prevent relationship corruption
                do {
                    try stepSparringService.modelContext.save()
                    print("✅ Saved sequence #\(sequenceData.sequenceNumber)")
                } catch {
                    print("❌ Failed to save sequence #\(sequenceData.sequenceNumber): \(error)")
                }
            }
            print("✅ Successfully loaded \(contentData.sequences.count) \(type.displayName) sparring sequences from \(filename)")
            
        } catch {
            print("❌ Failed to load \(type.displayName) sparring content from \(filename): \(error)")
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
        
        // DO NOT SET BELT RELATIONSHIPS - we bypass them entirely with manual checking
        // sequence.beltLevels = [] // Leave empty
        
        print("🔍 BELT DEBUG: Sequence #\(data.sequenceNumber) '\(data.name)':")
        print("   JSON belt IDs: \(data.applicableBeltLevels)")
        print("   NO SwiftData belt relationships - using manual checking")
        
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