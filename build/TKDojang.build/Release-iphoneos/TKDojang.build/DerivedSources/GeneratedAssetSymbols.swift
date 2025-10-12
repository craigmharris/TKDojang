import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "chon-ji-1" asset catalog image resource.
    static let chonJi1 = DeveloperToolsSupport.ImageResource(name: "chon-ji-1", bundle: resourceBundle)

    /// The "chon-ji-10" asset catalog image resource.
    static let chonJi10 = DeveloperToolsSupport.ImageResource(name: "chon-ji-10", bundle: resourceBundle)

    /// The "chon-ji-11" asset catalog image resource.
    static let chonJi11 = DeveloperToolsSupport.ImageResource(name: "chon-ji-11", bundle: resourceBundle)

    /// The "chon-ji-12" asset catalog image resource.
    static let chonJi12 = DeveloperToolsSupport.ImageResource(name: "chon-ji-12", bundle: resourceBundle)

    /// The "chon-ji-13" asset catalog image resource.
    static let chonJi13 = DeveloperToolsSupport.ImageResource(name: "chon-ji-13", bundle: resourceBundle)

    /// The "chon-ji-14" asset catalog image resource.
    static let chonJi14 = DeveloperToolsSupport.ImageResource(name: "chon-ji-14", bundle: resourceBundle)

    /// The "chon-ji-15" asset catalog image resource.
    static let chonJi15 = DeveloperToolsSupport.ImageResource(name: "chon-ji-15", bundle: resourceBundle)

    /// The "chon-ji-16" asset catalog image resource.
    static let chonJi16 = DeveloperToolsSupport.ImageResource(name: "chon-ji-16", bundle: resourceBundle)

    /// The "chon-ji-17" asset catalog image resource.
    static let chonJi17 = DeveloperToolsSupport.ImageResource(name: "chon-ji-17", bundle: resourceBundle)

    /// The "chon-ji-18" asset catalog image resource.
    static let chonJi18 = DeveloperToolsSupport.ImageResource(name: "chon-ji-18", bundle: resourceBundle)

    /// The "chon-ji-19" asset catalog image resource.
    static let chonJi19 = DeveloperToolsSupport.ImageResource(name: "chon-ji-19", bundle: resourceBundle)

    /// The "chon-ji-2" asset catalog image resource.
    static let chonJi2 = DeveloperToolsSupport.ImageResource(name: "chon-ji-2", bundle: resourceBundle)

    /// The "chon-ji-3" asset catalog image resource.
    static let chonJi3 = DeveloperToolsSupport.ImageResource(name: "chon-ji-3", bundle: resourceBundle)

    /// The "chon-ji-4" asset catalog image resource.
    static let chonJi4 = DeveloperToolsSupport.ImageResource(name: "chon-ji-4", bundle: resourceBundle)

    /// The "chon-ji-5" asset catalog image resource.
    static let chonJi5 = DeveloperToolsSupport.ImageResource(name: "chon-ji-5", bundle: resourceBundle)

    /// The "chon-ji-6" asset catalog image resource.
    static let chonJi6 = DeveloperToolsSupport.ImageResource(name: "chon-ji-6", bundle: resourceBundle)

    /// The "chon-ji-7" asset catalog image resource.
    static let chonJi7 = DeveloperToolsSupport.ImageResource(name: "chon-ji-7", bundle: resourceBundle)

    /// The "chon-ji-8" asset catalog image resource.
    static let chonJi8 = DeveloperToolsSupport.ImageResource(name: "chon-ji-8", bundle: resourceBundle)

    /// The "chon-ji-9" asset catalog image resource.
    static let chonJi9 = DeveloperToolsSupport.ImageResource(name: "chon-ji-9", bundle: resourceBundle)

    /// The "chon-ji-diagram" asset catalog image resource.
    static let chonJiDiagram = DeveloperToolsSupport.ImageResource(name: "chon-ji-diagram", bundle: resourceBundle)

    /// The "chon-ji-starting" asset catalog image resource.
    static let chonJiStarting = DeveloperToolsSupport.ImageResource(name: "chon-ji-starting", bundle: resourceBundle)

    /// The "dan-gun-1" asset catalog image resource.
    static let danGun1 = DeveloperToolsSupport.ImageResource(name: "dan-gun-1", bundle: resourceBundle)

    /// The "dan-gun-10" asset catalog image resource.
    static let danGun10 = DeveloperToolsSupport.ImageResource(name: "dan-gun-10", bundle: resourceBundle)

    /// The "dan-gun-11" asset catalog image resource.
    static let danGun11 = DeveloperToolsSupport.ImageResource(name: "dan-gun-11", bundle: resourceBundle)

    /// The "dan-gun-12" asset catalog image resource.
    static let danGun12 = DeveloperToolsSupport.ImageResource(name: "dan-gun-12", bundle: resourceBundle)

    /// The "dan-gun-13" asset catalog image resource.
    static let danGun13 = DeveloperToolsSupport.ImageResource(name: "dan-gun-13", bundle: resourceBundle)

    /// The "dan-gun-14" asset catalog image resource.
    static let danGun14 = DeveloperToolsSupport.ImageResource(name: "dan-gun-14", bundle: resourceBundle)

    /// The "dan-gun-15" asset catalog image resource.
    static let danGun15 = DeveloperToolsSupport.ImageResource(name: "dan-gun-15", bundle: resourceBundle)

    /// The "dan-gun-16" asset catalog image resource.
    static let danGun16 = DeveloperToolsSupport.ImageResource(name: "dan-gun-16", bundle: resourceBundle)

    /// The "dan-gun-17" asset catalog image resource.
    static let danGun17 = DeveloperToolsSupport.ImageResource(name: "dan-gun-17", bundle: resourceBundle)

    /// The "dan-gun-18" asset catalog image resource.
    static let danGun18 = DeveloperToolsSupport.ImageResource(name: "dan-gun-18", bundle: resourceBundle)

    /// The "dan-gun-19" asset catalog image resource.
    static let danGun19 = DeveloperToolsSupport.ImageResource(name: "dan-gun-19", bundle: resourceBundle)

    /// The "dan-gun-2" asset catalog image resource.
    static let danGun2 = DeveloperToolsSupport.ImageResource(name: "dan-gun-2", bundle: resourceBundle)

    /// The "dan-gun-20" asset catalog image resource.
    static let danGun20 = DeveloperToolsSupport.ImageResource(name: "dan-gun-20", bundle: resourceBundle)

    /// The "dan-gun-21" asset catalog image resource.
    static let danGun21 = DeveloperToolsSupport.ImageResource(name: "dan-gun-21", bundle: resourceBundle)

    /// The "dan-gun-3" asset catalog image resource.
    static let danGun3 = DeveloperToolsSupport.ImageResource(name: "dan-gun-3", bundle: resourceBundle)

    /// The "dan-gun-4" asset catalog image resource.
    static let danGun4 = DeveloperToolsSupport.ImageResource(name: "dan-gun-4", bundle: resourceBundle)

    /// The "dan-gun-5" asset catalog image resource.
    static let danGun5 = DeveloperToolsSupport.ImageResource(name: "dan-gun-5", bundle: resourceBundle)

    /// The "dan-gun-6" asset catalog image resource.
    static let danGun6 = DeveloperToolsSupport.ImageResource(name: "dan-gun-6", bundle: resourceBundle)

    /// The "dan-gun-7" asset catalog image resource.
    static let danGun7 = DeveloperToolsSupport.ImageResource(name: "dan-gun-7", bundle: resourceBundle)

    /// The "dan-gun-8" asset catalog image resource.
    static let danGun8 = DeveloperToolsSupport.ImageResource(name: "dan-gun-8", bundle: resourceBundle)

    /// The "dan-gun-9" asset catalog image resource.
    static let danGun9 = DeveloperToolsSupport.ImageResource(name: "dan-gun-9", bundle: resourceBundle)

    /// The "dan-gun-diagram" asset catalog image resource.
    static let danGunDiagram = DeveloperToolsSupport.ImageResource(name: "dan-gun-diagram", bundle: resourceBundle)

    /// The "dan-gun-starting" asset catalog image resource.
    static let danGunStarting = DeveloperToolsSupport.ImageResource(name: "dan-gun-starting", bundle: resourceBundle)

    /// The "do-san-1" asset catalog image resource.
    static let doSan1 = DeveloperToolsSupport.ImageResource(name: "do-san-1", bundle: resourceBundle)

    /// The "do-san-10" asset catalog image resource.
    static let doSan10 = DeveloperToolsSupport.ImageResource(name: "do-san-10", bundle: resourceBundle)

    /// The "do-san-11" asset catalog image resource.
    static let doSan11 = DeveloperToolsSupport.ImageResource(name: "do-san-11", bundle: resourceBundle)

    /// The "do-san-12" asset catalog image resource.
    static let doSan12 = DeveloperToolsSupport.ImageResource(name: "do-san-12", bundle: resourceBundle)

    /// The "do-san-13" asset catalog image resource.
    static let doSan13 = DeveloperToolsSupport.ImageResource(name: "do-san-13", bundle: resourceBundle)

    /// The "do-san-14" asset catalog image resource.
    static let doSan14 = DeveloperToolsSupport.ImageResource(name: "do-san-14", bundle: resourceBundle)

    /// The "do-san-15" asset catalog image resource.
    static let doSan15 = DeveloperToolsSupport.ImageResource(name: "do-san-15", bundle: resourceBundle)

    /// The "do-san-16" asset catalog image resource.
    static let doSan16 = DeveloperToolsSupport.ImageResource(name: "do-san-16", bundle: resourceBundle)

    /// The "do-san-17" asset catalog image resource.
    static let doSan17 = DeveloperToolsSupport.ImageResource(name: "do-san-17", bundle: resourceBundle)

    /// The "do-san-18" asset catalog image resource.
    static let doSan18 = DeveloperToolsSupport.ImageResource(name: "do-san-18", bundle: resourceBundle)

    /// The "do-san-19" asset catalog image resource.
    static let doSan19 = DeveloperToolsSupport.ImageResource(name: "do-san-19", bundle: resourceBundle)

    /// The "do-san-2" asset catalog image resource.
    static let doSan2 = DeveloperToolsSupport.ImageResource(name: "do-san-2", bundle: resourceBundle)

    /// The "do-san-20" asset catalog image resource.
    static let doSan20 = DeveloperToolsSupport.ImageResource(name: "do-san-20", bundle: resourceBundle)

    /// The "do-san-21" asset catalog image resource.
    static let doSan21 = DeveloperToolsSupport.ImageResource(name: "do-san-21", bundle: resourceBundle)

    /// The "do-san-22" asset catalog image resource.
    static let doSan22 = DeveloperToolsSupport.ImageResource(name: "do-san-22", bundle: resourceBundle)

    /// The "do-san-23" asset catalog image resource.
    static let doSan23 = DeveloperToolsSupport.ImageResource(name: "do-san-23", bundle: resourceBundle)

    /// The "do-san-24" asset catalog image resource.
    static let doSan24 = DeveloperToolsSupport.ImageResource(name: "do-san-24", bundle: resourceBundle)

    /// The "do-san-3" asset catalog image resource.
    static let doSan3 = DeveloperToolsSupport.ImageResource(name: "do-san-3", bundle: resourceBundle)

    /// The "do-san-4" asset catalog image resource.
    static let doSan4 = DeveloperToolsSupport.ImageResource(name: "do-san-4", bundle: resourceBundle)

    /// The "do-san-5" asset catalog image resource.
    static let doSan5 = DeveloperToolsSupport.ImageResource(name: "do-san-5", bundle: resourceBundle)

    /// The "do-san-6" asset catalog image resource.
    static let doSan6 = DeveloperToolsSupport.ImageResource(name: "do-san-6", bundle: resourceBundle)

    /// The "do-san-7" asset catalog image resource.
    static let doSan7 = DeveloperToolsSupport.ImageResource(name: "do-san-7", bundle: resourceBundle)

    /// The "do-san-8" asset catalog image resource.
    static let doSan8 = DeveloperToolsSupport.ImageResource(name: "do-san-8", bundle: resourceBundle)

    /// The "do-san-9" asset catalog image resource.
    static let doSan9 = DeveloperToolsSupport.ImageResource(name: "do-san-9", bundle: resourceBundle)

    /// The "do-san-diagram" asset catalog image resource.
    static let doSanDiagram = DeveloperToolsSupport.ImageResource(name: "do-san-diagram", bundle: resourceBundle)

    /// The "do-san-starting" asset catalog image resource.
    static let doSanStarting = DeveloperToolsSupport.ImageResource(name: "do-san-starting", bundle: resourceBundle)

    /// The "image-coming-soon" asset catalog image resource.
    static let imageComingSoon = DeveloperToolsSupport.ImageResource(name: "image-coming-soon", bundle: resourceBundle)

    /// The "launch-logo" asset catalog image resource.
    static let launchLogo = DeveloperToolsSupport.ImageResource(name: "launch-logo", bundle: resourceBundle)

    /// The "won-hyo-1" asset catalog image resource.
    static let wonHyo1 = DeveloperToolsSupport.ImageResource(name: "won-hyo-1", bundle: resourceBundle)

    /// The "won-hyo-10" asset catalog image resource.
    static let wonHyo10 = DeveloperToolsSupport.ImageResource(name: "won-hyo-10", bundle: resourceBundle)

    /// The "won-hyo-11" asset catalog image resource.
    static let wonHyo11 = DeveloperToolsSupport.ImageResource(name: "won-hyo-11", bundle: resourceBundle)

    /// The "won-hyo-12" asset catalog image resource.
    static let wonHyo12 = DeveloperToolsSupport.ImageResource(name: "won-hyo-12", bundle: resourceBundle)

    /// The "won-hyo-13" asset catalog image resource.
    static let wonHyo13 = DeveloperToolsSupport.ImageResource(name: "won-hyo-13", bundle: resourceBundle)

    /// The "won-hyo-14" asset catalog image resource.
    static let wonHyo14 = DeveloperToolsSupport.ImageResource(name: "won-hyo-14", bundle: resourceBundle)

    /// The "won-hyo-15" asset catalog image resource.
    static let wonHyo15 = DeveloperToolsSupport.ImageResource(name: "won-hyo-15", bundle: resourceBundle)

    /// The "won-hyo-16" asset catalog image resource.
    static let wonHyo16 = DeveloperToolsSupport.ImageResource(name: "won-hyo-16", bundle: resourceBundle)

    /// The "won-hyo-17" asset catalog image resource.
    static let wonHyo17 = DeveloperToolsSupport.ImageResource(name: "won-hyo-17", bundle: resourceBundle)

    /// The "won-hyo-18" asset catalog image resource.
    static let wonHyo18 = DeveloperToolsSupport.ImageResource(name: "won-hyo-18", bundle: resourceBundle)

    /// The "won-hyo-19" asset catalog image resource.
    static let wonHyo19 = DeveloperToolsSupport.ImageResource(name: "won-hyo-19", bundle: resourceBundle)

    /// The "won-hyo-2" asset catalog image resource.
    static let wonHyo2 = DeveloperToolsSupport.ImageResource(name: "won-hyo-2", bundle: resourceBundle)

    /// The "won-hyo-20" asset catalog image resource.
    static let wonHyo20 = DeveloperToolsSupport.ImageResource(name: "won-hyo-20", bundle: resourceBundle)

    /// The "won-hyo-21" asset catalog image resource.
    static let wonHyo21 = DeveloperToolsSupport.ImageResource(name: "won-hyo-21", bundle: resourceBundle)

    /// The "won-hyo-22" asset catalog image resource.
    static let wonHyo22 = DeveloperToolsSupport.ImageResource(name: "won-hyo-22", bundle: resourceBundle)

    /// The "won-hyo-23" asset catalog image resource.
    static let wonHyo23 = DeveloperToolsSupport.ImageResource(name: "won-hyo-23", bundle: resourceBundle)

    /// The "won-hyo-24" asset catalog image resource.
    static let wonHyo24 = DeveloperToolsSupport.ImageResource(name: "won-hyo-24", bundle: resourceBundle)

    /// The "won-hyo-25" asset catalog image resource.
    static let wonHyo25 = DeveloperToolsSupport.ImageResource(name: "won-hyo-25", bundle: resourceBundle)

    /// The "won-hyo-26" asset catalog image resource.
    static let wonHyo26 = DeveloperToolsSupport.ImageResource(name: "won-hyo-26", bundle: resourceBundle)

    /// The "won-hyo-27" asset catalog image resource.
    static let wonHyo27 = DeveloperToolsSupport.ImageResource(name: "won-hyo-27", bundle: resourceBundle)

    /// The "won-hyo-28" asset catalog image resource.
    static let wonHyo28 = DeveloperToolsSupport.ImageResource(name: "won-hyo-28", bundle: resourceBundle)

    /// The "won-hyo-3" asset catalog image resource.
    static let wonHyo3 = DeveloperToolsSupport.ImageResource(name: "won-hyo-3", bundle: resourceBundle)

    /// The "won-hyo-4" asset catalog image resource.
    static let wonHyo4 = DeveloperToolsSupport.ImageResource(name: "won-hyo-4", bundle: resourceBundle)

    /// The "won-hyo-5" asset catalog image resource.
    static let wonHyo5 = DeveloperToolsSupport.ImageResource(name: "won-hyo-5", bundle: resourceBundle)

    /// The "won-hyo-6" asset catalog image resource.
    static let wonHyo6 = DeveloperToolsSupport.ImageResource(name: "won-hyo-6", bundle: resourceBundle)

    /// The "won-hyo-7" asset catalog image resource.
    static let wonHyo7 = DeveloperToolsSupport.ImageResource(name: "won-hyo-7", bundle: resourceBundle)

    /// The "won-hyo-8" asset catalog image resource.
    static let wonHyo8 = DeveloperToolsSupport.ImageResource(name: "won-hyo-8", bundle: resourceBundle)

    /// The "won-hyo-9" asset catalog image resource.
    static let wonHyo9 = DeveloperToolsSupport.ImageResource(name: "won-hyo-9", bundle: resourceBundle)

    /// The "won-hyo-diagram" asset catalog image resource.
    static let wonHyoDiagram = DeveloperToolsSupport.ImageResource(name: "won-hyo-diagram", bundle: resourceBundle)

    /// The "won-hyo-starting" asset catalog image resource.
    static let wonHyoStarting = DeveloperToolsSupport.ImageResource(name: "won-hyo-starting", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "chon-ji-1" asset catalog image.
    static var chonJi1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi1)
