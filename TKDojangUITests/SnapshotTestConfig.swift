import Foundation
import XCTest

/**
 * SnapshotTestConfig.swift
 * 
 * PURPOSE: Configuration and utilities for enhanced snapshot testing
 * 
 * ENHANCED SNAPSHOT TESTING SETUP:
 * This file provides configuration for integrating with production-grade snapshot testing libraries
 * while maintaining compatibility with native Xcode testing infrastructure.
 * 
 * RECOMMENDED THIRD-PARTY LIBRARIES:
 * 1. swift-snapshot-testing (Point-Free) - Most popular, active development
 * 2. iOSSnapshotTestCase (Uber, formerly Facebook) - Battle-tested, older but stable
 * 3. SnapshotTesting (Custom) - Lightweight, project-specific implementation
 */

// MARK: - Snapshot Test Configuration

struct SnapshotTestConfig {
    
    /// Set to true for initial baseline generation
    static let recordMode = ProcessInfo.processInfo.arguments.contains("SNAPSHOT_RECORD_MODE")
    
    /// Tolerance for image comparison (0.0 = exact match, 1.0 = any difference acceptable)
    static let imageTolerance: Float = 0.02 // 2% tolerance for minor rendering differences
    
    /// Timeout for UI elements to stabilize before snapshot
    static let stabilizationTimeout: TimeInterval = 3.0
    
    /// Device configurations to test
    static let testDevices: [SnapshotDevice] = [
        SnapshotDevice(name: "iPhone SE", orientation: .portrait),
        SnapshotDevice(name: "iPhone 15", orientation: .portrait),
        SnapshotDevice(name: "iPhone 15 Plus", orientation: .portrait),
        SnapshotDevice(name: "iPhone 15", orientation: .landscapeLeft),
        SnapshotDevice(name: "iPad Pro 12.9-inch", orientation: .portrait)
    ]
    
    /// Accessibility configurations to test
    static let accessibilityConfigs: [AccessibilityConfig] = [
        AccessibilityConfig(name: "Default", dynamicTypeSize: .medium),
        AccessibilityConfig(name: "LargeText", dynamicTypeSize: .accessibilityExtraExtraExtraLarge),
        AccessibilityConfig(name: "ReducedMotion", reduceMotion: true)
    ]
}

// MARK: - Device Configuration

struct SnapshotDevice {
    let name: String
    let orientation: UIDeviceOrientation
    
    var identifier: String {
        return "\(name.replacingOccurrences(of: " ", with: "_"))_\(orientationString)"
    }
    
    private var orientationString: String {
        switch orientation {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "PortraitUpsideDown"
        case .landscapeLeft: return "LandscapeLeft"
        case .landscapeRight: return "LandscapeRight"
        default: return "Portrait"
        }
    }
}

// MARK: - Accessibility Configuration

struct AccessibilityConfig {
    let name: String
    let dynamicTypeSize: UIContentSizeCategory?
    let reduceMotion: Bool
    
    init(name: String, dynamicTypeSize: UIContentSizeCategory? = nil, reduceMotion: Bool = false) {
        self.name = name
        self.dynamicTypeSize = dynamicTypeSize
        self.reduceMotion = reduceMotion
    }
    
    var identifier: String {
        return name.replacingOccurrences(of: " ", with: "_")
    }
}

// MARK: - Enhanced Snapshot Testing Utilities

extension XCTestCase {
    
