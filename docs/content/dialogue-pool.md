# Nudge Dialogue Pool

- Version: 0.1
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
| `tts_line` | 음성 알림 | 한 문장 음성 출력 |
| `recovery` | 입력 복귀 직후 | 즉시 긍정 피드백 |
| `break_ack` | 휴식 모드 진입 | 휴식 승인 |
| `streak_reward` | 연속 집중 달성 | 보상 피드백 |
| `level_up` | 레벨 상승 | 성장 피드백 |
| `remote_escalation` | Pro iOS 전달 | 원격 알림 문구 |

### 2.2 Variation Rules

- 각 슬롯은 최소 3개 이상의 변형을 가진다.
- 변형은 의미가 같아야 하며, 감정 강도만 조정할 수 있다.
- 같은 세션에서 동일 문구를 연속 재사용하지 않는다.
- KR/EN은 의미 우선 일치, 직역 우선은 아니다.

## 3. Canonical Lines

### 3.1 focus_start

- KR: `시작이 절반입니다. 지금 흐름을 만들어 봅시다.`
- EN: `Starting is half the work. Let's build momentum now.`

- KR: `작게 시작해도 괜찮습니다. 지금 자리에서 이어가면 됩니다.`
- EN: `A small start is enough. Just continue from here.`

### 3.2 idle_notice

- KR: `잠깐 멈췄네요. 다시 돌아올 타이밍입니다.`
- EN: `You paused for a moment. It is time to come back.`

- KR: `입력이 멈췄어요. 이어갈 준비가 되었나요?`
- EN: `Input stopped. Are you ready to continue?`

### 3.3 gentle_warning

- KR: `흐름이 잠시 끊겼습니다. 지금 돌아오면 이어가기 쉽습니다.`
- EN: `The flow paused. Coming back now will be easy.`

- KR: `조금만 더 붙잡아 두겠습니다. 다시 시작해 봅시다.`
- EN: `I'll hold the line a little longer. Let's start again.`

### 3.4 strong_warning

- KR: `아직 돌아오지 않았네요. 지금 복귀해도 늦지 않습니다.`
- EN: `You have not returned yet. It is not too late to come back now.`

- KR: `이탈이 길어지고 있어요. 작업으로 돌아갈 시간입니다.`
- EN: `The pause is getting longer. It is time to return to work.`

### 3.5 tts_line

- KR: `지금 다시 시작해 봅시다.`
- EN: `Let's restart now.`

- KR: `여기서 바로 이어가면 됩니다.`
- EN: `You can continue right here.`

### 3.6 recovery

- KR: `좋습니다. 다시 돌아왔네요.`
- EN: `Good. You are back.`

- KR: `복귀가 빠릅니다. 지금 흐름을 유지해 봅시다.`
- EN: `That was a quick return. Let's keep the momentum.`

### 3.7 break_ack

- KR: `휴식 모드로 전환했습니다. 잠깐 쉬어도 됩니다.`
- EN: `Break mode is on. You can take a short pause.`

- KR: `잠시 멈춤을 허용했습니다. 돌아올 때 다시 시작하면 됩니다.`
- EN: `Pause allowed. Resume from here when you return.`

### 3.8 streak_reward

- KR: `연속 집중을 지켰습니다. 지금 리듬이 좋습니다.`
- EN: `Your streak held. The rhythm is strong now.`

- KR: `알림 없이 이어갔네요. 집중이 잘 이어지고 있습니다.`
- EN: `You kept going without alerts. The focus is holding.`

### 3.9 level_up

- KR: `레벨이 올랐습니다. 꾸준함이 쌓이고 있습니다.`
- EN: `Level up. Consistency is stacking up.`

- KR: `성장이 보입니다. 다음 단계로 넘어갈 준비가 되었네요.`
- EN: `Progress is visible. You are ready for the next step.`

### 3.10 remote_escalation

- KR: `Mac에서 멈춘 흐름이 길어지고 있습니다. iPhone에서도 확인해 주세요.`
- EN: `The pause on your Mac is getting long. Check your iPhone too.`

- KR: `복귀 신호가 필요합니다. 다른 기기에서도 한 번 더 알려드립니다.`
- EN: `A return signal is needed. I am nudging you again on another device.`

## 4. Tone Rules

- 금지 톤: 비난, 조롱, 죄책감 유발, 과도한 친밀감, 과장된 긴박감
- 허용 톤: 짧은 안내, 부드러운 제안, 즉시 복귀 격려, 관찰형 피드백
- 캐릭터성이 있어도 업무 방해처럼 들리면 안 된다.

## 5. Localization Handoff

- 원문 작성 책임은 `content-strategist`가 가진다.
- 번역 키는 `{domain}.{surface}.{intent}` 패턴으로 관리한다.
- 각 슬롯은 String Catalog comment로 사용 맥락을 명시해야 한다.
- 번역자는 문장의 길이 차이를 고려해 2줄 래핑 가능성을 전제로 작업한다.
- 누락 번역은 placeholder로 노출하지 않는다.

## 6. Variation and Reuse Rules

- 같은 기능 단계에서는 같은 slot의 변형을 순환 사용한다.
- 서로 다른 slot끼리도 의미가 겹치면 중복 사용을 피한다.
- `idle_notice`와 `gentle_warning`은 강도 차이를 분명히 유지한다.
- `recovery`는 알림 종료 후 즉시 출력되는 짧은 피드백만 허용한다.

## 7. Data Dependencies

- `idle_notice`, `gentle_warning`, `strong_warning`은 idle state machine과 연결된다.
- `recovery`는 입력 복귀 이벤트와 연결된다.
- `break_ack`는 manual break 상태와 연결된다.
- `streak_reward`, `level_up`는 `DailyStats` 및 `PetState`와 연결된다.
- `remote_escalation`은 CloudKit sync 상태와 Pro entitlement와 연결된다.

## 8. QA Notes

- KR/EN 길이 차이로 인한 truncation 여부를 검증한다.
- 동일 세션 내 반복 문구가 너무 빨리 재노출되지 않는지 검증한다.
- TTS 문구는 1문장, 1초기억 가능 길이, 발화 후 즉시 cancel 가능해야 한다.
