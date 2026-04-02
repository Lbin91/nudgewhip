# Nudge PRD 구체화 회의록

- 일시: 2026-04-02
- 방식: 역할별 서브에이전트 9명 병렬 검토 후 합의안 통합
- 대상 문서: `docs/app/spec.md`

## 참석자

- `data-architect`
- `macos-core`
- `swiftui-designer`
- `cloudkit-sync`
- `qa-integrator`
- `marketing-strategist`
- `content-strategist`
- `visual-designer`
- `web-dev`

## 회의 목적

- 현재 PRD를 기능 목록 수준에서 구현 가능한 spec vNext 수준으로 구체화한다.
- MVP/Pro 경계, 상태 머신, 데이터 모델, 알림 규칙, CloudKit 제약, 출시 전략을 한 문서 기준으로 정렬한다.

## 현재 PRD 진단

- 기능은 정의되어 있지만 상태 전이와 우선순위가 없다.
- `UserDefaults`와 `SwiftData`의 역할 경계가 없다.
- `무입력 = 딴짓` 가정의 오탐을 줄일 예외 규칙과 guardrail이 없다.
- iOS 연동이 “즉각적 푸시”처럼 표현되어 있으나 CloudKit의 실제 동작 특성과 맞지 않는다.
- Free/Pro 패키징과 Open-core 범위가 기능 나열 수준에 머물러 있다.
- 메뉴바 UI, 펫, 통계, 권한 UX가 한 흐름으로 정리되지 않았다.
- 프라이버시 메시지와 웹/런칭 요구사항이 빠져 있다.
- QA 관점의 수용 기준과 측정 가능한 성공 지표가 없다.

## 역할별 핵심 발언 요약

- `data-architect`: 로컬 `SwiftData`를 source of truth로 고정하고 `DailyStats`는 `FocusSession` 기반 파생 집계로 두는 편이 안정적이다.
- `macos-core`: MVP 화이트리스트는 브라우저 도메인 단위가 아니라 `frontmost bundleIdentifier` 기반 예외까지만 허용해야 구현 리스크를 통제할 수 있다.
- `swiftui-designer`: `MenuBarExtra`는 현재 상태와 빠른 제어만 담고, 상세 통계와 설정은 별도 창으로 분리해야 한다.
- `cloudkit-sync`: iOS 푸시는 보장형이 아니라 `best-effort near real-time`로 내려야 하며, 구매 entitlement와 iCloud 동기화 조건은 분리해야 한다.
- `qa-integrator`: idle 판정, 알림 해제, 동기화, 권한 거부를 모두 Given/When/Then과 시간 기준으로 측정 가능하게 써야 한다.
- `marketing-strategist`: 1차 페르소나는 `Mac+iPhone`을 함께 쓰는 지식노동자로 좁히고, 제품 포지셔닝을 `attention recall tool`로 고정해야 한다.
- `content-strategist`: PRD에는 대사 풀 대신 `알림 taxonomy`, `escalation rule`, `fatigue guardrail`을 넣는 것이 맞다.
- `visual-designer`: 메뉴바 상태 아이콘과 펫 자산은 분리하고, 시맨틱 컬러와 접근성 기준을 먼저 잠가야 한다.
- `web-dev`: 런칭 웹은 `Waitlist`, `GitHub`, `iOS 관심 등록`을 분리한 CTA와 강한 프라이버시 메시지가 필요하다.

## 합의된 Spec 확장안

### 1. 제품 정의와 포지셔닝

- 1차 페르소나는 `Mac+iPhone을 함께 쓰고 책상 앞 오프라인 딴짓이 잦은 개발자, 디자이너, 창업자, 작가형 지식노동자`로 고정한다.
- 제품 카테고리는 `차단 앱`이나 `시간 추적 앱`이 아니라 `attention recall tool`로 정의한다.
- 핵심 메시지는 `딴짓을 막는 앱이 아니라, 딴짓이 시작된 순간 다시 돌아오게 하는 앱`으로 정리한다.
- 톤은 `죄책감 유발 금지`, `부드러운 개입`, `프라이버시 우선`으로 고정한다.
- 제품 정체성은 `진지한 생산성 코어 + 선택 가능한 소프트 펫 레이어` 조합으로 정리한다.

### 2. 릴리즈 슬라이스와 수익화

