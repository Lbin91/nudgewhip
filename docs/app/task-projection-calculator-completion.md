# Nudge Task: iOS Companion 앱 Dashboard Projection Calculator 완료 계획서

- Version: 1.0
- Last Updated: 2026-04-18
- Status: active
- Owner: engineering

## 1. 개요

### 1.1 현재 상태

`DailyAggregateProjectionBuilder`가 이미 구현되어 있으며, 대부분의 필드 계산 로직이 작동 중입니다. 현재 구현된 기능:

- `recoverySampleCount`: AlertingSegment 중 `recoveredAt != nil`인 것의 개수 계산 완료
- `recoveryDurationTotalSeconds`: recovery duration 합산 완료
- `sessionsOver30mCount`: 세션 전체 duration이 1800초 초과인 세션 수 계산 완료
- `hourlyAlertCounts[24]`: alert 발생 시각 기준 24시간 분포 계산 완료
- cross-midnight session 처리: `FocusSession.focusDuration(overlapping:)`으로 교집합 분할 계산 완료

### 1.2 보강이 필요한 이유

`task-ios-dashboard-data-schema.md` §10.3에 정의된 필드 중 **`remoteEscalationRecoveredWithinWindowCount`**가 아직 구현되지 않았습니다. 이 필드는 iOS companion 앱의 Pro 기능(Alerts 탭)에서 원격 에스컬레이션 효과성 측정에 핵심적으로 사용됩니다.

### 1.3 영향받는 파일 목록

**변경 필요:**
- `nudgewhip/Shared/Models/DashboardDayProjectionPayload.swift` — 새 필드 추가
- `nudgewhip/Shared/Models/RemoteEscalationEvent.swift` — 신규 모델 생성 (없음)
- `nudgewhip/Shared/Services/DailyAggregateProjectionBuilder.swift` — 계산 로직 추가
- `nudgewhip/Shared/Services/CloudKitDailyAggregateBackupWriter.swift` — CloudKit 매핑 추가

**참조만 필요:**
- `nudgewhip/Shared/Models/AlertingSegment.swift` — recoveredAt 확인
- `nudgewhip/Shared/Models/FocusSession.swift` — focusDuration(overlapping:) 메서드
- `nudgewhip/Shared/Models/UserSettings.swift` — recovery window 설정값 (별도 확인 필요)
- `docs/architecture/cloudkit-daily-aggregate-backup.md` — CloudKit 스키마 정의

---

## 2. 미해결 계산 규칙 분석

### 2.1 이미 구현된 항목 (검증 테스트 필요)

#### `recoverySampleCount`
- **구현 상태**: 완료
- **코드 위치**: `DailyAggregateProjectionBuilder.swift` 79행
- **계산 방식**: `recoveredSegments.count` — `recoveredAt != nil`인 AlertingSegment 개수
- **검증 필요**: 정상 케이스, 빈 데이터, recoveredAt 전체 nil인 케이스

#### `recoveryDurationTotalSeconds`
- **구현 상태**: 완료
- **코드 위치**: `DailyAggregateProjectionBuilder.swift` 80행
- **계산 방식**: `recoveryDurations.reduce(0, +).rounded()` — 각 복구 duration 합산
- **검증 필요**: 정상 케이스, 빈 데이터, duration이 0인 케이스

#### `sessionsOver30mCount`
- **구현 상태**: 완료
- **코드 위치**: `DailyAggregateProjectionBuilder.swift` 49-56행
- **계산 방식**: `session.duration > 1_800`인 세션 수 (정확히 1800초인 세션은 제외)
- **검증 필요**: 정확히 1800초인 세션이 제외되는지 확인

#### `hourlyAlertCounts[24]`
- **구현 상태**: 완료
- **코드 위치**: `DailyAggregateProjectionBuilder.swift` 60-66행
- **계산 방식**: `calendar.component(.hour, from: segment.startedAt)` 기준 24시간 분포
- **검증 필요**: 24칸인지, 시간대가 올바르게 분배되는지

### 2.2 미구현 항목

#### `remoteEscalationRecoveredWithinWindowCount`
- **구현 상태**: **미구현** — 본 계획서의 핵심 작업
- **필요성**: iOS companion Pro 기능, 원격 에스컬레이션 효과성 측정
- **우선순위**: 높음 (iOS companion 핵심 기능)

