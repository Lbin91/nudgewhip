# Nudge CloudKit Sync Contract

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `cloudkit-sync`
- Related Specs: `docs/app/spec.md`, `docs/report/2026-04-02-spec-expansion-agent-meeting.md`

## 1. Purpose

- macOS의 상태 전이를 iOS companion이 소비할 수 있는 형태로 비동기 동기화한다.
- CloudKit은 source of truth가 아니라 전달 계층이다.
- 실시간 보장을 제공하지 않으며 `best-effort near real-time`만 목표로 한다.

## 2. Scope

- 포함: record/zone schema, state mapping, write triggers, outbox/coalescing, iOS fetch/push policy, entitlement separation, failure handling, privacy limits
- 제외: StoreKit 구현 코드, UI, local idle logic, alert rendering

## 3. CloudKit Topology

### 3.1 Container and Database

- Private Database만 사용한다.
- 사용자 데이터는 public database에 저장하지 않는다.
- app group 또는 shared container는 CloudKit 필수 조건이 아니다.

### 3.2 Zone

- custom zone 이름은 `NudgeSync`로 고정한다.
- zone 생성 실패 시 재시도 후 로컬 전용 모드로 폴백한다.

## 4. Record Schema

### 4.1 Core Record

- Record type: `MacState`
- Record identity key: `macDeviceID`

### 4.2 Canonical Fields

- `state`: runtime state string
- `stateChangedAt`: 상태 변경 시각
- `sequence`: monotonic sequence number
- `breakUntil`: 휴식 종료 예정 시각, 없으면 nil
- `sourceDeviceID`: 업로드 주체 식별자
- `lastAlertAt`: 마지막 알림 시각, 선택 필드
- `schemaVersion`: record schema version

### 4.3 Field Rules

- enum은 raw string으로 저장한다.
- 새 필드는 optional-first 정책을 따른다.
- record shape는 상태 전이 표현에 필요한 최소 정보만 담는다.
- 입력 이벤트 원본이나 사용자 콘텐츠는 저장하지 않는다.

## 5. State Mapping

### 5.1 Runtime to Sync Mapping

- `monitoring` -> `state = monitoring`
- `pausedManual` -> `state = pausedManual`
- `pausedWhitelist` -> `state = pausedWhitelist`
- `alerting` -> `state = alerting`
- `limitedNoAX` -> `state = limitedNoAX`
- `suspendedSleepOrLock` -> `state = suspendedSleepOrLock`

### 5.2 Content State Mapping

- `Focus` -> baseline sync marker
- `IdleDetected` -> `state = alerting` 전 단계 기록
- `GentleNudge` -> `state = alerting`
- `StrongNudge` -> `state = alerting`
- `Recovery` -> `state = monitoring`
- `Break` -> `state = pausedManual`
- `RemoteEscalation` -> iOS consumer-facing follow-up marker

### 5.3 Mapping Rule

- sync payload는 runtime state를 우선한다.
- content state는 보조 signal로만 사용한다.
- iOS는 runtime state 변화만으로도 충분히 사용자 상황을 이해할 수 있어야 한다.

## 6. Write Triggers

다음 상태 전이에서만 write를 수행한다.

- idle 진입
- 1차 alert 발생
- 2차 alert 발생
- user recovery
- manual break 시작
- manual break 종료
- accessibility 제한 모드 진입 또는 해제
- suspended state 진입 또는 해제

### Write Rule

- heartbeat write는 하지 않는다.
- 동일 상태가 연속으로 들어오면 coalesce한다.
- 상태 변경이 없으면 write하지 않는다.

## 7. Outbox and Coalescing

### 7.1 Local Outbox

- macOS는 네트워크와 분리된 local outbox를 먼저 기록한다.
- outbox entry는 최소 `state`, `stateChangedAt`, `sequence`, `breakUntil`, `sourceDeviceID`를 포함한다.

