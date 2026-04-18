# Sleep Preemptive Record 구현 계획서

- 문서 번호: 42
- 작성일: 2026-04-18
- 상태: 제안됨
- 작성자: cloudkit-sync
- 관련 문서: `docs/app/ios-companion-prd.md` §10, §12.3, `docs/architecture/cloudkit-sync-contract.md`

## 1. 개요

### 1.1 문제

Mac이 절전 모드(Sleep)에 진입하면 CloudKit 상태 업데이트가 불가능해진다. 이로 인해 iOS companion 앱은 Mac의 현재 상태를 알 수 없게 되며, 장기 미복귀 상황에서도 적절한 알림을 발송할 수 없다.

현재 `RuntimeStateController`에서 `.sleepDetected` 이벤트를 처리하여 `runtimeState = .suspendedSleepOrLock`으로 전환하지만, 이 상태가 CloudKit에 업로드되지 않는다.

### 1.2 해결

sleep/screen lock 이벤트 수신 시 MacState record를 CloudKit에 **선제적으로 업로드**한다.

- state = `"suspendedSleepOrLock"`
- stateChangedAt = 이벤트 발생 시각
- sequence = 증가

wake/screen unlock 이벤트 수신 시 정상 상태로 업데이트하여 iOS가 Mac이 복귀했음을 알 수 있게 한다.

### 1.3 영향받는 파일

- `nudgewhip/Services/SystemLifecycleMonitor.swift` — 이미 이벤트 감지 완료
- `nudgewhip/Services/RuntimeStateController.swift` — 이미 상태 전이 로직 완료
- `nudgewhip/Shared/Services/MacStateCloudKitWriter.swift` — save 메서드 활용
- `nudgewhip/Shared/Models/MacStatePayload.swift` — 이미 모델 정의 완료
- `nudgewhip/Shared/Services/DeviceIdentityProvider.swift` — macDeviceID 제공
- `nudgewhip/AppCoordinator.swift` — 이벤트 핸들러에서 CloudKit 업로드 추가 (신규)

### 1.4 iOS 측 대응

iOS는 MacState의 `state` 값을 읽어 화면에 표시한다:

- `state = "suspendedSleepOrLock"` → "오프라인" 상태 표시
- `state = "monitoring"` → "모니터링 중" 상태 표시
- 일정 시간(예: 1시간) 이상 마지막 업데이트가 없으면 "Mac이 꺼져 있거나 네트워크 연결이 끊겼을 수 있습니다" 안내

선택 사항: MacState 업데이트가 일정 시간(예: 2시간) 이상 없고, 마지막 상태가 `"monitoring"` 또는 `"alerting"`이었으면 iOS 자체 타이머로 로컬 알림 폴백.

## 2. 기능 구현 계획

### 2.1 Sleep 직전 MacState 업로드

#### 트리거

`NSWorkspace.willSleepNotification` 수신 시 `SystemLifecycleMonitor`가 `.sleepDetected` 이벤트 발생

#### 동작

1. `RuntimeStateController.handle(.sleepDetected)` 호출
2. 스냅샷에서 `runtimeState = .suspendedSleepOrLock` 확인
3. `MacStatePayload` 생성:
   ```swift
   MacStatePayload(
       macDeviceID: deviceIdentityProvider.macDeviceID(),
       state: "suspendedSleepOrLock",
       stateChangedAt: Date(),
       sequence: currentSequence + 1,
       breakUntil: snapshot.breakUntil,
       lastAlertAt: snapshot.lastAlertAt,
       schemaVersion: 1
   )
   ```
4. `macStateCloudKitWriter.save(payload)` 호출

#### 타이밍 문제

`willSleepNotification`은 sleep 진입 직전에 발생한다. CloudKit 업로드가 완료되기 전에 sleep될 수 있다.

#### 대응 전략

**대안 A: performExpiringActivity (추천)**

```swift
NSProcessInfo.processInfo.performExpiringActivity(withReason: "Save state before sleep") { expired in
    if !expired {
        Task {
            try? await macStateCloudKitWriter.save(payload)
        }
    }
}
```

- OS가 sleep을 최대 30초까지 지연시켜줌
- 실패해도 sleep은 막지 않음 (best-effort)

