# First-install Onboarding Wireflow and Copy Draft

- Version: 0.1
- Last Updated: 2026-04-03
- Owner: `swiftui-designer` + `localization` + `macos-core`
- Depends On: `docs/app/first-install-onboarding-plan.md`
- Scope: wireflow, screen structure, and KR/EN draft copy for the first-install onboarding flow

## 1. Purpose

- 최초 설치 온보딩을 실제 화면 단위로 구체화한다.
- 각 화면의 목적, 표시 요소, 버튼 구조, 분기 흐름을 명확히 한다.
- 구현 전에 KR/EN 초안 카피를 정리해 로컬라이제이션 키 설계의 기준으로 삼는다.

## 2. Wireflow overview

```text
App Launch
  └─ if onboarding required
      └─ Screen 1 Welcome
          └─ Continue
              └─ Screen 2 Accessibility Permission
                  ← Back: return to Screen 1
                  ├─ Request Access -> permission granted? -> yes -> Screen 3 Basic Setup
                  │                                           └─ no/unchanged -> stay on Screen 2
                  ├─ Open Settings -> return to app -> recheck -> granted? -> Screen 3
                  └─ Set Up Later -> Screen 4B Limited Mode Completion
              ← Back: return to Screen 2
              └─ Screen 3 Basic Setup
                  └─ Continue
                      ├─ if AX granted -> Screen 4A Ready to Monitor
                      └─ if AX denied -> Screen 4B Limited Mode Completion
  └─ else
      └─ Go directly to normal app startup
```

## 3. Entry and exit rules

### Entry conditions
- onboarding completed flag가 false
- required onboarding version보다 저장된 version이 낮음
- 사용자가 명시적으로 “온보딩 다시 보기”를 선택함

### Exit conditions
- Screen 4A 또는 4B의 primary CTA 탭
- 사용자가 `나중에 설정`을 통해 limited-mode 종료를 선택

### Resume rules
- 시스템 설정 앱에서 복귀하면 Screen 2에서 즉시 권한 상태를 재검사
- 앱 재실행 시 이미 저장된 basic setup 값은 다시 묻지 않음

### Window close rules
- Cmd+W 또는 Esc로 창을 닫은 경우:
  - Welcome 단계에서 닫으면: onboarding completed=true, `limitedNoAX`로 진입
  - Permission 단계에서 닫으면: onboarding completed=true, `limitedNoAX`로 진입
  - Basic Setup 단계에서 닫으면: 입력한 draft 값을 보존하고 다음 실행에서 이어서 진행 가능

## 4. Screen-by-screen spec

## Screen 1 — Welcome

### Goal
- 제품 가치와 신뢰 메시지를 짧게 전달한다.

### Layout
- 상단: 앱 아이콘 / 제품명
- 중단: headline + subheadline
- 하단: privacy reassurance bullet 2개
- footer: primary CTA

### Required elements
- Product name
- Value headline
- One-sentence explanation
- “수집하지 않음” 메시지 2개
- Primary CTA only

### Draft copy

| Element | KO | EN |
|---|---|---|
| Title | 넛지 | Nudge |
| Headline | 딴짓이 시작되면, 다시 돌아오게 | The moment attention drifts, Nudge brings you back |
| Body | 무입력 상태를 감지하고 부드럽게 작업 복귀를 돕는 메뉴바 앱입니다. | A menu bar app that detects idle moments and gently brings you back to work. |
| Bullet 1 | 키 입력 내용은 수집하지 않습니다. | Nudge does not collect keystroke content. |
| Bullet 2 | 화면 내용이나 스크린 캡처를 수집하지 않습니다. | Nudge does not collect screen contents or screenshots. |
| CTA | 시작하기 | Get Started |

### UX notes
- Welcome 화면에서는 권한 요청을 바로 붙이지 않는다.
- 사용자가 “무엇을 설치했는지”를 먼저 이해해야 한다.

---

## Screen 2 — Accessibility Permission

### Goal
- 왜 권한이 필요한지, 거부 시 무엇이 제한되는지, 어떻게 허용하는지 명확히 설명한다.

### Layout
- 상단: 권한 상태 badge
- 본문: 권한 필요 이유 + privacy disclosure summary
- 하단: primary / secondary / tertiary actions

