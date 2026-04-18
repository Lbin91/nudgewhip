# Nudge Task: Remote Escalation Schema Alignment & iOS Consumer 구현 계획서

- Version: draft-1
- Last Updated: 2026-04-18
- Status: active
- Owner: engineering
- Related Task: iOS Companion App Development

## 1. 개요

### 1.1 RemoteEscalationEvent의 역할

RemoteEscalationEvent는 macOS 장기 미복귀 시 iOS companion 앱으로 follow-up 알림을 보내기 위한 이벤트 기록 시스템입니다. Mac에서 장시간 사용자가 복귀하지 않을 때 발생하며, CloudKit을 통해 iOS로 전달되어 Alerts 탭에서 확인할 수 있습니다.

### 1.2 현재 구현 상태

- **Mac-side writer**: `RemoteEscalationEventWriter` 구현 완료
  - `nudgewhip/Shared/Services/RemoteEscalationEventWriter.swift`
  - `nudgewhip/Shared/Models/RemoteEscalationEventPayload.swift`
- **iOS-side consumer**: 미구현
  - CloudKit query 및 캐시 로직 필요
  - Alerts 탭 UI 구현 필요
- **Recovery window 판정 로직**: 미구현
  - `wasRecoveredWithinWindow`와 `recoveredAt` 필드는 있으나 계산 로직 없음
  - RuntimeStateController와 연동 필요

### 1.3 검증 필요 사항

- 스키마 정합성: CloudKit record vs Payload struct 매핑
- Recovery window 판정 로직: 계산 위치 및 트리거 방식
- Retention 정책: 최근 30일 보관 및 자동 삭제
- Record ID 생성 규칙: uniqueness 보장 여부

## 2. 스키마 정합성 분석

### 2.1 CloudKit Record vs Payload Struct 매핑

| CloudKit Field | Payload Property | Type | 상태 |
|----------------|------------------|------|------|
| `macDeviceID` | `macDeviceID` | String | ✅ 일치 |
| `occurredAt` | `occurredAt` | Date | ✅ 일치 |
| `escalationStep` | `escalationStep` | Int | ✅ 일치 |
| `contentStateRawValue` | `contentStateRawValue` | String | ✅ 일치 |
| `schemaVersion` | `schemaVersion` | Int | ✅ 일치 (기본값 1) |
| `wasRecoveredWithinWindow` | `wasRecoveredWithinWindow` | Bool? | ✅ 일치 (optional) |
| `recoveredAt` | `recoveredAt` | Date? | ✅ 일치 (optional) |

### 2.2 스키마 정의서와의 비교

`task-ios-dashboard-data-schema.md` §7.5 정의와 코드 비교:

**스키마 정의서 (§7.5)**:
- `occurredAt`: Date — escalation 이벤트 발생 시각
- `macDeviceID`: String — 발생 Mac 식별자
- `escalationStep`: Int — (1=idleDetected, 2=gentleNudge, 3=strongNudge)
- `contentStateRawValue`: String — 발생 당시 content state
- `wasRecoveredWithinWindow`: Bool? — recovery window 내 복구 여부
- `recoveredAt`: Date? — 실제 복구 시각
- `schemaVersion`: Int

**코드 구현 (`RemoteEscalationEventWriter.swift`)**:
```swift
record["macDeviceID"] = payload.macDeviceID as CKRecordValue
record["occurredAt"] = payload.occurredAt as CKRecordValue
record["escalationStep"] = payload.escalationStep as CKRecordValue
record["contentStateRawValue"] = payload.contentStateRawValue as CKRecordValue
record["schemaVersion"] = payload.schemaVersion as CKRecordValue
if let wasRecoveredWithinWindow = payload.wasRecoveredWithinWindow {
    record["wasRecoveredWithinWindow"] = wasRecoveredWithinWindow as CKRecordValue
}
if let recoveredAt = payload.recoveredAt {
    record["recoveredAt"] = recoveredAt as CKRecordValue
}
```

**결론**: 스키마 정의서와 코드 구현이 완전히 일치함. 누락 필드 없음.

### 2.3 Escalation Step 정의

`RuntimeStateController.swift`에서의 정의:

