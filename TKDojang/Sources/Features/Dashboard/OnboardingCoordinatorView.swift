import SwiftUI

/**
 * OnboardingCoordinatorView.swift
 * 
 * PURPOSE: Manages the first-time user experience and app introduction
 */
struct OnboardingCoordinatorView: View {
    
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var currentStep = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App logo
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to TKDojang")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Master the ancient art of Taekwondo with structured lessons, technique demonstrations, and personalized progress tracking.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button("Get Started") {
                    appCoordinator.showAuthentication()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                Button("I Already Have an Account") {
                    appCoordinator.showAuthentication()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct OnboardingCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCoordinatorView()
            .environmentObject(AppCoordinator.previewOnboarding)
    }
}