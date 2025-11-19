import SwiftUI

/**
 * LoadingView.swift
 * 
 * PURPOSE: Displays loading state during app initialization and major transitions
 */
struct LoadingView: View {
    
    @State private var scrollProgress: Double = 0.0
    @State private var beltAnimationPhase: Int = 0
    @State private var isScrollAnimating = false
    @State private var fontIsReady = false
    @State private var currentColorPhase = 0
    
    // Color phases for brush script animation
    private var brushScriptColor: Color {
        switch currentColorPhase {
        case 0: return Color(red: 0.5, green: 0.3, blue: 0.2) // Brown
        case 1: return Color(red: 0.4, green: 0.25, blue: 0.15) // Darker brown
        case 2: return Color(red: 0.3, green: 0.2, blue: 0.1) // Dark brown
        default: return Color(red: 0.2, green: 0.1, blue: 0.05) // Final dark
        }
    }
    
    // Helper function to handle custom Korean font with fallback
    private func customKoreanFont(size: CGFloat) -> Font {
        // Only show custom font when ready
        guard fontIsReady else {
            return .system(size: 1, weight: .ultraLight, design: .serif) // Invisible until ready
        }
        
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
        return .system(size: size, weight: .ultraLight, design: .serif)
    }
    
    // Belt progression data - TAGB ITF progression with proper colors and stripes
    private let beltProgression: [(name: String, primaryColor: Color, secondaryColor: Color?)] = [
        ("White", Color(hex: "#F5F5F5"), nil),
        ("White/Yellow", Color(hex: "#F5F5F5"), Color(hex: "#FFD60A")),
        ("Yellow", Color(hex: "#FFD60A"), nil),
        ("Yellow/Green", Color(hex: "#FFD60A"), Color(hex: "#4CAF50")),
        ("Green", Color(hex: "#4CAF50"), nil),
        ("Green/Blue", Color(hex: "#4CAF50"), Color(hex: "#2196F3")),
        ("Blue", Color(hex: "#2196F3"), nil),
        ("Blue/Red", Color(hex: "#2196F3"), Color(hex: "#F44336")),
        ("Red", Color(hex: "#F44336"), nil),
        ("Red/Black", Color(hex: "#F44336"), Color(hex: "#000000")),
        ("Black", Color(hex: "#000000"), nil)
    ]
    