**대안 B: 로컬에 pending 상태 저장 후 wake 시 업로드**

- `UserDefaults` 또는 SwiftData에 `"pendingState": "suspendedSleepOrLock"` 저장
- wake 시 현재 상태와 비교하여 필요 시 재업로드

**추천 조합**: 대안 A (best-effort) + 대안 B (fallback)

### 2.2 Screen Lock 시 MacState 업로드

#### 트리거

`com.apple.screenIsLocked` 수신 시 `SystemLifecycleMonitor`가 `.screenLocked` 이벤트 발생

#### 동작

sleep과 동일하게 `runtimeState = .suspendedSleepOrLock`으로 전환 후 업로드

#### 차이

screen lock은 sleep이 아니므로 Mac이 계속 실행 중이다. 비동기 save가 충분히 완료될 시간이 있다.

```swift
// AppCoordinator.swift
func handleScreenLocked() async {
    runtimeStateController.handle(.screenLocked)
    let payload = createMacStatePayload(from: runtimeStateController.snapshot)
    try? await macStateCloudKitWriter.save(payload)
}
```

### 2.3 Wake 후 MacState 업로드

#### 트리거

`NSWorkspace.didWakeNotification` 또는 `com.apple.screenIsUnlocked` 수신 시

#### 동작

1. `RuntimeStateController.handle(.wakeDetected)` 또는 `.screenUnlocked` 호출
2. 스냅샷에서 `runtimeState`가 `.monitoring`, `.pausedManual`, `.pausedWhitelist` 등으로 복귀 확인
3. `MacStatePayload` 생성:
   ```swift
   MacStatePayload(
       macDeviceID: deviceIdentityProvider.macDeviceID(),
       state: runtimeStateController.snapshot.runtimeState.rawValue,
       stateChangedAt: Date(),
       sequence: currentSequence + 1,
       breakUntil: snapshot.breakUntil,
       lastAlertAt: snapshot.lastAlertAt,
       schemaVersion: 1
   )
   ```
4. `macStateCloudKitWriter.save(payload)` 호출

#### 추가: DailyProjection 재계산 (선택)

wake 직후 현재까지의 today projection을 재계산하여 업로드:

```swift
let todayProjection = dailyAggregateProjectionBuilder.buildDayProjection(for: Date())
try? await cloudKitDailyAggregateBackupWriter.save(todayProjection)
```

### 2.4 DailyProjection sleep 전 업로드 (선택)

#### 목적

sleep 전 현재까지의 today projection을 CloudKit에 저장하여, 이틀 연속 sleep 시 yesterday projection 누락을 방지

#### 구현

sleep 이벤트 처리 시:

```swift
let todayProjection = dailyAggregateProjectionBuilder.buildDayProjection(for: Date())
try? await cloudKitDailyAggregateBackupWriter.save(todayProjection)
// 그 다음 MacState 업로드
```

#### 주의사항

- wake 후 yesterday projection을 확인하여 누락 시 보정
- 데이터 중복 업로드 가능성 고려 (CloudKit 덮어쓰기로 해결)

## 3. 고려 사항

### 3.1 willSleep 타이밍

macOS는 `willSleepNotification` 후 즉시 sleep 진행한다. `CKOperation`이 완료되기 전에 sleep될 수 있다.

**대안 비교:**

| 대안 | 장점 | 단점 | 추천도 |
|------|------|------|--------|
| A: performExpiringActivity | OS가 sleep 지연 | 30초 제한, 보장 X | ⭐⭐⭐⭐⭐ |
| B: BGTaskScheduler | 백그라운드 실행 | sleep 전에는 보장 X | ⭐⭐ |
| C: 로컬 저장 후 wake 재시도 | 안정성 높음 | wake까지 지연 | ⭐⭐⭐⭐ |
| D: 동기 CKOperation | 즉시 완료 | UI 차단, 권장 X | ⭐ |

**추천**: 대안 C (안정성 우선) + 대안 A (best-effort)

### 3.2 Sequence 증가

sleep/wake 이벤트마다 `sequence`를 증가시켜 iOS가 최신 상태인지 판단 가능:

```swift
private var currentSequence: Int64 = 0

private func incrementSequence() -> Int64 {
    currentSequence += 1
    UserDefaults.standard.set(currentSequence, forKey: "nudgewhip.sequence")
    return currentSequence
}
```

