# Nudge v0.2 — Quality & Stabilization Plan

- Version: draft-1
- Last Updated: 2026-04-09
- Status: draft
- Owner: engineering
- Precedes: v0.3 (Pet/Gamification), v1.0 (Pro/iOS)

## 1. Purpose

v0.1.0 오픈 베타 이후 첫 업데이트. 핵심 목표는 **일상 사용에서 불편한 지점을 제거**하고 **데이터 기반 피드백 루프**를 여는 것이다.

새로운 화려한 기능보다는, 이미 구현된 코어 위에서 실사용 완성도를 끌어올린다.

## 2. Design Principles

1. **베타 유저가 "불편하다"고 느낄 만한 것을 먼저 고친다**
2. **데이터 모델은 이미 있으니 UI/UX만 완성한다** (DailyStats)
3. **엣지케이스는 자동화 테스트로 영구 방어한다**
4. **Free 영역의 기능만 다룬다** (Pro 게이팅은 v1.0)

## 3. Scope Overview

| # | Feature | Priority | Complexity | Blocks |
|---|---------|----------|------------|--------|
| F1 | Statistics Dashboard v1 | P0 | Medium | — |
| F2 | Countdown Overlay Position | P1 | Low | — |
| F3 | 엣지케이스 안정화 | P0 | Medium | — |
| F4 | 테스트 커버리지 강화 | P0 | Medium | F3와 병렬 |

### Non-goals

- 펫 성장 시스템, 감정 확장 (→ v0.3)
- CloudKit, iOS 연동, StoreKit (→ v1.0)
- 원격 에스컬레이션, 수동 휴식 모드 (→ v1.0 Pro)
- 요일별 스케줄, 다중 시간대 (향후 고려)
- 랜딩 페이지, 마케팅 (→ v0.3과 병렬 가능)

---

## 4. Feature Specifications

### F1. Statistics Dashboard v1

**현재 상태**: `DailyStats` 값 타입과 `derive()` 메서드가 구현됨. `DailySummaryView`에 최소 정보만 표시됨.

**목표**: 드롭다운 또는 별도 윈도우에서 **일간/주간 통계**를 시각적으로 확인할 수 있게 한다.

#### 4.1.1 UI 구성

```
┌─────────────────────────────────────┐
│  📊 이번 주 통계                     │
│                                     │
│  ┌─ 오늘 ────────────────────────┐  │
│  │  포커스    3h 24m             │  │
│  │  알림      4회                │  │
│  │  회복률    75%                │  │
│  │  최장 집중  1h 12m            │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─ 주간 바차트 ────────────────┐   │
│  │  월 ██                        │  │
│  │  화 █████                     │  │
│  │  수 ████████                  │  │
│  │  목 ████                      │  │
│  │  금 ██████                    │  │
│  │  토 ██                        │  │
│  │  일  ← 오늘                   │  │
│  └───────────────────────────────┘  │
│                                     │
│  주간 합계  14h 30m  |  알림 23회  │
│                                     │
└─────────────────────────────────────┘
```

#### 4.1.2 데이터 소스

| 항목 | 소스 | 계산 |
|------|------|------|
| 포커스 시간 | `FocusSession.focusDuration()` | `DailyStats.totalFocusDuration` |
| 알림 횟수 | `FocusSession.alertCount` | `DailyStats.alertCount` |
| 회복률 | `AlertingSegment.recoveredAt` | `recoverySampleCount / alertCount` |
| 최장 집중 | `DailyStats.longestFocusDuration` | 이미 구현됨 |
| 세션 수 | `DailyStats.completedSessionCount` | 이미 구현됨 |
| 평균 회복 시간 | `DailyStats.recoveryDurationTotal / recoverySampleCount` | derive()에 추가 필요 |

#### 4.1.3 동작 명세

| 동작 | 상세 |
|------|------|
| 진입 | 드롭다운 "통계 보기" 버튼 → Settings 윈도우 Statistics 탭, 또는 별도 팝오버 |
| 기간 전환 | 탭 세그먼트: 오늘 / 이번 주 / 지난 7일 |
| 차트 | SwiftUI Canvas 또는 SF Symbols gauge로 간단한 바차트 |
| 데이터 갱신 | 세션 종료/알림 이벤트 시 자동 갱신 |
| 빈 데이터 | "아직 기록이 없습니다" 안내 |

