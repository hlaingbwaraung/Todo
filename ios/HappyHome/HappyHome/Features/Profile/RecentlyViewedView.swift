import SwiftUI

/// Full list of the locally persisted recently viewed properties.
struct RecentlyViewedView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var recentlyViewed: RecentlyViewedStore

    var body: some View {
        Group {
            if recentlyViewed.items.isEmpty {
                ScrollView {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: NSLocalizedString("recently_viewed.empty.title", comment: ""),
                        message: NSLocalizedString("recently_viewed.empty.message", comment: "")
                    )
                    .padding(.top, Spacing.xl)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(recentlyViewed.items) { property in
                            NavigationLink(value: property) {
                                PropertyRowCompact(
                                    property: property,
                                    isFavorite: appState.isFavorite(property),
                                    onFavorite: { appState.toggleFavorite(property) }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("profile.recently_viewed", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !recentlyViewed.items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("recently_viewed.clear", comment: "")) {
                        recentlyViewed.clear()
                    }
                }
            }
        }
    }
}
