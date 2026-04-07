import SwiftUI

struct DailySummaryView: View {
    let todayStats: DailyStats
    let whitelistCount: Int

    private let columns = [
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2),
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("menu.dropdown.group.today", defaultValue: "Today"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, spacing: NudgeWhipSpacing.s2) {
                statCard(
                    value: formattedDuration(todayStats.totalFocusDuration),
                    label: localizedAppString("menu.dropdown.label.focus_time", defaultValue: "Focus time")
                )

                statCard(
                    value: "\(todayStats.completedSessionCount)",
                    label: localizedAppString("menu.dropdown.label.completed_sessions", defaultValue: "Sessions")
                )

                statCard(
                    value: "\(todayStats.alertCount)",
                    label: localizedAppString("menu.dropdown.label.alerts", defaultValue: "Alerts")
                )

                statCard(
                    value: "\(whitelistCount)",
                    label: localizedAppString("menu.dropdown.label.whitelist_apps", defaultValue: "Whitelist")
                )
            }
        }
        .padding(NudgeWhipSpacing.s4)
        .background(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .fill(Color.nudgewhipBgSurface.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
        )
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .lineLimit(2)

            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NudgeWhipSpacing.s3)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.92), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default, style: .continuous))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        return localizedDurationString(duration)
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}