### Required elements
- Current permission state
- Reason for permission
- Non-collection disclosure
- Primary CTA: request access
- Secondary CTA: open settings
- Tertiary CTA: set up later

### State badge draft

| State | KO | EN |
|---|---|---|
| Unknown | 확인 전 | Not checked |
| Granted | 허용됨 | Granted |
| Denied | 필요함 | Needed |

### Draft copy

| Element | KO | EN |
|---|---|---|
| Headline | 손쉬운 사용 권한이 필요해요 | Accessibility permission is needed |
| Body 1 | 넛지는 전역 입력 활동을 감지해 무입력 상태를 파악하고, 로컬 넛지를 표시하기 위해서만 이 권한을 사용합니다. | Nudge uses this permission only to detect global input activity, identify idle moments, and show local nudges. |
| Body 2 | 키 입력 내용, 화면 내용, 파일, 메시지, 브라우징 기록은 수집하지 않습니다. | Nudge does not collect keystroke content, screen contents, files, messages, or browsing history. |
| Body 3 | 지금 허용하지 않아도 앱은 제한 모드로 계속 사용할 수 있습니다. | If you do not allow it now, the app can still continue in limited mode. |
| Primary CTA | 권한 요청 | Request Access |
| Secondary CTA | 설정 열기 | Open Settings |
| Tertiary CTA | 나중에 설정 | Set Up Later |

### Interaction notes
- `권한 요청`은 prompt-capable trust check 호출
- `설정 열기`는 macOS Accessibility settings deeplink
- foreground 복귀 시 상태 재검사
- granted 시 자동으로 Screen 3 진행 가능

### Error / fallback note
- prompt 후 상태 변화가 없으면 에러 메시지보다 “설정 열기” 경로를 더 강조한다.

---

## Screen 3 — Basic Setup

### Goal
- 첫 실행에 필요한 최소 설정만 빠르게 정한다.

### Layout
- Group A: detection basics
  - idle threshold
  - launch at login
- Group B: guidance style
  - top overlay
  - visual mode
- footer: continue CTA

### Required controls
- Idle threshold segmented choices
- Launch at login toggle
- Top overlay toggle
- Visual mode segmented control

### Draft copy

| Element | KO | EN |
|---|---|---|
| Headline | 처음 사용할 기본 설정을 정할게요 | Let’s set your starting defaults |
| Body | 나중에 설정에서 언제든 바꿀 수 있습니다. | You can change these later in Settings. |
| Idle threshold label | 무입력 기준 시간 | Idle threshold |
| Idle option 1 | 3분 | 3 min |
| Idle option 2 | 5분(추천) | 5 min (Recommended) |
| Idle option 3 | 10분 | 10 min |
| Launch at login label | 로그인 시 자동 실행 | Launch at login |
| Launch at login help | Mac을 켤 때 자동으로 시작합니다. | Start automatically when you sign in to your Mac. |
| Top overlay label | 상단 카운트다운 표시 | Show top countdown overlay |
| Top overlay help | 모니터링 중 남은 시간을 화면 상단에 표시합니다. | Show the remaining countdown at the top of the screen while monitoring. |
| Visual mode label | 기본 표시 방식 | Visual mode |
| Visual option 1 | 새싹 | Sprout |
| Visual option 2 | 미니멀 | Minimal |
| CTA | 계속 | Continue |

### UX notes
- Launch at login은 device-local setting임을 내부 구현에서 분리
- 이 화면에서 고급 옵션 링크를 넣지 않는다

---

## Screen 4A — Completion / Ready to Monitor

### Goal
- 권한 허용 완료 후 바로 사용할 수 있다는 확신을 준다.

### Layout
- success state icon
- headline
- summary list
- primary CTA

### Draft copy

| Element | KO | EN |
|---|---|---|
| Headline | 모니터링 준비가 완료됐어요 | Nudge is ready to monitor |
| Body | 이제 메뉴바에서 상태와 카운트다운을 확인할 수 있습니다. | You can now check status and countdown from the menu bar. |
| Summary label 1 | 무입력 기준 시간 | Idle threshold |
| Summary label 2 | 로그인 시 자동 실행 | Launch at login |
| Summary label 3 | 상단 오버레이 | Top overlay |
| Summary label 4 | 표시 방식 | Visual mode |
| CTA | 메뉴바에서 시작 | Continue to Menu Bar |

