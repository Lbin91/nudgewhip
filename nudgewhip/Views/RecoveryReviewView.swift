import SwiftUI

struct RecoveryReviewView: View {
    @State private var selectedPeriod: RecoveryPeriod = .thisWeek
    @State private var events: [RecoveryEvent] = []
    @State private var summary: RecoverySummary?
    @State private var hourlyCounts: [Int] = Array(repeating: 0, count: 24)

    private let service: RecoveryReviewService

    init(service: RecoveryReviewService) {
        self.service = service
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                Text(localizedAppString("recovery.review.title", defaultValue: "Recovery Review"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextPrimary)

                Text(localizedAppString("recovery.review.description", defaultValue: "See how quickly you recover from distractions and when they happen most."))
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }

            Picker("", selection: $selectedPeriod) {
                ForEach(RecoveryPeriod.allCases) { period in
                    Text(period.title).tag(period)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            let hasData = events.isEmpty == false

            if hasData {
                summaryCards
                HourlyHeatmapView(hourlyCounts: hourlyCounts)
                RecoveryTimelineView(events: events)
            } else {
                emptyState
            }
        }
        .onAppear { loadData() }
        .onChange(of: selectedPeriod) { loadData() }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: NudgeWhipSpacing.s2),
            GridItem(.flexible(), spacing: NudgeWhipSpacing.s2)
        ], spacing: NudgeWhipSpacing.s2) {
            summaryMetricCard(
                title: localizedAppString("recovery.review.metric.fastest", defaultValue: "Fastest recovery"),
                value: formattedDuration(summary?.fastestRecovery)
            )
            summaryMetricCard(
                title: localizedAppString("recovery.review.metric.longest", defaultValue: "Longest distraction"),
                value: formattedDuration(summary?.longestDistraction)
            )
            summaryMetricCard(
                title: localizedAppString("recovery.review.metric.peak_hour", defaultValue: "Peak distraction"),
                value: formattedHour(summary?.mostDistractedHour)
            )
        }
    }

    private func summaryMetricCard(title: String, value: String) -> some View {
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
        .background(Color.nudgewhipBgSurfaceAlt, in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            Text(localizedAppString("recovery.review.empty.title", defaultValue: "No recovery data yet"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)

            Text(localizedAppString("recovery.review.empty.body", defaultValue: "Once nudges trigger and you recover focus, your recovery patterns will appear here."))
                .font(.caption)
                .foregroundStyle(Color.nudgewhipTextMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NudgeWhipSpacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.6), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private func loadData() {
        events = service.fetchEvents(for: selectedPeriod)
        summary = service.fetchSummary(for: selectedPeriod)
        hourlyCounts = service.fetchHourlyCounts(for: selectedPeriod)
    }

    private func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else {
            return localizedAppString("recovery.review.value.none", defaultValue: "—")
        }
        return localizedDurationString(duration)
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }

    private func formattedHour(_ hour: Int?) -> String {
        guard let hour else {
            return localizedAppString("recovery.review.value.none", defaultValue: "—")
        }
        var components = DateComponents()
        components.hour = hour
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return "\(hour):00" }
        let formatter = DateFormatter()
        formatter.locale = appDisplayLocale()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
}