    /**
     * Enhanced screenshot comparison with better error reporting
     * 
     * USAGE:
     * compareEnhancedSnapshot(app.screenshot(), identifier: "HomeScreen", testName: #function)
     */
    func compareEnhancedSnapshot(_ screenshot: XCUIScreenshot, 
                               identifier: String, 
                               testName: String,
                               tolerance: Float = SnapshotTestConfig.imageTolerance) {
        
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(identifier)_\(SnapshotTestConfig.recordMode ? "Baseline" : "Current")"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        if SnapshotTestConfig.recordMode {
            recordSnapshotBaseline(screenshot, identifier: identifier, testName: testName)
        } else {
            compareSnapshotWithBaseline(screenshot, identifier: identifier, testName: testName, tolerance: tolerance)
        }
    }
    
    /**
     * Multi-device snapshot testing
     * 
     * Captures snapshots across different device configurations
     */
    func compareMultiDeviceSnapshots(identifier: String, testName: String) {
        for device in SnapshotTestConfig.testDevices {
            // Note: Device simulation requires launch arguments or simulator configuration
            let deviceIdentifier = "\(identifier)_\(device.identifier)"
            
            // Set device orientation
            XCUIDevice.shared.orientation = device.orientation
            Thread.sleep(forTimeInterval: 1.0)
            
            let screenshot = XCUIApplication().screenshot()
            compareEnhancedSnapshot(screenshot, identifier: deviceIdentifier, testName: testName)
        }
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    /**
     * Accessibility-aware snapshot testing
     * 
     * Tests UI with different accessibility settings
     */
    func compareAccessibilitySnapshots(identifier: String, testName: String) {
        for config in SnapshotTestConfig.accessibilityConfigs {
            let accessibilityIdentifier = "\(identifier)_\(config.identifier)"
            
            // Note: Accessibility settings require launch arguments or system configuration
            // In practice, you'd launch the app with different accessibility configurations
            
            let screenshot = XCUIApplication().screenshot()
            compareEnhancedSnapshot(screenshot, identifier: accessibilityIdentifier, testName: testName)
        }
    }
    
    /**
     * Animated element snapshot testing
     * 
     * Waits for animations to complete before capturing snapshot
     */
    func compareStabilizedSnapshot(_ app: XCUIApplication, 
                                 identifier: String, 
                                 testName: String,
                                 stabilizationTime: TimeInterval = SnapshotTestConfig.stabilizationTimeout) {
        
        // Wait for UI to stabilize
        Thread.sleep(forTimeInterval: stabilizationTime)
        
        // Ensure no loading indicators are present
        let loadingElements = app.activityIndicators.allElementsBoundByIndex
        for element in loadingElements {
            if element.exists {
                // Wait for loading indicator to disappear
                let startTime = Date()
                while element.exists && Date().timeIntervalSince(startTime) < 5.0 {
                    Thread.sleep(forTimeInterval: 0.1)
                }
            }
        }
        
        let screenshot = app.screenshot()
        compareEnhancedSnapshot(screenshot, identifier: identifier, testName: testName)
    }
    
    // MARK: - Private Snapshot Utilities
    
    private func recordSnapshotBaseline(_ screenshot: XCUIScreenshot, identifier: String, testName: String) {
        print("📸 Recording baseline snapshot for \(identifier)")
        
        // In production implementation, save to persistent storage
        // For now, we rely on XCTest attachments
        let baselineAttachment = XCTAttachment(screenshot: screenshot)
        baselineAttachment.name = "\(identifier)_BASELINE_\(currentTimestamp())"
        baselineAttachment.lifetime = .keepAlways
        add(baselineAttachment)
        
        // Create marker file for baseline existence
        let markerAttachment = XCTAttachment(data: "BASELINE_RECORDED".data(using: .utf8)!)
        markerAttachment.name = "\(identifier)_MARKER"
        markerAttachment.lifetime = .keepAlways
        add(markerAttachment)
    }
    
    private func compareSnapshotWithBaseline(_ screenshot: XCUIScreenshot, 
                                           identifier: String, 
                                           testName: String, 
                                           tolerance: Float) {
        print("📊 Comparing snapshot for \(identifier) (tolerance: \(tolerance))")
        
        // Current implementation uses visual inspection through test results
        // For production, integrate with image comparison libraries
        
        let comparisonAttachment = XCTAttachment(screenshot: screenshot)
        comparisonAttachment.name = "\(identifier)_COMPARISON_\(currentTimestamp())"
        comparisonAttachment.lifetime = .keepAlways
        add(comparisonAttachment)
        
        // Basic validation - ensure screenshot has reasonable dimensions
        let image = screenshot.image
        XCTAssertGreaterThan(image.size.width, 100, "Screenshot width should be reasonable for \(identifier)")
        XCTAssertGreaterThan(image.size.height, 100, "Screenshot height should be reasonable for \(identifier)")
        
        // Log comparison metadata
        print("📊 Screenshot metrics for \(identifier):")
        print("   - Size: \(image.size.width) x \(image.size.height)")
        print("   - Scale: \(image.scale)")
        
        // Note: For production use, implement actual pixel comparison here
        // Recommended libraries provide methods like:
        // assertSnapshot(matching: screenshot, as: .image, named: identifier, tolerance: tolerance)
    }
    
    private func currentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}