### 7.2 Coalescing Rules

- 최신 sequence만 업로드한다.
- 같은 state의 연속 업데이트는 하나로 합친다.
- 오프라인 중 다수 이벤트가 쌓이면 마지막 유효 상태만 유지한다.
- 복귀 후에는 이전 alert payload를 덮어쓰고 recovery 상태를 우선한다.

### 7.3 Retry Policy

- 네트워크 실패 시 exponential backoff를 적용한다.
- 할당량 초과 또는 transient error는 재시도 대상으로 분류한다.
- 권한/계정 문제는 재시도보다 사용자 안내를 우선한다.

## 8. iOS Fetch and Push Policy

### 8.1 Push Policy

- push는 보장형이 아니다.
- iOS 알림은 `alerting`이 일정 시간 지속된 뒤의 `RemoteEscalation`에서만 best-effort로 보낸다.
- silent push가 도착하지 않아도 iOS app은 최종 상태를 복구할 수 있어야 한다.

### 8.2 Fetch Policy

- app launch 시 delta fetch를 수행한다.
- foreground 전환 시 delta fetch를 수행한다.
- push 수신 여부와 관계없이 fetch는 가능해야 한다.
- fetch 실패 시 다음 foreground 또는 launch에서 재시도한다.

### 8.3 Device Consistency

- iOS는 서버 최신 상태를 표시하되, local preview가 있으면 임시 렌더링할 수 있다.
- 레코드 순서는 `sequence`와 `stateChangedAt`를 함께 본다.

## 9. Entitlement Separation

- iCloud 로그인 상태와 Pro 구매 상태는 분리해 판단한다.
- Pro entitlement의 source of truth는 StoreKit이다.
- CloudKit은 entitlement 저장소가 아니다.
- iCloud 미로그인 시에도 local-only 기능은 계속 동작해야 한다.
- 구매 상태가 없으면 iOS companion 연동은 기능적으로 비활성화할 수 있다.

## 10. Failure Handling

### 10.1 Account and Permission Failures

- iCloud 미로그인: 로컬 전용 모드로 폴백
- CloudKit permission denied: sync 비활성화 후 설정 안내
- Pro 미구매: sync payload는 생성하되 iOS follow-up 기능은 제한

### 10.2 Network Failures

- transient network error: outbox 유지 후 재시도
- offline 상태: outbox 축적 후 복구 시 coalesce 업로드
- partial save failure: 동일 sequence 재전송 전에 local state를 다시 읽는다

### 10.3 Schema Failures

- zone 생성 실패: 재시도 후 경고 로그
- record decode 실패: schemaVersion 기준으로 fallback decode 시도
- unknown field 발견: 무시하고 최소 필드만 읽는다

## 11. Privacy Limits

- 키 입력 내용은 저장하지 않는다.
- 화면 캡처, 스크린 내용, 앱 사용 상세 텍스트는 저장하지 않는다.
- CloudKit에는 상태 전이에 필요한 최소 metadata만 올린다.
- 사용자 식별 정보는 `sourceDeviceID` 수준으로 제한한다.
- 지역/계정/구매 정보는 entitlement 판단 외 목적에 사용하지 않는다.

## 12. Observability and QA Hooks

- upload attempt, coalesce decision, fetch result, push result는 테스트 훅으로 노출한다.
- sequence monotonicity는 unit test로 검증한다.
- offline-to-online 복구 시 마지막 state가 단일 record로 수렴하는지 검증한다.
- iOS launch/foreground fetch와 push missing 케이스를 별도 시나리오로 둔다.
- account denied, permission denied, zone creation failure, partial save failure를 각각 분리 테스트한다.

## 13. Implementation Notes

- sync writer는 idle controller와 분리된 서비스로 유지한다.
- CloudKit API 호출은 async boundary 뒤에 둔다.
- outbox와 remote record 간의 충돌은 최신 sequence 우선으로 해결한다.