- `Phase 1 / macOS Free Open Beta`: 메뉴바 앱, Accessibility 온보딩, idle detection, perimeter pulse 기반 기본 알림, 일일 스냅샷 통계.
- `Phase 2 / Pro Launch`: iOS 컴패니언 연동, 수동 휴식 모드, bundle ID 기반 화이트리스트, 상세 통계, 펫 성장 시스템.
- Free는 `Mac 단일 복귀 루프`, Pro는 `Mac+iPhone 복귀 루프 + 예외 처리 + 누적 보상`으로 패키징한다.
- Free 기본 범위는 `고정 임계시간`, `기본 시각 알림`, `기본 일일 카운트`까지만 둔다.
- Pro 범위는 `iOS 연동`, `커스텀 임계시간`, `휴식 모드`, `화이트리스트`, `상세 통계`, `펫 성장`으로 묶는다.
- Open-core는 `idle detection 엔진`, `기본 macOS 셸`, `기본 알림 로직`까지만 공개 후보로 본다.
- 비공개 영역은 `iOS 연동`, `CloudKit 동기화`, `프리미엄 예외 규칙`, `브랜드/캐릭터 자산`으로 둔다.
- 가격은 아직 확정하지 않는다. 현재 `$8.99~$9.99`는 가설로 유지하되, 웹 fake door와 대기자 명단으로 3안 테스트를 돌린 뒤 확정한다.

### 3. 상태 머신과 idle 판정 규칙

- 런타임 상태는 `limitedNoAX`, `monitoring`, `pausedManual`, `pausedWhitelist`, `alerting`, `suspendedSleepOrLock`으로 고정한다.
- 콘텐츠 상태는 `Focus`, `IdleDetected`, `GentleNudge`, `StrongNudge`, `Recovery`, `Break`, `RemoteEscalation`으로 정리한다.
- 글로벌 입력 감지는 `mouseMoved`, `mouseDown`, `scrollWheel`, `keyDown` 수준으로 제한하고, 핸들러는 `lastInputAt` 갱신만 수행한다.
- idle 판정은 polling 대신 `마지막 입력 시각 + 임계값` 기반 one-shot timer로 설계한다.
- `sleep/wake`, `screen lock`, `fast user switching` 시에는 idle 시간을 누적하지 않고 baseline을 재설정한다.
- 화이트리스트는 MVP에서 `frontmostApplication.bundleIdentifier` 기반 예외만 허용한다.
- 브라우저 도메인 단위 예외, YouTube/Netflix 탭 탐지, 일반 fullscreen heuristic은 후속 검증 항목으로 미룬다.
- `무입력 = 딴짓` 오탐을 줄이기 위해 휴식 모드와 whitelist pause는 통계상 별도 이벤트로 본다.

### 4. 알림 전략, 캐릭터, 게이미피케이션

- 기본 알림 흐름은 `무입력 임계 도달 -> 1차 perimeter pulse -> 45~60초 추가 무입력 시 강한 시각 넛지 -> 60~90초 추가 지속 시 짧은 TTS 1회 -> 장기 미복귀 시 iOS RemoteEscalation`으로 둔다.
- `Grayscale`은 기본 경험이 아니라 고강도 실험 옵션으로 분리한다.
- TTS는 짧은 1문장, 언어 자동 매칭, 큐 중첩 금지, 입력 복귀 즉시 중지 규칙을 따른다.
- 피로도 방지를 위해 `시간당 최대 알림 횟수`, `TTS 최대 횟수`, `복귀 후 쿨다운`, `같은 대사 재사용 금지 창`, `반복 오경보 시 break 제안`을 PRD에 넣는다.
- 캐릭터는 `감시자`가 아니라 `작업 메이트` 콘셉트로 고정한다.
- PRD에는 캐릭터 이름이나 lore 대신 `다정함`, `비난 금지`, `복귀 즉시 칭찬`, `짧은 관찰형 문장`만 고정한다.
- dialogue system은 `집중 시작`, `1차 경고`, `반복 이탈`, `복귀`, `휴식 승인`, `연속 집중`, `레벨업` 슬롯만 PRD에 정의하고 실제 대사 풀은 후속 문서로 뺀다.
- 게이미피케이션은 `집중 분 -> XP`, `무알림 세션 -> streak`, `복귀 성공 -> 즉시 긍정 피드백`, `일일 요약 -> 성장 반영` 수준까지만 PRD에 명시한다.

### 5. 데이터 모델과 로컬 저장 원칙