### 3.3 네트워크 끊김

sleep 직전 네트워크가 이미 끊겨 있으면 업로드 불가:

- 에러 로그 기록
- wake 후 네트워크 복구 시 재시도
- 로컬 outbox에 pending 상태 저장

### 3.4 중복 이벤트 처리

빠른 sleep/wake 반복 또는 동시에 sleep + screenLock 이벤트 발생 시:

```swift
private var lastStateUploadTime: Date?
private let uploadDebounceInterval: TimeInterval = 0.5

private func shouldUploadState() -> Bool {
    guard let lastTime = lastStateUploadTime else { return true }
    return Date().timeIntervalSince(lastTime) > uploadDebounceInterval
}
```

### 3.5 강제 종료

Mac 강제 종료 시 `willSleepNotification` 없이 종료됨:

- iOS는 마지막 MacState 업데이트 시각으로 offline 판단
- 재시작 후 첫 상태 변경 시 CloudKit 업로드

## 4. Lifecycle (시퀀스 다이어그�)

```
[Mac] willSleepNotification 발생
  ↓
[Mac] SystemLifecycleMonitor → .sleepDetected 이벤트
  ↓
[Mac] RuntimeStateController.handle(.sleepDetected)
  → snapshot.runtimeState = .suspendedSleepOrLock
  → snapshot.suspended = true
  ↓
[Mac] AppCoordinator: MacStatePayload 생성
  → state = "suspendedSleepOrLock"
  → stateChangedAt = 현재 시각
  → sequence = N+1
  ↓
[Mac] performExpiringActivity 실행
  ↓
[Mac] MacStateCloudKitWriter.save(payload) // best-effort
  ↓
[CloudKit] MacState record 업데이트 (성공 시)
  ↓
[Mac] Sleep 진입

---
[CloudKit] MacState 업데이트 완료
  ↓
[iOS] (배경) CKQuerySubscription 트리거 또는 foreground fetch
  ↓
[iOS] MacState 읽기:
  → state = "suspendedSleepOrLock"
  → stateChangedAt = (sleep 직전 시각)
  ↓
[iOS] HomeView 업데이트:
  → 상태 배지: "오프라인"
  → 보조 문구: "Mac이 절전 모드입니다"
  → 마지막 업데이트: "(sleep 직전 시각)"
  ↓
[Mac] didWakeNotification 발생
  ↓
[Mac] SystemLifecycleMonitor → .wakeDetected 이벤트
  ↓
[Mac] RuntimeStateController.handle(.wakeDetected)
  → snapshot.runtimeState = .monitoring (또는 이전 상태)
  → snapshot.suspended = false
  ↓
[Mac] AppCoordinator: MacStatePayload 생성
  → state = "monitoring"
  → stateChangedAt = 현재 시각
  → sequence = N+2
  ↓
[Mac] MacStateCloudKitWriter.save(payload)
  ↓
[Mac] (선택) DailyProjection 재계산 및 업로드
  ↓
[CloudKit] MacState record 업데이트
  ↓
[iOS] (배경) CKQuerySubscription 트리거 또는 foreground fetch
  ↓
[iOS] MacState 읽기:
  → state = "monitoring"
  → stateChangedAt = (wake 시각)
  ↓
[iOS] HomeView 업데이트:
  → 상태 배지: "모니터링 중"
  → 보조 문구: "Mac이 정상적으로 모니터링 중입니다"
```

## 5. UI/UX 영향

### 5.1 iOS HomeView Hero Card

| Mac 상태 | 상태 배지 | 보조 문구 | 마지막 업데이트 |
|----------|-----------|-----------|------------------|
| `monitoring` | "모니터링 중" | "Mac이 정상적으로 모니터링 중입니다" | (현재) |
| `alerting` | "알림 발생" | "Mac에서 넛지를 표시 중입니다" | (현재) |
| `pausedManual` | "휴식 중" | "사용자가 일시정지했습니다" | (현재) |
| `suspendedSleepOrLock` | "오프라인" | "Mac이 절전 모드입니다" | (sleep 직전 시각) |
| 업데이트 1시간+ 경과 | "오프라인" | "Mac이 꺼져 있거나 네트워크 연결이 끊겼을 수 있습니다" | (마지막 업데이트 시각) |
| `limitedNoAX` | "설정 필요" | "Mac에서 접근성 권한이 필요합니다" | (현재) |