| Step | RuntimeStateController | ContentState | 라벨 |
|------|------------------------|--------------|------|
| 0 | 초기 상태 | Focus/Recovery/Break | - |
| 1 | `idleDeadlineReached` | `idleDetected` | "유휴 감지됨" |
| 2 | `alertEscalationDeadlineReached` (첫 번째) | `gentleNudge` | "넛지 전송됨" |
| 3 | `alertEscalationDeadlineReached` (두 번째 이상) | `strongNudge` | "강한 넛지 전송됨" |

`alertEscalationDeadlineReached` 이벤트가 발생할 때마다 `alertEscalationStep`이 1씩 증가하며, contentState는 step 2에서 `gentleNudge`, step 3 이상에서 `strongNudge`로 설정됩니다.

## 3. Recovery Window 판정 로직

### 3.1 정의

Recovery window는 RemoteEscalationEvent 발생 후 UserSettings 기반 시간 내에 사용자가 복귀했는지 판정하는 기준입니다. 이를 통해 "알림이 효과적이었는지"를 측정할 수 있습니다.

### 3.2 현재 상태

- `wasRecoveredWithinWindow`와 `recoveredAt` 필드는 `RemoteEscalationEventPayload`에 정의되어 있음
- 하지만 이 값을 계산하여 채우는 로직이 구현되어 있지 않음
- 필드는 초기 생성 시 `nil`로 설정됨

### 3.3 필요 연동 지점

**RuntimeStateController와의 연동 필요**:
- `RuntimeStateController.userActivityDetected` 이벤트가 발생할 때 복구 감지
- 현재 활성화된 RemoteEscalationEvent가 있는지 확인 필요
- RemoteEscalationEvent 목록을 추적하는 별도 컴포넌트 필요

### 3.4 계산 방식

**단계 1: RemoteEscalationEvent 발생**
- Mac에서 escalationStep 3(strongNudge) 이후 일정 시간 경과 시 event 생성
- `occurredAt`에 현재 시각 기록
- `wasRecoveredWithinWindow` = `nil`, `recoveredAt` = `nil`
- CloudKit에 업로드

**단계 2: User Activity 감지**
- `RuntimeStateController.handle(.userActivityDetected)` 호출 시
- 가장 최근의 unrecovered RemoteEscalationEvent 확인
- `occurredAt` 기준으로 recovery window 내인지 판정

**단계 3: Recovery Window 판정**
- Recovery window 기본값: 300초 (5분)
- UserSettings에서 설정 가능한 값 (초 단위)
- `recoveredAt` = 현재 시각
- `wasRecoveredWithinWindow` = `(recoveredAt - occurredAt) <= recoveryWindow`
- CloudKit record 업데이트 (modify operation)

**단계 4: DashboardDayProjection 집계**
- `remoteEscalationSentCount` 증가 (event 생성 시)
- `remoteEscalationRecoveredWithinWindowCount` 증가 (recovery window 내 복구 시)

### 3.5 구현 위치 제안

**새로운 컴포넌트: `RemoteEscalationTracker`**

```swift
@MainActor
final class RemoteEscalationTracker {
    private var activeEscalationEvents: [RemoteEscalationEventPayload] = []
    private let writer: RemoteEscalationEventWriter
    private let userSettingsProvider: UserSettingsProvider
    private let deviceIdentityProvider: DeviceIdentityProvider

    // RemoteEscalationEvent 생성
    func recordEscalation(occurredAt: Date, escalationStep: Int, contentState: NudgeWhipContentState) async throws

    // User activity 감지 시 복구 처리
    func handleUserActivity(at date: Date) async throws

    // Recovery window 계산
    private func checkRecoveryWindow(escalationEvent: RemoteEscalationEventPayload, recoveredAt: Date) -> Bool
}
```

**RuntimeStateController 통합**:
- `RuntimeStateController`에서 `userActivityDetected` 이벤트 발생 시 `RemoteEscalationTracker.handleUserActivity()` 호출
- AlertManager에서 escalation event 생성 시 `RemoteEscalationTracker.recordEscalation()` 호출

## 4. Record ID 생성 규칙

### 4.1 현재 구현

```swift
let recordID = CKRecord.ID(
    recordName: "\(payload.macDeviceID)__\(Int(payload.occurredAt.timeIntervalSince1970))",
    zoneID: zoneID
)
```

