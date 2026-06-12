import SwiftUI
import MapKit

/// Map of results with price-pill markers; tapping a pill shows a bottom card.
struct PropertyMapView: View {
    let properties: [Property]

    @EnvironmentObject private var appState: AppState
    @State private var cameraPosition: MapCameraPosition
    @State private var selected: Property?

    private static let tokyo = CLLocationCoordinate2D(latitude: 35.68, longitude: 139.76)

    init(properties: [Property]) {
        self.properties = properties
        let center = properties.compactMap(\.coordinate).first ?? Self.tokyo
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
        _cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(properties.filter { $0.coordinate != nil }) { property in
                    Annotation(property.displayTitle, coordinate: property.coordinate ?? Self.tokyo) {
                        pricePill(for: property)
                    }
                    .annotationTitles(.hidden)
                }
            }
            .mapStyle(.standard)

            if let selected {
                NavigationLink(value: selected) {
                    PropertyRowCompact(
                        property: selected,
                        isFavorite: appState.isFavorite(selected),
                        onFavorite: { appState.toggleFavorite(selected) }
                    )
                }
                .buttonStyle(.plain)
                .padding(Spacing.md)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: selected)
    }

    private func pricePill(for property: Property) -> some View {
        Button {
            selected = (selected?.id == property.id) ? nil : property
        } label: {
            Text(property.compactPriceLabel)
                .font(.caption.bold())
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .foregroundStyle(selected?.id == property.id ? Color.appOnPrimary : Color.appPrimary)
                .background(selected?.id == property.id ? Color.appPrimary : Color.appSurface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().strokeBorder(Color.appPrimary.opacity(0.4), lineWidth: 1)
                )
                .shadow(color: AppShadow.card.color, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(property.displayTitle), \(property.priceLabel)")
    }
}