### 2.3 Cross-midnight Session 분할 규칙

#### `completedSessionCount`
- **구현 상태**: 완료
- **규칙**: 세션 **시작일**에 귀속
- **코드**: `dayInterval.contains(session.startedAt)`로 필터링 (38-44행)

#### `totalFocusDuration`
- **구현 상태**: 완료
- **규칙**: `focusDuration(overlapping:)`으로 교집합 분할 계산
- **코드**: 35-37행에서 `session.focusDuration(overlapping: dayInterval)` 합산

#### `longestFocusDuration`
- **구현 상태**: 완료
- **규칙**: 세션 전체 duration 기준, 하루 경계에서 잘린 세션이 longest가 될 수 있음
- **코드**: 45-48행에서 `session.focusDuration(overlapping: dayInterval)`의 최댓값

#### `sessionsOver30mCount`
- **구현 상태**: 완료
- **규칙**: 세션 전체 duration 기준, 시작일 귀속
- **코드**: 49-56행에서 `session.duration > 1_800` 확인

### 2.4 기타 참조 항목

#### Mac Sleep/Offline 중 Projection 누락 방지
- **상태**: 별도 문서(`task-sleep-preemptive-record.md`)에서 다룸
- **이 문서에서**: 참조만 하고 구현 범위에서 제외

---

## 3. `remoteEscalationRecoveredWithinWindowCount` 구현 계획

### 3.1 정의

remote escalation 이벤트 발생 후, UserSettings 기반 recovery window(기본 5분) 내에 사용자 활동이 감지되어 복구된 횟수를 집계합니다.

### 3.2 계산 방식

1. **데이터 소스**: `RemoteEscalationEvent` 레코드들 (아직 미구현 모델)
2. **기준 시점**: 각 `RemoteEscalationEvent.occurredAt`
3. **복구 확인 기간**: `occurredAt`부터 `UserSettings.recoveryWindowSeconds`까지 (기본 300초)
4. **복구 판정**: 해당 기간 내에 `userActivityDetected` 이벤트가 있었는지 확인
5. **집계**: 조건을 만족하는 `RemoteEscalationEvent` 개수

### 3.3 필요한 데이터 소스

| 데이터 소스 | 현재 상태 | 필요 작업 |
|-----------|---------|---------|
| `RemoteEscalationEvent` 모델 | 존재하지 않음 | 신규 생성 |
| `UserSettings.recoveryWindowSeconds` | 확인 필요 | 확인 및 기본값 정의 |
| `userActivityDetected` 이벤트 기록 | 확인 필요 | 기록 방식 확인 |

### 3.4 DashboardDayProjectionPayload 필드 추가 필요 여부

**현재 스키마 상태**: `DashboardDayProjectionPayload.swift`에 해당 필드 없음

**CloudKit 스키마 정의**: `cloudkit-daily-aggregate-backup.md` §15.4에 optional 필드로 정의됨

**결론**: 필드 추가 필요

추가할 필드:
```swift
let remoteEscalationSentCount: Int64
let remoteEscalationRecoveredWithinWindowCount: Int64
```

### 3.5 선행 작업 순서

1. `RemoteEscalationEvent` SwiftData 모델 생성
2. `RemoteEscalationEvent`를 저장/조회하는 Manager/Service 생성
3. `UserSettings`에 recoveryWindowSeconds 필드 확인/추가
4. `DailyAggregateProjectionBuilder`에 계산 로직 추가
5. `DashboardDayProjectionPayload`에 필드 추가
6. `CloudKitDailyAggregateBackupWriter`에 CloudKit 매핑 추가
7. 테스트 작성

---

## 4. 고려 사항

### 4.1 Timezone 변경 시 Projection 재계산 필요성

**정책**: 이미 계산된 historical day projection은 계산 당시 local timezone 기준 유지, 이후부터 새 timezone 사용

**구현 필요**: 없음 — 이미 `timeZoneIdentifier` 필드에 계산 기준 timezone 저장

**주의사항**:
- timezone 변경 시 과거 데이터를 재작성하지 않음
- 사용자가 "현재 timezone 기준으로 다시 보기"를 원하면 뷰 레벨에서 처리 (저장 키는 유지)

### 4.2 대량 FocusSession 조회 시 메모리 사용량

