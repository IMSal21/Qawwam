import CoreText
import SwiftUI

/// The mockup's colors and fonts.
enum Theme {
    static let ground = Color(hex: 0xF3F1EA)
    static let surface = Color.white
    static let ink = Color(hex: 0x15302A)
    static let muted = Color(hex: 0x56635E)
    static let palm = Color(hex: 0x1E6B4E)
    static let gold = Color(hex: 0x9A6A12)
    static let goldText = Color(hex: 0x7A520B)
    static let goldSoft = Color(hex: 0xF6ECD6)
    static let late = Color(hex: 0x8A5300)
    static let lateSoft = Color(hex: 0xFBEBD2)
    static let lateRing = Color(hex: 0xE0A030)
    static let missed = Color(hex: 0x9B3B2C)
    static let missedSoft = Color(hex: 0xF5E1DD)
    static let onTimeSoft = Color(hex: 0xE3EFE8)
    static let dueRing = Color(hex: 0xA9CDBB)
    static let line = Color(hex: 0xE2DED3)
    static let upcomingSoft = Color(hex: 0xECE9E1)
    static let upcomingRow = Color(hex: 0xF8F7F2)

    enum Weight { case regular, medium, semibold, bold }

    /// IBM Plex Sans Arabic, which also covers English.
    static func text(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        let name =
            switch weight {
            case .regular: "IBMPlexSansArabic-Regular"
            case .medium: "IBMPlexSansArabic-Medium"
            case .semibold: "IBMPlexSansArabic-SemiBold"
            case .bold: "IBMPlexSansArabic-Bold"
            }
        return .custom(name, size: size)
    }

    /// Reem Kufi for headings and prayer names.
    static func heading(_ size: CGFloat) -> Font {
        .custom("ReemKufi", size: size).weight(.semibold)
    }

    /// Registers the bundled fonts once at launch.
    static func registerFonts() {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255)
    }
}