#else
        .init()
#endif
    }

    /// The "chon-ji-10" asset catalog image.
    static var chonJi10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi10)
#else
        .init()
#endif
    }

    /// The "chon-ji-11" asset catalog image.
    static var chonJi11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi11)
#else
        .init()
#endif
    }

    /// The "chon-ji-12" asset catalog image.
    static var chonJi12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi12)
#else
        .init()
#endif
    }

    /// The "chon-ji-13" asset catalog image.
    static var chonJi13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi13)
#else
        .init()
#endif
    }

    /// The "chon-ji-14" asset catalog image.
    static var chonJi14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi14)
#else
        .init()
#endif
    }

    /// The "chon-ji-15" asset catalog image.
    static var chonJi15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi15)
#else
        .init()
#endif
    }

    /// The "chon-ji-16" asset catalog image.
    static var chonJi16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi16)
#else
        .init()
#endif
    }

    /// The "chon-ji-17" asset catalog image.
    static var chonJi17: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi17)
#else
        .init()
#endif
    }

    /// The "chon-ji-18" asset catalog image.
    static var chonJi18: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi18)
#else
        .init()
#endif
    }

    /// The "chon-ji-19" asset catalog image.
    static var chonJi19: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi19)
#else
        .init()
#endif
    }

    /// The "chon-ji-2" asset catalog image.
    static var chonJi2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi2)
