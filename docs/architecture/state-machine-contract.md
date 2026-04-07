# Nudge State Machine Contract

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `macos-core`
- Related Specs: `docs/app/spec.md`, `docs/report/2026-04-02-spec-expansion-agent-meeting.md`

## 1. Purpose

- Nudge의 idle detection, pause, alert, recovery 흐름을 구현 가능한 상태 계약으로 고정한다.
- runtime state와 content state를 분리해 UI, alert, CloudKit, QA가 같은 기준을 보게 한다.
- polling 중심 구현이 아니라 one-shot timer 중심 구현을 강제한다.

## 2. Scope

- 포함: runtime states, events, priorities, transitions, timers, invariants, failure handling, QA hooks
- 제외: 실제 UI 문구, 콘텐츠 대사, CloudKit record schema 상세, SwiftData 모델 구현 코드

## 3. Runtime States

### 3.1 Canonical States

- `limitedNoAX`: Accessibility 권한이 없어 제한 모드로 동작
- `monitoring`: 입력 감시와 idle timer가 정상 동작
- `pausedManual`: 사용자가 수동 휴식 모드를 켠 상태
- `pausedWhitelist`: 전면 활성 앱이 화이트리스트 조건에 들어간 상태
- `alerting`: idle 기준을 넘겨 알림 단계가 진행 중인 상태
- `suspendedSleepOrLock`: sleep, lock, fast user switching 등으로 타이머를 중단한 상태

### 3.2 State Ownership

- `limitedNoAX`는 권한 레이어가 소유한다.
- `monitoring`, `pausedManual`, `pausedWhitelist`, `alerting`, `suspendedSleepOrLock`은 idle controller가 소유한다.
- 상태 판단은 단일 source of truth로 `runtimeState` 한 개를 사용한다.

## 4. Event Model

### 4.1 Input Events

- `mouseMoved`
- `mouseDown`
- `scrollWheel`
- `keyDown`

### 4.2 System Events

- `accessibilityGranted`
- `accessibilityDenied`
- `manualPauseEnabled`
- `manualPauseDisabled`
- `frontmostAppChanged(bundleIdentifier)`
- `whitelistMatched`
- `whitelistUnmatched`
- `idleDeadlineReached`
- `alertEscalationDeadlineReached`
- `userActivityDetected`
- `sleepDetected`
- `wakeDetected`
- `screenLocked`
- `screenUnlocked`
- `fastUserSwitchingStarted`
- `fastUserSwitchingEnded`
- `cooldownExpired`
- `monitorStartFailed`

- `accessibilityGranted`는 권한 부여와 모니터 재시작 성공을 모두 포괄한다. 별도의 `permissionsRecovered` 이벤트는 두지 않는다.
- `accessibilityDenied`는 운영체제의 실시간 콜백이 아니라, 앱이 foreground 복귀나 권한 프롬프트 복귀 시점에 `AXIsProcessTrusted`를 재검사한 뒤 발행하는 합성 이벤트다.

### 4.3 Event Handling Rule

- 이벤트 핸들러는 `lastInputAt` 또는 관련 플래그 갱신만 수행한다.
- 무거운 계산, UI 렌더, CloudKit write는 이벤트 핸들러에서 금지한다.
- 상태 전환은 전용 reducer 또는 controller callback에서 수행한다.

## 5. State Priority

우선순위는 아래와 같다.

1. `suspendedSleepOrLock`
2. `limitedNoAX`
3. `pausedManual`
4. `pausedWhitelist`
5. `alerting`
6. `monitoring`

### Priority Rules

- 더 높은 우선순위 상태는 lower priority 상태를 덮어쓴다.
- `suspendedSleepOrLock`은 idle time 누적을 중단하고 baseline을 재설정한다.
- `limitedNoAX`는 monitoring보다 우선하지만, 내부적으로 idle elapsed는 계산하지 않는다.
- `alerting` 중에도 `pausedManual` 또는 `suspendedSleepOrLock`이 들어오면 즉시 중단한다.

## 6. Transition Rules

### 6.1 From `limitedNoAX`

- `accessibilityGranted` -> `monitoring`
- `monitorStartFailed` -> `limitedNoAX`
- `accessibilityDenied` -> `limitedNoAX`

### 6.2 From `monitoring`

- `manualPauseEnabled` -> `pausedManual`
- `whitelistMatched` -> `pausedWhitelist`
- `idleDeadlineReached` -> `alerting`
- `sleepDetected`, `screenLocked`, `fastUserSwitchingStarted` -> `suspendedSleepOrLock`
- `accessibilityDenied` -> `limitedNoAX`

### 6.3 From `pausedManual`

- `manualPauseDisabled` -> `monitoring`
- `sleepDetected`, `screenLocked`, `fastUserSwitchingStarted` -> `suspendedSleepOrLock`
- `accessibilityDenied` -> `limitedNoAX`

### 6.4 From `pausedWhitelist`

