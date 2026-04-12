// DailyStats.swift
// 하루 단위 집계 통계를 나타내는 값 타입.
//
// 총 포커스 시간, 알림 횟수, 최장 연속 포커스, 완료 세션 수를 보관한다.
// FocusSession 배열과 기준 날짜로부터 derive()로 자동 계산한다.

import Foundation

struct DailyStats: Equatable, Sendable {
    let dayStart: Date
    let totalFocusDuration: TimeInterval
    let alertCount: Int
    let longestFocusDuration: TimeInterval
    let completedSessionCount: Int

    // Recovery metrics — AlertingSegment에서 집계
    let recoverySampleCount: Int
    let recoveryDurationTotal: TimeInterval
    let recoveryDurationMax: TimeInterval

    var averageRecoveryDuration: TimeInterval {
        guard recoverySampleCount > 0 else { return 0 }
        return recoveryDurationTotal / Double(recoverySampleCount)
    }

    var recoveryRate: Double {
        guard alertCount > 0 else { return 0 }
        return Double(recoverySampleCount) / Double(alertCount)
    }

    var hasData: Bool {
        totalFocusDuration > 0 || alertCount > 0 || completedSessionCount > 0
    }

    static func empty(on referenceDate: Date, calendar: Calendar = .current) -> DailyStats {
        let dayStart = calendar.startOfDay(for: referenceDate)
        return DailyStats(
            dayStart: dayStart,
            totalFocusDuration: 0,
            alertCount: 0,
            longestFocusDuration: 0,
            completedSessionCount: 0,
            recoverySampleCount: 0,
            recoveryDurationTotal: 0,
            recoveryDurationMax: 0
        )
    }
    
    /// 세션 배열에서 특정 날짜의 통계를 집계해 DailyStats 생성
    static func derive(
        for sessions: [FocusSession],
        on referenceDate: Date,
        calendar: Calendar = .current
    ) -> DailyStats {
        let dayInterval = calendar.dateInterval(of: .day, for: referenceDate)
            ?? DateInterval(start: calendar.startOfDay(for: referenceDate), duration: 24 * 60 * 60)

        let sessionFocusDurations = sessions.map { session in
            session.focusDuration(overlapping: dayInterval)
        }
        let sessionsWithFocus = Array(zip(sessions, sessionFocusDurations))
            .filter { _, duration in duration > 0 }

        // AlertingSegment에서 recovery metrics 집계
        let recoveredSegments = sessions.flatMap(\.alertingSegments)
            .filter { segment in
                guard segment.recoveredAt != nil else { return false }
                return dayInterval.contains(segment.startedAt)
            }
        let recoveryDurations = recoveredSegments.compactMap(\.duration)

        return DailyStats(
            dayStart: dayInterval.start,
            totalFocusDuration: sessionsWithFocus.reduce(0) { $0 + $1.1 },
            alertCount: sessionsWithFocus.reduce(0) { $0 + $1.0.alertCount },
            longestFocusDuration: sessionsWithFocus.map(\.1).max() ?? 0,
            completedSessionCount: sessionsWithFocus.count,
            recoverySampleCount: recoveryDurations.count,
            recoveryDurationTotal: recoveryDurations.reduce(0, +),
            recoveryDurationMax: recoveryDurations.max() ?? 0
        )
    }
}

struct StatisticsPeriodSummary: Equatable, Sendable {
    let days: [DailyStats]
    let totalFocusDuration: TimeInterval
    let alertCount: Int
    let longestFocusDuration: TimeInterval
    let completedSessionCount: Int
    let recoverySampleCount: Int
    let recoveryDurationTotal: TimeInterval

    var averageRecoveryDuration: TimeInterval {
        guard recoverySampleCount > 0 else { return 0 }
        return recoveryDurationTotal / Double(recoverySampleCount)
    }

    var recoveryRate: Double {
        guard alertCount > 0 else { return 0 }
        return Double(recoverySampleCount) / Double(alertCount)
    }

    var hasData: Bool {
        days.contains(where: \.hasData)
    }

    static func aggregate(_ days: [DailyStats]) -> StatisticsPeriodSummary {
        StatisticsPeriodSummary(
            days: days,
            totalFocusDuration: days.reduce(0) { $0 + $1.totalFocusDuration },
            alertCount: days.reduce(0) { $0 + $1.alertCount },
            longestFocusDuration: days.map(\.longestFocusDuration).max() ?? 0,
            completedSessionCount: days.reduce(0) { $0 + $1.completedSessionCount },
            recoverySampleCount: days.reduce(0) { $0 + $1.recoverySampleCount },
            recoveryDurationTotal: days.reduce(0) { $0 + $1.recoveryDurationTotal }
        )
    }
}

struct StatisticsSnapshot: Equatable, Sendable {
    let today: DailyStats
    let thisWeek: StatisticsPeriodSummary
    let last7Days: StatisticsPeriodSummary

    static func derive(
        for sessions: [FocusSession],
        on referenceDate: Date,
        calendar: Calendar = .current
    ) -> StatisticsSnapshot {
        let today = DailyStats.derive(for: sessions, on: referenceDate, calendar: calendar)
        let todayStart = calendar.startOfDay(for: referenceDate)

        let thisWeekRange = dailyStatsRange(
            for: sessions,
            endingOn: referenceDate,
            dayCount: 7,
            calendar: calendar,
            alignment: .weekContainingReferenceDate
        )
        let last7DaysRange = dailyStatsRange(
            for: sessions,
            endingOn: referenceDate,
            dayCount: 7,
            calendar: calendar,
            alignment: .trailingDays
        )

        return StatisticsSnapshot(
            today: today,
            thisWeek: .aggregate(thisWeekRange.isEmpty ? [DailyStats.empty(on: todayStart, calendar: calendar)] : thisWeekRange),
            last7Days: .aggregate(last7DaysRange.isEmpty ? [DailyStats.empty(on: todayStart, calendar: calendar)] : last7DaysRange)
        )
    }

    private enum RangeAlignment {
        case weekContainingReferenceDate
        case trailingDays
    }

    private static func dailyStatsRange(
        for sessions: [FocusSession],
        endingOn referenceDate: Date,
        dayCount: Int,
        calendar: Calendar,
        alignment: RangeAlignment
    ) -> [DailyStats] {
        let startDate: Date
        switch alignment {
        case .weekContainingReferenceDate:
            let weekInterval = calendar.dateInterval(of: .weekOfYear, for: referenceDate)
            startDate = weekInterval?.start ?? calendar.startOfDay(for: referenceDate)
        case .trailingDays:
            let end = calendar.startOfDay(for: referenceDate)
            startDate = calendar.date(byAdding: .day, value: -(dayCount - 1), to: end) ?? end
        }

        return (0..<dayCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return DailyStats.derive(for: sessions, on: date, calendar: calendar)
        }
    }
}
