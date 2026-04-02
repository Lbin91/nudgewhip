# Nudge Execution TODO

- Last Updated: 2026-04-02
- Goal: 문서 기준을 실제 제품 구현, 검증, 출시 준비 작업으로 변환
- Primary References:
  - `docs/app/spec.md`
  - `docs/architecture/state-machine-contract.md`
  - `docs/architecture/cloudkit-sync-contract.md`
  - `docs/content/*.md`
  - `docs/design/*.md`
  - `docs/localization/*.md`
  - `docs/privacy/accessibility-and-data-disclosure.md`
  - `docs/qa/*.md`
  - `docs/release/release-readiness-checklist.md`

## Current Reality

- [x] Xcode 템플릿 상태를 벗어나도록 placeholder 구조 제거
- [x] `nudge/Item.swift`를 실제 도메인 모델 구조로 교체
- [ ] `nudge/Services`, `nudge/Views`, `nudge/Shared` 디렉터리 생성
- [ ] 문서 기준 구현 우선순위를 코드 구조에 맞게 반영

## Phase 1: macOS Free Open Beta

### 1. Data Foundation

- [x] `nudge/Shared/Models/UserSettings.swift` 작성
- [x] `nudge/Shared/Models/WhitelistApp.swift` 작성
- [x] `nudge/Shared/Models/FocusSession.swift` 작성
- [x] `nudge/Shared/Models/DailyStats.swift` 작성
- [x] `nudge/Shared/Models/PetState.swift` 작성
- [x] SwiftData `ModelContainer` 초기화 구조 설계
- [x] local source of truth를 SwiftData로 고정
- [ ] `UserDefaults`는 device-local 플래그 전용으로 분리
- [x] enum raw string 저장 정책 반영
- [x] 신규 필드 optional/default 우선 정책 반영
- [x] `DailyStats`를 `FocusSession` 파생 집계로 구현
- [x] raw input event를 저장하지 않도록 저장 계층 가드 추가

### 2. Core Runtime and State Machine

- [x] `nudge/Services/PermissionManager.swift` 작성
- [x] `nudge/Services/IdleMonitor.swift` 작성
- [ ] `nudge/Services/FrontmostAppProvider.swift` 작성
- [x] `nudge/Services/RuntimeStateController.swift` 또는 동등 구조 작성
- [x] runtime state enum 구현: `limitedNoAX`, `monitoring`, `pausedManual`, `pausedWhitelist`, `alerting`, `suspendedSleepOrLock`
- [x] content state enum 구현: `Focus`, `IdleDetected`, `GentleNudge`, `StrongNudge`, `Recovery`, `Break`, `RemoteEscalation`
- [ ] `mouseMoved`, `mouseDown`, `scrollWheel`, `keyDown`만 입력 소스로 사용
- [ ] 이벤트 핸들러에서 `lastInputAt` 갱신 외 무거운 작업 금지
- [x] idle detection을 polling이 아닌 one-shot deadline timer 기반으로 구현
- [ ] sleep/wake, lock/unlock, fast user switching 처리 추가
- [ ] `accessibilityDenied`를 OS 이벤트가 아닌 재검사 기반 합성 이벤트로 처리
- [x] `limitedNoAX` 제한 모드에서 graceful degradation 구현
- [x] 상태 전환 로그/테스트 훅 추가

### 3. Alert System

- [ ] `nudge/Services/AlertManager.swift` 작성
- [ ] `perimeterPulse` 1차 시각 넛지 구현
- [ ] `strongVisualNudge` 2차 시각 넛지 구현
- [ ] `ttsNudge` 3차 알림 구현
- [ ] TTS 큐 중첩 금지 및 복귀 시 즉시 cancel 구현
- [ ] `RemoteEscalation`은 Phase 1에서 비활성 상태로 유지
- [ ] 시간당 최대 알림 횟수 제한 구현
- [ ] 시간당 TTS 최대 횟수 제한 구현
- [ ] 복귀 직후 cooldown 구현
- [ ] 동일 문구 연속 반복 금지 창 구현
- [ ] 반복 오탐 시 `breakSuggestion` 노출 구현
- [ ] Free에서는 `breakSuggestion`이 `pausedManual`로 직접 진입하지 않도록 가드
- [ ] Free에서는 민감도 조정/알림 강도 완화/도움말 안내 흐름 구현
- [ ] `Reduce Motion`, `Increase Contrast`, `Differentiate Without Color` 대응

### 4. Menu Bar UI

