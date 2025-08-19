import SwiftUI

/**
 * ColorExtensions.swift
 * 
 * PURPOSE: SwiftUI Color extensions for profile theme colors
 * 
 * DESIGN DECISIONS:
 * - Safe color parsing with fallbacks
 * - Support for both named colors and hex values
 * - Consistent color handling across profile system
 */

extension Color {
    /**
     * Initialize Color from string representation
     * Supports both system color names and hex values
     */
    init(_ colorString: String) {
        switch colorString.lowercased() {
        case "blue":
            self = .blue
        case "green":
            self = .green
        case "red":
            self = .red
        case "orange":
            self = .orange
        case "purple":
            self = .purple
        case "pink":
            self = .pink
        case "lightblue":
            self = Color(red: 0.68, green: 0.85, blue: 0.90)
        case "mint":
            self = .mint
        case "yellow":
            self = .yellow
        case "indigo":
            self = .indigo
        default:
            // Try to parse as hex color (using existing BeltTheme extension)
            if colorString.hasPrefix("#") {
                self = Color(hex: colorString)
            } else if colorString.hasPrefix("0x") {
                self = Color(hex: "#" + String(colorString.dropFirst(2)))
            } else {
                // Fallback to system gray
                self = .gray
            }
        }
    }
}

extension ProfileColorTheme {
    /**
     * Returns SwiftUI Color for the primary color
     */
    var primarySwiftUIColor: Color {
        return Color(primaryColor)
    }
    
    /**
     * Returns SwiftUI Color for the secondary color
     */
    var secondarySwiftUIColor: Color {
        return Color(secondaryColor)
    }
}