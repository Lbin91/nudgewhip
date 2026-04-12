# Countdown Overlay Mini State Feedback — 문서 리뷰 리포트

- Version: 1
- Date: 2026-04-13
- Status: reviewed
- Reviewed Documents:
  - `docs/app/task-countdown-overlay-mini-state-feedback.md` (상위 기획, draft-1)
  - `docs/app/countdown-overlay-mini-state-feedback-examples.md` (디자인 예시, draft-1)
  - `docs/app/task-countdown-overlay-mini-state-feedback-implementation-plan.md` (구현 계획, draft-1)

---

## 1. 문서 간 정합성

세 문서는 각각 명확한 역할 분담을 갖추고 있다.

| 문서 | 역할 | 상위 기획과의 관계 |
|---|---|---|
| 상위 기획 (task-...-feedback.md) | 무엇을 왜 해야 하는지 | 기준 문서 |
| 디자인 예시 (examples.md) | 화면에서 어떻게 보일지 | §6 시각 계약의 시각화 |
| 구현 계획 (implementation-plan.md) | 코드를 어떻게 바꿀지 | §11 기술 방향의 실행 분해 |

세 문서 사이의 용어, 상태 분류, 우선순위 규칙이 모두 일치한다.

**판정: ✅ PASS**

---

## 2. 상위 기획 검토

### 2.1 문제 정의 (§1-§2)

현재 mini overlay의 축약 토큰(`AX`, `IDLE` 등)이 의미 전달에 한계가 있다는 진단은 타당하다. 실제 코드에서도 `miniPrimaryText`가 단순히 문자열만 반환하고, 색상/아이콘 분기가 전혀 없는 상태다.

### 2.2 상태 분류 (§5)

**Neutral vs Attention 분류:**

| 분류 | 상태 | 판단 |
|---|---|---|
| Neutral | monitoring, pausedManual, pausedWhitelist, pausedSchedule, suspendedSleepOrLock | ✅ 타당 |
| Attention | limitedNoAX (`AX`), alerting (`IDLE`) | ✅ 타당 |

이 분류는 합리적이다. 다만 한 가지 고려가 필요하다.

**주의:** `alerting`은 attention state로 분류되었지만, 실제 사용 시나리오에서는 "유휴 감지 후 곧바로 활동이 돌아와서 해소되는" 짧은 구간이 대부분이다. 즉, `IDLE` attention state가 사용자에게 보이는 시간이 매우 짧을 수 있다. 이 상태에 info affordance + popover까지 투자하는 것이 실제 가치가 있는지, 아니면 `AX`만 우선 처리하는 편이 나을지 검토가 필요하다. 구현 계획 §9에서도 AX를 최우선으로 두고 있으니 일치한다.

### 2.3 시각 계약 (§6)

- `AX` → amber/yellow: ✅ 적절. "에러"가 아니라 "설정 필요"에 가까운 톤
- `IDLE` → orange-red: ✅ 적절. 기존 `nudgewhipAlert` 컬러 톤과 자연스럽게 연결

**기존 디자인 토큰과의 관계:** `DesignTokens.swift`에 이미 `nudgewhipAccent` (amber 계열, light: `#D8A23A` / dark: `#F2C86A`)과 `nudgewhipAlert` (red 계열, light: `#B84525` / dark: `#FF8A68`)가 정의되어 있다. 새로운 색상을 만들기보다 이 기존 토큰을 재사용하는 것이 일관성에 좋다. 문서에서는 명시적 매핑이 없으므로 구현 시 참고해야 한다.

### 2.4 Info Affordance (§7)

hover close 실험과의 충돌을 인지하고 우선순위 규칙을 정의한 점이 좋다. 다만 구체적인 공간 배치가 명확하지 않다.

현재 mini overlay: 96×32 capsule. 여기에:
- 상태 토큰 (좌측-중앙)
- info `i.circle` (우측)
- hover close `xmark` (우측, hover 시)

세 요소가 96pt 안에 들어가야 한다. `i.circle`과 `xmark`가 같은 우측 영역에 있으면 96pt에서 터치 타겟이 겹칠 수 있다. 예시 문서 §7에서도 "공간이 부족하면 close를 생략"한다고 했으나, 구체적인 픽셀 레이아웃(각 요소의 x 오프셋과 padding)이 없다.

**권장:** 구현 전 attention state의 mini overlay 레이아웃을 픽셀 단위로 고정하라. 예: token(좌측 ~56pt) + gap(4pt) + i.circle(16pt hit area) = 76pt 내외. close는 attention state에서 숨김.

