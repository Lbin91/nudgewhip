# Feature Spec: Welcome Back Attention (복귀 시선 유도)

- **Version**: v1.0
- **Status**: Draft
- **Owner**: Product Management
- **Target Version**: v0.3.x
- **Related**: `docs/architecture/state-machine-contract.md`, `docs/app/task-idle-timer-and-quick-pause.md`

## 1. 개요 (Executive Summary)

NudgeWhip의 핵심 루프는 "이탈 감지 → 넛지 → 복귀"입니다. 그러나 현재 복귀 시점(`userActivityDetected`)에서는 타이머 리셋과 통계 기록만 수행하고, 사용자에게 **"돌아왔다는 사실 자체"**를 인지시키거나 앱으로 시선을 유도하는 장치가 없습니다.

본 기획은 **무제한 일시정지(Pause) 상태에서 사용자가 자리를 비운 것이 확실할 때(예: 5분 이상 입력 없음)**, **사용자가 다시 입력을 시작하는 순간**에 시선을 메뉴바 앱으로 유도하여 서비스 유지율(Retention)을 높이는 기능을 제안합니다.

> **핵심 가설**: 사용자가 자리에서 돌아온 직후는 가장 "집중 의지"가 높은 순간이다. 이 타이밍에 앱이 가볍게 인사하면, 앱 존재감이 강화되고 다음 세션의 복귀율이 올라간다.

---

## 2. 트리거 조건 (Trigger Conditions)

### 2.1 필수 조건 (모두 충족 시 활성화)

| # | 조건 | 근거 |
|---|------|------|
| 1 | 현재 runtime state가 `pausedManual` | 무제한 일시정지 상태에서만 동작 |
| 2 | 마지막 입력 후 5분 이상 경과 | `lastInputAt` 기준. "자리 비움 확신" 임계값 |
| 3 | 시스템 sleep/lock 상태가 아님 | `suspendedSleepOrLock`이 아닐 때만 |
| 4 | 최근 30분 내 Welcome Back 트리거 없음 | 쿨다운. 반복 피로도 방지 |

### 2.2 트리거 이벤트

```
userActivityDetected (NSEvent global monitor)
    → 조건 1~4 모두 충족?
        → YES: Welcome Back Attention 시퀀스 시작
        → NO: 기존 동작 유지 (타이머 리셋만)
```

### 2.3 비활성화 조건

- 사용자가 Settings에서 "Welcome Back 알림" 토글 OFF
- ` Reduce Motion` 설정 활성화 시 시각 효과 축소 (TTS만 유지)
- Focus Mode (DND) 활성화 중에는 시스템 알림 제외, 아이콘 펄스만 유지

---

## 3. 시선 유도 시퀀스 (Attention Sequence)

### 3.1 단계별 동작

사용자가 5분+ 자리를 비우고 돌아온 순간, **3개 채널을 동시에** 가볍게 자극합니다:

| 단계 | 채널 | 동작 | 지속 시간 | 강도 |
|------|------|------|-----------|------|
| **① 메뉴바 아이콘 펄스** | 시각 | `NSStatusBarButton` 이미지를 정상 ↔ 하이라이트 토글 | 3초 (6회 펄스) | 부드러움 |
| **② 시스템 알림** | 시스템 | `UNUserNotificationCenter` 배너 | 사용자가 닫거나 5초 자동 소멸 | 중간 |
| **③ TTS 인사** | 청각 | "돌아오셨네요!" (또는 설정 문구) | 1회 | 선택적 |

> **설계 원칙**: 이 시퀀스는 "공격적 넛지"가 아닙니다. 사용자가 **스스로 돌아온** 순간에 가벼운 환영을 제공하는 것입니다. 강도는 항상 GentleNudge 수준 이하를 유지합니다.

### 3.2 시퀀스 타임라인

```
T+0ms   userActivityDetected 감지
T+50ms  조건 판정 (4가지 필수 조건)
T+100ms ① 메뉴바 아이콘 펄스 시작 (NSAnimationContext)
T+200ms ② 시스템 알림 발행 (UNNotification)
T+300ms ③ TTS 재생 (AVSpeechSynthesizer, 설정 ON 시에만)
T+3s    ① 아이콘 펄스 종료 → 정상 아이콘 복귀
T+5s    ② 알림 자동 소멸 (사용자 미응답 시)
```

### 3.3 사용자 응답 분기

| 사용자 행동 | 앱 반응 |
|------------|---------|
| 시스템 알림 클릭 | 메뉴바 드롭다운 열기 → "다시 시작할까요?" 프롬프트 표시 |
| 알림 무시 (자동 소멸) | 아이콘 펄스만으로 종료. 강제 동작 없음 |
| 메뉴바 아이콘 클릭 | 기존 드롭다운 동작 + "Welcome Back" 배너 상단 표시 |

---

## 4. 상태 머신 연동

### 4.1 신규 이벤트

