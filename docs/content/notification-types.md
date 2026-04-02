# Nudge Notification Types

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `content-strategist`
- Scope: `P0` implementation contract for alert taxonomy and escalation

> **Cross-document Reference** — 이 문서의 타입명은 `character-design-brief.md` 및 `dialogue-pool.md`의 슬롯명과 아래 **Notification Type — Dialogue Slot Mapping** 섹션의 매핑 테이블로 연결된다.

## 1. Purpose

- 이 문서는 Nudge의 알림 종류, 발동 조건, 에스컬레이션, 피로도 제한, 접근성 원칙을 정의한다.
- 목표는 구현팀이 알림 시스템을 같은 기준으로 만들고 테스트할 수 있게 하는 것이다.
- 알림은 사용자 비난이 아니라 `return-to-work` 유도 장치여야 한다.

## 2. Design Principles

- 기본 톤은 짧고 중립적이며, 사용자 행동을 판단하지 않는다.
- 알림은 입력 복귀를 최우선 종료 조건으로 가진다.
- 알림 단계는 누적되어도 과도하게 반복되지 않아야 한다.
- 시각 알림은 색상만으로 상태를 전달하지 않는다.
- TTS는 보조 채널이며 기본 채널이 아니다.

## 3. Taxonomy

### 3.1 Core Types

| Type | Purpose | Default Surface |
|---|---|---|
| `perimeterPulse` | 1차 시각 넛지 | 현재 디스플레이 테두리 |
| `strongVisualNudge` | 2차 시각 넛지 | 더 강한 테두리/오버레이 |
| `ttsNudge` | 짧은 음성 넛지 | 시스템 음성 합성 |
| `remoteEscalation` | Pro용 원격 에스컬레이션 | iOS companion notification |
| `breakSuggestion` | 반복 오탐 완화 제안 | 메뉴바/설정 UI |

### 3.2 Non-goals

- 화면 콘텐츠 분석 기반 알림
- 브라우저 탭/도메인 자동 판정 알림
- 감정 분석 기반 문구 선택

## 4. Trigger Rules

### 4.1 Idle Trigger

- `lastInputAt + idleThreshold`에 도달하면 `perimeterPulse`를 시작한다.
- 입력 이벤트는 `mouseMoved`, `mouseDown`, `scrollWheel`, `keyDown`만 인정한다.
- idle 판정은 polling이 아니라 one-shot deadline timer를 기준으로 한다.

### 4.2 Escalation Trigger

- `perimeterPulse` 이후에도 입력이 없으면 단계적으로 강화한다.
- 권장 기본 간격은 다음과 같다.
- 1차: idle threshold 도달 즉시 `perimeterPulse`
- 2차: 추가 45~60초 무입력 시 `strongVisualNudge`
- 3차: 추가 60~90초 무입력 시 `ttsNudge`
- 4차: 장기 미복귀 시 `remoteEscalation`

### 4.3 Pause and Suppression

- `pausedManual` 상태에서는 모든 알림을 중단한다.
- `pausedWhitelist` 상태에서는 알림을 중단한다.
- `suspendedSleepOrLock` 상태에서는 알림을 일시 중단하고 기준 시각을 재설정한다.
- `limitedNoAX` 상태에서는 고정 권한 안내만 보여주고 idle 알림은 실행하지 않는다.

## 5. Escalation Contract

### 5.1 Escalation Order

- `perimeterPulse` -> `strongVisualNudge` -> `ttsNudge` -> `remoteEscalation`
- `remoteEscalation`은 Pro에서만 활성화한다.
- `grayscale`은 기본 단계가 아니며, 고강도 실험 옵션으로만 취급한다.

### 5.2 Termination Rules

- 사용자 입력 감지 시 즉시 알림을 종료한다.
- 종료 후에는 cooldown을 적용해 같은 세션에서 다시 과도하게 올라가지 않도록 한다.
- 알림 종료 후에는 `Recovery` 상태로 전환할 수 있다.

