import SwiftUI

@main
struct NextRepiOSApp: App {
    @State private var isAuthenticated = false
    @State private var showingSettings = false
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
            } else {
                AuthFlowView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}