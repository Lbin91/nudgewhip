# NudgeWhip Task: Countdown Overlay Mini Mode and Positioning

- Version: draft-2
- Last Updated: 2026-04-12
- Status: proposed
- Owner: product / engineering
- Priority: P1
- Related: `v0.3` daily usability polish

## 1. Purpose

- 이 문서는 사용 중 체감된 `countdown overlay 피로감`을 줄이기 위한 다음 단계 기획을 정리한다.
- 핵심은 두 가지다.
- `mini overlay`를 도입해 시각적 존재감을 줄인다.
- overlay 위치를 `좌상단 / 우상단 / 좌하단 / 우하단` 4곳 중 선택 가능하다는 제품 계약을 명확히 고정한다.

## 2. Problem Statement

현재 countdown overlay는 기능적으로는 유용하지만, 장시간 사용 시 아래 문제가 있다.

1. 화면에 상주하는 시각 무게가 생각보다 크다.
2. countdown 자체보다 `브랜드 라벨 + 부가 상태 텍스트 + close affordance`가 더 눈에 들어올 수 있다.
3. 사용자는 overlay를 켜 두고 싶어도, 현재 형태가 계속 눈에 걸리면 결국 꺼 버릴 가능성이 있다.
4. 사용자 인식상 overlay는 여전히 `화면 상단 좌측 고정`처럼 느껴질 수 있다.

즉, 문제는 overlay의 존재 자체가 아니라 `존재감의 크기와 배치 유연성`이다.

## 3. Current State

현재 코드베이스 기준 사실관계는 아래와 같다.

- 표준 overlay는 `146x72` 고정 크기 패널이다.
- 내용 구성은 `NUDGE 라벨 + 큰 primary text + 상태 설명 + 상시 close 버튼`이다.
- 위치 계산 함수는 이미 `topLeft`, `topRight`, `bottomLeft`, `bottomRight`를 지원한다.
- `UserSettings`, `MenuBarViewModel`, `SettingsViewModel`, `SettingsRootView`에도 4코너 위치 설정 surface가 존재한다.

즉, `4코너 위치 선택`은 순수 신규 아이디어가 아니라 **이미 구현 surface가 있는 기능을 제품 계약으로 명확히 정리하고 다듬는 작업**에 가깝다.

반면 아직 부족한 부분은 아래다.

- overlay가 여전히 크고 시선 점유율이 높다.
- Settings/Onboarding 문구 일부가 여전히 `top countdown overlay`, `Top overlay` 표현을 사용한다.
- mini mode에 대한 명세가 없다.
- "작고 덜 거슬리는 overlay"를 무엇으로 볼지 시각 계약이 없다.
- UITest 문구도 아직 기존 `Show top countdown overlay` 표현을 참조한다.

## 4. Goals

### 4.1 Product Goals

- overlay를 끄지 않고도 계속 사용할 수 있을 만큼 부담을 낮춘다.
- countdown의 핵심 가치인 `남은 시간 한눈에 보기`는 유지한다.
- 위치 선택을 통해 각 사용자 작업 환경에 맞게 배치할 수 있게 한다.

### 4.2 UX Goals

- 한 번 봤을 때 바로 읽힌다.
- 주변 시야를 덜 가린다.
- 상단에만 있는 UI처럼 느껴지지 않는다.

### 4.3 Success Criteria

- mini mode 사용 시 현재 표준 overlay 대비 시각 면적이 최소 `55%` 이상 감소한다.
- 4코너 위치 변경이 즉시 반영된다.
- KR/EN 모두 truncation 없이 읽힌다.
- 문서/설정/온보딩 어디에도 `top overlay`라는 고정 위치 전제가 남지 않는다.

## 5. Non-goals

- 자유 드래그 배치
- 모니터별 별도 위치 기억
- 화면 중앙 / 엣지 중간 지점 배치
- overlay animation 시스템 대개편
- iOS companion과의 동기화 설정

이번 범위는 `mini mode + 4 corners + copy alignment`까지만 다룬다.

## 6. Recommended Product Decision

### 6.1 Overlay Variants

다음 버전에서는 overlay를 2종으로 운영한다.

- `standard`
- `mini`

### 6.2 Recommended Default Strategy

- 신규 설치 기본값: `mini`
- 기존 사용자 마이그레이션: 현재 체감을 갑자기 바꾸지 않도록 `standard` 유지

이 결정의 이유는 아래와 같다.

- 신규 사용자는 처음부터 부담이 적은 형태를 경험하는 편이 낫다.
- 기존 사용자는 예고 없이 UI가 작아지면 정보 손실처럼 느낄 수 있다.

### 6.3 Explicit Implementation Decisions

구현 전 아래 결정을 이번 문서에서 고정한다.

1. `panelSize`는 `static let` 고정값이 아니라 **variant 기반 computed size**로 전환한다.
2. `observeVisibility()`는 `enabled`, `position`뿐 아니라 `variant` 변경도 추적한다.
3. `limitedNoAX` 표기는 **mini에서만 `AX`**, standard에서는 기존 임계값 표시를 유지한다.
4. Settings preview는 **경량 프리뷰 스와치**만 제공하고, 실제 NSPanel 수준의 라이브 시뮬레이터는 이번 범위에서 제외한다.
5. variant 전환은 **애니메이션 없이 즉시 교체**한다. 사이즈 변화 연출은 이번 범위 밖이다.

