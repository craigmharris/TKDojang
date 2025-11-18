import Foundation
import UIKit
import UserNotifications

/**
 * NotificationPermissionManager.swift
 *
 * PURPOSE: Manage push notification permissions with contextual user explanations
 *
 * FEATURES:
 * - Check current notification permission status
 * - Request permission with iOS system dialog
 * - Register for remote notifications with APNs
 * - Track permission state for UI updates
 *
 * DESIGN DECISIONS:
 * - Request in context (when user submits first feedback)
 * - Graceful degradation (feedback works without notifications)
 * - Clear explanation before system prompt
 * - UserDefaults tracking to avoid repeated requests
 *
 * WHY NEEDED:
 * iOS requires explicit user permission for push notifications. We use notifications
 * to alert users when developers respond to their feedback submissions.
 */

@MainActor
class NotificationPermissionManager: ObservableObject {

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var hasRequestedPermissionThisSession = false

    private let userDefaults = UserDefaults.standard
    private let hasRequestedPermissionKey = "hasRequestedNotificationPermission"

    // MARK: - Initialization

    init() {
        Task {
            await checkPermissionStatus()
        }
    }

    // MARK: - Permission Status

    /// Check current notification permission status
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    /// Check if we should show permission explanation
    var shouldShowPermissionExplanation: Bool {
        // Show if: permission not determined AND haven't asked this user before
        permissionStatus == .notDetermined && !hasAskedUserBefore
    }

    /// Check if user has been asked before (persisted across app launches)
    var hasAskedUserBefore: Bool {
        userDefaults.bool(forKey: hasRequestedPermissionKey)
    }

    /// Mark that we've asked the user for permission
    private func markAsAsked() {
        userDefaults.set(true, forKey: hasRequestedPermissionKey)
        hasRequestedPermissionThisSession = true
    }

    // MARK: - Permission Request

    /// Request notification permission from iOS
    /// Returns: true if granted, false if denied
    @discardableResult
    func requestPermission() async -> Bool {
        // Mark that we've asked (do this before request to avoid double-asking)
        markAsAsked()

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            // Update status
            await checkPermissionStatus()

            if granted {
                // Register for remote notifications with APNs
                await registerForRemoteNotifications()
            }

            return granted

        } catch {
            print("❌ Notification permission request failed: \(error)")
            return false
        }
    }

    /// Register for remote notifications with APNs (must be called on main thread)
    private func registerForRemoteNotifications() async {
        #if targetEnvironment(simulator)
        // Simulator support for push notifications (iOS 16.4+, Apple Silicon only)
        await UIApplication.shared.registerForRemoteNotifications()
        #else
        // Real device
        await UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    // MARK: - Permission Guidance

    /// Get user-friendly explanation of current permission state
    var permissionExplanation: String {
        switch permissionStatus {
        case .notDetermined:
            return "Enable notifications to get updates when developers respond to your feedback."
        case .denied:
            return "Notifications are disabled. You can enable them in Settings > TKDojang > Notifications."
        case .authorized, .provisional, .ephemeral:
            return "You'll receive notifications when developers respond to your feedback."
        @unknown default:
            return "Notification status unknown."
        }
    }

    /// Get actionable message for denied state
    var deniedPermissionGuidance: String {
        """
        Your feedback was submitted successfully!

        To receive notifications when developers respond, enable notifications in:
        Settings > TKDojang > Notifications
        """
    }

    // MARK: - Settings URL

    /// Open iOS Settings for this app
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }

        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
