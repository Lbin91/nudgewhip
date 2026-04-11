# Activity Measurement Feasibility on macOS

- Version: 0.1
- Last Updated: 2026-04-12
- Owner: `macos-core` + `product`
- Purpose: NudgeWhip가 macOS에서 실제로 측정 가능한 사용자 활동 범위를 현재 구현 기준과 플랫폼 제약 기준으로 정리

## 1. 결론 요약

NudgeWhip는 오늘 기준으로 이미 다음 범위를 안정적으로 측정할 수 있다.

- 전역 입력 활동 발생 여부와 마지막 입력 시각
- idle 진입, alert 시작/복귀, cooldown 등 집중 세션 전이
- 현재 전면 활성 앱의 `bundleIdentifier`
- sleep/wake, 화면 잠금/해제, fast user switching 같은 시스템 lifecycle 전이

추가 확장도 가능하다. 다만 수준별로 성격이 다르다.

- 앱 수준 측정: 현실적이고 안정적이다. 예: `Terminal`, `iTerm2`, `Xcode`, `Safari`가 전면에 있었던 시간
- 창/탭 수준 측정: 부분적으로 가능하지만 앱별 편차가 크다. 예: 창 제목, 브라우저 URL 속성, 포커스된 UI 요소 제목
- 프로세스 내부 도구 수준 측정: 일반화는 어렵다. 예: `Terminal` 안에서 `codex`, `claude`, `opencode`를 썼는지

핵심 판단은 아래와 같다.

- "어떤 앱을 쓰며 집중했는가"는 충분히 제품화 가능하다.
- "터미널 앱 안에서 어떤 CLI 도구를 썼는가"는 일부 앱에서는 가능하지만, 공통 macOS API만으로 안정적으로 일반화되지는 않는다.
- "Codex/Claude Code/OpenCode 사용량"은 장기적으로는 스크래핑보다 shell integration 또는 공식 연동이 더 정확하고 프라이버시 측면에서도 낫다.

## 2. 현재 코드베이스가 이미 측정하는 것

현재 구현은 이미 activity 측정의 기본 뼈대를 갖고 있다.

- 전역 입력 활동: `SystemEventMonitor`가 `NSEvent.addGlobalMonitorForEvents`와 `addLocalMonitorForEvents`로 마우스/키보드 이벤트를 감시한다.
- 전면 활성 앱: `FrontmostAppProvider`가 `NSWorkspace.frontmostApplication`과 `NSWorkspace.didActivateApplicationNotification`으로 frontmost app 변화를 받는다.
- 세션 전이 기록: `IdleMonitor`와 `SessionTracker`가 idle 진입, alert 시작, recovery, manual pause, whitelist pause를 세션 단위로 저장한다.
- 시스템 상태 전이: `SystemLifecycleMonitor`가 sleep/wake, session active 전환, screen lock/unlock을 반영한다.

현재 저장/계산 가능한 데이터는 사실상 다음과 같다.

- 마지막 입력 시각
- idle threshold 도달 시각
- alert escalation 단계와 횟수
- 복귀 횟수
- focus session 시작/종료 시각
- 화이트리스트로 pause된 여부
- 현재 frontmost app의 bundle identifier 기반 pause 여부

즉, "집중 중 어느 앱이 전면에 있었는지"를 붙이기 위한 기본 이벤트 스트림은 이미 있다.

## 3. 측정 가능 범위 매트릭스

| 질문 | 실현 가능성 | 주 수단 | 권한/조건 | 메모 |
| --- | --- | --- | --- | --- |
| 사용자가 지금 입력 중인가 | 높음 | 글로벌 NSEvent monitor | Accessibility | 현재 구현됨 |
| 사용자가 idle 상태에 들어갔는가 | 높음 | idle deadline 계산 | Accessibility | 현재 구현됨 |
| 지금 어떤 앱이 전면 활성인가 | 높음 | `NSWorkspace.frontmostApplication` | 기본 권한 | 현재 구현 일부 존재 |
| 집중 시간 동안 앱별 사용 시간 집계 | 높음 | frontmost app change + 세션 겹침 계산 | 기본 권한 + AX는 idle용 | 제품화 현실적 |
| 전면 앱의 이름/번들 ID/PID 저장 | 높음 | `NSRunningApplication` | 기본 권한 | 앱 레벨 측정의 핵심 |
| 전면 창 제목 저장 | 중간 | `CGWindowListCopyWindowInfo` 또는 AX | 앱별 편차 | 일부 앱은 제목이 비거나 의미가 약함 |
| 포커스된 UI 요소 제목/URL 읽기 | 중간 | AX UI tree | Accessibility | 브라우저/앱 지원 편차 큼 |
| Terminal 선택 탭의 실행 프로세스 목록 읽기 | 중간~높음 | Terminal AppleScript dictionary | Automation/Apple Events | Terminal 한정 |
| iTerm2 현재 foreground job 이름/명령줄 읽기 | 중간~높음 | iTerm2 scripting surface | iTerm2 설치 + 앱별 통합 | iTerm2 한정 |
| 모든 터미널/에디터에서 Codex/Claude/OpenCode를 일반적으로 탐지 | 낮음 | 공통 API 부재 | 앱별 통합 또는 shell integration 필요 | 일반화 어려움 |
| 백그라운드 앱 내부 사용량까지 정확히 측정 | 낮음 | 공통 API 부재 | 별도 통합 필요 | frontmost 중심이 현실적 |

