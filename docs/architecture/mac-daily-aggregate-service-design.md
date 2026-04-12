# Mac Daily Aggregate Service Design

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: engineering
- Scope: macOS에서 local SwiftData truth를 local-day aggregate projection으로 계산하는 서비스 설계

## 1. Purpose

- 이 문서는 macOS 쪽에서 하루 단위 aggregate를 계산하는 전용 서비스 계층을 어떻게 둘지 정의한다.
- 목표는 현재의 `DailyStats.derive()` 같은 UI-oriented 계산과, 향후 CloudKit backup용 deterministic projection 계산을 분리하는 것이다.

## 2. Why a Dedicated Service Is Needed

현재 코드 기준:

- `DailyStats.derive()`는 UI 표시용 일간 통계를 계산한다
- `StatisticsSnapshot.derive()`는 today/thisWeek/last7Days 뷰 모델용 집계다

이 구조는 UI에는 충분하지만, Cloud backup에는 부족할 수 있다.

이유:

1. Cloud backup은 deterministic payload가 필요하다
2. field naming/serialization 규칙이 다르다
3. trigger timing(세션 종료, 자정 경계, 재실행) 책임이 필요하다
4. `DailyStats`는 값 타입 통계이지 Cloud projection 계약 타입이 아니다

따라서:

- UI 통계 계산
- Cloud backup projection 계산

을 분리하는 서비스가 필요하다.

## 3. Recommended Layering

### Source of Truth

- `SwiftData`
  - `FocusSession`
  - `AlertingSegment`
  - `UserSettings`
  - 기타 로컬 truth

### Projection Builder Layer

- `DailyAggregateProjectionBuilder`

책임:

- 특정 `referenceDate` / `timeZoneIdentifier` 기준으로
- local truth를 읽고
- deterministic `DashboardDayProjectionPayload`를 생성

### Delivery Layer

- `CloudKitDailyAggregateBackupWriter`

책임:

- payload를 CloudKit record로 저장

즉:

- **builder는 계산**
- **writer는 전달**

으로 분리한다.

## 4. Service Contract

권장 프로토콜:

```swift
protocol DailyAggregateProjectionBuilding {
    func buildDayProjection(
        macDeviceID: String,
        referenceDate: Date,
        timeZoneIdentifier: String
    ) throws -> DashboardDayProjectionPayload
}
```

권장 추가 API:

```swift
func buildProjection(
    macDeviceID: String,
    interval: DateInterval,
    timeZoneIdentifier: String
) throws -> DashboardDayProjectionPayload
```

의도:

- 일반 사용 경로는 `referenceDate`
- 테스트/특수 경로는 explicit `DateInterval`

## 5. Builder Inputs

필수 입력:

- `macDeviceID`
- `referenceDate`
- `timeZoneIdentifier`

내부 조회:

- `FocusSession`
- 필요 시 `UserSettings`

원칙:

- builder는 세션 lifecycle을 몰라도 된다
- builder는 **이미 저장된 truth를 읽어서 projection을 만든다**

## 6. Builder Outputs

출력 타입:

- `DashboardDayProjectionPayload`

필드:

- metadata
  - `macDeviceID`
  - `localDayKey`
  - `dayStart`
  - `timeZoneIdentifier`
  - `updatedAt`
  - `schemaVersion`
- aggregate
  - `totalFocusDurationSeconds`
  - `completedSessionCount`
  - `alertCount`
  - `longestFocusDurationSeconds`
  - `recoverySampleCount`
  - `recoveryDurationTotalSeconds`
  - `recoveryDurationMaxSeconds`
  - `sessionsOver30mCount`
  - `hourlyAlertCounts`

## 7. Internal Calculation Rules

## 7.1 Day Interval

builder는 `timeZoneIdentifier` 기준 local day interval을 만들어야 한다.

권장:

- `Calendar(identifier: .gregorian)`
- `calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current`
- `calendar.dateInterval(of: .day, for: referenceDate)`

즉, UI와 달리 `Calendar.current`에만 기대지 않고 **명시적 timezone 주입**이 더 안전하다.

## 7.2 Focus Duration

재사용:

- `FocusSession.focusDuration(overlapping:)`

원칙:

- duration metric은 overlap 기준 분할

## 7.3 Completed Session Count

현재 문서 기준 목표 규칙:

- 세션 시작일 귀속

즉:

- 단순히 overlap한 세션 수를 세지 않고
- `calendar.isDate(session.startedAt, inSameDayAs: referenceDate)` 기준을 써야 한다