**현재 구현**: `modelContext.fetch(FetchDescriptor<FocusSession>())` — 전체 조회

**문제점**: 세션이 수천 개 이상이면 메모리 부하 가능

**개선 방안**:
- `FetchDescriptor`에 `predicate` 적용으로 범위 제한
- 예: `#Predicate<FocusSession> { $0.startedAt >= dayStart && $0.startedAt < dayEnd }`
- 하루 경계 전후 여유분(예: ±24시간)을 포함하여 cross-midnight 세션 누락 방지

**우선순위**: 중간 — MVP에서는 전체 조회 유지, 성능 이슈 발생 시 최적화

### 4.3 Projection 멱등성

**요구사항**: 같은 날에 여러 번 계산해도 같은 결과

**현재 구현**: 함수형 접근으로 이미 멱등성 보장 — 입력이 같으면 결과가 같음

**검증 필요**:
- 동일한 `referenceDate`와 `timeZoneIdentifier`로 여러 번 호출 시 동일한 결과 확인
- SwiftData에서 데이터가 추가되지 않은 상태에서 재계산 시 값이 변하지 않는지 확인

### 4.4 SwiftData 마이그레이션 영향

**상태**: 기존 `@Model` 변경 없음 — 새 모델(`RemoteEscalationEvent`)만 추가

**결론**: 마이그레이션 불필요 — 새 모델은 자동으로 스키마에 추가됨

---

## 5. Lifecycle

### 5.1 Projection 계산 트리거 시점

**현재 구현된 트리거**:
- 상태 전이 시 (alerting → recovery)
- 세션 종료 시
- 하루 경계 진입 시
- 앱 재시작/재동기화 시

**추가 필요 트리거**:
- remote escalation 발생 시 (iOS push 전송 후)
- remote escalation recovery 확인 시

### 5.2 CloudKit 업로드 타이밍

**현재 구현**: `DailyAggregateProjectionCoordinator`에서 projection 계산 직후 업로드

**구현 요약**:
1. `enqueueBackup(for: referenceDate)` — 백업 큐에 등록
2. `rebuildAndQueue(referenceDates:)` — projection 재계산
3. `outbox.upsert(payload)` — 로컬 아웃박스에 저장
4. `flushOutbox()` — CloudKit에 업로드

### 5.3 iOS 소비 타이밍

**예상 소비 시점**:
- Foreground fetch (앱 foreground 진입 시)
- Push notification 수신 후
- Background refresh (iOS 백그라운드 새로고침)

**데이터 흐름**:
```
Mac: 계산 → CloudKit 업로드 → iOS Push → iOS Fetch → iOS Dashboard 렌더링
```

---

## 6. 예외 처리

### 6.1 Timezone Identifier 무효 시

**현재 구현**: `makeCalendar(timeZoneIdentifier:)`에서 `DailyAggregateProjectionBuilderError.invalidTimeZoneIdentifier` throw

**처리 방식**: 이미 구현됨 — 에러를 호출자에게 전파

### 6.2 SwiftData Fetch 실패 시

**현재 구현**: `?? []`로 빈 배열 fallback

**코드 위치**: 26행, 32행
```swift
let sessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
let allSegments = (try? modelContext.fetch(FetchDescriptor<AlertingSegment>())) ?? []
```

**처리 방식**: 이미 구현됨 — 실패 시 빈 데이터로 계산 계속

### 6.3 Recovery Window 설정값 누락 시

**현재 상태**: `UserSettings.recoveryWindowSeconds` 확인 필요

**처리 방식**: 기본값 300초(5분) 사용

**구현 예시**:
```swift
let recoveryWindow = userSettings?.recoveryWindowSeconds ?? 300
```

### 6.4 FocusSession이 하루에 너무 많을 시

**현재 구현**: 전체 조회 후 필터링

**문제점**: 세션이 수천 개 이상이면 메모리 부하

**개선 방안**: `FetchDescriptor`에 `limit` 적용 검토

**예시**:
```swift
let descriptor = FetchDescriptor<FocusSession>(
    predicate: #Predicate<FocusSession> { session in
        session.startedAt >= dayStart.addingTimeInterval(-86400) &&
        session.startedAt <= dayEnd.addingTimeInterval(86400)
    },
    fetchLimit: 10_000
)
```

**우선순위**: 낮음 — MVP에서는 전체 조회 유지

