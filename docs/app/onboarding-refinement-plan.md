# Onboarding Refinement Plan

- Version: 0.1
- Last Updated: 2026-04-03
- Owner: `swiftui-designer` + `localization`
- Scope: first-install onboarding polish after the initial implementation landed

## 1. Purpose

- 최초 구현된 온보딩을 실제 제품 수준 UX로 다듬기 위한 후속 작업을 정리한다.
- 현재 구조는 동작은 하지만, 시각 밀도/정렬/상태 설명/권한 복구 경험에서 polish가 더 필요하다.

## 2. Current gaps

현재 구현 기준에서 보완이 필요한 대표 영역:

1. 창 크기와 카드 비율
2. step 간 시각적 일관성
3. 권한/limited mode 설명의 명확성
4. 완료 후 행동(메뉴바 시작/재진입) 안내
5. 키보드/VoiceOver 사용성

## 3. Refinement goals

1. 각 step가 더 명확한 정보 블록으로 보이게 한다.
2. CTA 우선순위를 더 분명히 만든다.
3. limited mode도 실패처럼 보이지 않게 한다.
4. KR/EN 텍스트 길이 차이에도 안정적으로 보이게 한다.
5. 재오픈/재진입 시 UX 혼란을 줄인다.

## 4. Screen-by-screen refinement focus

### 4.1 Welcome

현재 이슈:
- 가치 전달은 되지만 시각적 밀도가 낮을 수 있음

보강안:
- 작은 preview illustration 또는 status-strip 삽입
- “무엇을 하지 않는지” bullet을 더 읽기 쉽게 카드형으로 유지

### 4.2 Permission

현재 이슈:
- 설명이 길면 사용자가 CTA와 핵심 메시지를 바로 못 잡을 수 있음

보강안:
- `왜 필요한지` / `무엇을 수집하지 않는지`를 분리 섹션으로 표시
- denied 상태일 때 “설정 열기” CTA를 시각적으로 더 강하게

### 4.3 Basic Setup

현재 이슈:
- threshold / launch-at-login / TTS / visual mode가 많아 보일 수 있음

보강안:
- `Detection`, `Guidance` 두 그룹으로 시각 분리
- 테스트용 짧은 threshold는 개발용 라벨을 더 분명히
- 추천값 강조를 더 명확히

### 4.4 Completion (Ready)

현재 이슈:
- 완료 후 다음 행동이 메뉴바 앱 경험으로 충분히 연결되지 않을 수 있음

보강안:
- “이제 메뉴바 아이콘에서 상태와 countdown을 볼 수 있어요” 메시지 강화
- 필요 시 메뉴바 highlight 1회 연출 검토

### 4.5 Completion (Limited)

현재 이슈:
- 제한 모드 설명이 부족하면 “앱이 안 되는 것 같다”는 느낌 가능

보강안:
- 제한 모드에서도 가능한 것 / 불가능한 것을 더 명확히 구분
- `권한 다시 설정` CTA를 더 쉽게 찾게 함

## 5. UX mechanics to refine

### 5.1 Reopen path

- 메뉴바에서 다시 열 때 즉시 멈춤/혼란 없이 열려야 함
- 이미 열려 있으면 해당 window만 앞으로 가져오기

### 5.2 Close behavior

- `Cmd+W`, `Esc`, 창 닫기 버튼 동작 일관성 필요
- “나중에 설정”과 창 닫기의 의미 차이 명확화 필요

### 5.3 Error handling

- 권한 요청 실패
- launch at login 승인 필요
- 저장 실패

이때 사용자에게 너무 기술적인 에러를 보여주지 않도록 가공 필요

## 6. Accessibility / localization polish checklist

- Tab 순서 자연스러운지
- 기본 포커스가 primary CTA에 가는지
- VoiceOver에서 badge/CTA 의미 전달되는지
- KR/EN 줄바꿈 자연스러운지
- 버튼 폭이 locale 길이에 견디는지
- Dynamic Type 확대에도 섹션 붕괴 없는지

## 7. Visual design refinement ideas

- progress chip를 더 차분하게
- 헤더 title/subtitle 간 간격 미세 조정
- GroupBox 대신 커스텀 section card로 통일 여부 검토
- completion state icon 크기와 여백 통일
- 카드/배경 대비를 다크모드에서 재검토

## 8. Copy refinement items

- `나중에 설정` vs `건너뛰기`
- `메뉴바에서 시작` vs `계속`
- limited mode 설명 톤 축약 여부
- launch-at-login 도움말 문구 짧게 재작성

## 9. Recommended implementation order

1. 메뉴 재오픈/닫기 동작 안정화
2. Permission / Limited step copy hierarchy 정리
3. Basic setup 그룹화 강화
4. completion CTA polish
5. accessibility/keyboard/VoiceOver 점검
6. KR/EN screenshot QA

## 10. Acceptance Criteria

- 온보딩 모든 단계가 KR/EN에서 시각적으로 안정적이다.
- 재오픈/닫기 동작이 예측 가능하다.
- limited mode에서 복구 경로가 명확하다.
- primary CTA가 각 화면에서 즉시 눈에 띈다.
- keyboard/VoiceOver 탐색이 막히지 않는다.

## 11. Verification plan

Manual:
- fresh install granted
- fresh install denied
- reopen from menu bar
- close via window button / Cmd+W / Esc
- return from system settings

UI QA:
- KR screenshots
- EN screenshots
- dark mode
- small window

Accessibility QA:
- keyboard only
- VoiceOver
