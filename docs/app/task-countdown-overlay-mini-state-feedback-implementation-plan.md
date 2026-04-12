# Countdown Overlay Mini State Feedback Implementation Plan

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: engineering
- Related:
  - `docs/app/task-countdown-overlay-mini-state-feedback.md`
  - `docs/app/countdown-overlay-mini-state-feedback-examples.md`

## 1. Purpose

- 이 문서는 mini overlay state feedback를 실제 구현 작업으로 쪼갠 실행 계획이다.
- 목표는 “좋아 보이는 아이디어”를 넘어서, **어떤 파일을 어떻게 바꾸고 무엇으로 검증할지**를 바로 알 수 있게 만드는 것이다.

## 2. Target Outcome

첫 구현 패스에서 달성할 목표:

- `AX`와 `IDLE`를 attention state로 분류
- attention state에서 텍스트 색상 강조
- first-pass에서는 `AX`를 최우선 대상으로 처리
- attention state에서 info affordance 노출
- info click 시 small explanatory popover 노출 (`AX`부터)
- neutral state는 현재 mini 감각 유지

## 3. Recommended Scope Split

### Phase 1 — Visual Role Mapping

- runtime state → `neutral / attention` 매핑
- attention state text color 분기
- info button visibility 분기
- attention state의 96×32 레이아웃 고정

### Phase 2 — Explanation Surface

- small anchored popover UI
- AX / IDLE 별 설명 copy
- 접근성 label / hint 추가

기술 전제:

- overlay는 `NSPanel + NSHostingView` 구조라 SwiftUI 기본 `.popover` 의존이 위험하다
- `NSPopover` 직접 사용 또는 별도 anchored panel 구현을 먼저 POC로 검증한다

### Phase 3 — QA and Polish

- hover close와 info affordance 충돌 정리
- light/dark, contrast, KR/EN 확인
- click target / layout 미세 조정

## 4. Implementation Tasks

## T1. Overlay visual-role abstraction 추가

목표:

- mini overlay가 현재 runtime state를 직접 해석하기보다, `visual role` 개념으로 다루게 한다.

권장 타입 예시:

- `MiniOverlayVisualRole`
- case:
  - `.neutral(text: String)`
  - `.attention(text: String, kind: AttentionKind)`

권장 위치:

- `nudgewhip/Views/CountdownOverlayController.swift`

완료 기준:

- AX / IDLE 여부를 뷰 본문에서 중복 분기하지 않고 visual-role layer에서 결정한다.

## T2. AttentionKind 정의

목표:

- AX와 IDLE이 서로 다른 피드백 메시지와 색을 가질 수 있게 한다.

권장 타입 예시:

- `MiniOverlayAttentionKind`
- case:
  - `.accessibilityNeeded`
  - `.idleDetected`

완료 기준:

- attention state마다 color, icon meaning, feedback content source를 분기할 수 있다.

## T3. Mini overlay text color 분기

목표:

- neutral은 white
- accessibilityNeeded는 `Color.nudgewhipAccent`
- idleDetected는 `Color.nudgewhipAlert`

변경 면:

- `nudgewhip/Views/CountdownOverlayController.swift`

완료 기준:

- AX / IDLE 시 시각적으로 neutral state와 바로 구분된다.

## T4. Info affordance 추가

목표:

- attention state에서만 `i.circle` 계열 버튼을 노출한다.

변경 면:

- `nudgewhip/Views/CountdownOverlayController.swift`

고려 사항:

- hover close affordance와 공존 규칙
- 우측 공간 확보
- hit area 16x16 이상
- attention state에서는 `close`를 기본 생략하는 레이아웃도 허용

완료 기준:

- AX / IDLE에서 info affordance를 누를 수 있다.

## T5. Explanation popover 구현

목표:

- info button 클릭 시 작은 anchored popover를 띄운다.

권장 조건:

- modal 아님
- 작은 설명 카드
- overlay 맥락을 크게 깨지 않음
- runtime state 전환 시 즉시 dismiss

변경 면:

- `nudgewhip/Views/CountdownOverlayController.swift`
- 필요 시 설명 전용 작은 서브뷰 추출

기술 리스크:

- SwiftUI `.popover`가 NSPanel 환경에서 예상대로 동작하지 않을 수 있음
- first-pass 구현은 `NSPopover` 직접 사용 또는 AppKit 브리징을 우선 검토

완료 기준:

- AX 설명 popover가 우선 구현된다.
- IDLE 설명 popover는 Phase 2 후반 또는 후속 단계로 미뤄질 수 있으며, 미룰 경우 문서상 범위를 갱신한다.

## T6. Copy / Localization 추가

필요 문자열:

- AX title/body/CTA
- IDLE title/body/CTA
- info button accessibility label

변경 면:

- `nudgewhip/Localizable.xcstrings`

완료 기준:

- KR/EN 모두 의미가 자연스럽고 짧다.

## T7. Accessibility 보강

목표:

- 색상만으로 상태를 전달하지 않음
- VoiceOver가 상태와 info affordance를 이해할 수 있음

필요 항목:

- mini overlay label
- info button label
- info popover heading accessibility

완료 기준:

- attention state에서 VoiceOver로 의미가 충분히 전달된다.

## T8. Hover close 우선순위 조정

목표:

- attention state일 때 info와 close가 충돌하지 않게 한다.

권장 규칙:

- attention state:
  - info 우선
  - close는 hover 시 secondary로만 노출하거나 숨김

완료 기준:

- 작은 공간에서 affordance 충돌이 줄어든다.

## T9. Attention-state 픽셀 레이아웃 고정

목표:

- 96×32 안에서 token + info affordance + hit area를 안전하게 배치한다.

권장 규칙:

- token 영역 약 `56pt`
- gap `4pt`
- info hit area `16~18pt`
- attention state에서는 close affordance를 기본 숨김

완료 기준:

- AX와 IDLE의 실제 렌더링이 96pt 안에서 겹치지 않는다.

## 5. File-level Plan

### Primary

- `nudgewhip/Views/CountdownOverlayController.swift`

### Secondary

- `nudgewhip/Localizable.xcstrings`
- `nudgewhipTests/nudgewhipTests.swift`
- `nudgewhipUITests/nudgewhipUITests.swift` (필요 시)

### Optional

- `nudgewhip/Services/MenuBarViewModel.swift`
  - 상태 설명 문자열 재사용이 필요할 경우

## 6. Test Plan

### Unit / View-level

- AX role mapping
- IDLE role mapping
- neutral role mapping 유지
- text color selection logic
- info affordance visibility logic

### UI behavior

- AX 상태에서 info button 노출
- IDLE 상태에서 info button 또는 color-only fallback 동작 검증
- AX info click 후 설명 popover 표시
- close / info affordance 충돌 없음
- runtime state 전환 시 popover dismiss

### Localization

- KR/EN copy truncation 없음
- attention copy가 너무 장황하지 않음

## 7. Acceptance Checklist

- [ ] AX는 amber + info affordance로 표시된다
- [ ] IDLE은 orange-red attention treatment를 가진다
- [ ] neutral state는 기존 mini처럼 조용하다
- [ ] AX info 클릭 시 작은 설명 popover가 뜬다
- [ ] KR/EN localization이 자연스럽다
- [ ] hover close와 info affordance가 충돌하지 않는다
- [ ] mini overlay가 더 복잡한 standard처럼 보이지 않는다

## 8. Risks

### Risk A — Mini가 너무 복잡해짐

완화:

- attention state에만 affordance 허용

### Risk B — affordance 충돌

완화:

- info 우선순위 고정
- close는 보조 affordance로 제한

### Risk C — popover가 방해됨

완화:

- one-shot small popover
- 짧은 copy

### Risk D — NSPanel 환경에서 popover 구현이 예상보다 까다로움

완화:

- `.popover`에 바로 의존하지 말고 `NSPopover` POC 먼저 검증
- AX만 우선 구현해 범위를 줄인다

## 9. First-pass Recommendation

첫 구현은 아래까지만 가는 것이 적절하다.

- AX / IDLE 두 상태만 attention state 처리
- color + info button + small popover는 `AX` 우선
- settings deep-link CTA는 AX에만 제공
- hover close는 attention state에서 secondary 취급
- IDLE popover는 실제 체류 시간 검증 후 후속 결정

## 10. Bottom Line

- 이 작업은 mini overlay를 더 많은 기능으로 키우는 작업이 아니라,
- `이해 안 되는 축약 상태를 설명 가능한 UI로 바꾸는 작업`이다.

- 따라서 구현 우선순위는:
  1. visual role mapping
  2. color
  3. info affordance
  4. explanatory popover

순서가 가장 안전하다.
