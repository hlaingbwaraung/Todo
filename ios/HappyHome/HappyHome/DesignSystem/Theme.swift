import SwiftUI

// MARK: - Semantic colors (premium navy + warm gold, light/dark aware)

extension Color {
    /// Deep navy — primary brand color.
    static let appPrimary = Color(light: UIColor(hex: 0x0F2A43), dark: UIColor(hex: 0x4A7BA6))
    /// Warm gold accent.
    static let appAccent = Color(light: UIColor(hex: 0xC9A227), dark: UIColor(hex: 0xE1B84A))
    /// Screen background.
    static let appBackground = Color(light: UIColor(hex: 0xF7F5F0), dark: UIColor(hex: 0x0B1622))
    /// Card / surface background.
    static let appSurface = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x16263A))
    /// Subtle inset surface (chips, fields).
    static let appSurfaceSecondary = Color(light: UIColor(hex: 0xEFEBE2), dark: UIColor(hex: 0x1E3048))
    /// Main text.
    static let appTextPrimary = Color(light: UIColor(hex: 0x16202B), dark: UIColor(hex: 0xF2F4F7))
    /// Secondary text.
    static let appTextSecondary = Color(light: UIColor(hex: 0x5F6B78), dark: UIColor(hex: 0x9AA8B6))
    /// Hairline separators.
    static let appSeparator = Color(light: UIColor(hex: 0xE3DfD4), dark: UIColor(hex: 0x2A3C52))
    /// Success (confirmed states).
    static let appSuccess = Color(light: UIColor(hex: 0x2E7D5B), dark: UIColor(hex: 0x4CAF88))
    /// Danger (errors, destructive actions, favorite heart).
    static let appDanger = Color(light: UIColor(hex: 0xC0392B), dark: UIColor(hex: 0xE57368))
    /// Text drawn on top of appPrimary fills.
    static let appOnPrimary = Color(light: UIColor(hex: 0xFFFFFF), dark: UIColor(hex: 0x0B1622))
}

// MARK: - Spacing / radius / shadow tokens

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum Radii {
    static let chip: CGFloat = 8
    static let control: CGFloat = 12
    static let card: CGFloat = 16
    static let sheet: CGFloat = 24
}

enum AppShadow {
    struct Token {
        let color: Color
        let radius: CGFloat
        let y: CGFloat
    }

    static let card = Token(color: Color.black.opacity(0.10), radius: 10, y: 4)
    static let floating = Token(color: Color.black.opacity(0.18), radius: 16, y: 6)
}
