# First-install Onboarding Component Design

- Version: 0.1
- Last Updated: 2026-04-03
- Owner: `swiftui-designer` + `macos-core`
- Depends On:
  - `docs/app/first-install-onboarding-plan.md`
  - `docs/app/first-install-onboarding-wireflow-and-copy.md`
- Scope: macOS first-install onboarding UI architecture, component boundaries, state ownership, and implementation structure

## 1. Purpose

- 온보딩을 실제 SwiftUI 구조로 옮길 때 필요한 컴포넌트 단위 설계를 정의한다.
- 화면 구성, 상태 흐름, 저장 책임, 권한 처리 책임이 한 파일에 뭉치지 않도록 경계를 먼저 정한다.
- 구현 전에 뷰 / 뷰모델 / 설정 저장 / 권한 서비스의 역할을 분리해 이후 변경 비용을 줄인다.

## 2. Design goals

1. 메뉴바 앱 구조와 충돌하지 않도록 **독립된 first-run window flow**로 구성한다.
2. 온보딩 상태와 앱 런타임 상태를 분리하되, 권한 결과는 동일 `PermissionManager`를 재사용한다.
3. 화면별 뷰는 단순하고, 분기/저장은 상위 coordinator가 담당한다.
4. `launch at login`은 device-local 계층으로 분리한다.
5. 로컬라이제이션 키 설계와 QA 스냅샷 테스트가 쉬운 구조를 만든다.

## 3. Proposed file structure

추천 구조:

```text
nudge/
├── Onboarding/
│   ├── OnboardingCoordinator.swift
│   ├── OnboardingViewModel.swift
│   ├── OnboardingStep.swift
│   ├── OnboardingStorage.swift
│   ├── OnboardingWindowController.swift   # 필요 시
│   └── Views/
│       ├── OnboardingRootView.swift
│       ├── WelcomeStepView.swift
│       ├── PermissionStepView.swift
│       ├── BasicSetupStepView.swift
│       ├── CompletionReadyStepView.swift
│       ├── CompletionLimitedStepView.swift
│       ├── OnboardingCardView.swift
│       ├── OnboardingHeaderView.swift
│       ├── OnboardingFooterView.swift
│       ├── SettingOptionRow.swift
│       └── PermissionStateBadge.swift
```

보조 서비스:

```text
nudge/
├── Services/
│   ├── PermissionManager.swift            # existing reuse
│   ├── LaunchAtLoginManager.swift         # new
│   └── ...
```

## 4. Top-level architecture

### 4.1 Coordinator ownership

온보딩 흐름은 `OnboardingCoordinator`가 소유한다.

책임:
- 현재 step 결정
- granted / denied / set-up-later 분기
- 완료 처리
- 온보딩 종료 후 앱 메인 상태로 handoff

하지 말아야 할 일:
- 화면 카피 직접 소유
- 권한 API 직접 호출
- SwiftData 쿼리 직접 처리

### 4.2 ViewModel ownership

`OnboardingViewModel`은 화면에서 표시할 값과 액션을 조립한다.

책임:
- 현재 step view data 제공
- idle threshold / countdown overlay / visual mode draft state 보관
- permission state 반영
- launch at login toggle draft state 보관

하지 말아야 할 일:
- 시스템 설정 URL 직접 열기
- SwiftData 저장 직접 수행

### 4.3 Service ownership

서비스 계층 책임:

- `PermissionManager`
  - AX 상태 확인
  - permission prompt
  - 설정 앱 열기

- `LaunchAtLoginManager`
  - `SMAppService` 연동
  - launch at login 활성/비활성
  - device-local 현재 상태 조회

- `OnboardingStorage`
  - completed flag
  - onboarding version
  - first-run resume metadata

## 5. State model

## 5.1 Step enum

```swift
enum OnboardingStep {
    case welcome
    case permission
    case basicSetup
    case completionReady
    case completionLimited
}
```

## 5.2 Draft state

온보딩 중 임시 상태:

- `selectedIdleThresholdSeconds`
- `selectedLaunchAtLogin`
- `selectedCountdownOverlayEnabled`
- `selectedVisualMode`
- `currentPermissionState`

완료 시 저장 위치:

- SwiftData (`UserSettings`)
  - `idleThresholdSeconds`
  - `countdownOverlayEnabled`
  - `petPresentationMode`

- device-local storage
  - onboarding completed
  - onboarding version
  - launch at login enabled

## 5.3 Transition rules

| Current Step | Action | Next Step |
|---|---|---|
| welcome | continue | permission |
| permission | granted confirmed | basicSetup |
| permission | open settings | stay on permission, wait for recheck |
| permission | set up later | completionLimited |
| basicSetup | continue + AX granted | completionReady |
| basicSetup | continue + AX denied | completionLimited |
| completionReady | finish | dismiss onboarding |
| completionLimited | finish | dismiss onboarding |
| completionLimited | retry permission | permission |
| permission | back | welcome |
| basicSetup | back | permission (preserve draft) |
| any | window close (Cmd+W/Esc) | see window close rules |

## 6. Root UI composition

`OnboardingRootView`

구성:
- background container
- step progress / title region
- current step body
- footer actions

권장 레이아웃:

```text
┌──────────────────────────────────────┐
│ Header                               │
│  - app name / step context           │
│  - optional progress indicator       │
├──────────────────────────────────────┤
│ Body                                 │
│  - current step specific content     │
├──────────────────────────────────────┤
│ Footer                               │
│  - primary CTA                       │
│  - secondary / tertiary CTA if any   │
└──────────────────────────────────────┘
```

## 7. Reusable view components

## 7.1 `OnboardingCardView`

목적:
- 모든 step 화면의 공통 카드 프레임

포함:
- max width
- internal padding
- background / corner / shadow

## 7.2 `OnboardingHeaderView`

표시:
- 제품명
- step title
- optional subtitle
- optional progress indicator

## 7.3 `OnboardingFooterView`

표시:
- primary button
- optional secondary button
- optional tertiary text button

규칙:
- 버튼 우선순위 시각 차등 명확히
- KR/EN 모두 자연스럽게 줄바꿈 가능
- Welcome 이외의 모든 화면에 back 버튼 포함 (secondary text button)

## 7.4 `PermissionStateBadge`

표시:
- `확인 전 / 허용됨 / 필요함`

규칙:
- 색상 + 텍스트 + 아이콘 동시 사용

## 7.5 `SettingOptionRow`

용도:
- launch at login
- countdown overlay
- visual mode helper text
- idle threshold preset row

## 8. Screen-specific component design

## 8.1 `WelcomeStepView`

입력:
- headline
- body
- bullet items

출력 액션:
- continue

주의:
- 권한 CTA 포함 금지

## 8.2 `PermissionStepView`

입력:
- permission state
- disclosure copy

출력 액션:
- request permission
- open settings
- set up later

주의:
- PermissionStepView는 상태 refresh 이벤트를 직접 소유하지 않고 상위에서 주입받는다.

## 8.3 `BasicSetupStepView`

입력:
- current draft values
- preset lists

출력 액션:
- threshold selection
- launch at login toggle
- countdown overlay toggle
- visual mode selection
- continue

주의:
- 저장은 즉시 commit하지 않고 completion 시점에 반영
- 다만 resume UX가 필요하면 draft autosave를 별도 결정 가능

## 8.4 `CompletionReadyStepView`

입력:
- final summary values

출력 액션:
- finish

추가 연출 후보:
- 메뉴바 아이콘 1회 강조
- lightweight success animation

## 8.5 `CompletionLimitedStepView`

입력:
- limitation explanation

출력 액션:
- continue limited
- retry permission

주의:
- “부분 기능 사용”을 과장하지 않도록 카피 고정

## 9. Window and presentation strategy

MVP 후보는 2개:

### Option A — Dedicated onboarding window

장점:
- 메뉴바 앱 진입 문제를 직접 해결
- 사용자 시선 집중이 쉬움
- permission flow 설명에 유리

단점:
- window lifecycle 추가 관리 필요

### Option B — First-open menu bar expanded flow

장점:
- 구현량이 적음

단점:
- 발견성 낮음
- 현재 문제를 근본적으로 해결하지 못함

**권장: Option A**

즉, 최초 설치에서는 독립된 onboarding window를 띄우고, 완료 후 메뉴바 경험으로 넘긴다.

