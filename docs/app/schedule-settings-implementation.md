# Schedule Settings — 구현 문서

- Version: 1.0
- Last Updated: 2026-04-03
- Status: 구현 완료
- 관련 Plan: `schedule-settings-plan.md`

## 1. 기능 개요

사용자가 하루 중 Nudge의 유휴 감시가 활성화되는 **시간대(start / end)**를 설정할 수 있다.
설정된 시간대 밖에서는 monitoring과 alert이 완전히 정지하며, 시간대 안으로 진입하면 자동으로 감시가 재개된다.

**기본값:** 비활성화 (`scheduleEnabled = false`)

## 2. 데이터 모델

`UserSettings` (SwiftData `@Model`)

| 필드 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `scheduleEnabled` | `Bool` | `false` | 스케줄 활성화 여부 |
| `scheduleStartSecondsFromMidnight` | `Int` | `32400` (09:00) | 자정 이후 시작 시간(초) |
| `scheduleEndSecondsFromMidnight` | `Int` | `61200` (17:00) | 자정 이후 종료 시간(초) |

초 단위 저장 이유: `Date` 객체는 날짜 컴포넌트를 포함하므로, "매일 반복" 스케줄에는 적합하지 않다.
초 단위 정수로 저장하면 자정 기준 오프셋으로 시간대를 계산할 수 있다.

### 변환 헬퍼

`ContentView`에서 `Date` ↔ `secondsFromMidnight` 변환을 수행한다:

```swift
// 초 → Date (UI 표시용)
private func dateFromSeconds(_ seconds: Int) -> Date {
    let startOfDay = Calendar.current.startOfDay(for: .now)
    return startOfDay.addingTimeInterval(TimeInterval(seconds))
}

// Date → 초 (저장용)
private func secondsFromMidnight(for date: Date) -> Int {
    Calendar.current.component(.hour, from: date) * 3600
        + Calendar.current.component(.minute, from: date) * 60
}
```

## 3. 상태 기계

`RuntimeStateController`에서 `pausedSchedule` 상태를 관리한다.

### 상태 전이

```
                     scheduleEnabled=true
                     AND 현재 시각이 범위 밖
 monitoring ────────────────────────────────────► pausedSchedule
     │                                                │
     │  scheduleEnabled=false                         │ scheduleEnabled=false
     │  OR 범위 안으로 진입                            │ OR 범위 안으로 진입
     │                                                │
     ◄────────────────────────────────────────────────┘
```

### 관련 이벤트

| 이벤트 | 트리거 | 결과 |
|--------|--------|------|
| `scheduleWindowEntered` | 현재 시각이 스케줄 범위 밖 | `pausedSchedule = true`, 모니터링 정지 |
| `scheduleWindowExited` | 현재 시각이 스케줄 범위 안 | `pausedSchedule = false`, 모니터링 재개 |

### 자정 넘김 지원

`start > end`인 경우 (예: 22:00 ~ 06:00), 자정을 넘나드는 스케줄로 처리한다:

```swift
if scheduleStart <= scheduleEnd {
    inWindow = seconds >= scheduleStart && seconds < scheduleEnd
} else {
    // 자정 넘김: 22:00~24:00 OR 00:00~06:00
    inWindow = seconds >= scheduleStart || seconds < scheduleEnd
}
```

## 4. 서비스 계층

### IdleMonitor

**스케줄 관련 프로퍼니티:**

| 프로퍼티 | 타입 | 가시성 | 설명 |
|----------|------|--------|------|
| `scheduleEnabled` | `Bool` | `private(set)` | 스케줄 활성화 여부 |
| `scheduleStart` | `TimeInterval` | `private(set)` | 시작 시간(초) |
| `scheduleEnd` | `TimeInterval` | `private(set)` | 종료 시간(초) |

**주요 메서드:**

#### `checkSchedule(at:)`

현재 시간이 스케줄 윈도우 내/외인지 판단하여 상태 전이를 수행한다.
`applySettings()`에서 호출되어 설정 변경 즉시 반영한다.

#### `scheduleNextBoundary(from:)`

