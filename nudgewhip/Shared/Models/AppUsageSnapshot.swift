import Foundation

enum AppUsagePeriod: CaseIterable, Sendable {
    case today
    case thisWeek
    case last7Days
}

struct AppUsageEntry: Equatable, Sendable {
    let bundleIdentifier: String?
    let localizedName: String
    let processIdentifier: Int32?
    let duration: TimeInterval
    let transitionCount: Int
}

struct AppUsageSnapshot: Equatable, Sendable {
    let todayTopApps: [AppUsageEntry]
    let thisWeekTopApps: [AppUsageEntry]
    let last7DaysTopApps: [AppUsageEntry]
    let todayPrimaryApp: AppUsageEntry?
    let thisWeekPrimaryApp: AppUsageEntry?
    let last7DaysPrimaryApp: AppUsageEntry?

    static let empty = AppUsageSnapshot(
        todayTopApps: [],
        thisWeekTopApps: [],
        last7DaysTopApps: [],
        todayPrimaryApp: nil,
        thisWeekPrimaryApp: nil,
        last7DaysPrimaryApp: nil
    )

    func topApps(for period: AppUsagePeriod) -> [AppUsageEntry] {
        switch period {
        case .today:
            return todayTopApps
        case .thisWeek:
            return thisWeekTopApps
        case .last7Days:
            return last7DaysTopApps
        }
    }

    func primaryApp(for period: AppUsagePeriod) -> AppUsageEntry? {
        switch period {
        case .today:
            return todayPrimaryApp
        case .thisWeek:
            return thisWeekPrimaryApp
        case .last7Days:
            return last7DaysPrimaryApp
        }
    }

    static func derive(
        for sessions: [FocusSession],
        on referenceDate: Date,
        calendar: Calendar = .current
    ) -> AppUsageSnapshot {
        let todayInterval = calendar.dateInterval(of: .day, for: referenceDate)
            ?? DateInterval(start: calendar.startOfDay(for: referenceDate), duration: 24 * 60 * 60)
        let thisWeekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
            ?? DateInterval(start: todayInterval.start, duration: 7 * 24 * 60 * 60)
        let trailingStart = calendar.date(byAdding: .day, value: -6, to: todayInterval.start) ?? todayInterval.start
        let last7DaysInterval = DateInterval(start: trailingStart, end: todayInterval.end)

        let todayTopApps = topApps(for: sessions, in: todayInterval, referenceDate: referenceDate)
        let thisWeekTopApps = topApps(for: sessions, in: thisWeekInterval, referenceDate: referenceDate)
        let last7DaysTopApps = topApps(for: sessions, in: last7DaysInterval, referenceDate: referenceDate)

        return AppUsageSnapshot(
            todayTopApps: todayTopApps,
            thisWeekTopApps: thisWeekTopApps,
            last7DaysTopApps: last7DaysTopApps,
            todayPrimaryApp: todayTopApps.first,
            thisWeekPrimaryApp: thisWeekTopApps.first,
            last7DaysPrimaryApp: last7DaysTopApps.first
        )
    }

    private static func topApps(
        for sessions: [FocusSession],
        in interval: DateInterval,
        referenceDate: Date
    ) -> [AppUsageEntry] {
        let groupedEntries = sessions
            .flatMap(\.appUsageSegments)
            .compactMap { segment in
                makeAccumulationEntry(from: segment, in: interval, referenceDate: referenceDate)
            }
            .reduce(into: [AppUsageAggregationKey: AppUsageAccumulation]()) { partialResult, entry in
                partialResult[entry.key, default: .init()].merge(entry.accumulation)
            }

        return groupedEntries
            .map { key, accumulation in
                AppUsageEntry(
                    bundleIdentifier: key.bundleIdentifier,
                    localizedName: key.localizedName,
                    processIdentifier: accumulation.processIdentifier,
                    duration: accumulation.duration,
                    transitionCount: accumulation.transitionCount
                )
            }
            .filter { $0.duration > 0 }
            .sorted { lhs, rhs in
                if lhs.duration == rhs.duration {
                    return lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
                }
                return lhs.duration > rhs.duration
            }
            .prefix(3)
            .map { $0 }
    }

    private static func makeAccumulationEntry(
        from segment: AppUsageSegment,
        in interval: DateInterval,
        referenceDate: Date
    ) -> (key: AppUsageAggregationKey, accumulation: AppUsageAccumulation)? {
        let segmentEnd = max(segment.startedAt, segment.endedAt ?? referenceDate)
        let segmentInterval = DateInterval(start: segment.startedAt, end: segmentEnd)
        guard let overlap = segmentInterval.intersection(with: interval), overlap.duration > 0 else {
            return nil
        }

        let localizedName = segment.localizedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = localizedName?.isEmpty == false
            ? localizedName!
            : localizedAppString("settings.section.statistics.top_apps.unknown", defaultValue: "Unknown App")

        return (
            key: AppUsageAggregationKey(
                bundleIdentifier: segment.bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank,
                localizedName: displayName
            ),
            accumulation: AppUsageAccumulation(
                duration: overlap.duration,
                transitionCount: 1,
                processIdentifier: segment.processIdentifier
            )
        )
    }
}

private struct AppUsageAggregationKey: Hashable {
    let bundleIdentifier: String?
    let localizedName: String
}

private struct AppUsageAccumulation {
    var duration: TimeInterval = 0
    var transitionCount: Int = 0
    var processIdentifier: Int32?

    mutating func merge(_ other: AppUsageAccumulation) {
        duration += other.duration
        transitionCount += other.transitionCount
        processIdentifier = processIdentifier ?? other.processIdentifier
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
