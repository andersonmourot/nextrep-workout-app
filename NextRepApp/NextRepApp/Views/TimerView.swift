import SwiftUI

struct TimerView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Timer")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Theme.text)
            
            Text("Set workout timers")
                .font(.system(size: 16))
                .foregroundColor(Theme.textDim)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Timer")
        .navigationBarTitleDisplayMode(.inline)
    }
}