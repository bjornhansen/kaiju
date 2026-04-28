import SwiftUI

/// Design tokens for the Translucent Vibrancy variation.
/// Values mirror `docs/design_handoff_kaiju_vibrancy/README.md`.
enum VibrancyTokens {
    static let accent = Color(hex: 0x5E5CE6)

    enum Spacing {
        static let windowPadding: CGFloat = 10
        static let sidebarInset: CGFloat = 8
        static let columnGap: CGFloat = 10
        static let cardGap: CGFloat = 6
        static let cardPaddingX: CGFloat = 11
        static let cardPaddingY: CGFloat = 9
    }

    enum Radius {
        static let sidebar: CGFloat = 14
        static let column: CGFloat = 12
        static let card: CGFloat = 8
        static let pill: CGFloat = 8
    }

    enum Status {
        static let backlog    = Color(hex: 0x94A3B8)
        static let todo       = Color(hex: 0x64748B)
        static let inProgress = Color(hex: 0x3B82F6)
        static let inReview   = Color(hex: 0xA855F7)
        static let done       = Color(hex: 0x10B981)
    }

    enum Priority {
        static let urgent = Color(hex: 0xDC2626)
        static let high   = Color(hex: 0xEA580C)
        static let medium = Color(hex: 0xCA8A04)
        static let low    = Color(hex: 0x65A30D)
        static let none   = Color(hex: 0x6B7280)
    }

    /// Radial-gradient wallpaper that sits behind the window content.
    /// Translucent panels (sidebar, cards) pick up its color.
    static func wallpaper(for scheme: ColorScheme) -> some View {
        let stops: [Gradient.Stop] = scheme == .dark
            ? [
                .init(color: Color(hex: 0x2A3454), location: 0.00),
                .init(color: Color(hex: 0x1A1A2E), location: 0.50),
                .init(color: Color(hex: 0x0F0F1A), location: 1.00),
              ]
            : [
                .init(color: Color(hex: 0xD8E8FF), location: 0.00),
                .init(color: Color(hex: 0xEFE4FF), location: 0.50),
                .init(color: Color(hex: 0xFFE9F1), location: 1.00),
              ]
        return RadialGradient(
            gradient: Gradient(stops: stops),
            center: UnitPoint(x: 0.2, y: 0.1),
            startRadius: 0,
            endRadius: 1000
        )
        .ignoresSafeArea()
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
