import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            Text("Authenticated - Main app to be implemented")
        } else {
            AuthView(isAuthenticated: $isAuthenticated)
        }
    }
}