## 7. Mini Overlay Contract

### 7.1 Form Factor

- 형태: 작은 `capsule` 또는 낮은 높이의 rounded rectangle
- 목표 크기:
- monitoring countdown 기준 `92~100pt` width
- height `30~34pt`
- inset은 현재 `14pt`에서 `12pt` 수준으로 축소 가능

권장 기준안:

- target size: `96x32`

현재 `146x72` 대비 충분히 작고, 숫자 정보는 유지 가능한 수준이다.

### 7.2 Content Rules

mini mode에서는 정보 우선순위를 강하게 줄인다.

- `NUDGE` 브랜드 라벨 제거
- 상태 보조 문구 제거
- 상시 노출 close button 제거

표시 규칙:

- `monitoring`: 남은 시간만 표시 (`4m`, `58s`)
- `alerting`: `IDLE`
- `pausedManual`: `PAUSE`
- `pausedWhitelist`: `ALLOW`
- `pausedSchedule`: `SCHED`
- `suspendedSleepOrLock`: `SLEEP`
- `limitedNoAX`: `AX`

이 토큰은 영문 고정 축약형으로 두고, 필요 시 접근성 label에서 풀 문장을 제공한다.

### 7.3 Visual Rules

- 배경 opacity는 standard보다 낮춘다.
- stroke는 유지하되 대비가 과하지 않도록 약화한다.
- 그림자 없이 평평한 capsule에 가깝게 유지한다.
- 숫자 텍스트는 monospaced를 유지한다.

### 7.4 Interaction Rules

- mini mode에서는 close affordance를 상시 노출하지 않는다.
- overlay on/off는 menu/settings에서 제어한다.
- mini mode는 `display utility`이지 `조작 UI`가 아니다.
- baseline contract에서는 mini mode가 마우스 이벤트를 가로채지 않는 방향을 우선한다.
- standard mode는 기존 close affordance를 유지하므로 `ignoresMouseEvents = false`를 유지한다.

후속 검토 항목:

- hover 시에만 닫기 버튼을 노출할지 여부는 별도 polish 항목으로 둔다.
- warning state(`AX`, `IDLE`)에서 색상 강조와 info affordance를 둘지 여부는 별도 state-feedback 문서로 분리한다.

현재 follow-up:

- `countdown-overlay-mini-hover-affordance-experiment.md`에서 mini hover close affordance 실험을 별도 추적한다.
- 이 실험이 활성화된 빌드에서는 mini mode도 hover 감지를 위해 mouse events를 받는다.
- `task-countdown-overlay-mini-state-feedback.md`에서 warning-state color / info affordance / explanatory feedback을 별도 추적한다.

## 8. Standard Overlay Contract

standard는 현재 오버레이를 거의 유지하되, 아래만 정리한다.

- `position` 계약을 공식화한다.
- copy에서 `top`이라는 표현을 제거한다.
- mini mode 도입 후에도 `standard`는 정보량이 많은 대안으로 유지한다.
- `limitedNoAX` 상태에서는 기존처럼 configured idle threshold를 보여준다.

즉, 이번 작업은 standard를 없애는 것이 아니라 `mini를 기본 경량 옵션으로 추가`하는 것이다.

## 9. Positioning Contract

### 9.1 Supported Positions

- `topLeft`
- `topRight`
- `bottomLeft`
- `bottomRight`

### 9.2 Placement Rules

- 좌표 계산 기준은 `NSScreen.main ?? NSScreen.screens.first`
- 위치 계산 기준은 `visibleFrame`
- 멀티 모니터 정책은 이번 범위에서 `주요 화면 1장` 유지

Corner 계산 규칙:

- `topLeft`: `visibleFrame.minX + inset`, `visibleFrame.maxY - inset - panelHeight`
- `topRight`: `visibleFrame.maxX - inset - panelWidth`, `visibleFrame.maxY - inset - panelHeight`
- `bottomLeft`: `visibleFrame.minX + inset`, `visibleFrame.minY + inset`
- `bottomRight`: `visibleFrame.maxX - inset - panelWidth`, `visibleFrame.minY + inset`

### 9.3 Default Position

- 기본값은 기존 호환성을 위해 `topLeft`를 유지한다.
- 단, mini mode 도입 후 사용자 피드백을 보면 `bottomRight`를 신규 설치 기본값 후보로 재평가할 수 있다.

## 10. Settings and Onboarding IA

### 10.1 Settings

Monitoring 섹션 계약:

- Toggle: `Show countdown overlay`
- Variant control: `Standard | Mini`
- Position picker: 2x2 corner buttons
- Preview area: 현재 선택 variant/position을 반영하는 **경량 프리뷰 스와치**

권장 순서:

1. on/off
2. variant
3. position
4. helper text

프리뷰 범위 제한:

