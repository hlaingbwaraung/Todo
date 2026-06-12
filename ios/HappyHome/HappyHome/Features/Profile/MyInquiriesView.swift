import SwiftUI

struct MyInquiriesView: View {
    @StateObject private var viewModel = MyInquiriesViewModel()

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
                if viewModel.inquiries.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "envelope",
                            title: NSLocalizedString("my_inquiries.empty.title", comment: ""),
                            message: NSLocalizedString("my_inquiries.empty.message", comment: "")
                        )
                        .padding(.top, Spacing.xl)
                    }
                } else {
                    list
                }
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("profile.my_inquiries", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                ForEach(viewModel.inquiries) { inquiry in
                    inquiryRow(inquiry)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func inquiryRow(_ inquiry: Inquiry) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            CachedAsyncImage(url: inquiry.thumbnailURL)
                .frame(width: 72, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: Radii.chip, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(inquiry.displayPropertyTitle)
                        .font(.appSubheadline.weight(.medium))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Badge.forInquiryStatus(inquiry.status)
                }
                Text(inquiry.message)
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                if let createdAt = inquiry.createdAt {
                    Text(createdAt.displayDate)
                        .font(.appCaption)
                        .foregroundStyle(Color.appTextSecondary)
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
final class MyInquiriesViewModel: ObservableObject {
    @Published var state: LoadState = .idle
    @Published var inquiries: [Inquiry] = []

    private let repository: InquiryRepositoryProtocol

    init(repository: InquiryRepositoryProtocol = InquiryRepository()) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard state == .idle else { return }
        await load()
    }

    func load() async {
        if inquiries.isEmpty { state = .loading }
        do {
            inquiries = try await repository.myInquiries()
            state = .loaded
        } catch {
            state = inquiries.isEmpty ? .failed(error.localizedDescription) : .loaded
        }
    }
}
