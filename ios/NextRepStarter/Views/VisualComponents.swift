import SwiftUI

struct ProgressRing: View {
    let value: Double
    var size: CGFloat = 72
    var lineWidth: CGFloat = 7
    var color: Color = Theme.accentLight
    var trackColor: Color = Theme.textFaint.opacity(0.25)
    var center: String? = nil
    var caption: String? = nil

    private var clampedValue: Double {
        min(1, max(0, value))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.35), value: clampedValue)

            VStack(spacing: 1) {
                if let center {
                    Text(center)
                        .font(.headline.monospacedDigit().weight(.bold))
                        .foregroundStyle(Theme.text)
                }

                if let caption {
                    Text(caption)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textFaint)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct MiniLineChart: View {
    let values: [Double]
    var color: Color = Theme.accentLight
    var fill: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let points = chartPoints(size: proxy.size)

            ZStack(alignment: .bottomLeading) {
                if fill, points.count > 1 {
                    Path { path in
                        guard let first = points.first, let last = points.last else { return }
                        path.move(to: CGPoint(x: first.x, y: proxy.size.height))
                        path.addLine(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: last.x, y: proxy.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.28), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
            }
        }
    }

    private func chartPoints(size: CGSize) -> [CGPoint] {
        guard values.count > 1, let minValue = values.min(), let maxValue = values.max() else {
            return []
        }

        let range = max(1, maxValue - minValue)
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(max(1, values.count - 1))
            let normalized = (value - minValue) / range
            let y = size.height - (size.height * CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }
}

struct MetricProgressBar: View {
    let label: String
    let value: Double
    let target: Double
    let suffix: String
    var color: Color = Theme.accentLight

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, value / target))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textDim)

                Spacer()

                Text("\(formatMetric(value))/\(formatMetric(target))\(suffix)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.text)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.surface2)

                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(progress))
                }
            }
            .frame(height: 9)
        }
    }

    private func formatMetric(_ number: Double) -> String {
        if number.rounded() == number {
            return "\(Int(number))"
        }

        return String(format: "%.1f", number)
    }
}
