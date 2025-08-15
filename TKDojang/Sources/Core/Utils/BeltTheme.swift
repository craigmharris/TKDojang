import SwiftUI
import Foundation

/**
 * BeltTheme.swift
 * 
 * PURPOSE: Visual theming system based on TAGB belt colors
 * 
 * FEATURES:
 * - Converts hex colors to SwiftUI Color
 * - Creates gradients for belt styling
 * - Provides consistent visual identity per belt level
 */

struct BeltTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let textColor: Color
    let borderColor: Color
    let gradient: LinearGradient
    
    /**
     * Creates a BeltTheme from a BeltLevel model
     */
    init(from beltLevel: BeltLevel) {
        self.primaryColor = Color(hex: beltLevel.primaryColor ?? "#6C757D")
        self.secondaryColor = Color(hex: beltLevel.secondaryColor ?? "#E9ECEF")
        self.textColor = Color(hex: beltLevel.textColor ?? "#000000")
        self.borderColor = Color(hex: beltLevel.borderColor ?? "#DEE2E6")
        
        self.gradient = LinearGradient(
            gradient: Gradient(colors: [primaryColor, secondaryColor]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /**
     * Default theme for when belt information is not available
     */
    static let `default` = BeltTheme(
        primaryColor: .gray,
        secondaryColor: .gray.opacity(0.3),
        textColor: .primary,
        borderColor: .gray,
        gradient: LinearGradient(
            gradient: Gradient(colors: [.gray, .gray.opacity(0.3)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    
    private init(primaryColor: Color, secondaryColor: Color, textColor: Color, borderColor: Color, gradient: LinearGradient) {
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.gradient = gradient
    }
}

// MARK: - Color Extensions

extension Color {
    /**
     * Creates a Color from a hex string
     */
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Belt-Themed UI Components

/**
 * Belt-themed card background with white fill and belt-colored border
 */
struct BeltCardBackground: View {
    let theme: BeltTheme
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    init(theme: BeltTheme, cornerRadius: CGFloat = 20, borderWidth: CGFloat = 6) {
        self.theme = theme
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        ZStack {
            // White card background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
            
            // Belt-styled border: outer primary color + inner secondary color
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(theme.primaryColor, lineWidth: borderWidth)
                .overlay(
                    // Inner stripe for belts with tags (secondary color)
                    RoundedRectangle(cornerRadius: cornerRadius - borderWidth/3)
                        .strokeBorder(theme.secondaryColor, lineWidth: borderWidth/3)
                )
        }
        .shadow(color: theme.primaryColor.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

/**
 * Belt-themed progress indicator
 */
struct BeltProgressBar: View {
    let progress: Double
    let theme: BeltTheme
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle()
                        .fill(Double(index) < progress * 10 ? theme.primaryColor : theme.secondaryColor)
                        .frame(height: 4)
                }
            }
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
}

/**
 * Belt level badge with belt-styled border
 */
struct BeltBadge: View {
    let beltLevel: BeltLevel
    let theme: BeltTheme
    
    var body: some View {
        Text(beltLevel.colorName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    // Primary belt color background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.primaryColor)
                    
                    // Secondary color stripe for belts with tags
                    if theme.secondaryColor != theme.primaryColor {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(theme.secondaryColor, lineWidth: 2)
                    }
                }
            )
    }
}