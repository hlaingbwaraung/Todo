import SwiftUI

/// Contact form for a property. Works logged-out (fields prefill when a
/// session exists) per the API contract.
struct InquirySheet: View {
    let property: Property

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = InquirySheetViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSubmitted {
                    SubmissionSuccessView(
                        title: NSLocalizedString("inquiry.success.title", comment: ""),
                        message: NSLocalizedString("inquiry.success.message", comment: "")
                    ) {
                        dismiss()
                    }
                } else {
                    form
                }
            }
            .background(Color.appBackground)
            .navigationTitle(NSLocalizedString("inquiry.title", comment: ""))
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

            Section(NSLocalizedString("form.message", comment: "")) {
                TextEditor(text: $viewModel.message)
                    .frame(minHeight: 120)
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
                title: NSLocalizedString("inquiry.submit", comment: ""),
                systemImage: "paperplane.fill",
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
final class InquirySheetViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var phone = ""
    @Published var message = ""
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
            && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
        let body = InquiryBody(
            propertyId: propertyId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
            message: message.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        do {
            _ = try await repository.createInquiry(body)
            isSubmitted = true
        } catch {
            Haptics.error()
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Shared form pieces (used by InquirySheet and BookingSheet)

/// Inline validation/server error banner shown inside forms.
struct FormErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.appFootnote)
            .foregroundStyle(Color.appDanger)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Full-screen success state with a springy checkmark.
struct SubmissionSuccessView: View {
    let title: String
    let message: String
    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.appSuccess)
                .scaleEffect(appeared ? 1 : 0.3)
                .opacity(appeared ? 1 : 0)
            Text(title)
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(message)
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            PrimaryButton(title: NSLocalizedString("common.done", comment: "")) {
                onDone()
            }
        }
        .padding(Spacing.lg)
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                appeared = true
            }
        }
    }
}
