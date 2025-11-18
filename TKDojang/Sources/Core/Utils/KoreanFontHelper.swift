import SwiftUI

/**
 * KoreanFontHelper.swift
 *
 * PURPOSE: Centralized helper for applying NanumBrushScript font to Hangul text
 *
 * USAGE:
 *   Text(term.hangul)
 *       .font(.koreanFont(size: 32))
 *
 * WHY: Ensures consistent display of Hangul text across the app using the
 * traditional brush script font for authentic Korean aesthetic
 */

extension Font {
    /**
     * Returns NanumBrushScript font for Hangul text display
     *
     * - Parameter size: Font size in points
     * - Returns: Custom NanumBrushScript font, with system serif fallback
     */
    static func koreanFont(size: CGFloat) -> Font {
        // Try font names for NanumBrushScript
        let possibleNames = [
            "NanumBrushScript-Regular",
            "NanumBrushScript",
            "나눔손글씨붓",
            "NanumBrush"
        ]

        // Check if any of the font names work
        for fontName in possibleNames {
            if UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
        }

        // Fallback to system font with serif design
        return .system(size: size, weight: .light, design: .serif)
    }
}

/**
 * View modifier for applying Korean font to Text views
 *
 * USAGE:
 *   Text(hangulText)
 *       .modifier(KoreanTextStyle(size: 32))
 */
struct KoreanTextStyle: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.koreanFont(size: size))
    }
}

extension View {
    /**
     * Convenience method for applying Korean font
     *
     * USAGE:
     *   Text(term.hangul)
     *       .koreanFont(size: 32)
     */
    func koreanFont(size: CGFloat) -> some View {
        modifier(KoreanTextStyle(size: size))
    }
}
