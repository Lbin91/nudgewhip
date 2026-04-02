# Nudge Acceptance Matrix

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `qa-integrator`
- Scope: launch-blocking acceptance criteria for P1/P2 implementation

## 1. Purpose

- 이 문서는 구현팀과 QA가 같은 기준으로 기능 완료 여부를 판단하도록 만든다.
- 각 항목은 `Given / When / Then` 수용 기준, 담당자, 테스트 타입, 목표 지표, 엣지 케이스, blocker를 함께 담는다.
- `P2` 기준에서는 “작동함”보다 “경계면에서 깨지지 않음”을 더 중요하게 본다.

## 2. Acceptance Matrix

| Area | Given | When | Then | Owner | Test Type | Target Metric | Edge Cases | Blockers |
|---|---|---|---|---|---|---|---|---|
| Accessibility permission | 사용자가 첫 실행 상태이고 Accessibility 권한이 없다 | 권한 안내 화면을 보고 허용 또는 거부를 선택한다 | 허용 시 monitoring으로 진입하고, 거부 시 limitedNoAX 제한 모드가 노출된다 | `macos-core` + `localization` | UI + permission flow | 권한 허용/거부 결과가 UI 상태와 1:1로 일치 | 권한 재시도, 시스템 설정 이동 후 복귀, 권한 철회 후 재진입 | 권한 안내 문구 누락, 제한 모드 UI 미구현 |
| Idle detection | 앱이 monitoring 상태이고 lastInputAt이 설정되어 있다 | idle threshold 시간이 지난다 | one-shot timer 기준으로 alerting이 시작되고 threshold 오차는 ±1초 이내여야 한다 | `macos-core` | unit + integration | threshold accuracy ±1초 | 입력 폭주, multi-monitor, sleep/wake 직후 baseline 재설정 | polling timer 사용, 입력 이벤트 누락 |
| Alert escalation | idle alert가 시작되었다 | 추가 무입력 시간이 경과한다 | perimeter pulse -> strongVisualNudge -> ttsNudge 순서로 에스컬레이션된다 | `content-strategist` + `macos-core` | integration + snapshot | 단계 순서 100% 일치 | TTS 장치 없음, Reduce Motion on, 동일 세션 반복 알림 | escalation 순서 미정, TTS 종료 처리 없음 |
| Whitelist | Pro가 활성화되어 있고 frontmost app bundleIdentifier가 whitelist에 포함된다 | 전면 앱이 whitelist 상태가 된다 | alerting이 중단되고 pausedWhitelist로 전환된다 | `macos-core` + `data-architect` | integration | whitelist pause 진입/해제 정확도 100% | app switch 폭주, frontmost app 조회 실패, whitelist 앱 종료 | bundleIdentifier 미사용, 예외 처리 미구현 |
| Break mode | 사용자가 수동 휴식 모드를 켠다 | break mode가 활성화된다 | 모든 alert가 중단되고 pausedManual 상태가 유지된다 | `swiftui-designer` + `macos-core` | UI + integration | break 진입 후 alert 0건 | lock/unlock 중 break 전환, whitelist와 동시 요청, 복귀 직후 cooldown | manual pause 상태 정의 누락 |
| Stats | FocusSession이 종료되었다 | 일일 집계가 계산된다 | DailyStats는 session aggregate 기반으로 계산되고 raw input은 저장되지 않는다 | `data-architect` + `qa-integrator` | unit + data integrity | 집계 결과가 session 총합과 일치 | 자정 경계, multiple sessions per day, break excluded 조건 | 파생 집계 규칙 불일치, raw input 저장 |
| Pet | PetState와 reward rule이 연결되어 있다 | streak, recovery, level up 이벤트가 발생한다 | pet 성장/감정 상태가 docs와 일치하고 과도한 시각 방해가 없다 | `content-strategist` + `visual-designer` | snapshot + UX review | 성장 단계/감정 상태 매핑 100% 일치 | Reduce Motion on, low-resolution menu bar, stage unlock 직후 회복 | 감정 상태 불일치, 메뉴바 과점유 |
| CloudKit/iOS | Pro entitlement가 있고 iCloud가 사용 가능하다 | macOS 상태 전이가 발생한다 | best-effort near real-time sync가 outbox/coalescing 규칙대로 업로드되고 iOS는 launch/foreground delta fetch를 수행한다 | `cloudkit-sync` | integration + mocked network | 마지막 state 수렴 100% | offline-to-online 복구, push missing, partial save failure, Pro 미구매 | heartbeat write, public DB 사용, entitlement/iCloud 혼동 |
| Privacy disclosure | 사용자가 onboarding/privacy 섹션을 본다 | 권한 설명과 데이터 설명을 확인한다 | Accessibility 이유, 수집/미수집 데이터, CloudKit 조건이 앱/웹/문서 간에 의미상 일치한다 | `localization` + `macos-core` | copy review + UI snapshot | KR/EN 문구 parity 100% | 긴 EN copy, App Store 문구 축약, FAQ와 onboarding 불일치 | 고지 문구 누락, 과장된 데이터 주장 |
| Localization gate | launch-scope 문자열이 존재한다 | KR/EN 번역과 렌더링을 확인한다 | missing key 0, hardcoded user-facing string 0, truncation critical issue 0이어야 한다 | `localization` + `qa-integrator` | localization QA + screenshot | 누락 키 0, truncation 0 | plural variation, TTS locale mismatch, metadata locale drift | .xcstrings 누락, placeholder 노출, 웹/앱 용어 불일치 |

## 3. Release Gate Rules

- 위 표의 각 항목은 `blocked` 여부를 개별 판단하되, permission, idle detection, privacy disclosure, localization gate는 launch blocker로 우선 처리한다.
- `CloudKit/iOS`는 Pro 기능이므로 beta에서는 mocked network 기준으로 검증하고, release에서는 실제 iCloud 계정과 outbox 복구까지 확인한다.
- `Pet`과 `Stats`는 핵심 동작을 깨지 않으면 release blocker가 아니지만, 데이터 정합성 실패가 있으면 즉시 blocker로 격상한다.

## 4. Evidence Requirements

- UI 흐름은 스크린샷 또는 녹화로 남긴다.
- 타이밍 관련 항목은 측정 로그나 XCTest assertion을 남긴다.
- CloudKit 항목은 network mock 결과와 실제 iCloud 경로를 분리 기록한다.
- localization 항목은 KR/EN 각각의 핵심 화면 스크린샷과 누락 키 점검 결과를 남긴다.

## 5. Owner Handoff

- `macos-core`: 권한, idle, whitelist, break 관련 상태 전이
- `data-architect`: stats, whitelist 식별자, pet 및 CloudKit 메타데이터
- `content-strategist`: alert copy, pet reaction, escalation 문구
- `visual-designer`: pet visual, icon, motion review
- `cloudkit-sync`: macOS/iOS sync and recovery
- `localization`: KR/EN parity, key coverage, disclosure copy
- `qa-integrator`: final sign-off, regression triage, release report
