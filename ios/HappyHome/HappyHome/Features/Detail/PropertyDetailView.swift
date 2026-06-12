import SwiftUI
import MapKit

struct PropertyDetailView: View {
    @StateObject private var viewModel: PropertyDetailViewModel
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var recentlyViewed: RecentlyViewedStore
    @EnvironmentObject private var compareStore: CompareStore

    @State private var galleryIndex = 0
    @State private var showingFullscreenGallery = false
    @State private var showingInquiry = false
    @State private var showingBooking = false
    @State private var showingLogin = false

    init(property: Property) {
        _viewModel = StateObject(wrappedValue: PropertyDetailViewModel(property: property))
    }

    private var property: Property { viewModel.property }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingSkeleton
            case .failed(let message):
                ScrollView {
                    ErrorStateView(message: message) {
                        Task { await viewModel.load() }
                    }
                    .padding(.top, Spacing.xl)
                }
            case .loaded:
                content
            }
        }
        .background(Color.appBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .safeAreaInset(edge: .bottom) {
            if case .loaded = viewModel.state {
                bottomBar
            }
        }
        .sheet(isPresented: $showingInquiry) {
            InquirySheet(property: property)
        }
        .sheet(isPresented: $showingBooking) {
            BookingSheet(property: property)
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showingFullscreenGallery) {
            FullscreenGalleryView(urls: property.galleryURLs, index: $galleryIndex)
        }
        .task {
            await viewModel.loadIfNeeded()
            if case .loaded = viewModel.state {
                recentlyViewed.record(viewModel.property)
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                if appState.isAuthenticated {
                    appState.toggleFavorite(property)
                } else {
                    showingLogin = true
                }
            } label: {
                Image(systemName: appState.isFavorite(property) ? "heart.fill" : "heart")
                    .foregroundStyle(appState.isFavorite(property) ? Color.appDanger : Color.appPrimary)
            }
            .accessibilityLabel(
                appState.isFavorite(property)
                    ? NSLocalizedString("a11y.favorite.remove", comment: "")
                    : NSLocalizedString("a11y.favorite.add", comment: "")
            )

            ShareLink(item: shareURL, subject: Text(property.displayTitle)) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel(NSLocalizedString("a11y.share", comment: ""))

            Button {
                compareStore.toggle(property)
            } label: {
                Image(systemName: compareStore.contains(property)
                      ? "rectangle.split.2x1.fill"
                      : "rectangle.split.2x1")
            }
            .accessibilityLabel(
                compareStore.contains(property)
                    ? NSLocalizedString("compare.remove", comment: "")
                    : NSLocalizedString("compare.add", comment: "")
            )
        }
    }

    private var shareURL: URL {
        AppConfig.baseURL.appendingPathComponent("properties/\(property.id)")
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                gallery
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection
                    specsSection
                    if !property.amenityList.isEmpty {
                        amenitiesSection
                    }
                    if let description = property.displayDescription, !description.isEmpty {
                        descriptionSection(description)
                    }
                    if let floorPlanUrl = property.floorPlanUrl, let url = URL(string: floorPlanUrl) {
                        floorPlanSection(url)
                    }
                    locationSection
                    agentSection
                }
                .padding(.horizontal, Spacing.md)

                if !viewModel.similar.isEmpty {
                    similarSection
                }
            }
            .padding(.bottom, Spacing.lg)
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: Gallery

    private var gallery: some View {
        ZStack(alignment: .bottom) {
            if property.galleryURLs.isEmpty {
                CachedAsyncImage(url: nil)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                TabView(selection: $galleryIndex) {
                    ForEach(Array(property.galleryURLs.enumerated()), id: \.offset) { index, url in
                        CachedAsyncImage(url: url)
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showingFullscreenGallery = true
                            }
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 300)

                if property.galleryURLs.count > 1 {
                    indexDots
                        .padding(.bottom, Spacing.sm)
                }
            }
        }
    }

    private var indexDots: some View {
        HStack(spacing: 6) {
            ForEach(property.galleryURLs.indices, id: \.self) { index in
                Circle()
                    .fill(index == galleryIndex ? Color.white : Color.white.opacity(0.45))
                    .frame(width: 7, height: 7)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityHidden(true)
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(property.priceLabel)
                    .font(.appPriceLarge)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if let fee = property.managementFee, fee > 0 {
                    Text(String(format: NSLocalizedString("detail.management_fee_format", comment: ""), fee.yenString))
                        .font(.appFootnote)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
            }

            Text(property.displayTitle)
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)

            HStack(spacing: Spacing.xs) {
                if property.featured {
                    Badge(
                        text: NSLocalizedString("property.featured", comment: ""),
                        style: .featured,
                        systemImage: "star.fill"
                    )
                }
                Badge(text: property.transactionType.displayName, style: .neutral)
                if property.petAllowed == true {
                    Badge(
                        text: NSLocalizedString("property.pet_allowed", comment: ""),
                        style: .success,
                        systemImage: "pawprint.fill"
                    )
                }
                if property.parkingAvailable == true {
                    Badge(
                        text: NSLocalizedString("property.parking", comment: ""),
                        style: .neutral,
                        systemImage: "car.fill"
                    )
                }
            }

            if let viewCount = property.viewCount {
                RatingOrViewsLabel(viewCount: viewCount)
            }
        }
    }

    // MARK: Specs

    private var specsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.specs", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible())],
                spacing: Spacing.sm
            ) {
                if let layout = property.layout {
                    specCell(label: NSLocalizedString("detail.layout", comment: ""), value: layout)
                }
                if let size = property.sizeLabel {
                    specCell(label: NSLocalizedString("detail.size", comment: ""), value: size)
                }
                if let floor = property.floor, let total = property.totalFloors {
                    specCell(
                        label: NSLocalizedString("detail.floor", comment: ""),
                        value: String(format: NSLocalizedString("detail.floor_value", comment: ""), floor, total)
                    )
                }
                if let builtYear = property.builtYear {
                    specCell(
                        label: NSLocalizedString("detail.built", comment: ""),
                        value: builtValue(year: builtYear)
                    )
                }
                specCell(
                    label: NSLocalizedString("detail.deposit", comment: ""),
                    value: monthsValue(property.depositMonths)
                )
                specCell(
                    label: NSLocalizedString("detail.key_money", comment: ""),
                    value: monthsValue(property.keyMoneyMonths)
                )
            }
        }
    }

    private func specCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.appCaption)
                .foregroundStyle(Color.appTextSecondary)
            Text(value)
                .font(.appSubheadline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.sm)
        .background(Color.appSurfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func builtValue(year: Int) -> String {
        let built = String(format: NSLocalizedString("detail.built_value", comment: ""), year)
        if let age = property.ageLabel {
            return "\(built) (\(age))"
        }
        return built
    }

    private func monthsValue(_ months: Double?) -> String {
        guard let months, months > 0 else {
            return NSLocalizedString("common.none", comment: "")
        }
        return String(format: NSLocalizedString("detail.months_value", comment: ""), months)
    }

    // MARK: Amenities

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.amenities", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: Spacing.sm, alignment: .leading)],
                alignment: .leading,
                spacing: Spacing.sm
            ) {
                ForEach(property.amenityList, id: \.self) { amenity in
                    AmenityTag(amenity: amenity)
                }
            }
        }
    }

    // MARK: Description / floor plan

    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.description", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(description)
                .font(.appBody)
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    private func floorPlanSection(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.floor_plan", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)
            CachedAsyncImage(url: url, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
        }
    }

    // MARK: Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.location", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)

            if let coordinate = property.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker(property.displayTitle, coordinate: coordinate)
                        .tint(Color.appPrimary)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
                .allowsHitTesting(false)
            }

            if let address = property.displayAddress {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appTextPrimary)
            }
            if let station = property.displayStation {
                Label(
                    property.walkLabel.map { "\(station) \($0)" } ?? station,
                    systemImage: "tram.fill"
                )
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    // MARK: Agent

    private var agentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(NSLocalizedString("detail.agent", comment: ""))
                .font(.appSectionTitle)
                .foregroundStyle(Color.appTextPrimary)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let company = property.agentCompany {
                    Text(company)
                        .font(.appHeadline)
                        .foregroundStyle(Color.appTextPrimary)
                }
                if let name = property.agentName {
                    Text(name)
                        .font(.appSubheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
                HStack(spacing: Spacing.sm) {
                    if let phone = property.agentPhone,
                       let url = URL(string: "tel:" + phone.replacingOccurrences(of: " ", with: "")) {
                        Link(destination: url) {
                            Label(NSLocalizedString("detail.call", comment: ""), systemImage: "phone.fill")
                                .font(.appSubheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(Color.appOnPrimary)
                                .background(Color.appPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
                        }
                    }
                    if let email = property.agentEmail,
                       let url = URL(string: "mailto:\(email)") {
                        Link(destination: url) {
                            Label(NSLocalizedString("detail.email", comment: ""), systemImage: "envelope.fill")
                                .font(.appSubheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .foregroundStyle(Color.appPrimary)
                                .background(
                                    RoundedRectangle(cornerRadius: Radii.control, style: .continuous)
                                        .strokeBorder(Color.appPrimary, lineWidth: 1.5)
                                )
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    // MARK: Similar

    private var similarSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: NSLocalizedString("detail.similar", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(viewModel.similar) { similar in
                        NavigationLink(value: similar) {
                            PropertyCard(
                                property: similar,
                                isFavorite: appState.isFavorite(similar),
                                onFavorite: { appState.toggleFavorite(similar) },
                                width: 280
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.sm)
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        HStack(spacing: Spacing.sm) {
            SecondaryButton(
                title: NSLocalizedString("detail.inquire", comment: ""),
                systemImage: "envelope"
            ) {
                showingInquiry = true
            }
            PrimaryButton(
                title: NSLocalizedString("detail.book_visit", comment: ""),
                systemImage: "calendar"
            ) {
                showingBooking = true
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.thinMaterial)
    }

    // MARK: Skeleton

    private var loadingSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SkeletonView(cornerRadius: 0)
                    .frame(height: 300)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    SkeletonView().frame(width: 160, height: 30)
                    SkeletonView().frame(height: 22)
                    SkeletonView().frame(width: 200, height: 16)
                    HStack(spacing: Spacing.sm) {
                        SkeletonView(cornerRadius: Radii.control).frame(height: 56)
                        SkeletonView(cornerRadius: Radii.control).frame(height: 56)
                    }
                    HStack(spacing: Spacing.sm) {
                        SkeletonView(cornerRadius: Radii.control).frame(height: 56)
                        SkeletonView(cornerRadius: Radii.control).frame(height: 56)
                    }
                    SkeletonView(cornerRadius: Radii.card).frame(height: 160)
                }
                .padding(.horizontal, Spacing.md)
            }
        }
        .ignoresSafeArea(edges: .top)
        .disabled(true)
    }
}

// MARK: - Fullscreen gallery viewer

struct FullscreenGalleryView: View {
    let urls: [URL]
    @Binding var index: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(urls.enumerated()), id: \.offset) { idx, url in
                    CachedAsyncImage(url: url, contentMode: .fit)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .ignoresSafeArea()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(Spacing.md)
            .accessibilityLabel(NSLocalizedString("common.close", comment: ""))
        }
        .preferredColorScheme(.dark)
    }
}
