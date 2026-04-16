# Feature Spec: Idle Stopwatch & Overlay Quick Pause

- **Version**: v1.1
- **Status**: Draft
- **Owner**: Product Management
- **Target Version**: v0.3.x
- **Review**: 코드베이스 정합성 검토 완료 (2026-04-17)

## 1. 개요 (Executive Summary)

NudgeWhip의 핵심 가치는 사용자가 흐트러진 순간을 빠르게 인지하고 업무로 복귀하도록 돕는 것입니다. 현재의 오버레이 알림은 "업무 이탈" 사실만을 알리고 있으나, 사용자는 **"정확히 얼마나 자리를 비웠는지"**에 대한 실시간 정보와, 상황에 따라 **"알림을 유연하게 제어할 수 있는 방법"**을 요구하고 있습니다.

본 기획은 카운트다운 오버레이에 실시간 스톱워치를 도입하여 이탈 시간의 체감도를 높이고, 오버레이 내에서 즉시 일시정지(Pause)가 가능한 퀵 메뉴를 추가하여 제품의 사용성을 개선하는 것을 목표로 합니다.

> **참고 (현재 구현 상태)**: NudgeWhip에는 두 종류의 오버레이가 존재합니다.
> - **CountdownOverlay** (`CountdownOverlayController`): 화면 모서리에 항상 떠 있는 작은 HUD. 인터랙티브(버튼 클릭 가능). Standard(146×72) / Mini(96×32) 변형 지원.
> - **AlertOverlay** (`AlertManager` → `PerimeterPulsePresenter`): 전체 화면 테두리 펄스. **비인터랙티브** (`ignoresMouseEvents = true`).
>
> 본 기획의 스톱워치와 Quick Pause는 **CountdownOverlay**에 구현하는 것을 전제로 합니다. AlertOverlay는 사용자 클릭을 받을 수 없어 버튼 배치가 불가합니다.

---

## 2. 핵심 기능 1: 실시간 자리비움 타이머 (Idle Stopwatch)

### 2.1 기획 의도
- **심리적 넛지**: "5분 지남"이라는 정적인 문구보다, 1초씩 올라가는 타이머가 사용자의 복귀 본능을 더 강력하게 자극합니다.
- **데이터 신뢰성**: 사용자가 자리에 돌아왔을 때, 자신이 얼마나 자리를 비웠는지 즉각적인 피드백을 제공하여 통계 데이터와의 연결감을 강화합니다.

### 2.2 상세 사양

> **에스컬레이션 구조 (코드 매핑)**
>
> | Step | `NudgeWhipContentState` | `AlertVisualStyle` | UI 효과 |
> |------|------------------------|-------------------|---------|
> | 1 | `.idleDetected` | `.perimeterPulse` | 주황색 테두리 펄스 (메시지 없음) |
> | 2~3 | `.gentleNudge` | `.gentleNudge` | 테두리 + 중앙 메시지 카드 |
> | 4+ | `.strongNudge` | `.strongVisualNudge` | 빨간 테두리 + 배경 디밍 + 시스템 알림 |
>
> 에스컬레이션 간격은 `UserSettings.alertEscalationInterval`(기본 30초)로 제어됩니다.

1.  **시작 시점 (Escalation Policy)**:
    - **Step 1 (`.idleDetected`)**: 임계시간 도달 시점부터 타이머 시작. CountdownOverlay의 "IDLE" 표시를 경과 시간으로 교체.
    - **Step 2 (`.gentleNudge`)**: 에스컬레이션 진행과 무관하게 타이머는 계속 카운트업.
2.  **표시 내용**: `임계시간 도달 후 경과 시간`의 실시간 카운트업.
    - 예: 임계시간 5분(300초) 설정 시, 임계시간 도달 직후 `"00:00"`에서 시작하여 실시간 카운트업.
    - 현재 CountdownOverlay는 알림 상태에서 "IDLE" 정적 텍스트만 표시. 스톱워치는 이를 대체하는 **신규 기능**.
3.  **UI 디자인**:
    - 위치: CountdownOverlay의 기존 primary text 영역(standard: 24pt monospaced bold, mini: 16pt monospaced bold)을 그대로 활용.
    - 스타일: 이미 monospaced 폰트(`.monospaced` design)가 적용되어 있어 숫자 너비 고정 문제 없음.
    - 컬러: 기존 `nudgewhipAlert` 색상(주황)을 기본으로 사용. 15분 이상 경과 시 `nudgewhipAlert` → 점진적 강조(색상 변화 구체치는 시안 단계에서 결정, Reduce Motion / Differentiate Without Color 대응 필수).

---

## 3. 핵심 기능 2: 오버레이 퀵 일시정지 (Quick Pause)