### 5.2 iOS Settings

마지막 동기화 시각이 sleep 직전 시각으로 표시됨:

```
연결 상태: 연결됨
마지막 동기화: 2026년 4월 18일 오후 3:45
Mac 상태: 오프라인 (절전 모드)
```

## 6. 라벨 문구

### 6.1 Sleep 직전 업로드 성공 시

- **상태**: "오프라인"
- **보조 문구**: "Mac이 절전 모드입니다"
- **마지막 업데이트**: "2026년 4월 18일 오후 3:45"

### 6.2 Wake 후

- **상태**: "모니터링 중"
- **보조 문구**: "Mac이 정상적으로 모니터링 중입니다"
- **마지막 업데이트**: "2026년 4월 18일 오후 4:10"

### 6.3 Sleep 전 업로드 실패 시 (iOS 관점)

- **상태**: "오프라인" (동일)
- **보조 문구**: "최근 상태 업데이트가 없어 오프라인으로 표시합니다"
- **마지막 업데이트**: "2026년 4월 18일 오후 2:30" (이전 업데이트 시각)

### 6.4 네트워크 오프라인 감지

- **상태**: "연결 끊김"
- **보조 문구**: "Mac과 동기화할 수 없습니다. 네트워크 연결을 확인하세요."

## 7. 클릭 시 액션

### 7.1 iOS "오프라인" 상태 카드

- **동작**: Settings 탭으로 이동
- **표시**: 연결 상태 진단, 재시도 버튼

### 7.2 iOS "다시 시도" 버튼

- **동작**: 수동 CloudKit fetch 실행
- **표시**: 로딩 인디케이터 → 성공/실패 메시지

## 8. 예외 처리

### 8.1 willSleep 업로드 미완료

- **대응**: wake 후 재업로드로 보상
- **로직**: wake 시 현재 상태가 `"suspendedSleepOrLock"`이 아니면 이전 상태로 간주하여 업로드

### 8.2 CloudKit quota 초과

- **대응**: wake 후 재시도
- **로직**: exponential backoff 적용

### 8.3 Sequence 충돌

- **대응**: iOS는 항상 가장 높은 `sequence` 값을 사용
- **로직**: CloudKit 쿼리 시 `sequence` 내림차순 정렬하여 최신 값 선택

### 8.4 빠른 sleep/wake 반복

- **대응**: debounce 처리 (500ms 내 재이벤트 무시)
- **로직**:
  ```swift
  private var lastEventTime: Date?
  private let debounceInterval: TimeInterval = 0.5

  func handleLifecycleEvent(_ event: NudgeWhipRuntimeEvent) {
      guard let lastTime = lastEventTime,
            Date().timeIntervalSince(lastTime) > debounceInterval else {
          return
      }
      lastEventTime = Date()
      // ... 업로드 로직
  }
  ```

### 8.5 Mac 강제 종료

- **대응**: `willSleepNotification` 없이 종료
- **iOS**: 마지막 업데이트 시각으로 offline 판단
- **Mac 재시작**: 첫 상태 변경 시 CloudKit 업로드

### 8.6 동시에 sleep + screenLock 이벤트

- **대응**: 중복 업로드 방지
- **로직**: 같은 상태(`"suspendedSleepOrLock"`)이면 coalesce

## 9. iOS-side 로컬 알림 폴백 (선택)

### 9.1 시나리오

Mac이 sleep되어 CloudKit 업데이트가 안 된 상태에서 장기 미복귀 지속

### 9.2 폴백 로직

iOS 자체 타이머로 마지막 MacState 업데이트 후 N시간 경과 시 로컬 알림 발송

### 9.3 조건

- 마지막 MacState 업데이트 후 2시간 이상 경과
- 마지막 상태가 `"monitoring"` 또는 `"alerting"`이었음
- 사용자가 `"pausedManual"`, `"pausedWhitelist"` 상태가 아님
- iOS 앱이 foreground에 있지 않음

### 9.4 구현

