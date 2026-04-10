import SwiftUI

private enum StatisticsDisplayPeriod: String, CaseIterable, Identifiable {
    case today
    case thisWeek
    case last7Days

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return localizedAppString("settings.section.statistics.period.today", defaultValue: "Today")
        case .thisWeek:
            return localizedAppString("settings.section.statistics.period.this_week", defaultValue: "This week")
        case .last7Days:
            return localizedAppString("settings.section.statistics.period.last_7_days", defaultValue: "Last 7 days")
        }
    }
}

struct StatisticsDashboardView: View {
    let snapshot: StatisticsSnapshot

    @State private var selectedPeriod: StatisticsDisplayPeriod = .thisWeek

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                Text(localizedAppString("settings.section.statistics.title", defaultValue: "Statistics"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextPrimary)

                Text(localizedAppString("settings.section.statistics.desc", defaultValue: "Check whether nudges are helping you recover focus, not just how often they appear."))
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }

            Picker("", selection: $selectedPeriod) {
                ForEach(StatisticsDisplayPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if selectedSummary.hasData {
                LazyVGrid(columns: summaryColumns, spacing: NudgeWhipSpacing.s2) {
                    metricCard(
                        title: localizedAppString("settings.section.statistics.metric.focus", defaultValue: "Focus"),
                        value: localizedDurationString(selectedSummary.totalFocusDuration)
                            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
                    )
                    metricCard(
                        title: localizedAppString("settings.section.statistics.metric.alerts", defaultValue: "Alerts"),
                        value: "\(selectedSummary.alertCount)"
                    )
                    metricCard(
                        title: localizedAppString("settings.section.statistics.metric.recovery", defaultValue: "Recovery"),
                        value: localizedPercentString(selectedSummary.recoveryRate)
                    )
                    metricCard(
                        title: localizedAppString("settings.section.statistics.metric.longest", defaultValue: "Longest focus"),
                        value: localizedDurationString(selectedSummary.longestFocusDuration)
                            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
                    )
                }

                HStack(alignment: .top, spacing: NudgeWhipSpacing.s4) {
                    chartCard
                    detailCard
                }
            } else {
                emptyState
            }
        }
    }

    private let summaryColumns = [
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2),
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2)
    ]

    private var selectedSummary: StatisticsPeriodSummary {
        switch selectedPeriod {
        case .today:
            return .aggregate([snapshot.today])
        case .thisWeek:
            return snapshot.thisWeek
        case .last7Days:
            return snapshot.last7Days
        }
    }

    private var selectedDays: [DailyStats] {
        switch selectedPeriod {
        case .today:
            return [snapshot.today]
        case .thisWeek:
            return snapshot.thisWeek.days
        case .last7Days:
            return snapshot.last7Days.days
        }
    }

    private var chartMaxDuration: TimeInterval {
        max(selectedDays.map(\.totalFocusDuration).max() ?? 0, 1)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("settings.section.statistics.chart.title", defaultValue: "Focus trend"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            HStack(alignment: .bottom, spacing: NudgeWhipSpacing.s2) {
                ForEach(selectedDays, id: \.dayStart) { day in
                    VStack(spacing: NudgeWhipSpacing.s2) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(day.totalFocusDuration > 0 ? Color.nudgewhipFocus : Color.nudgewhipStrokeDefault.opacity(0.45))
                            .frame(width: 22, height: max(10, CGFloat(day.totalFocusDuration / chartMaxDuration) * 96))

                        Text(localizedWeekdayLabel(for: day.dayStart))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .bottom)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NudgeWhipSpacing.s4)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("settings.section.statistics.detail.title", defaultValue: "Recovery loop"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            detailRow(
                title: localizedAppString("settings.section.statistics.metric.sessions", defaultValue: "Sessions"),
                value: "\(selectedSummary.completedSessionCount)"
            )
            detailRow(
                title: localizedAppString("settings.section.statistics.metric.avg_recovery", defaultValue: "Avg recovery"),
                value: localizedDurationString(selectedSummary.averageRecoveryDuration)
                    ?? localizedAppString("settings.section.statistics.value.no_recovery", defaultValue: "No recoveries yet")
            )
            detailRow(
                title: localizedAppString("settings.section.statistics.metric.recovered_alerts", defaultValue: "Recovered alerts"),
                value: "\(selectedSummary.recoverySampleCount)"
            )
        }
        .frame(maxWidth: 220, alignment: .leading)
        .padding(NudgeWhipSpacing.s4)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            Text(localizedAppString("settings.section.statistics.empty.title", defaultValue: "No focus history yet"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)

            Text(localizedAppString("settings.section.statistics.empty.body", defaultValue: "Once you complete a few monitored sessions, focus time, alerts, and recovery trends will appear here."))
                .font(.caption)
                .foregroundStyle(Color.nudgewhipTextMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NudgeWhipSpacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.6), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextMuted)

            Text(value)
                .font(.headline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NudgeWhipSpacing.s3)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextMuted)

            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .minimumScaleFactor(0.8)
        }
    }
}