- 포맷: `"macDeviceID__timestamp"` (timestamp는 초 단위 Int)
- 예: `"MacABC123__1713745200"`

### 4.2 스키마 정의서

`task-ios-dashboard-data-schema.md` §7.5:
- identity key: `"macDeviceID + occurredAt"` (timestamp 기반 unique key)

### 4.3 일치 여부 검증

- 현재 구현: 초 단위 timestamp 사용 → 동일 초 내 두 이벤트 발생 시 충돌 가능
- 스키마 정의서: timestamp 기반 unique key → 초 단위면 충분하다고 가정
- 일치 여부: 구현이 정의서와 일치함. 초 단위 timestamp가 uniqueness 보장으로 충분하다고 판단

### 4.4 주의 사항

- 동일 초에 두 이벤트 발생 시 record ID 충돌 가능성
- 하지만 RemoteEscalationEvent는 장기 미복귀 시 발생하는 이벤트이므로 동일 초 내 다중 발생은 극히 드묾
- 만약 충돌 발생 시 CloudKit save는 오류 반환 → 로깅 후 재시도 또는 무시 처리 필요

## 5. iOS-side Consumer 구현 계획

### 5.1 CloudKit Query

```swift
let query = CKQuery(recordType: "RemoteEscalationEvent", predicate: NSPredicate(value: true))
query.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]
```

- Record type: `RemoteEscalationEvent`
- Predicate: 전체 (시간 기반 필터는 iOS 로컬에서 적용)
- Sort: `occurredAt` 내림차순 (최근 이벤트 우선)
- Limit: 최근 30일치 (로컬에서 필터링)

### 5.2 iOS Local Cache

**SwiftData Model** (task-ios-model-container.md에서 정의 예정):

```swift
@Model
final class CachedRemoteEscalation {
    var cloudKitRecordID: String
    var macDeviceID: String
    var occurredAt: Date
    var escalationStep: Int
    var contentStateRawValue: String
    var wasRecoveredWithinWindow: Bool?
    var recoveredAt: Date?
    var schemaVersion: Int
    var createdAt: Date
    var updatedAt: Date

    // Computed properties for UI
    var escalationStepLabel: String { ... }
    var isRecovered: Bool { recoveredAt != nil }
    var recoveryDuration: TimeInterval? { ... }
}
```

### 5.3 Fetch & Cache Strategy

**Fetch Trigger**:
- App launch 시
- Foreground 진입 시
- Push notification 수신 시 (CloudKit silent push)

**Cache Update Flow**:
1. CloudKit에서 `RemoteEscalationEvent` record fetch
2. 기존 `CachedRemoteEscalation`과 비교
3. 새로운 record는 추가, 기존 record는 업데이트
4. 30일 초과 오래된 record는 자동 삭제
5. SwiftData context save

**Retention**:
- 최근 30일치만 로컬 캐시에 보관
- 30일 경과 후 자동 삭제 (백그라운드 cleanup task)

### 5.4 Alerts 탭 데이터 소스

```swift
struct AlertsViewModel: ObservableObject {
    @Published var recentEscalations: [CachedRemoteEscalation] = []

    func loadRecentEscalations() async {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        recentEscalations = (try? modelContext.fetch(
            FetchDescriptor<CachedRemoteEscalation>(
                predicate: #Predicate { $0.occurredAt >= thirtyDaysAgo },
                sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
            )
        )) ?? []
    }
}
```

## 6. Lifecycle

### 6.1 Mac-side 생성

**트리거 조건**:
- Alerting 상태에서 escalationStep이 3(strongNudge) 이상
- 일정 시간 (예: 10분) 추가 경과
- 사용자 복귀 없음

**생성 로직**:
1. AlertManager에서 `RemoteEscalationTracker.recordEscalation()` 호출
2. `RemoteEscalationEventPayload` 생성 (macDeviceID, occurredAt, escalationStep, contentStateRawValue)
3. `RemoteEscalationEventWriter.save()`로 CloudKit 업로드 (best-effort)

### 6.2 CloudKit 업로드

- 즉시 업로드 시도 (best-effort)
- 네트워크 실패 시 exponential backoff로 재시도
- Outbox 패턴 사용 가능 (MacStateCloudKitWriter와 유사)

