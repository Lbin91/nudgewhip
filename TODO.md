# Nudge Code Implementation TODO

- Last Updated: 2026-04-03
- Goal: 남은 **코드 구현 작업**만 우선순위 순서대로 정리
- Current Delivery Rule:
  - 기능 하나 구현
  - `xcodebuild test` / `xcodebuild build` 검증
  - 성공 시 커밋
  - 다음 기능 진행

## Completed Baseline

- [x] 템플릿 `Item.swift` 제거 및 실제 도메인 모델 구조 전환
- [x] SwiftData 기반 모델/컨테이너/기본 시드 구성
- [x] 런타임 상태 골격(`PermissionManager`, `IdleMonitor`, `RuntimeStateController`) 구현
- [x] 실제 입력 이벤트(`mouseMoved`, `mouseDown`, `scrollWheel`, `keyDown`) 연결
- [x] 제한 모드 권한 CTA / 설정 이동 흐름 구현
- [x] 메뉴바 상태 기반 드롭다운 UI 구성
- [x] 최초 실행 온보딩(권한 + 기본 설정) 구현

## Phase 1 Remaining Code Work

### A. Core Runtime Completion

- [ ] `nudge/Services/FrontmostAppProvider.swift` 작성
- [ ] 이벤트 핸들러에서 `lastInputAt` 갱신 외 무거운 작업 금지 구조를 더 강하게 분리
- [ ] sleep/wake 처리 추가
- [ ] lock/unlock 처리 추가
- [ ] fast user switching 처리 추가
- [ ] 상태 아이콘 반영 1초 이내 목표 검증 및 필요 시 구조 보정

### B. Alert System MVP

- [ ] `nudge/Services/AlertManager.swift` 작성
- [ ] `perimeterPulse` 1차 시각 넛지 구현
- [ ] `strongVisualNudge` 2차 시각 넛지 구현
- [ ] `ttsNudge` 3차 알림 구현
- [ ] TTS 큐 중첩 금지 구현
- [ ] 복귀 시 TTS 즉시 cancel 구현
- [ ] 시간당 최대 알림 횟수 제한 구현
- [ ] 시간당 TTS 최대 횟수 제한 구현
- [ ] 복귀 직후 cooldown 구현
- [ ] 동일 문구 연속 반복 금지 창 구현
- [ ] `RemoteEscalation` 비활성 유지 가드 구현
- [ ] 반복 오탐 시 `breakSuggestion` 노출 구현
- [ ] Free에서 `breakSuggestion -> pausedManual` 직접 진입 금지 가드
- [ ] Free용 민감도 조정 / 알림 완화 / 도움말 안내 흐름 구현
- [ ] `Reduce Motion`, `Increase Contrast`, `Differentiate Without Color` 대응

### C. Menu Bar / First-run UX Completion

- [ ] 온보딩 완료 후 메뉴바 시작 CTA 동작 polish
- [ ] 메뉴/설정에서 온보딩 재오픈 UX polish
- [ ] 제한 모드/권한 복구 UX polish
- [ ] 온보딩 전체 UI 테스트 안정화

### D. Free Visual / Pet Layer

- [ ] `sprout` 고정 펫 vs 미니멀 모드 선택 구조를 실제 UI/상태와 연결
- [ ] Free 감정 상태를 `happy`, `cheer`, `sleep`만 사용하도록 가드
- [ ] `StrongNudge`에서 Free는 `concern` 대신 `cheer(active)` 사용 가드
- [ ] 펫이 메뉴바를 과점유하지 않도록 노출 규칙 조정
- [ ] 미니멀 모드 추상형 시각 넛지 구현
- [ ] 펫 레이어 완전 비활성 옵션 결정 및 구현

### E. Localization / Copy Runtime

- [ ] TTS 핵심 문구 locale 매핑 구현
- [ ] 온보딩 / 메뉴바 / 알림 신규 문자열의 `.xcstrings` 정리 및 stale key 정리

### F. Free Stats / Summary Completion

