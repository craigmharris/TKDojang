# Push Notification Setup Guide

## Overview

TKDojang uses CloudKit push notifications to notify users when developers respond to their feedback submissions.

**Status**: Code ready, certificate configuration required

---

## Apple Developer Portal Setup (USER ACTION REQUIRED)

### Step 1: Create Push Notification Certificate

1. Navigate to: https://developer.apple.com/account/resources/certificates/list
2. Click **"+"** to create a new certificate
3. Select **"Apple Push Notification service SSL (Sandbox & Production)"**
4. Click **Continue**
5. **App ID**: Select `com.craigmatthewharris.TKDojang`
6. Click **Continue**
7. **Create Certificate Signing Request (CSR)**:
   - Open **Keychain Access** on Mac
   - Menu: Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority
   - Enter your email address
   - Common Name: "TKDojang Push Notification"
   - Select "Saved to disk"
   - Click **Continue**, save the `.certSigningRequest` file
8. **Upload CSR** to Apple Developer Portal
9. **Download** the generated `.cer` certificate file
10. **Double-click** the `.cer` file to install in Keychain Access

### Step 2: Export Certificate for Xcode

1. Open **Keychain Access**
2. Find certificate: "Apple Push Services: com.craigmatthewharris.TKDojang"
3. **Right-click** → Export
4. Save as `.p12` file (set a password if prompted)
5. Certificate is now ready for use

---

## Xcode Configuration (Already Done)

✅ The following is already configured in the project:

### Entitlements
```xml
<!-- TKDojang.entitlements -->
<key>aps-environment</key>
<string>development</string>

<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### Code Implementation
- ✅ `CloudKitFeedbackService.swift` creates subscriptions automatically
- ✅ Push notification subscription created when user submits feedback
- ✅ Notification triggered when `developerResponse` field is updated

---

## Testing Push Notifications

### Test Flow

1. **Submit Feedback from App**:
   - Run app on simulator or device
   - Navigate to Community Hub → Send Feedback
   - Submit test feedback (e.g., "Testing push notifications")
   - Note: Subscription is created automatically

2. **Verify Subscription in CloudKit Console**:
   - Navigate to: https://icloud.developer.apple.com/dashboard
   - Select container: `iCloud.com.craigmatthewharris.TKDojang`
   - Go to **Data → Subscriptions**
   - Verify subscription exists for your feedback item (ID format: `feedback-[UUID]`)

3. **Respond to Feedback (Trigger Notification)**:
   - In CloudKit Console → Data → Public Database
   - Query record type: `Feedback`
   - Find your test feedback record
   - Click to edit
   - Add text to `developerResponse` field (e.g., "Thank you for testing!")
   - Update `responseStatus` to "Responded"
   - Set `responseTimestamp` to current date
   - **Save**

4. **Receive Notification**:
   - Notification should appear on device/simulator
   - Alert body: "Developer responded to your feedback"
   - Tapping notification opens app (MyFeedbackView)

---

## Push Notification Payload

CloudKit automatically sends this notification when `developerResponse` is updated:

```json
{
  "aps": {
    "alert": {
      "title": "TKDojang",
      "body": "Developer responded to your feedback"
    },
    "sound": "default",
    "badge": 1
  },
  "feedbackID": "[UUID]",
  "recordID": "[CKRecord.ID]"
}
```

---

## Troubleshooting

### Notifications Not Received

**Check 1: Device Settings**
- Settings → TKDojang → Notifications → Ensure "Allow Notifications" is ON

**Check 2: iCloud Sign-In**
- Settings → [Your Name] → Ensure signed into iCloud

**Check 3: Subscription Created**
- CloudKit Console → Data → Subscriptions
- Should see subscription with ID: `feedback-[UUID]`

**Check 4: Certificate Installed**
- Keychain Access → Certificates
- Should see: "Apple Push Services: com.craigmatthewharris.TKDojang"

**Check 5: Entitlements**
- Xcode → Project → Signing & Capabilities
- Ensure `aps-environment` is set (development or production)

### Simulator Limitations

- **iOS Simulator (macOS 13+)**: Push notifications work on Apple Silicon Macs
- **Older simulators**: May not support push notifications (test on real device)

### Production vs Development

- **Development**: Uses sandbox APNs server (current entitlement setting)
- **Production**: Change `aps-environment` to `production` before App Store submission

---

## Code Reference

### Subscription Creation (Automatic)

```swift
// CloudKitFeedbackService.swift:116-135
private func subscribeToResponse(feedbackID: String) async throws {
    let predicate = NSPredicate(format: "feedbackID == %@", feedbackID)

    let subscription = CKQuerySubscription(
        recordType: "Feedback",
        predicate: predicate,
        subscriptionID: "feedback-\(feedbackID)",
        options: [.firesOnRecordUpdate]
    )

    let notificationInfo = CKSubscription.NotificationInfo()
    notificationInfo.alertBody = "Developer responded to your feedback"
    notificationInfo.soundName = "default"
    notificationInfo.shouldBadge = true
    subscription.notificationInfo = notificationInfo

    _ = try await publicDatabase.save(subscription)
}
```

### Notification Handling (Future Enhancement)

For advanced notification handling, implement in `TKDojangApp.swift`:

```swift
import UserNotifications

@main
struct TKDojangApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // ... existing code
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - navigate to MyFeedbackView
        // Extract feedbackID from notification userInfo
        completionHandler()
    }
}
```

---

## Production Checklist

Before App Store submission:

- [ ] Change `aps-environment` from `development` to `production`
- [ ] Generate production push notification certificate (not just sandbox)
- [ ] Test notifications on TestFlight build
- [ ] Verify notification permissions requested properly
- [ ] Test notification deep linking (tap notification → opens MyFeedbackView)
- [ ] Ensure badge counts update correctly

---

## Status

**Current**: Development environment configured, code ready, certificate setup required

**Next Steps**:
1. Create push notification certificate in Apple Developer Portal (see Step 1 above)
2. Test notification flow with simulator/device
3. Verify subscription creation in CloudKit Console
4. Test developer response notification delivery