```swift
// iOS 측
func checkForLongAbsence() {
    guard let lastUpdate = lastMacStateUpdateDate else { return }

    let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
    guard timeSinceUpdate > 2 * 60 * 60 else { return } // 2시간

    guard let lastState = lastMacState,
          ["monitoring", "alerting"].contains(lastState.state) else { return }

    // 로컬 알림 발송
    let content = UNMutableNotificationContent()
    content.title = "Mac 확인 필요"
    content.body = "Mac에서 오랫동안 활동이 감지되지 않았습니다. 확인이 필요할 수 있습니다."
    content.sound = .default

    let request = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: content,
                                        trigger: nil)
    UNUserNotificationCenter.current().add(request)
}
```

### 9.5 타이머 트리거

- 앱 background 진입 시 타이머 시작
- foreground 진입 시 타이머 취소
- 백그라운드 작업에서 주기적 체크 (예: 1시간마다)

## 10. 테스트 구현

### 10.1 단위 테스트

```swift
func testSleepDetected_UploadsSuspendedState() async throws {
    // Given
    let mockWriter = MockMacStateCloudKitWriter()
    let controller = AppCoordinator(
        macStateCloudKitWriter: mockWriter,
        deviceIdentityProvider: mockDeviceIdentityProvider
    )

    // When
    controller.handle(.sleepDetected)

    // Then
    XCTAssertTrue(mockWriter.lastSavedPayload?.state == "suspendedSleepOrLock")
    XCTAssertTrue(mockWriter.lastSavedPayload?.sequence == expectedSequence)
}

func testWakeDetected_UploadsMonitoringState() async throws {
    // Given
    let mockWriter = MockMacStateCloudKitWriter()
    let controller = AppCoordinator(
        macStateCloudKitWriter: mockWriter,
        deviceIdentityProvider: mockDeviceIdentityProvider
    )

    // When
    controller.handle(.wakeDetected)

    // Then
    XCTAssertTrue(mockWriter.lastSavedPayload?.state == "monitoring")
    XCTAssertTrue(mockWriter.lastSavedPayload?.sequence == expectedSequence + 1)
}
```

### 10.2 통합 테스트

```swift
func testSleepWakeCycle_UpdatesMacState() async throws {
    // Given
    let monitor = SystemLifecycleMonitor()
    let controller = AppCoordinator(...)
    monitor.start(onEvent: { event in
        controller.handle(event)
    })

    // When
    NotificationCenter.default.post(name: NSWorkspace.willSleepNotification, object: nil)
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기

    // Then
    let sleepState = try await fetchMacStateFromCloudKit()
    XCTAssertEqual(sleepState.state, "suspendedSleepOrLock")

    // When
    NotificationCenter.default.post(name: NSWorkspace.didWakeNotification, object: nil)
    try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기

    // Then
    let wakeState = try await fetchMacStateFromCloudKit()
    XCTAssertEqual(wakeState.state, "monitoring")
}
```

## 11. 실패 테스트 구현

### 11.1 CloudKit 업로드 실패

```swift
func testSleepDetected_CloudKitFailure_DoesNotBlockSleep() async throws {
    // Given
    let failingWriter = FailingMacStateCloudKitWriter()
    let controller = AppCoordinator(macStateCloudKitWriter: failingWriter, ...)

    // When
    controller.handle(.sleepDetected)

    // Then
    // sleep은 계속 진행되어야 함
    // 에러가 로그되어야 함
    XCTAssertTrue(failingWriter.errorLogged)
}
```

### 11.2 빠른 sleep/wake 반복

```swift
func testRapidSleepWake_OnlyLastStateUploaded() async throws {
    // Given
    let mockWriter = MockMacStateCloudKitWriter()
    let controller = AppCoordinator(macStateCloudKitWriter: mockWriter, ...)

    // When
    controller.handle(.sleepDetected)
    controller.handle(.wakeDetected)
    controller.handle(.sleepDetected)
    controller.handle(.wakeDetected)
    try await Task.sleep(nanoseconds: 2_000_000_000) // 2초 대기

    // Then
    // debounce로 인해 마지막 상태만 업로드
    XCTAssertEqual(mockWriter.saveCallCount, 1)
}
```

### 11.3 네트워크 오프라인