- `whitelistUnmatched` -> `monitoring`
- `manualPauseEnabled` -> `pausedManual`
- `sleepDetected`, `screenLocked`, `fastUserSwitchingStarted` -> `suspendedSleepOrLock`
- `accessibilityDenied` -> `limitedNoAX`

### 6.5 From `alerting`

- `userActivityDetected` -> `monitoring`
- `manualPauseEnabled` -> `pausedManual`
- `whitelistMatched` -> `pausedWhitelist`
- `sleepDetected`, `screenLocked`, `fastUserSwitchingStarted` -> `suspendedSleepOrLock`
- `accessibilityDenied` -> `limitedNoAX`

### 6.6 From `suspendedSleepOrLock`

- `wakeDetected`, `screenUnlocked`, `fastUserSwitchingEnded` -> re-evaluate current mode
- if Accessibility still missing -> `limitedNoAX`
- if manual pause active -> `pausedManual`
- if whitelist active -> `pausedWhitelist`
- else -> `monitoring`

## 7. Timers

### 7.1 Timer Types

- `idleDeadlineTimer`: 마지막 입력 시각 + 사용자가 설정한 idle threshold에 맞춰 단일 deadline 예약
- `alertEscalationTimer`: 1차 알림 후 추가 escalation을 위한 deadline 예약
- `cooldownTimer`: 복귀 직후 일정 시간 재알림 방지
- `notificationDebounceTimer`: 3차 시스템 알림 연속 발행 방지

### 7.2 Timer Rules

- polling timer는 사용하지 않는다.
- 단, 이 금지는 idle detection deadline에 대한 규칙이다. 권한 상태는 앱 활성화 복귀나 제한된 재검사 경로에서 다시 확인할 수 있다.
- 하나의 runtime state에 대해 동시에 중복 deadline을 두지 않는다.
- state가 바뀌면 관련 timer는 cancel 후 재등록한다.
- `sleepDetected` 또는 `screenLocked`에서 모든 deadline timer는 suspend 상태로 들어간다.
- `userActivityDetected`는 모든 escalation timer를 즉시 취소한다.

### 7.3 Timing Contracts

- idle threshold 도달 오차 허용 범위: ±1초
- user activity 후 alert 해제 목표: 500ms 이내
- state icon 반영 목표: 1초 이내

## 8. Escalation Semantics

### 8.1 Content State Mapping

- `monitoring` -> `Focus`
- `idleDeadlineReached` -> `IdleDetected`
- first alert -> `GentleNudge`
- stronger alert -> `StrongNudge`
- user return -> `Recovery`
- manual pause -> `Break`
- iOS follow-up -> `RemoteEscalation`

### 8.2 Escalation Policy

- 1차 알림은 `perimeter pulse`만 사용한다.
- 2차 알림은 더 강한 시각 피드백으로 제한한다.
- 3차 시스템 알림은 짧은 1회성 문구만 허용한다.
- 장기 미복귀 시에만 `RemoteEscalation` 후보를 CloudKit 레이어에 넘긴다.

## 9. Invariants

- 입력이 감지되면 `lastInputAt`은 반드시 최신화되어야 한다.
- `pausedManual`과 `pausedWhitelist`는 동시에 active가 될 수 없으며, manual pause가 우선한다.
- `suspendedSleepOrLock` 동안 idle elapsed는 증가하지 않는다.
- `limitedNoAX`에서는 사용자에게 제한 모드를 항상 노출한다.
- `alerting`은 반드시 종료 경로를 가져야 하며, 무한 유지될 수 없다.
- raw input payload는 저장하지 않는다.

## 10. Failure Handling

- Accessibility 권한 거부 시 `limitedNoAX`로 전환하고 제한 모드를 유지한다.
- 글로벌 모니터 등록 실패 시 재시도 정책을 적용하되, 무한 루프는 금지한다.
- frontmost app 조회 실패 시 whitelist pause를 비활성화하고 monitoring은 유지한다.
- sleep/wake 이벤트 누락 감지 시 다음 input event에서 baseline을 재계산한다.
- timer drift가 크면 현재 deadline을 폐기하고 새 deadline을 계산한다.

## 11. QA Hooks

- 각 상태 전환은 이벤트명과 target state를 로그/테스트 훅으로 노출한다.
- timer 등록과 취소는 injectable clock으로 검증한다.
- accessibility denied, sleep/wake, lock/unlock, whitelist 전환, 입력 폭주 시나리오는 모두 테스트 케이스로 고정한다.
- alert 해제 latency, idle threshold 정확도, cooldown 적용 여부는 수치 기반 assertion으로 검증한다.

## 12. Implementation Notes

- reducer는 순수 함수 형태를 우선한다.
- side effect는 timer, UI, CloudKit, system notification으로 분리한다.
- 상태 이름은 UI 문구와 분리하고 코드 상 canonical enum으로 유지한다.
