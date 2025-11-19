import SwiftUI
import SwiftData

/**
 * ProfileCustomizationStepView.swift
 *
 * PURPOSE: Second step of onboarding - customize the default "Student" profile
 *
 * STEP 2 of 6 in initial tour
 *
 * WHY: Personalizing the profile immediately creates ownership and engagement
 * Users can update name, belt level, and learning mode preference
 */

struct ProfileCustomizationStepView: View {
    @Binding var name: String
    @Binding var selectedBelt: BeltLevel?
    @Binding var selectedLearningMode: LearningMode

    let availableBelts: [BeltLevel]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text("Customize Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text("Let's personalise your learning experience. You can add up to 5 more users later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 30)

                // Form Fields
                VStack(alignment: .leading, spacing: 24) {
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.headline)

                        TextField("Enter your name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()

                        Text("What should we call you?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Belt Level Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Belt Level")
                            .font(.headline)

                        if availableBelts.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Menu {
                                ForEach(availableBelts, id: \.id) { belt in
                                    Button(action: {
                                        selectedBelt = belt
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(BeltTheme(from: belt).primaryColor)
                                                .frame(width: 20, height: 20)
                                            Text(belt.shortName)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    if let belt = selectedBelt {
                                        Circle()
                                            .fill(BeltTheme(from: belt).primaryColor)
                                            .frame(width: 24, height: 24)
                                        Text(belt.shortName)
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    } else {
                                        Text("Select Belt Level")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                }
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }

                        Text("Choose your current Taekwondo rank")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Learning Mode Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learning Focus")
                            .font(.headline)

                        Picker("Learning Mode", selection: $selectedLearningMode) {
                            ForEach(LearningMode.allCases, id: \.self) { mode in
                                Text(mode.displayName)
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Show description for selected mode
                        Text(selectedLearningMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Note about profile menu
                    Text("Use the profile menu to add gradings, change icon and colour, and set learning mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)

                // Swipe hint
                VStack(spacing: 8) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.5))
                    Text("Swipe to continue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Preview

struct ProfileCustomizationStepView_Previews: PreviewProvider {
    @State static var testName = "Student"
    @State static var testBelt: BeltLevel? = nil
    @State static var testMode = LearningMode.mastery

    static var previews: some View {
        ProfileCustomizationStepView(
            name: $testName,
            selectedBelt: $testBelt,
            selectedLearningMode: $testMode,
            availableBelts: []
        )
    }
}