### 6.3 iOS Push

**Push Trigger**:
- RemoteEscalationEvent CloudKit save 성공 후
- CKQuerySubscription 설정으로 자동 트리거
- 또는 APNs silent push

**Push Content**:
- payload: 기본 알림 메시지
- content-available: true (silent push)
- 사용자 가시 알림: "Mac에서 장기 미복귀 감지됨"

### 6.4 iOS Fetch

**Fetch Trigger**:
- Push notification 수신 시
- App launch 시 (delta fetch)
- Foreground 진입 시

**Fetch Flow**:
1. CloudKit query로 최근 record fetch
2. SwiftData cache 업데이트
3. UI refresh

### 6.5 iOS 캐시 Retention

- 최근 30일치만 보관
- 30일 경과 후 자동 삭제
- 백그라운드 cleanup task에서 주기적으로 실행

### 6.6 Recovery 업데이트

**Mac-side**:
- User activity 감지 시 `RemoteEscalationTracker.handleUserActivity()` 호출
- 가장 최근 unrecovered event 확인
- `recoveredAt`과 `wasRecoveredWithinWindow` 계산
- CloudKit record 업데이트 (CKDatabase.modifyRecords)

**iOS-side**:
- Push 또는 fetch로 업데이트된 record 수신
- 로컬 cache 업데이트
- UI refresh (복구 상태 변경 표시)

## 7. UI/UX (iOS Alerts 탭)

### 7.1 리스트 Row 구성

```
┌─────────────────────────────────────┐
│ 오전 3:42                  [복구됨]  │ ← 시각 | 복구 여부 배지
│ 강한 넛지 전송됨                    │ ← 에스컬레이션 단계 라벨
│ (15분 소요)                        │ ← 복구 시간 (복구된 경우)
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 오후 2:15                 [미복구]  │
│ 강한 넛지 전송됨                    │
└─────────────────────────────────────┘
```

### 7.2 읽음/안읽음 구분

- MVP에서는 읽음/안읽음 구분 없음
- 모든 이벤트가 동일한 스타일로 표시

### 7.3 빈 상태

```
┌─────────────────────────────────────┐
│                                     │
│          (아이콘)                   │
│                                     │
│   최근 원격 알림이 없습니다          │
│                                     │
└─────────────────────────────────────┘
```

### 7.4 Free/Pro 분기

- Alerts 탭 전체가 Pro 기능
- Free 사용자에게는 "Pro 기능" 안내와 업그레이드 CTA 표시
- Home 화면의 "recent follow-up card"도 Free 사용자에게는 숨김

## 8. 라벨 문구

### 8.1 에스컬레이션 단계

| Step | 라벨 | 근거 |
|------|------|------|
| 1 | "유휴 감지됨" | `idleDetected` |
| 2 | "넛지 전송됨" | `gentleNudge` |
| 3 | "강한 넛지 전송됨" | `strongNudge` |

### 8.2 복구 상태

**복구됨**:
- 라벨: "복구됨"
- 세부: "(%@ 소요)" (초/분 단위)
- 예: "복구됨 (3분 소요)", "복구됨 (45초 소요)"

**미복구**:
- 라벨: "미복구"
- 배지 색상: 주의 색상 (예: 오렌지)

### 8.3 시간 표시

- 포맷: "오전 3:42", "오후 2:15" (12시간제)
- 타임존: 사용자 로컬 타임존
- 날짜: 오늘이면 시각만, 어제/그 이전이면 "어제 3:42", "4/18 3:42"

### 8.4 국제화 (i18n)

- 모든 라벨은 `Localizable.xcstrings`에서 관리
- 한국어/영어 기본 지원
- 시간 포맷은 `DateFormatter`의 localized string 사용

## 9. 클릭 시 액션

### 9.1 MVP 범위

- 리스트 항목 탭: 상세 보기 (구현 범위 밖)
- 향후 검토: 해당 이벤트의 상세 정보 (복구 시간, content state 등) 표시

### 9.2 Swipe Actions

- MVP에서는 swipe actions 없음
- 향후 검토: "복구 표시" (현재 복구되지 않은 이벤트에 대해)

## 10. 예외 처리