#### 4.1.4 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `Views/DailySummaryView.swift` | 기존 뷰 개선 또는 교체 |
| `Views/StatisticsDashboardView.swift` | **신규** — 통계 대시보드 메인 뷰 |
| `Views/Components/CircularGaugeView.swift` | 기존 컴포넌트 재활용 |
| `Shared/Models/DailyStats.swift` | `averageRecoveryDuration` 계산 추가 |
| `Settings/SettingsRootView.swift` | Statistics 탭 추가 |
| `Shared/Localization/AppStrings.swift` | 통계 관련 문자열 추가 |
| `Shared/Localization/AppFormatting.swift` | 시간 포맷 유틸 추가 (h시 m분 등) |

---

### F2. Countdown Overlay Position

**현재 상태**: `CountdownOverlayController.positionPanel()`은 overlay를 메인 화면의 좌상단에 고정 배치한다. 사용자가 위치를 바꿀 수 없다.

**목표**: Settings에서 countdown overlay 위치를 **네 모서리 중 하나**로 선택할 수 있게 한다.

#### 4.2.1 UI 구성

Settings Monitoring 섹션에 추가:

```
┌─────────────────────────────────────┐
│  카운트다운 오버레이 위치            │
│                                     │
│  [좌상단] [우상단]                  │
│  [좌하단] [우하단]                  │
│                                     │
│  ℹ️ 모든 화면에서 같은 위치에        │
│     고정 표시됩니다                  │
└─────────────────────────────────────┘
```

#### 4.2.2 동작 명세

| 동작 | 상세 |
|------|------|
| 위치 선택 | `topLeft`, `topRight`, `bottomLeft`, `bottomRight` 중 1개 선택 |
| 실시간 반영 | 값 변경 즉시 현재 표시 중인 overlay panel 재배치 |
| 기본값 | `topLeft` 유지 (기존 동작과 동일) |
| 화면 기준 | 현재 활성 화면이 아니라 `NSScreen.main ?? NSScreen.screens.first` 기준 유지 |
| 멀티 모니터 | v0.2에서는 "주요 화면(primary screen) 한 장만 표시" 정책 유지 |
| 저장 | `UserSettings`에 rawValue 저장 |

#### 4.2.3 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `Shared/Models/UserSettings.swift` | overlay 위치 enum + persisted rawValue 추가 |
| `Views/CountdownOverlayController.swift` | panel origin 계산을 corner별로 분기 |
| `Services/MenuBarViewModel.swift` | 설정값 노출 및 변경 반영 |
| `Settings/SettingsRootView.swift` | 위치 선택 UI 추가 |
| `Settings/SettingsViewModel.swift` | overlay 위치 저장/적용 |
| `Onboarding/Views/BasicSetupStepView.swift` | 필요시 v0.2 범위 밖, 기본값만 사용 |
| `Shared/Localization/AppStrings.swift` | 위치 선택 관련 문자열 추가 |

#### 4.2.4 Corner 계산 규칙

| 옵션 | 좌표 계산 |
|------|-----------|
| `topLeft` | `visibleFrame.minX + inset`, `visibleFrame.maxY - inset - panelHeight` |
| `topRight` | `visibleFrame.maxX - inset - panelWidth`, `visibleFrame.maxY - inset - panelHeight` |
| `bottomLeft` | `visibleFrame.minX + inset`, `visibleFrame.minY + inset` |
| `bottomRight` | `visibleFrame.maxX - inset - panelWidth`, `visibleFrame.minY + inset` |

---

### F3. 엣지케이스 안정화

v0.1.0에서 식별된 잠재적 불안정 영역을 정비한다.

#### 4.3.1 Sleep/Wake 전환

