import SwiftUI

struct ProgressRing: View {
    let value: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    
    init(value: Double, lineWidth: CGFloat = 8) {
        self.value = max(0, min(1, value))
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: value)
                .stroke(
                    Theme.accent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: value)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressRing(value: 0.75)
            .frame(width: 80, height: 80)
        
        ProgressRing(value: 0.25)
            .frame(width: 60, height: 60)
    }
    .padding()
    .background(Theme.bg)
}