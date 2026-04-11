# Activity Measurement - 구현 설계

- Version: 0.1
- Last Updated: 2026-04-12
- Status: 설계 초안
- Source: `docs/app/activity-measurement-feasibility.md`

## 1. 목표

`docs/app/activity-measurement-feasibility.md`의 결론에 맞춰, NudgeWhip의 첫 번째 구현 범위는 앱 수준 activity measurement를 제품화하는 것이다.

이번 설계의 목표는 아래 세 가지다.

- focus session 동안 frontmost app 구간을 안정적으로 저장한다.
- 앱별 집중 시간, 전환 횟수, top apps 같은 파생 통계를 계산한다.
- 기존 idle core와 privacy contract를 흔들지 않고 작은 diff로 붙인다.

이번 단계에서 의도적으로 제외하는 범위는 아래와 같다.

- window title / AX UI tree / browser URL 수집
- Terminal/iTerm2 Apple Events 연동
- shell integration
- 키 입력 내용, 화면 내용, terminal contents/history 분석

즉, 이번 설계는 feasibility 문서의 `Step 1. 앱 수준 usage tracking부터 제품화`만 다룬다.

## 2. 현재 기준선

현재 코드베이스는 앱 수준 측정을 붙일 수 있는 최소 이벤트 스트림을 이미 갖고 있다.

- `FrontmostAppProvider`는 frontmost app 변화를 감시하지만 아직 `bundleIdentifier`만 외부에 노출한다. `currentBundleIdentifier`와 callback 시그니처가 모두 `String?` 기준이다. `nudgewhip/Services/FrontmostAppProvider.swift:5-49`
- `IdleMonitor`는 permission, lifecycle, frontmost app monitoring, whitelist pause, schedule pause, manual pause를 한곳에서 조정한다. 특히 frontmost app 변경은 이미 `updateWhitelistMatch(for:)`로 처리된다. `nudgewhip/Services/IdleMonitor.swift:24-30`, `nudgewhip/Services/IdleMonitor.swift:143-147`, `nudgewhip/Services/IdleMonitor.swift:540-553`
- `IdleMonitor`는 메뉴바 메뉴가 열린 동안 observed activity를 무시하는 guard를 갖고 있다. 이 non-regression 요구사항은 그대로 유지해야 한다. `nudgewhip/Services/IdleMonitor.swift:203-231`
- `SessionTracker`는 focus session과 alerting segment만 저장한다. per-app usage를 저장하는 구조는 아직 없다. `nudgewhip/Services/SessionTracker.swift:5-82`
- `FocusSession`은 alerting segment relationship은 있지만 app usage relationship은 없다. `nudgewhip/Shared/Models/FocusSession.swift:18-88`
- 현재 통계 계층은 `FocusSession` 배열만 읽어 `DailyStats`와 `StatisticsSnapshot`을 계산한다. 앱별 usage aggregation은 아직 존재하지 않는다. `nudgewhip/Services/MenuBarViewModel.swift:259-275`, `nudgewhip/Shared/Models/DailyStats.swift:9-183`
- 통계 UI도 focus, alerts, recovery, longest focus만 보여준다. app ranking surface는 아직 없다. `nudgewhip/Views/StatisticsDashboardView.swift:22-209`
- privacy disclosure는 keystroke content, screen contents, browsing history, file contents를 수집하지 않는다고 명시한다. 이 계약은 이번 설계의 hard constraint다. `docs/privacy/accessibility-and-data-disclosure.md:15-39`

## 3. 설계 결정

### 3.1 결정 요약

MVP는 `FrontmostAppSnapshot + AppUsageTracker + AppUsageSegment` 조합으로 구현한다.

- `FrontmostAppProvider`는 bundle id만이 아니라 localized name과 PID까지 포함한 snapshot을 제공한다.
- `IdleMonitor`는 계속 orchestration 역할을 맡고, usage tracking 자체는 별도 `AppUsageTracker`에 위임한다.
- `AppUsageTracker`는 현재 focus window 안에서만 app usage segment를 열고 닫는다.
- `AppUsageSegment`는 `FocusSession`의 child relationship으로 저장한다.
- 통계 집계는 기존 `DailyStats`를 무리하게 확장하기보다 별도 app usage aggregation 타입을 추가한다.

