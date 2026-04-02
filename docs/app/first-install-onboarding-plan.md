# First-install Onboarding Plan

- Version: 0.1
- Last Updated: 2026-04-03
- Owner: `swiftui-designer` + `macos-core` + `localization`
- Scope: macOS first-run onboarding and initial permission/setup flow for Nudge Phase 1

## 1. Purpose

- 메뉴바 앱 특성상 최초 실행 시 사용자가 “어디서 시작해야 하는지”를 놓치지 않게 한다.
- Accessibility 권한의 필요성과 데이터 경계(무엇을 수집하지 않는지)를 먼저 설명한다.
- Free Phase 1 기본 루프를 시작하는 데 필요한 최소 설정만 받고 빠르게 실제 사용 상태로 진입시킨다.
- 권한을 거부해도 앱이 깨지지 않고 `limitedNoAX` 제한 모드로 계속 동작하게 한다.

## 2. Why this is needed

현재 구조에서는 사용자가 앱을 실행한 뒤 메뉴바 아이콘을 직접 열어 권한 요청 경로를 찾아야 한다.  
이 방식은 아래 문제를 만든다.

- 메뉴바 앱이라 메인 창이 없어 진입 경로가 불명확하다.
- Accessibility 권한이 필요한 이유를 사용자가 충분히 이해하기 전에 이탈할 수 있다.
- 권한을 거부했을 때 “앱이 고장 난 것처럼” 느껴질 수 있다.
- 최초 기본 설정(`idle threshold`, `TTS`, `visual mode`)이 정리되지 않아 기본 경험이 불안정하다.

따라서 최초 설치 시점에는 별도 온보딩 흐름이 필요하다.

## 3. Product goals

최초 설치 온보딩은 아래 5가지를 달성해야 한다.

1. 제품 가치와 사용 맥락을 1~2 화면 안에 이해시킨다.
2. Accessibility 권한 요청 전에 신뢰/프라이버시 메시지를 먼저 전달한다.
3. Phase 1 실행에 필요한 최소 설정만 수집한다.
4. 권한 허용/거부 어느 경로에서도 사용 가능한 종료 상태를 만든다.
5. 다음 실행부터는 동일 플로우를 반복하지 않는다.

## 4. Non-goals for MVP

최초 설치 온보딩에서 아래 항목은 다루지 않는다.

- whitelist 앱 설정
- Pro 업그레이드/결제 유도
- CloudKit / iCloud / iOS 연동 설정
- 상세 통계 및 게이미피케이션 설정
- 세부 알림 강도/에스컬레이션 튜닝
- break mode 고급 정책
- 시스템 알림(UNUserNotificationCenter) 권한 요청 (자체 커스텀 오버레이 UI를 사용하므로 온보딩에서 의도적으로 생략함)

## 5. First-run information architecture

MVP는 **최대 4화면**으로 제한한다.

### Screen 1 — Welcome

목적:
- Nudge가 어떤 앱인지 즉시 이해시킨다.

표시 내용:
- 제품명
- 한 줄 설명
  - 예: “무입력 상태를 감지하고 부드럽게 집중 복귀를 돕는 메뉴바 앱”
- 신뢰 메시지 요약
  - 키 입력 내용 수집 안 함
  - 화면 내용/스크린 캡처 수집 안 함
- Primary CTA: `시작하기`

### Screen 2 — Accessibility Permission

목적:
- 권한이 필요한 이유와 거부 시 동작을 명확히 설명한다.

표시 내용:
- 권한 필요 이유
  - 전역 입력 활동 감지를 위해 필요
- 데이터 비수집 고지
  - 키 입력 내용, 화면 내용, 파일, 메시지, 브라우징 기록 수집 안 함
- 현재 권한 상태 badge
- Primary CTA: `권한 요청`
- Secondary CTA: `설정 열기`
- Tertiary CTA: `나중에 설정`

행동 결과:
- 허용됨 → 다음 화면으로 진행
- 거부됨 → 다음 화면으로 진행하되 `limitedNoAX` 경로로 분기

### Screen 3 — Basic Setup

목적:
- Phase 1 기본 루프에 필요한 최소 설정만 고르게 한다.

수집할 항목:
- Idle threshold
  - `3분`, `5분(추천)`, `10분`
- 시작 시 로그인 자동 실행 (Launch on Login)
  - `켜기(추천)` / `끄기`
- TTS
  - `켜기` / `끄기`
- Visual mode
  - `sprout`
  - `minimal`

