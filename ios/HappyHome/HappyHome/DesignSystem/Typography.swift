import SwiftUI

/// Dynamic-Type-friendly type ramp; all fonts are based on text styles so
/// they scale with the user's settings.
extension Font {
    static let appLargeTitle = Font.system(.largeTitle, design: .default, weight: .bold)
    static let appTitle = Font.system(.title2, design: .default, weight: .bold)
    static let appSectionTitle = Font.system(.title3, design: .default, weight: .semibold)
    static let appHeadline = Font.system(.headline, design: .default, weight: .semibold)
    static let appBody = Font.system(.body, design: .default, weight: .regular)
    static let appCallout = Font.system(.callout, design: .default, weight: .regular)
    static let appSubheadline = Font.system(.subheadline, design: .default, weight: .regular)
    static let appFootnote = Font.system(.footnote, design: .default, weight: .regular)
    static let appCaption = Font.system(.caption, design: .default, weight: .regular)
    /// Prominent price display.
    static let appPrice = Font.system(.title3, design: .rounded, weight: .bold)
    static let appPriceLarge = Font.system(.title, design: .rounded, weight: .bold)
}