### 3.2 왜 이 구조인가

이 구조를 선택한 이유는 아래와 같다.

- feasibility 문서가 권장하는 첫 제품화 범위가 app-level usage이며, 이 범위는 `FrontmostAppProvider`와 `IdleMonitor`가 이미 가진 이벤트를 그대로 재사용할 수 있다. `docs/app/activity-measurement-feasibility.md:68-100`
- `SessionTracker`에 모든 책임을 몰아넣으면 세션/알림 기록과 app identity 관리가 결합된다. sidecar tracker가 더 작은 diff다.
- raw frontmost stream 전체를 별도 로그처럼 저장하는 방식도 가능하지만, 지금 제품이 필요한 것은 "집중 모드 안에서의 앱 사용량"이다. focus session child relationship이 더 직접적이고 privacy 설명도 쉽다.
- window/AX/terminal integration까지 한 번에 들어가면 권한과 배포 전략이 함께 바뀐다. MVP는 그 리스크를 피해야 한다. `docs/app/activity-measurement-feasibility.md:200-225`

### 3.3 이번 단계에서 하지 않는 결정

- `NSAppleEventsUsageDescription` 추가 없음
- Terminal/iTerm2 automation 없음
- app 내부 문맥 추정 없음
- background app usage 측정 없음
- menu presentation 중 `NudgeWhip` self-activation을 usage로 기록하지 않음

## 4. 데이터 모델 설계

### 4.1 FrontmostAppSnapshot

새 값 타입을 도입한다.

```swift
struct FrontmostAppSnapshot: Equatable, Sendable {
    let bundleIdentifier: String?
    let localizedName: String?
    let processIdentifier: pid_t?
}
```

역할은 단순하다.

- whitelist 판단에 필요한 `bundleIdentifier`
- UI/통계 표시에 필요한 `localizedName`
- 동일 bundle 다중 프로세스 식별과 future hints를 위한 `processIdentifier`

`FrontmostAppProviding`은 아래 형태로 확장한다.

- `var currentApp: FrontmostAppSnapshot?`
- `func start(onChange: @escaping @MainActor (FrontmostAppSnapshot?) -> Void)`

기존 `currentBundleIdentifier` 기반 호출부는 `currentApp?.bundleIdentifier`로 옮긴다.

### 4.2 AppUsageSegment

새 SwiftData 모델을 추가한다.

```swift
@Model
final class AppUsageSegment {
    var bundleIdentifier: String?
    var localizedName: String?
    var processIdentifier: Int32?
    var startedAt: Date
    var endedAt: Date?
    var createdAt: Date
    var focusSession: FocusSession?
}
```

필드 선택 원칙은 최소 수집이다.

- 저장: app identity + 시간 구간
- 저장하지 않음: window title, URL, process list, command line, screen text

`endedAt == nil`이면 currently open segment로 간주한다.

### 4.3 FocusSession relationship

`FocusSession`에 아래 relationship을 추가한다.

```swift
var appUsageSegments: [AppUsageSegment] = []
```

이 relationship을 택한 이유는 앱 usage가 "집중 모드 안에서의 사용량"이라는 제품 의미와 직접 맞기 때문이다. 세션이 끊기면 usage segment도 같이 잘려야 하고, 이후 집계도 세션 경계 안에서 계산하면 된다.

### 4.4 Schema 변경

`NudgeWhipModelContainer` schema에 `AppUsageSegment.self`를 추가한다. `nudgewhip/Shared/Persistence/NudgeWhipModelContainer.swift:45-55`

주의할 점:

- 현재 컨테이너 생성 실패 시 store reset fallback이 있다. `nudgewhip/Shared/Persistence/NudgeWhipModelContainer.swift:13-23`
- 새 엔티티 추가는 일반적으로 lightweight migration으로 처리 가능하지만, misconfiguration 시 기존 데이터가 reset될 수 있다.
- 따라서 구현 단계에서 migration smoke test를 별도로 넣어야 한다.

## 5. 서비스 설계

### 5.1 AppUsageTracker 책임

새 서비스 `AppUsageTracker`를 추가한다.

핵심 책임은 아래 네 가지다.

