import Foundation

struct DailyStats: Equatable, Sendable {
    let dayStart: Date
    let totalFocusDuration: TimeInterval
    let alertCount: Int
    let ttsCount: Int
    let longestFocusDuration: TimeInterval
    let completedSessionCount: Int
    
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
        
        return DailyStats(
            dayStart: dayInterval.start,
            totalFocusDuration: sessionsWithFocus.reduce(0) { $0 + $1.1 },
            alertCount: sessionsWithFocus.reduce(0) { $0 + $1.0.alertCount },
            ttsCount: sessionsWithFocus.reduce(0) { $0 + $1.0.ttsCount },
            longestFocusDuration: sessionsWithFocus.map(\.1).max() ?? 0,
            completedSessionCount: sessionsWithFocus.count
        )
    }
}
