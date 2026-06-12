import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingLogin = false
    @State private var showingSignup = false
    @State private var showingLogoutConfirmation = false

    var body: some View {
        Group {
            if let user = appState.user {
                loggedInList(user: user)
            } else {
                loggedOutHero
            }
        }
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("tab.profile", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $showingSignup) {
            NavigationStack {
                SignupView(showsCancelButton: true)
            }
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            NSLocalizedString("profile.logout.confirm_title", comment: ""),
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button(NSLocalizedString("profile.logout", comment: ""), role: .destructive) {
                appState.sessionDidEnd()
            }
            Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) {}
        }
    }

    // MARK: Logged out

    private var loggedOutHero: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Spacer(minLength: Spacing.xl)
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.appTextSecondary)
                VStack(spacing: Spacing.xs) {
                    Text(NSLocalizedString("profile.logged_out.title", comment: ""))
                        .font(.appTitle)
                        .foregroundStyle(Color.appTextPrimary)
                    Text(NSLocalizedString("profile.logged_out.message", comment: ""))
                        .font(.appSubheadline)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
                VStack(spacing: Spacing.sm) {
                    PrimaryButton(
                        title: NSLocalizedString("auth.login", comment: ""),
                        systemImage: "arrow.right.circle.fill"
                    ) {
                        showingLogin = true
                    }
                    SecondaryButton(
                        title: NSLocalizedString("auth.signup", comment: ""),
                        systemImage: "person.badge.plus"
                    ) {
                        showingSignup = true
                    }
                }

                settingsFooterLink
            }
            .padding(Spacing.lg)
        }
    }

    /// Settings stay reachable without an account (API base URL override).
    private var settingsFooterLink: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Label(NSLocalizedString("profile.settings", comment: ""), systemImage: "gearshape")
                .font(.appSubheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: Logged in

    private func loggedInList(user: User) -> some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    avatar(for: user)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name)
                            .font(.appHeadline)
                            .foregroundStyle(Color.appTextPrimary)
                        Text(user.email)
                            .font(.appFootnote)
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.vertical, Spacing.xs)
            }
            .listRowBackground(Color.appSurface)

            Section {
                NavigationLink {
                    MyInquiriesView()
                } label: {
                    profileRow(
                        icon: "envelope.fill",
                        title: NSLocalizedString("profile.my_inquiries", comment: "")
                    )
                }
                NavigationLink {
                    MyReservationsView()
                } label: {
                    profileRow(
                        icon: "calendar",
                        title: NSLocalizedString("profile.my_reservations", comment: "")
                    )
                }
                NavigationLink {
                    RecentlyViewedView()
                } label: {
                    profileRow(
                        icon: "clock.arrow.circlepath",
                        title: NSLocalizedString("profile.recently_viewed", comment: "")
                    )
                }
                NavigationLink {
                    CompareView()
                } label: {
                    profileRow(
                        icon: "rectangle.split.2x1",
                        title: NSLocalizedString("compare.title", comment: "")
                    )
                }
            }
            .listRowBackground(Color.appSurface)

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    profileRow(
                        icon: "gearshape.fill",
                        title: NSLocalizedString("profile.settings", comment: "")
                    )
                }
            }
            .listRowBackground(Color.appSurface)

            Section {
                Button(role: .destructive) {
                    showingLogoutConfirmation = true
                } label: {
                    profileRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: NSLocalizedString("profile.logout", comment: ""),
                        tint: .appDanger
                    )
                }
            }
            .listRowBackground(Color.appSurface)
        }
        .scrollContentBackground(.hidden)
    }

    private func avatar(for user: User) -> some View {
        ZStack {
            Circle()
                .fill(Color.appPrimary)
            Text(user.initials)
                .font(.appHeadline)
                .foregroundStyle(Color.appOnPrimary)
        }
        .frame(width: 56, height: 56)
        .accessibilityHidden(true)
    }

    private func profileRow(icon: String, title: String, tint: Color = .appAccent) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 26)
            Text(title)
                .font(.appBody)
                .foregroundStyle(tint == .appDanger ? Color.appDanger : Color.appTextPrimary)
        }
    }
}
