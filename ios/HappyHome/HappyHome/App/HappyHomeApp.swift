import SwiftUI

@main
struct HappyHomeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(appState.recentlyViewed)
                .environmentObject(appState.compareStore)
                .tint(Color.appAccent)
                .task {
                    await appState.bootstrap()
                }
        }
    }
}
