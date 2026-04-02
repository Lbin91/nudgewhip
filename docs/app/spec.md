# Nudge Product & Technical Spec vNext

- Version: vNext (draft-1)
- Last Updated: 2026-04-02
- Supersedes: 초기 PRD 초안

## 1. Product Definition

- Product Name: Nudge (넛지)
- Category: `attention recall tool`
- One-liner: 딴짓을 막는 앱이 아니라, 딴짓이 시작된 순간 다시 돌아오게 하는 앱
- Core Value: 사용자 입력이 멈춘 오프라인 이탈 순간을 감지해 부드럽게 작업 복귀를 유도
- Tone: 죄책감 유발 금지, 짧고 명확한 개입, 프라이버시 우선

## 2. Primary User

- Primary Persona: Mac + iPhone을 함께 사용하는 지식노동자 (개발자, 디자이너, 창업자, 작가)
- Secondary Persona: 시험 준비/학습 사용자
- Core Problem: 책상 앞에서 입력이 멈춘 상태가 길어져 집중이 깨지는 문제

## 3. Scope and Release Plan

### 3.1 Phase 1 (macOS Free Open Beta)

- Menu bar app (`LSUIElement = YES`)
- Accessibility 권한 온보딩 + 제한 모드
- 전역 입력 기반 idle detection
- 기본 시각 넛지 (`perimeter pulse`)
- 기본 일일 요약 통계
- 한국어/영어 동시 지원 (핵심 UI + 핵심 알림)

### 3.2 Phase 2 (Pro Launch)

- iOS companion 연동 (CloudKit 기반 상태 전이 알림)
- 수동 휴식 모드
- 화이트리스트 (frontmost `bundleIdentifier` 기반)
- 상세 통계 대시보드
- 펫 성장 시스템

## 4. Free/Pro Packaging

- Free: Mac 단일 기기 복귀 루프
- Pro: Mac + iPhone 복귀 루프 + 예외 처리 + 누적 보상
- Free included: 고정 임계시간 프리셋, 기본 시각 알림, 기본 일일 카운트
- Pro included: iOS 연동, 커스텀 임계시간, 휴식 모드, 화이트리스트, 상세 통계, 펫 성장
- Pricing: `$8.99~$9.99`는 가설 가격. 웹 waitlist fake-door 테스트 후 확정

## 5. Runtime State Model

### 5.1 Runtime States

- `limitedNoAX`: Accessibility 미허용 제한 모드
- `monitoring`: 정상 모니터링
- `pausedManual`: 사용자가 수동 휴식 모드 활성화
- `pausedWhitelist`: 전면 활성 앱이 화이트리스트에 포함
- `alerting`: 알림 단계 진행 중
- `suspendedSleepOrLock`: sleep/lock/user switching으로 일시 중단

### 5.2 Content States

- `Focus`
- `IdleDetected`
- `GentleNudge`
- `StrongNudge`
- `Recovery`
- `Break`
- `RemoteEscalation` (Pro)

### 5.3 State Priority

- `suspendedSleepOrLock` > `limitedNoAX` > `pausedManual` > `pausedWhitelist` > `alerting` > `monitoring`
- `limitedNoAX`는 capability gate이자 우선순위 체인에 포함된다. 권한 없음이 monitoring보다 항상 우선한다.

## 6. Idle Detection and Alert Rules

### 6.1 Input Detection

- Source events: `mouseMoved`, `mouseDown`, `scrollWheel`, `keyDown`
- Event handler rule: `lastInputAt` 갱신 외 무거운 연산 금지
- Idle timer rule: polling이 아닌 one-shot deadline timer 기반

### 6.2 Escalation

- Step 1: 임계시간 도달 시 `perimeter pulse` 1차 넛지
- Step 2: 45~60초 추가 무입력 시 강한 시각 넛지
- Step 3: 60~90초 추가 무입력 시 짧은 TTS 1회
- Step 4: 장기 미복귀 시 iOS `RemoteEscalation` (Pro, best-effort)

### 6.3 Fatigue Guardrails