#else
        .init()
#endif
    }

    /// The "chon-ji-3" asset catalog image.
    static var chonJi3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi3)
#else
        .init()
#endif
    }

    /// The "chon-ji-4" asset catalog image.
    static var chonJi4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi4)
#else
        .init()
#endif
    }

    /// The "chon-ji-5" asset catalog image.
    static var chonJi5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi5)
#else
        .init()
#endif
    }

    /// The "chon-ji-6" asset catalog image.
    static var chonJi6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi6)
#else
        .init()
#endif
    }

    /// The "chon-ji-7" asset catalog image.
    static var chonJi7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi7)
#else
        .init()
#endif
    }

    /// The "chon-ji-8" asset catalog image.
    static var chonJi8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi8)
#else
        .init()
#endif
    }

    /// The "chon-ji-9" asset catalog image.
    static var chonJi9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJi9)
#else
        .init()
#endif
    }

    /// The "chon-ji-diagram" asset catalog image.
    static var chonJiDiagram: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJiDiagram)
#else
        .init()
#endif
    }

    /// The "chon-ji-starting" asset catalog image.
    static var chonJiStarting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chonJiStarting)
#else
        .init()
#endif
    }

    /// The "dan-gun-1" asset catalog image.
    static var danGun1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun1)
#else
        .init()