    init() {
        #if DEBUG
        DebugLogger.ui("🎨 LoadingView: INIT - LoadingView is being created - \(Date())")
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Traditional scroll parchment background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.96, green: 0.92, blue: 0.84), location: 0.0),
                        .init(color: Color(red: 0.94, green: 0.88, blue: 0.78), location: 0.5),
                        .init(color: Color(red: 0.92, green: 0.86, blue: 0.76), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all)
                
                // Scroll border decoration
                VStack {
                    // Top scroll edge
                    Rectangle()
                        .fill(Color(red: 0.7, green: 0.5, blue: 0.3))
                        .frame(height: 8)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    Spacer()
                    
                    // Bottom scroll edge
                    Rectangle()
                        .fill(Color(red: 0.7, green: 0.5, blue: 0.3))
                        .frame(height: 8)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: -2)
                }
                .ignoresSafeArea(.all)
                
                // Main content
                VStack(spacing: 40) {
                    Spacer(minLength: 60)
                    
                    // Vertical Korean characters in traditional brush style
                    HStack(spacing: 40) {
                        VStack(spacing: 15) {
                            Text("태")
                                .font(customKoreanFont(size: 140))
                                .foregroundColor(brushScriptColor)
                                .opacity(fontIsReady && scrollProgress > 0.0 ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.8), value: scrollProgress)
                                .animation(.easeInOut(duration: 0.3), value: brushScriptColor)
                            
                            Text("권")
                                .font(customKoreanFont(size: 140))
                                .foregroundColor(brushScriptColor)
                                .opacity(fontIsReady && scrollProgress > 0.33 ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.8).delay(1.5), value: scrollProgress)
                                .animation(.easeInOut(duration: 0.3), value: brushScriptColor)
                            
                            Text("도")
                                .font(customKoreanFont(size: 140))
                                .foregroundColor(brushScriptColor)
                                .opacity(fontIsReady && scrollProgress > 0.66 ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.8).delay(3.0), value: scrollProgress)
                                .animation(.easeInOut(duration: 0.3), value: brushScriptColor)
                        }
                        
                        // Traditional decorative line
                        Rectangle()
                            .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                            .frame(width: 2, height: 200)
                            .opacity(0.6)
                        
                        // App name in traditional style
                        VStack(spacing: 20) {
                            Text("TKDojang")
                                .font(.system(size: 32, weight: .heavy, design: .default))
                                .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                                .opacity(scrollProgress > 0.99 ? 1.0 : 0.0)
                                .animation(.easeInOut(duration: 0.6).delay(4.0), value: scrollProgress)
                            
                        }
                    }
                    
                    Spacer()
                    
                    // Traditional scroll unrolling belt progression
                    VStack(spacing: 20) {
                        Text("Beginning your journey...")
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(Color(red: 0.4, green: 0.3, blue: 0.2))
                            .opacity(0.8)
                        
                        // Belt progression as unrolling scroll
                        ScrollingBeltProgression(
                            belts: beltProgression,
                            animationPhase: beltAnimationPhase,
                            geometry: geometry
                        )
                    }
                    .padding(.bottom, 60)
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            #if DEBUG
            DebugLogger.ui("🎨 LoadingView: ON_APPEAR - LoadingView is now visible on screen! - \(Date())")

            // Enhanced font debug
            DebugLogger.ui("📋 Font bundle debug:")

            // Check if font file exists in bundle
            if let fontPath = Bundle.main.path(forResource: "NanumBrushScript-Regular", ofType: "ttf") {
                DebugLogger.ui("  ✅ Font file found at: \(fontPath)")

                // Try to register font manually
                let fontURL = URL(fileURLWithPath: fontPath)
                if CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil) {
                    DebugLogger.ui("  ✅ Font registered successfully")
                } else {
                    DebugLogger.ui("  ❌ Font registration failed")
                }
            } else {
                DebugLogger.ui("  ❌ Font file not found in bundle")
                // List all .ttf files in bundle
                if let bundlePath = Bundle.main.resourcePath {
                    DebugLogger.ui("  📁 Bundle contents (.ttf files):")
                    let fileManager = FileManager.default
                    do {
                        let files = try fileManager.contentsOfDirectory(atPath: bundlePath)
                        for file in files.filter({ $0.hasSuffix(".ttf") }) {
                            DebugLogger.ui("    Found: \(file)")
                        }
                    } catch {
                        DebugLogger.ui("    Error reading bundle: \(error)")
                    }
                }
            }

            // Check available fonts after potential registration
            DebugLogger.ui("📋 Available font families with 'nanum' or 'brush':")
            for family in UIFont.familyNames.sorted() {
                if family.lowercased().contains("nanum") || family.lowercased().contains("brush") {
                    DebugLogger.ui("  Family: \(family)")
                    for fontName in UIFont.fontNames(forFamilyName: family) {
                        DebugLogger.ui("    Font: \(fontName)")
                    }
                }
            }
            if UIFont.familyNames.filter({ $0.lowercased().contains("nanum") || $0.lowercased().contains("brush") }).isEmpty {
                DebugLogger.ui("  No Nanum or Brush fonts found in system")
            }

            DebugLogger.ui("🎨 LoadingView: Starting scroll animation... - \(Date())")
            #endif

            // Mark font as ready after registration attempt
            fontIsReady = true

            startScrollAnimation()
            startColorAnimation()
        }
        .onDisappear {
            #if DEBUG
            DebugLogger.ui("🎨 LoadingView: ON_DISAPPEAR - LoadingView is being removed! - \(Date())")
            #endif
        }
    }
    
    private func startScrollAnimation() {
        // Start scroll progress animation over full duration to sync with belts
        withAnimation(.easeInOut(duration: 4.4)) {
            scrollProgress = 1.0
        }
        
        // Start belt progression animation concurrently - 0.4 seconds per belt
        var currentBelt = 0
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.2)) {
                beltAnimationPhase = currentBelt
            }
            
            currentBelt += 1
            
            // Stop timer after all belts have animated
            if currentBelt >= beltProgression.count {
                timer.invalidate()
                // Signal completion after a short pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Loading complete - app will handle transition
                    #if DEBUG
                    DebugLogger.ui("🎨 LoadingView: Belt progression complete - ready for transition")
                    #endif
                }
            }
        }
    }
    
    private func startColorAnimation() {
        // Change color every 1.4 seconds (4.4s total / 3 changes = ~1.47s each)
        var colorPhase = 0
        Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.8)) {
                currentColorPhase = colorPhase
            }
            
            colorPhase += 1
            
            // Stop timer after all color phases
            if colorPhase > 3 {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Scrolling Belt Progression Component

struct ScrollingBeltProgression: View {
    let belts: [(name: String, primaryColor: Color, secondaryColor: Color?)]
    let animationPhase: Int
    let geometry: GeometryProxy
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<belts.count, id: \.self) { index in
                LoadingBeltIcon(
                    belt: belts[index],
                    isActive: index <= animationPhase,
                    isCurrently: index == animationPhase
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.9, green: 0.85, blue: 0.75))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct LoadingBeltIcon: View {
    let belt: (name: String, primaryColor: Color, secondaryColor: Color?)
    let isActive: Bool
    let isCurrently: Bool
    
    var body: some View {
        ZStack {
            // Base circle with primary color
            Circle()
                .fill(belt.primaryColor)
                .frame(width: 20, height: 20)
            
            // Horizontal stripe for dual-color belts (1/3 of circle height)
            if let secondaryColor = belt.secondaryColor {
                Rectangle()
                    .fill(secondaryColor)
                    .frame(width: 16, height: 7)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 3.5)
                    )
            }
            
            // Border
            Circle()
                .stroke(Color(red: 0.3, green: 0.2, blue: 0.1), lineWidth: isActive ? 2 : 1)
                .frame(width: 20, height: 20)
        }
        .scaleEffect(isActive ? 1.0 : 0.6)
        .opacity(isActive ? 1.0 : 0.2)
        .animation(.easeInOut(duration: 0.6), value: isActive)
        .overlay(
            // Pulse effect for currently animating belt
            Circle()
                .fill(belt.primaryColor.opacity(0.4))
                .frame(width: isCurrently ? 35 : 20, height: isCurrently ? 35 : 20)
                .opacity(isCurrently ? 0.8 : 0.0)
                .animation(.easeInOut(duration: 0.8).repeatCount(3, autoreverses: true), value: isCurrently)
        )
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .preferredColorScheme(.light)
            .previewDisplayName("Loading Screen - Light")
        
        LoadingView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Loading Screen - Dark")
    }
}