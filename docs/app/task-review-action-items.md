# Review Action Items: iOS Dashboard + macOS UX

- Version: draft-1
- Created: 2026-04-05
- Status: active
- Owner: engineering / product
- Source: 3개 task 문서 전문가 리뷰 (2026-04-04)

## 1. Purpose

최근 커밋된 3개 작업 문서에 대한 아키텍처 리뷰에서 식별된 7개 필수 해결 항목을 추적하고, 구현 순서와 완료 기준을 고정한다.

## 2. Source Documents

- [task-ios-dashboard-data-schema.md](./task-ios-dashboard-data-schema.md)
- [task-ios-dashboard-ia-and-prep.md](./task-ios-dashboard-ia-and-prep.md)
- [task-macos-ux-stabilization.md](./task-macos-ux-stabilization.md)

## 3. Action Items

### A1: AlertingSegment 로컬 모델 설계

- **심각도**: HIGH
- **영역**: Data Schema
- **문제**: `recoveryDurationTotal/Max`, `recoverySampleCount`를 계산하려면 alerting→recovery 구간의 시작-종료 시간 쌍이 필요하나, 현재 SwiftData 모델에 추적 필드가 전혀 없음. `FocusSession.recoveryCount`는 횟수만 저장.
- **해결**: `AlertingSegment(startedAt: Date, recoveredAt: Date?, escalationStep: Int)` 모델을 `FocusSession`에 추가하거나 독립 SwiftData 모델로 생성.
- **완료 기준**: recovery 계열 지표의 계산 근거가 코드에 존재하고, 단위 테스트로 검증 가능.

### A2: Identity Key 통일

- **심각도**: HIGH
- **영역**: Data Schema (3개 문서 공통)
- **문제**: PRD는 `macDeviceID + dayStart`, 스키마 문서는 `macDeviceID + localDayKey` 사용. 세 문서 간 불일치.
- **해결**: `macDeviceID + localDayKey`로 통일. `dayStart`는 데이터 필드로만 사용. PRD 및 cloudkit-sync-contract 업데이트.
- **완료 기준**: 세 문서가 동일한 identity key 정의를 사용.

### A3: NudgeWhipPreviewOverlay "Preview" 배지 추가

- **심각도**: HIGH
- **영역**: macOS UX
- **문제**: Non-regression rule #3("preview는 실제 alert으로 오인되면 안 됨")을 현재 코드가 위반 중. `NudgeWhipPreviewOverlay.swift`에 demo/preview 표시가 전혀 없음.
- **해결**: overlay에 "Preview" 배지 또는 상단 라벨 추가. 시각적으로 runtime alert과 구분.
- **관련 파일**: `nudge/Onboarding/Views/NudgeWhipPreviewOverlay.swift`
- **완료 기준**: preview overlay가 실제 runtime alert과 시각적으로 구분됨. KR/EN 모두 "미리보기" / "Preview" 텍스트 표시.

### A4: Mac → iOS 상태 매핑 테이블

- **심각도**: HIGH
- **영역**: IA
- **문제**: Mac `NudgeWhipRuntimeState` 7개 상태와 iOS 6개 표시 상태 간 매핑 규칙이 어디에도 정의되지 않음.
- **Mac states**: `limitedNoAX`, `monitoring`, `pausedManual`, `pausedWhitelist`, `alerting`, `pausedSchedule`, `suspendedSleepOrLock`
- **iOS display states**: `Monitoring`, `Alerting`, `Break`, `Needs Attention`, `Mac Setup Needed`, `Offline`
- **해결**: 매핑 테이블을 IA 문서 또는 별도 섹션에 추가.
- **완료 기준**: iOS 개발자가 Mac 상태 코드를 보지 않고도 iOS 표시 상태를 결정 가능.

### A5: RemoteEscalation Projection 스키마 정의

- **심각도**: HIGH
- **영역**: IA + Data Schema
- **문제**: Alerts 탭의 데이터 소스인 `RemoteEscalation` history projection이 어떤 CloudKit record type, 어떤 필드로 구성되는지 정의되지 않음. Data schema 문서에는 `MacState` + `DashboardDayProjection`만 존재.
- **해결**: `RemoteEscalationEvent` record type 정의 (occurredAt, message, state, macDeviceID 등). CloudKit 저장 방식(inbox model vs inline) 결정.
- **완료 기준**: Alerts 탭 구현에 필요한 데이터 소스가 스키마 수준에서 정의됨.

### A6: Screen Contract Free/Pro 분기 명시

- **심각도**: HIGH
- **영역**: IA
- **문제**: Stats의 hourly alert distribution은 Pro 전용, Home의 insight card(`recoveryDurationTotal/recoverySampleCount`)도 Pro 전용이나, IA 문서 screen contract에 Free/Pro 분기가 전혀 없음. Alerts 탭 자체의 Free/Pro 여부도 불명확.
- **해결**: 각 screen contract 섹션에 Free/Pro 가시성 마킹 추가.
- **완료 기준**: 각 섹션/필드가 Free에서 보이는지 Pro에서 보이는지 명시됨.