### LSUIElement 고려사항

현재 `LSUIElement = YES` 설정으로 앱이 Dock에 나타나지 않는다. 전용 온보딩 윈도우를 띄울 때:

- `NSWindow` 직접 사용 시 Dock에 임시 아이콘이 나타날 수 있음
- 대안: `NSPanel`(utility level) 또는 `NSWindow.Level.floating` 검토
- 완료 후 윈도우를 `orderOut`하고 메뉴바 상태로 전환

### Window close handling

- `OnboardingCoordinator`는 window close(Cmd+W/Esc) 이벤트를 수신해야 한다.
- close 시 동작:
  - Welcome/Permission 단계: `limitedNoAX`로 진입, onboarding completed=true
  - Basic Setup 단계: draft 값 보존, 다음 실행에서 resume 가능
- `NSWindowDelegate.windowWillClose` 또는 SwiftUI `onDisappear`로 처리

## 10. Persistence design

## 10.1 `OnboardingStorage`

저장 예:
- `onboarding.completed`
- `onboarding.version`
- `onboarding.last_step` (선택)

권장 API:

```swift
protocol OnboardingStoring {
    var hasCompletedOnboarding: Bool { get }
    var onboardingVersion: Int { get }
    func markCompleted(version: Int)
    func reset()
}
```

## 10.2 `LaunchAtLoginManager`

권장 API:

```swift
protocol LaunchAtLoginManaging {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
```

주의:
- 이 값은 `UserSettings`에 넣지 않는다.
- device-local behavior이므로 local service + local flag로만 다룬다.

## 11. App integration points

앱 진입 시점:
- `NudgeWhipApp`에서 onboarding required 여부 판단
- required면 onboarding window 먼저 표시
- 아니면 기존 menu bar app flow 진행

완료 후:
- onboarding dismiss
- `MenuBarViewModel.startIfNeeded()` 호출 가능 상태로 handoff

설정 재오픈:
- 메뉴바 드롭다운 하단 "도움말" 영역에 "초기 설정 다시" 메뉴 아이템 배치
- menu/settings에서 onboarding coordinator 재호출

## 12. Localization design notes

키 그룹:
- `onboarding.welcome.*`
- `onboarding.permission.*`
- `onboarding.setup.*`
- `onboarding.completion.ready.*`
- `onboarding.completion.limited.*`
- `onboarding.common.*`

규칙:
- step별 title/body/button을 분리
- summary labels도 onboarding 전용 key 사용
- disclosure 문구는 privacy 문서 의미를 그대로 유지

## 13. Testing strategy

Unit:
- coordinator transition tests
- onboarding storage tests
- launch at login manager tests
- permission retry / return flow tests

UI:
- first launch welcome visibility
- denied path
- granted path
- settings return path
- re-open onboarding path

Snapshot:
- KR/EN 모든 step
- granted / denied completion both

## 14. Accessibility and appearance requirements

### Keyboard navigation
- Tab: CTA 버튼 간 순차 이동
- Enter/Space: 현재 포커스된 버튼 실행
- Esc: 온보딩 창 닫기 (window close rules 적용)
- Backspace: 이전 화면 복귀 (coordinator back action)

### VoiceOver
- 각 step 화면의 제목/본문/버튼에 의미 있는 accessibility label 적용
- step 전환 시 announcement로 화면 변경 알림
- permission 상태 badge는 값이 변경될 때 accessibility value 갱신

### Dark mode / Appearance
- `OnboardingCardView` 배경/그림자가 light/dark 모두에서 가독성 유지
- 상태 badge 색상(확인 전/허용됨/필요함)이 색맹 사용자도 구분 가능하도록 아이콘+텍스트 동시 사용 (기존 규칙과 일치)
- CTA 버튼 색상 대비 WCAG AA 기준 충족

### Minimum window size
- 너비: 480pt, 높이: 400pt 기준
- Basic Setup 화면의 4개 컨트롤이 이 크기에서 scrolling 없이 표시되어야 함

## 15. Open implementation questions

- onboarding window를 SwiftUI `WindowGroup`로 둘지, 별도 window controller로 둘지
- progress indicator를 step count로 보여줄지, 숨길지
- draft state autosave가 필요한지 여부