### 3.1 기획 의도
- **이탈 방지**: 알림이 업무 흐름을 방해한다고 느낄 때 사용자가 앱을 완전히 종료해버리는 '최악의 시나리오'를 방지합니다.
- **상황 대응**: 갑작스러운 회의, 전화, 휴식 등 정당한 이탈 상황에서 메뉴바까지 가지 않고도 오버레이 내에서 즉시 "합법적 휴식"을 선언하게 합니다.

### 3.2 상세 사양

> **구현 위치**: Quick Pause 버튼은 CountdownOverlay(standard 변형)에 배치. AlertOverlay는 비인터랙티브이므로 버튼 배치 불가.
>
> **기존 PausePresetChips**: `nudgewhip/Views/Components/PausePresetChips.swift`에 이미 15m / 30m / 1h / 2h / Custom 프리셋이 구현되어 있음. Quick Pause 옵션은 이와 일치시키는 것을 원칙으로 함.

1.  **진입점 (Entry Point)**:
    - CountdownOverlay(standard 변형) 하단 또는 우측에 pause 아이콘 버튼 배치.
    - 아이콘: SF Symbols `pause.fill` 사용.
    - Mini 변형에서는 버튼 미노출 (공간 제약). 대신 hover 시 나타나는 기존 close(xmark) 버튼 옆에 pause 버튼 추가 검토.
2.  **상호작용 (UX Flow)**:
    - 버튼 클릭 시, 버튼 위쪽으로 **수직 리스트(Pop-up Menu)** 노출.
    - 옵션 구성: `15m`, `30m`, `1h`, `2h`, `Custom...` (기존 `PausePresetChips`와 동일).
    - ~~`Until Tomorrow`~~: v0.3에서는 **제외**. 스케줄 재개 시점(next schedule window start) 계산 로직이 추가로 필요하며, 현재 `IdleMonitor.setManualPause`는 `until: Date?` 기반이라 "내일" 기준 시점을 별도로 계산해야 함. v0.4+에서 검토.
    - 선택 즉시: 해당 시간만큼 일시정지 모드 진입 및 CountdownOverlay 상태 "PAUSE"로 전환.
3.  **UI/UX 고려사항**:
    - **Hover State**: 버튼에 마우스를 올리면 "Quick Pause" 툴팁 또는 강조 효과 제공.
    - **Safety**: 실수로 클릭하는 것을 방지하기 위해 버튼 크기는 기존 close 버튼(xmark, 14×14)과 동일한 크기 유지. 리스트의 각 옵션 클릭 영역은 최소 28pt 높이 확보.
    - **Animation**: 리스트가 아래에서 위로 부드럽게 슬라이드하며 나타나는 연출 (기존 feedback popover의 슬라이드 패턴과 일치).

---

## 4. 사용자 시나리오 (User Scenario)

1.  **이탈 인지**: 사용자가 유튜브를 보느라 5분이 흐름 → 임계시간 도달 → AlertOverlay(Step 1 perimeter pulse) + CountdownOverlay에 스톱워치 표시.
2.  **시간 체감**: CountdownOverlay에 `00:12... 00:13...` 올라가는 타이머를 보고 "아, 벌써 딴짓한 지 좀 지났네"라고 인지함.
3.  **에스컬레이션**: 30초 후 Step 2 격상 → AlertOverlay에 중앙 메시지 카드 표시. CountdownOverlay의 스톱워치는 계속 카운트업(`00:42...`).
4.  **상황 판단**: 마침 팀원에게 전화가 옴. 지금은 알림을 끌 수 없는 상황.
5.  **퀵 액션**: CountdownOverlay의 pause 버튼 클릭 → `30m` 선택.
6.  **상태 전이**: `MenuBarViewModel.pauseForMinutes(30)` 호출 → `IdleMonitor.setManualPause(true, until:)` → `RuntimeStateController.handle(.manualPauseEnabled)`. 앱은 30분간 일시정지 모드로 들어가고, CountdownOverlay는 "PAUSE"로 전환. AlertOverlay 사라짐. 사용자는 미안함 없이 통화에 집중.

---

## 5. 기대 효과 (Expected Impact)

- **Retention**: 알림의 피로도를 유연하게 관리하게 함으로써 앱 삭제/종료율 감소.
- **Engagement**: 사용자가 자신의 시간 낭비를 초 단위로 직면하게 하여 업무 복귀율(Recovery Rate) 향상.
- **UX Polishing**: 메뉴바를 통하지 않는 직관적인 제어로 고급스러운 유틸리티 앱 경험 제공.

---

## 6. 개발 가이드 (Implementation Note)

