# Nudge iOS Dashboard Screen Spec

- Version: draft-1
- Last Updated: 2026-04-03
- Status: proposed
- Related: `docs/app/ios-companion-prd.md`, `docs/architecture/cloudkit-sync-contract.md`

## 1. Purpose

- 이 문서는 iOS companion app의 `Home` 및 `Stats` 중심 dashboard 경험을 구체화한다.
- 목표는 iOS 앱이 단순한 상태 미러가 아니라, 사용자가 자기 흐름을 해석할 수 있는 읽기 중심 dashboard가 되도록 화면 구조와 데이터 표현 방식을 고정하는 것이다.
- 구현 전제는 `Mac에서 계산된 projection을 iOS가 읽는다`는 점이다.

## 2. Product Role

- iOS dashboard는 `지금 상태 확인 + 오늘/이번 주 흐름 이해 + 필요한 경우 follow-up 확인` 역할을 맡는다.
- iPhone에서 할 수 있는 일은 읽기, 확인, 가벼운 진단 중심이다.
- iOS app은 집중 차단기나 별도 타이머가 아니다.

## 3. Dashboard Principles

- 상태는 즉시 이해되어야 한다.
- 숫자는 설명 가능해야 한다.
- 차트는 예쁘기보다 해석 가능해야 한다.
- 하루/일주일 단위 요약을 우선하고, 이벤트 로그 재생처럼 보이지 않게 한다.
- 문제를 지적하는 느낌보다 패턴을 보여주는 느낌을 유지한다.

## 4. Data Inputs

### 4.1 Runtime Input

- `MacState`
- 사용처:
- 현재 상태 표시
- 마지막 상태 변경 시각
- 연결/오프라인 판단

### 4.2 Dashboard Projection Input

- `DashboardDayProjection`
- 기본 사용 범위:
- 오늘
- 최근 7일

### 4.3 Alert History Input

- RemoteEscalation 기록용 read model 또는 inbox projection
- 사용처:
- Alerts 탭
- Home의 최근 follow-up 요약

## 5. Navigation Structure

- Tab 1: `Home`
- Tab 2: `Stats`
- Tab 3: `Alerts`
- Tab 4: `Settings`

출시 중심:

- MVP 중심 가치는 `Home + Stats`
- `Alerts`와 `Settings`는 보조 탭

## 6. Home Screen

### 6.1 Goal

- 사용자가 앱을 열자마자 `지금 Mac이 어떤 상태인지`, `오늘 흐름이 어떤지`, `지금 조치가 필요한지`를 이해한다.

### 6.2 Layout Order

1. 상태 hero card
2. 오늘 요약 metrics row
3. 오늘의 짧은 해석 카드
4. 연결/동기화 상태 카드
5. 최근 원격 follow-up 카드

### 6.3 Status Hero Card

포함 요소:

- 상태 아이콘
- 상태 타이틀
- 보조 설명
- 마지막 상태 변경 시각
- 연결 상태 배지

표시 상태:

- `Monitoring`
- `Alerting`
- `Break`
- `Needs Attention`
- `Mac Setup Needed`
- `Offline`

상태별 표현 원칙:

- `Monitoring`: 차분한 안정 상태
- `Alerting`: 대비가 높은 주의 상태
- `Break`: 휴식/일시정지 느낌
- `Mac Setup Needed`: 제한 모드/권한 안내
- `Offline`: 연결 단절 또는 오랫동안 업데이트 없음

보조 문구 예시:

- `Mac이 정상적으로 모니터링 중입니다.`
- `Mac에서 아직 복귀 신호가 확인되지 않았습니다.`
- `Mac에서 잠시 쉬는 중입니다.`
- `Mac에서 권한 또는 설정 확인이 필요합니다.`
- `최근 상태 업데이트가 없어 오프라인으로 표시합니다.`

### 6.4 Today Summary Metrics

카드 4개를 2x2 또는 가변 grid로 구성한다.

카드:

- `오늘 집중 시간`
- `오늘 알림 횟수`
- `평균 복귀 시간`
- `30분 이상 집중 세션`

표현 규칙:

- 숫자가 핵심
- 단위는 짧고 명확하게
- subtitle은 짧은 설명만
- 색은 상태 보조용으로만 사용

### 6.5 Today Insight Card

목적:

- 사용자가 숫자를 해석할 수 있도록 약한 코칭 문장을 제공

입력 예시:

- `hourlyAlertCounts`
- `recoveryDurationTotal / recoverySampleCount`
- `sessionsOver30mCount`

문장 예시:

- `오늘은 오전보다 오후에 넛지가 더 자주 발생했어요.`
- `복귀 시간은 비교적 짧은 편이에요. 흐름 회복이 빠릅니다.`
- `30분 이상 이어진 집중 세션이 여러 번 있었어요.`

주의:

- 비난/진단/감정 해석 금지
- 건강/심리 추정 금지

### 6.6 Sync Health Card

포함 요소:

- 마지막 동기화 시각
- iCloud 상태
- 연결된 Mac 이름/라벨
- 권한/설정 문제 진단 링크

상태 예시:

- `정상 동기화됨`
- `최근 업데이트 없음`
- `iCloud 연결 확인 필요`
- `Mac 권한 설정 필요`

### 6.7 Recent Follow-up Card

목적:

- 최근 RemoteEscalation이 있었는지 짧게 알려준다.

포함 요소:

- 최근 follow-up 발생 시각
- 당시 상태 요약
- Alerts 탭으로 이동하는 CTA

## 7. Stats Screen

### 7.1 Goal

