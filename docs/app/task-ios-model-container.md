# Nudge Task: iOS ModelContainer (Read-Only Projection Cache)

- Version: draft-1
- Last Updated: 2026-04-18
- Status: active
- Owner: product / engineering
- Related: `docs/app/task-ios-model-container.md`, `docs/app/task-ios-dashboard-data-schema.md`, `docs/app/ios-companion-prd.md`

## 1. 개요

### 1.1 배경

iOS companion 앱은 Mac에서 CloudKit으로 업로드한 projection 데이터를 소비하는 read-only 클라이언트다. Mac의 SwiftData가 source of truth이며, iOS는 CloudKit에서 받은 데이터를 로컬에 캐시하여 오프라인에서도 UI 렌더링이 가능해야 한다.

### 1.2 현재 상태

- macOS ModelContainer(`NudgeWhipModelContainer`)는 모든 @Model을 등록하여 디스크에 저장
- iOS 앱 엔트리 포인트(`nudgewhipiosApp.swift`)에 ModelContainer 없음
- `DashboardDayProjectionPayload`, `MacStatePayload`, `RemoteEscalationEventPayload`는 struct로 정의되어 SwiftData 캐시 불가
- `CloudKitDailyAggregateFetchConsumer`가 CloudKit record → payload 변환은 이미 구현됨

### 1.3 목표

iOS 앱에서 CloudKit fetch 결과를 SwiftData 로컬 캐시에 저장하여:
1. 오프라인 상태에서도 기존 데이터로 UI 렌더링
2. stale-while-revalidate 패턴 적용 (캐시 먼저 보여주고, 백그라운드에서 갱신)
3. 복잡한 날짜 범위 쿼리(최근 7일)를 로컬에서 빠르게 수행

### 1.4 영향받는 파일

| 구분 | 파일 | 설명 |
|------|------|------|
| 신규 | `nudgewhipios/Persistence/iOSModelContainer.swift` | iOS용 ModelContainer 팩토리 |
| 신규 | `nudgewhipios/Models/CachedMacState.swift` | MacState 캐시 @Model |
| 신규 | `nudgewhipios/Models/CachedDayProjection.swift` | DayProjection 캐시 @Model |
| 신규 | `nudgewhipios/Models/CachedRemoteEscalation.swift` | RemoteEscalation 캐시 @Model |
| 신규 | `nudgewhipios/Services/CloudKitCacheSyncService.swift` | CloudKit fetch → 로컬 upsert 로직 |
| 수정 | `nudgewhipios/nudgewhipiosApp.swift` | ModelContainer 주입 |

## 2. 설계 원칙

### 2.1 iOS는 순수 Consumer

- iOS에서 생성하는 데이터는 없음
- SwiftData @Model은 캐시 레이어용이며, Mac의 @Model과 스키마가 달라도 됨
- CloudKit → fetch → payload → @Model upsert → UI 렌더링

### 2.2 macOS @Model과 iOS @Model 분리

- macOS: `FocusSession`, `AlertingSegment`, `UserSettings` 등 (source of truth)
- iOS: `CachedMacState`, `CachedDayProjection`, `CachedRemoteEscalation` (캐시 전용)
- 스키마 버전 관리 불필요 (iOS 첫 설치, 마이그레이션 이슈 없음)
- CloudKitDatabase = `.none` (iOS는 직접 CloudKit API로 fetch 후 로컬 저장)

### 2.3 Retention

| 캐시 모델 | 보존 기간 | 최대 레코드 |
|-----------|-----------|-------------|
| CachedMacState | 무제한 (단일 레코드) | 1 |
| CachedDayProjection | 최근 35일 | 35 |
| CachedRemoteEscalation | 최근 30일 | ~30 |

## 3. iOS용 @Model 설계

### 3.1 CachedMacState

Mac의 최신 런타임 상태를 단일 레코드로 캐시.

```swift
@Model
final class CachedMacState {
    var macDeviceID: String
    var state: String             // NudgeWhipRuntimeState rawValue
    var stateChangedAt: Date
    var sequence: Int64
    var breakUntil: Date?
    var lastAlertAt: Date?
    var schemaVersion: Int64
    var fetchedAt: Date           // iOS가 CloudKit에서 fetch한 시각
}
```

