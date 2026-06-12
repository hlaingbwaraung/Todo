import SwiftUI

/// AsyncImage replacement backed by ImageCache (NSCache + URLCache disk),
/// with a shimmer placeholder and graceful failure state.
struct CachedAsyncImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if failed || url == nil {
                Color.appSurfaceSecondary
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(Color.appTextSecondary)
                    )
            } else {
                Color.appSurfaceSecondary
                    .shimmering()
            }
        }
        .task(id: url) {
            failed = false
            guard let url else { return }
            if let cached = ImageCache.shared.cachedImage(for: url) {
                image = cached
                return
            }
            let loaded = await ImageCache.shared.image(for: url)
            if let loaded {
                image = loaded
            } else {
                failed = true
            }
        }
    }
}