설계 원칙:
- 고급 옵션은 숨긴다.
- 한 화면에서 제어 수가 많아질 경우 `Idle threshold + Launch on Login`을 1차 그룹, `TTS + Visual mode`를 2차 그룹으로 시각적으로 분리한다.
- 한 화면에서 “결정해야 하는 질문 수”는 4개를 넘기지 않는다.
- 기본값은 즉시 usable 해야 한다.

### Screen 4 — Completion

권한 허용/거부에 따라 2가지 버전이 필요하다.

#### 4.1 Granted variant

표시 내용:
- `모니터링 준비 완료`
- 선택한 threshold / TTS / visual mode 요약
- Primary CTA: `메뉴바에서 시작`

종료 상태:
- 앱은 `monitoring` 진입 준비 상태여야 한다.

#### 4.2 Denied variant

표시 내용:
- `제한 모드로 시작`
- 무엇이 제한되는지 설명
  - 백그라운드 전역 키보드/마우스 입력 감지가 불가능함
  - 따라서 무입력 감지와 자동 복귀 루프는 완전하게 동작하지 않음
- Primary CTA: `메뉴바에서 계속`
- Secondary CTA: `권한 다시 설정`

종료 상태:
- 앱은 `limitedNoAX` 상태를 명확히 노출해야 한다.

## 6. What to collect on first install

최초 설치에서 저장할 설정:

- `UserSettings.idleThresholdSeconds`
- `UserSettings.ttsEnabled`
- `UserSettings.petPresentationMode`

기기 로컬 플래그(`UserDefaults`)로 저장할 값:

- onboarding completed 여부
- 마지막으로 본 onboarding 버전
- launch at login 선택값 (`SMAppService` 상태와 동일한 device-local flag)

최초 설치에서 저장하지 않을 값:

- whitelist 목록
- CloudKit preference
- custom alert cadence
- Pro entitlement 관련 사용자 선택

## 7. Copy and disclosure rules

온보딩 권한 화면의 문구는 아래 문서와 의미가 일치해야 한다.

- `docs/privacy/accessibility-and-data-disclosure.md`
- `docs/app/spec.md`
- `docs/localization/glossary.md`

필수 원칙:

- KR/EN 의미 parity 유지
- 사용자 비난 톤 금지
- “실시간 보장”, “감시”, “추적” 같은 과장/위협 표현 금지
- 권한 거부 시에도 앱이 계속 실행됨을 명시
- 고지 문구는 `String Catalog (.xcstrings)` 단일 소스로 관리
- onboarding 권한 문구는 `docs/privacy/accessibility-and-data-disclosure.md`의 의미를 축약하되 새로운 주장(수집/전송/추적)을 추가하지 않는다.

## 8. UX rules

- 최대 4단계
- 각 화면은 primary action 1개 중심으로 설계
- 고정 폭 CTA 버튼 사용 금지
- KR/EN 모두 2줄 래핑 허용
- 제한 모드도 실패가 아니라 “부분 기능 사용 상태”로 표현
- 온보딩 종료 후에도 메뉴/설정에서 다시 열 수 있어야 함
- 각 step에서 이전 화면으로 돌아갈 수 있는 back 액션을 제공한다.
- 온보딩 창 닫기(Cmd+W/Esc) 시: Welcome 단계면 limitedNoAX로 진입, Basic Setup 이후면 저장된 draft 유지
- 다크모드/Appearance에 관계없이 카드, 배경, 그림자가 가독성을 유지해야 한다.
- 키보드 Tab/Enter 네비게이션과 VoiceOver를 지원한다.
- 앱이 시스템 설정에서 foreground로 복귀하면 권한 상태를 즉시 재검사해야 한다.

## 9. Trigger and resume rules

온보딩은 아래 조건에서 표시한다.

- 앱 첫 실행이며 onboarding completed가 false
- 온보딩 버전이 현재 앱의 required onboarding version보다 낮음
- 사용자가 메뉴/설정에서 “온보딩 다시 보기”를 명시적으로 선택함

온보딩은 아래 조건에서는 표시하지 않는다.

- 단순 앱 재실행이며 completed/version 조건이 충족됨
- 제한 모드 사용자이지만 이미 온보딩을 완료했고 별도 재오픈 요청이 없음

중도 이탈/재진입 규칙:

- 사용자가 `나중에 설정`으로 종료하면 completed는 true로 처리하되 최종 상태는 `limitedNoAX`로 남긴다.
- 시스템 설정 앱으로 이동했다가 돌아오면 permission step에서 즉시 상태를 갱신한다.
- 앱이 강제 종료되더라도 이미 저장된 basic setup 값은 재입력하지 않도록 유지한다.
- 사용자가 온보딩 창을 닫으면(Cmd+W/Esc): 아무 설정도 저장하지 않은 Welcome 단계면 limitedNoAX로 진입하고, Basic Setup 이후면 이미 입력한 draft 값을 보존해 다음 실행에서 이어서 진행할 수 있게 한다.