특이사항:
- 항상 단일 레코드만 유지 (upsert 시 기존 레코드 삭제 후 삽입)
- `fetchedAt`은 iOS 관점의 메타데이터 (CloudKit record 필드 아님)

### 3.2 CachedDayProjection

일별 대시보드 projection 캐시.

```swift
@Model
final class CachedDayProjection {
    var macDeviceID: String
    var localDayKey: String       // "2026-04-18@Asia/Seoul"
    var dayStart: Date
    var timeZoneIdentifier: String
    var updatedAt: Date
    var schemaVersion: Int64
    var totalFocusDurationSeconds: Int64
    var completedSessionCount: Int64
    var alertCount: Int64
    var longestFocusDurationSeconds: Int64
    var recoverySampleCount: Int64
    var recoveryDurationTotalSeconds: Int64
    var recoveryDurationMaxSeconds: Int64
    var sessionsOver30mCount: Int64
    var hourlyAlertCountsData: Data    // JSON 인코딩된 [Int]
    var fetchedAt: Date
}
```

특이사항:
- `hourlyAlertCountsData`: `[Int]`를 JSON Data로 저장 (CloudKit의 `hourlyAlertCountsJSON`과 동일 방식)
- `localDayKey`를 고유 식별자로 사용 (macDeviceID + localDayKey 조합)
- `#Unique` 제약 또는 upsert 로직으로 중복 방지

### 3.3 CachedRemoteEscalation

원격 에스컬레이션 이벤트 캐시.

```swift
@Model
final class CachedRemoteEscalation {
    var macDeviceID: String
    var occurredAt: Date
    var escalationStep: Int
    var contentStateRawValue: String
    var wasRecoveredWithinWindow: Bool?
    var recoveredAt: Date?
    var schemaVersion: Int
    var fetchedAt: Date
}
```

특이사항:
- `occurredAt` 내림차순 정렬로 Alerts 탭 리스트 구성
- record ID: `"macDeviceID__Int(occurredAt.timeIntervalSince1970)"`

## 4. iOS ModelContainer 구성

```swift
enum iOSModelContainer {
    static let shared: ModelContainer = {
        do {
            return try makeModelContainer(inMemory: false)
        } catch {
            fatalError("Failed to create iOS model container: \(error)")
        }
    }()

    @MainActor
    static let preview: ModelContainer = {
        do {
            let container = try makeModelContainer(inMemory: true)
            // preview용 샘플 데이터 삽입
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()

    static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            CachedMacState.self,
            CachedDayProjection.self,
            CachedRemoteEscalation.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none    // iOS는 직접 CloudKit API 사용
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
```

주요 차이점 (macOS 대비):
- 등록 @Model이 완전히 다름 (macOS 전용 모델 제외)
- `cloudKitDatabase: .none` (iOS는 NSPersistentCloudKitContainer 미사용)
- 저장소 파일명이 다름 (자동 분리됨, 다른 Bundle ID)
- `NudgeWhipDataBootstrap` 불필요 (iOS는 기본값 seed 필요 없음)

## 5. CloudKitCacheSyncService

CloudKit fetch → SwiftData upsert 로직을 담당하는 서비스.

### 5.1 책임

1. CloudKit에서 최신 MacState, DayProjection, RemoteEscalation fetch
2. 수신한 payload를 해당 @Model로 변환
3. SwiftData context에 upsert (기존 레코드 업데이트 또는 신규 삽입)
4. retention 정책에 따라 오래된 캐시 삭제

### 5.2 인터페이스

```swift
@MainActor
final class CloudKitCacheSyncService {
    func syncAll(macDeviceID: String) async throws
    func syncMacState(macDeviceID: String) async throws
    func syncRecentProjections(macDeviceID: String, days: Int = 7) async throws
    func syncRecentEscalations(macDeviceID: String, days: Int = 30) async throws
    func trimExpiredCache() throws
}
```

### 5.3 Upsert 로직

**CachedMacState**: 단일 레코드 유지
1. 기존 `CachedMacState` 전체 삭제
2. 새 `MacStatePayload` → `CachedMacState` 변환 후 삽입

