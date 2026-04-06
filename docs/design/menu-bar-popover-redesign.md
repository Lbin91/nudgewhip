# Nudge Menu Bar Popover Redesign Spec

- Version: 0.1
- Last Updated: 2026-04-06
- Status: draft
- Owner: `visual-designer` + `swiftui-designer`
- Scope: macOS `MenuBarExtra` dropdown redesign before implementation

## 1. Purpose

- 현재 메뉴바 popover를 "기능이 들어 있는 패널"이 아니라 "상태를 한눈에 읽고 바로 행동하는 복귀 도구"로 재정의한다.
- 기존 구현의 구조적 장점은 유지하면서, 시각 위계와 브랜드 표정을 다시 설계한다.
- 이후 SwiftUI 구현과 QA가 따라야 할 단일 문서 기준을 만든다.

## 2. Related Docs

- [spec.md](../app/spec.md)
- [design-system.md](./design-system.md)
- [2026-04-02-spec-expansion-agent-meeting.md](../report/2026-04-02-spec-expansion-agent-meeting.md)
- [task-macos-ux-stabilization.md](../app/task-macos-ux-stabilization.md)

## 3. Current Problems

### 3.1 Flat hierarchy

- 상태 요약, pause controls, 보조 액션이 모두 비슷한 카드 강도와 밀도로 보인다.
- 사용자는 첫 1초에 핵심 정보와 핵심 액션을 구분하기 어렵다.
- 결과적으로 화면이 "빠른 조작 UI"보다 "비슷한 박스 3개"로 읽힌다.

### 3.2 Weak brand anchor

- 디자인 토큰 방향은 맞지만 실제 화면 인상은 너무 안전하고 범용적이다.
- 따뜻한 뉴트럴 + 신호성 포인트라는 의도는 있으나, 브랜드 표정은 약하고 macOS 설정 패널에 가깝게 보인다.
- ASCII 펫이 존재하지만 중심 자산이 아니라 보조 장식처럼 읽힌다.

### 3.3 Weak action prioritization

- `Pause / Resume`와 `Settings / Onboarding / Quit`가 거의 같은 버튼 언어를 사용한다.
- "지금 사용자에게 가장 필요한 행동"과 "부가 행동"이 같은 시각 강도로 노출된다.
- 메뉴바 utility 특성상 스캔 속도가 중요한데, 현재는 결정 포인트가 분산된다.

### 3.4 Layout coherence gap

- 드롭다운 내부 레이아웃은 `360px` 기준인데, 외부 컨테이너는 `320px`로 잡혀 있다.
- 이 상태는 의도된 긴장감보다 "정리 덜 된 폭 규칙"처럼 보일 가능성이 크다.
- 재디자인에서는 outer/inner width와 여백 리듬을 하나의 규칙으로 통일해야 한다.

### 3.5 Accessibility and contrast debt

- 라이트 모드에서 `text.muted`, `focus`, `alert` 조합 일부가 AA를 통과하지 못한다.
- 재디자인은 분위기 개선과 동시에 가독성 회복을 포함해야 한다.

## 4. Redesign Goals

1. 첫 1초에 `현재 상태`, `남은 시간`, `핵심 액션`이 보이게 한다.
2. popover 전체가 하나의 강한 surface처럼 느껴지게 한다.
3. 펫/브랜드 자산은 장식이 아니라 감정적 앵커로 사용한다.
4. 보조 액션은 존재하되 전면에 나서지 않게 한다.
5. 메뉴바 utility답게 compact하고 빠르게 스캔되게 한다.
6. 라이트/다크 모두 대비와 포커스 가시성을 확보한다.

## 5. Non-goals

- 메뉴바 popover 안에 상세 설정을 다시 많이 넣지 않는다.
- 통계 대시보드를 popover 내부에서 확장하지 않는다.
- glassmorphism, neon, playful toy UI 같은 시각 언어로 방향을 틀지 않는다.
- 현재 `.window` 기반 구조를 기본 메뉴 추적으로 되돌리지 않는다.

## 6. Constraints to Preserve

- `MenuBarExtra`는 `.window` 스타일을 유지한다.
- pause 관련 액션은 nested `Menu`가 아니라 plain button 기반 custom content로 유지한다.
- 단일 컬럼 `360px` 내외의 compact layout을 유지한다.
- 정보 구조는 `상태`, `빠른 제어`, `요약`의 3구역 원칙을 지킨다.
- 상세 설정, 상세 통계, 상세 펫 정보는 별도 창으로 분리한다.