- [ ] `nudge/nudgeApp.swift`를 실제 `MenuBarExtra` 구조로 정리
- [x] `nudge/ContentView.swift` placeholder 제거
- [ ] `nudge/Views/MenuBarDropdownView.swift` 작성
- [ ] `nudge/Views/StatusSummaryView.swift` 작성
- [ ] `nudge/Views/QuickControlsView.swift` 작성
- [ ] `nudge/Views/DailySummaryView.swift` 작성
- [ ] 드롭다운 상단에 현재 상태 + 카운트다운 표시
- [ ] 중간 구역에 임계시간, TTS on/off, 기본 제어 배치
- [ ] 하단 구역에 오늘 요약 통계 표시
- [ ] 제한 모드 UI 표시
- [ ] 권한 요청 CTA와 설정 이동 흐름 구현
- [ ] 상태 변화에 따른 메뉴바 아이콘 반영
- [ ] 상태 아이콘 반영 1초 이내 목표 충족

### 5. Free Visual and Pet Layer

- [ ] Phase 1에서는 `sprout` 고정 펫 또는 미니멀 모드 중 선택 가능한 구조 설계
- [ ] Free 감정 상태를 `happy`, `cheer`, `sleep`만 사용하도록 가드
- [ ] `StrongNudge`에서 Free는 `concern` 대신 `cheer(active)`로 대체
- [ ] 펫이 메뉴바를 과점유하지 않도록 드롭다운 중심 노출 유지
- [ ] 미니멀 모드에서 추상형 시각 넛지 구현
- [ ] 펫 레이어를 완전히 끌 수 있는지 여부 결정 및 구현

### 6. Localization Foundation

- [ ] `nudge/Localizable.xcstrings` 생성
- [ ] launch-scope 문자열을 전부 `.xcstrings`로 외부화
- [ ] 하드코딩된 사용자 노출 문자열 제거
- [ ] key naming을 `domain.surface.intent`로 통일
- [ ] 모든 key에 comment 문맥 추가
- [ ] 한국어(`ko`) 번역 입력
- [ ] 영어(`en`) 번역 입력
- [ ] TTS 핵심 문구 locale 매핑 구현
- [ ] unsupported locale -> English fallback 구현
- [ ] placeholder/key name 노출 방지

### 7. Free Stats and Summary

- [ ] 기본 일일 통계 집계 구현
- [ ] 총 집중 시간 집계 구현
- [ ] 알림 발생 횟수 집계 구현
- [ ] 최대 연속 집중 시간 집계 구현
- [ ] 일일 요약 카드 UI 구현
- [ ] 자정 경계 처리 검증
- [ ] break/whitelist 구간 제외 집계 검증

## Phase 2: Pro Launch

### 8. Pro Controls

- [ ] manual break mode 구현
- [ ] `pausedManual` 상태 UI/로직 연결
- [ ] whitelist UI 및 저장 모델 연결
- [ ] `frontmostApplication.bundleIdentifier` 기반 whitelist pause 구현
- [ ] 이름 기반이 아닌 bundle identifier 기반임을 코드로 강제
- [ ] custom idle threshold 구현

### 9. Detailed Stats and Gamification

- [ ] XP 계산 규칙 구현
- [ ] streak 계산 규칙 구현
- [ ] recovery bonus 규칙 구현
- [ ] pet 성장 단계 `sprout -> buddy -> guide` 구현
- [ ] Pro 전용 `concern` 감정 에셋/상태 연결
- [ ] 펫 상세 화면 구현
- [ ] 상세 통계 화면 구현
- [ ] reward 계산 deterministic 보장
- [ ] anti-gaming rule 구현

### 10. CloudKit and iOS Gating

- [ ] `nudge/Shared/Services/CloudKitManager.swift` 작성
- [ ] Private DB + `NudgeSync` zone 계약 반영
- [ ] `MacState` record shape 구현
- [ ] outbox 저장 구조 구현
- [ ] same-state coalescing 구현
- [ ] write trigger를 상태 전이 시점으로 제한
- [ ] heartbeat write 금지
- [ ] iCloud 로그인 상태와 Pro entitlement 분리 구현
- [ ] local-only fallback 구현
- [ ] `RemoteEscalation`은 사용자 가시 알림 기준으로 설계
- [ ] silent push 단독 의존 금지
- [ ] launch/foreground delta fetch 경로 구현

### 11. Pro Packaging and Upgrade Surfaces