다음 스케줄 경계 시각(start 또는 end)에 `DispatchWorkItem`을 예약한다.
경계 시각에 도달하면 `checkSchedule()`이 자동 호출되어 상태가 전이된다.
`DispatchQueue.main.asyncAfter`를 사용하므로 앱이 실행 중일 때만 동작한다.

#### `applySettings(_:at:)`

설정 변경 시 호출. `checkSchedule()`으로 즉시 반영하며,
`idleThreshold`가 실제로 변경된 경우에만 `scheduleIdleDeadline()`을 재호출한다.

**중요:** threshold 미변경 시 `scheduleIdleDeadline()`을 생략하여,
`delay=0`로 인한 즉시 `fireIdleDeadline` 트리거와 SwiftUI 렌더링 충돌을 방지한다.

### MenuBarViewModel

`apply(settings:)`를 통해 `IdleMonitor.applySettings()`를 호출한다.
`ContentView.task(id:)`에서 설정 변경 감지 시 자동 호출된다.

## 5. UI 계층

### 메뉴바 드롭다운

`QuickControlsView`에 스케줄 컨트롤이 위치한다.

```
┌─ Settings ────────────────────────────┐
│ Schedule           09:00 - 17:00      │
│ ☐ Use schedule                        │
│ Start  [09:00 ▾]                      │
│ End   [17:00 ▾]                        │
└───────────────────────────────────────┘
```

| 컴포넌트 | 타입 | 설명 |
|----------|------|------|
| 스케줄 텍스트 | `Text` | 활성: "09:00 - 17:00", 비활성: "Off" |
| Use schedule | `Toggle` | `scheduleEnabled` 바인딩 |
| Start / End | `DatePicker(.hourAndMinute)` | `.compact` 스타일, 비활성 시 `disabled` |

### Binding 흐름

```
ContentView (@Query settings)
  → scheduleEnabledBinding, scheduleStartTimeBinding, scheduleEndTimeBinding
    → QuickControlsView
      → Toggle / DatePicker
        → updateSettings() { settings.field = newValue; save(); apply() }
```

`updateSettings()`는 SwiftData 컨텍스트에 즉시 저장하고 `apply(settings:)`를 호출하여
런타임에 즉시 반영한다.

## 6. 상태 표시

`StatusSummaryView`에서 스케줄 일시정지 상태를 표시한다:

| 상태 | 아이콘 | 타이틀 | 설명 |
|------|--------|--------|------|
| `pausedSchedule` | `clock.badge` | "Waiting for schedule" | "Outside the active schedule..." |

## 7. 엣지 케이스

| 시나리오 | 동작 |
|----------|------|
| start == end | 항상 범위 밖으로 간주 (모니터링 안함) |
| start > end (예: 22:00~06:00) | 자정 넘김으로 정상 동작 |
| 스케줄 비활성화 → 활성화 | 즉시 현재 시간 기준으로 범위 판단 |
| alerting 중 스케줄 범위 밖 진입 | alert 즉시 종료, `pausedSchedule` 전이 |
| 앱 수면/깨어남 | 깨어날 때 `checkSchedule()` 재실행 |
| 설정 변경 없이 드롭다운 재오픈 | `scheduleIdleDeadline()` 생략 (블로킹 방지) |

## 8. 테스트

단위 테스트에서 `IdleMonitor`의 스케줄 동작을 검증한다:

- `idleMonitorSuspendsAndResumesAcrossSystemLifecycleEvents` — lifecycle 이벤트 시 스케줄 재계산
- `runtimeReducerHonorsPriorityRulesAndRecoveryFlow` — `pausedSchedule` 상태 전이 검증

### 수동 테스트 가이드

1. 10초 threshold 설정
2. 스케줄 활성화, 현재 시간 ±1분으로 start/end 설정
3. 범위 밖에서 `pausedSchedule` 상태 확인
4. 시간 경과 후 범위 진입 시 자동 `monitoring` 전이 확인
5. `alerting` 중 스케줄 범위 밖으로 시간 경과 시 alert 자동 종료 확인
