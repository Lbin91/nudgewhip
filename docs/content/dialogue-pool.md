# Nudge Dialogue Pool

- Version: 0.2
- Last Updated: 2026-04-02
- Owner: `content-strategist`
- Scope: app notification copy slots for KR/EN

## 1. Purpose

- 이 문서는 Nudge의 대사 슬롯과 기본 문구 풀을 정의한다.
- 실제 대사는 캐릭터의 감정 표현보다 `복귀 유도`와 `톤 일관성`을 우선한다.
- 번역과 레이아웃 검증이 가능하도록 KR/EN canonical lines를 함께 둔다.

## 2. Slot Model

### 2.1 Required Slots

| Slot | When Used | Intent |
|---|---|---|
| `focus_start` | 세션 시작 | 작업 진입 응원 |
| `idle_notice` | 무입력 임계 도달 | 부드러운 재호출 |
| `gentle_warning` | 1차 경고 | 짧은 주의 환기 |
| `strong_warning` | 반복 무입력 | 더 명확한 복귀 요청 |
| `notification_line` | 시스템 알림 | 짧은 1회성 알림 문구 |
| `recovery` | 입력 복귀 직후 | 즉시 긍정 피드백 |
| `break_ack` | 휴식 모드 진입 | 휴식 승인 |
| `break_suggestion` | 반복 오탐 감지 시 | 휴식 제안 안내 |
| `streak_reward` | 연속 집중 달성 | 보상 피드백 |
| `level_up` | 레벨 상승 | 성장 피드백 |
| `remote_escalation` | Pro iOS 전달 | 원격 알림 문구 |

### 2.2 Variation Rules

- 각 슬롯은 최소 3개 이상의 변형을 가진다.
- 변형은 의미가 같아야 하며, 감정 강도만 조정할 수 있다.
- 같은 세션에서 동일 문구를 연속 재사용하지 않는다.
- KR/EN은 의미 우선 일치, 직역 우선은 아니다.

## 3. Notification Type Mapping

| Notification Type | Dialogue Slot | Notes |
|---|---|---|
| `perimeterPulse` | `idle_notice` → `gentle_warning` | idle_notice first, escalate to gentle_warning if no return |
| `strongVisualNudge` | `strong_warning` | stronger visual + copy |
| `notificationNudge` | `notification_line` | single sentence, cancelable |
| `remoteEscalation` | `remote_escalation` | Pro only, iOS follow-up |
| `breakSuggestion` | `break_suggestion` | repeated false-positive mitigation |

## 4. Canonical Lines

### 4.1 focus_start

- KR: `시작이 절반입니다. 지금 흐름을 만들어 봅시다.`
- EN: `Starting is half the work. Let's build momentum now.`

- KR: `작게 시작해도 괜찮습니다. 지금 자리에서 이어가면 됩니다.`
- EN: `A small start is enough. Just continue from here.`

- KR: `지금 시작하면 충분합니다. 한 걸음만 내디뎌 보세요.`
- EN: `Now is a fine time to start. Just take one step.`

### 4.2 idle_notice

- KR: `잠깐 멈췄네요. 다시 돌아올 타이밍입니다.`
- EN: `You paused for a moment. It is time to come back.`

- KR: `입력이 멈췄어요. 이어갈 준비가 되었나요?`
- EN: `Input stopped. Are you ready to continue?`

- KR: `화면이 잠잠하네요. 다시 움직여 볼까요?`
- EN: `Everything went quiet. Shall we get moving again?`

### 4.3 gentle_warning

- KR: `흐름이 잠시 끊겼습니다. 지금 돌아오면 이어가기 쉽습니다.`
- EN: `The flow paused. Coming back now will be easy.`

- KR: `조금만 더 붙잡아 두겠습니다. 다시 시작해 봅시다.`
- EN: `I'll hold the line a little longer. Let's start again.`

- KR: `잠시 빗나갔네요. 여기서 방향을 잡으면 됩니다.`
- EN: `A brief detour. You can find your way back from here.`

### 4.4 strong_warning

- KR: `아직 돌아오지 않았네요. 지금 복귀해도 늦지 않습니다.`
- EN: `You have not returned yet. It is not too late to come back now.`

- KR: `이탈이 길어지고 있어요. 작업으로 돌아갈 시간입니다.`
- EN: `The pause is getting longer. It is time to return to work.`

- KR: `자리를 비운 지 꽤 됐습니다. 지금 돌아오는 것이 좋습니다.`
- EN: `You have been away for a while. Now would be a good time to return.`

### 4.5 notification_line

- KR: `지금 다시 시작해 봅시다.`
- EN: `Let's restart now.`

- KR: `여기서 바로 이어가면 됩니다.`
- EN: `You can continue right here.`

- KR: `다시 자리에 앉아 볼까요?`
- EN: `Shall we settle back in?`

### 4.6 recovery

- KR: `좋습니다. 다시 돌아왔네요.`
- EN: `Good. You are back.`

- KR: `복귀가 빠릅니다. 지금 흐름을 유지해 봅시다.`
- EN: `That was a quick return. Let's keep the momentum.`

