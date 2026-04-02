# Nudge Landing Mockup

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `visual-designer`
- Scope: prelaunch landing page wireframe and responsive behavior

## 1. Page Goal

- 방문자가 10초 안에 제품 목적을 이해하게 한다.
- waitlist, GitHub, iPhone 관심 등록 CTA를 분리한다.
- 프라이버시와 접근성 메시지를 신뢰 장치로 보여준다.
- **랜딩 페이지는 ko/en 동시 운영**한다. 모든 섹션은 한국어/영어 버전을 동시에 제공하며, URL 경로(`/ko`, `/en`) 또는 하위 도메인으로 분리한다.

## 2. Information Architecture

- Hero
- Problem
- How It Works
- Visual Preview
- Free / Pro Comparison
- Privacy and Permission
- Waitlist CTA
- FAQ

## 3. Desktop Wireframe

```text
[Header]  Logo | Product | Privacy | FAQ | Waitlist

[Hero]
Left: headline, subhead, CTA group
Right: product preview card + pet visual + status pill

[Problem]
3-column cards: distraction, idle detection, return loop

[How It Works]
Step 1 -> input stops
Step 2 -> gentle nudge
Step 3 -> recovery

[Visual Preview]
Menu bar dropdown mock + alert overlay mock

[Free / Pro]
Two-column comparison table

[Privacy and Permission]
Permission rationale + data disclosure + trust bullets

[Waitlist CTA]
Email field + interest chips + submit

[FAQ]
Accordion list
```

### 3.1 Desktop Rules

- Hero는 2열 구조를 유지한다.
- CTA는 주 CTA 1개, 보조 CTA 2개로 나눈다.
- 시각 프리뷰는 제품이 실제로 작동하는 느낌을 줘야 한다.
- 비교 섹션은 표 형태보다 카드 형태가 더 적합하면 카드로 바꾼다.

## 4. Mobile Wireframe

```text
[Header]
Logo | menu

[Hero]
Headline
Subhead
Primary CTA
Secondary CTA
Preview card

[Problem]
Stacked cards

[How It Works]
Vertical steps

[Visual Preview]
Swipeable mock cards

[Free / Pro]
Accordion or stacked comparison

[Privacy and Permission]
Short trust bullets

[Waitlist CTA]
Email + interest chips

[FAQ]
Accordion
```

### 4.1 Mobile Rules

- hero는 한 화면에서 headline과 CTA가 먼저 보이도록 한다.
- 모바일에서는 긴 설명보다 카드와 단계형 구성이 우선이다.
- CTA는 세로로 쌓고, 버튼 높이를 넉넉하게 둔다.
- 이미지보다 텍스트 우선 순서를 더 높게 둔다.

## 5. Section Content Guidance

### 5.1 Hero

- 카피: copywriting.md Section 3 참조
- KR 카피:
  - headline: "딴짓이 시작되면, 바로 돌아오게"
  - subhead: "입력이 멈춘 순간을 감지해 부드럽게 작업 복귀를 유도하는 macOS 메뉴바 앱"
  - supporting: "키 입력 내용은 보지 않고, 전역 입력 활동만 사용합니다"
- EN 카피:
  - headline: "The moment attention drifts, Nudge brings you back"
  - subhead: "A macOS menu bar app that detects idle moments and gently brings you back to work"
  - supporting: "Nudge does not read typed text. It only uses global input activity"
- CTA primary: `Join Waitlist` / 카피: copywriting.md Section 4 참조
- CTA secondary: `View on GitHub` (Prelaunch에서는 "Coming Soon"으로 대체, copywriting.md Section 12 참조)
- CTA tertiary: `Get iPhone alert updates`

### 5.2 Problem

- 카피: copywriting.md Section 3 Core Message 참조
- 카드 1: 작업 중 입력이 멈춘다
- 카드 2: 멈춘 순간을 놓치면 흐름이 길어진다
- 카드 3: Nudge는 그 순간만 짧게 건드린다

### 5.3 How It Works

- 카피: copywriting.md Section 5.2 Feature Bullets 참조
- Step 1: 글로벌 입력이 멈춤
- Step 2: 부드러운 시각 넛지
- Step 3: 복귀와 보상

### 5.4 Visual Preview

- 카피: copywriting.md Section 5.1 Short Description 참조
- 메뉴바 드롭다운 mock
- perimeter pulse alert mock
- pet progression mock

### 5.5 Free / Pro

- 카피: copywriting.md Section 5.2 Feature Bullets 참조
- Free는 Mac 단일 복귀 루프를 보여준다.
- Pro는 iPhone follow-up과 예외 제어를 추가한다.

#### Free/Pro 기능 비교표 (spec.md Section 4 기준)

| 기능 | Free | Pro |
|---|---|---|
| Mac idle detection | O | O |
| 기본 시각 알림 (perimeter pulse) | O | O |
| 기본 일일 카운트 통계 | O | O |
| 고정 임계시간 프리셋 | O | O |
| 펫 캐릭터 (sprout 고정, 3가지 감정) | O | O |
| iOS 연동 (CloudKit 상태 전이 알림) | - | O |
| 커스텀 임계시간 설정 | - | O |
| 수동 휴식 모드 | - | O |
| 화이트리스트 (bundleIdentifier 기반) | - | O |
| 상세 통계 대시보드 | - | O |
| 펫 성장 시스템 (buddy/guide) | - | O |
| 가격 | 무료 | $8.99~$9.99 (가설) |

