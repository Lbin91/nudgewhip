# NudgeWhip Task: Countdown Overlay Mini State Feedback

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: product / engineering
- Related:
  - `docs/app/task-countdown-overlay-mini-and-positioning.md`
  - `docs/app/countdown-overlay-mini-hover-affordance-experiment.md`
  - `docs/app/countdown-overlay-mini-state-feedback-examples.md`
  - `docs/app/task-countdown-overlay-mini-state-feedback-implementation-plan.md`
  - `docs/app/task-countdown-overlay-mini-state-feedback-review.md`

## 1. Purpose

- 이 문서는 mini countdown overlay가 `상태를 너무 축약해서 보여줄 때 생기는 혼란`을 줄이기 위한 피드백 설계를 정의한다.
- 특히 `AX`처럼 정상 상태가 아닌 축약 토큰이 표시될 때, 사용자가 `버그인지, 경고인지, 내가 뭘 해야 하는지`를 이해할 수 있게 만드는 것이 목적이다.

## 2. Problem Statement

현재 mini overlay는 공간 제약 때문에 상태를 짧은 토큰으로 축약한다.

예:

- `IDLE`
- `PAUSE`
- `ALLOW`
- `SCHED`
- `SLEEP`
- `AX`

이 방식은 평소에는 충분히 가볍지만, 다음 문제가 있다.

1. 정상 상태가 아닌 토큰(`AX`)이 갑자기 보이면 사용자가 의미를 바로 이해하기 어렵다.
2. 흰색 단일 텍스트만으로는 `그냥 상태 표시`와 `주의가 필요한 상태`의 우선순위가 구분되지 않는다.
3. 사용자가 왜 저 상태가 떴는지, 뭘 해야 해소되는지 overlay 안에서 직접 알 수 없다.

즉, mini overlay는 단순히 `작은 표시`를 넘어서, **경고 상태에서는 작은 상태 피드백 UI**가 되어야 한다.

## 3. Product Goal

- 정상 상태에서는 지금처럼 조용하고 가볍게 유지한다.
- 비정상/주의 상태에서는 시각 강조를 통해 `이건 그냥 정보가 아니라, 이해가 필요한 상태`라는 점을 전달한다.
- 사용자가 작은 info affordance를 눌러 `무슨 상황인지`를 바로 이해할 수 있게 한다.

## 4. Scope

이번 문서가 다루는 범위:

- mini overlay의 warning-state text color
- mini overlay의 `info` affordance
- info affordance 클릭 시 노출되는 explanatory feedback
- 어떤 상태를 warning-state로 볼지에 대한 기준

비범위:

- standard overlay 전체 재설계
- fullscreen modal / sheet 도입
- 설정 화면 전체 리디자인
- 접근성 권한 획득 플로우 자체 변경

## 5. State Classification

mini overlay 상태는 아래 두 부류로 나눈다.

### 5.1 Neutral States

일반적인 운영 상태. 현재처럼 기본 흰색 텍스트를 유지한다.

- `monitoring` → countdown
- `pausedManual` → `PAUSE`
- `pausedWhitelist` → `ALLOW`
- `pausedSchedule` → `SCHED`
- `suspendedSleepOrLock` → `SLEEP`

### 5.2 Attention States

사용자 이해 또는 조치가 필요한 상태. 색상 강조와 info affordance 대상이다.

- `limitedNoAX` → 현재 표시 토큰 `AX`
- `alerting` → 현재 표시 토큰 `IDLE`

권장 우선순위:

- **Phase 1 우선 대상은 `limitedNoAX`**
- `limitedNoAX`는 **설정/권한 복구 필요 상태**
- `alerting`은 **실시간 주의 상태**이지만 체류 시간이 짧을 수 있으므로 `AX` 안정화 후 2순위로 확장한다

둘 다 기본 neutral 상태와 동일한 흰색 텍스트로만 처리하면 구분력이 약하다.

## 6. Recommended Visual Contract

### 6.1 Neutral State

- 텍스트 색상: 흰색
- capsule/stroke: 현재 mini baseline 유지
- info affordance: 숨김

### 6.2 Attention State

#### limitedNoAX (`AX`)

- 텍스트 색상: 경고 amber / yellow 계열
- capsule background는 기존 대비를 유지하되 과한 점멸은 금지
- trailing `i` affordance 노출
- 기존 디자인 토큰 기준 권장 매핑: `Color.nudgewhipAccent`

의도:

- `오류`보다 `설정 필요`에 가까운 경고
- 사용자를 겁주지 않고, 해석이 필요한 상태임을 표시

#### alerting (`IDLE`)

- 텍스트 색상: alert red / orange-red 계열
- trailing `i` affordance 노출
- 기존 디자인 토큰 기준 권장 매핑: `Color.nudgewhipAlert`

의도:

- 지금 넛지가 활성 상태이며 즉각적인 맥락 안내가 가능하다는 점을 표시

## 7. Info Affordance Contract

### 7.1 Appearance

- mini overlay 오른쪽 끝에 작은 `i.circle` 또는 `info` 계열 아이콘 노출
- hover가 아니라 **attention state일 때는 기본 노출**
- hover close affordance 실험과 충돌하지 않도록 `close`와 `info`의 우선순위를 명확히 정해야 한다

권장 규칙:

- neutral state: `close`만 hover 시 노출
- attention state: `info`를 우선 노출, `close`는 hover 시 보조 노출 또는 비노출 검토

레이아웃 고정 기준:

