import SwiftUI

/// Viewing-reservation form: contact info + preferred date (today or later)
/// and a 10:00–18:00 time-slot picker.
struct BookingSheet: View {
    let property: Property

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BookingSheetViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSubmitted {
                    SubmissionSuccessView(
                        title: NSLocalizedString("booking.success.title", comment: ""),
                        message: NSLocalizedString("booking.success.message", comment: "")
                    ) {
                        dismiss()
                    }
                } else {
                    form
                }
            }
            .background(Color.appBackground)
            .navigationTitle(NSLocalizedString("booking.title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(viewModel.isSubmitting)
        .onAppear {
            viewModel.prefill(from: appState.user)
        }
    }

    private var form: some View {
        Form {
            Section {
                HStack(spacing: Spacing.sm) {
                    CachedAsyncImage(url: property.thumbnailURL)
                        .frame(width: 56, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: Radii.chip, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(property.displayTitle)
                            .font(.appSubheadline.weight(.medium))
                            .foregroundStyle(Color.appTextPrimary)
                            .lineLimit(1)
                        Text(property.priceLabel)
                            .font(.appFootnote)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            Section(NSLocalizedString("booking.date_time", comment: "")) {
                DatePicker(
                    NSLocalizedString("booking.preferred_date", comment: ""),
                    selection: $viewModel.preferredDate,
                    in: Date()...,
                    displayedComponents: .date
                )

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(NSLocalizedString("booking.preferred_time", comment: ""))
                        .font(.appSubheadline)
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 68), spacing: Spacing.sm)],
                        alignment: .leading,
                        spacing: Spacing.sm
                    ) {
                        ForEach(BookingSheetViewModel.timeSlots, id: \.self) { slot in
                            FilterChip(
                                title: slot,
                                isSelected: viewModel.preferredTime == slot
                            ) {
                                viewModel.preferredTime = slot
                            }
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }

            Section(NSLocalizedString("form.contact_info", comment: "")) {
                TextField(NSLocalizedString("form.name", comment: ""), text: $viewModel.name)
                    .textContentType(.name)
                TextField(NSLocalizedString("form.email", comment: ""), text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(NSLocalizedString("form.phone_optional", comment: ""), text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            Section(NSLocalizedString("form.message_optional", comment: "")) {
                TextEditor(text: $viewModel.message)
                    .frame(minHeight: 90)
                    .font(.appBody)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    FormErrorBanner(message: errorMessage)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: NSLocalizedString("booking.submit", comment: ""),
                systemImage: "calendar.badge.checkmark",
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.isValid
            ) {
                Task { await viewModel.submit(propertyId: property.id) }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(.thinMaterial)
        }
    }
}

// MARK: - View model

@MainActor
final class BookingSheetViewModel: ObservableObject {
    static let timeSlots = [
        "10:00", "11:00", "12:00", "13:00", "14:00",
        "15:00", "16:00", "17:00", "18:00"
    ]

    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var message = ""
    @Published var preferredDate = Date()
    @Published var preferredTime = "10:00"
    @Published var isSubmitting = false
    @Published var isSubmitted = false
    @Published var errorMessage: String?

    private let repository: InquiryRepositoryProtocol
    private var didPrefill = false

    init(repository: InquiryRepositoryProtocol = InquiryRepository()) {
        self.repository = repository
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && email.isLikelyEmail
            && Self.timeSlots.contains(preferredTime)
    }

    func prefill(from user: User?) {
        guard !didPrefill, let user else { return }
        didPrefill = true
        if name.isEmpty { name = user.name }
        if email.isEmpty { email = user.email }
        if phone.isEmpty, let userPhone = user.phone { phone = userPhone }
    }

    func submit(propertyId: Int) async {
        guard isValid, !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = ReservationBody(
            propertyId: propertyId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            preferredDate: preferredDate.apiDateString,
            preferredTime: preferredTime,
            message: trimmedMessage.isEmpty ? nil : trimmedMessage
        )
        do {
            _ = try await repository.createReservation(body)
            isSubmitted = true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
        }
    }
}