## 7. Target Experience

사용자가 메뉴바 아이콘을 눌렀을 때 느껴야 하는 인상은 아래와 같다.

- "지금 어떤 상태인지 바로 안다."
- "다음으로 할 수 있는 핵심 행동이 맨 먼저 보인다."
- "Nudge만의 표정이 있지만 시끄럽지 않다."
- "설정 패널이 아니라 집중 복귀 도구처럼 느껴진다."

핵심 키워드:

- calm operator
- compact control room
- warm neutral + clear signal
- cute but disciplined

## 8. Information Architecture

### 8.1 Zone A: Hero status

목적:
- 상태 인지와 감정적 앵커를 동시에 담당하는 최상단 구역

필수 요소:
- 현재 상태 타이틀
- 한 줄 상태 설명 또는 카운트다운
- 펫 또는 캐릭터 표현
- 상태에 따른 semantic color signal

원칙:
- 이 구역이 화면의 시각적 중심이어야 한다.
- 하단 카드들과 동일한 톤을 쓰지 않는다.
- 카드 안의 정보 나열보다 "한 장면"처럼 느껴져야 한다.

### 8.2 Zone B: Primary control

목적:
- 사용자가 가장 자주 쓰는 `Pause / Resume`를 즉시 실행

필수 요소:
- 현재 상태에 따라 하나의 주 액션
- 필요 시 보조 duration actions (`10m`, `30m`, `60m`)

원칙:
- 주 액션은 가장 강한 버튼 언어를 사용한다.
- duration actions는 주 액션보다 한 단계 낮은 밀도와 강조를 사용한다.
- 보조 액션이 주 액션과 경쟁하면 안 된다.

### 8.3 Zone C: Secondary utilities

목적:
- 설정 진입, 온보딩 재진입, 종료 등 부가 동작 제공

필수 요소:
- `Settings`
- `Open setup guide`
- `Quit`

원칙:
- 리스트형 또는 조용한 secondary treatment를 사용한다.
- primary control과 같은 시각 강도로 보여서는 안 된다.
- destructive하지 않은 범위에서 최대한 low-emphasis로 둔다.

### 8.4 Zone D: Compact daily summary

목적:
- 오늘의 성과/상태를 가볍게 확인

필수 요소:
- focus time
- sessions
- alerts
- whitelist count 또는 그에 준하는 compact stat

원칙:
- hero도 아니고 설정도 아닌, 조용한 evidence strip이어야 한다.
- 작은 카드 여러 개를 쓰더라도 전체가 하나의 요약 구역처럼 보이게 한다.

## 9. Visual Hierarchy Rules

### 9.1 One hero, not three equal cards

- 상단 hero는 가장 강한 면, 가장 큰 질량, 가장 높은 시선 우선순위를 가진다.
- middle control은 상단보다 조용하지만 행동 유도가 강해야 한다.
- bottom summary는 정보성만 유지하고 존재감은 낮춘다.
- "모든 구역을 같은 카드 스타일로 감싸기"는 금지한다.

### 9.2 Surface strategy

- popover 바깥 배경은 따뜻한 canvas 계열로 유지한다.
- hero는 surface 위에 약한 색 신호나 온도 차를 갖는다.
- primary control은 또렷한 구조를 가지되 hero와 경쟁하지 않는다.
- secondary utilities는 카드보다는 row/list에 가깝게 처리하는 편이 낫다.

### 9.3 Brand anchor

- ASCII 펫은 우측 구석의 장식이 아니라 hero와 함께 정체성을 만든다.
- 다만 장난감처럼 과하게 튀면 안 된다.
- 펫은 "귀여움"보다 "조용한 존재감"을 목표로 한다.

## 10. Action Hierarchy Rules

### 10.1 Primary vs secondary

- `Pause until resumed` 또는 `Resume NudgeWhip`가 항상 최우선 행동이다.
- duration preset은 quick option이지만 주 행동보다 약해야 한다.
- `Settings`, `Open setup guide`, `Quit`는 secondary 또는 tertiary다.

### 10.2 Button language

- primary button은 fill, strong contrast, clear label을 사용한다.
- secondary button은 subtle surface 또는 outline treatment를 사용한다.
- tertiary utility는 row button, icon+label, 또는 text button treatment가 더 적합하다.