### 10.1 CloudKit Network 오류

- 자동 재시도 (exponential backoff)
- 최대 재시도 횟수: 3회
- 실패 시 로깅 및 사용자 안내 (설정 화면에서 sync 상태 표시)

### 10.2 Zone 없음

- `ensureZoneExistsIfNeeded()`에서 자동 생성
- 생성 실패 시 경고 로그 및 로컬 전용 모드로 폴백

### 10.3 중복 Record Save

- CKRecord ID 기반 upsert 동작 (CloudKit 자동 처리)
- 동일 ID로 save 시 기존 record 덮어씀

### 10.4 iOS에서 Record 파싱 실패

- 스킵하고 다음 record 처리
- 로깅 (record ID, error reason)
- 가능하면 일부 필드만이라도 파싱 시도

### 10.5 30일 초과 오래된 Record

- iOS 로컬 캐시에서 자동 삭제
- CloudKit에서는 유지 (장기 보관용)
- DashboardDayProjection의 retention(35일)과 독립적

### 10.6 미래 시간의 Record

- 시계 오류 등으로 발생 가능
- iOS fetch 시 필터링 (`occurredAt <= now`)
- 로깅 후 스킵

### 10.7 스키마 버전 불일치

- `schemaVersion` 필드로 판별
- iOS에서 지원하지 않는 버전인 경우:
  - 가능한 필드만 파싱
  - 최소한의 UI 표시
  - 사용자에게 앱 업데이트 권장

## 11. 테스트 구현

### 11.1 Unit Tests

**RemoteEscalationEventWriter.record()**:
- [ ] payload → CKRecord 필드 매핑 정확성
  - `macDeviceID` 매핑
  - `occurredAt` 매핑
  - `escalationStep` 매핑
  - `contentStateRawValue` 매핑
  - `schemaVersion` 매핑
  - `wasRecoveredWithinWindow` optional 처리
  - `recoveredAt` optional 처리
- [ ] record ID 생성 포맷 검증
  - `"macDeviceID__timestamp"` 형식
  - timestamp가 초 단위 Int인지 확인

**RemoteEscalationEventWriter.save()**:
- [ ] mock CKDatabase으로 save 호출 확인
- [ ] save 성공 시 반환
- [ ] save 실패 시 에러 전파

**ensureZoneExistsIfNeeded()**:
- [ ] zone 생성 한 번만 호출
- [ ] zone 생성 성공 시 `hasEnsuredZone` 설정
- [ ] 이미 존재하는 zone일 때 정상 동작

**Optional 필드 처리**:
- [ ] `wasRecoveredWithinWindow`가 nil일 때도 record 생성 성공
- [ ] `recoveredAt`가 nil일 때도 record 생성 성공
- [ ] 두 필드 모두 nil일 때도 record 생성 성공

### 11.2 Integration Tests

**End-to-End Flow**:
- [ ] Mac에서 RemoteEscalationEvent 생성 → CloudKit 업로드
- [ ] iOS에서 CloudKit fetch → 로컬 cache 저장
- [ ] Mac에서 user activity 감지 → recovery 업데이트 → CloudKit upload
- [ ] iOS에서 updated record fetch → 로컬 cache 업데이트

**Recovery Window 판정**:
- [ ] recovery window 내 복구 시 `wasRecoveredWithinWindow = true`
- [ ] recovery window 외 복구 시 `wasRecoveredWithinWindow = false`
- [ ] 복구되지 않은 event는 `wasRecoveredWithinWindow = nil`

**Retention**:
- [ ] 30일 초과 record가 로컬 cache에서 자동 삭제
- [ ] 최신 30일치만 fetch 및 표시

### 11.3 UI Tests (iOS)

**Alerts 탭**:
- [ ] 최근 이벤트가 `occurredAt` 내림차순으로 표시
- [ ] 복구된 event에 "복구됨" 배지 표시
- [ ] 미복구 event에 "미복구" 배지 표시
- [ ] 에스컬레이션 단계 라벨 정확 표시
- [ ] 시각이 로컬 타임존 기준으로 표시
- [ ] 빈 상태시 "최근 원격 알림이 없습니다" 메시지 표시