- frontmost app snapshot change를 받아 active segment를 열고 닫기
- focus window가 열리거나 닫힐 때 segment lifecycle 정리
- 동일 app 연속 이벤트 dedupe
- 현재 open `FocusSession`에 segment를 연결해 저장

이 서비스는 `@MainActor`로 유지한다. 현재 `IdleMonitor`, `SessionTracker`, `FrontmostAppProvider`가 모두 메인 액터 기준이기 때문이다.

### 5.2 IdleMonitor와의 경계

`IdleMonitor`는 조정자 역할만 맡는다.

- permission grant / schedule resume / manual pause 해제 / whitelist 해제 / wake/unlock에서 `sessionTracker.beginSession()` 후 `appUsageTracker.resumeFocusWindow(...)` 호출
- manual pause / whitelist pause / schedule pause / suspend / permission loss에서 `appUsageTracker.pauseFocusWindow(...)` 후 `sessionTracker.endSession(...)` 호출
- frontmost app 변경 시 `updateWhitelistMatch(for:)`는 그대로 유지하고, 이어서 `appUsageTracker.handleFrontmostAppChange(...)` 호출

중요한 점은 `IdleMonitor`가 app usage의 저장 규칙을 직접 알지 않는다는 것이다. 저장 규칙은 tracker가 가진다.

### 5.3 메뉴바 self-noise 차단

프로젝트 메모리에 있는 non-regression directive를 그대로 반영한다.

- MenuBarExtra hover/depth-menu tracking은 activity로 카운트하지 않는다.
- menu presentation 중 `NudgeWhip` 자신이 frontmost app으로 잠깐 활성화되어도 usage segment를 열지 않는다.

따라서 `IdleMonitor.isMenuPresentationActive == true`이고 frontmost snapshot의 bundle id가 app 자신과 같으면, 해당 전환은 `AppUsageTracker`에 전달하지 않거나 tracker에서 무시해야 한다.

이 규칙은 `pause submenu`나 dropdown interaction이 usage 통계와 idle timer 둘 다 흔들지 않게 하는 데 필요하다.

### 5.4 Open segment 연결 방식

새 segment를 열 때 tracker는 현재 open focus session을 fetch해서 relationship을 붙인다.

권장 순서는 아래와 같다.

1. `IdleMonitor`가 `sessionTracker.beginSession(at:)` 호출
2. `SessionTracker`가 `FocusSession` insert/save
3. `AppUsageTracker`가 가장 최근 open `FocusSession` fetch
4. 현재 frontmost app snapshot 기준으로 `AppUsageSegment` insert/save

이 방식은 `SessionTracking` protocol을 크게 넓히지 않으면서도 구현 가능하다.

### 5.5 Frontmost change 처리 규칙

tracker는 아래 규칙으로 동작한다.

- focus window가 비활성 상태면 어떤 segment도 열지 않는다.
- snapshot이 `nil`이거나 bundle id/name/pid가 모두 비어 있으면 기존 segment만 닫고 새 segment는 열지 않는다.
- 동일 snapshot이 연속으로 오면 no-op
- 다른 app으로 바뀌면 현재 segment를 닫고 새 segment를 연다.
- app이 pause/suspend로 빠지면 현재 segment를 닫는다.

### 5.6 포함 범위

Phase 1에서는 `monitoring` 상태와 같은 focus window 안에 있는 시간을 저장한다. alerting 중 별도 app switch가 없으면 segment가 유지될 수 있다.

이 의미는 현재 `FocusSession` 정의와 일치한다.

- session은 idle alerting 때문에 즉시 끊기지 않는다. `nudgewhip/Services/IdleMonitor.swift:305-326`
- recovery는 alerting segment를 닫을 뿐 focus session을 새로 만들지 않는다. `nudgewhip/Services/SessionTracker.swift:48-74`

따라서 앱 usage도 현재 제품의 focus session semantics를 그대로 따른다. 향후 "strict input-active time"이 필요해지면 별도 metric으로 추가한다.

## 6. 통계 및 UI 설계

### 6.1 집계 타입 분리

기존 `DailyStats`는 focus/recovery 전용 aggregate로 유지한다. `nudgewhip/Shared/Models/DailyStats.swift:9-183`

