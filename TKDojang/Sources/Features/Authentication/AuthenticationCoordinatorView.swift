import SwiftUI

/**
 * AuthenticationCoordinatorView.swift
 * 
 * PURPOSE: Coordinates navigation within the authentication flow
 */
struct AuthenticationCoordinatorView: View {
    
    @EnvironmentObject var appCoordinator: AppCoordinator
    @State private var currentScreen: AuthScreen = .login
    @State private var isLoading = false
    
    enum AuthScreen {
        case login
        case register
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.martial.arts")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("TKDojang")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to continue your training")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // Auth content
                    VStack(spacing: 20) {
                        if currentScreen == .login {
                            loginContent
                        } else {
                            registerContent
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Switch between login/register
                    HStack {
                        Text(currentScreen == .login ? "Don't have an account?" : "Already have an account?")
                            .foregroundColor(.secondary)
                        
                        Button(currentScreen == .login ? "Sign Up" : "Sign In") {
                            currentScreen = currentScreen == .login ? .register : .login
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 30)
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Signing in...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var loginContent: some View {
        VStack(spacing: 16) {
            Text("Sign In")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Email", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.password)
            }
            
            Button("Sign In") {
                handleAuthentication()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
    }
    
    private var registerContent: some View {
        VStack(spacing: 16) {
            Text("Create Account")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Full Name", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.name)
                
                TextField("Email", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.newPassword)
            }
            
            Button("Create Account") {
                handleAuthentication()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
    }
    
    private func handleAuthentication() {
        isLoading = true
        
        // Simulate authentication
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            appCoordinator.showMainFlow()
        }
    }
}

struct AuthenticationCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationCoordinatorView()
            .environmentObject(AppCoordinator())
    }
}