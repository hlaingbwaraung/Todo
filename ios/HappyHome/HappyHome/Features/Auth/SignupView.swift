import SwiftUI

/// Account registration. Pushed from LoginView or presented directly
/// from the Profile tab's logged-out hero.
struct SignupView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    /// Presented standalone (sheet root) vs pushed from LoginView.
    var showsCancelButton: Bool = false

    private var passwordTooShort: Bool {
        !password.isEmpty && password.count < 8
    }

    private var passwordsMismatch: Bool {
        !confirmPassword.isEmpty && confirmPassword != password
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && email.isLikelyEmail
            && password.count >= 8
            && confirmPassword == password
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                header

                VStack(spacing: Spacing.sm) {
                    AuthTextField(
                        placeholder: NSLocalizedString("form.name", comment: ""),
                        text: $name,
                        systemImage: "person"
                    )
                    .textContentType(.name)

                    AuthTextField(
                        placeholder: NSLocalizedString("form.email", comment: ""),
                        text: $email,
                        systemImage: "envelope"
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    AuthTextField(
                        placeholder: NSLocalizedString("form.phone_optional", comment: ""),
                        text: $phone,
                        systemImage: "phone"
                    )
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)

                    AuthSecureField(
                        placeholder: NSLocalizedString("form.password", comment: ""),
                        text: $password
                    )
                    .textContentType(.newPassword)

                    if passwordTooShort {
                        inlineHint(NSLocalizedString("auth.password_min", comment: ""))
                    }

                    AuthSecureField(
                        placeholder: NSLocalizedString("form.confirm_password", comment: ""),
                        text: $confirmPassword
                    )
                    .textContentType(.newPassword)

                    if passwordsMismatch {
                        inlineHint(NSLocalizedString("auth.password_mismatch", comment: ""))
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    FormErrorBanner(message: errorMessage)
                }

                PrimaryButton(
                    title: NSLocalizedString("auth.signup", comment: ""),
                    systemImage: "person.badge.plus",
                    isLoading: viewModel.isLoading,
                    isEnabled: isValid
                ) {
                    let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        let success = await viewModel.register(
                            name: name,
                            email: email,
                            password: password,
                            phone: trimmedPhone.isEmpty ? nil : trimmedPhone,
                            appState: appState
                        )
                        if success {
                            dismiss()
                        }
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("auth.signup", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCancelButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("common.cancel", comment: "")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.appAccent)
            Text(NSLocalizedString("auth.signup_title", comment: ""))
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(NSLocalizedString("auth.signup_subtitle", comment: ""))
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }

    private func inlineHint(_ text: String) -> some View {
        Text(text)
            .font(.appCaption)
            .foregroundStyle(Color.appDanger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.xs)
    }
}
