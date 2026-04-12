# Statistics Dashboard Data Selection — Review

- Reviewed document: `docs/app/statistics-dashboard-data-selection.md` (draft-1, 2026-04-12)
- Review date: 2026-04-12
- Review type: code–document cross-reference

## 1. 정합성이 확인된 항목

| 항목 | 상태 |
|------|------|
| FocusSession 필드 10개 (startedAt ~ createdAt) | 코드와 일치 |
| AlertingSegment 필드 3개 (startedAt, recoveredAt, maxEscalationStep) | 코드와 일치 |
| AppUsageSegment 핵심 필드 6개 | 코드와 일치 (단 `createdAt` 누락, 아래 참조) |
| DailyStats 파생 계산 항목 (recoveryRate, averageRecoveryDuration 등) | 코드와 일치 |
| StatisticsSnapshot의 today / thisWeek / last7Days 구조 | 코드와 일치 |
| AppUsageSnapshot의 top 3 apps, primary app, transitionCount | 코드와 일치 |
| "window title, URL, typed content 수집 안 함" 명시 | 코드와 일치 |
| 대시보드 KPI 4개 (Focus, Alerts, Recovery, Longest focus) | `StatisticsDashboardView`와 완전 일치 |

## 2. 보강 포인트

### 2.1 🔴 AppUsageSegment에 `createdAt` 필드 누락

원문 §3.3에서 AppUsageSegment 필드를 6개로 나열했으나, 실제로는 7개입니다.

```swift
// AppUsageSegment.swift L11
var createdAt: Date
```

FocusSession에서는 `createdAt`을 명시했으므로, 일관성을 위해 추가해야 합니다.

**권장**: §3.3 "현재 저장 중인 정보" 목록에 `레코드 생성 시각 createdAt` 추가.

### 2.2 🔴 `endReason` vs `endReasonRawValue` 필드명 불일치

원문 §3.1에 "세션 종료 사유 `endReason`"이라고 기술했지만, 실제 SwiftData 저장 필드는 `endReasonRawValue: String?`입니다. `endReason`은 computed property입니다.

```swift
// FocusSession.swift L28
var endReasonRawValue: String?  // ← 실제 저장 필드

// FocusSession.swift L38-46
var endReason: FocusSessionEndReason? { ... }  // ← computed property
```

문서의 서문이 "코드 기준으로 정리한다"이므로, 실제 필드명을 명시하거나 computed임을 각주로 남겨야 합니다.

**권장**: `세션 종료 사유 endReasonRawValue (→ endReason computed)` 형태로 병기.

### 2.3 🟡 FocusSession 관계 필드 미기재

FocusSession에는 SwiftData relationship 필드가 2개 있습니다.

```swift
// FocusSession.swift L32-35
var alertingSegments: [AlertingSegment] = []
var appUsageSegments: [AppUsageSegment] = []
```

원문 §3.1 "현재 저장 중인 정보"에 이 관계 필드가 빠져 있습니다. §3.2, §3.3에서 각각 다루긴 하지만, §3.1 관점에서 누락은 정보 목록의 완전성을 떨어뜨립니다.

**권장**: §3.1에 "관계 필드: alertingSegments, appUsageSegments" 항목 추가.

### 2.4 🟡 `FocusSessionEndReason` enum 값 미기재

원문 §3.1에서 "세션 종료 사유"를 언급하면서, enum이 가진 5개 case를 명시하지 않았습니다.

```swift
enum FocusSessionEndReason: String, Codable, CaseIterable, Sendable {
    case completed
    case idleTimeout
    case manualPause
    case whitelistPause
    case suspended
}
```

§4.2에서 "종료 사유 분포"를 보조 지표로, §7에서 "endReason 기반 회고 카드"를 확장 후보로 언급하므로, 가능한 값을 명시해두면 후속 구현에 도움이 됩니다.

**권장**: §3.1에 가능한 종료 사유 값 목록 추가.

### 2.5 🟡 `contributesToFocusTotals` 필터 조건 누락

원문 §3.1에 "이 데이터로 이미 계산 가능한 것"으로 총 집중 시간, 완료 세션 수 등을 나열했지만, 어떤 세션이 통계에 포함되는지에 대한 핵심 필터 조건이 빠져 있습니다.

```swift
// FocusSession.swift L55-57
var contributesToFocusTotals: Bool {
    monitoringActive && !breakMode && !whitelistedPause && endedAt != nil
}
```

이 조건은 `DailyStats.derive()` → `focusDuration(overlapping:)` 경로로 사용되며, 대시보드 수치가 어떻게 걸러지는지 이해하는 데 필수적입니다.

**권장**: §3.1에 "통계 포함 조건" 항목 추가.

### 2.6 🟡 `StatisticsPeriodSummary`에 `recoveryDurationMax` 없음

원문 §3.4에 "현재 계산 중인 정보"를 나열하면서 최장 복귀 시간을 포함했지만, `StatisticsPeriodSummary` 구조체에는 `recoveryDurationMax` 필드가 없습니다.

```swift
// DailyStats.swift L85-119 — StatisticsPeriodSummary
// recoveryDurationMax 필드 없음
```

반면 `DailyStats`에는 `recoveryDurationMax`가 있습니다. 원문 §4.2에서 "최장 복귀 시간"을 보조 지표로 분류하긴 했지만, "현재 계산 중"이라는 §3.4 기술과 달리 주간/7일 집계에서는 실제로 계산되지 않습니다.

**권장**: §3.4에서 "최장 복귀 시간"을 DailyStats(today only)로 한정 명시하거나, 또는 `StatisticsPeriodSummary` 확장 후보로 이동.

### 2.7 🟢 §3.3 소스 경로에 `AppUsageSnapshot.swift` 혼재

원문 §3.3에 AppUsageSegment의 소스로 `AppUsageSnapshot.swift`를 포함했지만, 이 파일은 계산/파생 로직이지 저장 모델이 아닙니다. §3.3 "현재 저장 중인 정보"와 §3.4 "파생 통계 스냅샷"의 소스 구분이 모호합니다.

**권장**: §3.3 소스에서 `AppUsageSnapshot.swift`를 제거하고 §3.4에만 배치.

## 3. 요약

| 심각도 | 항목 | 권장 |
|--------|------|------|
| 🔴 | AppUsageSegment `createdAt` 누락 | §3.3 필드 목록에 추가 |
| 🔴 | `endReason` vs `endReasonRawValue` 불일치 | 실제 필드명 병기 또는 computed임 명시 |
| 🟡 | FocusSession 관계 필드 누락 | §3.1에 `alertingSegments`, `appUsageSegments` 추가 |
| 🟡 | `FocusSessionEndReason` enum 값 미기재 | 5개 case 명시 |
| 🟡 | `contributesToFocusTotals` 필터 조건 누락 | 통계 포함 조건 설명 추가 |
| 🟡 | `StatisticsPeriodSummary`에 `recoveryDurationMax` 없음 | "계산 중" 주장과 불일치 → 한정 명시 필요 |
| 🟢 | §3.3 소스 경로에 AppUsageSnapshot 혼재 | §3.4로 이동 |