### CTA behavior candidates
- close onboarding and leave app in active menu bar state
- optionally pulse/highlight the menu bar icon once

---

## Screen 4B — Completion / Limited Mode

### Goal
- 권한 거부가 앱 실패가 아님을 설명하고, 복구 경로를 명확히 남긴다.

### Layout
- caution state icon
- headline
- limitation explanation
- primary + secondary actions

### Draft copy

| Element | KO | EN |
|---|---|---|
| Headline | 제한 모드로 시작할게요 | Starting in limited mode |
| Body 1 | 손쉬운 사용 권한이 없으면 백그라운드 전역 입력 감지가 불가능합니다. | Without Accessibility permission, Nudge cannot detect global background input activity. |
| Body 2 | 그래서 무입력 감지와 자동 복귀 루프는 완전하게 동작하지 않습니다. | That means idle detection and the automatic return loop will not work fully. |
| Body 3 | 권한은 나중에 메뉴나 설정에서 다시 허용할 수 있습니다. | You can allow the permission later from the menu or in Settings. |
| Primary CTA | 메뉴바에서 계속 | Continue in Menu Bar |
| Secondary CTA | 권한 다시 설정 | Set Up Permission Again |

### UX notes
- “부분 동작”이라는 표현은 실제 구현 범위가 확정되기 전까지 남용하지 않는다.
- 사용자가 죄책감 없이 나중에 복귀할 수 있는 톤 유지

## 5. Navigation rules by action

| Screen | Action | Result |
|---|---|---|
| Welcome | Get Started | Go to Permission |
| Permission | Request Access | Recheck permission; if granted go to Basic Setup |
| Permission | Open Settings | Open system settings; on return recheck |
| Permission | Set Up Later | Go to Limited Mode completion |
| Basic Setup | Continue | Go to Ready or Limited completion based on AX state |
| Ready completion | Continue to Menu Bar | Dismiss onboarding |
| Limited completion | Continue in Menu Bar | Dismiss onboarding in `limitedNoAX` |
| Limited completion | Set Up Permission Again | Return to Permission step |
| Permission | Back | Return to Welcome |
| Basic Setup | Back | Return to Permission, preserve draft values |
| Any screen | Cmd+W / Esc | Close window (see Window close rules) |

## 6. Suggested localization key groups

추천 키 그룹:

- `onboarding.welcome.*`
- `onboarding.permission.*`
- `onboarding.setup.*`
- `onboarding.completion.ready.*`
- `onboarding.completion.limited.*`
- `onboarding.common.*`

예시:
- `onboarding.permission.title`
- `onboarding.permission.body.reason`
- `onboarding.permission.cta.request`
- `onboarding.setup.idle_threshold.label`
- `onboarding.completion.limited.body.primary`

## 7. Layout and accessibility notes

- KR/EN 모두 2줄 래핑 허용
- CTA 버튼 고정 폭 금지
- 상태 전달은 아이콘 + 텍스트 동시 사용
- permission / limited completion 화면은 색상만으로 성공/제한 상태를 구분하지 않음
- macOS 작은 창 크기에서도 1-screen scrolling 없이 보여줄 수 있도록 정보량 제한
- 최소 윈도우 너비 480pt, 높이 400pt 기준으로 레이아웃 검증
- 다크모드에서 카드 배경, 그림자, 상태 badge 색상이 가독성을 유지해야 함
- VoiceOver: 각 화면의 제목/본문/버튼이 의미 있는 accessibility label을 가져야 함
- 키보드: Tab으로 CTA 간 이동, Enter/Space로 실행, Esc로 창 닫기 지원

## 8. Out-of-scope copy

아래 문구는 온보딩에서 직접 다루지 않는다.

- CloudKit / iOS companion 설명
- Pro 업그레이드 CTA
- whitelist 설정 가이드
- detailed stats / XP / streak 설명
- system notification permission 문구

## 9. Open copy questions

- 제품 1줄 설명에서 `집중 복귀 도구`를 직접 노출할지 여부
- `메뉴바에서 시작`보다 더 자연스러운 완료 CTA가 필요한지 여부
- `나중에 설정`과 `건너뛰기` 중 어느 표현이 더 적절한지 여부
- launch at login 기본값을 정말 `on`으로 둘지 여부
