import SwiftUI

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Workout History")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("View your past workouts")
                .font(.system(size: 16))
                .foregroundColor(Theme.textDim)
            
            Spacer()
        }
        .padding()
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}