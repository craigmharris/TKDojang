import Foundation

/**
 * LeitnerConfig.swift
 * 
 * PURPOSE: Configurable Leitner box system for spaced repetition learning
 * 
 * BENEFITS:
 * - Customizable review intervals for different learning preferences
 * - Multiple presets (beginner, standard, advanced, intensive)
 * - JSON-based configuration for easy content management
 * - Eliminates hardcoded review intervals
 */

// MARK: - Configuration Data Structures

struct LeitnerSystemConfig: Codable {
    let leitnerSystem: LeitnerSystemData
    
    private enum CodingKeys: String, CodingKey {
        case leitnerSystem = "leitner_system"
    }
}

struct LeitnerSystemData: Codable {
    let name: String
    let description: String
    let version: String
    let intervals: [String: LeitnerInterval]
    let presets: [String: LeitnerPreset]
    let settings: LeitnerSettings
}

struct LeitnerInterval: Codable {
    let days: Int
    let description: String
}

struct LeitnerPreset: Codable {
    let name: String
    let description: String
    let intervals: [String: LeitnerBoxInterval]
}

struct LeitnerBoxInterval: Codable {
    let days: Int
}

struct LeitnerSettings: Codable {
    let defaultPreset: String
    let maxBoxes: Int
    let allowCustomIntervals: Bool
    let minIntervalDays: Int
    let maxIntervalDays: Int
    
    private enum CodingKeys: String, CodingKey {
        case defaultPreset = "default_preset"
        case maxBoxes = "max_boxes"
        case allowCustomIntervals = "allow_custom_intervals"
        case minIntervalDays = "min_interval_days"
        case maxIntervalDays = "max_interval_days"
    }
}

// MARK: - Configuration Loader

class LeitnerConfigManager {
    static let shared = LeitnerConfigManager()
    
    private var config: LeitnerSystemConfig?
    private var currentPreset: String = "standard"
    
    private init() {}
    
    /**
     * Loads Leitner configuration from JSON file
     */
    func loadConfiguration() throws -> LeitnerSystemConfig {
        if let cached = config {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "leitner_config", withExtension: "json") else {
            throw LeitnerConfigError.configFileNotFound
        }
        
        let data = try Data(contentsOf: url)
        let loadedConfig = try JSONDecoder().decode(LeitnerSystemConfig.self, from: data)
        
        self.config = loadedConfig
        self.currentPreset = loadedConfig.leitnerSystem.settings.defaultPreset
        
        return loadedConfig
    }
    
    /**
     * Gets review interval in days for specified Leitner box
     */
    func getIntervalDays(forBox boxNumber: Int) -> Int {
        do {
            let config = try loadConfiguration()
            let preset = getCurrentPreset()
            
            let boxKey = "box_\(boxNumber)"
            
            if let interval = preset.intervals[boxKey] {
                return interval.days
            }
            
            // Fallback to default intervals
            if let defaultInterval = config.leitnerSystem.intervals[boxKey] {
                return defaultInterval.days
            }
            
            // Ultimate fallback to legacy hardcoded values
            return getLegacyInterval(forBox: boxNumber)
            
        } catch {
            DebugLogger.data("❌ LeitnerConfigManager: Failed to load config, using fallback: \(error)")
            return getLegacyInterval(forBox: boxNumber)
        }
    }
    
    /**
     * Gets the current active preset
     */
    func getCurrentPreset() -> LeitnerPreset {
        do {
            let config = try loadConfiguration()
            
            if let preset = config.leitnerSystem.presets[currentPreset] {
                return preset
            }
            
            // Fallback to standard preset
            if let standardPreset = config.leitnerSystem.presets["standard"] {
                return standardPreset
            }
            
            // Create fallback preset
            return createFallbackPreset()
            
        } catch {
            DebugLogger.data("❌ LeitnerConfigManager: Failed to get preset, using fallback")
            return createFallbackPreset()
        }
    }
    
    /**
     * Changes the active preset
     */
    func setCurrentPreset(_ presetName: String) throws {
        let config = try loadConfiguration()
        
        guard config.leitnerSystem.presets[presetName] != nil else {
            throw LeitnerConfigError.presetNotFound(presetName)
        }
        
        currentPreset = presetName
    }
    
    /**
     * Gets all available presets
     */
    func getAvailablePresets() -> [String: LeitnerPreset] {
        do {
            let config = try loadConfiguration()
            return config.leitnerSystem.presets
        } catch {
            DebugLogger.data("❌ LeitnerConfigManager: Failed to load presets")
            return ["standard": createFallbackPreset()]
        }
    }
    
    // MARK: - Private Helpers
    
    private func getLegacyInterval(forBox boxNumber: Int) -> Int {
        switch boxNumber {
        case 1: return 1      // Review tomorrow
        case 2: return 3      // Review in 3 days
        case 3: return 7      // Review in 1 week
        case 4: return 14     // Review in 2 weeks
        case 5: return 30     // Review in 1 month
        default: return 1
        }
    }
    
    private func createFallbackPreset() -> LeitnerPreset {
        return LeitnerPreset(
            name: "Standard Learning",
            description: "Default intervals when configuration is unavailable",
            intervals: [
                "box_1": LeitnerBoxInterval(days: 1),
                "box_2": LeitnerBoxInterval(days: 3),
                "box_3": LeitnerBoxInterval(days: 7),
                "box_4": LeitnerBoxInterval(days: 14),
                "box_5": LeitnerBoxInterval(days: 30)
            ]
        )
    }
}

// MARK: - Errors

enum LeitnerConfigError: Error, CustomStringConvertible {
    case configFileNotFound
    case presetNotFound(String)
    case invalidConfiguration(String)
    
    var description: String {
        switch self {
        case .configFileNotFound:
            return "Leitner configuration file not found"
        case .presetNotFound(let preset):
            return "Leitner preset not found: \(preset)"
        case .invalidConfiguration(let details):
            return "Invalid Leitner configuration: \(details)"
        }
    }
}