- 로컬 `SwiftData`를 source of truth로 둔다.
- `UserDefaults`는 device-local UI/운영 플래그만 저장한다.
- MVP 영속 모델 최소 집합은 `UserSettings`, `WhitelistApp`, `FocusSession`, `DailyStats`, `PetState`로 잡는다.
- `DailyStats`는 원천 데이터가 아니라 `FocusSession`에서 계산되는 파생 집계로 둔다.
- 화이트리스트 식별자는 앱 이름이 아니라 `bundleIdentifier`를 공식 키로 사용한다.
- 집중 시간은 `monitoringActive && !breakMode && !whitelistedPause` 구간만 합산한다.
- raw input event는 저장하지 않고 `timestamp`, `duration`, `count` 중심으로만 저장한다.
- enum은 raw string으로 저장하고, 신규 필드는 optional/default 우선 정책을 사용한다.
- 휴식 이력을 통계에 강하게 반영할 필요가 생기면 `BreakSession`을 후속 엔티티로 추가 검토한다.

### 6. CloudKit 및 iOS 연동 원칙

- iOS 연동은 서버리스 sync가 아니라 `상태 전이 기반 알림 보조 채널`로 정의한다.
- PRD의 “즉각적 푸시” 표현은 `best-effort near real-time`로 낮춘다.
- CloudKit Private Database에 custom zone `NudgeSync`를 두고 `MacState(macDeviceID)` 레코드를 기본 단위로 삼는다.
- 기본 필드는 `state`, `stateChangedAt`, `sequence`, `breakUntil`, `sourceDeviceID`로 제한한다.
- CloudKit write는 heartbeat가 아니라 `idle 진입`, `alert 발생`, `복귀`, `break 시작`, `break 종료` 같은 상태 전이 시점에만 수행한다.
- iOS 사용자 체감용 푸시는 `alerting`이 일정 시간 지속된 뒤의 `RemoteEscalation` 단계에서만 발송하는 쪽으로 정리한다.
- macOS는 로컬 outbox에 먼저 적재하고 온라인 복구 시 최신 상태만 coalesce 후 업로드한다.
- iOS는 push 수신 여부와 무관하게 launch/foreground 시 delta fetch를 수행한다.
- 구매 entitlement의 진실 원천은 StoreKit으로 두고, CloudKit은 sync 운반층으로만 사용한다.
- `같은 Apple ID`는 iCloud sync 조건일 뿐이며, App Store 구매 계정과 분리해서 서술한다.

### 7. 메뉴바 UX, 비주얼 시스템, 접근성

- `MenuBarExtra` IA는 `현재 상태 + 카운트다운`, `빠른 제어`, `펫/오늘 요약` 3구역으로 제한한다.
- 상세 설정, 상세 통계, 펫 성장 상세 화면은 별도 창으로 분리한다.
- 앱 아이콘과 메뉴바 아이콘은 분리한다.
- 메뉴바 아이콘은 단색 템플릿 기반으로 `활성`, `휴식`, `알림`, `권한 필요` 4개 최소 상태를 제공한다.
- 펫은 기본적으로 드롭다운과 오버레이 자산으로 쓰고 메뉴바에는 1색 실루엣 또는 배지 수준으로만 노출한다.
- 펫 스펙은 MVP에서 `3 성장 단계 x 4 감정 상태(행복/슬픔/응원/잠)` 정도로 제한한다.
- 시맨틱 컬러 토큰 `focus`, `rest`, `alert`, `surface`, `accent`를 PRD에 추가한다.
- 경고용 red는 브랜드 대표색과 분리한다.
- 시각 알림 기본값은 `perimeter pulse` 1종으로 고정하고, 표시 범위는 `현재 활성 디스플레이` 기준으로 시작한다.
- 접근성 기준은 `텍스트 4.5:1`, `핵심 UI 3:1`, `색만으로 상태 전달 금지`, `3회/초 초과 깜빡임 금지`, `Reduce Motion/Increase Contrast/Differentiate Without Color` 대응으로 둔다.
- 에셋 파이프라인은 `SVG master -> PDF export`를 기본으로 두고, Lottie 채택 여부는 구현 결정 후 별도 확정한다.

### 8. QA 수용 기준과 테스트 가능성