---

## 7. 테스트 구현

### 7.1 정상 케이스

**테스트 이름**: `testBuildDayProjection_normalCase`

**Given**:
- FocusSession 3개 (각 30분, 45분, 60분)
- AlertingSegment 2개 (1개 복구됨, 1개 미복구)

**When**:
- `buildDayProjection` 호출

**Then**:
- `totalFocusDurationSeconds` = (30 + 45 + 60) × 60 = 8100
- `completedSessionCount` = 3
- `alertCount` = 2
- `recoverySampleCount` = 1
- `recoveryDurationTotalSeconds` = 복구된 세그먼트의 duration
- `sessionsOver30mCount` = 3 (모두 1800초 초과)

### 7.2 빈 데이터

**테스트 이름**: `testBuildDayProjection_emptyData`

**Given**:
- FocusSession 없음
- AlertingSegment 없음

**When**:
- `buildDayProjection` 호출

**Then**:
- `totalFocusDurationSeconds` = 0
- `completedSessionCount` = 0
- `alertCount` = 0
- `recoverySampleCount` = 0
- `recoveryDurationTotalSeconds` = 0
- `recoveryDurationMaxSeconds` = 0
- `sessionsOver30mCount` = 0
- `hourlyAlertCounts` = [0, 0, ..., 0] (24칸 모두 0)

### 7.3 Cross-midnight 세션

**테스트 이름**: `testBuildDayProjection_crossMidnight`

**Given**:
- Timezone: Asia/Seoul (UTC+9)
- FocusSession: 2026-04-13 23:30 ~ 2026-04-14 00:30 (60분)
- Reference date: 2026-04-13

**When**:
- `buildDayProjection` 호출 (referenceDate = 2026-04-13)

**Then**:
- `completedSessionCount` = 1 (시작일 귀속)
- `totalFocusDurationSeconds` = 30 × 60 = 1800 (23:30~00:00, 교집합 분할)
- `longestFocusDurationSeconds` = 1800 (하루 기준으로 잘린 부분)

### 7.4 Longest Focus Duration (하루 경계에서 잘림)

**테스트 이름**: `testBuildDayProjection_longestAtBoundary`

**Given**:
- Session A: 2026-04-13 10:00 ~ 10:30 (30분)
- Session B: 2026-04-13 23:45 ~ 2026-04-14 00:45 (60분)
- Reference date: 2026-04-13

**When**:
- `buildDayProjection` 호출 (referenceDate = 2026-04-13)

**Then**:
- `longestFocusDurationSeconds` = 15 × 60 = 900 (Session B의 23:45~00:00 부분)
- Session A(1800초)보다 Session B의 잘린 부분이 길더라도 longest가 될 수 있음

### 7.5 Hourly Alert Counts 분포

**테스트 이름**: `testBuildDayProjection_hourlyAlertDistribution`

**Given**:
- AlertingSegment 1: 2026-04-13 09:15 발생
- AlertingSegment 2: 2026-04-13 14:30 발생
- AlertingSegment 3: 2026-04-13 14:45 발생
- Timezone: Asia/Seoul

**When**:
- `buildDayProjection` 호출

**Then**:
- `hourlyAlertCounts[9]` = 1
- `hourlyAlertCounts[14]` = 2
- 나머지 21칸은 모두 0
- 전체 배열 길이 = 24

### 7.6 Recovery Sample Count

**테스트 이름**: `testBuildDayProjection_recoverySampleCount`

**Given**:
- AlertingSegment 1: `recoveredAt` = nil (미복구)
- AlertingSegment 2: `recoveredAt` = 2026-04-13 10:05 (복구됨)
- AlertingSegment 3: `recoveredAt` = 2026-04-13 11:20 (복구됨)

**When**:
- `buildDayProjection` 호출

**Then**:
- `recoverySampleCount` = 2 (`recoveredAt != nil`인 세그먼트만 카운트)

### 7.7 Sessions Over 30m Count

**테스트 이름**: `testBuildDayProjection_sessionsOver30m`

**Given**:
- Session A: duration = 1799초 (29분 59초)
- Session B: duration = 1800초 (정확히 30분)
- Session C: duration = 1801초 (30분 1초)
- Session D: duration = 3600초 (60분)

**When**:
- `buildDayProjection` 호출