### 10.3 Scannability

- 사용자는 위에서 아래로 읽으면서 `상태 확인 -> 행동 -> 부가 동작` 흐름을 자연스럽게 따라야 한다.
- 동등한 버튼이 연속으로 나열되는 구조는 피한다.

## 11. Layout Contract

- target width는 outer/inner를 포함해 `360px` 기준으로 통일한다.
- section 간 간격은 `space.4`와 `space.5`를 기본 리듬으로 사용한다.
- hero 내부는 더 넉넉하고, utility 영역은 더 조밀하게 한다.
- small stats는 2열 또는 4칸 compact grid를 허용하되, 전체 리듬이 깨지지 않아야 한다.
- 외부 padding과 내부 card padding은 같은 숫자를 반복하기보다 용도별로 분리한다.

## 12. Typography and Tone

- 상태 타이틀은 `headline`보다 한 단계 강한 존재감이 필요하다.
- countdown과 숫자형 정보는 monospaced/tabular figures를 유지한다.
- 보조 설명은 짧고 명확해야 하며 2줄 이내를 기본으로 한다.
- muted text는 라이트 모드 대비 기준을 만족하도록 재조정한다.

## 13. Color and Contrast Adjustments

재디자인 구현 전 아래 조정을 기본 후보로 둔다.

- `text.muted`: `#7B8596` -> `#5F6D82` 계열 검토
- light mode `focus` text: `#1E8E7E`보다 더 어두운 접근성 통과 값 검토
- light mode `alert` text: `#E35D3D`보다 더 어두운 접근성 통과 값 검토

원칙:

- 분위기를 위해 대비를 희생하지 않는다.
- signal color는 텍스트와 장식에서 같은 강도로 남발하지 않는다.
- 한 화면 내 가장 강한 색 포인트는 1개만 둔다.

## 14. Proposed Wireframe

```text
+--------------------------------------------------+
| HERO STATUS                                      |
| Focus / Paused / Alerting                        |
| 04:32 until next check        [pet presence]     |
| One-line explanation or reassurance              |
+--------------------------------------------------+
| PRIMARY ACTION                                   |
| [ Pause until resumed ]                          |
| [ 10m ] [ 30m ] [ 60m ]                          |
+--------------------------------------------------+
| TODAY                                            |
| Focus time | Sessions | Alerts | Whitelist       |
+--------------------------------------------------+
| Settings                                         |
| Open setup guide                                 |
| Quit                                             |
+--------------------------------------------------+
```

설명:

- `Today`와 utility의 순서는 구현 시안에서 바뀔 수 있다.
- 다만 utility가 primary action보다 강하게 보이는 구성은 허용하지 않는다.

## 15. Implementation Guidance

### 15.1 Keep

- `.window` based `MenuBarExtra`
- plain button pause controls
- single-column compact layout
- semantic color token system

### 15.2 Change

- 동일한 카드 처리에서 벗어나 section별 시각 강도를 분리한다.
- hero section을 별도 surface language로 재구성한다.
- secondary utilities는 filled button stack이 아니라 더 조용한 row treatment로 낮춘다.
- 폭 규칙을 하나로 통일한다.

### 15.3 Do not regress

- pause action hover/flicker regression 금지
- menu presentation tracking 안정성 유지
- KR/EN 둘 다 truncation 없이 읽혀야 함
- `Reduce Motion`에서 불필요한 장식 모션 금지

## 16. Review Checklist

- [ ] 첫 1초에 상태와 핵심 액션이 보이는가
- [ ] hero가 실제로 화면의 중심인가
- [ ] 펫이 브랜드 앵커로 기능하는가
- [ ] utility actions가 primary action과 경쟁하지 않는가
- [ ] 라이트 모드 대비가 AA 기준을 통과하는가
- [ ] KR/EN 모두 2줄 이내로 안정적으로 읽히는가
- [ ] current `.window` architecture를 깨지 않았는가
- [ ] pause flow manual QA를 통과하는가

## 17. Next Step

1. 이 문서를 기준으로 low-fidelity SwiftUI wireframe을 만든다.
2. hero, primary control, utility row의 surface hierarchy를 먼저 구현한다.
3. contrast token 조정과 width normalization을 함께 반영한다.
4. 수동 QA로 pause/menu stability를 다시 확인한다.
