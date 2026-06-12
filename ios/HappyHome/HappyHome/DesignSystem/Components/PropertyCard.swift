import SwiftUI

/// Hero card used in carousels and grids: image, prominent price,
/// layout · size · age row, station + walk time, favorite heart, featured badge.
struct PropertyCard: View {
    let property: Property
    let isFavorite: Bool
    let onFavorite: () -> Void
    var width: CGFloat? = nil

    @EnvironmentObject private var compareStore: CompareStore

    private var specsLine: String {
        [property.layout, property.sizeLabel, property.ageLabel]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ZStack(alignment: .topLeading) {
                CachedAsyncImage(url: property.thumbnailURL)
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))

                HStack {
                    if property.featured {
                        Badge(
                            text: NSLocalizedString("property.featured", comment: ""),
                            style: .featured,
                            systemImage: "star.fill"
                        )
                    }
                    Spacer()
                    favoriteButton
                }
                .padding(Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(property.priceLabel)
                        .font(.appPrice)
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Badge(text: property.transactionType.displayName, style: .neutral)
                }

                Text(property.displayTitle)
                    .font(.appSubheadline.weight(.medium))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)

                if !specsLine.isEmpty {
                    Text(specsLine)
                        .font(.appFootnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                }

                if let station = property.displayStation {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "tram.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.appAccent)
                        Text(walkLine(station: station))
                            .font(.appFootnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.bottom, Spacing.xs)
        }
        .padding(Spacing.sm)
        .frame(width: width)
        .cardStyle()
        .contextMenu {
            Button {
                compareStore.toggle(property)
            } label: {
                Label(
                    compareStore.contains(property)
                        ? NSLocalizedString("compare.remove", comment: "")
                        : NSLocalizedString("compare.add", comment: ""),
                    systemImage: "square.split.2x1"
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(property.displayTitle), \(property.priceLabel)")
    }

    private var favoriteButton: some View {
        Button(action: onFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isFavorite ? Color.appDanger : Color.white)
                .padding(8)
                .background(.ultraThinMaterial, in: Circle())
                .scaleEffect(isFavorite ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3), value: isFavorite)
        .accessibilityLabel(
            isFavorite
                ? NSLocalizedString("a11y.favorite.remove", comment: "")
                : NSLocalizedString("a11y.favorite.add", comment: "")
        )
    }

    private func walkLine(station: String) -> String {
        if let walk = property.walkLabel {
            return "\(station) \(walk)"
        }
        return station
    }
}