| 시나리오 | 기대 동작 | 검증 항목 |
|----------|----------|-----------|
| Sleep 진입 | `suspendedSleepOrLock` 전이, deadline 취소 | 타이머 무효화 확인 |
| Wake 복귀 | 즉시 `monitoring` 복귀, fresh baseline | 이전 idle 시간 무시, lastInputAt 갱신 |
| Sleep 중 알림 | 절대 발생하지 않음 | deadline nil 확인 |
| 연속 sleep/wake | 상태 누수 없음 | 10회 반복 테스트 |

#### 4.3.2 권한 해제/재부여

| 시나리오 | 기대 동작 | 검증 항목 |
|----------|----------|-----------|
| 권한 해제 | `limitedNoAX` 전이, 모니터링 중단 | 이벤트 핸들러 해제 |
| 권한 재부여 | `monitoring` 복귀, fresh baseline | 즉시 이벤트 수신 재개 |
| 알림 중 권한 해제 | 알림 즉시 dismiss | overlay 창 닫힘 |

#### 4.3.3 스케줄 자정 경계

| 시나리오 | 기대 동작 | 검증 항목 |
|----------|----------|-----------|
| 22:00~06:00 스케줄 | 자정 넘김 정상 동작 | interval 계산 확인 |
| 경계 진입 | 정확한 시간에 `pausedSchedule` 전이 | 타이머 정확도 ±5초 |
| 경계 이탈 | 정확한 시간에 `monitoring` 복귀 | fresh baseline |
| 스케줄 변경 | 즉시 새 스케줄 적용 | 이전 타이머 취소 |

#### 4.3.4 Fatigue Guardrails

| 시나리오 | 기대 동작 | 검증 항목 |
|----------|----------|-----------|
| 시간당 알림 한도 도달 | 알림 중단, 조용한 모드 | 카운터 리셋 시점 확인 |
| 시간당 알림 한도 미달 | 정상 알림 | 카운터 정확도 |
| 경계 시간 (59분→60분) | 정확한 리셋 | 시간 기반 슬라이딩 윈도 |

#### 4.3.5 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `Services/IdleMonitor.swift` | 엣지케이스 방어 로직 |
| `Services/RuntimeStateController.swift` | 상태 전이 안정성 |
| `Services/SystemLifecycleMonitor.swift` | Sleep/Wake 핸들링 |
| `Services/AlertManager.swift` | 권한 변경 시 알림 정리 |
| `Services/PermissionManager.swift` | 권한 변경 통지 개선 |

---

### F4. 테스트 커버리지 강화

v0.2에서 수정하는 모든 영역에 대해 **회귀 방지 테스트**를 작성한다.

#### 4.4.1 단위 테스트

| 테스트 대상 | 테스트 케이스 수 | 핵심 시나리오 |
|-------------|-----------------|--------------|
| `DailyStats.derive()` | 8+ | 빈 세션, 자정 경계 세션, 긴 세션 분할 |
| `SessionTracker` | 6+ | 시작/종료, 알림 기록, 회복 기록, 중복 세션 |
| `CountdownOverlayController` 위치 계산 | 4+ | 네 모서리 origin 계산 |
| `IdleMonitor` 엣지 | 10+ | sleep/wake, 권한, 스케줄 경계 |

#### 4.4.2 통합 테스트

| 시나리오 | 검증 항목 |
|----------|----------|
| Full alert cycle | idle → gentle → strong → recovery → 통계 기록 |
| Pause/Resume lifecycle | 수동/시간제한/스케줄 |
| Settings 변경 전파 | 사운드, 펫 모드, overlay 위치 변경이 즉시 반영 |

#### 4.4.3 관련 파일

| 파일 | 변경 내용 |
|------|----------|
| `nudgewhipTests/DailyStatsTests.swift` | **신규** |
| `nudgewhipTests/SessionTrackerTests.swift` | **신규** |
| `nudgewhipTests/CountdownOverlayPositionTests.swift` | **신규** |
| `nudgewhipTests/IdleMonitorEdgeCaseTests.swift` | **신규** |
| `nudgewhipTests/IntegrationTests.swift` | **신규** |

---

## 5. Implementation Phases

### Phase 1: 기반 정비 (F3 + F4 일부)

엣지케이스 안정화를 먼저 해야 후속 기능 개발이 안전하다.