### 5.6 Privacy and Permission

- 카피: copywriting.md Section 11 Privacy 카피 블록 참조
- Accessibility 필요 이유를 한 문단으로 설명한다.
- 수집하지 않는 데이터 목록을 명시한다.
- CloudKit은 Pro 동기화용이라는 점을 분명히 한다.

### 5.7 FAQ

- 카피: copywriting.md Section 5.3 Review Notes 참조

#### Q1. 왜 Accessibility 권한이 필요한가?

- KR: Nudge는 전역 입력 활동(마우스 이동, 키보드 입력 여부)을 감지하기 위해 Accessibility 권한이 필요합니다. 입력한 내용이나 화면 내용은 수집하지 않으며, 오직 "입력이 있었다/없었다"만 확인합니다.
- EN: Nudge needs Accessibility permission to detect global input activity (mouse movement, key presses). It does not collect typed content or screen data. It only checks whether input occurred or not.

#### Q2. 어떤 데이터를 수집하는가?

- KR: Nudge는 키 입력 텍스트, 화면 내용, 브라우징 기록을 수집하지 않습니다. 저장하는 데이터는 idle 발생 횟수, 복귀 시간, 집중 세션 지속 시간뿐입니다. 모든 데이터는 Mac에 로컬로 저장됩니다. iOS 연동 사용 시에만 CloudKit으로 상태 정보가 동기화됩니다.
- EN: Nudge does not collect keystroke text, screen content, or browsing history. The only data stored is idle event counts, recovery times, and focus session durations. All data is stored locally on your Mac. CloudKit sync is used only when iOS companion is enabled.

#### Q3. Pro는 무엇이 다른가?

- KR: Pro는 Mac + iPhone 복귀 루프, 커스텀 임계시간, 수동 휴식 모드, 화이트리스트 예외 제어, 상세 통계 대시보드, 펫 성장 시스템(buddy/guide)을 추가로 제공합니다. Free는 Mac 단일 기기 기본 복귀 루프입니다.
- EN: Pro adds Mac + iPhone return loop, custom threshold, break mode, whitelist controls, detailed stats dashboard, and pet growth system (buddy/guide). Free covers the Mac-only basic return loop.

#### Q4. iPhone은 언제 연결되는가?

- KR: iOS 연동은 Phase 2(Pro Launch)에서 제공될 예정입니다. CloudKit 기반으로 Mac의 상태 변화를 iPhone에 알림으로 전달하며, 실시간 보장이 아닌 best-effort 기준으로 동작합니다.
- EN: iOS companion will be available in Phase 2 (Pro Launch). It uses CloudKit to deliver Mac state changes as iPhone notifications, operating on a best-effort near real-time basis.

## 6. Responsive Behavior

### 6.1 Breakpoints

| Breakpoint | Width | Layout | Notes |
|---|---|---|---|
| `mobile` | <768px | 1 column | stacked, swipe-friendly |
| `tablet` | 768-1024px | 1-2 column | balanced preview |
| `desktop` | >1024px | 2 column hero + multi-section | full storytelling |

### 6.2 Responsive Rules

- Hero preview는 모바일에서 아래로 이동한다.
- 비교표는 작은 화면에서 카드로 전환한다.
- FAQ는 아코디언으로 표시한다.
- CTA는 늘 첫 화면 안에 남도록 재배치한다.

## 7. SEO and OGP

### 7.1 Title / Description Template

- KR title: "Nudge - 딴짓이 시작되면, 바로 돌아오게 | macOS 메뉴바 앱"
- EN title: "Nudge - Bring Attention Back | macOS Menu Bar App"
- KR description: "입력이 멈춘 순간을 감지해 부드럽게 작업 복귀를 유도하는 macOS 메뉴바 앱. 키 입력 내용은 보지 않습니다."
- EN description: "A macOS menu bar app that detects idle moments and gently brings you back to work. No keystroke content is collected."

### 7.2 Technical SEO

- Canonical URL: `https://nudge.app` (가설) + `/ko`, `/en` 경로별 canonical
- FAQ schema (JSON-LD): Section 5.7 FAQ 질문/답변을 FAQPage schema로 마크업
- Open Graph: `og:type=website`, `og:image=1200x630` OGP 이미지 (펫 캐릭터 + 로고 + tagline)
- Twitter Card: `summary_large_image`

### 7.3 OGP 이미지

- 크기: 1200x630px
- 구성: Nudge 로고 + 펫 캐릭터 실루엣 + 핵심 tagline (KR/EN 각각 제작)
- 배경: 단색 또는 약한 그라데이션 (Visual Notes와 일관성 유지)

## 8. Visual Notes

- 배경은 단색보다 약한 질감 또는 그라데이션을 사용한다.
- 제품 프리뷰는 실제 스크린샷이 없어도 wireframe 수준으로 신뢰감을 준다.
- 여백을 넉넉하게 두고, 정보 밀도를 너무 빨리 올리지 않는다.
- 강한 빨강은 alert 순간에만 제한적으로 쓴다.

## 9. Handoff Notes

- `web-dev`는 이 문서를 기준으로 랜딩 구현을 시작한다.
- `marketing-strategist`의 카피가 확정되면 hero와 FAQ 텍스트를 교체한다.
- `visual-designer`의 아이콘과 캐릭터 자산이 확정되면 preview card를 실제 에셋으로 대체한다.