**CachedDayProjection**: localDayKey 기준 upsert
1. 동일 `localDayKey`의 기존 레코드 조회
2. 있으면 필드 업데이트, 없으면 신규 삽입

**CachedRemoteEscalation**: macDeviceID + occurredAt 기준 upsert
1. 동일 `occurredAt`의 기존 레코드 조회
2. 있으면 `wasRecoveredWithinWindow`, `recoveredAt` 업데이트, 없으면 신규 삽입

## 6. Lifecycle

### 6.1 앱 시작

```
앱 실행
  → iOSModelContainer.shared 초기화
  → nudgewhipiosApp에 .modelContainer 주입
  → CloudKitCacheSyncService.syncAll() 호출 (백그라운드)
  → 캐시 데이터 있으면 즉시 UI 렌더링
  → CloudKit fetch 완료 후 UI 갱신
```

### 6.2 Foreground 복귀

```
UIApplication.didBecomeActiveNotification
  → syncMacState() — 최신 상태 갱신
  → syncRecentProjections() — 오늘 projection 갱신
```

### 6.3 Push 수신

```
원격 알림 수신
  → 관련 record type에 따라 syncMacState() 또는 syncRecentEscalations()
```

### 6.4 하루 경계 진입

```
날짜 변경 감지 ( significantTimeChangeNotification)
  → syncRecentProjections() — 어제/오늘 projection 갱신
  → trimExpiredCache() — 35일/30일 초과 레코드 정리
```

### 6.5 앱 종료

```
앱 종료 / 백그라운드
  → 디스크에 자동 저장 (SwiftData 기본 동작)
  → 특별한 cleanup 불필요
```

## 7. UI/UX 영향

### 7.1 데이터 흐름

```
CloudKit → CloudKitCacheSyncService → SwiftData (@Model 캐시) → View
```

각 뷰의 데이터 소스:

| 뷰 | 데이터 소스 | 쿼리 |
|----|-----------|------|
| HomeView | CachedMacState (1개) + CachedDayProjection (오늘) | localDayKey == today |
| StatsView | CachedDayProjection (최근 7개) | dayStart 내림차순, limit 7 |
| AlertsView | CachedRemoteEscalation (최근 30일) | occurredAt 내림차순 |
| SettingsView | CachedMacState.fetchedAt | 마지막 동기화 시각 |

### 7.2 Loading State 전략 (Stale-While-Revalidate)

1. 캐시 데이터 있으면 즉시 렌더링
2. CloudKit fetch 백그라운드 실행
3. fetch 완료 후 UI 갱신 (`.task` modifier + `@Query` 자동 반영)
4. 캐시 없으면 skeleton/loading 표시

## 8. 라벨 문구

### 8.1 동기화 상태

| 상태 | 문구 |
|------|------|
| 동기화 중 | "Mac 상태를 불러오고 있습니다..." |
| 동기화 완료 | "마지막 업데이트: %@ (오전/오후 h:mm)" |
| 오프라인 | "최근 업데이트 없음" |
| CloudKit 에러 | "동기화에 실패했습니다. 잠시 후 다시 시도합니다." |
| iCloud 미로그인 | "iCloud에 로그인하면 Mac과 연결할 수 있습니다." |
| 빈 캐시 | "Mac에서 NudgeWhip을 실행하면 여기에 상태가 표시됩니다" |

### 8.2 Stale 데이터 표시

- 마지막 업데이트 후 1시간 이상: `Text.secondary` + "최근 업데이트: %@"
- 마지막 업데이트 후 6시간 이상: `.nudgewhipAlert` 배지 + "연결이 끊어졌을 수 있습니다"

## 9. 클릭 시 액션

| 위치 | 액션 | 동작 |
|------|------|------|
| HomeView 동기화 카드 | 탭 | Settings 탭으로 이동 |
| SettingsView "다시 시도" 버튼 | 탭 | 수동 syncAll() 트리거 + 로딩 인디케이터 |
| SettingsView "iCloud 로그인" | 탭 | 시스템 설정 앱 열기 (UIApplication.shared.open) |
| AlertsView 리스트 항목 | 탭 | 향후 상세 보기 (MVP 범위 밖) |

## 10. 예외 처리

### 10.1 iCloud 미로그인

