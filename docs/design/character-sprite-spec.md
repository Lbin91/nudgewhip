# Nudge Character Sprite Spec

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `visual-designer`
- Scope: pet growth stages, emotion states, frame timing, export rules

## 1. Character Role

- 캐릭터는 감시자가 아니라 작업 복귀를 돕는 동행자다.
- 표정은 과장된 귀여움보다 짧고 분명한 감정 전달을 우선한다.
- 메뉴바에서 과도하게 존재감을 차지하지 않고, 드롭다운과 상세 화면에서 더 많이 보인다.

## 2. Growth Stages

### 2.1 Stage Names

| Stage | Meaning | Visual Scale |
|---|---|---|
| `sprout` | 초기 상태 | 가장 단순한 실루엣 |
| `buddy` | 사용자가 가장 자주 보는 상태 | 안정된 기본형 |
| `guide` | 성장 완료에 가까운 상태 | 디테일과 자신감이 조금 더 있음 |

### 2.2 Stage Rules

- 각 단계는 실루엣만 바뀌어도 구분되어야 한다.
- 성장할수록 복잡해지되, 과밀해지지 않는다.
- 단계 변화는 보상 이벤트와 연결된다.

## 3. Emotion States

| Emotion | Meaning | Default Usage |
|---|---|---|
| `happy` | 집중 유지, 복귀 성공 | streak, recovery |
| `sad` | 잠깐 흐름이 끊김 | idle notice |
| `cheer` | 다시 시작할 수 있음 | gentle warning, level up |
| `sleep` | 휴식 모드, 비활성 | break ack, manual pause |

## 4. Motion Set

### 4.1 Core Motions

| Motion | Frames | Timing | Use |
|---|---|---|---|
| `idle` | 6-8 | loop | 기본 대기 |
| `blink` | 2 | quick | 살아 있음 표현 |
| `nod` | 6-8 | short | 복귀 유도 |
| `cheer` | 10-12 | upbeat | 보상, 레벨업 |
| `sleeping` | 8-10 | slow | 휴식, 야간 상태 |
| `bounce` | 6-8 | soft | 가벼운 강조 |

### 4.2 Timing Rules

- 짧은 루프는 1초 안팎, 긴 루프는 2초 이내를 기준으로 한다.
- alert 중 과한 떨림은 피한다.
- 입력 복귀 시 motion은 즉시 정지하거나 recovery pose로 전환한다.
- reduce motion 대응 시 blink와 minimal pose만 남긴다.

## 5. Stage x Emotion Matrix

| Stage | happy | sad | cheer | sleep |
|---|---|---|---|---|
| `sprout` | 가능 | 가능 | 가능 | 가능 |
| `buddy` | 기본 | 기본 | 기본 | 기본 |
| `guide` | 가능 | 가능 | 강한 보상 | 가능 |

## 6. Frame and Asset Rules

- 모든 표정은 같은 anchor point를 유지한다.
- 눈, 입, 귀, 꼬리 같은 파츠는 재사용 가능한 레이어로 분리한다.
- 감정 상태는 색보다 자세와 실루엣으로 먼저 구분한다.
- 배경이 필요한 경우에도 투명 버전을 우선 만든다.

## 7. File Naming and Export

### 7.1 Naming Convention

- 포맷: `pet/{stage}/{emotion}/{motion}`
- 예: `pet/buddy/happy/cheer.svg`
- 스프라이트 시트용 파일은 `sheet` 접미사를 사용한다.

### 7.2 Export Matrix

| Use | Format | Size |
|---|---|---|
| master source | SVG | vector |
| app preview | PNG | 256, 512 |
| design review | PNG | 1024 |
| sheet export | PNG sprite sheet | 2x, 3x |

### 7.3 Layer Rules

- background, body, face, accessory 레이어를 분리한다.
- 애니메이션이 필요한 파츠는 별도 레이어로 유지한다.
- 자산은 회전/스케일을 하더라도 중심이 무너지지 않도록 설계한다.

## 8. Usage Rules

- `happy`는 복귀 직후와 streak 달성에 우선 사용한다.
- `sad`는 사용자 비난이 아니라 흐름이 잠깐 끊겼다는 표시로만 쓴다.
- `sleep`은 휴식 모드와 야간 비활성에서만 사용한다.
- `cheer`는 과도한 축하보다 다음 행동을 유도하는 톤으로 유지한다.

## 9. Handoff Notes

- `content-strategist`는 각 emotion에 대응하는 대사 슬롯을 유지한다.
- `swiftui-designer`는 motion state와 UI alert state를 분리해 사용한다.
- `web-dev`는 hero 영역에 가장 단순한 stage만 사용하고, growth progression은 설명용으로만 배치한다.
