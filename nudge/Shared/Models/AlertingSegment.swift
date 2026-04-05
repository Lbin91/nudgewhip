// AlertingSegment.swift
// alerting → recovery 구간을 추적하는 SwiftData 모델.
//
// 사용자가 idle 임계값을 초과해 alerting 상태에 진입한 시점부터
// 활동을 감지해 recovery로 전환되는 시점까지의 구간을 기록한다.
// DashboardDayProjection의 recoveryDurationTotal/Max/SampleCount 계산 근거.

import Foundation
import SwiftData

@Model
final class AlertingSegment {
    /// alerting 상태에 진입한 시각
    var startedAt: Date

    /// 사용자 활동 감지로 recovery 전환된 시각. nil이면 아직 alerting 중이거나 세션 종료로 미복구
    var recoveredAt: Date?

    /// alerting 중 도달한 최대 에스컬레이션 단계 (1=idleDetected, 2=gentleNudge, 3=strongNudge)
    var maxEscalationStep: Int

    /// 부모 FocusSession (inverse relationship)
    var focusSession: FocusSession?

    /// 복구까지 걸린 시간(초). recoveredAt이 nil이면 nil
    var duration: TimeInterval? {
        guard let recoveredAt else { return nil }
        return recoveredAt.timeIntervalSince(startedAt)
    }

    init(
        startedAt: Date,
        recoveredAt: Date? = nil,
        maxEscalationStep: Int = 1,
        focusSession: FocusSession? = nil
    ) {
        self.startedAt = startedAt
        self.recoveredAt = recoveredAt
        self.maxEscalationStep = maxEscalationStep
        self.focusSession = focusSession
    }
}