- `CKContainer.accountStatus()` 로 확인
- 결과: Settings에서 안내 문구 표시, 데이터는 캐시만으로 동작 불가
- 복구: 사용자가 iCloud 로그인 후 앱 재시작

### 10.2 CloudKit quota 초과

- `CKError.quotaExceeded` 감지
- 대응: 사용자에게 알림 없이 자동 재시도 (exponential backoff: 1s, 2s, 4s, 8s, max 60s)
- 최대 5회 재시도 후 포기

### 10.3 CloudKit 네트워크 오류

- `CKError.networkFailure`, `CKError.networkUnavailable`
- 대응: 기존 캐시 데이터로 UI 유지, 다음 foreground에서 재시도

### 10.4 SwiftData 캐시 손상

- macOS ModelContainer와 동일한 패턴 적용
- 저장소 파일 삭제 후 재생성
- 이후 CloudKit에서 전체 재동기화

### 10.5 Schema 버전 불일치

- 수신한 record의 `schemaVersion`이 예상과 다르면
- 해당 record 스킵, 나머지 정상 record는 처리
- 로그에 schema 버전 불일치 기록

### 10.6 잘못된 record 필드

- `CloudKitDailyAggregateFetchConsumer`가 이미 `missingField`, `invalidField` 에러 처리
- iOS consumer에서도 동일한 에러 처리 패턴 적용
- 실패한 record 스킵, 다음 record 처리

## 11. 테스트 구현

### 11.1 CachedMacState 테스트

**Given** 빈 SwiftData 컨텍스트
**When** MacStatePayload를 CachedMacState로 upsert
**Then** 정확히 1개의 레코드가 존재, 필드 값이 payload와 일치

**Given** 기존 CachedMacState 1개 존재 (state = "monitoring")
**When** 새 MacStatePayload(state = "alerting") upsert
**Then** 기존 레코드가 업데이트됨, 여전히 1개만 존재, state = "alerting"

### 11.2 CachedDayProjection 테스트

**Given** 빈 컨텍스트
**When** 7개의 DayProjectionPayload를 upsert
**Then** 7개의 CachedDayProjection 존재, localDayKey별로 고유

**Given** 기존 projection(localDayKey = "2026-04-18@Asia/Seoul", totalFocusDuration = 3600)
**When** 동일 localDayKey의 업데이트된 projection(totalFocusDuration = 7200) upsert
**Then** 레코드 수는 동일(1개), totalFocusDuration = 7200로 업데이트됨

**Given** 7개 projection 존재
**When** localDayKey 기준 내림차순 정렬 쿼리
**Then** 최신 날짜가 첫 번째

### 11.3 CachedRemoteEscalation 테스트

**Given** 빈 컨텍스트
**When** 5개의 RemoteEscalationEventPayload를 upsert
**Then** 5개의 CachedRemoteEscalation 존재

**Given** escalation(event A, occurredAt = T1, wasRecoveredWithinWindow = nil)
**When** 동일 occurredAt의 업데이트(wasRecoveredWithinWindow = true, recoveredAt = T2) upsert
**Then** 1개 레코드, wasRecoveredWithinWindow = true

**Given** 30일치 escalation 존재
**When** occurredAt 내림차순 정렬 쿼리
**Then** 최신 이벤트가 첫 번째

### 11.4 iOSModelContainer 테스트

**Given** inMemory = true
**When** makeModelContainer 호출
**Then** CachedMacState, CachedDayProjection, CachedRemoteEscalation 모두 등록됨

**Given** preview 컨테이너
**When** 샘플 데이터 삽입 후 @Query로 조회
**Then** 정상적으로 렌더링 가능

### 11.5 Retention 테스트

**Given** 40일치 CachedDayProjection 존재
**When** trimExpiredCache() 호출 (35일 보존)
**Then** 최근 35일만 남고, 5개 삭제됨

**Given** 35일치 CachedRemoteEscalation 존재
**When** trimExpiredCache() 호출 (30일 보존)
**Then** 최근 30일만 남고, 5개 삭제됨

### 11.6 CloudKitCacheSyncService 테스트

**Given** mock CloudKit database가 MacState record 반환
**When** syncMacState() 호출
**Then** CachedMacState에 올바른 값 저장

