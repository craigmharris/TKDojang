import Foundation

/**
 * DebugLogger.swift
 * 
 * PURPOSE: Centralized debug logging that gets compiled out in release builds
 * 
 * FEATURES:
 * - Conditional compilation based on DEBUG flag
 * - Zero runtime overhead in release builds
 * - Consistent debug output formatting
 * - Easy to disable/enable debug categories
 */

struct DebugLogger {
    
    /**
     * Logs debug messages only in DEBUG builds
     * Completely compiled out in RELEASE builds for zero overhead
     */
    static func debug(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
    
    /**
     * Logs critical system events that should appear in all builds
     * Use sparingly for essential information only
     */
    static func system(_ message: String) {
        print(message)
    }
    
    /**
     * Logs data operation debug information
     * Useful for database operations, content loading, etc.
     */
    static func data(_ message: String) {
        #if DEBUG
        print("DEBUG: \(message)")
        #endif
    }
    
    /**
     * Logs profile/user operation debug information
     */
    static func profile(_ message: String) {
        #if DEBUG
        print("DEBUG: \(message)")
        #endif
    }
    
    /**
     * Logs UI/view lifecycle debug information
     */
    static func ui(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}