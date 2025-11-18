import UIKit
import UserNotifications

/**
 * AppDelegate.swift
 *
 * PURPOSE: Handle app-level events and notification interactions
 *
 * RESPONSIBILITIES:
 * - Register for remote notifications
 * - Handle notification taps (deep linking to specific feedback)
 * - Manage notification presentation while app is in foreground
 *
 * DESIGN DECISIONS:
 * - Use UIApplicationDelegateAdaptor to bridge UIKit AppDelegate with SwiftUI App
 * - Implement UNUserNotificationCenterDelegate for notification handling
 * - Post NotificationCenter events for deep link navigation
 *
 * WHY NEEDED:
 * Notification tap handling requires UIKit AppDelegate methods that aren't
 * available in pure SwiftUI App lifecycle. This bridges that gap.
 */

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // MARK: - Notification Keys

    /// Posted when user taps a notification to open specific feedback
    static let openFeedbackNotification = Notification.Name("openFeedbackItem")

    /// UserInfo key for feedback ID
    static let feedbackIDKey = "feedbackID"

    // MARK: - App Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set ourselves as the notification center delegate
        UNUserNotificationCenter.current().delegate = self

        print("✅ AppDelegate: Notification handling configured")
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear badge when app becomes active
        // WHY: Badge should only show when app is in background
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    // MARK: - Remote Notifications Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to hex string for debugging
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("✅ AppDelegate: Registered for remote notifications")
        print("📱 Device Token: \(tokenString)")

        // NOTE: We don't need to send this token to a server since CloudKit
        // handles APNs registration automatically
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ AppDelegate: Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - Notification Handling (App in Foreground)

    /// Called when a notification arrives while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        // WHY: User should see feedback responses immediately
        completionHandler([.banner, .sound, .badge])

        print("📬 AppDelegate: Notification received in foreground")
    }

    // MARK: - Notification Handling (User Tapped Notification)

    /// Called when user taps on a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        print("🔔 AppDelegate: User tapped notification")
        print("📋 UserInfo: \(userInfo)")

        // CloudKit notification structure:
        // userInfo contains "ck" dictionary with query notification data
        var feedbackID: String?

        // Extract from subscription ID (most reliable for query subscriptions)
        if let ckData = userInfo["ck"] as? [String: Any],
           let qryData = ckData["qry"] as? [String: Any],
           let subscriptionID = qryData["sid"] as? String,
           subscriptionID.hasPrefix("feedback-") {
            feedbackID = String(subscriptionID.dropFirst("feedback-".count))
            print("✅ AppDelegate: Feedback ID from subscription ID: \(feedbackID!)")
        }
        // Fallback: Try to extract from CloudKit record fields (if included)
        else if let ckData = userInfo["ck"] as? [String: Any],
                let notification = ckData["qry"] as? [String: Any],
                let recordFields = notification["af"] as? [String: Any],
                let feedbackIDValue = recordFields["feedbackID"] as? String {
            feedbackID = feedbackIDValue
            print("✅ AppDelegate: Feedback ID from CloudKit record fields: \(feedbackIDValue)")
        }
        // Last resort: Try direct feedbackID key
        else if let directFeedbackID = userInfo["feedbackID"] as? String {
            feedbackID = directFeedbackID
            print("✅ AppDelegate: Feedback ID from direct key: \(directFeedbackID)")
        }

        if let feedbackID = feedbackID {
            // Post notification to trigger navigation
            NotificationCenter.default.post(
                name: AppDelegate.openFeedbackNotification,
                object: nil,
                userInfo: [AppDelegate.feedbackIDKey: feedbackID]
            )
        } else {
            print("⚠️ AppDelegate: Could not extract feedbackID from notification")
            print("📋 Full userInfo structure: \(userInfo)")
        }

        // Clear badge when notification is tapped
        Task { @MainActor in
            UIApplication.shared.applicationIconBadgeNumber = 0
        }

        completionHandler()
    }
}