- mini panel 크기: `96x32`
- token 영역: 좌측 기준 약 `56pt`
- token과 info 사이 gap: `4pt`
- info affordance hit area: 최소 `16x16`, 가능하면 `18x18`
- attention state에서는 공간 충돌을 막기 위해 `close` affordance를 기본 숨김 처리하는 것을 우선 고려한다

### 7.2 Interaction

- 클릭 시 작은 설명성 popover / tooltip / transient panel 중 하나를 띄운다
- 설명은 짧고 행동 가능해야 한다
- overlay 자체보다 크게 방해되지 않아야 한다

권장 구현 방향:

- 첫 단계는 **small popover anchored to the mini overlay**
- modal이나 settings window 강제 오픈은 하지 않는다
- 단, 현재 overlay가 `NSPanel + NSHostingView` 구조이므로 SwiftUI 기본 `.popover`가 충분하지 않을 수 있다
- 구현 전제는 `NSPopover` 직접 사용 또는 별도 anchored panel 대안 검토다

## 8. Feedback Content Contract

### 8.1 limitedNoAX

제목 예시:

- KR: `손쉬운 사용 권한이 필요해요`
- EN: `Accessibility access is needed`

본문 예시:

- KR: `NudgeWhip가 입력 멈춤을 감지하려면 손쉬운 사용 권한이 필요합니다. 설정에서 허용하면 카운트다운과 감지가 정상 동작합니다.`
- EN: `NudgeWhip needs Accessibility access to detect idle input reliably. Enable it in System Settings to restore normal monitoring.`

CTA 후보:

- `Open Settings`
- `Why this appears`

권장 동작:

- 가능하면 `MenuBarViewModel.openAccessibilitySettings()`를 직접 호출하는 경로를 우선 사용한다

### 8.2 alerting

제목 예시:

- KR: `입력이 멈춘 상태예요`
- EN: `Idle input detected`

본문 예시:

- KR: `설정한 기준 시간 동안 입력이 없어 넛지를 보여주고 있어요. 활동을 다시 시작하면 자동으로 돌아갑니다.`
- EN: `There has been no input for your configured threshold, so NudgeWhip is showing a nudge. It clears automatically when activity resumes.`

CTA 후보:

- `Dismiss hint`
- `Open menu`

우선순위 메모:

- `IDLE`은 설명 가치가 있지만, 실제 체류 시간이 짧을 수 있으므로 first-pass에서는 color + icon만 우선 적용하고 popover는 AX부터 도입해도 된다

## 9. Interaction Priority Rules

mini overlay에는 현재 혹은 계획상 다음 affordance가 동시에 존재할 수 있다.

- hover close affordance
- attention-state info affordance

둘이 충돌하지 않도록 아래 우선순위를 권장한다.

### Recommended

1. `attention state`일 때는 `info` affordance가 기본 우선
2. `close` affordance는 hover 시 secondary affordance로만 노출
3. 공간이 부족하면 attention state에서는 `close`를 생략하고 menu/settings 경로로 남긴다
4. attention popover가 떠 있는 동안 runtime state가 바뀌면 popover는 즉시 dismiss한다

## 10. Accessibility

- 색상만으로 상태를 구분하지 않는다
- info affordance에는 명확한 accessibility label을 제공한다
- text color 변화 + 아이콘 + explanatory feedback의 3단 구성을 권장한다

예:

- `AX` + amber + info button
- VoiceOver label: `Accessibility access needed. More information.`

## 11. Technical Direction

예상 변경 면:

- `nudgewhip/Views/CountdownOverlayController.swift`
- `nudgewhip/Services/MenuBarViewModel.swift`
- `nudgewhip/Settings/SettingsRootView.swift` (필요 시 helper copy)
- `nudgewhip/Localizable.xcstrings`
- `nudgewhipTests/nudgewhipTests.swift`
- `nudgewhipUITests/nudgewhipUITests.swift` (필요 시)

구현 포인트:

- runtime state → overlay visual role 매핑
- mini attention state에서 foreground color 분기
- info button visibility rule
- info button tap target
- explanatory popover content source
- `NSPopover` 또는 anchored panel 기반 explanation surface 검토
- state transition 시 popover dismiss rule

## 12. Acceptance Criteria

- neutral state에서는 기존 mini처럼 조용하게 유지된다
- `AX` 상태에서는 기본 흰색이 아닌 경고 시각 처리로 구분된다
- `AX` 상태에서 info affordance를 눌렀을 때 의미와 다음 행동이 설명된다
- `IDLE` 상태는 최소한 neutral과 구분되는 attention visual treatment를 가진다
- `IDLE` 상태 popover는 2차 구현으로 미뤄질 수 있으나, 미룰 경우 문서와 구현 범위가 일치해야 한다
- 색상, 아이콘, 접근성 라벨이 함께 제공된다
- mini overlay가 과도하게 복잡해지지 않는다

## 13. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| mini overlay가 너무 많은 역할을 하게 됨 | 간결함 상실 | attention state에만 info affordance 제한 |
| close/info affordance 충돌 | 클릭 혼란 | attention state 우선순위 규칙 고정 |
| 색상 강조가 과도해 보임 | 시각 피로 | amber/red 계열도 저채도로 유지 |
| info popover가 또 다른 방해물처럼 느껴짐 | UX 복잡도 증가 | small anchored popover로 제한 |

## 14. Bottom Line

- mini overlay는 평소에는 조용해야 하지만, 경고 상태에서는 `조용한데 이해 불가한 UI`가 되면 안 된다.
- 따라서 `attention state color + info affordance + short explanatory feedback` 조합이 필요하다.
- 가장 우선 적용할 상태는 `AX (limitedNoAX)`이고, 그 다음이 `IDLE (alerting)`이다.