```swift
func testSleepDetected_Offline_PendingStateSaved() async throws {
    // Given
    let offlineWriter = OfflineMacStateCloudKitWriter()
    let controller = AppCoordinator(macStateCloudKitWriter: offlineWriter, ...)

    // When
    controller.handle(.sleepDetected)

    // Then
    // 로컬에 pending 상태 저장
    XCTAssertTrue(offlineWriter.pendingState != nil)

    // When (네트워크 복구)
    offlineWriter.simulateNetworkRecovery()

    // Then
    // pending 상태 업로드
    XCTAssertTrue(offlineWriter.uploadedPendingState)
}
```

### 11.4 동시 sleep + screenLock

```swift
func testConcurrentSleepAndScreenLock_NoDuplicateUploads() async throws {
    // Given
    let mockWriter = MockMacStateCloudKitWriter()
    let controller = AppCoordinator(macStateCloudKitWriter: mockWriter, ...)

    // When (동시에 발생)
    Task { controller.handle(.sleepDetected) }
    Task { controller.handle(.screenLocked) }
    try await Task.sleep(nanoseconds: 2_000_000_000)

    // Then
    // 중복 업로드 방지
    XCTAssertEqual(mockWriter.saveCallCount, 1)
}
```

## 12. 완료 기준

- [ ] `AppCoordinator`에 sleep/wake/screenLock/screenUnlocked 이벤트 핸들러 추가
- [ ] sleep 이벤트 수신 시 `MacStatePayload(state: "suspendedSleepOrLock")` 생성 및 CloudKit 업로드
- [ ] wake 이벤트 수신 시 `MacStatePayload(state: "monitoring")` 생성 및 CloudKit 업로드
- [ ] screenLock/screenUnlocked 이벤트 동일하게 처리
- [ ] `performExpiringActivity`를 사용하여 sleep 전 업로드 시간 확보
- [ ] 로컬에 pending 상태 저장 후 wake 시 재시도 로직 구현
- [ ] `sequence` 증가 로직 구현 및 UserDefaults에 영구 저장
- [ ] debounce 처리로 빠른 이벤트 반복 시 중복 업로드 방지
- [ ] iOS HomeView에서 `state = "suspendedSleepOrLock"` 시 "오프라인" 표시
- [ ] iOS Settings에서 마지막 동기화 시각 표시
- [ ] iOS에서 "오프라인" 상태 카드 탭 시 Settings로 이동
- [ ] iOS에서 "다시 시도" 버튼으로 수동 CloudKit fetch
- [ ] 단위 테스트: sleep → `suspendedSleepOrLock` 확인
- [ ] 단위 테스트: wake → `monitoring` 확인
- [ ] 단위 테스트: sequence 증가 확인
- [ ] 통합 테스트: sleep/wake cycle 전체 흐름 확인
- [ ] 실패 테스트: CloudKit 업로드 실패 시 sleep 막지 않음 확인
- [ ] 실패 테스트: 빠른 sleep/wake 반복 시 마지막 상태만 유효 확인
- [ ] 실패 테스트: 네트워크 오프라인 시 wake 후 재시도 확인
- [ ] 실패 테스트: 동시 sleep + screenLock 시 중복 업로드 방지 확인
- [ ] (선택) iOS 로컬 알림 폴백 구현
- [ ] (선택) wake 후 DailyProjection 재계산 및 업로드

## 13. 향후 고려사항

### 13.1 Wake 후 Today Projection 재계산

wake 시 현재까지의 today projection을 재계산하여 업로드하면 iOS가 더 정확한 통계를 볼 수 있다.

### 13.2 이틀 연속 Sleep 시 Yesterday Projection 보정

Mac이 이틀 연속 sleep하면 yesterday projection이 누락될 수 있다. wake 후 누락된 projection을 보정하는 로직을 고려한다.

### 13.3 Background Task Scheduler 활용

iOS 13+에서 `BGTaskScheduler`를 사용하여 백그라운드에서 주기적으로 MacState를 확인하고 로컬 알림을 발송할 수 있다.

### 13.4 Network Reachability 감지

Network Reachability를 감지하여 오프라인에서 온라인으로 전환 시 자동으로 CloudKit 동기화를 시도한다.