- KR: `돌아와서 반갑습니다. 그대로 계속 가면 됩니다.`
- EN: `Welcome back. Just keep going as you were.`

### 4.7 break_ack

- KR: `휴식 모드로 전환했습니다. 잠깐 쉬어도 됩니다.`
- EN: `Break mode is on. You can take a short pause.`

- KR: `잠시 멈춤을 허용했습니다. 돌아올 때 다시 시작하면 됩니다.`
- EN: `Pause allowed. Resume from here when you return.`

- KR: `휴식 시간입니다. 충분히 쉬고 오세요.`
- EN: `Break time. Take all the rest you need.`

### 4.8 break_suggestion

- KR: `반복해서 멈추고 있네요. 잠시 숨을 고르거나 민감도를 조정해 볼까요?`
- EN: `You keep pausing. Want to take a breather or adjust sensitivity?`

- KR: `집중이 자주 끊기고 있습니다. 잠시 알림 강도를 낮춰도 괜찮습니다.`
- EN: `Focus keeps breaking. It is okay to lower the alert intensity for a while.`

- KR: `계속 멈춤이 발생하고 있어요. 잠시 쉬었다 오면 더 나을 수 있습니다.`
- EN: `Pauses keep happening. Stepping away briefly might help.`

### 4.9 streak_reward

- KR: `연속 집중을 지켰습니다. 지금 리듬이 좋습니다.`
- EN: `Your streak held. The rhythm is strong now.`

- KR: `알림 없이 이어갔네요. 집중이 잘 이어지고 있습니다.`
- EN: `You kept going without alerts. The focus is holding.`

- KR: `흐름이 끊기지 않았습니다. 이대로 가면 더 멀리 갈 수 있습니다.`
- EN: `The flow never broke. You can go even further like this.`

### 4.10 level_up

- KR: `레벨이 올랐습니다. 꾸준함이 쌓이고 있습니다.`
- EN: `Level up. Consistency is stacking up.`

- KR: `성장이 보입니다. 다음 단계로 넘어갈 준비가 되었네요.`
- EN: `Progress is visible. You are ready for the next step.`

- KR: `한 단계 올라섰습니다. 지금까지의 노력이 결과로 나타나고 있습니다.`
- EN: `You leveled up. Your effort is showing results.`

### 4.11 remote_escalation

- KR: `Mac에서 멈춘 흐름이 길어지고 있습니다. iPhone에서도 확인해 주세요.`
- EN: `The pause on your Mac is getting long. Check your iPhone too.`

- KR: `복귀 신호가 필요합니다. 다른 기기에서도 한 번 더 알려드립니다.`
- EN: `A return signal is needed. I am nudging you again on another device.`

- KR: `Mac 작업이 멈춰 있습니다. 다른 기기에서 상태를 확인해 주세요.`
- EN: `Work on your Mac has stopped. Please check from another device.`

## 5. Tone Rules

- 금지 톤: 비난, 조롱, 죄책감 유발, 과도한 친밀감, 과장된 긴박감
- 허용 톤: 짧은 안내, 부드러운 제안, 즉시 복귀 격려, 관찰형 피드백
- 캐릭터성이 있어도 업무 방해처럼 들리면 안 된다.

## 6. Localization Handoff

- 원문 작성 책임은 `content-strategist`가 가진다.
- 번역 키는 `{domain}.{surface}.{intent}` 패턴으로 관리한다.
- 각 슬롯은 String Catalog comment로 사용 맥락을 명시해야 한다.
- 번역자는 문장의 길이 차이를 고려해 2줄 래핑 가능성을 전제로 작업한다.
- 누락 번역은 placeholder로 노출하지 않는다.

## 7. Variation and Reuse Rules

- 같은 기능 단계에서는 같은 slot의 변형을 순환 사용한다.
- 서로 다른 slot끼리도 의미가 겹치면 중복 사용을 피한다.
- `idle_notice`와 `gentle_warning`은 강도 차이를 분명히 유지한다.
- `recovery`는 알림 종료 후 즉시 출력되는 짧은 피드백만 허용한다.

## 8. Data Dependencies

- `idle_notice`, `gentle_warning`, `strong_warning`은 idle state machine과 연결된다.
- `recovery`는 입력 복귀 이벤트와 연결된다.
- `break_ack`는 manual break 상태와 연결된다.
- `break_suggestion`은 반복 오탐 감지 로직과 연결된다.
- `break_suggestion`은 Free에서 break mode 진입을 직접 약속하지 않는다. 기본 동작은 민감도 조정, 알림 강도 완화, 도움말 안내다.
- `streak_reward`, `level_up`는 `DailyStats` 및 `PetState`와 연결된다.
- `remote_escalation`은 CloudKit sync 상태와 Pro entitlement와 연결된다.

## 9. QA Notes

- KR/EN 길이 차이로 인한 truncation 여부를 검증한다.
- 동일 세션 내 반복 문구가 너무 빨리 재노출되지 않는지 검증한다.
- 시스템 알림 문구는 1문장, 빠르게 훑을 수 있는 길이, 복귀 시 즉시 정리 가능해야 한다.
