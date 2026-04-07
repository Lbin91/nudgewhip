# 온보딩 넛지 프리뷰 단계 기획서

> **상태**: 기획 검토 완료, 구현 대기
> **작성일**: 2026-04-03
> **범위**: first-install 온보딩에 넛지 방식 체험 단계 추가

---

## 1. 배경

### 1.1 문제 의식

현재 온보딩(BasicSetupStepView)에서 사용자는 **문구만으로** 넛지 방식을 선택한다:

| 설정 | 현재 온보딩 표시 | 문제 |
|------|-----------------|------|
| Idle Threshold | "10초 / 3분 / 5분 / 10분" | 숫자만 보이고 실제 체감 불가 |
| Visual Mode | "새싹 / 미니멀" | 두 모드가 어떻게 다른지 알 수 없음 |
| Sound Preview | 재생 버튼 | 어떤 사운드가 단계별로 재생되는지 알기 어려움 |

사용자는 **자신이 선택한 설정이 실제로 어떻게 느껴지는지** 온보딩에서 체험할 방법이 없다.

### 1.2 목표

- 온보딩에서 **실제 넛지를 클릭 한 번으로 체험**할 수 있게 한다
- 사용자가 설정값을 **경험 기반으로 선택**하게 돕는다
- 펫 모드(sprout/minimal) 차이를 **시각적으로 미리 보여준다**

---

## 2. 기능 명세

### 2.1 위치: BasicSetupStepView 하단에 프리뷰 섹션 추가

새로운 독립 단계가 아니라, 기존 BasicSetupStepView의 하단에 **"미리보기" 카드**를 추가한다.

**이유:**
- 온보딩 단계를 5→6으로 늘리면 완료율 저하 위험
- 설정 선택과 프리뷰가 같은 화면에 있어야 "고쳐야 할 게 있으면 바로 위에서 수정" 가능
- 현재 BasicSetupStepView는 창 높이 520으로 여유 공간 있음

### 2.2 프리뷰 카드 구성

```
┌─────────────────────────────────────────────┐
│ 🎯 넛지가 어떻게 느껴지는지 미리 확인해 보세요   │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  가벼운   │  │  부드러운  │  │  강한    │  │
│  │  넛지    │  │  넛지     │  │  넛지     │  │
│  │ (1단계)  │  │ (2단계)   │  │ (3단계)   │  │
│  │          │  │           │  │          │  │
│  │  [미리보기] │  │  [미리보기]  │  │  [미리보기] │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                             │
│  🔊 사운드 미리듣기  [▶ 재생]                 │
│                                             │
│  현재 설정: 5분 기준 → 1단계 후 30초마다 에스컬레이션 │
└─────────────────────────────────────────────┘
```

### 2.3 각 프리뷰 동작 명세

#### 2.3.1 시각 넛지 프리뷰 (3종)

| 버튼 | 클릭 시 동작 | 지속 시간 | 종료 조건 |
|------|------------|----------|----------|
| **가벼운 넛지** (1단계) | `AlertOverlayView`를 현재 온보딩 창에 오버레이. 주황 테두리 펄스(border 12px). 사운드: Tink | 2초 | 자동 종료 |
| **부드러운 넛지** (2단계) | 주황 테두리 펄스(border 14px) + 중앙 메시지 카드 "Let's refocus". 사운드: Hero | 3초 | 자동 종료 |
| **강한 넛지** (3단계) | 빨간 테두리 펄스(border 18px) + 화면 디밍(8%) + 중앙 메시지 "Come back now!". 사운드: Sosumi | 3초 | 자동 종료 |

**중요: 실제 전체화면 오버레이가 아닌 온보딩 창 내 프리뷰로 구현.**

구현 방식:
- `PerimeterPulsePresenter`(현재 NSPanel 기반 전체화면)를 재사용하지 않음
- 대신 **인라인 SwiftUI 프리뷰 오버레이**를 BasicSetupStepView 내부에 렌더링
- 온보딩 창(NSWindow) 위에 ZStack으로 겹쳐서 보여줌
- 프리뷰 중에는 다른 프리뷰 버튼 비활성화 (중복 실행 방지)

#### 2.3.2 사운드 프리뷰

