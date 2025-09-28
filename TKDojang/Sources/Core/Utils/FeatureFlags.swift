import Foundation

/**
 * FeatureFlags.swift
 * 
 * PURPOSE: Centralized feature toggle system for controlling app functionality
 * 
 * This allows us to hide features that require additional setup or subscriptions
 * while preserving the code for future activation.
 */

struct FeatureFlags {
    
    // MARK: - iCloud Integration
    
    /**
     * Controls whether iCloud backup and restore functionality is visible
     * 
     * Set to false to hide iCloud features when no Developer subscription is available
     * All iCloud code remains intact and can be re-enabled by setting this to true
     */
    static let isiCloudEnabled = false
    
    // MARK: - Future Feature Toggles
    
    /**
     * Controls whether advanced analytics features are visible
     * Currently enabled - can be disabled if needed for performance or privacy
     */
    static let isAdvancedAnalyticsEnabled = true
    
    /**
     * Controls whether pattern video integration is visible
     * Currently disabled until video content is available
     */
    static let isPatternVideoEnabled = false
    
    /**
     * Controls whether social features (sharing achievements, etc.) are visible
     * Currently disabled - can be enabled for future social functionality
     */
    static let isSocialFeaturesEnabled = false
    
    // MARK: - Debug Features
    
    /**
     * Controls whether debug logging is enabled
     * Should be disabled in production builds
     */
    static let isDebugLoggingEnabled = true
    
    /**
     * Controls whether development tools are visible in the UI
     * Should be disabled in production builds
     */
    static let isDevelopmentToolsEnabled = false
    
}

// MARK: - Convenience Methods

extension FeatureFlags {
    
    /**
     * Returns true if any cloud-based features should be shown
     * Currently just iCloud, but could include other cloud services in future
     */
    static var isCloudIntegrationAvailable: Bool {
        return isiCloudEnabled
    }
    
    /**
     * Returns true if premium features requiring subscriptions should be shown
     */
    static var isPremiumFeaturesEnabled: Bool {
        return isiCloudEnabled || isSocialFeaturesEnabled
    }
    
}