- [ ] 기본 일일 통계 집계 완성
- [ ] 총 집중 시간 집계 완성
- [ ] 알림 발생 횟수 집계 완성
- [ ] 최대 연속 집중 시간 집계 완성
- [ ] 일일 요약 카드 완성도 향상
- [ ] 자정 경계 처리 검증/보정
- [ ] break/whitelist 구간 제외 집계 검증/보정

## Phase 2 Code Backlog

### G. Pro Controls

- [ ] manual break mode 구현
- [ ] `pausedManual` 상태 UI/로직 연결
- [ ] whitelist UI 및 저장 모델 연결
- [ ] `frontmostApplication.bundleIdentifier` 기반 whitelist pause 구현
- [ ] 이름 기반이 아닌 bundle identifier 기반 강제
- [ ] custom idle threshold 구현

### H. Detailed Stats / Gamification

- [ ] XP 계산 규칙 구현
- [ ] streak 계산 규칙 구현
- [ ] recovery bonus 규칙 구현
- [ ] pet 성장 단계 `sprout -> buddy -> guide` 구현
- [ ] Pro 전용 `concern` 감정 상태 연결
- [ ] 펫 상세 화면 구현
- [ ] 상세 통계 화면 구현
- [ ] reward deterministic 보장
- [ ] anti-gaming rule 구현

### I. CloudKit / iOS Gating

- [ ] `nudge/Shared/Services/CloudKitManager.swift` 작성
- [ ] Private DB + `NudgeSync` zone 계약 반영
- [ ] `MacState` record shape 구현
- [ ] outbox 저장 구조 구현
- [ ] same-state coalescing 구현
- [ ] write trigger를 상태 전이 시점으로 제한
- [ ] heartbeat write 금지
- [ ] iCloud 로그인 상태와 Pro entitlement 분리
- [ ] local-only fallback 구현
- [ ] `RemoteEscalation` 사용자 가시 알림 기준 설계
- [ ] silent push 단독 의존 금지
- [ ] launch/foreground delta fetch 경로 구현

### J. Pro Packaging Surfaces

- [ ] Free vs Pro 기능 경계 UI 반영
- [ ] 업그레이드 CTA 문구 반영
- [ ] Pro 기능 잠금 상태 UI 구현
- [ ] 실시간 보장처럼 보이는 표현 제거

## Testing / Verification Backlog

### K. Infrastructure

- [ ] `Clock` injectable 구현 및 테스트 추가
- [x] `EventMonitor` injectable 구현 및 테스트 추가
- [x] `PermissionProvider` injectable 구현 및 테스트 추가
- [ ] `FrontmostAppProvider` injectable 구현 및 테스트 추가
- [ ] `SpeechSynthesizer` injectable 구현 및 테스트 추가
- [ ] `CloudKitClient` injectable 구현 및 테스트 추가

### L. Behavior Tests

- [ ] idle threshold accuracy 테스트 작성
- [ ] alert recovery latency 테스트 작성
- [ ] permission 허용/거부/재시도 테스트 작성
- [ ] sleep/wake, lock/unlock, whitelist 전환 테스트 작성
- [ ] outbox/coalescing 테스트 작성
- [ ] stats 파생 집계 테스트 작성
- [ ] XP/streak deterministic 테스트 작성

### M. UI / Localization QA

- [ ] KR 메뉴바 핵심 화면 스크린샷 검증
- [ ] EN 메뉴바 핵심 화면 스크린샷 검증
- [ ] KR/EN truncation 0 달성
- [ ] App/웹 용어집 일치 검증
- [ ] TTS locale mismatch 0 검증
- [ ] privacy wording mismatch 0 검증
- [ ] App Store metadata drift 0 검증
- [ ] user-facing hardcoded strings 0 검증

## Current Next Slice

- [ ] sleep/wake, lock/unlock, fast user switching 처리 추가
- [ ] `perimeterPulse` 최소 구현으로 Free 루프 첫 시각 넛지 완성
