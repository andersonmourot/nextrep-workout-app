import SwiftUI

struct PeopleView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Search People")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Find and follow other users")
                .font(.system(size: 16))
                .foregroundColor(Theme.textDim)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
            .background(Theme.bg)
    }
}