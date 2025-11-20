import SwiftUI

/**
 * PrivacyPolicyView.swift
 *
 * PURPOSE: Simple, clear privacy policy in British English
 *
 * DESIGN DECISIONS:
 * - Plain language, easy to understand
 * - British English spelling and phrasing
 * - Short sections with clear headings
 * - Emphasises privacy-first approach
 */

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Last updated: November 2025")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)

                    // Introduction
                    PrivacySection(
                        title: "Our Commitment to Your Privacy",
                        icon: "heart.circle.fill",
                        iconColor: .red
                    ) {
                        Text("TKDojang is built with privacy at its core. We believe your learning journey is yours alone, and we've designed the app to keep it that way.")

                        Text("This policy explains, in plain English, what data we collect, how we use it, and how we protect it.")
                    }

                    // What We Collect
                    PrivacySection(
                        title: "What Information We Collect",
                        icon: "doc.text.fill",
                        iconColor: .blue
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Information Stored on Your Device")
                                .fontWeight(.medium)

                            Text("• Your profile name (if you choose to add one)")
                            Text("• Your belt level and learning preferences")
                            Text("• Your study progress and session history")
                            Text("• Your flashcard performance and test results")

                            Text("All of this data stays on your device. We never see it, access it, or store it on our servers.")
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            Divider()
                                .padding(.vertical, 8)

                            Text("Optional Information You Choose to Share")
                                .fontWeight(.medium)

                            Text("If you submit feedback or vote on features:")

                            Text("• Your iOS version (helps us fix bugs)")
                            Text("• Your belt level (if you tick the box to share it)")
                            Text("• Your most-used feature (if you tick the box to share it)")
                            Text("• The feedback text you write")

                            Text("You decide what to share. We never collect this automatically.")
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            Divider()
                                .padding(.vertical, 8)

                            Text("Technical Information During Testing")
                                .fontWeight(.medium)

                            Text("During TestFlight testing, Apple automatically sends us crash reports. These include:")

                            Text("• Device type and iOS version")
                            Text("• What the app was doing when it crashed")
                            Text("• Technical diagnostic information")

                            Text("These reports never include your name, profile data, or progress information.")
                                .fontWeight(.medium)
                                .padding(.top, 4)
                        }
                    }

                    // What We Don't Collect
                    PrivacySection(
                        title: "What We Don't Collect",
                        icon: "hand.raised.slash.fill",
                        iconColor: .orange
                    ) {
                        Text("We don't collect:")

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Your name, email, or contact details (unless you choose to include them in feedback)")
                            Text("• Your location")
                            Text("• Your browsing habits")
                            Text("• Advertising identifiers")
                            Text("• Analytics about how you use the app")
                        }

                        Text("We don't track you. We don't build profiles. We don't sell data. Full stop.")
                            .fontWeight(.medium)
                            .padding(.top, 8)
                    }

                    // How We Use Information
                    PrivacySection(
                        title: "How We Use Your Information",
                        icon: "gearshape.fill",
                        iconColor: .gray
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Data on Your Device")
                                .fontWeight(.medium)

                            Text("Your profile and progress data is used solely to provide the app's functionality - tracking your learning, showing your progress, and customising your experience. This data never leaves your device unless you back it up to iCloud (which you control through your iPhone settings).")

                            Divider()
                                .padding(.vertical, 8)

                            Text("Feedback You Submit")
                                .fontWeight(.medium)

                            Text("When you submit feedback, we use it to:")

                            Text("• Fix bugs you've reported")
                            Text("• Consider feature requests")
                            Text("• Understand which features are most valuable")
                            Text("• Prioritise development work")

                            Text("If you include demographic information (belt level, favourite feature), we may use this in aggregate to understand our user community - but we'll never identify you individually.")
                                .padding(.top, 4)

                            Divider()
                                .padding(.vertical, 8)

                            Text("Crash Reports")
                                .fontWeight(.medium)

                            Text("We use crash reports to identify and fix bugs. These reports help us make the app more stable and reliable for everyone.")
                        }
                    }

                    // Data Storage and Security
                    PrivacySection(
                        title: "How We Store and Protect Your Data",
                        icon: "lock.shield.fill",
                        iconColor: .green
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("On Your Device")
                                .fontWeight(.medium)

                            Text("Your profile and progress data is stored using Apple's SwiftData framework, which is encrypted as part of your device's standard security. Only you can access it.")

                            Divider()
                                .padding(.vertical, 8)

                            Text("In the Cloud")
                                .fontWeight(.medium)

                            Text("Feedback submissions and roadmap votes are stored using Apple's CloudKit service, which provides enterprise-grade security. Apple handles all the infrastructure, encryption, and data protection.")

                            Text("We can't identify you from this data - CloudKit keeps user identities private, even from us.")
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            Divider()
                                .padding(.vertical, 8)

                            Text("iCloud Backups")
                                .fontWeight(.medium)

                            Text("If you have iCloud backup enabled on your device, your TKDojang progress data may be included in your backups. This is managed entirely by Apple and controlled through your iPhone settings - we have no access to these backups.")
                        }
                    }

                    // Your Rights
                    PrivacySection(
                        title: "Your Rights and Choices",
                        icon: "person.fill.checkmark",
                        iconColor: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("You have complete control over your data:")

                            Text("Access Your Data")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("All your data is visible within the app - your profiles, progress, and history are all accessible through the Profile tab.")

                            Text("Delete Your Data")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("You can delete profiles, reset progress, or clear all data at any time through Settings → Data Management. Once deleted, it's gone permanently.")

                            Text("Export Your Data")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("You can export your progress data as JSON through Settings → Data Management if you want to keep a copy or move it elsewhere.")

                            Text("Control Feedback Sharing")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("When submitting feedback, you choose whether to share demographic information. Both options are presented as tick boxes - nothing is shared unless you explicitly tick them.")
                        }
                    }

                    // Third Parties
                    PrivacySection(
                        title: "Third-Party Services",
                        icon: "building.2.fill",
                        iconColor: .indigo
                    ) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("We use only Apple's services:")

                            Text("Apple CloudKit")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("Used for feedback submissions and roadmap voting. Apple manages all data storage and security. See Apple's privacy policy at apple.com/legal/privacy")

                            Text("Apple TestFlight")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("Used during beta testing to collect crash reports. Apple manages this service. See Apple's privacy policy at apple.com/legal/privacy")

                            Text("We don't use:")
                                .fontWeight(.medium)
                                .padding(.top, 8)

                            Text("• Google Analytics or similar tracking services")
                            Text("• Facebook or social media SDKs")
                            Text("• Advertising networks")
                            Text("• Any third-party analytics")
                        }
                    }

                    // Children's Privacy
                    PrivacySection(
                        title: "Children's Privacy",
                        icon: "figure.2.and.child.holdinghands",
                        iconColor: .pink
                    ) {
                        Text("TKDojang is designed to be family-friendly and suitable for children aged 9 and above.")

                        Text("We collect the same minimal data from all users regardless of age. We don't knowingly collect personal information from children, and all data stays on the device unless a child chooses to submit feedback (which should be done with parental guidance).")

                        Text("Parents can review, manage, and delete their children's profiles through the app's Data Management section.")
                            .padding(.top, 8)
                    }

                    // Changes to Policy
                    PrivacySection(
                        title: "Changes to This Policy",
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .cyan
                    ) {
                        Text("If we change this privacy policy, we'll update the 'Last updated' date at the top and notify you through the app's 'What's New' section.")

                        Text("We'll never make changes that reduce your privacy protections without giving you clear notice and choice.")
                            .fontWeight(.medium)
                            .padding(.top, 8)
                    }

                    // Contact
                    PrivacySection(
                        title: "Questions or Concerns",
                        icon: "questionmark.circle.fill",
                        iconColor: .orange
                    ) {
                        Text("If you have questions about this privacy policy or how we handle your data, please submit feedback through the Community Hub within the app.")

                        Text("We'll respond through the app's feedback system, which keeps your identity private whilst still allowing two-way communication.")
                            .padding(.top, 8)
                    }

                    // Footer
                    VStack(spacing: 8) {
                        Divider()

                        Text("Built with privacy and respect for learners")
                            .font(.subheadline)
                            .italic()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Text("© 2025 Craig Matthew Harris")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Privacy Section Component

struct PrivacySection<Content: View>: View {
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
                    .font(.title3)
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

#Preview {
    PrivacyPolicyView()
}
