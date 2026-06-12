import SwiftUI
import UIKit

/// App settings: version info, dev/QA API base URL override and a note on
/// how the app picks its language (it follows the system setting).
struct SettingsView: View {
    @State private var baseURLText: String = UserDefaults.standard
        .string(forKey: AppConfig.baseURLDefaultsKey) ?? ""
    @State private var didSave = false

    var body: some View {
        Form {
            Section(NSLocalizedString("settings.about", comment: "")) {
                LabeledContent(
                    NSLocalizedString("settings.version", comment: ""),
                    value: AppConfig.appVersion
                )
            }

            Section {
                TextField(AppConfig.defaultBaseURLString, text: $baseURLText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit(save)
                Button(NSLocalizedString("settings.save_base_url", comment: ""), action: save)
                if didSave {
                    Label(NSLocalizedString("settings.saved", comment: ""), systemImage: "checkmark.circle.fill")
                        .font(.appFootnote)
                        .foregroundStyle(Color.appSuccess)
                }
            } header: {
                Text(NSLocalizedString("settings.api_base_url", comment: ""))
            } footer: {
                Text(String(
                    format: NSLocalizedString("settings.api_base_url.footer", comment: ""),
                    AppConfig.defaultBaseURLString
                ))
            }

            Section {
                Text(NSLocalizedString("settings.language.note", comment: ""))
                    .font(.appFootnote)
                    .foregroundStyle(Color.appTextSecondary)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(NSLocalizedString("settings.language.open_settings", comment: ""), destination: url)
                }
            } header: {
                Text(NSLocalizedString("settings.language", comment: ""))
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(NSLocalizedString("profile.settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        let trimmed = baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            UserDefaults.standard.removeObject(forKey: AppConfig.baseURLDefaultsKey)
        } else {
            UserDefaults.standard.set(trimmed, forKey: AppConfig.baseURLDefaultsKey)
        }
        Haptics.light()
        withAnimation { didSave = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { didSave = false }
        }
    }
}