- 시간당 최대 알림 횟수 제한
- 시간당 TTS 최대 횟수 제한
- 복귀 직후 cooldown 적용
- 동일 문구 연속 반복 금지 창 적용
- 반복 오탐 시 휴식 모드 제안

### 6.4 Out of Scope for MVP

- 브라우저 도메인 단위 화이트리스트 (YouTube/Netflix 탭 인식)
- 일반화된 fullscreen heuristic 자동 판정

## 7. UI/UX and Visual System

### 7.1 Menu Bar IA

- Top: 현재 상태 + 남은 시간/카운트다운
- Middle: 빠른 제어 (임계시간, 휴식, TTS on/off)
- Bottom: 펫 요약 + 오늘 요약 통계
- 상세 설정/상세 통계/펫 상세는 별도 창으로 분리

### 7.2 Icon and Overlay Rules

- 앱 아이콘과 메뉴바 아이콘 분리
- 메뉴바 최소 상태 아이콘: 활성, 휴식, 알림, 권한 필요
- 펫은 메뉴바 직접 노출보다 드롭다운/상세 화면 중심
- 기본 시각 알림은 `perimeter pulse`, `grayscale`은 고강도 옵션

### 7.3 Accessibility

- Text contrast 4.5:1 이상
- Core UI contrast 3:1 이상
- 상태 전달 시 색상만으로 구분 금지
- 초당 3회 초과 깜빡임 금지
- `Reduce Motion`, `Increase Contrast`, `Differentiate Without Color` 대응

## 8. Data and Persistence

### 8.1 Source of Truth

- Local `SwiftData`를 source of truth로 사용
- `UserDefaults`는 device-local UI/운영 플래그만 저장

### 8.2 MVP Models

- `UserSettings`
- `WhitelistApp`
- `FocusSession`
- `DailyStats`
- `PetState`

### 8.3 Data Rules

- `DailyStats`는 `FocusSession` 기반 파생 집계
- 화이트리스트 식별자는 앱 이름이 아닌 `bundleIdentifier`
- 집중 시간 합산 조건: `monitoringActive && !breakMode && !whitelistedPause`
- Raw input event는 저장하지 않고 시각/횟수/지속시간만 저장
- Enum은 raw string 저장, 신규 필드는 optional/default 우선

## 9. CloudKit and iOS Companion

### 9.1 Positioning

- iOS 연동은 실시간 보장 채널이 아닌 상태 전이 기반 보조 채널
- “즉각적 푸시” 대신 `best-effort near real-time` 기준 사용

### 9.2 Sync Shape

- CloudKit Private DB + custom zone `NudgeSync`
- Core record: `MacState(macDeviceID)`
- Core fields: `state`, `stateChangedAt`, `sequence`, `breakUntil`, `sourceDeviceID`, `lastAlertAt` (선택), `schemaVersion`

### 9.3 Write and Fetch Policy

- Write trigger: `idle 진입`, `alert 발생`, `복귀`, `break 시작`, `break 종료`
- macOS: local outbox 선기록 후 온라인 복구 시 최신 상태 coalesce 업로드
- iOS: push 수신 여부와 무관하게 launch/foreground 시 delta fetch 수행

### 9.4 Account and Entitlement

- iCloud 계정 조건과 App Store 구매 계정 조건을 분리해 취급
- 구매 entitlement source of truth는 StoreKit
- CloudKit은 entitlement 저장소가 아니라 동기화 운반 계층

## 10. Localization and Language Strategy

### 10.1 Initial Language Support

- 초기 지원 언어: 한국어(`ko`), 영어(`en`)
- 범위: macOS 핵심 UI, iOS 핵심 UI, 권한 안내, 알림/TTS 핵심 문구, 업그레이드 문구, 웹 핵심 랜딩/프라이버시 카피
- Locale behavior: 시스템 언어가 `ko/en`이면 해당 언어 표시, 미지원 언어는 영어 fallback

### 10.2 Localization System Contract

- 앱 문자열 단일 소스: `String Catalog (.xcstrings)`
- 신규 `Localizable.strings` 추가 금지
- 하드코딩 사용자 노출 문자열 금지
- Key naming: `{domain}.{surface}.{intent}`
- 모든 key에 번역 문맥 `comment` 필수
- 수량형은 String Catalog variation으로 처리

