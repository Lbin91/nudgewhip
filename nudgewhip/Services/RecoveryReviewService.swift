// RecoveryReviewService.swift
// F1 Recovery Review — AlertingSegment + FocusSession 데이터를
// 프레젠테이션용 값 타입으로 변환하는 서비스.

import Foundation
import SwiftData

// MARK: - Value Types

struct RecoveryEvent: Identifiable, Sendable {
    let id: UUID
    let alertStartedAt: Date
    let recoveredAt: Date?
    let escalationStep: Int
    let recoveryDuration: TimeInterval? // nil = not recovered
    let sessionStart: Date
    let sessionEnd: Date?
}

struct RecoverySummary: Sendable {
    let fastestRecovery: TimeInterval?
    let longestDistraction: TimeInterval?
    let mostDistractedHour: Int? // 0–23
    let totalEvents: Int
    let recoveredCount: Int
    let unrecoveredCount: Int
}

// MARK: - Period

enum RecoveryPeriod: String, CaseIterable, Identifiable, Sendable {
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

    func dateInterval(calendar: Calendar = .current, referenceDate: Date = .now) -> DateInterval {
        switch self {
        case .today:
            if let interval = calendar.dateInterval(of: .day, for: referenceDate) {
                return interval
            }
            return DateInterval(start: calendar.startOfDay(for: referenceDate), duration: 86400)
        case .thisWeek:
            if let interval = calendar.dateInterval(of: .weekOfYear, for: referenceDate) {
                return interval
            }
            return DateInterval(start: calendar.startOfDay(for: referenceDate), duration: 86400)
        case .last7Days:
            let end = calendar.startOfDay(for: referenceDate)
            let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
            return DateInterval(start: start, end: calendar.date(byAdding: .day, value: 1, to: end) ?? end)
        }
    }
}

// MARK: - Service

@MainActor
final class RecoveryReviewService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? NudgeWhipModelContainer.shared.mainContext
    }

    // MARK: Fetch Events

    func fetchEvents(for period: RecoveryPeriod) -> [RecoveryEvent] {
        let interval = period.dateInterval()
        let segments = fetchSegments(in: interval)
        return segments.map { segment -> RecoveryEvent in
            let sessionStart = segment.focusSession?.startedAt ?? segment.startedAt
            let sessionEnd = segment.focusSession?.endedAt
            return RecoveryEvent(
                id: UUID(),
                alertStartedAt: segment.startedAt,
                recoveredAt: segment.recoveredAt,
                escalationStep: segment.maxEscalationStep,
                recoveryDuration: segment.duration,
                sessionStart: sessionStart,
                sessionEnd: sessionEnd
            )
        }
        .sorted { $0.alertStartedAt > $1.alertStartedAt }
    }

    // MARK: Fetch Summary

    func fetchSummary(for period: RecoveryPeriod) -> RecoverySummary {
        let interval = period.dateInterval()
        let segments = fetchSegments(in: interval)

        let recoveredDurations: [TimeInterval] = segments.compactMap { $0.duration }
        let fastestRecovery = recoveredDurations.min()
        let longestDistraction = computeLongestDistraction(from: segments, recoveredDurations: recoveredDurations)
        let hourlyCounts = computeHourlyCounts(from: segments)

        let mostDistractedHour: Int?
        if let maxCount = hourlyCounts.max(), maxCount > 0 {
            mostDistractedHour = hourlyCounts.firstIndex(of: maxCount)
        } else {
            mostDistractedHour = nil
        }

        let recoveredCount = recoveredDurations.count
        let unrecoveredCount = segments.count - recoveredCount

        return RecoverySummary(
            fastestRecovery: fastestRecovery,
            longestDistraction: longestDistraction,
            mostDistractedHour: mostDistractedHour,
            totalEvents: segments.count,
            recoveredCount: recoveredCount,
            unrecoveredCount: unrecoveredCount
        )
    }

    // MARK: Fetch Hourly Counts

    func fetchHourlyCounts(for period: RecoveryPeriod) -> [Int] {
        let interval = period.dateInterval()
        let segments = fetchSegments(in: interval)
        return computeHourlyCounts(from: segments)
    }

    // MARK: - Private

    private func fetchSegments(in interval: DateInterval) -> [AlertingSegment] {
        let descriptor = FetchDescriptor<AlertingSegment>(
            sortBy: [SortDescriptor(\AlertingSegment.startedAt, order: .forward)]
        )
        let allSegments = (try? modelContext.fetch(descriptor)) ?? []
        return allSegments.filter { interval.contains($0.startedAt) }
    }

    private func computeHourlyCounts(from segments: [AlertingSegment]) -> [Int] {
        let calendar = Calendar.current
        var counts = Array(repeating: 0, count: 24)
        for segment in segments {
            let hour = calendar.component(.hour, from: segment.startedAt)
            if counts.indices.contains(hour) {
                counts[hour] += 1
            }
        }
        return counts
    }

    /// longestDistraction: recovered가 없으면 현재까지 경과 시간을, 있으면 max duration 사용
    private func computeLongestDistraction(from segments: [AlertingSegment], recoveredDurations: [TimeInterval]) -> TimeInterval? {
        guard !segments.isEmpty else { return nil }

        var maxDuration: TimeInterval = 0
        var hasValue = false

        for segment in segments {
            if let duration = segment.duration {
                if duration > maxDuration { maxDuration = duration }
                hasValue = true
            } else {
                // Unrecovered — use elapsed time from alert start to now
                let elapsed = Date.now.timeIntervalSince(segment.startedAt)
                if elapsed > maxDuration { maxDuration = elapsed }
                hasValue = true
            }
        }

        return hasValue ? maxDuration : nil
    }
}