비고:

- 현재 `DailyStats.derive()`는 이 점이 정확히 일치하지 않을 수 있으므로 builder에서 명시적으로 구현하는 편이 안전하다

## 7.4 Sessions Over 30 Minutes

규칙:

- 세션 전체 duration 기준
- 30분 초과이면 1건
- 시작일 귀속

## 7.5 Recovery Metrics

입력:

- `AlertingSegment`

규칙:

- `recoveredAt != nil`만 sample 대상
- startedAt가 해당 day에 속한 segment를 기준으로 집계
- `duration` 합/최대값 계산

## 7.6 Hourly Alert Counts

규칙:

- alert 발생 시각 기준
- local timezone 기준 hour bucket
- 항상 24칸 고정

권장 구현:

- `[Int](repeating: 0, count: 24)`
- 세션별 alert 발생 시각들을 순회해 hour index에 누적

주의:

- 현재 truth에 alert timestamp가 `lastAlertAt` 하나만으로 충분한지 점검 필요
- 부족하면 향후 alert event truth 보강 필요

## 8. Trigger Model

builder 자체는 pure-ish 계산 계층으로 두고, trigger는 상위 coordinator가 담당한다.

권장 상위 계층:

- `DailyAggregateProjectionCoordinator`

책임:

- 세션 종료 시 builder 호출
- recovery 종료 시 builder 호출
- 자정 경계 시 전일 finalize
- foreground/launch 시 최근 day 재계산

즉:

- builder는 stateless/deterministic
- coordinator가 lifecycle/trigger를 담당

## 9. Suggested File Layout

### Primary

- `nudgewhip/Shared/Models/DashboardDayProjectionPayload.swift`
- `nudgewhip/Shared/Services/DailyAggregateProjectionBuilder.swift`

### Secondary

- `nudgewhip/Shared/Services/DailyAggregateProjectionCoordinator.swift`
- `nudgewhip/Shared/Services/CloudKitDailyAggregateBackupWriter.swift`

### Existing read-only dependencies

- `nudgewhip/Shared/Models/DailyStats.swift`
- `nudgewhip/Shared/Models/FocusSession.swift`
- `nudgewhip/Shared/Models/AlertingSegment.swift`
- `nudgewhip/Shared/Persistence/NudgeWhipModelContainer.swift`

## 10. Determinism Rules

builder는 같은 입력 truth에 대해 항상 같은 payload를 내야 한다.

즉:

- local truth가 같으면
- field 값
- `localDayKey`
- `hourlyAlertCounts`

이 모두 동일해야 한다

예외:

- `updatedAt`만 계산 시점에 따라 다를 수 있다

권장:

- 테스트에서는 `updatedAtProvider` 주입 가능하게 설계

## 11. Testing Strategy

필수 테스트:

- local day interval 생성
- cross-midnight session 분할
- completedSessionCount 시작일 귀속
- recovery metrics 집계
- empty day payload
- timezoneIdentifier 반영
- deterministic localDayKey 생성

## 12. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| UI용 `DailyStats`와 backup projection 값이 어긋남 | 사용자 혼란 | builder와 UI 통계 간 공용 helper 재사용 또는 비교 테스트 추가 |
| alert truth 부족으로 `hourlyAlertCounts` 계산이 부정확 | schema는 있는데 값이 허술함 | 1차에서 field를 optional로 두거나 local alert truth 보강 작업 병행 |
| coordinator가 너무 많은 lifecycle 책임을 가짐 | 복잡도 증가 | builder/coordinator/writer 책임 분리 |
| timezone을 `Calendar.current`에 맡기면 비결정성 발생 | 수치 흔들림 | explicit timezone 주입 |

## 13. Recommended First-pass Design

가장 안전한 1차 구현:

- `DashboardDayProjectionPayload`
- `DailyAggregateProjectionBuilder`
- explicit timezone 기반 local day interval 계산
- `completedSessionCount` 시작일 귀속을 builder에서 명시 구현
- `hourlyAlertCounts`는 truth가 충분하면 포함, 부족하면 optional 처리

## 14. Bottom Line

- Cloud backup 구현의 핵심은 CloudKit 자체보다 **Mac에서 믿을 수 있는 일간 projection을 안정적으로 계산하는 것**이다.
- 따라서 먼저 필요한 것은 거대한 Cloud layer가 아니라,
- **deterministic local-day projection builder + coordinator**다.
