# Nudge Landing Mockup

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `visual-designer`
- Scope: prelaunch landing page wireframe and responsive behavior

## 1. Page Goal

- 방문자가 10초 안에 제품 목적을 이해하게 한다.
- waitlist, GitHub, iPhone 관심 등록 CTA를 분리한다.
- 프라이버시와 접근성 메시지를 신뢰 장치로 보여준다.

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

- 메시지: 딴짓을 막는 앱이 아니라 다시 돌아오게 하는 앱
- 서브 메시지: 키 입력과 화면을 보지 않고도, 입력이 멈춘 순간을 감지한다
- CTA primary: `Join Waitlist`
- CTA secondary: `View on GitHub`
- CTA tertiary: `Get iPhone alert updates`

### 5.2 Problem

- 카드 1: 작업 중 입력이 멈춘다
- 카드 2: 멈춘 순간을 놓치면 흐름이 길어진다
- 카드 3: Nudge는 그 순간만 짧게 건드린다

### 5.3 How It Works

- Step 1: 글로벌 입력이 멈춤
- Step 2: 부드러운 시각 넛지
- Step 3: 복귀와 보상

### 5.4 Visual Preview

- 메뉴바 드롭다운 mock
- perimeter pulse alert mock
- pet progression mock

### 5.5 Free / Pro

- Free는 Mac 단일 복귀 루프를 보여준다.
- Pro는 iPhone follow-up과 예외 제어를 추가한다.

### 5.6 Privacy and Permission

- Accessibility 필요 이유를 한 문단으로 설명한다.
- 수집하지 않는 데이터 목록을 명시한다.
- CloudKit은 Pro 동기화용이라는 점을 분명히 한다.

### 5.7 FAQ

- 왜 Accessibility가 필요한가
- 어떤 데이터를 수집하는가
- Pro는 무엇이 다른가
- iPhone은 언제 연결되는가

## 6. Responsive Behavior

### 6.1 Breakpoints

| Breakpoint | Layout | Notes |
|---|---|---|
| `mobile` | 1 column | stacked, swipe-friendly |
| `tablet` | 1-2 column | balanced preview |
| `desktop` | 2 column hero + multi-section | full storytelling |

### 6.2 Responsive Rules

- Hero preview는 모바일에서 아래로 이동한다.
- 비교표는 작은 화면에서 카드로 전환한다.
- FAQ는 아코디언으로 표시한다.
- CTA는 늘 첫 화면 안에 남도록 재배치한다.

## 7. Visual Notes

- 배경은 단색보다 약한 질감 또는 그라데이션을 사용한다.
- 제품 프리뷰는 실제 스크린샷이 없어도 wireframe 수준으로 신뢰감을 준다.
- 여백을 넉넉하게 두고, 정보 밀도를 너무 빨리 올리지 않는다.
- 강한 빨강은 alert 순간에만 제한적으로 쓴다.

## 8. Handoff Notes

- `web-dev`는 이 문서를 기준으로 랜딩 구현을 시작한다.
- `marketing-strategist`의 카피가 확정되면 hero와 FAQ 텍스트를 교체한다.
- `visual-designer`의 아이콘과 캐릭터 자산이 확정되면 preview card를 실제 에셋으로 대체한다.
