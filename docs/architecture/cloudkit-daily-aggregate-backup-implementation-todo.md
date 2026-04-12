# CloudKit Daily Aggregate Backup Implementation TODO

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: engineering
- Source Docs:
  - `docs/architecture/cloudkit-daily-aggregate-backup.md`
  - `docs/app/task-ios-dashboard-data-schema.md`

## 1. Purpose

- 이 문서는 local-day 기준 daily aggregate CloudKit backup을 실제 구현 작업으로 분해한 TODO다.
- 목표는 “설계는 정해졌는데 어디서부터 뭘 바꿔야 하는지 모르는 상태”를 없애고, 구현자가 바로 레인별로 작업할 수 있게 만드는 것이다.

## 2. Scope Lock

이번 구현 범위:

- local SwiftData source of truth 유지
- local day 기준 `DashboardDayProjection` 계산
- CloudKit private DB upsert backup
- raw/session/event timeline 업로드 금지

이번 범위 밖:

- iOS companion fetch 구현
- TopAppsDayProjection
- RemoteEscalationEvent 업로드
- historical timezone rebucket

## 3. Primary Workstreams

### W1. Local aggregation service

- local SwiftData truth에서 하루 projection 계산
- cross-midnight 규칙 반영
- projection을 값 타입 또는 DTO로 생성

### W2. CloudKit writer

- `DashboardDayProjection` record 생성/업데이트
- recordName deterministic key 사용
- private DB + `NudgeWhipSync` zone write

### W3. Trigger wiring

- focus session 종료
- recovery 종료
- 자정 경계
- 앱 재실행/복구

### W4. Verification

- unit tests
- integration-like write tests (mock/fake)
- local-day boundary regression 확인

## 4. File-level TODO

## 4.1 Add aggregation service layer

추천 신규 파일:

- `nudgewhip/Shared/Services/DailyAggregateProjectionBuilder.swift`

책임:

- `FocusSession` + `AlertingSegment` 기반 일간 projection 계산
- `DashboardDayProjectionPayload` 생성

완료 기준:

- 지정한 `referenceDate`와 `timeZoneIdentifier` 기준으로 projection 1건을 계산할 수 있다

## 4.2 Add CloudKit backup writer

추천 신규 파일:

- `nudgewhip/Shared/Services/CloudKitDailyAggregateBackupWriter.swift`

책임:

- `DashboardDayProjectionPayload` → CloudKit record 변환
- upsert write
- zone/database 선택

완료 기준:

- deterministic `recordName`
- overwrite/update 가능
- serialization 규칙 반영 (`hourlyAlertCountsJSON` 등)

## 4.3 Add payload / DTO type

추천 신규 파일:

- `nudgewhip/Shared/Models/DashboardDayProjectionPayload.swift`

필드:

- `macDeviceID`
- `localDayKey`
- `dayStart`
- `timeZoneIdentifier`
- `updatedAt`
- `schemaVersion`
- `totalFocusDurationSeconds`
- `completedSessionCount`
- `alertCount`
- `longestFocusDurationSeconds`
- `recoverySampleCount`
- `recoveryDurationTotalSeconds`
- `recoveryDurationMaxSeconds`
- `sessionsOver30mCount`
- `hourlyAlertCounts`
- optional UTC source window

완료 기준:

- CloudKit 없이도 projection payload를 독립적으로 테스트 가능

## 4.4 Add device identity source

확인/추가 필요 파일:

- existing runtime/app controller layer
- 필요 시 신규 helper:
  - `nudgewhip/Shared/Services/DeviceIdentityProvider.swift`

책임:

- stable `macDeviceID` 제공

완료 기준:

- CloudKit record key 생성에 사용할 device identity가 앱 전역에서 안정적으로 공급된다

## 4.5 Add day-boundary scheduler or recompute hook

추천 위치:

- app controller / lifecycle coordinator layer

책임:

- 자정 경계에서 전일 projection finalize
- 앱 재실행 시 최근 day 재계산

완료 기준:

- 사용자가 앱을 켜둔 상태에서도 날짜가 바뀌면 전일 projection이 닫힌다

## 4.6 Wire session/recovery triggers

관련 기존 면:

- `FocusSession`
- `AlertingSegment`
- session lifecycle owner (`IdleMonitor` / controller path)

