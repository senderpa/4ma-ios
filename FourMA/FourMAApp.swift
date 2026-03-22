import SwiftUI

@main
struct FourMAApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.needsSetup {
                SetupView(appState: appState)
            } else if appState.trialExpired {
                PaywallView(appState: appState)
            } else {
                MainView(appState: appState)
            }
        }
    }
}