**Free/Pro 분기**:
- [ ] Free 사용자에게 Pro 기능 안내 표시
- [ ] Pro 사용자에게 Alerts 탭 내용 표시

## 12. 실패 테스트 구현

### 12.1 RemoteEscalationEventWriter 실패 케이스

**Configuration 실패**:
- [ ] `database == nil`일 때 `save()` 호출 → `notConfigured` 에러
- [ ] 에러 메시지와 에러 코드 검증

**Zone 생성 실패**:
- [ ] CloudKit 권한 문제로 zone 생성 실패 시 에러 전파
- [ ] 네트워크 실패 시 에러 전파
- [ ] `hasEnsuredZone`이 false로 유지되는지 확인

**CKRecord save 실패**:
- [ ] CloudKit quota 초과 시 에러 전파
- [ ] 네트워크 실패 시 에러 전파
- [ ] record 파싱 실패 시 에러 전파

### 12.2 Record ID 충돌

**동일 timestamp 두 이벤트**:
- [ ] 동일 초에 두 이벤트 발생 시 record ID 충돌 감지
- [ ] CloudKit save 실패 시 에러 전파
- [ ] 로깅으로 충돌 기록
- [ ] 재시도 또는 무시 처리

### 12.3 Recovery Window 판정 실패

**UserSettings 없음**:
- [ ] UserSettings에서 recovery window 값 가져오기 실패 시 기본값(300초) 사용
- [ ] 기본값으로 recovery window 판정 정상 동작

**이벤트 목록 누락**:
- [ ] `activeEscalationEvents`가 비어있을 때 `handleUserActivity()` 호출 시 정상 동작 (무시)
- [ ] 모든 event가 이미 recovered일 때 정상 동작 (무시)

### 12.4 iOS Fetch 실패

**CloudKit query 실패**:
- [ ] 네트워크 실패 시 에러 전파
- [ ] 권한 문제 시 에러 전파
- [ ] 기존 캐시 데이터 유지 (fallback)

**Record 파싱 실패**:
- [ ] 필수 필드 누락 시 해당 record 스킵
- [ ] 타입 불일치 시 해당 record 스킵
- [ ] 로깅으로 실패 기록
- [ ] 다른 record는 정상 처리

### 12.5 시스템 시계 오류

**미래 시간의 record**:
- [ ] `occurredAt > now`인 record 수신 시 필터링
- [ ] 로깅으로 경고 기록
- [ ] iOS fetch에서 제외

**과거 시간의 record (30일 초과)**:
- [ ] `occurredAt < (now - 30 days)`인 record 수신 시 필터링
- [ ] 로깅으로 정보 기록
- [ ] iOS fetch에서 제외

## 13. 완료 기준

### 13.1 Mac-side

- [ ] RemoteEscalationEventWriter 구현 완료 및 테스트 통과
- [ ] RemoteEscalationEventPayload 모델 정의 완료
- [ ] RemoteEscalationTracker 컴포넌트 구현
  - [ ] recordEscalation() 메서드 구현
  - [ ] handleUserActivity() 메서드 구현
  - [ ] checkRecoveryWindow() 메서드 구현
- [ ] RuntimeStateController와 연동 완료
  - [ ] userActivityDetected 이벤트에서 handleUserActivity() 호출
  - [ ] AlertManager에서 recordEscalation() 호출
- [ ] Recovery window 계산 로직 테스트 통과
  - [ ] window 내 복구 시 `wasRecoveredWithinWindow = true`
  - [ ] window 외 복구 시 `wasRecoveredWithinWindow = false`
  - [ ] 미복구 시 `wasRecoveredWithinWindow = nil`
- [ ] CloudKit 업로드 테스트 통과
  - [ ] record 생성 및 save 성공
  - [ ] recovery 업데이트 (modify) 성공
  - [ ] 네트워크 실패 시 재시도 동작

### 13.2 iOS-side

- [ ] CachedRemoteEscalation SwiftData 모델 정의
- [ ] CloudKit query 구현
  - [ ] RemoteEscalationEvent fetch
  - [ ] 최신 30일치 필터링
- [ ] Local cache 업데이트 로직 구현
  - [ ] 새 record 추가
  - [ ] 기존 record 업데이트
  - [ ] 30일 초과 record 삭제
