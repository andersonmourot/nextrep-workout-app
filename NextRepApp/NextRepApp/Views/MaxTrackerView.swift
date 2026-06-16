import SwiftUI

struct MaxTrackerView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Max Tracker")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Track your personal records")
                .font(.system(size: 16))
                .foregroundColor(Theme.textDim)
            
            Spacer()
            
            Button("Add Record") {
                // TODO: Add record
            }
            .buttonStyle(PrimaryButton())
            .padding(.horizontal)
        }
        .padding()
        .navigationTitle("Max Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
    }
}