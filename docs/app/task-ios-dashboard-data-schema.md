# Nudge Task: iOS Dashboard Data Schema & Alignment

- Version: draft-2
- Last Updated: 2026-04-04
- Status: active
- Owner: product / engineering

## 1. Purpose

- iOS dashboard가 구현 가능한 수준으로 schema, projection, 계산 규칙, CloudKit 경계를 고정한다.
- 목표는 `iOS가 raw event를 재구성하지 않고`, Mac이 계산한 읽기 최적화 projection을 안전하게 소비하도록 만드는 것이다.

## 2. Related Docs

- [ios-companion-prd.md](./ios-companion-prd.md)
- [ios-dashboard-screen-spec.md](./ios-dashboard-screen-spec.md)
- [spec.md](./spec.md)
- [cloudkit-sync-contract.md](../architecture/cloudkit-sync-contract.md)
- [cloudkit-daily-aggregate-backup.md](../architecture/cloudkit-daily-aggregate-backup.md)

## 3. Official Alignment Check

다음 공식 문서와 어긋나지 않도록 유지한다.

- App Review Guidelines
  [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- CloudKit 설계 기준
  [Designing with CloudKit](https://developer.apple.com/icloud/cloudkit/designing/)

반영 원칙:

- CloudKit은 app container 단위로 관리하고, 사용자별 데이터는 private database에 둔다.
- `MacState`와 dashboard projection은 관심사를 분리한다.
- production schema는 forward-compatible 하게 유지한다.
- app review를 위해 iOS app은 dashboard/demo mode 등 자체 utility를 설명할 수 있어야 한다.

## 4. Non-Negotiable Boundaries

- `MacState`는 최신 상태 동기화용 최소 metadata record다.
- `DashboardDayProjection`은 읽기용 aggregate record다.
- exact input event, mouse/keyboard timeline, screen contents, app usage text는 수집하지 않는다.
- iOS는 sync stream만으로 지표를 재구성하지 않는다.
- `frontmost app`, bundle ID history, push receipt/open attribution은 MVP에서 제외한다.
- Mac이 계산하고 CloudKit이 운반하며 iOS는 렌더링만 담당한다.

## 5. Docs Alignment

### 5.1 Required Checks

- [ ] `CloudKit은 최소 상태 전이 metadata 운반 계층` 문구가 [ios-companion-prd.md](./ios-companion-prd.md)와 [cloudkit-sync-contract.md](../architecture/cloudkit-sync-contract.md)에서 일치하는지 확인
- [ ] `Dashboard projection은 Mac 계산 read model` 문구가 [ios-companion-prd.md](./ios-companion-prd.md)와 [ios-dashboard-screen-spec.md](./ios-dashboard-screen-spec.md)에서 일치하는지 확인
- [ ] MVP 제외 항목(frontmost app, exact timeline, per-alert history) 문구 일치 확인
- [ ] `Remote Escalation Efficacy` 또는 유사 표현이 비인과/추정치 표현으로 유지되는지 확인

### 5.2 Completion Criteria

- 세 문서가 같은 데이터 경계를 설명한다.
- `iOS가 보여주는 것`과 `CloudKit이 저장하는 것`이 분리되어 설명된다.
- CloudKit이 analytics warehouse처럼 보이는 문장이 없다.

## 6. Dashboard Field Set Freeze

### 6.1 Derivable Now

현재 local source of truth만으로 비교적 바로 계산 가능한 필드:

- `dayStart`
- `updatedAt`
- `schemaVersion`
- `totalFocusDuration`
- `completedSessionCount`
- `alertCount`
- `longestFocusDuration`
- `timeZoneIdentifier`

### 6.2 Requires New Local Source Data

현재 shared model만으로는 durable local truth가 부족하거나 규칙 추가가 필요한 필드:

- `recoverySampleCount`
- `recoveryDurationTotal`
- `recoveryDurationMax`
- `sessionsOver30mCount`
- `hourlyAlertCounts[24]`
- `remoteEscalationSentCount`
- `remoteEscalationRecoveredWithinWindowCount`

규칙:

- 위 필드들은 MVP 목표에는 포함할 수 있지만, 구현 착수 전에 로컬 계산 근거를 먼저 보강해야 한다.
- iOS나 CloudKit 상태 스트림만으로 억지 계산하지 않는다.

### 6.3 Later Fields

- `sessionsOver60mCount`
- `recoveryDurationMedianApprox`
- `hourlyRecoveryCounts[24]`
- `weeklyRollupVersion`
- `monthlyRollupVersion`

### 6.4 Excluded from MVP

- frontmost app
- app category history
- exact timestamp timeline
- per-alert detailed history
- notification receipt/open attribution
- “why distraction happened” inference fields

### 6.5 Packaging Mapping

- Free:
  `totalFocusDuration`, `completedSessionCount`, `alertCount`, `longestFocusDuration`
- Pro:
  `recovery*`, `sessionsOver30mCount`, `hourlyAlertCounts`, `remoteEscalation*`

### 6.6 Completion Criteria

- MVP 저장 필드가 더 이상 흔들리지 않는다.
- 각 필드가 `Free / Pro / Later / Excluded` 중 어디에 속하는지 명확하다.
- `지금 바로 계산 가능한 필드`와 `선행 작업이 필요한 필드`가 분리되어 있다.

## 7. Projection Record Spec

### 7.1 Record Types

- `MacState`
  목적: 최신 runtime state sync
- `DashboardDayProjection`
  목적: iOS dashboard read model
- `RemoteEscalationEvent`
  목적: iOS Alerts 탭용 원격 follow-up 이벤트 기록

### 7.2 `DashboardDayProjection` Identity

- record type: `DashboardDayProjection`
- identity key: `macDeviceID + localDayKey`
- database: private database
- zone: `NudgeWhipSync` custom zone 유지

정의:

- `localDayKey`
  예: `2026-04-04@Asia/Seoul`
- `dayStart`
  local day start `Date`
- `timeZoneIdentifier`
  projection 계산 기준 timezone

### 7.3 Field Rules

- 새 필드는 optional-first
- enum/string은 raw value 또는 명시적 문자열로 저장
- array field는 bounded size만 허용
  `hourlyAlertCounts`는 항상 24칸
- 하루 단위 projection은 overwrite/update 가능해야 하며 append-only log처럼 취급하지 않는다

### 7.4 Recommended Field Types

- `dayStart`: Date
- `localDayKey`: String
- `updatedAt`: Date
- `timeZoneIdentifier`: String
- `schemaVersion`: Int
- `totalFocusDuration`: Double or Int seconds
- `completedSessionCount`: Int
- `alertCount`: Int
- `longestFocusDuration`: Double or Int seconds
- `recoverySampleCount`: Int
- `recoveryDurationTotal`: Double or Int seconds
- `recoveryDurationMax`: Double or Int seconds
- `sessionsOver30mCount`: Int
- `hourlyAlertCounts`: [Int] with length 24
- `remoteEscalationSentCount`: Int
- `remoteEscalationRecoveredWithinWindowCount`: Int

### 7.5 `RemoteEscalationEvent` Spec

- record type: `RemoteEscalationEvent`
- identity key: `macDeviceID + occurredAt` (timestamp 기반 unique key)
- database: private database
- zone: `NudgeWhipSync` custom zone 유지

정의:

- `occurredAt`: Date — escalation 이벤트 발생 시각 (alerting이 일정 시간 지속 후 remote push 발송 시점)
- `macDeviceID`: String — 발생 Mac 식별자
- `escalationStep`: Int — 발생 당시 escalation 단계 (1=idleDetected, 2=gentleNudge, 3=strongNudge)
- `contentStateRawValue`: String — 발생 당시 content state (예: "StrongNudge")
- `wasRecoveredWithinWindow`: Bool? — recovery window 내 복구 여부. nil이면 아직 복구되지 않았거나 판단 불가
- `recoveredAt`: Date? — 실제 복구 시각. nil이면 미복구
- `schemaVersion`: Int

규칙:

- `RemoteEscalationEvent`는 Mac이 생성하고 CloudKit에 업로드한다.
- iOS는 이 record를 읽기만 한다 (consumer).
- MVP에서 최근 30일치 보관. DashboardDayProjection의 retention(35일)과 독립적으로 관리.
- Recovery window는 UserSettings 기반 값(예: 5분)으로, DashboardDayProjection에는 집계 결과(`remoteEscalationSentCount`, `remoteEscalationRecoveredWithinWindowCount`)만 저장하고 개별 이벤트는 이 record에서 조회한다.

iOS Alerts 탭 매핑:

- Alerts 탭 리스트는 `RemoteEscalationEvent`를 `occurredAt` 내림차순으로 표시한다.
- 각 row에서 시각, escalation 단계 label, 복구 여부를 표시한다.
- Free 사용자는 Alerts 탭 접근 불가 (전체가 Pro 기능).

### 7.6 Completion Criteria

- 엔지니어가 record schema를 바로 만들 수 있다.
- `MacState`, `DashboardDayProjection`, `RemoteEscalationEvent`가 서로 섞이지 않는다.
- Alerts 탭의 데이터 소스가 스키마 수준에서 정의되어 있다.

## 8. Retention and Roll-up

### 8.1 MVP Retention

- `DashboardDayProjection`는 일 단위 projection을 기본 보존 단위로 사용한다.
- 권장 기본 보존:
  최근 35일 일별 projection 유지

### 8.2 Roll-up Direction

- 이후 필요 시 `DashboardMonthProjection` 추가 검토
- 월별 roll-up은 day projection을 대체하지 않고 장기 보관/조회 비용 최적화 목적이다

### 8.3 Deletion / Trimming Rule

- MVP에서는 공격적 삭제보다 단순 보존을 우선한다.
- 다만 product decision이 생기면 `365일 유지 + 그 이전 월별 roll-up` 전략으로 전환 가능하도록 문서화한다.

### 8.4 Completion Criteria

- 1년 누적 데이터가 day-level projection 기준으로 충분히 작다는 가정이 문서화된다.
- roll-up이 필요한 시점과 이유가 설명된다.

## 9. Fetch and Read Scope

### 9.1 iOS Read Pattern

- Home:
  `MacState` + 오늘 `DashboardDayProjection`
- Stats:
  최근 7일 `DashboardDayProjection`
- Alerts:
  `RemoteEscalation` history projection 또는 inbox model

### 9.2 Fetch Scope

- foreground / launch 시 `선택된 1대의 Mac`에 대해 최근 7일 projection + current `MacState` fetch
- push missing 상황에서도 foreground fetch로 정합성 회복
- cross-Mac aggregate는 MVP 범위 밖이다

### 9.3 Completion Criteria

- iOS가 어떤 화면에서 어떤 record를 읽는지 명확하다.
- iOS가 계산 로직을 재현할 필요가 없다.

## 10. Mac-side Calculation Ownership

### 10.1 Ownership Rule

- projection 계산 책임은 Mac 쪽 application/service layer에 둔다.
- iOS는 projection 소비자다.

### 10.2 Calculation Timing

- 상태 전이 또는 세션 종료 시 projection 업데이트
- 하루 경계 진입 시 이전 day projection finalize
- 앱 재시작/재동기화 시 projection 재계산 가능 경로 확보

### 10.3 Required Calculation Rules

- [ ] `recoverySampleCount`를 언제 1건으로 계산하는지 정의
- [ ] `recoveryDurationTotal` 계산 기준 정의
- [ ] `sessionsOver30mCount` 기준 정의
- [ ] `hourlyAlertCounts`를 alert 발생 시각 기준으로 집계하는지 명시
- [ ] `remoteEscalationRecoveredWithinWindowCount`의 recovery window 정의
- [ ] Mac sleep/offline 전환 중 projection 누락 방지 규칙 정의
- [ ] cross-midnight session이 day boundary를 넘을 때 어떤 기준으로 split/count 하는지 정의

### 10.4 Cross-midnight Session Rules

자정을 넘나드는 focus session의 projection 계산 규칙:

- `completedSessionCount`: 세션 **시작일**에 귀속한다. 자정 이후에 끝난 세션이 다음 날 count에 포함되지 않는다.
- `totalFocusDuration`: `FocusSession.focusDuration(overlapping:)`을 사용해 각 일의 DateInterval과의 교집합으로 분할 계산한다. 세션이 두 날에 걸치면 각 일에 실제 초 단위로 분배한다.
- `longestFocusDuration`: 일 단위로 자른 세그먼트 기준이 아닌, 세션 전체 duration 기준으로 판단한다. 하루 경계에서 잘린 세션이 longest가 될 수 있다.
- `sessionsOver30mCount`: 세션 전체 duration이 30분 초과인지로 판단한다. 하루 분할 여부와 무관하게 세션 시작일에 1건으로 계산한다.
- `hourlyAlertCounts`: alert 발생 시각 기준으로 해당 시간 bin에 귀속한다. 세션 경계와 무관하다.
- `alertCount`: 이벤트 발생 시각 기준으로 해당 일에 귀속한다.

완료 기준:

- 엔지니어가 자정 경계 처리를 질문 없이 구현 가능하다.
- `FocusSession.focusDuration(overlapping:)`이 분할 계산에 사용됨이 명시되어 있다.

### 10.5 Edge-case Rules

- sleep/wake 중 상태 전이 누락 시 다음 복구 시점에 projection 보정
- offline 상태에서는 local source of truth 기준으로 projection 유지 후 나중에 업로드
- timed manual pause / schedule pause는 focus totals에 섞이지 않도록 유지
- cross-midnight session은 `day overlap` 규칙과 `count metric` 규칙을 분리해 정의한다

### 10.5 Completion Criteria

- 계산 규칙이 질문 없이 구현 가능한 수준이다.
- sleep/offline edge case 처리 방향이 적혀 있다.

## 11. Review Checklist

- [ ] private database / custom zone 원칙 유지
- [ ] forward-compatible schema 원칙 유지
- [ ] optional-first field 정책 유지
- [ ] App Review 상 standalone utility 설명 가능
- [ ] projection이 raw behavioral log처럼 보이지 않음

## 12. Risks to Watch

- `MacState`와 `DashboardDayProjection` 관심사가 다시 섞일 수 있음
- projection 필드가 늘어나며 analytics-heavy 방향으로 커질 수 있음
- iOS가 계산 책임을 일부 떠안는 구조로 밀릴 수 있음
- retention 미정 상태가 장기 운영 비용/이해를 흐릴 수 있음