#endif
    }

    /// The "dan-gun-10" asset catalog image.
    static var danGun10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun10)
#else
        .init()
#endif
    }

    /// The "dan-gun-11" asset catalog image.
    static var danGun11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun11)
#else
        .init()
#endif
    }

    /// The "dan-gun-12" asset catalog image.
    static var danGun12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun12)
#else
        .init()
#endif
    }

    /// The "dan-gun-13" asset catalog image.
    static var danGun13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun13)
#else
        .init()
#endif
    }

    /// The "dan-gun-14" asset catalog image.
    static var danGun14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun14)
#else
        .init()
#endif
    }

    /// The "dan-gun-15" asset catalog image.
    static var danGun15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun15)
#else
        .init()
#endif
    }

    /// The "dan-gun-16" asset catalog image.
    static var danGun16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun16)
#else
        .init()
#endif
    }

    /// The "dan-gun-17" asset catalog image.
    static var danGun17: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun17)
#else
        .init()
#endif
    }

    /// The "dan-gun-18" asset catalog image.
    static var danGun18: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun18)
#else
        .init()
#endif
    }

    /// The "dan-gun-19" asset catalog image.
    static var danGun19: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun19)
#else
        .init()
#endif
    }

    /// The "dan-gun-2" asset catalog image.
    static var danGun2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun2)
