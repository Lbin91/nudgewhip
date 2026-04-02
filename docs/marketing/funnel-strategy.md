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

### 3.1 Accessibility 권한 거부 사용자 Sub-funnel (limitedNoAX)

`limitedNoAX` 상태 사용자를 위한 별도 Activation 경로:

| 단계 | 경험 | 가치 제안 |
|---|---|---|
| 진입 | 권한 없이 앱 실행 | 기본 카운트 확인 가능 (UI 노출) |
| 인지 | 제한 모드 안내 메시지 | "권한 없이도 기본 카운트를 확인할 수 있습니다" |
| 동기 | 정확한 감지 vs 제한 모드 차이 체감 | "권한 승인 시 정확한 idle 감지 + 캐릭터 활성화" |
| 전환 | 권한 재요청 CTA | 설정 앱 바로가기 + 권한 필요 이유 재안내 |

- 제한 모드에서도 메뉴바 UI와 기본 카운트를 보여주어 앱 가치를 선경험시킨다.
- 캐릭터(pet)는 권한 승인 후에만 활성화되어 권한 전환의 추가 동기가 된다.
- 권한 재요청은 최초 1회 자동, 이후 사용자 액션(설정 버튼)에 의해서만 트리거.

## 4. Conversion Mechanics

- Free value: Mac 단일 복귀 루프
- Pro value: Mac + iPhone 복귀 루프 + 예외 제어 + 상세 통계 + 누적 보상
- upgrade trigger는 기능 목록이 아니라 `반복되는 불편`과 `추가 통제 필요`로 설명한다
- 가격 커뮤니케이션은 기능보다 신뢰와 편의성에 묶어 말한다

### 4.1 Pricing 전략 (사전 검증)

- 가설 가격: `$8.99~$9.99` (spec.md Section 4 기준)
- Prelaunch 단계에서 landing page에 fake-door 가격 테스트를 배치하여 지불 의향을 사전 검증한다.
- waitlist 폼에 가격 민감도 옵션을 추가하여 가격대별 전환 의향 데이터를 수집한다.
- Beta 종료 시 수집된 데이터로 최종 가격을 확정한다.

### 4.2 Free 사용자 펫 프리뷰 전략

- Free 사용자: `sprout` 고정 캐릭터, 3가지 감정 상태만 노출 (기쁨, 보통, 슬픔)
- Pro 카드(업그레이드 유도 UI)에서 `buddy`/`guide` 펫 프리뷰를 실루엣 또는 흐림 처리로 노출
- 프리뷰 카피: "Pro에서 buddy/guide 캐릭터와 함께 성장하세요"
- 펫 프리뷰는 기능 나열이 아닌 감정적 연결(attachment)을 유도하는 방향으로 설계한다.
- Free에서도 펫 기본 애니메이션(흔들림, 반응)은 제공하여 캐릭터 존재감을 유지한다.

## 5. Retention Mechanics

- 일일 요약은 성과와 개선점을 함께 보여준다
- streak는 죄책감 장치가 아니라 복귀 동기 부여 장치다
- pet growth는 주 사용자 행동을 가리지 않는 범위에서만 노출한다
- 반복 오탐이 있으면 break suggestion으로 전환해 이탈을 줄인다

## 6. KPI and Instrumentation

| Stage | Primary KPI | 목표 | 최소 | 위험 | Secondary KPI | Event |
|---|---|---|---|---|---|---|
| Acquisition | waitlist conversion rate | >15% | 5% | <2% | GitHub CTR | landing page visit |
| Activation | permission grant rate | >70% | 50% | <30% | first recovery rate | onboarding complete |
| Conversion | upgrade CTR | - | - | - | checkout start rate | Pro value view |
| Retention | D7 retention | >40% | 25% | <15% | session frequency | daily summary view |
| Retention | D30 retention | >20% | 10% | <5% | session frequency | daily summary view |

### KPI 해석 기준

- **목표**: 이 수치에 도달하면 해당 단계가 정상 궤도에 있다고 판단
- **최소**: 이 수치 미만이면 해당 단계의 메커니즘 재검토 필요
- **위험**: 이 수치 미만이면 전략 전환 또는 심층 원인 분석 필수

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