## 4. 안정적으로 가능한 범위

### 4.1 앱 수준 사용량

이 범위는 가장 현실적이다.

NudgeWhip는 이미 frontmost app 변화를 받을 수 있으므로, focus session과 겹치는 시간 구간에 대해 다음과 같은 집계를 만들 수 있다.

- 앱별 집중 시간
- 앱별 active transition 횟수
- focus session 중 가장 오래 사용한 앱
- productive app group과 distracting app group 비중
- `Terminal`/`iTerm2`/`Cursor`/`Safari` 등 상위 앱 랭킹

실무적으로는 다음 데이터만 추가 저장하면 된다.

- `bundleIdentifier`
- `localizedName`
- `processIdentifier`
- 활성 시작 시각
- 비활성 전환 시각
- 해당 구간이 focus session과 얼마나 겹쳤는지

이건 현재 아키텍처와도 잘 맞는다. `FrontmostAppProvider` 이벤트를 `IdleMonitor` 또는 별도 usage tracker로 흘려 보내면 된다.

### 4.2 시스템 상태와 함께 해석한 사용량

현재 lifecycle 이벤트도 받고 있으므로 아래 해석이 가능하다.

- 화면 잠금이나 수면으로 끊긴 세션 제외
- 수동 휴식 중 사용량 제외
- 화이트리스트 앱 활성 동안 pause된 구간 제외
- schedule pause 구간 제외

즉 단순한 "총 앱 사용 시간"보다, NudgeWhip가 정의하는 "집중 모드 안에서의 앱 사용 시간"으로 해석할 수 있다.

## 5. 조건부로 가능한 범위

### 5.1 창 제목 기반 추정

Core Graphics window list는 창 소유 PID, 앱 이름, 창 이름을 일부 제공한다. 그래서 다음 같은 추정은 가능하다.

- 현재 창 제목이 `claude-code - repo-name`
- 현재 브라우저 탭 제목이 `OpenAI API Docs`
- 현재 Terminal 창 제목이 `codex`

하지만 창 제목은 다음 문제가 있다.

- 앱마다 title 정책이 다르다.
- 사용자가 title format을 바꿀 수 있다.
- 빈 제목인 경우가 있다.
- 동일 앱이라도 문맥 신뢰도가 낮다.

따라서 창 제목은 보조 힌트로는 쓸 수 있지만, 핵심 측정 소스로 쓰면 안 된다.

### 5.2 Accessibility UI tree 기반 추정

AX API로 frontmost app의 focused window, focused UI element, title, URL 같은 속성을 읽는 접근은 가능하다. 이 방식은 다음 같은 확장이 가능하다.

- 브라우저에서 현재 문서/페이지 제목 읽기
- 일부 앱에서 현재 선택 항목 제목 읽기
- 일부 웹뷰/문서 앱에서 URL 읽기

하지만 AX는 지원 편차가 크고 실패 가능성도 명확하다.

- 모든 앱이 같은 속성을 제공하지 않는다.
- `AXUIElementCopyAttributeValue`는 attribute unsupported, no value, not implemented 같은 에러를 반환할 수 있다.
- 브라우저 URL이나 탭 정보는 앱별 구조가 달라 일반화가 어렵다.

그래서 AX는 "지원하는 앱에 한해 메타데이터 힌트 확보" 정도로 보는 것이 맞다.

## 6. 터미널 내부 도구 감지의 현실

### 6.1 공통 macOS API만으로는 일반화가 어렵다

`Terminal`이나 `iTerm2`가 전면 앱이라는 사실은 쉽게 알 수 있다. 하지만 그 안에서 실제로 foreground job이 `codex`인지 `claude`인지 `opencode`인지는 공통 API만으로 안정적으로 알기 어렵다.

걸림돌은 다음과 같다.