#else
        .init()
#endif
    }

    /// The "dan-gun-20" asset catalog image.
    static var danGun20: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun20)
#else
        .init()
#endif
    }

    /// The "dan-gun-21" asset catalog image.
    static var danGun21: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun21)
#else
        .init()
#endif
    }

    /// The "dan-gun-3" asset catalog image.
    static var danGun3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun3)
#else
        .init()
#endif
    }

    /// The "dan-gun-4" asset catalog image.
    static var danGun4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun4)
#else
        .init()
#endif
    }

    /// The "dan-gun-5" asset catalog image.
    static var danGun5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun5)
#else
        .init()
#endif
    }

    /// The "dan-gun-6" asset catalog image.
    static var danGun6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun6)
#else
        .init()
#endif
    }

    /// The "dan-gun-7" asset catalog image.
    static var danGun7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun7)
#else
        .init()
#endif
    }

    /// The "dan-gun-8" asset catalog image.
    static var danGun8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun8)
#else
        .init()
#endif
    }

    /// The "dan-gun-9" asset catalog image.
    static var danGun9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGun9)
#else
        .init()
#endif
    }

    /// The "dan-gun-diagram" asset catalog image.
    static var danGunDiagram: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGunDiagram)
#else
        .init()
#endif
    }

    /// The "dan-gun-starting" asset catalog image.
    static var danGunStarting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .danGunStarting)
#else
        .init()
#endif
    }

    /// The "do-san-1" asset catalog image.
    static var doSan1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan1)
#else
        .init()
#endif
    }

    /// The "do-san-10" asset catalog image.
    static var doSan10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan10)
#else
        .init()
#endif
    }

    /// The "do-san-11" asset catalog image.
    static var doSan11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan11)
#else
        .init()
#endif
    }

    /// The "do-san-12" asset catalog image.
    static var doSan12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan12)
#else
        .init()
#endif
    }

    /// The "do-san-13" asset catalog image.
    static var doSan13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan13)
#else
        .init()
#endif
    }

    /// The "do-san-14" asset catalog image.
    static var doSan14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan14)
#else
        .init()
#endif
    }

    /// The "do-san-15" asset catalog image.
    static var doSan15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan15)
#else
        .init()
#endif
    }

    /// The "do-san-16" asset catalog image.
    static var doSan16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan16)
#else
        .init()
#endif
    }

    /// The "do-san-17" asset catalog image.
    static var doSan17: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan17)
#else
        .init()
#endif
    }

    /// The "do-san-18" asset catalog image.
    static var doSan18: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan18)
#else
        .init()
#endif
    }

    /// The "do-san-19" asset catalog image.
    static var doSan19: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan19)
#else
        .init()
#endif
    }

    /// The "do-san-2" asset catalog image.
    static var doSan2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan2)
#else
        .init()
#endif
    }

    /// The "do-san-20" asset catalog image.
    static var doSan20: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan20)
#else
        .init()
#endif
    }

    /// The "do-san-21" asset catalog image.
    static var doSan21: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan21)
#else
        .init()
#endif
    }

    /// The "do-san-22" asset catalog image.
    static var doSan22: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan22)
#else
        .init()
#endif
    }

    /// The "do-san-23" asset catalog image.
    static var doSan23: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan23)
#else
        .init()
#endif
    }

    /// The "do-san-24" asset catalog image.
    static var doSan24: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan24)
#else
        .init()
#endif
    }

    /// The "do-san-3" asset catalog image.
    static var doSan3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan3)
#else
        .init()
#endif
    }

    /// The "do-san-4" asset catalog image.
    static var doSan4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan4)
#else
        .init()
#endif
    }

    /// The "do-san-5" asset catalog image.
    static var doSan5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan5)
#else
        .init()
#endif
    }

    /// The "do-san-6" asset catalog image.
    static var doSan6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan6)
#else
        .init()
#endif
    }

    /// The "do-san-7" asset catalog image.
    static var doSan7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan7)
#else
        .init()
#endif
    }

    /// The "do-san-8" asset catalog image.
    static var doSan8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan8)
#else
        .init()
#endif
    }

    /// The "do-san-9" asset catalog image.
    static var doSan9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSan9)
#else
        .init()
#endif
    }

    /// The "do-san-diagram" asset catalog image.
    static var doSanDiagram: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSanDiagram)
#else
        .init()
#endif
    }

    /// The "do-san-starting" asset catalog image.
    static var doSanStarting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .doSanStarting)
#else
        .init()
#endif
    }

    /// The "image-coming-soon" asset catalog image.
    static var imageComingSoon: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .imageComingSoon)
#else
        .init()
#endif
    }

    /// The "launch-logo" asset catalog image.
    static var launchLogo: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .launchLogo)
