import SwiftUI

struct SettingsView: View {
    @StateObject private var authState = AuthState.shared
    
    var body: some View {
        List {
            Section {
                Button(action: {
                    authState.logout()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.red)
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
            } header: {
                Text("Account")
            }
            
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(Theme.textDim)
                }
            } header: {
                Text("About")
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }
}