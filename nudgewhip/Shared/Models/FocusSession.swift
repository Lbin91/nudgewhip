// FocusSession.swift
// 개별 포커스 세션을 기록하는 SwiftData 모델.
//
// 세션 시작/종료 시각, 모니터링·휴식·화이트리스트 상태,
// 알림·복구 횟수를 추적한다. 특정 시간 구간과의 겹침 계산도 지원한다.

import Foundation
import SwiftData

enum FocusSessionEndReason: String, Codable, CaseIterable, Sendable {
    case completed
    case idleTimeout
    case manualPause
    case whitelistPause
    case suspended
}

@Model
final class FocusSession {
    var startedAt: Date
    var endedAt: Date?
    var monitoringActive: Bool
    var breakMode: Bool
    var whitelistedPause: Bool
    var alertCount: Int
    var recoveryCount: Int
    var lastAlertAt: Date?
    var endReasonRawValue: String?
    var createdAt: Date

    /// alerting → recovery 구간 기록. SwiftData 자동 relationship
    var alertingSegments: [AlertingSegment] = []
    
    /// 종료 사유 로우 밸류 ↔ enum 편의 변환
    var endReason: FocusSessionEndReason? {
        get {
            guard let endReasonRawValue else { return nil }
            return FocusSessionEndReason(rawValue: endReasonRawValue)
        }
        set {
            endReasonRawValue = newValue?.rawValue
        }
    }
    
    /// 세션 지속 시간(초). 종료되지 않았으면 0 반환
    var duration: TimeInterval {
        guard let endedAt else { return 0 }
        return max(0, endedAt.timeIntervalSince(startedAt))
    }
    
    /// 통계 집계에 포함되는 유효 세션 여부 (모니터링 활성 + 휴식/화이트리스트 아님 + 종료됨)
    var contributesToFocusTotals: Bool {
        monitoringActive && !breakMode && !whitelistedPause && endedAt != nil
    }
    
    /// 세션 생성. 모니터링 활성 상태로 시작
    init(
        startedAt: Date,
        endedAt: Date? = nil,
        monitoringActive: Bool = true,
        breakMode: Bool = false,
        whitelistedPause: Bool = false,
        alertCount: Int = 0,
        recoveryCount: Int = 0,
        lastAlertAt: Date? = nil,
        endReason: FocusSessionEndReason? = nil,
        createdAt: Date = .now
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.monitoringActive = monitoringActive
        self.breakMode = breakMode
        self.whitelistedPause = whitelistedPause
        self.alertCount = alertCount
        self.recoveryCount = recoveryCount
        self.lastAlertAt = lastAlertAt
        self.endReasonRawValue = endReason?.rawValue
        self.createdAt = createdAt
    }
    
    /// 특정 시간 구간과 겹치는 포커스 시간(초) 계산
    func focusDuration(overlapping interval: DateInterval) -> TimeInterval {
        guard contributesToFocusTotals, let endedAt else { return 0 }
        let safeEnd = max(startedAt, endedAt)
        let sessionInterval = DateInterval(start: startedAt, end: safeEnd)
        guard let overlap = sessionInterval.intersection(with: interval) else { return 0 }
        return overlap.duration
    }
}