#else
        .init()
#endif
    }

    /// The "won-hyo-1" asset catalog image.
    static var wonHyo1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo1)
#else
        .init()
#endif
    }

    /// The "won-hyo-10" asset catalog image.
    static var wonHyo10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo10)
#else
        .init()
#endif
    }

    /// The "won-hyo-11" asset catalog image.
    static var wonHyo11: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo11)
#else
        .init()
#endif
    }

    /// The "won-hyo-12" asset catalog image.
    static var wonHyo12: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo12)
#else
        .init()
#endif
    }

    /// The "won-hyo-13" asset catalog image.
    static var wonHyo13: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo13)
#else
        .init()
#endif
    }

    /// The "won-hyo-14" asset catalog image.
    static var wonHyo14: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo14)
#else
        .init()
#endif
    }

    /// The "won-hyo-15" asset catalog image.
    static var wonHyo15: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo15)
#else
        .init()
#endif
    }

    /// The "won-hyo-16" asset catalog image.
    static var wonHyo16: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo16)
#else
        .init()
#endif
    }

    /// The "won-hyo-17" asset catalog image.
    static var wonHyo17: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo17)
#else
        .init()
#endif
    }

    /// The "won-hyo-18" asset catalog image.
    static var wonHyo18: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo18)
#else
        .init()
#endif
    }

    /// The "won-hyo-19" asset catalog image.
    static var wonHyo19: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo19)
#else
        .init()
#endif
    }

    /// The "won-hyo-2" asset catalog image.
    static var wonHyo2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo2)
#else
        .init()
#endif
    }

    /// The "won-hyo-20" asset catalog image.
    static var wonHyo20: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo20)
#else
        .init()
#endif
    }

    /// The "won-hyo-21" asset catalog image.
    static var wonHyo21: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo21)
#else
        .init()
#endif
    }

    /// The "won-hyo-22" asset catalog image.
    static var wonHyo22: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo22)
#else
        .init()
#endif
    }

    /// The "won-hyo-23" asset catalog image.
    static var wonHyo23: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo23)
#else
        .init()
#endif
    }

    /// The "won-hyo-24" asset catalog image.
    static var wonHyo24: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo24)
#else
        .init()
#endif
    }

    /// The "won-hyo-25" asset catalog image.
    static var wonHyo25: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo25)
#else
        .init()
#endif
    }

    /// The "won-hyo-26" asset catalog image.
    static var wonHyo26: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo26)
#else
        .init()
#endif
    }

    /// The "won-hyo-27" asset catalog image.
    static var wonHyo27: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo27)
#else
        .init()
#endif
    }

    /// The "won-hyo-28" asset catalog image.
    static var wonHyo28: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo28)
#else
        .init()
#endif
    }

    /// The "won-hyo-3" asset catalog image.
    static var wonHyo3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo3)
#else
        .init()
#endif
    }

    /// The "won-hyo-4" asset catalog image.
    static var wonHyo4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo4)
#else
        .init()
#endif
    }

    /// The "won-hyo-5" asset catalog image.
    static var wonHyo5: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo5)
#else
        .init()
#endif
    }

    /// The "won-hyo-6" asset catalog image.
    static var wonHyo6: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo6)
#else
        .init()
#endif
    }

    /// The "won-hyo-7" asset catalog image.
    static var wonHyo7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo7)
#else
        .init()
#endif
    }

    /// The "won-hyo-8" asset catalog image.
    static var wonHyo8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo8)
#else
        .init()
#endif
    }

    /// The "won-hyo-9" asset catalog image.
    static var wonHyo9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyo9)
#else
        .init()
#endif
    }

    /// The "won-hyo-diagram" asset catalog image.
    static var wonHyoDiagram: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyoDiagram)
#else
        .init()
#endif
    }

    /// The "won-hyo-starting" asset catalog image.
    static var wonHyoStarting: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .wonHyoStarting)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "chon-ji-1" asset catalog image.
    static var chonJi1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi1)
#else
        .init()
#endif
    }

    /// The "chon-ji-10" asset catalog image.
    static var chonJi10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi10)
#else
        .init()
#endif
    }

    /// The "chon-ji-11" asset catalog image.
    static var chonJi11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi11)
#else
        .init()
#endif
    }

    /// The "chon-ji-12" asset catalog image.
    static var chonJi12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi12)
#else
        .init()
#endif
    }

    /// The "chon-ji-13" asset catalog image.
    static var chonJi13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi13)
#else
        .init()
#endif
    }

    /// The "chon-ji-14" asset catalog image.
    static var chonJi14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi14)
#else
        .init()
#endif
    }

    /// The "chon-ji-15" asset catalog image.
    static var chonJi15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi15)
#else
        .init()
#endif
    }

    /// The "chon-ji-16" asset catalog image.
    static var chonJi16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi16)
#else
        .init()
#endif
    }

    /// The "chon-ji-17" asset catalog image.
    static var chonJi17: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi17)
#else
        .init()
#endif
    }

    /// The "chon-ji-18" asset catalog image.
    static var chonJi18: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi18)
#else
        .init()
#endif
    }

    /// The "chon-ji-19" asset catalog image.
    static var chonJi19: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi19)
#else
        .init()
#endif
    }

    /// The "chon-ji-2" asset catalog image.
    static var chonJi2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi2)
#else
        .init()
#endif
    }

    /// The "chon-ji-3" asset catalog image.
    static var chonJi3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi3)
#else
        .init()