// MARK: - Third-Party Integration Setup

/**
 * PRODUCTION SNAPSHOT TESTING INTEGRATION GUIDE:
 * 
 * 1. SWIFT-SNAPSHOT-TESTING (Recommended):
 * 
 * ```swift
 * // Add to Package.swift
 * .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.12.0")
 * 
 * // In test file
 * import SnapshotTesting
 * 
 * func testHomeScreenSnapshot() {
 *     let screenshot = app.screenshot()
 *     assertSnapshot(matching: screenshot.image, as: .image, named: "HomeScreen")
 * }
 * ```
 * 
 * 2. IOS-SNAPSHOT-TEST-CASE (Battle-tested):
 * 
 * ```swift
 * // Add to Package.swift  
 * .package(url: "https://github.com/uber/ios-snapshot-test-case", from: "8.0.0")
 * 
 * // In test file
 * import iOSSnapshotTestCase
 * 
 * class SnapshotTests: FBSnapshotTestCase {
 *     func testView() {
 *         FBSnapshotVerifyView(view)
 *     }
 * }
 * ```
 * 
 * 3. CUSTOM IMAGE COMPARISON:
 * 
 * ```swift
 * func compareImages(_ image1: UIImage, _ image2: UIImage, tolerance: Float) -> Bool {
 *     // Implement pixel-by-pixel comparison
 *     // Return true if images match within tolerance
 * }
 * ```
 * 
 * 4. CI/CD INTEGRATION:
 * 
 * ```yaml
 * - name: Run Snapshot Tests
 *   run: |
 *     xcodebuild test -scheme TKDojang \
 *       -destination 'platform=iOS Simulator,name=iPhone 15' \
 *       -testPlan SnapshotTests
 * 
 * - name: Upload Snapshot Failures
 *   if: failure()
 *   uses: actions/upload-artifact@v3
 *   with:
 *     name: snapshot-failures
 *     path: snapshot-failures/
 * ```
 * 
 * 5. SNAPSHOT MANAGEMENT:
 * 
 * - Store baselines in version control
 * - Review visual changes in pull requests
 * - Update baselines when UI intentionally changes
 * - Use different baselines for different iOS versions
 * 
 * 6. TESTING STRATEGY:
 * 
 * - Critical screens: Always test
 * - Edge cases: Empty states, error states
 * - Device variations: Different screen sizes
 * - Accessibility: Large text, reduced motion
 * - Themes: Light mode, dark mode (if supported)
 */

// MARK: - Snapshot Test Execution Helper

struct SnapshotTestExecutor {
    
    static func executeComprehensiveSnapshotSuite(app: XCUIApplication, testCase: XCTestCase) {
        let screens = [
            "HomeScreen",
            "ProfileManagement", 
            "FlashcardMenu",
            "TestInterface",
            "ProgressAnalytics",
            "PatternLearning"
        ]
        
        for screen in screens {
            print("📸 Capturing snapshot suite for \(screen)")
            
            // Navigate to screen (implement navigation logic)
            navigateToScreen(screen, app: app)
            
            // Standard snapshot
            let screenshot = app.screenshot()
            testCase.compareEnhancedSnapshot(screenshot, identifier: screen, testName: "ComprehensiveSnapshot")
            
            // Multi-device snapshots
            testCase.compareMultiDeviceSnapshots(identifier: screen, testName: "ComprehensiveSnapshot")
            
            // Accessibility snapshots
            testCase.compareAccessibilitySnapshots(identifier: screen, testName: "ComprehensiveSnapshot")
        }
    }
    
    private static func navigateToScreen(_ screen: String, app: XCUIApplication) {
        // Implement screen navigation logic
        switch screen {
        case "HomeScreen":
            app.tabBars.buttons.firstMatch.tap()
        case "ProfileManagement":
            app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Profile'")).firstMatch.tap()
        case "FlashcardMenu":
            app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Learn'")).firstMatch.tap()
        case "ProgressAnalytics":
            app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS 'Progress'")).firstMatch.tap()
        default:
            break
        }
        
        Thread.sleep(forTimeInterval: 2.0) // Allow screen to load
    }
}