앱 usage는 별도 타입으로 분리한다.

```swift
struct AppUsageEntry: Equatable, Sendable {
    let bundleIdentifier: String?
    let localizedName: String
    let processIdentifier: Int32?
    let duration: TimeInterval
    let transitionCount: Int
}

struct AppUsageSnapshot: Equatable, Sendable {
    let todayTopApps: [AppUsageEntry]
    let thisWeekTopApps: [AppUsageEntry]
    let last7DaysTopApps: [AppUsageEntry]
    let todayPrimaryApp: AppUsageEntry?
}
```

집계 규칙은 아래를 따른다.

- 같은 `bundleIdentifier + localizedName` 조합 기준으로 그룹핑
- `endedAt - startedAt` 합산
- 구간 수를 `transitionCount`로 사용
- empty bundle id는 `Unknown App` 같은 fallback label로 표시

### 6.2 MenuBarViewModel 변경

`MenuBarViewModel.refreshMenuSnapshot()`는 현재 `FocusSession`만 fetch해 기존 통계를 계산한다. `nudgewhip/Services/MenuBarViewModel.swift:259-275`

여기에 app usage snapshot 계산을 추가한다.

- `focusSessions` fetch는 유지
- `statisticsSnapshot`은 그대로 계산
- 새 `appUsageSnapshot`을 추가 계산

이렇게 하면 UI는 기존 snapshot 기반 패턴을 그대로 재사용할 수 있다.

### 6.3 첫 UI surface

첫 노출면은 `StatisticsDashboardView`로 제한한다. `nudgewhip/Views/StatisticsDashboardView.swift:22-209`

Phase 1 UI:

- settings dashboard에 `Top apps` 카드 추가
- 선택된 period 기준 top 3 app과 duration 표시
- primary app 비중이 크면 별도 badge 또는 one-line summary 제공 가능

이번 단계에서 미루는 UI:

- menu bar dropdown에 top apps 직접 노출
- productive vs distracting 분류 비율
- app별 상세 drill-down

이유는 menu bar surface는 공간이 좁고, 우선은 대시보드에서 데이터 품질을 검증하는 편이 안전하기 때문이다.

## 7. 권한 및 프라이버시 가드

Phase 1은 새로운 권한을 요구하지 않는다.

- frontmost app bundle id / name / PID는 `NSWorkspace`와 `NSRunningApplication`로 얻는다.
- Accessibility는 기존 idle detection 용도로만 계속 사용한다.
- Apple Events, AX title scraping, window list scraping은 사용하지 않는다.

사용자 고지 문구는 feasibility 문서의 권장 문구와 privacy disclosure를 합쳐 아래 수준으로 맞춘다.

- 집중 세션 동안 어떤 앱이 전면에서 사용되었는지 측정할 수 있음
- 키 입력 내용, 화면 내용, 파일, 메시지, browsing history는 수집하지 않음

이 문구는 `docs/privacy/accessibility-and-data-disclosure.md`와 충돌하지 않는다.

## 8. 구현 단계

### Step 1. 모델/프로토콜 기반 추가

대상 파일:

- `nudgewhip/Services/FrontmostAppProvider.swift`
- `nudgewhip/Shared/Models/FocusSession.swift`
- `nudgewhip/Shared/Models/AppUsageSegment.swift` 신규
- `nudgewhip/Shared/Persistence/NudgeWhipModelContainer.swift`
- `nudgewhipTests/nudgewhipTests.swift`

작업:

- `FrontmostAppSnapshot` 도입
- `FrontmostAppProviding` 프로토콜 확장
- `AppUsageSegment` 모델 추가
- `FocusSession.appUsageSegments` relationship 추가
- test double을 snapshot 기반으로 업데이트

완료 기준:

- build가 통과한다.
- 기존 idle/whitelist/session 테스트가 깨지지 않는다.

### Step 2. tracker와 runtime wiring 추가

대상 파일:

- `nudgewhip/Services/AppUsageTracker.swift` 신규
- `nudgewhip/Services/IdleMonitor.swift`
- `nudgewhip/NudgeWhipAppController.swift`

작업:

