# Nudge Launch Plan

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `marketing-strategist`
- Scope: Phase 1~2 launch alignment for product, web, and community

## 1. Purpose

- 이 문서는 Phase 1~2 출시 전에 마케팅, 웹, 콘텐츠, 디자인, QA가 같은 일정과 메시지를 보게 하기 위한 실행 계획이다.
- 목표는 `attention recall tool` 포지셔닝을 고정하고, `ko/en` 동시 운영과 Free/Pro 패키징을 출시 전에 정렬하는 것이다.

## 2. Launch Narrative

- 핵심 메시지: 딴짓을 막는 앱이 아니라, 딴짓이 시작된 순간 다시 돌아오게 하는 앱
- 제품 카테고리: `attention recall tool`
- 톤: 짧고 명확하며 죄책감을 유발하지 않는다
- 신뢰 축: 프라이버시 우선, 로컬 퍼스트, Accessibility 권한 이유를 명확히 설명

## 3. Timeline

### Phase Duration (예상)

| Phase | 기간 | 비고 |
|---|---|---|
| Prelaunch | 4주 | 카피/디자인/웹/현지화 정렬 |
| Beta | 8주 | 초기 사용자 확보, 피드백 수집, 리텐션 검증 |
| Pro Launch | 4주 | Pro 전환, iOS 연동 메시징, 유료화 |

### Phase Transition Gates

| Gate | 진입 조건 | 검증 시점 |
|---|---|---|
| Beta 진입 | landing page 배포 완료 + waitlist 100명 이상 | Prelaunch 종료 시 |
| Pro Launch 진입 | Beta D7 retention > 30% + critical bug 0개 + waitlist 500명 | Beta 종료 시 |

### 3.1 Prelaunch

| Workstream | Goal | Deliverable | Owner | KPI |
|---|---|---|---|---|
| Positioning | 메시지 고정 | hero/subhead/FAQ 핵심 카피 | `marketing-strategist` | 카피 승인 1회 완료 |
| Web | waitlist 수집 준비 | landing page, OGP, form, analytics | `web-dev` | form submit 성공률 |
| Content | 앱 내 카피 정렬 | 알림/업그레이드/프라이버시 문구 | `content-strategist` + `localization` | launch-scope key coverage |
| Design | 비주얼 방향 고정 | design system, icon, character brief | `visual-designer` | 시안 승인 |
| QA | KR/EN 검증 준비 | screenshot matrix, copy fit check | `qa-integrator` | critical truncation 0 |

### 3.2 Beta

| Workstream | Goal | Deliverable | Owner | KPI |
|---|---|---|---|---|
| Beta acquisition | 초기 사용자 확보 | GitHub, waitlist, community posts | `marketing-strategist` | waitlist conversion rate |
| Beta feedback | 문제/오탐 수집 | issue template, feedback form | `qa-integrator` + `web-dev` | feedback response rate |
| Beta trust | 권한/프라이버시 설명 | onboarding copy, privacy page | `localization` + `content-strategist` | permission drop-off |
| Beta retention | 재방문 유도 | daily summary, email follow-up | `marketing-strategist` | return visit rate |

### 3.3 Pro Launch

| Workstream | Goal | Deliverable | Owner | KPI |
|---|---|---|---|---|
| Monetization | Pro value 정리 | Free/Pro comparison, pricing page | `marketing-strategist` | upgrade CTR |
| Cross-device story | iOS 연동 설명 | best-effort sync messaging | `cloudkit-sync` + `marketing-strategist` | Pro interest rate |
| Social proof | 신뢰 형성 | testimonials, launch post, changelog | `marketing-strategist` | share rate |
| Conversion | 구매 전환 | upgrade CTA, paywall copy | `marketing-strategist` + `web-dev` | checkout start rate |

## 4. Channel Plan

### 4.1 Owned

- Launch website
- GitHub repository and README
- App onboarding and in-app upgrade surfaces
- Email waitlist and launch announcement

### 4.2 Earned

- Product Hunt
- Hacker News
- Reddit communities for productivity, macOS, indie apps
- developer newsletters and community posts

### 4.3 Paid

- Phase 1에서는 기본적으로 사용하지 않는다
- Phase 2에서만 소규모 테스트 광고를 검토한다

## 5. KPI Stack

### 5.1 Prelaunch KPIs

- Waitlist conversion rate: 목표 >15%, 최소 5%, 위험 <2%
- GitHub click-through rate
- permission onboarding completion rate: 목표 >70%, 최소 50%, 위험 <30%
- KR/EN page parity pass rate

### 5.2 Beta KPIs

- Activation rate: idle detection 첫 성공 경험 비율
- D7 retention: 목표 >40%, 최소 25%, 위험 <15%
- permission grant rate: 목표 >70%, 최소 50%, 위험 <30%
- alert recovery rate
- feedback completion rate
- D30 retention: 목표 >20%, 최소 10%, 위험 <5%

### 5.3 Pro Launch KPIs

- Free to Pro upgrade CTR
- Pro checkout start rate
- iOS companion interest rate
- churn risk indicator based on failed activation or repeated false positives

## 6. Ownership Matrix

| Area | Primary Owner | Support |
|---|---|---|
| Positioning | `marketing-strategist` | `content-strategist`, `web-dev` |
| Copy | `marketing-strategist` | `localization` |
| Visual direction | `visual-designer` | `web-dev` |
| Permission/privacy copy | `localization` | `macos-core`, `content-strategist` |
| Launch site | `web-dev` | `marketing-strategist`, `visual-designer` |
| QA | `qa-integrator` | all owners |

## 7. Operating Rules

- 출시 메시지는 `attention recall tool`, `privacy-first`, `ko/en`, `Free/Pro`의 4개 축을 벗어나지 않는다.
- 제품이 실제로 제공하지 않는 실시간 보장, 화면 분석, 입력 내용 수집은 절대 주장하지 않는다.
- 모든 채널은 동일한 핵심 문장을 재사용하되, 표면별로 길이와 톤만 조절한다.