### A7: Cross-midnight Session 분할 규칙 명문화

- **심각도**: HIGH
- **영역**: Data Schema
- **문제**: 자정을 넘나드는 focus session의 `completedSessionCount` 귀속일, `totalFocusDuration` 분할 방식, `sessionsOver30mCount` 기준이 정의되지 않음.
- **해결**:
  - `completedSessionCount`: 세션 시작일에 귀속
  - `totalFocusDuration`: `focusDuration(overlapping:)`으로 각 일에 분할 계산
  - `sessionsOver30mCount`: 세션 전체 duration 기준으로 판단 (하루 분할 영향 없음)
- **완료 기준**: 엔지니어가 질문 없이 cross-midnight session의 projection 계산을 구현 가능.

## 4. Implementation Order

```
Phase 1 (문서 수정, 병렬 가능):
  [A2] Identity Key 통일
  [A4] Mac → iOS 상태 매핑 테이블
  [A6] Screen Contract Free/Pro 분기
  [A7] Cross-midnight Session 분할 규칙

Phase 2 (스키마/모델, A2 완료 후):
  [A1] AlertingSegment 로컬 모델 설계
  [A5] RemoteEscalation Projection 스키마 정의

Phase 3 (코드, Phase 2 완료 후):
  [A3] NudgeWhipPreviewOverlay "Preview" 배지 추가
```

의존성:
- A2 → A1, A5 (identity key 통일 후 스키마 작업)
- A1 → A3 완료는 아니지만, A3는 독립 코드 작업이므로 Phase 1과 병렬 가능
- A7은 A1과 연관 (session 분할이 AlertingSegment에도 영향)

## 5. Secondary Items (MEDIUM)

리뷰에서 식별된 MEDIUM 항목들. Phase 1-3 완료 후 별도 처리.

| # | 항목 | 영역 |
|---|------|------|
| S1 | `sessionsOver30mCount`를 "Derivable Now"로 재분류 | Data Schema |
| S3 | `localDayKey` timezone 변경 시나리오 정의 | Data Schema |
| S4 | 24-bin chart 접근성 대응 방안 명시 | IA |
| S5 | State matrix에 화면별 매핑 추가 | IA |
| S6 | NudgeWhipPreviewOverlay `@Environment(\.accessibilityReduceMotion)` 적용 | UX |
| S7 | QA matrix에 교차 상태 축 추가 (pause+schedule, pause+whitelist) | UX |
| S8 | Duration 필드를 Int(초)로 통일 | Data Schema |

## 6. Exit Criteria

- A1~A7 전체 완료
- 각 항목의 완료 기준 충족
- 변경 사항이 관련 task 문서에 반영됨
- S1~S8은 별도 티켓으로 분리 또는 후속 작업에서 처리

## 7. Completion Log

- 2026-04-05: Phase 1 완료 (A2, A4, A6, A7) — `e439118`
- 2026-04-05: Phase 2 완료 (A1, A5) — `a1b2c3d`
- 2026-04-05: Phase 3 완료 (A3) — `bedd102`

### A1: AlertingSegment 로컬 모델 설계

- `nudge/Shared/Models/AlertingSegment.swift` 생성
- `FocusSession`에 `alertingSegments` relationship 추가
- `DailyStats.derive()`에 recoverySampleCount/DurationTotal/DurationMax 집계 로직 추가
- **잔여**: FocusSession lifecycle management가 아직 구현되지 않아 AlertingSegment 실제 생성/종료 연결 필요

### A2: Identity Key 통일

- `ios-companion-prd.md`에서 `macDeviceID + dayStart` → `macDeviceID + localDayKey`로 통일

### A3: NudgeWhipPreviewOverlay "Preview" 배지

- overlay 우상단에 "Preview" / "미리보기" 배지 추가
- `@Environment(\.accessibilityReduceMotion)` 적용
- KR/EN 로컬라이제이션 추가

### A4: Mac → iOS 상태 매핑

- IA 문서에 NudgeWhipRuntimeState 7개 → iOS 표시 상태 6개 매핑 테이블 추가
- pausedWhitelist subtitle 구분 권장사항 포함

### A5: RemoteEscalationEvent 스키마

- data schema 문서에 `RemoteEscalationEvent` record type 정의 (section 7.5)
- occurredAt, macDeviceID, escalationStep, contentState, recovery tracking 포함

### A6: Free/Pro 분기

- Home: Free(summary cards), Pro(+insight card, follow-up card)
- Stats: Free(KPI strip, focus chart), Pro(+recovery chart, alert distribution)
- Alerts: 전체 Pro 기능
- Settings: 공통 화면, Pro status에서 CTA

### A7: Cross-midnight Session 분할

- completedSessionCount: 세션 시작일 귀속
- totalFocusDuration: focusDuration(overlapping:)으로 각 일에 분할
- sessionsOver30mCount: 세션 전체 duration 기준
