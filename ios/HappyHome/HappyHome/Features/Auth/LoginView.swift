import SwiftUI

/// Email/password sign-in, presented as a sheet wherever auth is required.
struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var password = ""

    private var isValid: Bool {
        email.isLikelyEmail && !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    header

                    VStack(spacing: Spacing.sm) {
                        AuthTextField(
                            placeholder: NSLocalizedString("form.email", comment: ""),
                            text: $email,
                            systemImage: "envelope"
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        AuthSecureField(
                            placeholder: NSLocalizedString("form.password", comment: ""),
                            text: $password
                        )
                        .textContentType(.password)
                    }

                    if let errorMessage = viewModel.errorMessage {
                        FormErrorBanner(message: errorMessage)
                    }

                    PrimaryButton(
                        title: NSLocalizedString("auth.login", comment: ""),
                        systemImage: "arrow.right.circle.fill",
                        isLoading: viewModel.isLoading,
                        isEnabled: isValid
                    ) {
                        Task {
                            if await viewModel.login(email: email, password: password, appState: appState) {
                                dismiss()
                            }
                        }
                    }

                    NavigationLink {
                        SignupView()
                    } label: {
                        Text(NSLocalizedString("auth.no_account", comment: ""))
                            .font(.appSubheadline.weight(.medium))
                            .foregroundStyle(Color.appAccent)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle(NSLocalizedString("auth.login", comment: ""))
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
        // Covers signup completing deeper in this sheet's stack: once a
        // session exists there is nothing left to do here.
        .onChange(of: appState.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "house.lodge.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.appAccent)
            Text(NSLocalizedString("auth.welcome_back", comment: ""))
                .font(.appTitle)
                .foregroundStyle(Color.appTextPrimary)
            Text(NSLocalizedString("auth.login_subtitle", comment: ""))
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.lg)
    }
}

// MARK: - Field chrome shared by Login/Signup

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(width: 20)
            }
            TextField(placeholder, text: $text)
                .font(.appBody)
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
    }
}

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String

    @State private var isRevealed = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lock")
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 20)
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.appBody)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                isRevealed.toggle()
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .foregroundStyle(Color.appTextSecondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(NSLocalizedString("a11y.toggle_password", comment: ""))
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radii.control, style: .continuous))
    }
}
