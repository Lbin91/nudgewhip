# Nudge Design System

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `visual-designer`
- Scope: product UI, menu bar surfaces, alerts, landing page visual direction

## 1. Design Direction

- Direction keyword: `calm operator`
- Product personality: 조용하지만 분명한 개입, 귀엽지만 가볍지 않음
- Visual balance: 따뜻한 뉴트럴 바탕 + 신호성 포인트 컬러 + 단단한 대비
- Anti-pattern: 네온 과다, 과한 유리질감, 장난감 같은 UI, 보라색 중심 팔레트

## 2. Color Tokens

### 2.1 Core Palette

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg.canvas` | `#F7F3EC` | `#0F1318` | 전체 배경 |
| `bg.surface` | `#FFFDF9` | `#161C23` | 카드/패널 |
| `bg.surfaceAlt` | `#F2EDE4` | `#1B222B` | 보조 면 |
| `text.primary` | `#141A21` | `#F5F7FA` | 본문 |
| `text.secondary` | `#596273` | `#A7B0BF` | 보조 텍스트 |
| `text.muted` | `#7B8596` | `#758095` | 힌트/캡션 |
| `focus` | `#1E8E7E` | `#47C4B0` | 집중, 활성 |
| `rest` | `#5C7E52` | `#8CBB7E` | 휴식, 완화 |
| `alert` | `#E35D3D` | `#FF8A68` | 경고, 넛지 |
| `accent` | `#D8A23A` | `#F2C86A` | 강조, 보상 |
| `stroke.default` | `#D7D0C6` | `#2A3440` | 구분선 |
| `stroke.strong` | `#B8B0A2` | `#3A4656` | 강한 구분선 |

### 2.2 Semantic Rules

- `focus`는 상태, 진행, 활성 입력을 표시한다.
- `alert`는 회복 촉구와 시각 알림에만 사용한다.
- `rest`는 pause와 break를 표시한다.
- `accent`는 성장, 배지, CTA 보조 강조에만 사용한다.
- 오류색과 경고색은 동일하게 쓰지 않는다.

### 2.3 Gradients and Backgrounds

- 배경은 단색보다 아주 약한 그라데이션을 우선 사용한다.
- Light mode: `bg.canvas` 기반의 따뜻한 크림-샌드 그라데이션.
- Dark mode: `bg.canvas` 기반의 차가운 차콜-슬레이트 그라데이션.
- 랜딩 페이지는 미세한 입자 패턴이나 반투명 원형 하이라이트를 사용할 수 있다.
- 본문 카드에는 gradient보다 단색 surface를 우선한다.

## 3. Typography

### 3.1 Typeface Stack

- Product UI: `SF Pro Text`, `SF Pro Display`
- Web headline: `SF Pro Display` 중심, 강조 시 세미볼드 사용
- Numeric UI: tabular figures 활성화

### 3.2 Type Scale

| Style | Size | Weight | Use |
|---|---|---|---|
| `display` | 32/40 | Semibold | 랜딩 hero, 핵심 메시지 |
| `title` | 24/32 | Semibold | 설정 제목, 패널 헤드 |
| `subtitle` | 18/26 | Medium | 섹션 보조 타이틀 |
| `body` | 15/22 | Regular | 본문, 설명 |
| `bodyStrong` | 15/22 | Medium | 핵심 문장 |
| `caption` | 12/16 | Regular | 부가 정보, 라벨 |
| `micro` | 11/14 | Medium | 메뉴바 보조 정보 |

### 3.3 Type Rules

- UI는 2줄 래핑을 기본 허용한다.
- 메뉴바와 작은 패널은 축약보다 구조 조정이 우선이다.
- 숫자는 밀집도를 줄이기 위해 tabular figures를 사용한다.
- 대시보드는 문장보다 숫자와 라벨 위주로 구성한다.

## 4. Spacing and Layout

### 4.1 Spacing Scale

| Token | Value | Use |
|---|---|---|
| `space.1` | 4 | 아이콘 내부 여백 |
| `space.2` | 8 | 관련 요소 간 간격 |
| `space.3` | 12 | 라벨-본문 간격 |
| `space.4` | 16 | 카드 내부 기본 |
| `space.5` | 24 | 섹션 간격 |
| `space.6` | 32 | 큰 블록 분리 |
| `space.7` | 48 | 랜딩 섹션 리듬 |