**Then**:
- `sessionsOver30mCount` = 2 (Session C, Session D)
- Session A(1799초)와 Session B(1800초)는 제외 (`>` 연산자 사용)

---

## 8. 실패 테스트 구현

### 8.1 Timezone Identifier 무효 시 에러

**테스트 이름**: `testBuildDayProjection_invalidTimeZone`

**Given**:
- `timeZoneIdentifier` = "Invalid/Zone"

**When**:
- `buildDayProjection` 호출

**Then**:
- `DailyAggregateProjectionBuilderError.invalidTimeZoneIdentifier` throw
- 메시지에 "Invalid/Zone" 포함

### 8.2 모든 세션이 다른 날에 속할 때

**테스트 이름**: `testBuildDayProjection_noSessionsOnTargetDay`

**Given**:
- Session A: 2026-04-12 (어제)
- Session B: 2026-04-14 (내일)
- Reference date: 2026-04-13

**When**:
- `buildDayProjection` 호출

**Then**:
- `totalFocusDurationSeconds` = 0
- `completedSessionCount` = 0
- 모든 집계값이 0

### 8.3 AlertingSegment가 dayInterval 밖에 있을 때

**테스트 이름**: `testBuildDayProjection_segmentOutsideDay`

**Given**:
- AlertingSegment: 2026-04-12 23:59 발생
- Reference date: 2026-04-13
- Timezone: Asia/Seoul

**When**:
- `buildDayProjection` 호출

**Then**:
- `alertCount` = 0 (dayInterval 밖의 세그먼트는 제외)
- `hourlyAlertCounts` 모두 0

### 8.4 Session Duration이 음수인 경우 (방어적 처리)

**테스트 이름**: `testBuildDayProjection_negativeDuration`

**Given**:
- FocusSession: `startedAt` > `endedAt` (비정상)

**When**:
- `buildDayProjection` 호출

**Then**:
- 에러 없이 처리
- `FocusSession.duration`에서 `max(0, ...)`로 0으로 clamp됨
- `totalFocusDurationSeconds`에 영향 없음

### 8.5 Hourly Alert Counts 항상 24칸인지

**테스트 이름**: `testBuildDayProjection_hourlyAlertCountsSize`

**Given**:
- 아무 데이터 없음

**When**:
- `buildDayProjection` 호출

**Then**:
- `hourlyAlertCounts.count` = 24
- 모든 요소가 0

---

## 9. 완료 기준

- [ ] `RemoteEscalationEvent` SwiftData 모델 생성
- [ ] `DashboardDayProjectionPayload`에 `remoteEscalationSentCount`, `remoteEscalationRecoveredWithinWindowCount` 필드 추가
- [ ] `UserSettings.recoveryWindowSeconds` 확인 및 기본값(300초) 정의
- [ ] `DailyAggregateProjectionBuilder.buildDayProjection()`에 `remoteEscalationRecoveredWithinWindowCount` 계산 로직 추가
- [ ] `CloudKitDailyAggregateBackupWriter.record()`에 새 필드 CloudKit 매핑 추가
- [ ] §7의 모든 테스트 케이스 구현 및 통과
- [ ] §8의 모든 실패 테스트 케이스 구현 및 통과
- [ ] `xcodebuild test -scheme nudgewhip -destination 'platform=macOS' -only-testing:nudgewhipTests` 통과
- [ ] 빌드 성공 확인: `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'`
- [ ] LSP diagnostics clean on 모든 변경 파일
- [ ] 본 계획서에 명시된 모든 구현 항목 완료

---

## 10. 참고 문서

- `docs/app/task-ios-dashboard-data-schema.md` — 데이터 스키마 정의서, §10.3 미해결 계산 규칙
- `docs/architecture/cloudkit-daily-aggregate-backup.md` — CloudKit 백업 전략서, §15.3/15.4 스키마 정의
- `nudgewhip/Shared/Services/DailyAggregateProjectionBuilder.swift` — 현재 projection builder
- `nudgewhip/Shared/Models/DashboardDayProjectionPayload.swift` — projection 데이터 모델
- `nudgewhip/Shared/Models/AlertingSegment.swift` — alerting segment 모델
- `nudgewhip/Shared/Models/FocusSession.swift` — focus session 모델
- `nudgewhip/Shared/Services/CloudKitDailyAggregateBackupWriter.swift` — CloudKit writer
- `nudgewhip/Shared/Services/DailyAggregateProjectionCoordinator.swift` — coordinator

