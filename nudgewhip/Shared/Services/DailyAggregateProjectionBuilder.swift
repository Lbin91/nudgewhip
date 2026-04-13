import Foundation
import SwiftData

enum DailyAggregateProjectionBuilderError: Error, Equatable {
    case invalidTimeZoneIdentifier(String)
}

@MainActor
final class DailyAggregateProjectionBuilder {
    private let modelContext: ModelContext
    private let schemaVersion: Int64

    init(modelContext: ModelContext, schemaVersion: Int64 = 1) {
        self.modelContext = modelContext
        self.schemaVersion = schemaVersion
    }

    func buildDayProjection(
        macDeviceID: String,
        referenceDate: Date,
        timeZoneIdentifier: String,
        updatedAt: Date = .now
    ) throws -> DashboardDayProjectionPayload {
        let calendar = try makeCalendar(timeZoneIdentifier: timeZoneIdentifier)
        let dayInterval = try dayInterval(for: referenceDate, calendar: calendar)
        let sessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let relevantSessions = sessions.filter { session in
            session.focusDuration(overlapping: dayInterval) > 0 ||
            calendar.isDate(session.startedAt, inSameDayAs: referenceDate)
        }

        let allSegments = (try? modelContext.fetch(FetchDescriptor<AlertingSegment>())) ?? []
        let daySegments = allSegments.filter { dayInterval.contains($0.startedAt) }

        let totalFocusDuration = relevantSessions.reduce(0.0) { partial, session in
            partial + session.focusDuration(overlapping: dayInterval)
        }
        let completedSessionCount = relevantSessions.reduce(0) { partial, session in
            guard session.contributesToFocusTotals,
                  dayInterval.contains(session.startedAt) else {
                return partial
            }
            return partial + 1
        }
        let longestFocusDuration = relevantSessions.reduce(0.0) { partial, session in
            let duration = session.focusDuration(overlapping: dayInterval)
            return max(partial, duration)
        }
        let sessionsOver30mCount = relevantSessions.reduce(0) { partial, session in
            guard session.contributesToFocusTotals,
                  dayInterval.contains(session.startedAt),
                  session.duration > 1_800 else {
                return partial
            }
            return partial + 1
        }
        let recoveredSegments = daySegments.filter { $0.recoveredAt != nil }
        let recoveryDurations = recoveredSegments.compactMap(\.duration)

        var hourlyAlertCounts = Array(repeating: 0, count: 24)
        for segment in daySegments {
            let hour = calendar.component(.hour, from: segment.startedAt)
            if hourlyAlertCounts.indices.contains(hour) {
                hourlyAlertCounts[hour] += 1
            }
        }

        return DashboardDayProjectionPayload(
            macDeviceID: macDeviceID,
            localDayKey: Self.localDayKey(for: dayInterval.start, timeZoneIdentifier: timeZoneIdentifier, calendar: calendar),
            dayStart: dayInterval.start,
            timeZoneIdentifier: timeZoneIdentifier,
            updatedAt: updatedAt,
            schemaVersion: schemaVersion,
            totalFocusDurationSeconds: Int64(totalFocusDuration.rounded()),
            completedSessionCount: Int64(completedSessionCount),
            alertCount: Int64(daySegments.count),
            longestFocusDurationSeconds: Int64(longestFocusDuration.rounded()),
            recoverySampleCount: Int64(recoveryDurations.count),
            recoveryDurationTotalSeconds: Int64(recoveryDurations.reduce(0, +).rounded()),
            recoveryDurationMaxSeconds: Int64((recoveryDurations.max() ?? 0).rounded()),
            sessionsOver30mCount: Int64(sessionsOver30mCount),
            hourlyAlertCounts: hourlyAlertCounts,
            sourceWindowUTCStart: dayInterval.start,
            sourceWindowUTCEnd: dayInterval.end
        )
    }

    func dayInterval(for referenceDate: Date, calendar: Calendar) throws -> DateInterval {
        if let interval = calendar.dateInterval(of: .day, for: referenceDate) {
            return interval
        }
        throw DailyAggregateProjectionBuilderError.invalidTimeZoneIdentifier(calendar.timeZone.identifier)
    }

    func makeCalendar(timeZoneIdentifier: String) throws -> Calendar {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            throw DailyAggregateProjectionBuilderError.invalidTimeZoneIdentifier(timeZoneIdentifier)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    static func localDayKey(for dayStart: Date, timeZoneIdentifier: String, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: dayStart))@\(timeZoneIdentifier)"
    }
}