- 실제 overlay window를 settings 안에서 띄우지 않는다.
- miniature card/capsule 형태로만 시각 계약을 보여준다.
- 이번 스프린트에서는 `variant + position` 확인이 목적이며, 초 단위 라이브 countdown 시뮬레이션은 비범위다.

### 10.2 Onboarding

온보딩은 복잡도를 늘리지 않도록 축소 적용한다.

- 온보딩에서는 overlay `on/off`만 유지
- variant와 position은 Settings에서 조정
- completion summary 문구는 `Top overlay`가 아니라 `Countdown overlay`로 통일

이 결정은 초기 진입 복잡도를 늘리지 않기 위한 것이다.

## 11. Copy and Localization Rules

이번 작업에서 반드시 함께 정리해야 하는 문구:

- `Show top countdown overlay` → `Show countdown overlay`
- `Top overlay` → `Countdown overlay`
- 관련 한국어도 `상단 카운트다운 표시`보다 위치 중립적 표현으로 변경

권장 표현:

- KR: `카운트다운 오버레이 표시`
- EN: `Show countdown overlay`

mini/standard variant 문구:

- KR: `표준`, `미니`
- EN: `Standard`, `Mini`

## 12. Technical Surfaces

예상 변경 면은 아래와 같다.

- `nudgewhip/Shared/Models/UserSettings.swift`
- `nudgewhip/Views/CountdownOverlayController.swift`
- `nudgewhip/Services/MenuBarViewModel.swift`
- `nudgewhip/Settings/SettingsViewModel.swift`
- `nudgewhip/Settings/SettingsRootView.swift`
- `nudgewhip/Onboarding/Views/BasicSetupStepView.swift`
- `nudgewhip/Onboarding/Views/CompletionReadyStepView.swift`
- `nudgewhip/Onboarding/Views/OnboardingRootView.swift`
- `nudgewhipUITests/nudgewhipUITests.swift`
- `nudgewhip/Localizable.xcstrings`
- `docs/qa/localization-test-matrix.md`

권장 모델 추가:

- `CountdownOverlayVariant`
- case: `.standard`, `.mini`

## 13. Acceptance Criteria

- Settings에서 `standard`와 `mini`를 전환할 수 있다.
- Settings에서 4코너 위치를 전환할 수 있고, overlay가 즉시 재배치된다.
- variant 전환 시 panel 크기와 마우스 이벤트 처리 방식이 즉시 바뀐다.
- mini mode는 standard 대비 면적이 명확히 작다.
- mini mode에서 countdown 가독성이 유지된다.
- settings의 경량 프리뷰가 variant/position 선택을 설명할 수 있다.
- settings/onboarding/completion summary의 위치 관련 copy가 모두 중립 표현으로 정리된다.
- KR/EN 모두 truncation 없이 동작한다.
- standard mode 동작 회귀가 없다.

## 14. QA Matrix

필수 축:

- variant: `standard`, `mini`
- position: 4 corners
- locale: `ko`, `en`
- state: `monitoring`, `alerting`, `pausedManual`, `pausedSchedule`, `limitedNoAX`
- appearance: light, dark
- accessibility: increase contrast, reduce transparency

필수 시나리오:

- [ ] standard → mini 전환 즉시 반영
- [ ] 각 코너 선택 즉시 재배치
- [ ] mini는 마우스 클릭을 가로채지 않고 standard는 기존 close affordance가 유지됨
- [ ] countdown 59s / 1m / 10m 표시 확인
- [ ] `IDLE`, `PAUSE`, `ALLOW`, `SCHED`, `SLEEP`, `AX` 축약 상태 확인
- [ ] KR/EN 설정 문구 truncation 없음
- [ ] Settings preview가 variant/position 변경을 올바르게 반영
- [ ] onboarding/completion summary 용어 정합성 확인

## 15. Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| mini가 너무 작아 가독성이 떨어짐 | 사용자 불만, 결국 비활성화 | 숫자 우선, 96x32 기준안에서 시작, 실제 사용 테스트 |
| close affordance 제거가 불편함 | 즉시 끄기 어려움 | menu/settings 토글 유지, hover affordance는 후속 후보로 보류 |
| 4코너 지원이 이미 있는데 copy가 뒤따르지 않음 | 사용자 혼란 | copy migration을 이번 범위의 필수 항목으로 묶음 |
| onboarding에 옵션이 많아짐 | 첫 설치 피로 증가 | onboarding은 on/off만 유지, 상세 설정은 settings로 이동 |

## 16. Recommended Implementation Order

1. copy와 IA 정리
2. `CountdownOverlayVariant` 모델 추가
3. `CountdownOverlayController` mini layout 구현
4. Settings preview 및 variant selector 연결
5. QA matrix 수행

## 17. Bottom Line

- countdown overlay의 다음 단계는 `더 많은 정보`가 아니라 `덜 거슬리는 존재감`이다.
- 가장 적절한 방향은 `mini mode + 4-corner positioning + copy alignment` 조합이다.
- 이 작업은 제품 완성도 대비 구현 부담이 비교적 낮고, 장시간 사용성 개선 효과가 직접적이다.
