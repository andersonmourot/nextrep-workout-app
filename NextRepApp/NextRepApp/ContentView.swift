import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    
    var body: some View {
        if isAuthenticated {
            ProgramsListView(isAuthenticated: $isAuthenticated)
        } else {
            AuthFlowView(isAuthenticated: $isAuthenticated)
        }
    }
}