- 사용자가 최근 7일 동안의 패턴을 빠르게 읽고, 언제 흐름이 잘 이어졌고 언제 자주 끊겼는지 파악한다.

### 7.2 Layout Order

1. 범위 선택
2. KPI strip
3. 집중 시간 차트
4. 복귀 시간 차트
5. 시간대별 alert distribution
6. 하단 설명/주의 문구

### 7.3 Range Control

- `Today`
- `Last 7 Days`

MVP 규칙:

- `Today`: 단일 일자 상세
- `Last 7 Days`: 최근 7일 비교

### 7.4 KPI Strip

항목:

- 총 집중 시간
- 평균 복귀 시간
- 최장 집중 블록
- 원격 후속 알림 이후 복귀 비율(추정치)

표현 규칙:

- 4개 이하
- 한 번에 스캔 가능해야 함
- 지나치게 많은 지표 나열 금지

### 7.5 Focus Time Chart

형태:

- 일별 bar chart

목적:

- 최근 7일 집중 시간 흐름 비교

표현:

- x축: 날짜 또는 요일
- y축: 집중 시간
- 오늘은 강조

해석 문구 예시:

- `최근 7일 중 집중 시간이 가장 길었던 날`

### 7.6 Recovery Time Chart

형태:

- line chart 또는 compact bar chart

지표:

- 평균 복귀 시간
- 필요 시 max 복귀 시간은 보조 정보로만

표현 원칙:

- 변동을 보여주되 과한 정밀도는 피함
- 초 단위보다 분 단위 요약 우선

### 7.7 Alert Distribution

형태:

- 24칸 hourly distribution
- MVP에서는 heatmap 또는 segmented bar 중 하나

목적:

- “언제 넛지가 자주 발생하는지”를 보여준다.

표현 원칙:

- 1시간 버킷만 사용
- exact timestamp 로그처럼 보이지 않게 함

해석 문구 예시:

- `오후 3시~5시에 넛지가 집중되는 경향이 있어요.`

### 7.8 Stats Footnote

- 이 데이터는 Mac에서 계산된 요약치입니다.
- 실시간 보장이나 정밀 행동 추적을 의미하지 않습니다.

## 8. Alerts Screen

### 8.1 Goal

- 원격 후속 알림이 언제 있었는지, 놓친 알림이 있었는지 확인한다.

### 8.2 Layout

- 최근 알림 리스트
- 각 row:
- 시각
- 짧은 문구
- 당시 상태 요약
- 복귀 여부가 있으면 가벼운 보조 badge

### 8.3 Empty State

- `최근 원격 후속 알림이 없습니다.`

## 9. Settings Screen

### 9.1 Goal

- 연동 상태와 문제를 이해하고, 어디를 고쳐야 하는지 알 수 있게 한다.

### 9.2 Sections

- Account / iCloud
- Notification permission
- Connected Mac
- Sync status
- Pro status
- Privacy / data explanation

## 10. Visual Direction

- overall tone: calm utility
- 배경은 밝고 안정적
- 숫자 대비는 높게
- 상태 색은 제한적으로 사용
- chart는 장식보다 읽기 우선

디자인 키워드:

- calm
- precise
- non-judgmental
- reflective

## 11. Copy Direction

- 평가하지 않는다.
- 사용자를 진단하지 않는다.
- “왜 또 딴짓했는지” 같은 표현 금지
- 숫자를 설명하는 짧은 관찰형 문장 사용

좋은 예:

- `오늘은 복귀가 비교적 빨랐어요.`
- `오후 시간대에 넛지가 조금 더 많았습니다.`
- `최근 7일 동안 집중 시간이 안정적으로 유지되고 있어요.`

나쁜 예:

- `집중력이 낮습니다.`
- `산만함이 심해졌습니다.`
- `문제가 있는 패턴입니다.`

## 12. Empty / Error / Edge States

### 12.1 No Mac Connected

- 앱 역할 설명
- 연결 유도 CTA
- demo preview 허용

### 12.2 No Data Yet

- 첫 사용자의 빈 상태
- 예시 카드와 설명 제공

### 12.3 Offline

- 마지막 업데이트 시각 표시
- stale data badge 표시

### 12.4 Limited No AX

- `Mac에서 권한 설정이 필요합니다`
- iOS에서 해결 불가함을 명확히 안내

### 12.5 Push Disabled

- Alerts 탭/Settings에서 권한 안내
- dashboard 자체는 계속 사용 가능

## 13. Free / Pro Presentation

### 13.1 Free

- Home 기본 상태 카드
- 오늘 요약 일부
- 제한된 최근 통계 또는 sample stats

### 13.2 Pro

- 전체 7일 stats
- hourly distribution
- remote follow-up history
- 원격 후속 알림 이후 복귀 비율(추정치)

## 14. Data-to-UI Mapping

- `MacState` -> Home hero, Settings status
- `DashboardDayProjection(today)` -> Home summary
- `DashboardDayProjection(last7)` -> Stats charts
- `RemoteEscalation history projection` -> Alerts

## 15. Non-Goals

- 앱별 사용 추적
- 세부 activity log replay
- exact per-event forensic view
- iPhone에서 Mac을 원격 제어하는 기능

## 16. Implementation Hand-off Notes

- UI는 projection-first로 설계한다.
- chart용 모델은 screen-specific view model로 한 번 더 정규화해도 된다.
- Home과 Stats는 loading skeleton을 제공한다.
- 숫자 계산은 iOS가 아니라 Mac projection 생성 단계에서 끝내는 것을 원칙으로 한다.
