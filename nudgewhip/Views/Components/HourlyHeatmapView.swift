import SwiftUI

struct HourlyHeatmapView: View {
    let hourlyCounts: [Int]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var maxCount: Int {
        hourlyCounts.max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("recovery.review.hourly_heatmap.title", defaultValue: "Distraction by hour"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            VStack(spacing: NudgeWhipSpacing.s2) {
                rowView(hours: 0..<12)
                rowView(hours: 12..<24)
            }
        }
        .padding(NudgeWhipSpacing.s4)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private func rowView(hours: Range<Int>) -> some View {
        HStack(spacing: NudgeWhipSpacing.s1) {
            ForEach(Array(hours), id: \.self) { hour in
                cellView(hour: hour)
            }
        }
    }

    private func cellView(hour: Int) -> some View {
        let count = hourlyCounts.indices.contains(hour) ? hourlyCounts[hour] : 0
        let intensity = maxCount > 0 ? Double(count) / Double(maxCount) : 0

        return VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(cellFill(intensity: intensity))
                .frame(height: 28)
                .overlay {
                    if reduceMotion || count > 0 {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .medium).monospacedDigit())
                            .foregroundStyle(intensity > 0.5 ? .white : Color.nudgewhipTextMuted)
                    }
                }

            Text(shortHourLabel(hour))
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func cellFill(intensity: Double) -> Color {
        guard intensity > 0 else {
            return Color.nudgewhipStrokeDefault.opacity(0.3)
        }
        return Color.nudgewhipFocus.opacity(0.15 + intensity * 0.85)
    }

    private func shortHourLabel(_ hour: Int) -> String {
        let locale = appDisplayLocale()
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return "\(hour)" }
        let label = formatter.string(from: date)
        return label.lowercased()
    }
}