### 10.3 Copy Ownership

- 앱 마이크로카피/알림 슬롯 원문: `content-strategist`
- 마케팅/웹 원문: `marketing-strategist`
- 번역 검수/용어집/키 거버넌스: `localization`
- 앱/웹 공통 용어집 운영 (제품 카테고리, 프라이버시 문구, Free/Pro 명칭)

### 10.4 UI and QA for KR/EN

- KR/EN 모두 2줄 래핑 허용 가능한 레이아웃 기본
- 고정 폭 CTA 버튼 금지
- 누락 번역 fallback placeholder 노출 금지
- QA gate: 누락 key 0, 하드코딩 문자열 0, truncation 0, KR/EN 스크린샷 검증, 앱/웹 용어 일치

### 10.5 New Language Expansion Workflow

- Step 1: 언어 추가 제안 + 비즈니스 우선순위 승인
- Step 2: 범위 고정 (앱/웹/마케팅 포함 범위 정의)
- Step 3: 용어집 업데이트 + 키 coverage 점검
- Step 4: 번역/리뷰/문맥 검수
- Step 5: 레이아웃/접근성/스크린샷 QA
- Step 6: 릴리즈 게이트 통과 후 언어 활성화

## 11. Privacy and Trust

- 입력 내용(키 입력 텍스트) 저장/전송 금지
- 화면 캡처/스크린 내용 수집 금지
- 기본 감지 기능은 로컬 우선 동작
- CloudKit은 iOS 연동 기능 사용 시에만 상태 동기화에 활용
- 권한 거부 시 가능한 기능과 제한 기능을 UI에서 명확히 고지

## 12. QA and Acceptance Criteria

### 12.1 Timing SLAs

- 임계시간 도달 오차: ±1초
- 사용자 입력 복귀 후 알림 해제: 500ms 이내
- 상태 아이콘 반영: 1초 이내

### 12.2 Testability Requirements

- DI points: `Clock`, `EventMonitor`, `PermissionProvider`, `FrontmostAppProvider`, `SpeechSynthesizer`, `CloudKitClient`
- 필수 시나리오: AX 허용/거부/재시도, sleep/wake, lock/unlock, whitelist 전환, 입력 폭주, 오디오 부재, 다중 모니터, 오프라인 복구, iOS 미실행/알림 비허용

## 13. Launch Web Presence

- KPI: 방문 대비 waitlist 전환율, GitHub 클릭률, 출시 알림 구독 수
- CTA 분리: `Waitlist`, `GitHub`, `iPhone 알림 소식 받기`
- Waitlist 최소 필드: 이메일 + 관심사 1개
- 관심사 세그먼트: macOS 출시, iOS 연동 관심, 오픈소스 업데이트
- Web IA: Hero -> 문제/차별점 -> 동작 방식 -> 프라이버시/권한 -> Free/Pro 비교 -> Waitlist -> FAQ
- SEO/OGP baseline: title/description template, canonical, FAQ schema, 1200x630 OGP 이미지
- 웹도 초기 `ko/en` 동시 운영을 원칙으로 시작

## 14. Open-Core Policy

- 공개 후보: idle detection 엔진, 기본 macOS 셸, 기본 알림 로직
- 비공개: iOS 연동, CloudKit 동기화 구현, 프리미엄 예외 규칙, 브랜드/캐릭터 자산
- 라이선스/상표 정책은 별도 문서에서 확정

## 15. Explicit Non-Goals (vNext)

- 브라우저 탭/도메인 단위 자동 예외 인식
- 감정 분석, 키스트로크 의미 분석, 화면 콘텐츠 분석
- 다국어 3개 이상 동시 런칭

## 16. Open Questions

- TTS 기본값을 on으로 둘지 opt-in으로 둘지
- `activate(ignoringOtherApps:)` 기반 강제 포커스 획득 허용 여부
- 상세 통계와 펫 성장의 Free/Pro 경계 세분화
- `Mac-only` 사용자용 Pro 가치 제안
- 애니메이션 포맷을 SwiftUI native로 고정할지 Lottie 병행할지
- 지역별 가격/얼리버드 정책 확정 시점