### 6.1 Timer Logic
- CountdownOverlayView에 이미 `Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common).autoconnect()`가 구현되어 있음.
- `@State private var now = Date()`를 활용한 매초 UI 갱신 로직 그대로 활용.
- `RuntimeSnapshot.lastInputAt`과 임계시간(`UserSettings.idleThresholdSeconds`)을 기반으로 경과 시간 계산:
  ```swift
  // 임계시간 도달 후 경과 시간
  let idleSince = snapshot.lastInputAt?.addingTimeInterval(TimeInterval(settings.idleThresholdSeconds))
  let elapsed = now.timeIntervalSince(idleSince ?? now)
  ```

### 6.2 Pause Logic
- 기존 `MenuBarViewModel.pauseForMinutes(_ minutes:, at:)` 재활용.
- 내부적으로 `IdleMonitor.setManualPause(true, until: date, at:)` → `RuntimeStateController.handle(.manualPauseEnabled)` 이벤트 체인 동작.
- Quick Pause 선택 시 `minutes` 값을 전달하여 호출. Custom은 기존 `PausePresetChips`의 Custom Sheet 재활용.

### 6.3 Component
- CountdownOverlay(standard 변형) 내에 pause 버튼 + SwiftUI `Popover`로 퀵 메뉴 구현.
- AlertOverlay에는 수정 없음 (비인터랙티브 유지).
- Mini 변형에 pause 버튼을 넣을 공간이 부족할 경우, standard 변형에만 적용하고 mini에서는 제외.

---

## 7. 추가 고려사항

### 7.1 접근성 (Accessibility)
- 스톱워치 경과 시간은 VoiceOver에서 실시간 읽기를 피함 (매초 읽기는 사용자 경험 저하). 대신 "Idle for 5 minutes"와 같이 분 단위 요약 제공.
- 색상 점진 변화는 `Differentiate Without Color` 설정 시 추가 텍스트/아이콘 변화로 대체 필수.
- Quick Pause 버튼은 `accessibilityLabel` 필수 (예: "Quick pause for 30 minutes").

### 7.2 로컬라이제이션 (Localization)
- 스톱워치 시간 포맷(`MM:SS`, `HH:MM:SS`)은 locale-independent (숫자만).
- Quick Pause 버튼 툴팁("Quick Pause"), 옵션 라벨("Custom...")은 `String Catalog (.xcstrings)` 키로 관리.
- 키 네이밍 규칙: `overlay.quick-pause.tooltip`, `overlay.quick-pause.custom`.

### 7.3 Fatigue Guardrails 연동
- `AlertManager`의 `alertsPerHourLimit`(기본 6)와 `thirdStagePerHourLimit`(기본 2)는 Quick Pause와 무관하게 동작.
- Quick Pause로 인한 `manualPauseEnabled` 전이 시 `alertEscalationStep`이 0으로 리셋되어 기존 피로도 가드레일과 충돌 없음.

### 7.4 Analytics / 통계 연동
- Quick Pause로 인한 휴식은 기존 `FocusSession`에 `pausedManual` 상태로 기록됨.
- `DailyStats`의 집계 로직(`monitoringActive && !breakMode && !whitelistedPause`)에 따라 휴식 시간은 집중 시간에서 자동 제외됨.
- 신규 메트릭: "overlay quick pause 사용 횟수" 추적 여부는 v0.3 Recovery Review에서 검토.

---

## 8. 검증 기준 (Acceptance Criteria)

### 8.1 Idle Stopwatch
- [ ] 임계시간 도달 시 CountdownOverlay(standard)에 경과 시간 카운트업 표시 (`00:00` → `00:01` → ...)
- [ ] 1초 간격으로 정확히 갱신 (Timer.publish 활용)
- [ ] Mini 변형에서도 경과 시간 표시 (공간 허용 시)
- [ ] 사용자 입력 복귀 시 스톱워치 즉시 정지 및 기본 카운트다운으로 복귀
- [ ] AlertOverlay(perimeter pulse)의 동작에는 영향 없음

### 8.2 Quick Pause
- [ ] CountdownOverlay(standard)에 pause 버튼 표시 (alerting 상태에서만)
- [ ] 버튼 클릭 시 15m / 30m / 1h / 2h / Custom 옵션 리스트 노출
- [ ] 옵션 선택 즉시 `pausedManual` 상태 전이 및 AlertOverlay 사라짐
- [ ] Custom 선택 시 기존 duration picker sheet 노출
- [ ] Quick Pause를 통한 pause도 기존 pause와 동일하게 Stats에 반영

### 8.3 비기능 요구사항
- [ ] VoiceOver: pause 버튼에 `accessibilityLabel` 설정
- [ ] Localization: 하드코딩 문자열 없음 (모든 문자열 .xcstrings 키 사용)
- [ ] Build: `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'` 통과
- [ ] Test: 기존 단위 테스트 / UI 테스트 회귀 없음
