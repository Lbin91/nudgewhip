# Nudge Funnel Strategy

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `marketing-strategist`
- Scope: acquisition, activation, conversion, retention

## 1. Funnel Objective

- Nudge의 퍼널은 `attention recall tool`을 처음 이해한 사용자가 실제 idle recovery를 경험하고, 이후 Free/Pro 전환까지 가는 흐름을 정의한다.
- 핵심은 설치 수가 아니라 `첫 복귀 성공 경험`이다.

## 2. Funnel Stages

### 2.1 Acquisition

- 목적: waitlist, GitHub, launch website 유입 확보
- 유입원: Product Hunt, GitHub, Reddit, HN, newsletter, direct share
- Trigger: hero copy, privacy message, beta invite
- Metrics: visit-to-waitlist, GitHub CTR, scroll depth, launch page completion

### 2.2 Activation

- 목적: 권한 승인과 첫 idle detection 성공
- Trigger: onboarding, Accessibility explanation, first run tutorial
- Success event: 첫 `monitoring -> alerting -> recovery` 완료
- Metrics: permission grant rate, first alert completion rate, time-to-first-recovery

### 2.3 Conversion

- 목적: Free 사용자가 Pro 가치까지 이해하고 업그레이드
- Trigger: iPhone follow-up 필요, whitelist need, break mode, detailed stats, pet growth
- Success event: upgrade CTA 클릭 또는 checkout start
- Metrics: upgrade CTR, checkout start rate, price-page bounce, feature comparison engagement

### 2.4 Retention

- 목적: 반복 사용과 습관화를 만든다
- Trigger: daily summary, streak, pet progress, recovery praise, email follow-up
- Success event: 반복 세션 발생
- Metrics: D7/D30 retention, session frequency, alerts per active day, streak persistence

## 3. Activation Mechanics

- 사용자가 설치 후 가장 먼저 이해해야 하는 것은 `왜 Accessibility가 필요한가`이다.
- 다음으로 이해해야 하는 것은 `Nudge가 키 입력 내용을 보지 않는다`는 점이다.
- 마지막으로 경험해야 하는 것은 `idle 후 부드러운 복귀`이다.

## 4. Conversion Mechanics

- Free value: Mac 단일 복귀 루프
- Pro value: Mac + iPhone 복귀 루프 + 예외 제어 + 상세 통계 + 누적 보상
- upgrade trigger는 기능 목록이 아니라 `반복되는 불편`과 `추가 통제 필요`로 설명한다
- 가격 커뮤니케이션은 기능보다 신뢰와 편의성에 묶어 말한다

## 5. Retention Mechanics

- 일일 요약은 성과와 개선점을 함께 보여준다
- streak는 죄책감 장치가 아니라 복귀 동기 부여 장치다
- pet growth는 주 사용자 행동을 가리지 않는 범위에서만 노출한다
- 반복 오탐이 있으면 break suggestion으로 전환해 이탈을 줄인다

## 6. KPI and Instrumentation

| Stage | Primary KPI | Secondary KPI | Event |
|---|---|---|---|
| Acquisition | waitlist conversion rate | GitHub CTR | landing page visit |
| Activation | permission grant rate | first recovery rate | onboarding complete |
| Conversion | upgrade CTR | checkout start rate | Pro value view |
| Retention | D7/D30 retention | session frequency | daily summary view |

## 7. Messaging Triggers

| Trigger | Message Angle | Channel |
|---|---|---|
| First visit | What Nudge is | hero, social |
| Permission step | Why Accessibility is needed | onboarding, FAQ |
| First idle recovery | The product works | in-app, email |
| Repeated false positives | You can pause or whitelist | in-app, support |
| Pro need emerges | iPhone follow-up and detailed control | pricing, upgrade surface |

## 8. Risks and Mitigations

- Risk: 사용자가 권한 문구를 경계한다
- Mitigation: 수집하지 않는 데이터와 필요한 이유를 먼저 말한다
- Risk: Free와 Pro 차이가 모호하다
- Mitigation: Mac-only loop와 Mac+iPhone loop를 분리해서 보여준다
- Risk: 알림이 잔소리처럼 보인다
- Mitigation: 짧은 문장과 cooldown, fatigue guardrail을 앞세운다

