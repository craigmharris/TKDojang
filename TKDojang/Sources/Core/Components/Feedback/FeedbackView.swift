import SwiftUI
import SwiftData

/**
 * FeedbackView.swift
 *
 * PURPOSE: User feedback submission with CloudKit integration
 *
 * FEATURES:
 * - Category selection (Bug, Feature, Content, General)
 * - Free-text feedback description
 * - Opt-in demographic sharing for feature prioritization
 * - Anonymous CloudKit submission
 * - Automatic push notification subscription for developer responses
 *
 * DESIGN DECISIONS:
 * - Privacy-first: No email required, CloudKit manages anonymous user IDs
 * - Opt-in demographics: Users control sharing belt level, learning mode, usage stats
 * - Device info always included: Essential for bug tracking (iOS version, device model)
 * - Push notifications: User gets notified when developer responds
 */

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var feedbackService = CloudKitFeedbackService()

    // Form state
    @State private var selectedCategory: FeedbackCategory = .general
    @State private var feedbackText: String = ""
    @State private var shareDemographics: Bool = true

    // Submission state
    @State private var isSubmitting = false
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage: String = ""

    // User profile for demographics (optional)
    var userProfile: UserProfile?

    var canSubmit: Bool {
        !feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category Selection
                categorySection

                // Feedback Text
                feedbackTextSection

                // Privacy Controls
                privacySection

                // Device Info Preview
                deviceInfoSection
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task {
                            await submitFeedback()
                        }
                    }
                    .disabled(!canSubmit || isSubmitting)
                }
            }
            .alert("Feedback Sent", isPresented: $showingConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you! Your feedback helps shape TKDojang's future. You'll be notified when the developer responds.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .disabled(isSubmitting)
        }
    }

    // MARK: - Sections

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $selectedCategory) {
                ForEach(FeedbackCategory.allCases, id: \.self) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("What type of feedback?")
        } footer: {
            Text(categoryFooterText)
                .font(.caption)
        }
    }

    private var feedbackTextSection: some View {
        Section {
            TextEditor(text: $feedbackText)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) {
                    if feedbackText.isEmpty {
                        Text("Describe your \(selectedCategory.rawValue.lowercased()) in detail...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                }
        } header: {
            Text("Your Feedback")
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(isOn: $shareDemographics) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Share Usage Data")
                        .font(.body)
                    Text("Helps prioritize features for users like you")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if shareDemographics {
                VStack(alignment: .leading, spacing: 8) {
                    demographicRow(label: "Belt Level", value: userProfile?.currentBeltLevel.name ?? "Not set")
                    demographicRow(label: "Learning Mode", value: userProfile?.learningMode.rawValue ?? "Not set")
                    demographicRow(label: "Total Sessions", value: "\(userProfile?.studySessions.count ?? 0)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("Your feedback is anonymous. No email or personal identifiers are stored. You can disable usage data sharing anytime.")
                .font(.caption)
        }
    }

    private var deviceInfoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("The following device information will be included:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                deviceInfoRow(label: "App Version", value: Bundle.main.appVersion)
                deviceInfoRow(label: "iOS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                deviceInfoRow(label: "Device Model", value: "iPhone/iPad")
            }
        } header: {
            Text("Device Information")
        } footer: {
            Text("Device info helps us debug issues and test compatibility.")
                .font(.caption)
        }
    }

    // MARK: - Helper Views

    private func demographicRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }

    private func deviceInfoRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }

    private var categoryFooterText: String {
        switch selectedCategory {
        case .bug:
            return "Report crashes, errors, or unexpected behavior"
        case .feature:
            return "Suggest new features or improvements to existing ones"
        case .content:
            return "Report incorrect Korean terms, missing content, or suggest additions"
        case .general:
            return "Share general thoughts, questions, or appreciation"
        }
    }

    // MARK: - Actions

    private func submitFeedback() async {
        guard canSubmit else { return }

        isSubmitting = true

        // Gather demographics if user opted in
        var demographics: AnonymousDemographics? = nil
        if shareDemographics, let profile = userProfile {
            demographics = AnonymousDemographics(
                beltLevel: profile.currentBeltLevel.name,
                learningMode: profile.learningMode.rawValue,
                mostUsedFeature: nil, // Could track this in future
                totalSessions: profile.studySessions.count
            )
        }

        do {
            _ = try await feedbackService.submitFeedback(
                category: selectedCategory,
                text: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines),
                demographics: demographics
            )

            isSubmitting = false
            showingConfirmation = true

        } catch {
            isSubmitting = false
            errorMessage = "Failed to submit feedback: \(error.localizedDescription). Please try again."
            showingError = true
        }
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        (object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown"
    }

    var buildNumber: String {
        (object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "Unknown"
    }
}

// MARK: - Preview

#Preview {
    FeedbackView(userProfile: nil)
}
