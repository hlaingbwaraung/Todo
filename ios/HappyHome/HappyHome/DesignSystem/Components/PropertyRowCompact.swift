import SwiftUI

/// Compact horizontal row used in search results and favorites lists.
struct PropertyRowCompact: View {
    let property: Property
    let isFavorite: Bool
    let onFavorite: () -> Void

    private var specsLine: String {
        [property.layout, property.sizeLabel, property.ageLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: property.thumbnailURL)
                    .frame(width: 110, height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
                if property.featured {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.appAccent)
                        .padding(5)
                        .background(.ultraThinMaterial, in: Circle())
                        .padding(4)
                        .accessibilityLabel(NSLocalizedString("property.featured", comment: ""))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(property.priceLabel)
                    .font(.appPrice)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(property.displayTitle)
                    .font(.appSubheadline.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                if !specsLine.isEmpty {
                    Text(specsLine)
                        .font(.appFootnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }
                if let station = property.displayStation {
                    Text(property.walkLabel.map { "\(station) \($0)" } ?? station)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFavorite ? Color.appDanger : Color.appTextSecondary)
            }
            .buttonStyle(.plain)
            .animation(.spring(duration: 0.3), value: isFavorite)
            .accessibilityLabel(
                isFavorite
                    ? NSLocalizedString("a11y.favorite.remove", comment: "")
                    : NSLocalizedString("a11y.favorite.add", comment: "")
            )
        }
        .padding(Spacing.sm)
        .cardStyle(cornerRadius: Radii.card)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.displayTitle), \(property.priceLabel)")
    }
}