**Given** mock CloudKit database가 7개 projection record 반환
**When** syncRecentProjections() 호출
**Then** CachedDayProjection 7개 생성

## 12. 실패 테스트 구현

### 12.1 CloudKit fetch 실패

**Given** CloudKit fetch가 CKError.networkFailure 발생
**When** syncAll() 호출
**Then** 기존 캐시 유지, 에러 전파하지 않고 조용히 실패
**And** fetchedAt이 이전 시간 그대로 유지됨

### 12.2 잘못된 schemaVersion

**Given** CloudKit record의 schemaVersion이 999 (알 수 없는 버전)
**When** payload(from:) 호출
**Then** 필드 값은 정상 파싱되나, schemaVersion 필드에 999 저장
**And** 향후 호환성 체크 시 스킵 가능

### 12.3 hourlyAlertCountsData 손상

**Given** CachedDayProjection의 hourlyAlertCountsData가 "invalid json"
**When** 디코딩 시도
**Then** 빈 배열 [Int](repeating: 0, count: 24)로 폴백

### 12.4 동일 localDayKey 동시 upsert

**Given** 두 스레드에서 동일 localDayKey upsert 시도
**When** 동시에 insert 실행
**Then** SwiftData 충돌 없이 하나만 남음 (또는 마지막 것으로 덮어씀)

### 12.5 iCloud 비활성 상태

**Given** CKContainer.accountStatus() == .couldNotDetermine
**When** syncAll() 호출
**Then** CloudKit 접근 시도하지 않고 기존 캐시 유지

### 12.6 MacState record 누락

**Given** CloudKit에 MacState record가 아직 없음
**When** syncMacState() 호출
**Then** CachedMacState 기존 레코드 유지 (삭제하지 않음)

### 12.7 대량 projection 수신

**Given** CloudKit에서 100개의 projection record 반환 (비정상적으로 많음)
**When** syncRecentProjections(limit: 7) 호출
**Then** 최근 7개만 upsert, 나머지 무시

## 13. 파일 구성 계획

```
nudgewhipios/
├── Persistence/
│   └── iOSModelContainer.swift          // ModelContainer 팩토리 + preview
├── Models/
│   ├── CachedMacState.swift             // MacState 캐시 @Model
│   ├── CachedDayProjection.swift        // DayProjection 캐시 @Model
│   └── CachedRemoteEscalation.swift     // RemoteEscalation 캐시 @Model
└── Services/
    └── CloudKitCacheSyncService.swift   // CloudKit fetch → upsert 로직
```

의존성:
- `CloudKitDailyAggregateFetchConsumer` (Shared) — projection record → payload 변환
- `CloudKitConfiguration` (Shared) — container identifier
- `DeviceIdentityProvider` (Shared) — macDeviceID

## 14. 구현 순서

1. `CachedMacState`, `CachedDayProjection`, `CachedRemoteEscalation` @Model 생성
2. `iOSModelContainer` 팩토리 생성
3. `nudgewhipiosApp.swift`에 `.modelContainer` 주입
4. `CloudKitCacheSyncService` 기본 구현 (MacState sync만 먼저)
5. projection sync 구현
6. escalation sync 구현
7. retention trimming 구현
8. 각 단위 테스트 작성

## 15. 완료 기준

- [ ] CachedMacState @Model 생성 및 단위 테스트 통과
- [ ] CachedDayProjection @Model 생성 및 단위 테스트 통과
- [ ] CachedRemoteEscalation @Model 생성 및 단위 테스트 통과
- [ ] iOSModelContainer 생성 (shared + preview)
- [ ] nudgewhipiosApp에 .modelContainer 주입
- [ ] CloudKitCacheSyncService 기본 구현 (MacState sync)
- [ ] projection sync (최근 7일) 구현
- [ ] escalation sync (최근 30일) 구현
- [ ] retention trimming (35일 / 30일) 구현
- [ ] stale-while-revalidate 패턴 적용 (캐시 먼저 렌더링, 백그라운드 갱신)
- [ ] iCloud 미로그인 상태 처리
- [ ] CloudKit 네트워크 오류 시 기존 캐시 유지
- [ ] 실패 테스트 7개 이상 포함
- [ ] Preview 컨테이너에 샘플 데이터 포함
