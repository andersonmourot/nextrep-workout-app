import SwiftUI
import UIKit

final class PortraitOnlyAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

@main
struct NextRepApp: App {
    @UIApplicationDelegateAdaptor(PortraitOnlyAppDelegate.self) private var appDelegate
    @State private var store: AppStore

    init() {
        // UI tests / local dev can point the app at a non-production backend.
        if let raw = ProcessInfo.processInfo.environment["NEXTREP_API_URL"],
           let url = URL(string: raw) {
            // UI tests need a clean session — the keychain token survives
            // between launches, so clear it before AppStore can load it.
            if ProcessInfo.processInfo.environment["NEXTREP_RESET_SESSION"] == "1" {
                try? KeychainStore().deleteToken()
            }
            _store = State(initialValue: AppStore(apiClient: APIClient(baseURL: url)))
        } else {
            _store = State(initialValue: AppStore())
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