### 2.5 Feedback Content (§8)

AX와 IDLE 각각에 대한 KR/EN copy 예시가 명확하고 행동 중심적이다.

한 가지: CTA 후보로 `Open Settings`가 있는데, 현재 `MenuBarViewModel`에 `openAccessibilitySettings()` 메서드가 이미 존재한다. popover CTA에서 이 메서드를 직접 호출할 수 있는지, 아니면 settings window 경유인지 명세가 필요하다. 직접 호출이 가능하다면 UX가 더 매끄럽다.

### 2.6 접근성 (§10)

"색상만으로 상태를 구분하지 않는다"는 원칙이 명확하다. 현재 구현의 `overlayAccessibilityLabel`은 runtimeStateText만 제공하므로, attention state에서 색상 + 아이콘 + VoiceOver label 3단 구성으로 보강하는 방향이 맞다.

---

## 3. 디자인 예시 문서 검토

### 3.1 Baseline 레이아웃

기본 구조가 ASCII art로 명확하다. neutral state의 "거의 안 보이는 UI" 감각이 잘 표현되어 있다.

### 3.2 Attention State 예시

```text
┌────────────────────┐
│   AX           (i) │
└────────────────────┘
```

시각적으로 명확하다. 다만 96pt 안에서 `AX` + gap + `(i)` 의 공간 배치가 실제로 가능한지 확인이 필요하다. 글자 폭 기준:
- `AX` (monospaced 16pt bold): 약 24pt
- `IDLE` (monospaced 16pt bold): 약 48pt

`IDLE` + `i.circle` hit area(16pt) = 64pt + padding = 96pt 안에 가능하지만 매우 타이트하다. 구현 시 실제 렌더링으로 검증 필요.

### 3.3 Anti-slop Guardrails (§9)

"mini를 작은 standard overlay처럼 만들지 않기" 등 4가지 가이드라인이 실용적이다. 구현 중 drift를 방지하는 좋은 가드레일.

### 3.4 Hit Area 전략 (§8)

최소 16×16, 가능하면 18×18 hit target 권장. 96×32 안에서 이것이 실현 가능한지는 info 아이콘의 위치에 따라 다르다. invisible padding 확보 방식은 좋은 접근이다.

---

## 4. 구현 계획 검토

### 4.1 Phase 분할

| Phase | 내용 | 판단 |
|---|---|---|
| Phase 1 | Visual role mapping + color + info visibility | ✅ 안전한 첫 단계 |
| Phase 2 | Explanation popover | ✅ Phase 1 완료 후 독립 진행 가능 |
| Phase 3 | QA + hover 충돌 정리 | ✅ |

순서가 합리적이다. Phase 1만 완료해도 AX/IDLE의 시각적 구분이 가능하므로, popover는 후속으로 미뤄도 된다.

### 4.2 태스크 분해 (T1-T8)

각 태스크의 완료 기준이 구체적이고 검증 가능하다.

**T1 (Visual Role):** `MiniOverlayVisualRole` enum 도입. 현재 `miniPrimaryText`가 직접 runtimeState를 switch하는 구조를 한 단계 추상화하는 것은 좋은 방향이다.

**T2 (AttentionKind):** `.accessibilityNeeded` / `.idleDetected` 분기. 색상과 피드백 콘텐츠의 소스 역할. 깔끔한 설계.

**T5 (Popover):** 이 태스크가 구현 난이도가 가장 높다. NSPanel 기반 overlay 안에서 SwiftUI popover를 띄우는 것은 일반적인 `Popover` modifier가 동작하지 않을 수 있다. 별도 NSPanel 생성 또는 `NSPopover` 사용이 필요할 수 있다. 이 부분의 기술적 난이도가 문서에 반영되지 않았다.

### 4.3 파일 변경 면

Primary: `CountdownOverlayController.swift` — 맞다. 모든 mini overlay UI가 이 파일에 집중되어 있다.

Secondary: `Localizable.xcstrings` — AX/IDLE 설명 copy 추가.

Optional: `MenuBarViewModel.swift` — 현재 `overlayRuntimeStateText`가 이미 영문 설명을 제공하므로, popover copy의 소스를 VM에 둘지 View 내부에 둘지 결정이 필요하다.

### 4.4 테스트 계획