- PRD의 핵심 기능은 모두 Given/When/Then 형태 수용 기준을 가진다.
- 기본 시간 기준은 `idle 임계 도달 오차 ±1초`, `입력 복귀 후 500ms 이내 알림 해제`, `상태 아이콘 반영 1초 이내`로 둔다.
- 테스트용 의존성 주입 포인트는 `Clock`, `EventMonitor`, `PermissionProvider`, `FrontmostAppProvider`, `SpeechSynthesizer`, `CloudKitClient`를 기본 세트로 정의한다.
- 필수 테스트 매트릭스에는 `AX 허용/거부/재시도`, `sleep/wake`, `screen lock`, `whitelist 전환`, `입력 폭주`, `오디오 부재`, `다중 모니터`, `동기화 오프라인 복구`, `iOS 알림 비허용`, `iOS 미실행 상태`를 포함한다.
- 통계와 펫 성장 규칙은 측정 가능한 수식과 리셋 조건을 가져야 한다.

### 9. Launch Web Presence 요구사항

- PRD에 웹 전용 섹션을 추가한다.
- 웹 1차 KPI는 `방문 -> 대기자 전환율`, `GitHub 클릭률`, `출시 알림 구독 수`로 둔다.
- CTA는 `Waitlist`, `GitHub`, `iPhone 알림 소식 받기`로 분리한다.
- 대기자 폼은 `이메일 + 관심사 1개` 최소 필드로 시작한다.
- 관심사 세그먼트는 최소 `macOS 출시`, `iOS 연동 관심`, `오픈소스 업데이트`를 둔다.
- 웹 IA는 `Hero -> 문제/차별점 -> 동작 방식 -> 프라이버시/권한 -> Free/Pro 비교 -> Waitlist -> FAQ` 초안으로 잡는다.
- 프라이버시 메시지에는 `키 입력 내용 저장 안 함`, `화면 캡처 안 함`, `기본 기능은 서버 비의존`, `CloudKit은 iOS 연동 시 사용`을 명시한다.
- SEO/OGP 최소 요구사항으로 `title/description 템플릿`, `1200x630 OGP 이미지`, `canonical`, `FAQ schema`, `국문 우선 + 영문 병행 가능성`을 기록한다.

## 미결정 항목

- TTS를 기본 프리셋에서 켤지, opt-in으로 둘지.
- `activate(ignoringOtherApps:)`로 포커스를 강제로 가져오는 알림을 허용할지.
- `상세 통계`와 `펫 성장`을 전부 Pro로 둘지, 일부 요약을 Free에 남길지.
- `Mac only` 사용자에게 별도 Pro 가치 제안을 둘지.
- 애니메이션 구현을 `SwiftUI native`로 고정할지, `Lottie`를 채택할지.
- 런칭 시점에 한국어 단일 운영으로 갈지, 영문 병행까지 포함할지.
- 지역별 가격 정책과 얼리버드 정책을 어떻게 둘지.

## 액션 아이템

1. `data-architect`는 `UserSettings`, `WhitelistApp`, `FocusSession`, `DailyStats`, `PetState` 초안 스키마를 문서화한다.
2. `macos-core`는 상태 머신, 권한 상태, sleep/wake 처리, whitelist 범위를 반영한 구현 계약을 정리한다.
3. `content-strategist`와 `visual-designer`는 알림 단계별 감정/표정/카피 슬롯 명세를 공동 작성한다.
4. `swiftui-designer`는 `MenuBarExtra` IA와 별도 상세 창 구조를 와이어프레임 수준으로 구체화한다.
5. `cloudkit-sync`는 custom zone, record shape, Pro entitlement 분리 원칙을 반영한 sync 설계 메모를 만든다.
6. `marketing-strategist`와 `web-dev`는 페르소나, CTA, 프라이버시 카피를 반영한 런칭 메시지 구조를 정리한다.
7. `qa-integrator`는 수용 기준과 테스트 매트릭스를 `_workspace/qa_report.md` 형식 초안으로 변환한다.
8. 회의 합의안을 바탕으로 `docs/app/spec.md`를 `vNext` 구조로 재작성한다.

## 결론

- 이번 회의의 핵심 결론은 `기능 추가`보다 `판정 규칙 고정`이 먼저라는 점이다.
- 다음 버전의 PRD는 `상태 머신`, `데이터 경계`, `알림 escalation`, `CloudKit 현실 제약`, `패키징/런칭 구조`를 중심으로 다시 써야 한다.
- 현재 문서는 방향성 문서로는 충분하지만, 구현 문서로 쓰기에는 아직 모호성이 크다. 본 회의록을 `spec.md vNext`의 편집 기준으로 사용한다.
