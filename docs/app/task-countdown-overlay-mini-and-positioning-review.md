# NudgeWhip Task: Countdown Overlay Mini Mode and Positioning — 구현 전 리뷰

- Version: 1
- Date: 2026-04-12
- Status: reviewed
- Reviewed Document: `docs/app/task-countdown-overlay-mini-and-positioning.md` (draft-1)

## 1. 사실관계 검증

문서 Section 3 (Current State)에 기술된 모든 항목이 실제 코드와 일치한다.

| 문서 기술 | 실제 코드 | 상태 |
|---|---|---|
| 146x72 고정 패널 | `CountdownOverlayController.swift:8` — `CGSize(width: 146, height: 72)` | ✅ |
| NUDGE 라벨 + primary text + 상태 텍스트 + close 버튼 | `CountdownOverlayView` (lines 149-175) | ✅ |
| 4코너 위치 함수 이미 존재 | `countdownOverlayOrigin()` (lines 109-137) | ✅ |
| UserSettings/MenuBarVM/SettingsVM/SettingsRootView에 surface 존재 | 모두 확인 | ✅ |
| "top countdown overlay" copy 잔존 | 4개 파일에서 발견 | ✅ |

잔존 copy 위치:

- `nudgewhip/Settings/SettingsRootView.swift:95` — `"Show top countdown overlay"`
- `nudgewhip/Onboarding/Views/BasicSetupStepView.swift:37` — subtitle에 `"top countdown overlay stays on"`
- `nudgewhip/Onboarding/Views/BasicSetupStepView.swift:42` — toggle label `"Show top countdown overlay"`
- `nudgewhip/Onboarding/Views/CompletionReadyStepView.swift:25` — summary label `"Top overlay"`
- `nudgewhipUITests/nudgewhipUITests.swift:60` — `"Show top countdown overlay"` (문서 Technical Surfaces에 누락)

---

## 2. 구현 전 필수 결정 사항 (P0)

### 2.1 panelSize 동적 전환 아키텍처

현재 `CountdownOverlayController`에서 `panelSize`가 `static let`으로 고정되어 있다. Mini/Standard 전환 시 NSPanel frame을 동적으로 변경해야 한다.

```swift
// 현재 — 고정값
private static let panelSize = CGSize(width: 146, height: 72)

// 필요 — variant에 따른 동적 크기
private var currentPanelSize: CGSize { ... }
```

또한 `observeVisibility()`에서 `countdownOverlayEnabled`와 `countdownOverlayPosition`만 추적 중인데, `countdownOverlayVariant`도 추적 대상에 추가해야 한다. variant가 바뀔 때마다 panel frame을 재계산하고 `setFrame(_:display:)`를 호출해야 한다.

### 2.2 limitedNoAX 상태 표기 전략

현재 코드에서 `limitedNoAX` 상태는 `configuredIdleThresholdText`(예: "03:00")를 보여준다.

```swift
// 현재 (CountdownOverlayView line 215)
case .limitedNoAX, .monitoring:
    return menuBarViewModel.configuredIdleThresholdText  // ← "03:00" 같은 임계값
```

문서에서는 mini mode에서 `limitedNoAX` → `"AX"` 축약을 명세하지만, standard mode에서도 이 상태를 어떻게 처리할지 결정이 필요하다. 두 가지 옵션:

- **A**: Standard에서도 "AX"로 통일 (코드 단순, 정보량 감소)
- **B**: Mini에서만 "AX", Standard는 기존 임계값 유지 (기존 동작 보존)

### 2.3 Settings Preview area 구현 범위

문서 10.1에 "현재 선택값을 즉시 보여주는 미리보기"가 명세되어 있으나, 현재 Settings에 이 기능이 전혀 없다. 이는 순수 신규 구현이며 구현 면적이 크다:

- 실시간 mini/standard 전환 프리뷰 뷰
- 위치 프리뷰 (miniature screen + 코너 표시)
- variant와 position 조합에 대한 실시간 시각화

문서의 구현 순서에서 가볍게 언급되었지만, 별도 서브태스크로 분리하거나 범위를 축소하는 것이 좋다.

### 2.4 SwiftData 마이그레이션

`CountdownOverlayVariant` enum 추가 시 `countdownOverlayVariantRawValue` 프로퍼티가 추가된다. 기존 사용자 DB에 값이 없으므로:

- 기본값을 `.standard`로 설정 (문서의 기존 사용자 마이그레이션 전략과 일치)
- nilable String(`String?`)으로 선언하면 SwiftData lightweight migration이 자동 처리
- `UserSettings`의 다른 rawValue 패턴(`countdownOverlayPositionRawValue`, `soundThemeRawValue`)과 동일한 패턴 사용

