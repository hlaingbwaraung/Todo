import SwiftUI

/// Small "320 views" style popularity indicator.
struct RatingOrViewsLabel: View {
    let viewCount: Int

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "eye.fill")
                .font(.caption2)
            Text(String(format: NSLocalizedString("property.views", comment: ""), viewCount))
                .font(.appCaption)
        }
        .foregroundStyle(Color.appTextSecondary)
        .accessibilityLabel(String(format: NSLocalizedString("property.views", comment: ""), viewCount))
    }
}
