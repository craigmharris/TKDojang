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
        let primaryHex = beltLevel.primaryColor ?? "#6C757D"
        let secondaryHex = beltLevel.secondaryColor ?? "#E9ECEF"
        
        self.primaryColor = Color(hex: primaryHex)
        // For solid belts, ensure colors are identical
        self.secondaryColor = primaryHex == secondaryHex ? self.primaryColor : Color(hex: secondaryHex)
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
        secondaryColor: .gray,  // Same color for solid appearance
        textColor: .primary,
        borderColor: .gray,
        gradient: LinearGradient(
            gradient: Gradient(colors: [.gray, .gray]),
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
 * Proper belt border design with explicit Primary-Secondary-Primary pattern
 */
struct BeltBorder: View {
    let theme: BeltTheme
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    var body: some View {
        ZStack {
            // 2px grey stroke as base layer (outermost)
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.gray.opacity(0.6), lineWidth: 2)
            
            if theme.secondaryColor != theme.primaryColor {
                // For tag belts: Three concentric layers inside grey stroke
                BeltThreeLayerDesign(theme: theme, cornerRadius: cornerRadius - 1, borderWidth: borderWidth - 2)
            } else {
                // For solid color belts: Single solid color border
                RoundedRectangle(cornerRadius: cornerRadius - 1)
                    .strokeBorder(theme.primaryColor, lineWidth: borderWidth - 2)
            }
        }
    }
}

/**
 * Three-layer belt design with proper concentric positioning using insets
 */
struct BeltThreeLayerDesign: View {
    let theme: BeltTheme
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    var body: some View {
        let thirdWidth = borderWidth / 3
        
        ZStack {
            // Layer 1: Outer ring - Primary color
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(theme.primaryColor, lineWidth: thirdWidth)
            
            // Layer 2: Middle ring - Secondary color (inset by thirdWidth)
            RoundedRectangle(cornerRadius: max(2, cornerRadius - thirdWidth))
                .strokeBorder(theme.secondaryColor, lineWidth: thirdWidth)
                .padding(thirdWidth)
            
            // Layer 3: Inner ring - Primary color (inset by 2 * thirdWidth)
            RoundedRectangle(cornerRadius: max(2, cornerRadius - (thirdWidth * 2)))
                .strokeBorder(theme.primaryColor, lineWidth: thirdWidth)
                .padding(thirdWidth * 2)
        }
    }
}

/**
 * Belt-themed card background with white fill and belt-colored border
 */
struct BeltCardBackground: View {
    let theme: BeltTheme
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    
    init(theme: BeltTheme, cornerRadius: CGFloat = 20, borderWidth: CGFloat = 15) {
        self.theme = theme
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
    }
    
    var body: some View {
        ZStack {
            // Belt design: Primary-Secondary-Primary in thirds with grey stroke
            BeltBorder(theme: theme, cornerRadius: cornerRadius, borderWidth: borderWidth)
            
            // Adaptive card background (positioned inside belt border)
            RoundedRectangle(cornerRadius: max(2, cornerRadius - borderWidth))
                .fill(Color(UIColor.systemBackground))
                .padding(borderWidth)
            
            // Belt knot decoration at bottom center
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    BeltKnot(theme: theme)
                    Spacer()
                }
                .offset(y: 8)
            }
        }
        .shadow(color: theme.primaryColor.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

/**
 * Belt-themed progress indicator with proper tag color positioning
 */
struct BeltProgressBar: View {
    let progress: Double
    let theme: BeltTheme
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(0..<10, id: \.self) { index in
                    BeltProgressSegment(
                        index: index,
                        progress: progress,
                        theme: theme
                    )
                }
            }
        }
        .frame(height: 6)
        .cornerRadius(3)
    }
}

/**
 * Individual progress bar segment with center stripe for tag belts
 */
struct BeltProgressSegment: View {
    let index: Int
    let progress: Double
    let theme: BeltTheme
    
    private var isActive: Bool {
        Double(index) < progress * 10
    }
    
    var body: some View {
        ZStack {
            // Base color (primary for active, gray for inactive)
            Rectangle()
                .fill(isActive ? theme.primaryColor : Color.gray.opacity(0.3))
                .frame(height: 6)
            
            // Center stripe for tag belts (only if active and has secondary color)
            if isActive && theme.secondaryColor != theme.primaryColor {
                Rectangle()
                    .fill(theme.secondaryColor)
                    .frame(height: 2) // Center third of 6px height
            }
        }
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
        )
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
            .foregroundColor(theme.textColor)
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

/**
 * Small belt knot decoration for card bottom with proper belt ends
 */
struct BeltKnot: View {
    let theme: BeltTheme
    
    var body: some View {
        ZStack {
            // Belt ends angled downward at 45 degrees with proper belt design
            HStack(spacing: 20) {
                // Left belt end
                BeltEnd(theme: theme, angle: -45)
                    .offset(x: 2, y: 3)
                
                // Right belt end  
                BeltEnd(theme: theme, angle: 45)
                    .offset(x: -2, y: 3)
            }
            
            // Main knot body (on top) - sized to match belt thickness
            RoundedRectangle(cornerRadius: 4)
                .fill(theme.primaryColor)
                .frame(width: 20, height: 15)
            
            // Knot center tie (secondary color stripe)
            if theme.secondaryColor != theme.primaryColor {
                RoundedRectangle(cornerRadius: 1)
                    .fill(theme.secondaryColor)
                    .frame(width: 7, height: 15)
            }
        }
        .frame(width: 45, height: 15)
    }
}

/**
 * Individual belt end with proper belt design and thickness
 */
struct BeltEnd: View {
    let theme: BeltTheme
    let angle: Double
    
    var body: some View {
        ZStack {
            // Base belt end (primary color) - sized to match belt border
            Rectangle()
                .fill(theme.primaryColor)
                .frame(width: 18, height: 15) // Match 15px belt border thickness
            
            // Center stripe for tag belts
            if theme.secondaryColor != theme.primaryColor {
                Rectangle()
                    .fill(theme.secondaryColor)
                    .frame(width: 18, height: 5) // Center third (5px of 15px)
            }
        }
        .rotationEffect(.degrees(angle))
    }
}
