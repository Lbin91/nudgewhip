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
                guard let recoveredAt = segment.recoveredAt else { return false }
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
