import SwiftUI

struct MyReservationsView: View {
    @StateObject private var viewModel = MyReservationsViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                skeletons
            case .failed(let message):
                ScrollView {
                    ErrorStateView(message: message) {
                        Task { await viewModel.load() }
                    }
                    .padding(.top, Spacing.xl)
                }
            case .loaded:
                if viewModel.reservations.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "calendar.badge.clock",
                            title: NSLocalizedString("my_reservations.empty.title", comment: ""),
                            message: NSLocalizedString("my_reservations.empty.message", comment: "")
                        )
                        .padding(.top, Spacing.xl)
                    }
                } else {
                    list
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("profile.my_reservations", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.reservations) { reservation in
                    reservationRow(reservation)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func reservationRow(_ reservation: Reservation) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            CachedAsyncImage(url: reservation.thumbnailURL)
                .frame(width: 72, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Radii.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(reservation.displayPropertyTitle)
                        .font(.appSubheadline.weight(.medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Badge.forReservationStatus(reservation.status)
                }
                Label(
                    "\(reservation.preferredDate) \(reservation.preferredTime)",
                    systemImage: "calendar"
                )
                .font(.appFootnote)
                .foregroundStyle(Color.appTextSecondary)
                if let message = reservation.message, !message.isEmpty {
                    Text(message)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(Spacing.sm)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var skeletons: some View {
        ScrollView {
            VStack(spacing: Spacing.sm) {
                ForEach(0..<4, id: \.self) { _ in
                    PropertyRowSkeleton()
                }
            }
            .padding(.horizontal, Spacing.md)
        }
        .disabled(true)
    }
}

@MainActor
final class MyReservationsViewModel: ObservableObject {
    @Published var state: LoadState = .idle
    @Published var reservations: [Reservation] = []

    private let repository: InquiryRepositoryProtocol

    init(repository: InquiryRepositoryProtocol = InquiryRepository()) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        if reservations.isEmpty { state = .loading }
        do {
            reservations = try await repository.myReservations()
            state = .loaded
        } catch {
            state = reservations.isEmpty ? .failed(error.localizedDescription) : .loaded
        }
    }
}
