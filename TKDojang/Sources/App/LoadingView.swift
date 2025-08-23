import SwiftUI

/**
 * LoadingView.swift
 * 
 * PURPOSE: Displays loading state during app initialization and major transitions
 */
struct LoadingView: View {
    
    @State private var isAnimating = false
    @State private var textOpacity: Double = 0.5
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.15),
                    Color.red.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Hangul Characters for Tae Kwon Do
                VStack(spacing: 20) {
                    Text("태권도")
                        .font(.system(size: 72, weight: .light, design: .default))
                        .foregroundColor(.primary)
                        .scaleEffect(pulseScale)
                        .animation(
                            Animation.easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    
                    // Animated martial arts figure
                    Image(systemName: "figure.martial.arts")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 3)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                // App Branding
                VStack(spacing: 12) {
                    Text("TKDojang")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Master the Art of Taekwondo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: textOpacity
                        )
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Preparing your training...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            isAnimating = true
            textOpacity = 1.0
            pulseScale = 1.1
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}