- [ ] AlertsViewModel 구현
  - [ ] loadRecentEscalations() 메서드
  - [ ] @Published recentEscalations 상태 관리
- [ ] Alerts 탭 UI 구현
  - [ ] 리스트 row 레이아웃
  - [ ] 에스컬레이션 단계 라벨 표시
  - [ ] 복구 상태 배지 표시
  - [ ] 시간 표시 (로컬 타임존)
  - [ ] 빈 상태 표시
  - [ ] Free/Pro 분기
- [ ] Push notification 수신 처리
  - [ ] CloudKit silent push
  - [ ] fetch trigger
- [ ] 예외 처리 구현
  - [ ] 네트워크 실패 시 fallback
  - [ ] record 파싱 실패 시 스킵
  - [ ] 미래 시간 record 필터링

### 13.3 테스트

- [ ] RemoteEscalationEventWriter unit test 통과
  - [ ] record() 메서드 테스트
  - [ ] save() 메서드 테스트
  - [ ] ensureZoneExistsIfNeeded() 테스트
  - [ ] optional 필드 처리 테스트
- [ ] RemoteEscalationTracker unit test 통과
  - [ ] recordEscalation() 테스트
  - [ ] handleUserActivity() 테스트
  - [ ] checkRecoveryWindow() 테스트
- [ ] Integration test 통과
  - [ ] Mac 생성 → iOS fetch flow
  - [ ] Recovery 업데이트 flow
  - [ ] Retention 동작
- [ ] iOS UI test 통과
  - [ ] Alerts 탭 렌더링
  - [ ] 시간 순서 정렬
  - [ ] 복구 상태 표시
  - [ ] Free/Pro 분기
- [ ] 실패 케이스 테스트 통과
  - [ ] Configuration 실패
  - [ ] Zone 생성 실패
  - [ ] Record save 실패
  - [ ] Record ID 충돌
  - [ ] Recovery window 판정 실패
  - [ ] iOS fetch 실패
  - [ ] 시스템 시계 오류

### 13.4 문서

- [ ] 이 문서 (`task-remote-escalation-schema-alignment.md`) 완료
- [ ] 코드 주석 추가 (Recovery window 판정 로직 등)
- [ ] API 문서 업데이트 (RemoteEscalationEventWriter, RemoteEscalationTracker)
- [ ] 테스트 결과 문서화

## 14. 향후 검토 사항

### 14.1 상세 보기

- 리스트 항목 탭 시 상세 화면 표시
- 복구 시간, content state, recovery duration 등 상세 정보

### 14.2 Swipe Actions

- 미복구 이벤트에 대해 "복구 표시" 액션
- 사용자가 수동으로 복구 기록 가능

### 14.3 필터링 및 정렬

- 에스컬레이션 단계별 필터
- 기간 범위 필터 (예: 최근 7일, 30일, 모두)
- 복구 상태별 필터 (복구됨, 미복구)

### 14.4 Analytics

- RemoteEscalationEvent 효과성 분석
- Recovery window 최적화
- Escalation 단계별 복구율 추적

### 14.5 사용자 피드백

- 알림이 도움이 되었는지 피드백 수집
- 너무 자주 오는지 여부 체크
- 알림 타이밍 조정 가능 여부

## 15. 관련 문서

- [task-ios-dashboard-data-schema.md](./task-ios-dashboard-data-schema.md) — §7.5 RemoteEscalationEvent spec
- [task-ios-dashboard-ia-and-prep.md](./task-ios-dashboard-ia-and-prep.md) — §5.3 Alerts 탭 스크린 컨트랙트
- [cloudkit-sync-contract.md](../architecture/cloudkit-sync-contract.md) — CloudKit 동기화 계약서
- [RemoteEscalationEventWriter.swift](../nudgewhip/Shared/Services/RemoteEscalationEventWriter.swift) — Mac-side writer 구현
- [RemoteEscalationEventPayload.swift](../nudgewhip/Shared/Models/RemoteEscalationEventPayload.swift) — Payload 모델
- [RuntimeStateController.swift](../nudgewhip/Services/RuntimeStateController.swift) — 런타임 상태 기계

## 16. 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| draft-1 | 2026-04-18 | 초기 문서 작성 | engineering |