- `AppUsageTracker` 구현
- `IdleMonitor`에 optional dependency 주입
- `NudgeWhipAppController`에서 wiring
- menu presentation self-noise 무시 규칙 반영

완료 기준:

- frontmost app 변경이 focus window 안에서만 segment를 생성한다.
- manual pause / whitelist / suspend / schedule pause 시 open segment가 닫힌다.

### Step 3. 집계와 UI surface 추가

대상 파일:

- `nudgewhip/Shared/Models/AppUsageSnapshot.swift` 신규
- `nudgewhip/Services/MenuBarViewModel.swift`
- `nudgewhip/Views/StatisticsDashboardView.swift`
- 필요 시 localizable strings

작업:

- period별 top apps 집계 구현
- settings dashboard에 top apps 카드 추가
- empty state 및 fallback label 처리

완료 기준:

- top apps가 duration 기준으로 안정적으로 정렬된다.
- existing statistics cards와 충돌하지 않는다.

### Step 4. 검증과 disclosure 정리

대상 파일:

- `nudgewhipTests/nudgewhipTests.swift`
- 필요 시 `docs/privacy/accessibility-and-data-disclosure.md`

작업:

- 모델/서비스/집계 단위 테스트 추가
- privacy wording이 실제 동작과 맞는지 최종 정리

완료 기준:

- unit tests 통과
- build 통과
- disclosure 문구가 구현 범위를 과장하지 않는다.

## 9. Acceptance Criteria

- focus session 중 frontmost app 전환이 `AppUsageSegment`로 저장된다.
- 저장되는 데이터는 `bundleIdentifier`, `localizedName`, `processIdentifier`, `startedAt`, `endedAt`에 한정된다.
- manual pause, whitelist pause, schedule pause, suspend, permission loss 시 open segment가 닫힌다.
- menu bar menu interaction은 idle timer와 app usage statistics를 오염시키지 않는다.
- statistics dashboard가 period별 top apps를 보여준다.
- Terminal/iTerm2 내부 command/tool 식별은 이번 단계에 포함되지 않는다.

## 10. 테스트 계획

단위 테스트:

- `FrontmostAppProvider`가 snapshot에 bundle id, name, pid를 담아 전달하는지
- `AppUsageTracker`가 app change 시 segment open/close를 올바르게 수행하는지
- 동일 snapshot 연속 입력을 dedupe하는지
- pause/suspend/whitelist/schedule 전이에서 open segment가 닫히는지
- menu presentation 중 NudgeWhip self-activation을 무시하는지
- app usage aggregation이 duration/transitionCount를 기대대로 계산하는지

수동 검증:

1. monitored session을 시작한다.
2. `Xcode -> Safari -> Terminal` 순서로 전환한다.
3. settings dashboard에서 top apps 순위와 시간이 기대대로 보이는지 확인한다.
4. menu bar dropdown을 열고 pause submenu를 hover해도 idle reset이나 self-usage segment가 생기지 않는지 확인한다.
5. manual pause, whitelist app 전환, lock/unlock, sleep/wake 시 segment 경계가 끊기는지 확인한다.

## 11. 리스크와 대응

- SwiftData schema 추가가 migration fallback reset을 유발할 수 있다.
  대응: 기존 store가 있는 상태에서 build/run smoke test를 포함한다.
- `NSWorkspace.didActivateApplicationNotification`은 빠른 전환에서 중복 이벤트를 줄 수 있다.
  대응: tracker에서 snapshot equality dedupe를 기본 규칙으로 둔다.
- menu bar self-activation이 top apps에 섞일 수 있다.
  대응: menu presentation guard와 app-bundle ignore rule을 명시적으로 유지한다.
- app usage가 strict typing time이 아니라 "focus session 안에서 frontmost였던 시간"이라는 의미라는 점을 UI copy가 놓칠 수 있다.
  대응: dashboard copy를 "Used during focus sessions" 수준으로 제한한다.

## 12. 후속 단계

이 설계가 구현 완료되면 다음 순서로 확장한다.

1. Terminal.app / iTerm2 opt-in integration feasibility 재검토
2. app-specific 최소 metadata policy 수립
3. 장기적으로 shell integration 기반 tool usage tracking 설계

그 전까지는 app-level usage를 제품의 공식 measurement boundary로 삼는다.