#endif
    }

    /// The "chon-ji-4" asset catalog image.
    static var chonJi4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi4)
#else
        .init()
#endif
    }

    /// The "chon-ji-5" asset catalog image.
    static var chonJi5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi5)
#else
        .init()
#endif
    }

    /// The "chon-ji-6" asset catalog image.
    static var chonJi6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi6)
#else
        .init()
#endif
    }

    /// The "chon-ji-7" asset catalog image.
    static var chonJi7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi7)
#else
        .init()
#endif
    }

    /// The "chon-ji-8" asset catalog image.
    static var chonJi8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi8)
#else
        .init()
#endif
    }

    /// The "chon-ji-9" asset catalog image.
    static var chonJi9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJi9)
#else
        .init()
#endif
    }

    /// The "chon-ji-diagram" asset catalog image.
    static var chonJiDiagram: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJiDiagram)
#else
        .init()
#endif
    }

    /// The "chon-ji-starting" asset catalog image.
    static var chonJiStarting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chonJiStarting)
#else
        .init()
#endif
    }

    /// The "dan-gun-1" asset catalog image.
    static var danGun1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun1)
#else
        .init()
#endif
    }

    /// The "dan-gun-10" asset catalog image.
    static var danGun10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun10)
#else
        .init()
#endif
    }

    /// The "dan-gun-11" asset catalog image.
    static var danGun11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun11)
#else
        .init()
#endif
    }

    /// The "dan-gun-12" asset catalog image.
    static var danGun12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun12)
#else
        .init()
#endif
    }

    /// The "dan-gun-13" asset catalog image.
    static var danGun13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun13)
#else
        .init()
#endif
    }

    /// The "dan-gun-14" asset catalog image.
    static var danGun14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun14)
#else
        .init()
#endif
    }

    /// The "dan-gun-15" asset catalog image.
    static var danGun15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun15)
#else
        .init()
#endif
    }

    /// The "dan-gun-16" asset catalog image.
    static var danGun16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun16)
#else
        .init()
#endif
    }

    /// The "dan-gun-17" asset catalog image.
    static var danGun17: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun17)
#else
        .init()
#endif
    }

    /// The "dan-gun-18" asset catalog image.
    static var danGun18: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun18)
#else
        .init()
#endif
    }

    /// The "dan-gun-19" asset catalog image.
    static var danGun19: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun19)
#else
        .init()
#endif
    }

    /// The "dan-gun-2" asset catalog image.
    static var danGun2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun2)
#else
        .init()
#endif
    }

    /// The "dan-gun-20" asset catalog image.
    static var danGun20: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun20)
#else
        .init()
#endif
    }

    /// The "dan-gun-21" asset catalog image.
    static var danGun21: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun21)
#else
        .init()
#endif
    }

    /// The "dan-gun-3" asset catalog image.
    static var danGun3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun3)
#else
        .init()
#endif
    }

    /// The "dan-gun-4" asset catalog image.
    static var danGun4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun4)
#else
        .init()
#endif
    }

    /// The "dan-gun-5" asset catalog image.
    static var danGun5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun5)
#else
        .init()
#endif
    }

    /// The "dan-gun-6" asset catalog image.
    static var danGun6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun6)
#else
        .init()
#endif
    }

    /// The "dan-gun-7" asset catalog image.
    static var danGun7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun7)
#else
        .init()
#endif
    }

    /// The "dan-gun-8" asset catalog image.
    static var danGun8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun8)
#else
        .init()
#endif
    }

    /// The "dan-gun-9" asset catalog image.
    static var danGun9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGun9)
#else
        .init()
#endif
    }

    /// The "dan-gun-diagram" asset catalog image.
    static var danGunDiagram: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGunDiagram)
#else
        .init()
#endif
    }

    /// The "dan-gun-starting" asset catalog image.
    static var danGunStarting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .danGunStarting)
#else
        .init()
#endif
    }

    /// The "do-san-1" asset catalog image.
    static var doSan1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan1)
#else
        .init()
#endif
    }

    /// The "do-san-10" asset catalog image.
    static var doSan10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan10)
#else
        .init()
#endif
    }

    /// The "do-san-11" asset catalog image.
    static var doSan11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan11)
#else
        .init()
#endif
    }

    /// The "do-san-12" asset catalog image.
    static var doSan12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan12)
#else
        .init()
#endif
    }

    /// The "do-san-13" asset catalog image.
    static var doSan13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan13)
#else
        .init()
#endif
    }

    /// The "do-san-14" asset catalog image.
    static var doSan14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan14)
#else
        .init()
#endif
    }

    /// The "do-san-15" asset catalog image.
    static var doSan15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan15)
#else
        .init()
#endif
    }

    /// The "do-san-16" asset catalog image.
    static var doSan16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan16)
#else
        .init()
#endif
    }

    /// The "do-san-17" asset catalog image.
    static var doSan17: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan17)
#else
        .init()
#endif
    }

    /// The "do-san-18" asset catalog image.
    static var doSan18: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan18)
#else
        .init()
#endif
    }

    /// The "do-san-19" asset catalog image.
    static var doSan19: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan19)
#else
        .init()
#endif
    }

    /// The "do-san-2" asset catalog image.
    static var doSan2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan2)
#else
        .init()
#endif
    }

    /// The "do-san-20" asset catalog image.
    static var doSan20: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan20)
#else
        .init()
#endif
    }

    /// The "do-san-21" asset catalog image.
    static var doSan21: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan21)
#else
        .init()