### 4.2 Radius and Stroke

- 기본 radius: 12
- 카드 radius: 16
- 팝오버 radius: 18
- 버튼 radius: 10
- 기본 stroke: 1px
- 강조 stroke: 1.5px

### 4.3 Layout Rules

- 메뉴바 드롭다운은 360px 내외의 단일 컬럼을 우선한다.
- 설정창과 대시보드는 최대 2열까지 허용한다.
- 랜딩 페이지는 데스크톱 12컬럼, 모바일 4컬럼 기준으로 정렬한다.

## 5. Surfaces and Elevation

### 5.1 Surface Hierarchy

- Level 0: canvas
- Level 1: surface
- Level 2: surfaceAlt
- Level 3: popover / modal

### 5.2 Elevation Rules

- 그림자는 얇고 넓게 사용한다.
- 알림 오버레이는 고대비 윤곽선과 약한 glow만 사용한다.
- glassmorphism은 배경 정보 가독성을 해치면 사용하지 않는다.

### 5.3 Component Surfaces

- Menu bar dropdown: compact surface, 빠른 탐색 우선
- Alerts: high-contrast surface, 한눈에 상태 인식 우선
- Stats cards: calm surface, 수치 가독성 우선
- Landing sections: alternating surface rhythm, 시선 흐름 우선

## 6. Motion

### 6.1 Motion Principles

- 짧고 의미 있는 모션만 사용한다.
- 진입, 전환, 복귀에만 motion을 집중한다.
- 사용자 입력 복귀 시 즉시 멈출 수 있어야 한다.

### 6.2 Motion Tokens

| Token | Duration | Curve | Use |
|---|---|---|---|
| `motion.fast` | 120ms | ease-out | hover, press |
| `motion.base` | 180ms | ease-in-out | 일반 전환 |
| `motion.slow` | 260ms | ease-out | 패널 진입 |
| `motion.alert` | 320ms | spring-ish | perimeter pulse |
| `motion.recovery` | 220ms | ease-out | 복귀 피드백 |

### 6.3 Motion Rules

- 깜빡임은 초당 3회 초과 금지.
- `Reduce Motion` 활성화 시 pulse를 opacity transition으로 대체한다.
- 모션은 상태를 설명해야지 장식이 되어서는 안 된다.

## 7. Accessibility

- 텍스트 대비는 최소 4.5:1을 기준으로 한다.
- 상태 구분은 색상, 아이콘, 문구를 함께 사용한다.
- `Differentiate Without Color`에 대응하는 패턴/형태를 준비한다.
- 포커스 링은 명확해야 하며 배경에 묻히면 안 된다.
- 터치 타깃은 최소 44px을 기준으로 한다.

## 8. Asset Pipeline

### 8.1 Source and Export

- Master source는 SVG로 유지한다.
- 앱 런타임용 벡터는 PDF로 export한다.
- 웹 preview나 문서용은 PNG를 함께 export할 수 있다.
- 메뉴바/상태 아이콘은 template-friendly monochrome 버전을 별도 유지한다.

### 8.2 Naming Convention

- 폴더 구조는 `docs/design/assets/{category}/{name}`를 사용한다.
- 파일명은 `kebab-case`를 사용한다.
- 예: `docs/design/assets/icons/menu-active.svg`

### 8.3 Handoff Rules

- `visual-designer`는 마스터 SVG와 스펙 문서를 제공한다.
- `web-dev`는 랜딩용 raster preview만 임시 사용하고, 배포 전에는 최종 export를 교체한다.
- `swiftui-designer`는 template PDF와 상태별 icon set을 우선 사용한다.

## 9. Implementation Notes

- 라이트/다크는 같은 의미 토큰을 유지하고 값만 바꾼다.
- 브랜드 컬러는 하나의 강한 포인트만 유지한다.
- 카드와 배경은 명확히 분리하고, 정보 밀도가 높은 화면일수록 표면 대비를 높인다.