- Terminal emulator마다 세션 모델이 다르다.
- `tmux`, `ssh`, `mosh`, shell wrapper를 거치면 실제 foreground job 해석이 더 어려워진다.
- 같은 도구도 `bash -lc`, wrapper script, npm shim, uvx, login shell 아래에서 다른 프로세스 이름으로 보일 수 있다.
- 백그라운드 pane이나 비선택 탭의 상태까지 일반화하면 난도가 크게 올라간다.

즉 "전면 terminal app 사용 시간"은 쉽지만, "그 안에서 정확히 어떤 AI coding tool을 썼는지"는 공통 기반만으로는 약하다.

### 6.2 Terminal.app은 앱 전용 통합으로 어느 정도 가능하다

로컬 `Terminal.app`의 scripting dictionary에는 다음 읽기 속성이 있다.

- `selected tab`
- `tab.processes`
- `tab.tty`
- `tab.busy`
- `tab.contents`
- `tab.history`

이 의미는 중요하다.

- `processes`와 `tty`만 사용하면 현재 선택 탭에서 어떤 프로세스들이 돌고 있는지 추정할 수 있다.
- `codex`, `claude`, `opencode`, `python`, `node`, `ssh`, `tmux` 같은 이름을 앱별 통합으로 일부 잡을 수 있다.
- 반대로 `contents`나 `history`까지 읽는 것은 기술적으로 가능하더라도 NudgeWhip의 프라이버시 방향과 충돌하므로 금지하는 편이 맞다.

따라서 Terminal.app 한정 opt-in 통합은 가능하지만, 이건 "macOS 전체에서 일반적으로 가능한 측정"이 아니라 "Terminal용 특수 연동"이다.

### 6.3 iTerm2도 앱 전용 통합이면 더 좋은 신호를 줄 수 있다

iTerm2 문서에는 세션 변수로 다음 항목이 있다.

- `jobName`
- `commandLine`
- `jobPid`
- `tty`

이건 Terminal.app보다 더 직접적인 foreground job 신호가 될 수 있다. 다만 전제가 있다.

- iTerm2가 설치되어 있어야 한다.
- iTerm2의 scripting surface에 맞춘 전용 구현이 필요하다.
- shell integration 유무에 따라 일부 값 품질이 달라질 수 있다.

즉 iTerm2도 가능성은 높지만, 여전히 앱 전용 통합이다.

## 7. 실무적으로 불가능하거나 권장하지 않는 범위

다음은 현재 제품 방향과 macOS 제약을 기준으로 "하지 않는 것이 맞는 범위"다.

- 모든 앱의 내부 문맥을 공통 방식으로 읽기
- 모든 터미널에서 현재 command line을 보편적으로 복원하기
- screen content를 OCR/스크린샷 없이 이해하기
- 백그라운드 비가시 앱에서 실제 사용 중인 도구를 정확히 판별하기
- Terminal/tab `contents`나 `history`를 읽어 사용 내용을 분석하기

특히 마지막 항목은 기술적으로 가능한 앱도 있지만, 현재 NudgeWhip의 프라이버시 약속인 "키 입력 내용, 화면 내용, 파일, 메시지, 브라우징 기록 비수집"과 충돌할 가능성이 크다.

## 8. 권한, 배포, 심사 관점

### 8.1 지금 이미 필요한 권한

현재 idle detection 핵심은 Accessibility에 의존한다.

- 글로벌 key event는 Accessibility trust가 있어야 안정적으로 모니터링된다.
- 현재 코드도 `AXIsProcessTrusted`/`AXIsProcessTrustedWithOptions`를 사용한다.

### 8.2 Terminal/iTerm2 연동을 붙이면 추가 고려가 생긴다

Terminal.app이나 iTerm2를 Apple Events로 제어하거나 조회하려면 Automation 계열 권한/설정이 추가될 수 있다.

현재 프로젝트 상태는 다음과 같다.

- `GENERATE_INFOPLIST_FILE = YES`
- `INFOPLIST_KEY_NSAppleEventsUsageDescription` 미설정
- `ENABLE_APP_SANDBOX = NO`

따라서 Developer ID 배포 기준으로는 구현 여지가 있지만, Apple Events를 실제로 붙이려면 최소한 다음을 준비해야 한다.

- 사용자에게 왜 Terminal/iTerm2 자동화 접근이 필요한지 별도 고지
- `NSAppleEventsUsageDescription` 설정
- 향후 Mac App Store 배포를 고려한다면 sandbox + Apple Events entitlement 정책 재검토

즉 이 영역은 단순 기능 추가가 아니라 권한/배포 전략 결정까지 연결된다.

## 9. NudgeWhip에 권장하는 구현 순서

### Step 1. 앱 수준 usage tracking부터 제품화

먼저 이 범위를 권장한다.