---

## 11. 부록: 구현 예시 코드

### A. RemoteEscalationEvent 모델 (신규 생성)

```swift
import Foundation
import SwiftData

@Model
final class RemoteEscalationEvent {
    var occurredAt: Date
    var macDeviceID: String
    var escalationStep: Int
    var contentStateRawValue: String
    var wasRecoveredWithinWindow: Bool?
    var recoveredAt: Date?
    var schemaVersion: Int

    init(
        occurredAt: Date,
        macDeviceID: String,
        escalationStep: Int = 1,
        contentStateRawValue: String = "IdleDetected",
        wasRecoveredWithinWindow: Bool? = nil,
        recoveredAt: Date? = nil,
        schemaVersion: Int = 1
    ) {
        self.occurredAt = occurredAt
        self.macDeviceID = macDeviceID
        self.escalationStep = escalationStep
        self.contentStateRawValue = contentStateRawValue
        self.wasRecoveredWithinWindow = wasRecoveredWithinWindow
        self.recoveredAt = recoveredAt
        self.schemaVersion = schemaVersion
    }
}
```

### B. DashboardDayProjectionPayload 필드 추가

```swift
// init 메서드에 추가
let remoteEscalationSentCount: Int64
let remoteEscalationRecoveredWithinWindowCount: Int64

// init 파라미터에 추가
remoteEscalationSentCount: Int64,
remoteEscalationRecoveredWithinWindowCount: Int64,
```

### C. DailyAggregateProjectionBuilder 계산 로직 추가

```swift
// buildDayProjection() 메서드 내 추가
let remoteEscalationEvents = (try? modelContext.fetch(FetchDescriptor<RemoteEscalationEvent>())) ?? []
let dayRemoteEvents = remoteEscalationEvents.filter { dayInterval.contains($0.occurredAt) }

// remoteEscalationRecoveredWithinWindowCount 계산
let recoveryWindow = Double(userSettings?.recoveryWindowSeconds ?? 300)
let remoteEscalationRecoveredWithinWindowCount = dayRemoteEvents.reduce(0) { partial, event in
    // 이미 복구 여부가 기록되어 있으면 사용
    if let wasRecovered = event.wasRecoveredWithinWindow {
        return partial + (wasRecovered ? 1 : 0)
    }

    // 기록이 없으면 recoveredAt으로 판단
    guard let recoveredAt = event.recoveredAt else {
        return partial
    }

    let recoveryTime = recoveredAt.timeIntervalSince(event.occurredAt)
    return partial + (recoveryTime <= recoveryWindow ? 1 : 0)
}

// return 문에 추가
remoteEscalationSentCount: Int64(dayRemoteEvents.count),
remoteEscalationRecoveredWithinWindowCount: Int64(remoteEscalationRecoveredWithinWindowCount),
```

### D. CloudKitDailyAggregateBackupWriter 매핑 추가

```swift
// record(for:) 메서드 내 추가
record["remoteEscalationSentCount"] = payload.remoteEscalationSentCount as CKRecordValue
record["remoteEscalationRecoveredWithinWindowCount"] = payload.remoteEscalationRecoveredWithinWindowCount as CKRecordValue
```

---

## 12. 개발 일정 추정

| 작업 | 예상 시간 | 의존성 |
|------|---------|--------|
| `RemoteEscalationEvent` 모델 생성 | 30분 | 없음 |
| `DashboardDayProjectionPayload` 필드 추가 | 15분 | 없음 |
| `UserSettings` 확인 | 15분 | 없음 |
| `DailyAggregateProjectionBuilder` 계산 로직 추가 | 2시간 | 위 3개 완료 후 |
| `CloudKitDailyAggregateBackupWriter` 매핑 추가 | 30분 | DashboardDayProjectionPayload 완료 후 |
| 테스트 작성 (정상 케이스 7개) | 2시간 | 계산 로직 완료 후 |
| 테스트 작성 (실패 케이스 5개) | 1시간 | 계산 로직 완료 후 |
| 빌드 및 테스트 통과 | 30분 | 모든 구현 완료 후 |
| **총합** | **약 7시간** | - |

---

**문서 끝**
