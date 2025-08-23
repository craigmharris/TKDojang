import Foundation
import SwiftData

/**
 * DataValidationService.swift
 * 
 * PURPOSE: Provides safe data validation and repair functions
 * 
 * FEATURES:
 * - Fix common data issues without full reset
 * - Validate belt color configurations  
 * - Repair broken relationships
 * - Clean up orphaned data
 * - Non-destructive fixes that preserve user progress
 */

@Observable
final class DataValidationService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Validation Functions
    
    /**
     * Validates and fixes belt color configurations
     * This addresses the most common reason users want to "reset database"
     */
    func validateAndFixBeltColors() -> DataValidationResult {
        var issues: [String] = []
        var fixes: [String] = []
        
        do {
            let descriptor = FetchDescriptor<BeltLevel>()
            let belts = try modelContext.fetch(descriptor)
            
            for belt in belts {
                // Check for missing primary colors
                if belt.primaryColor == nil || belt.primaryColor?.isEmpty == true {
                    belt.primaryColor = getDefaultPrimaryColor(for: belt)
                    issues.append("Missing primary color for \(belt.shortName)")
                    fixes.append("Set default primary color for \(belt.shortName)")
                }
                
                // Check for missing secondary colors  
                if belt.secondaryColor == nil || belt.secondaryColor?.isEmpty == true {
                    belt.secondaryColor = getDefaultSecondaryColor(for: belt)
                    issues.append("Missing secondary color for \(belt.shortName)")
                    fixes.append("Set default secondary color for \(belt.shortName)")
                }
                
                // Check for missing text colors
                if belt.textColor == nil || belt.textColor?.isEmpty == true {
                    belt.textColor = getDefaultTextColor(for: belt)
                    issues.append("Missing text color for \(belt.shortName)")
                    fixes.append("Set default text color for \(belt.shortName)")
                }
                
                // Note: BeltLevel doesn't have updatedAt field, changes will be saved at context level
            }
            
            try modelContext.save()
            
            return DataValidationResult(
                success: true,
                issuesFound: issues,
                fixesApplied: fixes,
                message: fixes.isEmpty ? "Belt colors are correctly configured" : "Fixed \(fixes.count) belt color issues"
            )
            
        } catch {
            return DataValidationResult(
                success: false,
                issuesFound: ["Failed to validate belt colors"],
                fixesApplied: [],
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     * Cleans up orphaned progress records
     */
    func cleanupOrphanedData() -> DataValidationResult {
        var issues: [String] = []
        var fixes: [String] = []
        
        do {
            // Find orphaned terminology progress (progress without valid profile)
            let termProgressDescriptor = FetchDescriptor<UserTerminologyProgress>()
            let allTermProgress = try modelContext.fetch(termProgressDescriptor)
            
            let profileDescriptor = FetchDescriptor<UserProfile>()
            let activeProfiles = try modelContext.fetch(profileDescriptor)
            let activeProfileIds = Set(activeProfiles.map { $0.id })
            
            for progress in allTermProgress {
                if !activeProfileIds.contains(progress.userProfile.id) {
                    modelContext.delete(progress)
                    issues.append("Found orphaned terminology progress")
                    fixes.append("Removed orphaned terminology progress")
                }
            }
            
            // Similar cleanup for pattern progress
            let patternProgressDescriptor = FetchDescriptor<UserPatternProgress>()
            let allPatternProgress = try modelContext.fetch(patternProgressDescriptor)
            
            for progress in allPatternProgress {
                if !activeProfileIds.contains(progress.userProfile.id) {
                    modelContext.delete(progress)
                    issues.append("Found orphaned pattern progress")
                    fixes.append("Removed orphaned pattern progress")
                }
            }
            
            // Cleanup step sparring progress  
            let stepSparringProgressDescriptor = FetchDescriptor<UserStepSparringProgress>()
            let allStepSparringProgress = try modelContext.fetch(stepSparringProgressDescriptor)
            
            for progress in allStepSparringProgress {
                if !activeProfileIds.contains(progress.userProfile.id) {
                    modelContext.delete(progress)
                    issues.append("Found orphaned step sparring progress")
                    fixes.append("Removed orphaned step sparring progress")
                }
            }
            
            try modelContext.save()
            
            return DataValidationResult(
                success: true,
                issuesFound: issues,
                fixesApplied: fixes,
                message: fixes.isEmpty ? "No orphaned data found" : "Cleaned up \(fixes.count) orphaned records"
            )
            
        } catch {
            return DataValidationResult(
                success: false,
                issuesFound: ["Failed to cleanup orphaned data"],
                fixesApplied: [],
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     * Validates and fixes profile relationships
     */
    func validateProfileRelationships() -> DataValidationResult {
        var issues: [String] = []
        var fixes: [String] = []
        
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            // Ensure at least one profile is active
            let activeProfiles = profiles.filter { $0.isActive }
            if activeProfiles.isEmpty && !profiles.isEmpty {
                profiles.first?.isActive = true
                issues.append("No active profile found")
                fixes.append("Set first profile as active")
            }
            
            // Check for duplicate active profiles (should only be one)
            if activeProfiles.count > 1 {
                for (index, profile) in activeProfiles.enumerated() {
                    if index > 0 {
                        profile.isActive = false
                    }
                }
                issues.append("Multiple active profiles found")
                fixes.append("Set only first profile as active")
            }
            
            // Validate profile order (should be sequential)
            let sortedProfiles = profiles.sorted { $0.profileOrder < $1.profileOrder }
            for (index, profile) in sortedProfiles.enumerated() {
                if profile.profileOrder != index {
                    profile.profileOrder = index
                    issues.append("Profile order inconsistency")
                    fixes.append("Fixed profile order for \(profile.name)")
                }
            }
            
            try modelContext.save()
            
            return DataValidationResult(
                success: true,
                issuesFound: issues,
                fixesApplied: fixes,
                message: fixes.isEmpty ? "Profile relationships are valid" : "Fixed \(fixes.count) profile issues"
            )
            
        } catch {
            return DataValidationResult(
                success: false,
                issuesFound: ["Failed to validate profiles"],
                fixesApplied: [],
                message: "Error: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     * Comprehensive data validation and repair
     */
    func validateAndRepairAllData() -> DataValidationResult {
        let beltResult = validateAndFixBeltColors()
        let orphanResult = cleanupOrphanedData()
        let profileResult = validateProfileRelationships()
        
        let allIssues = beltResult.issuesFound + orphanResult.issuesFound + profileResult.issuesFound
        let allFixes = beltResult.fixesApplied + orphanResult.fixesApplied + profileResult.fixesApplied
        
        let success = beltResult.success && orphanResult.success && profileResult.success
        
        return DataValidationResult(
            success: success,
            issuesFound: allIssues,
            fixesApplied: allFixes,
            message: success ? "Data validation completed successfully" : "Some validation steps failed"
        )
    }
    
    // MARK: - Default Color Helpers
    
    private func getDefaultPrimaryColor(for belt: BeltLevel) -> String {
        // Return appropriate hex colors based on belt name/level
        if belt.colorName.lowercased().contains("white") {
            return "#FFFFFF"
        } else if belt.colorName.lowercased().contains("yellow") {
            return "#FFD700"
        } else if belt.colorName.lowercased().contains("green") {
            return "#32CD32"
        } else if belt.colorName.lowercased().contains("blue") {
            return "#4169E1"
        } else if belt.colorName.lowercased().contains("red") {
            return "#DC143C"
        } else if belt.colorName.lowercased().contains("black") {
            return "#1C1C1C"
        } else {
            return "#808080" // Default gray
        }
    }
    
    private func getDefaultSecondaryColor(for belt: BeltLevel) -> String {
        // Usually a darker shade or complementary color
        let primary = getDefaultPrimaryColor(for: belt)
        switch primary {
        case "#FFFFFF": return "#E0E0E0"
        case "#FFD700": return "#DAA520"
        case "#32CD32": return "#228B22"
        case "#4169E1": return "#1E40AF"
        case "#DC143C": return "#B91C3C"
        case "#1C1C1C": return "#404040"
        default: return "#606060"
        }
    }
    
    private func getDefaultTextColor(for belt: BeltLevel) -> String {
        let primary = getDefaultPrimaryColor(for: belt)
        // Use dark text on light backgrounds, light text on dark backgrounds
        switch primary {
        case "#FFFFFF", "#FFD700": return "#1C1C1C"
        default: return "#FFFFFF"
        }
    }
}

// MARK: - Result Types

struct DataValidationResult {
    let success: Bool
    let issuesFound: [String]
    let fixesApplied: [String]
    let message: String
    
    var hasIssues: Bool {
        return !issuesFound.isEmpty
    }
    
    var hasFixes: Bool {
        return !fixesApplied.isEmpty
    }
}