- focus session 중 frontmost app 구간 기록
- 앱별 집중 시간 집계
- `Terminal`/`iTerm2`/`Cursor`/`Safari` 등 상위 앱 통계
- whitelist와 동일하게 `bundleIdentifier` 중심 설계 유지

이 단계는 현재 앱 방향과 가장 잘 맞고 프라이버시 부담도 낮다.

### Step 2. terminal app 전용 opt-in integration 실험

다음 단계로는 Terminal.app, iTerm2만 별도 지원하는 실험이 가능하다.

- 대상 앱이 frontmost일 때만 조회
- `processes`, `jobName`, `jobPid`, `tty`처럼 최소 신호만 사용
- `contents`, `history`, 화면 텍스트는 금지
- 사용자가 명시적으로 켰을 때만 동작

이 단계가 되면 "AI coding tools 사용 시간" 같은 통계를 일부 만들 수 있다.

단, 이 수치는 "지원되는 터미널 앱에서만 측정된 추정값"으로 표현해야 한다.

### Step 3. 장기적으로는 shell integration이 정답

`codex`, `claude`, `opencode`를 정확히 잡고 싶다면, 장기적으로는 shell integration이 더 적합하다.

예를 들면 다음 접근이다.

- shell prompt hook이 현재 foreground command의 시작/종료 이벤트를 NudgeWhip에 로컬 전송
- 특정 CLI 도구 wrapper가 시작/종료를 명시적으로 기록
- terminal emulator에 의존하지 않는 session metadata 프로토콜 사용

이 방식의 장점은 명확하다.

- Terminal/iTerm2/Kitty/Ghostty 등 여러 터미널에 더 잘 확장된다.
- 창 제목 스크래핑보다 정확하다.
- 수집 범위를 command name 등 최소 메타데이터로 제한하기 쉽다.
- 프라이버시 설명도 더 명확하게 설계할 수 있다.

## 10. 추천 제품 문구

현재 단계에서 사용자에게 약속 가능한 문구는 아래 수준이 적절하다.

- `NudgeWhip는 집중 세션 동안 어떤 앱이 전면에서 사용되었는지 측정할 수 있습니다.`
- `Terminal/iTerm2 같은 일부 앱에서는 선택적으로 현재 작업 도구를 더 자세히 식별할 수 있지만, 이 기능은 앱별 지원과 추가 권한에 따라 달라집니다.`
- `키 입력 내용, 화면 내용, 터미널 출력 본문은 수집하지 않습니다.`

반대로 아직 하면 안 되는 약속은 아래와 같다.

- `모든 앱 내부 활동을 정확히 측정합니다`
- `모든 터미널에서 Codex/Claude/OpenCode 사용을 자동 인식합니다`
- `브라우저/에디터 내부 문맥까지 일반적으로 추적합니다`

## 11. 구현 메모

현재 구조에서 가장 작은 확장 포인트는 다음과 같다.

- `FrontmostAppProvider`: frontmost app의 `bundleIdentifier` 외에 `localizedName`, `processIdentifier`까지 노출
- 새로운 `AppUsageTracker`: 앱 활성 구간 시작/종료 저장
- `FocusSession`과 겹치는 시간 계산용 usage segment 모델 추가
- 통계 대시보드에서 앱별 집중 시간 카드 제공

이건 idle core를 크게 흔들지 않고 붙일 수 있다.

## 12. 참고 근거

### Repo evidence

- `nudgewhip/Services/EventMonitor.swift`
- `nudgewhip/Services/FrontmostAppProvider.swift`
- `nudgewhip/Services/IdleMonitor.swift`
- `nudgewhip/Services/SystemLifecycleMonitor.swift`
- `docs/privacy/accessibility-and-data-disclosure.md`

### Apple / platform references

- AppKit `NSEvent` header: 글로벌 이벤트 모니터는 다른 앱 이벤트를 관찰만 가능하며, key-related event는 Accessibility trust가 있어야 함
- AppKit `NSWorkspace` / `NSRunningApplication`: frontmost app, localized name, bundle identifier, process identifier 제공
- HIServices `AXUIElement`: `AXIsProcessTrustedWithOptions`, `AXUIElementCopyAttributeValue`, `kAXFocusedUIElementAttribute`, `kAXTitleAttribute`, `kAXURLAttribute`
- CoreGraphics `CGWindowListCopyWindowInfo`: `kCGWindowOwnerPID`, `kCGWindowOwnerName`, `kCGWindowName`
- Apple docs: `NSAppleEventsUsageDescription`, Apple Events entitlement, App Sandbox automation restrictions

### App-specific references

- local `Terminal.app` scripting dictionary (`sdef /System/Applications/Utilities/Terminal.app`)
- iTerm2 variables documentation: current session `jobName`, `commandLine`, `jobPid`, `tty`