해야 할 일:

- 세션 종료 시 해당 day projection 갱신
- recovery segment 완료 시 해당 day projection 갱신
- 동일 day에서 여러 번 갱신되어도 upsert만 일어남

완료 기준:

- 하루 동안 데이터가 누적될수록 projection이 자연스럽게 덮어써진다

## 4.7 CloudKit serialization rules

반영 규칙:

- `hourlyAlertCounts` → `hourlyAlertCountsJSON`
- duration/count는 전부 초/정수 기반
- optional 필드는 nil 허용

완료 기준:

- record field 타입이 흔들리지 않는다

## 4.8 Failure handling / retry

추천 신규 파일 또는 writer 내부 책임:

- local outbox 또는 pending write queue

최소 규칙:

- CloudKit write 실패 시 로컬 계산값은 유지
- 다음 앱 활성화/재계산 시 재시도 가능
- 같은 projection을 중복 append하지 않고 최신 상태로 coalesce

완료 기준:

- 네트워크/CloudKit 일시 실패가 로컬 통계 정합성을 깨지 않는다

## 5. Concrete TODO Checklist

### Step 1 — Projection payload foundation

- [ ] `DashboardDayProjectionPayload` 정의
- [ ] payload 생성에 필요한 field 타입을 `Int seconds` 중심으로 고정
- [ ] `localDayKey` formatter 정의

### Step 2 — Builder implementation

- [ ] 특정 day interval 계산 helper 추가
- [ ] `FocusSession.focusDuration(overlapping:)` 재사용
- [ ] `completedSessionCount`는 `focusDuration(overlapping:) > 0` 필터로 계산하지 않도록 명시 구현
- [ ] `completedSessionCount` 시작일 귀속 규칙 반영
- [ ] `sessionsOver30mCount` 전체 세션 duration 기준 반영
- [ ] `hourlyAlertCounts[24]` 계산 로직 추가

### Step 3 — Cloud writer

- [ ] `DashboardDayProjectionPayload` → CKRecord mapping
- [ ] recordName 규칙 구현
- [ ] `private database` + `NudgeWhipSync` zone 선택
- [ ] upsert write 구현

### Step 4 — Trigger wiring

- [ ] session 종료 시 write trigger
- [ ] recovery 종료 시 write trigger
- [ ] 자정 경계 finalize trigger
- [ ] launch/foreground 시 최근 day 재계산 trigger

### Step 5 — Retry/coalescing

- [ ] write failure 시 retry 정책 정의
- [ ] 동일 day projection coalescing 정의

### Step 6 — Verification

- [ ] localDayKey 생성 테스트
- [ ] cross-midnight 분할 테스트
- [ ] timezone identifier 포함 테스트
- [ ] hourlyAlertCounts 직렬화 테스트
- [ ] Cloud writer record field 이름 테스트

## 6. Test Matrix

필수 테스트:

- same-day normal sessions
- cross-midnight session
- recovery segment 포함 day
- alert가 여러 시간대에 분포한 day
- timezone identifier가 다른 payload
- Cloud write 실패 후 retry

## 7. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| projection 계산과 기존 `DailyStats.derive`가 어긋남 | 수치 불일치 | builder가 기존 derive 규칙을 재사용하거나 명시적 규칙 테스트 추가 |
| session 종료/복구 이벤트에서 write가 너무 자주 발생 | write amplification | local coalescing + same-day overwrite |
| device identity가 불안정 | record key 흔들림 | stable provider 추가 |
| CloudKit 구현이 로컬 truth를 침범 | 데이터 정합성 저하 | Cloud writer는 payload consumer로만 유지 |

> ⚠️ `completedSessionCount`는 특히 주의:
> 기존 `DailyStats.derive()`의 overlap 기준 count를 그대로 복사하면
> Cloud backup의 시작일 귀속 규칙과 달라진다.
> builder에서는 반드시 별도 필터로 구현해야 한다.

## 8. Exit Criteria

- `DashboardDayProjectionPayload` 생성 가능
- CloudKit upsert writer 존재
- session/recovery/day-boundary trigger 연결
- cross-midnight/day-boundary 테스트 통과
- 로컬 truth와 Cloud backup 책임이 분리됨
