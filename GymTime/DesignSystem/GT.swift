import SwiftUI

// GymTime design tokens — ported from lib/tokens.jsx.
// Dark mode. Acid lime accent. Mono for numbers.
enum GT {
    // Grounds
    static let bg       = Color(red: 0x0A/255, green: 0x0B/255, blue: 0x0D/255)
    static let surface  = Color(red: 0x14/255, green: 0x16/255, blue: 0x19/255)
    static let surface2 = Color(red: 0x1B/255, green: 0x1E/255, blue: 0x22/255)
    static let line     = Color.white.opacity(0.07)
    static let line2    = Color.white.opacity(0.12)

    // Ink
    static let ink      = Color(red: 0xF4/255, green: 0xF5/255, blue: 0xF2/255)
    static let ink2     = Color(red: 0xF4/255, green: 0xF5/255, blue: 0xF2/255).opacity(0.66)
    static let ink3     = Color(red: 0xF4/255, green: 0xF5/255, blue: 0xF2/255).opacity(0.38)
    static let ink4     = Color(red: 0xF4/255, green: 0xF5/255, blue: 0xF2/255).opacity(0.18)

    // Accent
    static let lime     = Color(red: 0xD8/255, green: 0xFF/255, blue: 0x3D/255)
    static let limeDim  = Color(red: 0xA8/255, green: 0xCC/255, blue: 0x2C/255)
    static let limeInk  = Color(red: 0x0A/255, green: 0x0B/255, blue: 0x0D/255)
    static let limeWash = Color(red: 0xD8/255, green: 0xFF/255, blue: 0x3D/255).opacity(0.12)
    static let limeWashSoft = Color(red: 0xD8/255, green: 0xFF/255, blue: 0x3D/255).opacity(0.08)
    static let limeEdge = Color(red: 0xD8/255, green: 0xFF/255, blue: 0x3D/255).opacity(0.22)

    // Semantic
    static let warn     = Color(red: 0xFF/255, green: 0x7A/255, blue: 0x45/255)
    static let rest     = Color(red: 0x7F/255, green: 0xE7/255, blue: 0xFF/255)

    // Radii
    static let rSm: CGFloat = 10
    static let rMd: CGFloat = 14
    static let rLg: CGFloat = 22
    static let rXl: CGFloat = 28
}

// ─── Fonts ────────────────────────────────────────────────────
extension Font {
    static func gtDisplay(_ size: CGFloat, weight: Weight = .semibold) -> Font {
        let name: String
        switch weight {
        case .regular: name = "InterTight-Regular"
        case .medium: name = "InterTight-Medium"
        case .bold, .heavy, .black: name = "InterTight-Bold"
        case .semibold: name = "InterTight-SemiBold"
        default: name = "InterTight-SemiBold"
        }
        return .custom(name, size: size)
    }

    static func gtBody(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "Inter-Medium"
        case .semibold, .bold, .heavy: name = "Inter-SemiBold"
        default: name = "Inter-Regular"
        }
        return .custom(name, size: size)
    }

    static func gtMono(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "JetBrainsMono-Medium"
        case .semibold, .bold, .heavy: name = "JetBrainsMono-SemiBold"
        default: name = "JetBrainsMono-Regular"
        }
        return .custom(name, size: size)
    }
}

// ─── Helpers ──────────────────────────────────────────────────
extension View {
    /// Mono caption: uppercase tracking label used all over the app.
    func gtMonoCaption(color: Color = GT.ink3, size: CGFloat = 11, tracking: CGFloat = 1.4) -> some View {
        self.font(.gtMono(size, weight: .medium))
            .tracking(tracking)
            .foregroundColor(color)
    }

    /// Card background: surface fill + 1px border.
    func gtCard(radius: CGFloat = GT.rLg, fill: Color = GT.surface, border: Color = GT.line) -> some View {
        self
            .background(RoundedRectangle(cornerRadius: radius).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(border, lineWidth: 1)
            )
    }
}
