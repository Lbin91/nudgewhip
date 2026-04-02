# Nudge Icon Spec

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `visual-designer`
- Scope: app icon, menu bar icon, status variants, export rules

## 1. Purpose

- 앱 아이콘과 메뉴바 아이콘의 역할을 분리한다.
- 작은 크기에서도 상태가 즉시 읽히도록 한다.
- 캐릭터 자산과 UI 아이콘의 스타일을 일관되게 유지한다.

## 2. App Icon

### 2.1 Concept

- 콘셉트: `orbit + nudge`
- 형태: 중앙의 핵심 점과 이를 감싸는 부드러운 궤도 형상
- 인상: 조용한 집중, 가벼운 리듬, Apple-native 정갈함

### 2.2 Construction Rules

- 한눈에 읽히는 실루엣을 우선한다.
- 내부 디테일은 1024px에서도 과도하게 많지 않게 유지한다.
- 텍스트, 숫자, 작은 표정은 아이콘에 넣지 않는다.
- 원형과 곡선을 중심으로, 모서리는 둥글고 단정하게 유지한다.

### 2.3 Export Rules

- Master: SVG
- Deliverables: 1024px app icon, 512px preview, 256px preview
- macOS asset catalog용 PDF도 함께 준비한다.
- 투명 배경이 필요한 변형과 불투명 배경 변형을 분리한다.

## 3. Menu Bar Icon

### 3.1 State Set

> 상태명은 `docs/app/spec.md` 5.1 Runtime States 기준. 6개 상태를 Phase 1 필수(4개)와 Phase 2 추가(2개)로 구분한다.

| State | Phase | Meaning | Color Guide | Shape Example |
|---|---|---|---|---|
| `monitoring` | **1** | 정상 모니터링 — 입력 유휴 타이머 동작 중 | 기본 전경색 (템플릿 렌더링) | 채워진 중심점 + 얇은 궤도 |
| `alerting` | **1** | 알림 단계 진행 중 — 에스컬레이션 활성 | 강조 전경색 (윤곽 대비 우선) | 더 강한 궤도 + 명확한 강조 요소 |
| `pausedManual` | **1** | 사용자 수동 휴식 모드 | 낮은 대비, 보조색 | 완화된 곡선 + 일시정지 표시 |
| `limitedNoAX` | **1** | Accessibility 미허용 제한 모드 | 경고 보조색 | 점선 궤도 또는 경고 마크 |
| `pausedWhitelist` | **2** | 전면 활성 앱이 화이트리스트에 포함 | 기본 전경색, 체크 보조 | 얇은 정지선 또는 체크형 보조 |
| `suspendedSleepOrLock` | **2** | sleep/lock/user switching으로 감지 중단 | 무채색, 가장 낮은 대비 | 궤도 생략 + 점만 표시 또는 빈 실루엣 |

### 3.2 Rendering Rules

- 16px, 18px, 20px, 22px에서 모두 읽혀야 한다.
- 한 색상만으로도 기본 상태를 구분할 수 있어야 한다.
- 색은 보조 신호이고, 형태가 주 신호다.
- 너무 작은 내부 선은 제거한다.

### 3.3 Template Strategy

- 상태 아이콘은 template rendering을 전제로 한다.
- `monitoring`, `alerting`, `pausedManual`, `limitedNoAX`는 동일한 실루엣 계열을 유지한다.
- 상태 변화 시 외형이 급격히 바뀌지 않도록 한다.

## 4. Badge and Glyph Rules

- 숫자 배지는 최소 사용한다.
- 가능한 경우 상태 전환과 아이콘 형태만으로 표현한다.
- `alerting`에서는 빨간색 자체보다 윤곽 대비를 먼저 강화한다.
- `pausedManual`은 눈에 띄지만 공격적이지 않게 유지한다.

## 5. Geometry

- 아이콘 기본 stroke: 1px (design-system.md 토큰 참조), 강조 요소 stroke: 1.5px.
- 캡과 조인 형태는 round를 기본으로 한다.
- 아이콘은 24px 그리드 기준으로 설계한다.
- 모든 상태 변형은 같은 중심과 safe area를 공유한다.

## 6. Export Matrix

| Use | Size | Format | Background | Notes |
|---|---|---|---|---|
| macOS app icon | 1024 | PDF + SVG source | 불투명 (불필요 시 투명) | App Store/asset catalog |
| menu bar icon | 16, 18, 20, 22 | PDF | 투명 (template rendering) | template-friendly |
| settings preview | 128, 256 | PNG | 투명 + 불투명 양쪽 변형 | docs and QA |
| landing preview | 512, 1024 | PNG/WebP | 불투명 배경 | marketing use only |

## 7. Naming Convention

- App icon: `app-icon/{variant}`
- Menu bar icon: `menu-bar/{state}`
- 상태별 파일명은 `kebab-case`를 사용한다.
- 예: `menu-bar/alerting.svg`, `menu-bar/limited-no-ax.svg`, `menu-bar/suspended-sleep-or-lock.svg`

## 8. QA Checklist

- 16px 렌더링 시 최소 1px 유효 stroke 유지, 실루엣이 무너지지 않는다.
- light/dark 모두 대비 3:1 이상 유지한다.
- `limitedNoAX`는 권한 부족 상태가 명확하다.
- `alerting`과 `pausedManual`이 색만으로 달라 보이지 않는다 — 형태 차이로 구분 가능해야 한다.
- App icon은 메뉴바 아이콘과 혼동되지 않는다.
- `suspendedSleepOrLock`은 다른 상태와 명확히 구분되면서도 시각적 노이즈가 아니다.
- 18px 이하 크기에서 내부 디테일(점선, 보조 마크)이 번지지 않는다.
- 투명 배경 변형이 임의 배경색 위에서도 윤곽이 유지된다.

## 9. Handoff Notes

- `visual-designer`는 시안 2안 이상과 함께 final silhouette을 제안한다.
- `swiftui-designer`는 상태별 template assets만 사용한다.
- `web-dev`는 landing preview 이미지를 그대로 앱 아이콘으로 재사용하지 않는다.