기존 `state-machine-contract.md`의 이벤트 모델에 다음을 추가합니다:

- `welcomeBackTriggered`: 트리거 조건 충족 시 `userActivityDetected` 핸들러에서 파생

### 4.2 상태 전이 영향

Welcome Back Attention은 **runtime state 전이를 발생시키지 않습니다**. 현재 `pausedManual` 상태를 유지하며, 오버레이 효과만 부가적으로 동작합니다.

```
pausedManual + userActivityDetected
    → 조건 충족: pausedManual (유지) + Welcome Back 시퀀스 실행
    → 조건 불충족: pausedManual (유지) + lastInputAt 갱신만
```

### 4.3 타이머 규칙

- 신규 타이머: `welcomeBackCooldownTimer` (30분 쿨다운, 일회성)
- 기존 `cooldownTimer`와 독립 동작
- `sleepDetected` / `screenLocked` 발생 시 `welcomeBackCooldownTimer`도 함께 리셋

---

## 5. 시스템 알림 (UNNotification) 사양

### 5.1 알림 내용

| 필드 | 한국어 | English |
|------|--------|---------|
| title | 돌아오셨네요! | Welcome back! |
| body | 집중할 시간이에요 🎯 | Time to focus 🎯 |
| categoryIdentifier | `WELCOME_BACK` | `WELCOME_BACK` |
| sound | `.none` (청각은 TTS가 담당) | `.none` |

### 5.2 알림 액션

| 액션 | 버튼 텍스트 | 동작 |
|------|------------|------|
| 기본 (알림 클릭) | — | 메뉴바 드롭다운 열기 |
| dismiss | — | 알림 닫기, 추가 동작 없음 |

### 5.3 알림 권한

- 기존 `UNUserNotificationCenter` 권한을 그대로 활용
- 권한이 없는 경우: 시스템 알림 채널을 스킵하고 아이콘 펄스 + TTS만 동작

---

## 6. 메뉴바 아이콘 펄스 사양

### 6.1 애니메이션

- **방식**: `NSAnimationContext`를 활용한 opacity/image 토글
- **패턴**: 정상 이미지 → 하이라이트 이미지 (0.25초) → 정상 이미지 (0.25초) × 6회
- **총 지속**: 3초
- **하이라이트 이미지**: 기존 아이콘에 주황색 테두리 또는 글로우 효과 (SF Symbols `bell.fill` 또는 커스텀)

### 6.2 접근성

- `Reduce Motion` 활성화 시: 펄스 대신 1회 점멸 (blink)로 대체
- `accessibilityLabel` 업데이트: "Welcome back notification active"

---

## 7. TTS (Text-to-Speech) 사양

### 7.1 설정

| 항목 | 기본값 | 비고 |
|------|--------|------|
| 활성화 여부 | OFF | 청각 넛지는 명시적 동의 필요 |
| 문구 | "돌아오셨네요!" | 설정에서 커스텀 가능 |
| 언어 | 시스템 locale 따라감 | `AVSpeechSynthesizer` 자동 감지 |
| 볼륨 | 시스템 볼륨의 70% | 너무 크지 않게 |
| 속도 | 기본 (`AVSpeechUtteranceDefaultSpeechRate`) | — |

### 7.2 구현

- `AVSpeechSynthesizer` 활용 (기존 TTS 넛지 인프라 재활용)
- 재생 중복 방지: 이전 발화가 끝나지 않았으면 스킵

---

## 8. 설정 UI

### 8.1 Settings 위치

Settings → Nudges 섹션 하단에 신규 그룹 추가:

```
┌─ Welcome Back ─────────────────────────┐
│ [Toggle] 돌아올 때 알림               │
│                                         │
│ 자리 비움 기준: [  5분  ] ▾            │
│                                         │
│ [Toggle] 음성 인사                     │
│ 인사 문구: [돌아오셨네요!          ]   │
│                                         │
│ 쿨다운: [  30분  ] ▾                   │
└─────────────────────────────────────────┘
```

### 8.2 UserSettings 신규 필드

| 필드 | 타입 | 기본값 | 비고 |
|------|------|--------|------|
| `welcomeBackEnabled` | `Bool` | `true` | 전체 기능 ON/OFF |
| `welcomeBackIdleThresholdMinutes` | `Int` | `5` | 자리 비움 확신 임계값 (분) |
| `welcomeBackTtsEnabled` | `Bool` | `false` | TTS ON/OFF |
| `welcomeBackTtsMessage` | `String` | `"돌아오셨네요!"` | TTS 문구 |
| `welcomeBackCooldownMinutes` | `Int` | `30` | 쿨다운 (분) |

---

## 9. 데이터 흐름

### 9.1 시퀀스 다이어그램