## 10. State expectations

온보딩 완료 시 상태 기대값:

- Granted path
  - `runtimeState = monitoring`
  - `lastInputAt` baseline 준비
  - idle countdown 시작 가능

- Denied path
  - `runtimeState = limitedNoAX`
  - 제한 모드 UI 노출
  - 설정 복귀 후 재검사 가능

## 11. Acceptance Criteria

- 최초 실행이고 AX 권한이 없으면 메뉴 탐색 전에 온보딩이 먼저 보인다.
- 권한 허용/거부 어느 경우든 온보딩을 완료할 수 있다.
- 권한 허용 시 monitoring 준비 상태로 진입한다.
- 권한 거부 시 limited mode 안내와 복구 경로가 보인다.
- `idle threshold`, `launch at login`, `TTS`, `visual mode`가 저장되고 다음 실행에 유지된다.
- KR/EN 모두 문구가 disclosure 문서와 의미상 일치한다.
- 다음 실행에서는 onboarding completed 플래그에 따라 반복 노출되지 않는다.
- launch at login은 SwiftData가 아니라 device-local 설정 계층으로 저장된다.
- 각 step에서 이전 화면으로 돌아가는 back 네비게이션이 동작한다.
- 온보딩 창 닫기(Cmd+W/Esc) 시 정의된 동작(limitedNoAX 진입 또는 draft 보존)이 수행된다.
- 다크모드/Appearance에서 모든 화면이 가독성을 유지한다.
- 키보드 네비게이션(Tab/Enter)과 VoiceOver가 온보딩 전체 흐름에서 동작한다.

## 12. Recommended implementation order

1. `UserDefaults` 기반 onboarding completion/version flag 추가
2. 온보딩 전용 container 및 step state 추가
3. Permission screen에 기존 `PermissionManager` 흐름 재사용
4. Basic setup 화면에서 `UserSettings` 저장 연결 (`idle threshold`, `TTS`, `visual mode`)
5. launch at login은 `SMAppService` + device-local flag로 별도 연결
6. granted / denied completion 분기 추가
7. 메뉴/설정에서 onboarding 재오픈 경로 추가 (예: 메뉴바 드롭다운 하단 "도움말" 섹션에 "초기 설정 다시" 메뉴 아이템)
8. KR/EN 로컬라이제이션 반영
9. UI / permission flow 테스트 추가

## 13. Verification plan

Unit:
- onboarding completed flag 저장/복원
- initial setting persistence
- permission state refresh after returning from Settings
- launch at login device-local persistence
- onboarding version bump 시 재표시 조건

UI:
- fresh install granted path
- fresh install denied path
- open-settings and return path
- skip / set-up-later path
- re-open onboarding path

Localization:
- KR/EN screenshot review
- truncation critical issue 0
- placeholder key exposure 0

Manual:
- 새 설치 → 권한 거부 → 제한 모드 진입 확인
- 설정 앱에서 권한 허용 후 앱 복귀 → 상태 재검사 확인
- launch at login on/off 설정 후 재부팅 또는 로그인 재진입 시 반영 확인

## 14. Known constraints / notes

- Phase 1은 자체 커스텀 오버레이 넛지를 사용하므로 `UNUserNotificationCenter` 권한 요청은 온보딩에서 제외한다.
- `launch at login`은 사용자 기기별 동작이므로 SwiftData source of truth에 넣지 않고 device-local 설정으로 관리해야 한다.
- Input Monitoring 권한은 현재 표준 경로의 필수 권한으로 가정하지 않는다. 실제 macOS 정책/배포 방식에서 필요성이 확인될 때만 별도 검토한다.
- `LSUIElement = YES` 환경에서 전용 온보딩 윈도우를 띄울 때 Dock에 임시로 아이콘이 나타날 수 있다. `NSPanel` 또는 floating 레벨 윈도우를 검토해 이 사이드 이펙트를 최소화해야 한다.

## 15. Open questions

- 최초 온보딩을 full-screen window로 띄울지, 작은 setup window로 띄울지
- 완료 화면에서 “메뉴바에서 시작” CTA가 실제로 어떤 행동을 해야 하는지
- onboarding을 다시 여는 진입점을 메뉴바에 둘지 설정 화면에 둘지
- 최초 기본값을 `5분 / 자동실행 on / TTS on / sprout`로 확정할지 여부
- `나중에 설정`을 눌렀을 때 completion으로 볼지, reminder 배지를 남길지 여부