unit/view-level 테스트 항목이 명확하다. 다만 popover의 UI 테스트는 UITest에서 NSPanel 기반 overlay 접근이 까다로울 수 있으니, popover 존재 여부보다는 "info button tap 후 상태 변화"를 검증하는 편이 현실적이다.

---

## 5. 코드베이스와의 교차 검증

### 5.1 기존 기획서와의 충돌 여부

이전 기획서 `task-countdown-overlay-mini-and-positioning.md`의 mini contract와 충돌하는 항목이 없다. 해당 기획서 §7.4에서 "hover 시 close 버튼 노출은 별도 polish 항목"으로 이미 열려 있었고, 이번 문서들은 그 후속으로 자연스럽게 연결된다.

### 5.2 기존 코드와의 호환성

현재 `miniOverlay` 뷰 구조에 attention state 분기를 추가하는 것은 기존 neutral 경로에 영향을 주지 않는다. `Group { switch ... }` 패턴 안에서 `miniOverlay` 내부만 변경되므로 standard overlay는 회귀 없음.

### 5.3 디자인 토큰 재사용

| 상태 | 문서 권장 색상 | 기존 토큰 매핑 가능 |
|---|---|---|
| AX amber | amber/yellow | `Color.nudgewhipAccent` (✅ 거의 일치) |
| IDLE orange-red | orange-red | `Color.nudgewhipAlert` (✅ 일치) |

새 컬러를 정의하지 않고 기존 토큰을 사용하면 디자인 시스템 일관성이 유지된다.

---

## 6. 리스크 및 권고사항

### 🔴 구현 전 반드시 해결해야 할 것

**R1. Info popover 기술적 난이도**

현재 overlay는 `NSPanel` + `NSHostingView` 구조다. SwiftUI `.popover` modifier는 NSPanel 환경에서 정상 동작하지 않을 가능성이 높다. 대안:
- `NSPopover` 직접 사용 (AppKit 네이티브)
- 별도 NSPanel을 popover처럼 positioning
- 구현 전 `NSPopover` + `NSHostingView` 조합으로 POC 필요

구현 계획 T5에 이 기술적 제약을 명시해야 한다.

**R2. 96×32 공간 내 레이아웃 고정**

`IDLE` + `i.circle` + invisible hit padding이 96pt 안에 들어가는지 실제 렌더링으로 검증해야 한다. 실패 시:
- info 버튼 위치를 capsule 외부로 확장 (panel size는 96×32이지만 hit area는 더 크게)
- 또는 info 터치 시 전체 capsule이 clickable이 되는 방식

### 🟡 구현 중 주의

**R3. `alerting` 상태의 체류 시간**

`alerting` → 사용자 활동 감지 → `monitoring` 복귀가 보통 수 초 이내에 일어난다. 이 짧은 시간에 info popover까지 보여줄 필요가 있는지 의문. Phase 1에서는 color만 강조하고 popover는 AX 전용으로 시작하는 것도 고려.

**R4. Popover dismiss 정책**

popover가 떠 있는 동안 overlay 상태가 바뀌면(예: AX → monitoring 전환) popover를 어떻게 처리할지 명세가 없다. 권장: 상태 전환 시 즉시 dismiss.

**R5. 접근성 설정에서의 색상 대비**

`increaseContrast` 켜진 환경에서 amber/orange-red 텍스트가 dark 배경과 충분한 대비를 유지하는지 확인 필요. 기존 `CountdownOverlayAccessibilityConfiguration`의 분기 로직에 attention state 색상도 포함해야 한다.

### 🟢 좋은 점

- 문서 3종의 역할 분담이 명확하고 교차 참조가 잘 되어 있다
- 상태 분류(Neutral/Attention)가 직관적이고 코드와 자연스럽게 매핑된다
- Anti-slop guardrails가 구현 중 drift를 방지하는 실질적 가이드
- 기존 hover close 실험과의 충돌을 인지하고 우선순위 규칙을 미리 정의
- 기존 디자인 토큰과의 재사용 가능성이 높다

---

## 7. 종합 판정

**REVISE** — 방향성은 타당하나 구현 전 2가지 보강 필요:

1. **Popover 기술 제약 명시** — NSPanel 환경에서의 SwiftUI popover 한계와 대안을 구현 계획에 추가
2. **Attention state 레이아웃 픽셀 고정** — 96×32 내에서 token + info + hit area의 구체적 배치를 검증 또는 명세

이 두 가지만 보강하면 구현 착수 가능하다.