---

## 3. 구현 중 주의 사항 (P1)

### 3.1 ignoresMouseEvents 전환

현재 `panel.ignoresMouseEvents = false` (close 버튼 클릭용). Mini mode에서는:

- close 버튼이 없으므로 `true`로 설정하는 것이 맞음
- 후속 polish에서 hover 감지 로직 추가 시 다시 `false`로 전환 필요
- variant 전환 시 이 값도 함께 변경해야 함
- 마우스 이벤트를 무시하면 overlay 뒤의 앱 클릭이 가능해짐 (의도된 동작)

### 3.2 접근성 설정 분기

현재 `CountdownOverlayAccessibilityConfiguration`은 3개 값만 제공:

```swift
struct CountdownOverlayAccessibilityConfiguration: Equatable {
    let backgroundOpacity: Double
    let strokeOpacity: Double
    let closeButtonBackgroundOpacity: Double
}
```

Mini mode에서는:

- `closeButtonBackgroundOpacity` 불필요
- opacity를 standard보다 더 낮춰야 함 (문서 7.3: "배경 opacity는 standard보다 낮춘다")
- 별도 Mini용 configuration 값 또는 파라미터화된 함수로 분기 필요

### 3.3 영문 고정 축약형

`IDLE`, `PAUSE`, `ALLOW`, `SCHED`, `SLEEP`, `AX`는 영문 고정이다. 한국어 사용자에게 직관적인지 고민이 필요하다. 문서에서는 "접근성 label에서 풀 문장 제공"이라고 했으므로 VoiceOver 사용자는 한국어 풀 문장을 들을 수 있어 시각적 가독성은 괜찮은 선택이다.

---

## 4. UI/UX 검토

| 항목 | 판단 | 비고 |
|---|---|---|
| 96x32 크기 | ✅ 적절 | countdown 텍스트(`4m`, `58s`) 충분히 표시 가능. monospaced 14-16pt 가정 |
| 면적 감소율 | ✅ 달성 | 146x72 = 10,512 → 96x32 = 3,072 = 70.8% 감소. 문서 기준 55% 이상 충족 |
| 4코너 배치 | ✅ 적절 | `visibleFrame` 기반이므로 Dock 위치 자동 대응 |
| Bottom 위치 + Dock 확대 | ⚠️ 주의 | Dock magnify 켠 경우 inset 12pt로 충분한지 실기기 테스트 필요 |
| Dark/Light 모드 | ⚠️ 주의 | Mini 배경 opacity를 더 낮추면 light mode에서 대비 부족 가능. QA matrix에 포함됨 |
| Close affordance 제거 | ✅ 합리적 | Settings/Menu에서 토글 가능하므로 문제 없음. hover 후보는 polish로 보류 OK |
| Onboarding 단순화 | ✅ 좋은 결정 | Onboarding은 on/off만 유지, variant/position은 Settings로 진입 복잡도 증가 방지 |
| Capsule cornerRadius | ❓ 결정 필요 | Capsule이면 `cornerRadius = height / 2 = 16`. 현재 standard는 14. Mini에서 16 vs 다른 값? |

---

## 5. 문서에서 누락된 항목

1. **Variant 전환 시 애니메이션/트랜지션 명세** — 패널 크기가 146x72 ↔ 96x32로 변하는데 즉각 교체인지 crossfade인지 명세 없음
2. **`limitedNoAX` 상태 표기 통합 여부** — Standard에서도 "AX"로 바꿀지 mini에서만 바꿀지
3. **Settings Preview area 구현 난이도** — 별도 서브태스크로 분리 권장
4. **`ignoresMouseEvents` 전환 로직** — variant에 따라 마우스 이벤트 처리를 달리해야 함
5. **UITest 갱신** — `nudgewhipUITests.swift:60`에 "Show top countdown overlay" 레이블 참조가 있어 copy 변경 시 함께 갱신 필요. 문서 Section 12 Technical Surfaces에 이 파일이 누락되어 있음
6. **CompletionReadyStepView summary label** — `"Top overlay"` → `"Countdown overlay"` 변경이 QA matrix에 포함되어야 하나 명시적 언급이 약함

---

## 6. 결론

문서의 사실관계가 코드와 완벽히 일치하고, 방향성(mini mode + 4-corner + copy alignment)이 타당하다. 구현 착수 전 아래 3가지를 먼저 합의하면 문서대로 진행 가능:

1. panelSize 동적 전환 아키텍처 (static let → computed + variant observation)
2. `limitedNoAX` 표기 전략 (standard도 같이 바꿀지 mini만 바꿀지)
3. Settings Preview area 구현 범위 (이번 스프린트에 전부 포함할지 분리할지)
