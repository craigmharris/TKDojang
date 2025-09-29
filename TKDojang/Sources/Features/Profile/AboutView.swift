import SwiftUI

/**
 * AboutView.swift
 * 
 * PURPOSE: Comprehensive About section with app origin, developer background,
 * content accuracy, target audience, privacy approach, future vision, and legal information
 */

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "figure.martial.arts")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("TKDojang")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Traditional Taekwondo Learning Companion")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // App Origin & Mission
                    AboutSection(
                        title: "Why TKDojang Exists",
                        icon: "heart.fill",
                        iconColor: .red
                    ) {
                        Text("TKDojang began as a family project. While helping my children prepare for Taekwondo gradings, my partner and I created paper flashcards to practice Korean terminology. As they progressed through belt levels, the content grew beyond what paper could handle effectively.")
                        
                        Text("I searched for apps that could teach terminology in the same engaging way, but found nothing that combined high build quality with visual appeal and effective learning methods. Coming from a coding background, I thought: 'I could build this with some time and study.'")
                        
                        Text("The real inspiration came from wanting to test generative AI as a learning tool for programming in SwiftUI – turning a martial arts challenge into a technical adventure that benefits families worldwide.")
                    }
                    
                    // Developer Background
                    AboutSection(
                        title: "About the Developer",
                        icon: "person.circle.fill",
                        iconColor: .blue
                    ) {
                        Text("I'm a dedicated parent with nearly twenty years of Taekwondo experience. After training for seven years and reaching 1st Keup, life took me away from the martial arts for a decade. Now I've returned with my partner and five children, re-learning my way back to my former level with hopes of achieving Dan grade soon.")
                        
                        Text("I train at a TAGB school in South West England, where I particularly enjoy patterns – the mental focus and precision they require. While I may never be the strongest sparring partner, I'm committed to performing high-quality patterns with slow, deliberate technique.")
                        
                        Text("My professional coding background gave me confidence to build this app, but my experience with language learning apps helped me think differently about creating effective learning tools. I don't consider myself a teacher – rather, I'm curating content to help others learn by sharing what has helped my family.")
                    }
                    
                    // Target Audience
                    AboutSection(
                        title: "Who TKDojang Is For",
                        icon: "person.2.fill",
                        iconColor: .green
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Primary Users:")
                                .fontWeight(.medium)
                            Text("Students and families looking to practice terminology and theory, with additional support for pattern and step sparring retention. Recommended for ages 9 and up, with no upper age limit – it's never too late to learn Taekwondo!")
                            
                            Text("Learning Styles:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("While traditional front-of-class instruction works for many, students who struggle with spatial awareness or visualization can benefit from this alternative medium. Having multiple ways to practice helps accommodate different learning preferences.")
                            
                            Text("Usage Approach:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("Use TKDojang 'little and often' – a few times per week when approaching gradings, but less frequently overall. Ramp up before belt tests, then ease off. This shouldn't be an app where you spend excessive time.")
                            
                            Text("Important:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("TKDojang is designed as a supplement to dojo training, never a replacement. No prior Taekwondo knowledge is required, but a few lessons help determine if the martial art is right for you.")
                        }
                    }
                    
                    // Content Accuracy
                    AboutSection(
                        title: "Content Sources & Accuracy",
                        icon: "checkmark.shield.fill",
                        iconColor: .orange
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Primary Sources:")
                                .fontWeight(.medium)
                            Text("Content is built from TAGB curriculum materials and validated against the TAGB pattern manual. Korean terminology draws from my instructors' teaching, cross-referenced with available online materials from other schools.")
                            
                            Text("Quality Approach:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("Romanization has been standardized for both external consistency with TAGB syllabuses and internal consistency within the app. Generative AI assists with hangul characters and phonetic definitions.")
                            
                            Text("Acknowledgment:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("There will likely be mistakes, which I'll resolve as they're identified. A Korean-speaking family member and native speaker will help maintain language accuracy over time.")
                            
                            Text("Future Plans:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("While starting with TAGB standards, I hope to eventually accommodate multiple syllabuses, belt systems, and organizations as terminology doesn't vary dramatically between most Taekwondo schools.")
                            
                            Text("Feedback Welcome:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("I'm open to all content accuracy feedback and working toward a scalable way to manage corrections from the community.")
                        }
                    }
                    
                    // Privacy & Data
                    AboutSection(
                        title: "Your Privacy Matters",
                        icon: "lock.shield.fill",
                        iconColor: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Local-Only Data:")
                                .fontWeight(.medium)
                            Text("All profile and progress information stays on your device. I don't see any of your personal data – you don't even need to add your name if you prefer not to.")
                            
                            Text("No Tracking:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("During TestFlight testing, I receive crash reports but no personal data. Nothing is tracked for advertising or other purposes. This app is for users, not for data collection.")
                            
                            Text("Multiple Users:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("The app supports up to 6 local profiles per device, perfect for families while maintaining individual progress tracking.")
                            
                            Text("Trade-offs:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("The privacy-first approach means convenience features like cross-device sync aren't available yet. Cloud features may come when I can guarantee the same level of privacy protection.")
                            
                            Text("Philosophy:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("This approach aligns with my preference to reduce screen time addiction across all technology touchpoints. TKDojang respects your time and attention.")
                        }
                    }
                    
                    // Future Vision
                    AboutSection(
                        title: "Where We're Heading",
                        icon: "arrow.up.forward.circle.fill",
                        iconColor: .indigo
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Content Expansion:")
                                .fontWeight(.medium)
                            Text("Additional belt levels, learning modes, and video content showing patterns and technique breakdowns from multiple angles. Development will be driven by user feedback and needs.")
                            
                            Text("Geographic Goals:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("Eventually reaching a few thousand users UK-wide, serving a meaningful proportion of the student base across different schools and organizations.")
                            
                            Text("Collaboration:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("While I'll likely keep development as a solo effort, I'm eager to bring in collaborators for content creation and review to ensure accuracy and comprehensiveness.")
                            
                            Text("Success Metric:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("TKDojang will have achieved its purpose when users can progress from white belt to black belt using the app as a learning companion throughout their entire journey.")
                            
                            Text("Ethical Technology:")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            Text("No engagement hooks, streaks, or rewards. No advertisements ever. Content should be engaging to improve learning effectiveness, not to increase time spent in the app. The goal is learning, not screen time.")
                        }
                    }
                    
                    // Legal & Contact
                    AboutSection(
                        title: "Legal & Contact Information",
                        icon: "doc.text.fill",
                        iconColor: .gray
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Copyright & Attribution")
                                .fontWeight(.medium)
                            
                            Text("Original content © 2024 TKDojang. TAGB curriculum materials serve as inspiration with no direct copies or plagiarism. TAGB organization approval is being sought for official recognition.")
                            
                            Text("Important Disclaimers")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• TKDojang is a learning aid, not direct instruction")
                                Text("• All physical activities are at your own risk")
                                Text("• This app supplements but never replaces proper dojo training")
                                Text("• Content accuracy is best-effort with ongoing improvements")
                                Text("• No commercial use of app content permitted")
                            }
                            
                            Text("Pricing Philosophy")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            
                            Text("Small one-time fees cover development and maintenance costs only. No advertisements, subscriptions, or mandatory in-app purchases. If sustainable support isn't possible, the app will be retired rather than compromised with invasive monetization.")
                            
                            Text("Contact & Feedback")
                                .fontWeight(.medium)
                                .padding(.top, 8)
                            
                            Text("Currently available through TestFlight feedback or App Store reviews. A dedicated support email address will be provided soon for bug reports, content corrections, and general feedback.")
                        }
                    }
                    
                    // Footer
                    VStack(spacing: 8) {
                        Divider()
                        
                        Text("Thank you for joining the TKDojang journey")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("Version 1.0 • Built with SwiftUI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("About TKDojang")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - About Section Component

struct AboutSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .font(.body)
            .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Preview

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}