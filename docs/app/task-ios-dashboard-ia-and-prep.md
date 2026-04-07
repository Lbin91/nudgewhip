# Nudge Task: iOS Dashboard IA Freeze & Implementation Prep

- Version: draft-2
- Last Updated: 2026-04-04
- Status: active
- Owner: product / design / engineering

## 1. Purpose

- iOS dashboard 구현에 바로 들어갈 수 있도록 화면 구조, 섹션 계약, 상태별 fallback, 차트 선택, 카피 톤을 개발 단위로 확정한다.
- 목표는 `화면이 어떤 질문에 답해야 하는지`와 `어떤 projection field를 쓰는지`를 동시에 고정하는 것이다.

## 2. Related Docs

- [ios-dashboard-screen-spec.md](./ios-dashboard-screen-spec.md)
- [ios-companion-prd.md](./ios-companion-prd.md)
- [task-ios-dashboard-data-schema.md](./task-ios-dashboard-data-schema.md)

## 3. Official Alignment Check

다음 공식 문서와 어긋나지 않도록 유지한다.

- Apple Human Interface Guidelines
  [Tab views](https://developer.apple.com/design/human-interface-guidelines/tab-views)
  [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/)
- App Review Guidelines
  [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

반영 원칙:

- 탭은 4개 이하로 유지하고 역할을 명확히 나눈다.
- Home은 glanceable 해야 하고, 정보 밀도가 과도하면 안 된다.
- 차트는 해석 가능성이 장식성보다 우선이다.
- 앱은 자체 utility가 보여야 하므로 demo/empty 상태에서도 구조를 이해시켜야 한다.
- copy는 비판/진단/감정 해석을 피한다.

## 4. IA Freeze

### 4.1 Navigation

- `Home`
- `Stats`
- `Alerts`
- `Settings`

### 4.2 Navigation Rules

- Home은 현재 상태와 오늘 요약에 답한다.
- Stats는 최근 7일 패턴 해석에 답한다.
- Alerts는 놓친 remote follow-up 확인에 답한다.
- Settings는 연결/권한/동기화 문제 해결에 답한다.

### 4.3 Completion Criteria

- 탭 구조가 더 이상 흔들리지 않는다.
- 각 탭이 “무엇을 보여주기 위한 화면인지” 한 문장으로 설명 가능하다.

## 4.4 Mac → iOS 상태 매핑

Mac `NudgeWhipRuntimeState` 7개 상태를 iOS 표시 상태 6개로 매핑한다.

| Mac RuntimeState | iOS Display State | 근거 |
|---|---|---|
| `monitoring` | Monitoring | 정상 집중 중 |
| `alerting` | Alerting | idle 임계값 초과 |
| `pausedManual` | Break | 사용자 수동 휴식 |
| `pausedSchedule` | Break | 스케줄 기반 휴식 |
| `pausedWhitelist` | Break (화이트리스트) | 화이트리스트 앱 사용 중 자동 휴식. iOS에서는 Break로 표시하되 subtitle로 구분 권장 |
| `limitedNoAX` | Mac Setup Needed | 접근성 권한 미승인 |
| `suspendedSleepOrLock` | Offline | Mac sleep/잠금 상태 |

매핑 규칙:

- `pausedManual`, `pausedSchedule`, `pausedWhitelist`는 iOS에서 모두 `Break` 라벨을 사용한다.
- `pausedWhitelist`는 `Break` 하위에 "허용된 앱 사용 중" 같은 subtitle로 구분을 권장한다. (MVP에서는 subtitle 없이 Break로 통합 가능)
- `suspendedSleepOrLock`과 `limitedNoAX`는 서로 다른 원인이므로 iOS에서 반드시 구분된 라벨을 사용한다.
- `alerting`과 Break 계열이 동시 발생할 수 없으므로, 표시 상태 간 충돌은 없다.

## 5. Screen Contracts

### 5.1 Home

화면이 답해야 하는 질문:

- 지금 Mac 상태가 무엇인가?
- 오늘 흐름은 어땠는가?
- 지금 조치가 필요한가?

섹션 순서:

1. hero status card
2. today summary cards
3. insight card
4. sync health card
5. recent follow-up card

사용 데이터:

- `MacState`
- 오늘 `DashboardDayProjection`
- 최근 `RemoteEscalation` summary

필수 필드:

- 상태 label
- 마지막 상태 변경 시각
- `totalFocusDuration` (Free)
- `alertCount` (Free)
- `completedSessionCount` (Free)
- `longestFocusDuration` (Free)
- `recoveryDurationTotal / recoverySampleCount` (Pro)
- `sessionsOver30mCount` (Pro)

Free/Pro 분기:

- Free: hero status card, today summary cards (totalFocusDuration, alertCount, completedSessionCount, longestFocusDuration), sync health card
- Pro: 위 항목 + insight card (recoveryDurationTotal/recoverySampleCount), recent follow-up card (remoteEscalation summary)
- Free 사용자는 insight card와 recent follow-up card가 숨김 처리되거나 "Pro에서 확인 가능" CTA로 대체

CTA:

- Alerts 탭 이동
- Settings 탭 이동

Acceptance:

- Home만 보고도 현재 상태와 오늘 흐름을 설명할 수 있다.
- 첫 화면에서 차트 없이도 상태를 이해할 수 있다.
- 첫 화면 스크롤 1회 이내에서 핵심 정보가 끝난다.

### 5.2 Stats

화면이 답해야 하는 질문:

- 최근 7일 동안 언제 흐름이 잘 이어졌는가?
- 언제 자주 끊겼는가?
- 복귀 속도는 어떤 추세인가?

섹션 순서:

1. range control
2. KPI strip
3. focus chart
4. recovery chart
5. alert distribution
6. stats footnote

사용 데이터:

- 최근 7일 `DashboardDayProjection`

필수 필드:

- `totalFocusDuration` (Free)
- `longestFocusDuration` (Free)
- `completedSessionCount` (Free)
- `recoveryDurationTotal` (Pro)
- `recoverySampleCount` (Pro)
- `hourlyAlertCounts[24]` (Pro)
- `remoteEscalationSentCount` (Pro)
- `remoteEscalationRecoveredWithinWindowCount` (Pro)

Free/Pro 분기:

- Free: KPI strip (totalFocusDuration, completedSessionCount, alertCount, longestFocusDuration), focus chart, stats footnote
- Pro: 위 항목 + recovery chart, alert distribution (hourlyAlertCounts), remote escalation metrics
- Free 사용자는 recovery chart와 alert distribution 섹션이 숨김 처리되거나 "Pro에서 확인 가능" CTA로 대체

CTA:

- 없음 또는 future drill-down only

Acceptance:

- 사용자가 7일 패턴을 한 번의 스크롤로 이해할 수 있다.
- exact event log처럼 보이지 않는다.
- 24-bin 분포가 좁은 화면에서도 읽기 가능한 fallback을 가진다.

### 5.3 Alerts

화면이 답해야 하는 질문:

- 최근 원격 후속 알림이 있었는가?
- 놓친 알림이 있었는가?

섹션 순서:

1. alerts list
2. empty state if needed

사용 데이터:

- `RemoteEscalationEvent` CloudKit records (data schema section 7.5 참조)

필수 필드:

- alert occurred at
- short message
- state summary

Free/Pro 분기:

- Alerts 탭 전체가 Pro 기능이다.
- Free 사용자는 탭은 표시되나, 내부에 “Pro 기능” 안내와 업그레이드 CTA만 표시된다.
- Free 사용자의 Home recent follow-up card도 숨김 처리된다.

Acceptance:

- 사용자가 “언제 follow-up이 왔는지”를 시간 순서로 이해 가능하다.
- missed notification을 앱 안에서 복기할 수 있다.
- Free 사용자에게 Alerts 탭이 Pro 기능임이 명확히 전달된다.

### 5.4 Settings

화면이 답해야 하는 질문:

- 연결이 정상인가?
- iCloud / 알림 권한 / Mac 권한 상태가 어떤가?
- 어디를 고치면 되는가?

섹션 순서:

1. account / iCloud
2. connected Mac
3. sync status
4. notification permission
5. Pro status
6. privacy explanation

Free/Pro 분기:

- Settings는 Free/Pro 공통 화면이다.
- Pro status 섹션에서 현재 플랜 상태와 Pro 기능 목록(recovery metrics, hourly distribution, alerts history)을 보여준다.
- Free 사용자는 Pro status 섹션에서 업그레이드 CTA를 본다.

필수 필드:

- iCloud status
- notification permission status
- connected Mac label
- last sync time

Acceptance:

- 문제 상태가 있을 때 사용자가 해결 방향을 이해할 수 있다.

## 6. Chart Choices

### 6.1 Locked Choices

- Focus:
  vertical bar chart
- Recovery:
  line chart
  compact bar fallback 허용
- Alert distribution:
  24-bin segmented bar 우선
  compact heatmap fallback 허용

### 6.2 Chart Constraints

- Home에는 heavy chart를 넣지 않는다.
- Stats에서만 비교형 차트를 사용한다.
- 24-bin chart는 label density를 줄이고 hover 없는 모바일 읽기 기준으로 설계한다.
- exact timestamp처럼 읽히는 표현은 피한다.

### 6.3 Acceptance

- 차트가 없어도 핵심 KPI는 읽힌다.
- 차트는 숫자를 설명하는 역할만 하고, 유일한 의미 전달 경로가 아니다.

## 7. Empty / Error / Demo State Matrix

### 7.1 Required States

- no Mac connected
- no data yet
- offline / stale
- limited / permission issue
- CloudKit sync error
- push disabled

### 7.2 Rules

- empty state는 앱 구조를 설명해야 한다.
- demo state는 App Review를 위해 app utility를 보여줄 수 있어야 하며, sample/demo data임을 명확히 라벨링해야 한다.
- error state는 진단과 다음 행동을 함께 제공해야 한다.
- stale data는 “마지막 업데이트 시각”을 함께 보여야 한다.

### 7.3 Acceptance

- 어떤 상태에서도 화면이 갑자기 비거나 의미 없는 placeholder만 보이지 않는다.

## 8. Tone & Manner

### 8.1 Tone Template

- 관찰:
  사실을 짧게 말한다
- 해석:
  가벼운 패턴 설명 1문장
- 제안:
  필요할 때만 다음 행동 1개

### 8.2 Allowed Style

- calm
- observational
- reflective
- non-judgmental

### 8.3 Banned Style

- 비난
- 진단
- 감정 추정
- 건강/심리 추론
- “왜 또” 같은 표현

### 8.4 Acceptance

- 모든 insight 문장이 `사실 -> 약한 해석` 수준에 머문다.

## 9. Accessibility & HIG Watchouts

### 9.1 Required

- 44pt tap target
- Dynamic Type 대응
- VoiceOver labels
- color-only signaling 금지
- reduced motion 대응
- chart 외 수치 요약 제공

### 9.2 Watchouts

- 탭이 많아 보여도 각 탭 목적이 분명해야 한다.
- Home에 너무 많은 카드/차트를 넣지 않는다.
- 24-bin heatmap은 작아지면 읽기 어려우므로 segmented bar fallback 준비
- judgmental copy는 App Review 및 UX 모두에서 리스크
- 차트만으로 의미를 전달하지 말고 KPI/footnote와 함께 제공
- settings row와 주요 카드 CTA는 최소 44pt tap target을 유지

## 10. Implementation Start Order

권장 순서:

1. `DashboardDayProjection` 모델/스키마
2. Mac-side projection calculator
3. mock data 기반 iOS Home / Stats UI
4. CloudKit projection sync

작업:

- [ ] 우선순위 합의
- [ ] 첫 구현 단위 acceptance 기준 구체화
- [ ] mock data contract 정의
- [ ] UI 구현 티켓 생성

완료 기준:

- 다음 작업이 문서 작성이 아니라 코드 작업으로 이어진다.

## 11. Deliverables

- screen-by-screen field mapping
- chart selection freeze
- empty/error/demo matrix
- tone template
- implementation order

## 12. Risks to Watch

- Home이 summary screen이 아니라 analytics screen처럼 무거워질 수 있음
- Stats가 exact behavior log처럼 보일 수 있음
- demo/empty state가 약하면 standalone utility가 약해 보일 수 있음
- accessibility 대응이 뒤로 밀릴 수 있음
