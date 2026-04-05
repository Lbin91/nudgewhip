import SwiftUI

struct DailySummaryView: View {
    let todayStats: DailyStats
    let whitelistCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s3) {
            Text(localizedAppString("menu.dropdown.group.today", defaultValue: "Today"))
                .font(.caption)
                .foregroundStyle(Color.nudgeTextMuted)
                .textCase(.uppercase)
                .padding(.horizontal, NudgeSpacing.s4)

            HStack(spacing: NudgeSpacing.s3) {
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
            }

            HStack(spacing: NudgeSpacing.s3) {
                statCard(
                    value: "\(whitelistCount)",
                    label: localizedAppString("menu.dropdown.label.whitelist_apps", defaultValue: "Whitelist")
                )
            }
        }
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: NudgeSpacing.s1) {
            Text(value)
                .font(.title3.monospacedDigit())
                .foregroundStyle(Color.nudgeTextPrimary)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.nudgeTextMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(NudgeSpacing.s3)
        .background(Color.nudgeBgSurface)
        .clipShape(RoundedRectangle(cornerRadius: NudgeRadius.default))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeRadius.default)
                .stroke(Color.nudgeStrokeDefault, lineWidth: 1)
        )
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: max(duration, 0))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}
