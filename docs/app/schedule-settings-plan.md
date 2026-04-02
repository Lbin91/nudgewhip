# Schedule Settings Plan

- Version: 0.1
- Last Updated: 2026-04-03
- Owner: `macos-core` + `swiftui-designer`
- Scope: Phase 1 schedule-based monitoring window (`start time` / `end time`) for the macOS app

## 1. Purpose

- 사용자가 Nudge의 감시 시간대를 직접 제한할 수 있게 한다.
- 특정 시간대 밖에서는 monitoring/alert가 동작하지 않도록 제어한다.
- “일하는 시간에만 넛지를 받고 싶다”는 현실적인 사용 패턴을 반영한다.

## 2. Why this matters

현재는 사용자가 앱을 켜 두면 감시와 알림이 시간대 제한 없이 동작할 수 있다.
이 방식은 아래 문제를 만든다.

- 야간/휴식 시간에도 감시가 살아 있다고 느낄 수 있다.
- 업무 시간 외 사용 시 피로도가 올라간다.
- 사용자가 schedule 기능을 원해도 설정 경로가 없다.

## 3. Product goals

1. 사용자가 하루 감시 시작/종료 시각을 설정할 수 있다.
2. schedule 밖에서는 alert loop가 완전히 정지한다.
3. schedule 안으로 다시 들어오면 자동으로 monitoring이 재개된다.
4. 자정을 넘기는 시간대(예: 22:00 ~ 06:00)도 처리 가능해야 한다.

## 4. Non-goals

- 요일별 반복 스케줄
- 다중 시간대(block) 스케줄
- 캘린더/Focus mode 연동
- iOS companion schedule sync

## 5. User-facing behavior

### 5.1 기본 동작

- schedule이 꺼져 있으면 현재처럼 항상 감시 가능
- schedule이 켜져 있으면:
  - 지정 시간대 **안**: monitoring 가능
  - 지정 시간대 **밖**: `pausedSchedule`

### 5.2 상태 표현

- 메뉴바 상태:
  - `pausedSchedule` 전용 아이콘
  - 상태 설명 문구 필요
- 드롭다운:
  - 현재 schedule 범위 표시
  - 언제 자동 재개되는지 설명 가능하면 표시

### 5.3 알림 동작

- schedule 밖에서는:
  - idle deadline 취소
  - visual alert 중단
  - notification/TTS 채널 중단
- schedule 안으로 복귀 시:
  - baseline 재설정
  - idle countdown 다시 시작

## 6. UX proposal

설정 위치:
- 메뉴바 드롭다운 Quick Controls 또는 별도 Settings 화면

MVP 구성:
- `Schedule` 토글
- `Start time`
- `End time`

권장 UI:
- Toggle + 2개 `DatePicker(.hourAndMinute)` 또는 compact time picker

### 6.1 Validation

- 시작/종료 시간이 같으면 허용하지 않음
- 자정 넘김 허용
  - 예: 22:00 ~ 06:00
- 저장 즉시 runtime 반영

## 7. Data contract

현재 `UserSettings`에 이미 있는 필드:

- `scheduleEnabled`
- `scheduleStartSecondsFromMidnight`
- `scheduleEndSecondsFromMidnight`

원칙:
- schedule은 SwiftData source of truth에 저장
- UI는 seconds-from-midnight ↔ local time picker 변환 필요

## 8. Runtime contract

### 8.1 New state usage

이미 코드상 존재:
- `pausedSchedule`
- `scheduleWindowEntered`
- `scheduleWindowExited`

의도 의미:
- `scheduleWindowEntered`: 감시 가능 시간대 밖으로 들어감 → `pausedSchedule`
- `scheduleWindowExited`: 감시 가능 시간대 안으로 다시 들어옴 → `monitoring`

### 8.2 Boundary rules

- schedule 경계 시각에 타이머 재평가
- wake/unlock 후에도 schedule 재평가
- 앱 foreground 복귀 시에도 schedule 재평가

### 8.3 Baseline reset

schedule 밖 → 안으로 복귀 시:
- 기존 `lastInputAt`를 그대로 쓰지 않음
- 현재 시각 기준으로 baseline 재설정

## 9. Edge cases

- 자정 넘김
- 사용자가 schedule 변경 중 이미 alerting 상태
- sleep/wake 중 경계 시각 통과
- 시스템 timezone/clock 변경
- 앱 재실행 시 schedule 즉시 반영

## 10. Acceptance Criteria

- 사용자가 시작/종료 시각을 저장하면 앱 재실행 후에도 유지된다.
- schedule 밖에서는 `pausedSchedule` 상태가 노출된다.
- schedule 안으로 들어오면 monitoring이 자동 재개된다.
- alerting 중 schedule 밖으로 나가면 즉시 알림이 종료된다.
- 자정 넘김 schedule이 올바르게 동작한다.

## 11. Recommended implementation order

1. 설정 UI 노출 위치 결정
2. time picker UI 추가
3. seconds-from-midnight 변환 유틸 추가
4. 저장 즉시 `UserSettings` 반영
5. `MenuBarViewModel -> IdleMonitor.apply(settings:)` 경로로 runtime 즉시 반영
6. `pausedSchedule` 문구/UI polish
7. boundary test 추가

## 12. Verification plan

Unit:
- start/end 변환 테스트
- 자정 넘김 판단 테스트
- boundary transition 테스트

Integration:
- alerting 중 schedule entry/exit
- wake 후 schedule 재계산

Manual:
- 10초 테스트 threshold + schedule on
- 현재 시각 기준 안/밖 전환 확인
- 자정 넘김 시나리오 확인
