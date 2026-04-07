import SwiftUI

struct CircularGaugeView: View {
    var progress: Double
    var lineWidth: CGFloat = 6
    var gaugeSize: CGFloat = 48
    var tint: Color = .nudgewhipFocus

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.nudgewhipStrokeDefault.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: progress)

            Text("\(Int(clampedProgress * 100))%")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.nudgewhipTextSecondary)
        }
        .frame(width: gaugeSize, height: gaugeSize)
    }

    private var clampedProgress: Double {
        max(0, min(1, progress))
    }
}