| 항목 | 내용 |
|------|------|
| 동작 | `NSSound`로 현재 단계에 대응하는 시스템 사운드(Tink/Hero/Sosumi) 1회 재생 |
| 제약 | 프리뷰는 1회만 재생. 다른 프리뷰와 동시 실행하지 않음 |
| 표시 방식 | 별도 토글 없이 항상 표시하고, 재생 중에는 버튼을 비활성화 |

**현재 구현 방향:**
- 별도 음성 채널 없이 **시스템 사운드만** 프리뷰한다.
- 시스템 사운드(Tink/Hero/Sosumi)는 이미 구현되어 있으므로, 각각의 사운드를 버튼 클릭으로 재생한다.
- 3차 시스템 알림은 별도 음성 재생 없이 notification copy로만 유지한다.

#### 2.3.3 에스컬레이션 타임라인 표시

현재 선택한 idle threshold에 따라 **언제 각 단계가 발동하는지** 텍스트로 표시:

```
선택한 기준: 5분
┌─── 0분 ──── 5분 ──── 5분30초 ──── 6분 ──── 6분30초 ──→
     입력 없음   1단계      2단계       3단계      시스템 알림
     가벼운 넛지  부드러운   강한 넛지    알림 배너
```

- idle threshold 값이 변경되면 타임라인 실시간 갱신
- 각 단계 간격은 30초(`alertEscalationInterval`) 기준

### 2.4 펫 모드 프리뷰

현재 **펫 캐릭터 렌더링이 미구현**이므로, 1차에서는 텍스트+아이콘으로만 차이 설명:

| 모드 | 프리뷰 표시 |
|------|-----------|
| **새싹(Sprout)** | "🌱 작업 메이트가 곁에서 응원해요" + 감정 변화 예시(happy → concern → cheer) |
| **미니멀(Minimal)** | "◾ 깔끔한 시각 알림만 사용해요" + 테두리 효과 아이콘 |

펫 캐릭터 구현 완료 후, 실제 펫 애니메이션을 인라인으로 보여주도록 업그레이드.

---

## 3. 구현 범위 분리

### 3.1 1차 구현 (이번 스프린트)

| 항목 | 구현 내용 |
|------|----------|
| 시각 넛지 프리뷰 | 인라인 오버레이 3종 (perimeterPulse / gentleNudge / strongVisualNudge) |
| 사운드 프리뷰 | 시스템 사운드 3종 (Tink / Hero / Sosumi) 버튼 클릭 재생 |
| 에스컬레이션 타임라인 | idle threshold 기반 시간 표시 |
| 펫 모드 설명 | 텍스트+아이콘 차이 설명 |

### 3.2 2차 구현 (펫 캐릭터 완성 후)

| 항목 | 구현 내용 |
|------|----------|
| 펫 애니메이션 프리뷰 | 실제 캐릭터 감정 변화 인라인 렌더링 |
| 사운드 프리뷰 polish | 단계별 사운드 라벨/설명 보강 |

### 3.3 3차 구현 (Pro 기능)

| 항목 | 구현 내용 |
|------|----------|
| 원격 에스컬레이션 프리뷰 | iOS companion 연동 설명 + 시뮬레이션 |
| Grayscale 프리뷰 | 고강도 실험 옵션 체험 |

---

## 4. 기술 설계

### 4.1 새 파일

| 파일 | 역할 |
|------|------|
| `nudge/Onboarding/Views/NudgeWhipPreviewCard.swift` | 프리뷰 섹션 전체 뷰. 3개 프리뷰 버튼 + 사운드 재생 + 타임라인 |
| `nudge/Onboarding/Views/NudgeWhipPreviewOverlay.swift` | 인라인 오버레이 애니메이션 뷰. AlertOverlayView 로직 재사용 |

### 4.2 기존 파일 수정

| 파일 | 변경 |
|------|------|
| `BasicSetupStepView.swift` | 하단에 `NudgeWhipPreviewCard` 추가 |
| `OnboardingStep.swift` | 창 높이 조정 (520 → 680, 프리뷰 공간 확보) |
| `OnboardingRootView.swift` | 없음 (기존 body 스위칭 그대로) |

### 4.3 인라인 오버레이 구현 전략

`PerimeterPulsePresenter`(NSPanel 전체화면)를 재사용하지 않고, **순수 SwiftUI ZStack**으로 구현:

```swift
// NudgeWhipPreviewOverlay.swift - 개념 코드
struct NudgeWhipPreviewOverlay: View {
    let style: AlertVisualStyle  // perimeterPulse / gentleNudge / strongVisualNudge
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 디밍 (strongVisualNudge만)
            if style == .strongVisualNudge {
                Color.black.opacity(0.08)
            }

            // 테두리 펄스
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
                .shadow(color: borderColor.opacity(0.6), radius: 8)
                .scaleEffect(isAnimating ? 1.01 : 1.0)
                .opacity(isAnimating ? 1.0 : 0.6)
                .animation(.easeInOut(duration: pulseDuration).repeatForever(), value: isAnimating)

            // 중앙 메시지 (gentleNudge, strongVisualNudge만)
            if style != .perimeterPulse {
                // 메시지 카드
            }
        }
        .onAppear { isAnimating = true }
    }
}
```

### 4.4 사운드 재생

```swift
// NudgeWhipPreviewCard.swift 내
private func playPreviewSound(_ style: AlertVisualStyle) {
    let soundName: String = switch style {
        case .perimeterPulse: "Tink"
        case .gentleNudge: "Hero"
        case .strongVisualNudge: "Sosumi"
    }
    NSSound(named: soundName)?.play()
}
```

---

## 5. 고려사항

### 5.1 온보딩 창 높이

- 프리뷰 카드 추가로 BasicSetupStepView가 약 160px 증가
- `OnboardingWindowMetrics`에서 basicSetup 창 높이를 520→680으로 조정 필요
- 기존 정책(각 단계가 스크롤 없이 한 화면에 완결) 유지

### 5.2 접근성

- Reduce Motion 활성화 시: 펄스 애니메이션 대신 opacity 페이드로 대체
- 프리뷰 버튼에 `accessibilityLabel` 추가 ("1단계 가벼운 넛지 미리보기")
- 사운드 재생 전 사용자 명시적 클릭 필요 (자동 재생 금지)

### 5.3 프리뷰 중 상호작용

- 프리뷰 오버레이 표시 중(2~3초): 다른 버튼/토글 비활성화
- 프리뷰 종료 후 자동으로 원래 상태 복원
- 연속 클릭 방지: 프리뷰 진행 중 같은 버튼 다시 클릭 무시

### 5.4 다국어

- 프리뷰 섹션 제목, 버튼 텍스트, 에스컬레이션 설명 모두 `localizedAppString` 사용
- 새 현지화 키 약 10개 추가 필요

---

## 6. 현지화 키 (예상)

| 키 | EN | KO |
|----|----|----|
| `onboarding.preview.section_title` | Preview how nudges feel | 넛지가 어떻게 느껴지는지 미리 확인 |
| `onboarding.preview.gentle.button` | Gentle | 가벼운 넛지 |
| `onboarding.preview.moderate.button` | Moderate | 부드러운 넛지 |
| `onboarding.preview.strong.button` | Strong | 강한 넛지 |
| `onboarding.preview.sound.button` | Preview sound | 소리 미리듣기 |
| `onboarding.preview.timeline.label` | Escalation timeline | 에스컬레이션 타임라인 |
| `onboarding.preview.timeline.step1` | Step 1 | 1단계 |
| `onboarding.preview.timeline.step2` | Step 2 | 2단계 |
| `onboarding.preview.timeline.step3` | Step 3 | 3단계 |
| `onboarding.preview.pet.sprout_desc` | A work buddy cheers you on | 작업 메이트가 곁에서 응원해요 |
| `onboarding.preview.pet.minimal_desc` | Clean visual alerts only | 깔끔한 시각 알림만 사용해요 |

---

## 7. 마일스톤

| 단계 | 작업 | 산출물 |
|------|------|--------|
| Phase 1 | NudgeWhipPreviewCard + NudgeWhipPreviewOverlay 구현 | 인라인 프리뷰 3종 + 사운드 |
| Phase 2 | BasicSetupStepView 통합 + 창 높이 조정 | 온보딩 화면 완성 |
| Phase 3 | 에스컬레이션 타임라인 동적 표시 | threshold 변경 시 실시간 갱신 |
| Phase 4 | 현지화 키 추가 + 빌드 검증 | Localizable.xcstrings 업데이트 |