```
NSEvent Monitor ──── userActivityDetected ────→ IdleMonitor
                                                       │
                                                   [조건 판정]
                                                       │
                                    ┌──────────────────┼──────────────────┐
                                    │ 충족             │ 불충족           │
                                    ▼                  ▼                  │
                            WelcomeBackManager    lastInputAt 갱신만      │
                                    │                                    │
                    ┌───────────────┼───────────────┐                    │
                    ▼               ▼               ▼                    │
            StatusBarIcon    UNNotification    TTS Engine               │
            PulseController  Manager           Service                  │
                    │               │               │                    │
                    └───────────────┴───────────────┘                    │
                                    │                                    │
                            cooldownTimer 시작                          │
                            (30분간 재트리거 방지)                       │
                                                                        │
                                                                    (종료)
```

### 9.2 신규 컴포넌트

| 컴포넌트 | 책임 | 파일 위치 (예상) |
|----------|------|-----------------|
| `WelcomeBackManager` | 조건 판정, 시퀀스 오케스트레이션 | `nudgewhip/Services/WelcomeBackManager.swift` |
| `StatusBarPulseController` | 메뉴바 아이콘 펄스 애니메이션 | `nudgewhip/Services/StatusBarPulseController.swift` |
| 기존 `AlertManager` | UNNotification 발행 (기존 메서드 재활용) | `nudgewhip/Services/AlertManager.swift` |
| 기존 TTS 인프라 | 음성 재생 (기존 서비스 재활용) | 기존 TTS 서비스 |

---

## 10. 기존 시스템과의 관계

### 10.1 기존 Idle Detection 루프와의 차이

| | 기존 Idle → Nudge 루프 | Welcome Back Attention |
|---|---|---|
| **트리거** | 입력이 멈춤 (idle) | 입력이 재개됨 (return) |
| **목적** | "이탈했다"고 알림 | "돌아왔다"고 환영 |
| **상태** | `monitoring` → `alerting` | `pausedManual` (유지) |
| **강도** | 점진적 에스컬레이션 | 항상 1회 가벼운 터치 |
| **대상** | 업무 중 이탈자 | 휴식 후 복귀자 |

### 10.2 충돌 시나리오

| 시나리오 | 처리 |
|----------|------|
| Welcome Back 중에 idle threshold 도달 | Welcome Back 시퀀스는 무조건 3초 내 종료되므로 충돌 불가 |
| Welcome Back + 일시정지 해제 동시 | 일시정지 해제가 우선. Welcome Back은 스킵 |
| 시스템 알림 권한 거부 | 아이콘 펄스 + TTS만 동작. 에러 로그 없음 |
| 연속 자리 비움/복귀 반복 | 30분 쿨다운으로 1시간에 최대 2회 |

---

## 11. 검증 기준 (Acceptance Criteria)

### 11.1 핵심 플로우

- [ ] `pausedManual` 상태에서 5분+ 입력 없음 후 입력 발생 시 Welcome Back 시퀀스 실행
- [ ] 메뉴바 아이콘이 3초간 펄스 애니메이션 동작 (6회 토글)
- [ ] 시스템 알림 "돌아오셨네요!" 배너 표시 (권한 있는 경우)
- [ ] TTS 설정 ON 시 음성 재생 (1회)
- [ ] 알림 클릭 시 메뉴바 드롭다운 열림

### 11.2 조건 판정

- [ ] `monitoring` 상태에서는 Welcome Back 동작하지 않음
- [ ] 5분 미만 자리 비움 시 Welcome Back 동작하지 않음
- [ ] 쿨다운(30분) 내 재트리거 방지
- [ ] Settings 토글 OFF 시 전체 기능 비활성화

### 11.3 비기능 요구사항

- [ ] VoiceOver: 펄스 중 `accessibilityLabel` 업데이트
- [ ] Reduce Motion: 펄스 → 1회 blink로 대체
- [ ] Localization: 알림 문구, TTS 문구 모두 `.xcstrings` 키 관리
- [ ] Build: `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'` 통과
- [ ] Test: 기존 단위 테스트 / UI 테스트 회귀 없음

---

## 12. 마일스톤 (제안)

| Phase | 내용 | 예상 기간 |
|-------|------|-----------|
| Phase 1 | `WelcomeBackManager` + 아이콘 펄스 | 2일 |
| Phase 2 | 시스템 알림 연동 | 1일 |
| Phase 3 | TTS 연동 + 설정 UI | 1일 |
| Phase 4 | QA + 엣지 케이스 검증 | 1일 |

---

## 13. 향후 확장 (Future Considerations)

- **가상 펫 연동**: Welcome Back 시 펫 캐릭터가 반응하는 애니메이션 (Phase 2 펫 시스템 완료 후)
- **복귀 통계**: "평균 자리 비움 시간", "하루 복귀 횟수" 대시보드 메트릭
- **시간대 인사**: 아침/점심/저녁에 따른 인사 문구 변경 ("좋은 아침이에요!" 등)
- **iOS 연동 (Pro)**: Mac에서 복귀 시 iPhone에도 가벼운 haptic 피드백
