import SwiftUI

/**
 * LoadingView.swift
 * 
 * PURPOSE: Displays loading state during app initialization and major transitions
 */
struct LoadingView: View {
    
    @State private var isAnimating = false
    @State private var textOpacity: Double = 0.5
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Animated app logo
                Image(systemName: "figure.martial.arts")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                // Loading indicator and text
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle())
                    
                    Text("Preparing your training...")
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
                
                // App branding
                VStack(spacing: 8) {
                    Text("TKDojang")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Master the Art of Taekwondo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 50)
            }
            .padding(.top, 100)
            .padding(.horizontal, 40)
        }
        .onAppear {
            isAnimating = true
            textOpacity = 1.0
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}