#endif
    }

    /// The "do-san-22" asset catalog image.
    static var doSan22: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan22)
#else
        .init()
#endif
    }

    /// The "do-san-23" asset catalog image.
    static var doSan23: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan23)
#else
        .init()
#endif
    }

    /// The "do-san-24" asset catalog image.
    static var doSan24: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan24)
#else
        .init()
#endif
    }

    /// The "do-san-3" asset catalog image.
    static var doSan3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan3)
#else
        .init()
#endif
    }

    /// The "do-san-4" asset catalog image.
    static var doSan4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan4)
#else
        .init()
#endif
    }

    /// The "do-san-5" asset catalog image.
    static var doSan5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan5)
#else
        .init()
#endif
    }

    /// The "do-san-6" asset catalog image.
    static var doSan6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan6)
#else
        .init()
#endif
    }

    /// The "do-san-7" asset catalog image.
    static var doSan7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan7)
#else
        .init()
#endif
    }

    /// The "do-san-8" asset catalog image.
    static var doSan8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan8)
#else
        .init()
#endif
    }

    /// The "do-san-9" asset catalog image.
    static var doSan9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSan9)
#else
        .init()
#endif
    }

    /// The "do-san-diagram" asset catalog image.
    static var doSanDiagram: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSanDiagram)
#else
        .init()
#endif
    }

    /// The "do-san-starting" asset catalog image.
    static var doSanStarting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .doSanStarting)
#else
        .init()
#endif
    }

    /// The "image-coming-soon" asset catalog image.
    static var imageComingSoon: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .imageComingSoon)
#else
        .init()
#endif
    }

    /// The "launch-logo" asset catalog image.
    static var launchLogo: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .launchLogo)
#else
        .init()
#endif
    }

    /// The "won-hyo-1" asset catalog image.
    static var wonHyo1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo1)
#else
        .init()
#endif
    }

    /// The "won-hyo-10" asset catalog image.
    static var wonHyo10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo10)
#else
        .init()
#endif
    }

    /// The "won-hyo-11" asset catalog image.
    static var wonHyo11: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo11)
#else
        .init()
#endif
    }

    /// The "won-hyo-12" asset catalog image.
    static var wonHyo12: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo12)
#else
        .init()
#endif
    }

    /// The "won-hyo-13" asset catalog image.
    static var wonHyo13: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo13)
#else
        .init()
#endif
    }

    /// The "won-hyo-14" asset catalog image.
    static var wonHyo14: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo14)
#else
        .init()
#endif
    }

    /// The "won-hyo-15" asset catalog image.
    static var wonHyo15: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo15)
#else
        .init()
#endif
    }

    /// The "won-hyo-16" asset catalog image.
    static var wonHyo16: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo16)
#else
        .init()
#endif
    }

    /// The "won-hyo-17" asset catalog image.
    static var wonHyo17: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo17)
#else
        .init()
#endif
    }

    /// The "won-hyo-18" asset catalog image.
    static var wonHyo18: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo18)
#else
        .init()
#endif
    }

    /// The "won-hyo-19" asset catalog image.
    static var wonHyo19: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo19)
#else
        .init()
#endif
    }

    /// The "won-hyo-2" asset catalog image.
    static var wonHyo2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo2)
#else
        .init()
#endif
    }

    /// The "won-hyo-20" asset catalog image.
    static var wonHyo20: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo20)
#else
        .init()
#endif
    }

    /// The "won-hyo-21" asset catalog image.
    static var wonHyo21: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo21)
#else
        .init()
#endif
    }

    /// The "won-hyo-22" asset catalog image.
    static var wonHyo22: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo22)
#else
        .init()
#endif
    }

    /// The "won-hyo-23" asset catalog image.
    static var wonHyo23: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo23)
#else
        .init()
#endif
    }

    /// The "won-hyo-24" asset catalog image.
    static var wonHyo24: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo24)
#else
        .init()
#endif
    }

    /// The "won-hyo-25" asset catalog image.
    static var wonHyo25: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo25)
#else
        .init()
#endif
    }

    /// The "won-hyo-26" asset catalog image.
    static var wonHyo26: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo26)
#else
        .init()
#endif
    }

    /// The "won-hyo-27" asset catalog image.
    static var wonHyo27: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo27)
#else
        .init()
#endif
    }

    /// The "won-hyo-28" asset catalog image.
    static var wonHyo28: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo28)
#else
        .init()
#endif
    }

    /// The "won-hyo-3" asset catalog image.
    static var wonHyo3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo3)
#else
        .init()
#endif
    }

    /// The "won-hyo-4" asset catalog image.
    static var wonHyo4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo4)
#else
        .init()
#endif
    }

    /// The "won-hyo-5" asset catalog image.
    static var wonHyo5: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo5)
#else
        .init()
#endif
    }

    /// The "won-hyo-6" asset catalog image.
    static var wonHyo6: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo6)
#else
        .init()
#endif
    }

    /// The "won-hyo-7" asset catalog image.
    static var wonHyo7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo7)
#else
        .init()
#endif
    }

    /// The "won-hyo-8" asset catalog image.
    static var wonHyo8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo8)
#else
        .init()
#endif
    }

    /// The "won-hyo-9" asset catalog image.
    static var wonHyo9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyo9)
#else
        .init()
#endif
    }

    /// The "won-hyo-diagram" asset catalog image.
    static var wonHyoDiagram: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyoDiagram)
#else
        .init()
#endif
    }

    /// The "won-hyo-starting" asset catalog image.
    static var wonHyoStarting: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .wonHyoStarting)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

