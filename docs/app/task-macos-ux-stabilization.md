# Nudge Task: macOS UX Stabilization

- Version: draft-2
- Last Updated: 2026-04-04
- Status: active
- Owner: engineering / QA

## 1. Purpose

- 현재 macOS UX 흔들림을 단순 확인이 아니라 **재발 방지 중심**으로 안정화한다.
- 대상은 `Pause Menu`와 `Onboarding Preview / Completion`이다.

## 2. Related Docs

- [spec.md](./spec.md)
- [onboarding-refinement-plan.md](./onboarding-refinement-plan.md)
- [onboarding-screenshot-review-2026-04-03.md](./onboarding-screenshot-review-2026-04-03.md)
- [acceptance-matrix.md](../qa/acceptance-matrix.md)
- [localization-test-matrix.md](../qa/localization-test-matrix.md)
- [accessibility-and-data-disclosure.md](../privacy/accessibility-and-data-disclosure.md)

## 3. Related Code Surfaces

- [MenuPresentationActivityGuard.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Views/MenuPresentationActivityGuard.swift)
- [ContentView.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/ContentView.swift)
- [IdleMonitor.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Services/IdleMonitor.swift)
- [MenuBarViewModel.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Services/MenuBarViewModel.swift)
- [NudgePreviewCard.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Onboarding/Views/NudgePreviewCard.swift)
- [NudgePreviewOverlay.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Onboarding/Views/NudgePreviewOverlay.swift)
- [CompletionReadyStepView.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudge/Onboarding/Views/CompletionReadyStepView.swift)

## 4. Permanent Non-Regression Rules

- 메뉴가 열려 있는 동안 depth-menu hover / tracking은 observed activity로 취급하지 않는다.
- timed pause는 stale pre-pause baseline이 아니라 fresh baseline으로 복귀해야 한다.
- onboarding preview는 실제 runtime alert처럼 오인되면 안 된다.
- completion summary는 KR/EN에서 truncation 없이 읽혀야 한다.

## 5. Scope A: Pause Menu Stabilization

### 5.1 Expected Behavior

- `일시 정지` submenu가 hover / 진입 / 선택 중 흔들리거나 닫히지 않는다.
- `켤 때까지 / 10분 / 30분 / 60분`이 정상 동작한다.
- pause 중 메뉴 항목이 `일시 정지 해제` 단일 항목으로 바뀐다.
- pause 중 메뉴바 아이콘 상태가 올바르게 반영된다.
- 메뉴가 열린 동안 idle timer / countdown 갱신이 submenu를 invalidate하지 않는다.

### 5.2 Failure Signatures

- submenu flicker
- hover 중 submenu dismiss
- countdown 변화와 함께 menu redraw
- timed pause expiry 후 baseline 이상
- pause/resume 후 상태와 아이콘 불일치

### 5.3 Pause Menu QA Matrix

필수 축:

- locale: `ko`, `en`
- permission state: granted, denied
- runtime state: monitoring, paused
- action: each pause duration, resume
- visual state: icon change, menu label change

필수 시나리오:

- [ ] monitoring 상태에서 submenu hover 반복
- [ ] 각 pause duration 선택
- [ ] timed pause 만료 확인
- [ ] manual resume 확인
- [ ] 메뉴 open 상태에서 countdown 변화 시 안정성 확인
- [ ] accessibility denied 상태에서 메뉴 구조 유지 확인

완료 기준:

- 모든 필수 시나리오 pass
- submenu flicker / invalidation 재현 안 됨

## 6. Scope B: Onboarding Preview and Completion UX

### 6.1 Expected Behavior

- 사용자가 `gentle / moderate / strong` 차이를 설명 없이 이해할 수 있다.
- preview overlay는 demo라는 점이 명확해야 한다.
- TTS off 상태에서는 sound preview gating이 명확하다.
- completion summary는 스캔이 쉽고 줄바꿈이 안정적이다.

### 6.2 Onboarding QA Matrix

필수 축:

- locale: `ko`, `en`
- appearance: light, dark
- TTS: on, off
- style: gentle, moderate, strong
- accessibility: reduced motion on/off
- flow: completion ready, completion limited

필수 시나리오:

- [ ] 각 preview style visual distinction 확인
- [ ] TTS off 시 sound preview 비활성 상태 확인
- [ ] KR/EN 문장 줄바꿈 확인
- [ ] light/dark contrast 확인
- [ ] reduced motion 대응 확인
- [ ] completion summary scanability 확인

완료 기준:

- style distinction이 시각적으로 명확함
- completion summary가 KR/EN 모두 읽기 쉬움
- preview가 실제 runtime alert로 오인되지 않음

## 7. Automation Linkage

현재 regression anchor:

- [nudgeTests.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudgeTests/nudgeTests.swift)
  `idleMonitorIgnoresObservedActivityWhileMenuIsPresented()`
- [nudgeTests.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudgeTests/nudgeTests.swift)
  `systemEventMonitorIgnoresMenuBarTrackingEventsWithoutWindow()`
- [nudgeTests.swift](/Users/bongjinlee/Documents/Project/bots/nudge/nudgeTests/nudgeTests.swift)
  `menuBarViewModelTracksMenuPresentationGuardState()`

필수 follow-through:

- [ ] pause menu 상태 전환에 대한 UI test 추가 여부 판단
- [ ] onboarding preview/completion 화면에 대한 snapshot or view-level test 후보 정리
- [ ] 재현된 회귀는 테스트 추가 또는 follow-up issue 둘 중 하나로 반드시 귀결

## 8. Bug Report Contract

버그 리포트 필수 필드:

- `Title`
- `Build / Commit`
- `Environment`
- `Preconditions`
- `Steps`
- `Expected`
- `Actual`
- `Frequency`
- `Evidence`
- `Suspected regression point`
- `Follow-up owner`

저장 위치:

- `reports/bug/` 하위

## 9. Completion Evidence

각 QA pass에 남겨야 하는 것:

- build or commit SHA
- macOS version
- locale
- permission state
- test setup state
- screenshot or recording
- matrix row별 result
- linked bug/follow-up if failed

## 10. Exit Criteria

- pause menu matrix 전체 수행
- onboarding matrix 전체 수행
- zero untriaged failures
- 재현된 회귀는 fix+test 또는 follow-up issue로 정리
- non-regression rules가 코드/문서/메모리와 일치

## 11. Risks to Watch

- pause submenu flicker 재발
- onboarding preview가 runtime alert로 오인
- KR/EN truncation 재발
- UI test 부재로 수동 QA에만 의존하는 상태 지속