- [ ] Free vs Pro 기능 경계 UI 반영
- [ ] 업그레이드 CTA 문구 반영
- [ ] Pro 기능 잠금 상태 UI 구현
- [ ] 실시간 보장처럼 보이는 표현 제거
- [ ] pricing copy를 실제 판매 정책과 맞추기 전까지 가설 가격 문구로만 유지할지 결정

## Web and Marketing

### 12. Launch Website

- [ ] `docs/design/landing-mockup.md` 기준으로 웹 구현 시작
- [ ] `/ko`, `/en` locale route 구조 결정
- [ ] Hero, Problem, How It Works, Free/Pro, Privacy, Waitlist, FAQ 구현
- [ ] waitlist form 구현
- [ ] 관심사 3종 구현: `macOS 출시`, `iOS 연동`, `오픈소스 업데이트`
- [ ] GitHub CTA 연결
- [ ] iPhone 알림 소식 받기 CTA 연결
- [ ] canonical, hreflang, OGP locale 분리
- [ ] FAQ와 privacy copy를 앱 문구와 의미 일치시키기

### 13. Marketing Operations

- [ ] launch-plan 기준 채널별 운영 체크리스트 생성
- [ ] waitlist 운영 방식 확정
- [ ] beta 모집 채널별 카피 준비
- [ ] App Store short description / feature bullets 확정
- [ ] community post 템플릿 준비
- [ ] fake-door pricing test 여부 결정

## QA and Verification

### 14. Unit and Integration Tests

- [ ] `Clock` injectable 구현 및 테스트 추가
- [ ] `EventMonitor` injectable 구현 및 테스트 추가
- [ ] `PermissionProvider` injectable 구현 및 테스트 추가
- [ ] `FrontmostAppProvider` injectable 구현 및 테스트 추가
- [ ] `SpeechSynthesizer` injectable 구현 및 테스트 추가
- [ ] `CloudKitClient` injectable 구현 및 테스트 추가
- [ ] idle threshold accuracy 테스트 작성
- [ ] alert recovery latency 테스트 작성
- [ ] permission 허용/거부/재시도 테스트 작성
- [ ] sleep/wake, lock/unlock, whitelist 전환 테스트 작성
- [ ] outbox/coalescing 테스트 작성
- [ ] stats 파생 집계 테스트 작성
- [ ] XP/streak deterministic 테스트 작성

### 15. UI and Localization QA

- [ ] KR 메뉴바 핵심 화면 스크린샷 검증
- [ ] EN 메뉴바 핵심 화면 스크린샷 검증
- [ ] KR/EN truncation 0 목표 달성
- [ ] App/웹 용어집 일치 검증
- [ ] TTS locale mismatch 0 검증
- [ ] privacy wording mismatch 0 검증
- [ ] App Store metadata drift 0 검증
- [ ] user-facing hardcoded strings 0 검증

### 16. Acceptance and Release Gate

- [ ] `docs/qa/acceptance-matrix.md` 각 항목별 evidence 수집
- [ ] `docs/qa/localization-test-matrix.md` evidence 수집
- [ ] beta launch gate 체크
- [ ] Pro launch gate 체크
- [ ] rollback/fallback 경로 점검
- [ ] support owner 지정
- [ ] known issues / FAQ 준비

## Open-Core and Repo Hygiene

### 17. Repository Structure and Policy

- [ ] 공개 코드와 비공개 자산 경계 방식 결정
- [ ] `LICENSE` 초안 선택: `Apache-2.0` vs `MIT`
- [ ] `NOTICE` 필요 여부 판단
- [ ] `CONTRIBUTING.md` 추가 여부 결정
- [ ] `CODE_OF_CONDUCT.md` 추가 여부 결정
- [ ] brand/trademark 자산 분리 전략 결정

### 18. Project Cleanup

- [ ] `.DS_Store` 정리
- [ ] placeholder 파일 제거 후 실제 구조로 치환
- [ ] Xcode 사용자 상태 파일이 재추적되지 않도록 유지
- [ ] 불필요한 `docs/markerting` 오타 디렉터리 처리 여부 결정

## Immediate Next Slice

- [x] `Item.swift` 제거 및 `Shared/Models` 기본 구조 생성
- [x] `PermissionManager`, `IdleMonitor`, `RuntimeStateController` 스켈레톤 작성
- [ ] `Localizable.xcstrings` 생성 및 메뉴바 핵심 문자열 외부화
- [ ] `MenuBarExtra` 기본 드롭다운을 실제 상태 기반 UI로 교체
- [ ] idle detection + limitedNoAX + perimeter pulse까지 동작하는 최소 Free 루프 완성