### 5.3 Fatigue Guardrails

- 시간당 최대 알림 횟수를 제한한다.
- 시간당 TTS 횟수를 별도로 제한한다.
- 동일 문구 연속 반복 금지 창을 둔다.
- 입력 복귀 직후 일정 시간은 재알림을 금지한다.
- 반복 오탐이 발생하면 `breakSuggestion`을 노출한다.

## 6. Copy Rules

- 비난, 경고, 처벌 느낌의 단어를 피한다.
- 짧고 관찰형 문장을 사용한다.
- 문구는 행동 유도 중심이어야 한다.
- TTS 문구는 1문장, 1회, 1톤으로 고정한다.

### 6.1 Good Examples

- `잠깐 멈췄네요. 돌아오면 바로 이어갈 수 있어요.`
- `입력이 잠시 멈췄어요. 다시 시작할 준비가 되었나요?`
- `복귀했네요. 지금 흐름 그대로 이어가면 됩니다.`

### 6.2 Bad Examples

- `왜 또 딴짓했나요?`
- `집중력이 떨어졌습니다.`
- `게으름을 멈추세요.`

## 7. Accessibility

- 색만으로 단계 구분을 만들지 않는다.
- 시각 플래시는 초당 3회 초과로 깜빡이지 않는다.
- `Reduce Motion`, `Increase Contrast`, `Differentiate Without Color`에 대응한다.
- 텍스트 대비는 최소 4.5:1을 기준으로 한다.
- 핵심 상태 전달은 색 + 형태 + 문구를 함께 사용한다.

## 8. Ownership and Handoff

- 원문 문구 소유권은 `content-strategist`에 있다.
- 번역 검수와 키 거버넌스는 `localization`과 협업한다.
- UI 반영은 `swiftui-designer`가 담당한다.
- 알림 기반 데이터 저장 규칙은 `data-architect`와 `qa-integrator`가 검증한다.

## 9. Implementation Notes

- 구현은 알림 상태를 코드상 enum으로 고정하고, 단계별 카피 슬롯을 분리해야 한다.
- 알림 종류는 UI와 로직이 섞이지 않도록 presentation layer와 trigger layer를 분리해야 한다.
- TTS 호출은 큐 중첩을 금지하고, 입력 복귀 시 즉시 cancel 가능해야 한다.

## 10. Notification Type — Dialogue Slot Mapping

- 이 매핑은 `character-design-brief.md`의 **State-to-Emotion Mapping** (Section 3.3) 및 **Dialogue Slot Linkage** (Section 5.1)과 일치해야 한다.
- 캐릭터 감정 열은 `character-design-brief.md` Section 3.1의 Canonical Emotion States를 따른다.

| Notification Type | Dialogue Slot | 캐릭터 감정 | 비고 |
|---|---|---|---|
| `perimeterPulse` | `idle_notice` | cheer (mild) | 1차 시각 넛지 |
| `strongVisualNudge` | `strong_warning` | sad (mild) + cheer | 2차 강화 넛지 |
| `ttsNudge` | `tts_line` | cheer (active) | 음성 보조 채널 |
| `remoteEscalation` | `remote_escalation` | sad (mild) | iOS 원격 에스컬레이션 |
| `breakSuggestion` | `break_suggestion` | sleep | 휴식 제안 |
| (복귀 감지 시) | `recovery_cheer` | happy (strong) | 복귀 축하 |
| (GentleNudge) | `gentle_warning` | cheer (active) | 1.5차 경고 |

- `recovery_cheer` 슬롯은 `dialogue-pool.md`의 `recovery` 슬롯에 대응하며, 복귀 감지 시 자동 발화한다.
- `gentle_warning`은 `perimeterPulse`와 `strongVisualNudge` 사이의 선택적 중간 단계에서 사용한다.