| 작업 | 담당 에이전트 | 산출물 |
|------|-------------|--------|
| Sleep/Wake, 권한, 스케줄 엣지케이스 수정 | `macos-core` | IdleMonitor, RuntimeStateController 수정 |
| DailyStats, SessionTracker 단위 테스트 | `qa-integrator` | Tests/*.swift |
| IdleMonitor 엣지케이스 테스트 | `qa-integrator` | IdleMonitorEdgeCaseTests.swift |

### Phase 2: 사용자 기능 (F1 + F2)

통계와 overlay 위치 조정처럼 데이터/배치 모델은 이미 있으니 UI를 완성한다.

| 작업 | 담당 에이전트 | 산출물 |
|------|-------------|--------|
| Statistics Dashboard | `swiftui-designer` | StatisticsDashboardView, DailySummaryView 개선 |
| Countdown Overlay Position UI | `swiftui-designer` | SettingsRootView 위치 선택 UI |
| Countdown Overlay corner 계산 | `macos-core` | CountdownOverlayController 분기 처리 |
| DailyStats 평균 회복시간 계산 | `data-architect` | DailyStats.swift 수정 |
| KR/EN 현지화 문자열 | `localization` | AppStrings, .xcstrings 갱신 |

### Phase 3: 통합 검증 (F4 나머지)

| 작업 | 담당 에이전트 | 산출물 |
|------|-------------|--------|
| Statistics 통합 테스트 | `qa-integrator` | 통합 테스트 |
| 전체 회귀 테스트 | `qa-integrator` | 전체 테스트 스위트 실행 |
| 빌드 + 릴리즈 검증 | `qa-integrator` | Acceptance report |

---

## 6. Acceptance Criteria

### F1 — Statistics Dashboard

- [ ] 오늘 통계가 표시된다 (포커스 시간, 알림, 회복률, 최장 집중)
- [ ] 주간 바차트가 표시된다
- [ ] 데이터가 없을 때 빈 상태 메시지가 표시된다
- [ ] 세션 종료 후 통계가 자동 갱신된다
- [ ] KR/EN 모두 정상 표시

### F2 — Countdown Overlay Position

- [ ] Settings에서 네 모서리 중 하나를 선택할 수 있다
- [ ] 선택 즉시 overlay가 재배치된다
- [ ] 앱 재실행 후에도 선택한 위치가 유지된다
- [ ] 모든 모서리에서 화면 밖으로 벗어나지 않는다

### F3 — 엣지케이스

- [ ] Sleep/Wake 전환 후 상태 누수가 없다
- [ ] 권한 해제/재부여 후 정상 동작한다
- [ ] 자정을 넘기는 스케줄이 정확히 동작한다
- [ ] 시간당 알림 한도가 정확히 적용된다

### F4 — 테스트

- [ ] DailyStats 단위 테스트 8+개 통과
- [ ] SessionTracker 단위 테스트 6+개 통과
- [ ] Countdown overlay 위치 계산 테스트 4+개 통과
- [ ] IdleMonitor 엣지케이스 테스트 10+개 통과
- [ ] 통합 테스트 3+개 통과
- [ ] `xcodebuild test` 전체 통과

---

## 7. Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| 통계 쿼리가 많은 세션에서 느려짐 | UI 버벅임 | 최근 7일만 쿼리, SwiftData predicate 최적화 |
| 코너별 overlay가 노치/메뉴바/독과 충돌 | 위치 어색함 | `visibleFrame` 기준 + inset 유지 |
| Sleep/Wake 테스트 자동화 어려움 | 커버리지 한계 | XCTRunLoop 기반 단위 테스트 + 수동 QA 매트릭스 |

---

## 8. Related Docs

- [spec.md](./spec.md) — 제품 스펙
- [task-macos-ux-stabilization.md](./task-macos-ux-stabilization.md) — UX 안정화
- [schedule-settings-plan.md](./schedule-settings-plan.md) — 스케줄 설정 (참고 패턴)
- [schedule-settings-implementation.md](./schedule-settings-implementation.md) — 구현 사례 (참고 패턴)
