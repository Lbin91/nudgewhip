# Countdown Overlay Mini State Feedback Examples

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: product / design / engineering
- Related: `docs/app/task-countdown-overlay-mini-state-feedback.md`

## 1. Purpose

- 이 문서는 mini overlay의 상태 피드백을 실제 화면 감각으로 상상할 수 있도록 예시 시안과 레이아웃 원칙을 정리한다.
- 목표는 구현 전에 `얼마나 보여줄지`, `어디까지 단순해야 하는지`, `경고 상태를 어떻게 구분할지`를 눈높이에서 맞추는 것이다.

## 2. Design Principles

1. **평소에는 거의 안 보이는 UI처럼 느껴져야 한다**
2. **문제가 있을 때만 한 단계 더 설명적인 UI가 된다**
3. **경고여도 과장되거나 공포스럽지 않아야 한다**
4. **mini의 정체성은 끝까지 유지한다**

## 3. Baseline Layout

mini overlay 기본 크기 기준:

- `96x32`
- capsule 형태
- 좌우 padding 최소화
- monospaced text 유지

attention state 레이아웃 고정 권장:

- token 영역: 약 `56pt`
- trailing affordance 영역: 약 `16~18pt`
- token ↔ affordance gap: `4pt`
- `IDLE`처럼 긴 토큰은 좌측 정렬을 우선하고, attention state에서는 close affordance를 기본 생략한다

기본 구조:

```text
┌────────────────────┐
│        3m          │
└────────────────────┘
```

중립 상태에서는 이 정도가 이상적인 baseline이다.

## 4. Neutral State Examples

### 4.1 Monitoring

```text
┌────────────────────┐
│        3m          │
└────────────────────┘
```

- 텍스트: white
- info affordance: 없음
- close affordance: hover 실험이 있으면 hover 시만 보조 노출

### 4.2 Manual Pause

```text
┌────────────────────┐
│      PAUSE         │
└────────────────────┘
```

- 중립 상태
- 흰색 유지
- “이상 상태”처럼 보이지 않아야 함

### 4.3 Schedule Pause

```text
┌────────────────────┐
│      SCHED         │
└────────────────────┘
```

- 역시 중립 상태
- 설명이 필요한 경우는 settings/menu에서 해결

## 5. Attention State Examples

## 5.1 Accessibility Needed (`AX`)

권장 예시:

```text
┌────────────────────┐
│   AX           (i) │
└────────────────────┘
```

권장 실배치 감각:

```text
| AX |    gap    | i |
|<-- 24 -->|<--4-->|<--16~18-->|
```

시각 규칙:

- `AX` 텍스트: amber / yellow
- `i` 아이콘: same family, slightly muted
- capsule 배경은 기존 mini baseline 유지

의도:

- 에러보다는 `설정 필요`
- “왜 이런 글자가 뜨지?”라는 질문에 시각적으로 먼저 답해야 함

### 5.2 Idle Alert (`IDLE`)

권장 예시:

```text
┌────────────────────┐
│  IDLE          (i) │
└────────────────────┘
```

주의:

- `IDLE`은 `AX`보다 token 폭이 크므로 실제 96pt 안에서 더 타이트하다
- first-pass에서는 `IDLE + info`의 동시 표기를 유지하되, 구현 시 공간이 부족하면 `IDLE`의 info affordance를 2차 단계로 미루는 선택도 허용한다

시각 규칙:

- `IDLE` 텍스트: orange-red
- `i` 아이콘: 같은 계열 또는 white with tinted accent

의도:

- 단순 상태가 아니라, 지금 넛지가 진행 중이라는 사실을 더 명확히 드러냄

## 6. Info Popover Examples

### 6.1 AX 상태 클릭 시

```text
┌──────────────────────────────────┐
│ 손쉬운 사용 권한이 필요해요        │
│                                  │
│ NudgeWhip가 입력 멈춤을 감지하려면 │
│ 손쉬운 사용 권한이 필요합니다.     │
│ 설정에서 허용하면 정상 동작해요.   │
│                                  │
│ [설정 열기]   [닫기]              │
└──────────────────────────────────┘
```

원칙:

- 2~3문장 이하
- 해결 행동이 분명해야 함
- 기술 설명보다 사용자 행동 우선
- 가능하면 `설정 열기` CTA는 곧바로 시스템 설정을 열어야 한다

### 6.2 IDLE 상태 클릭 시

```text
┌──────────────────────────────────┐
│ 입력이 멈춘 상태예요              │
│                                  │
│ 설정한 기준 시간 동안 입력이 없어 │
│ 넛지를 보여주고 있어요.           │
│ 활동을 다시 시작하면 사라집니다.  │
│                                  │
│ [메뉴 열기]   [닫기]              │
└──────────────────────────────────┘
```

원칙:

- 비난하지 않음
- “문제 발생”보다 “현재 상태 설명”에 가깝게
- 짧은 체류 시간 때문에 first-pass에서는 popover보다 color + icon만 먼저 적용해도 된다

## 7. Layout Priority Rules

작은 공간 안에서 우선순위는 아래와 같다.

1. 상태 토큰 / countdown
2. warning color
3. info affordance
4. hover close affordance

즉, 공간이 부족하면 가장 먼저 희생되어야 하는 것은 `close` 쪽이다.

## 8. Recommended Hit Area Strategy

info affordance는 보여도 못 누르면 의미가 없다.

권장:

- visual icon은 작아도
- 실제 hit target은 최소 `16x16` 또는 가능하면 `18x18`

mini 96x32 안에서 너무 답답하면:

- token과 icon 간 간격을 줄이기보다
- icon hit area를 invisible padding으로 확보하는 편이 낫다

## 9. Anti-slop Guardrails

다음은 하지 않는다.

- mini를 작은 standard overlay처럼 만들기
- 설명 문구를 overlay 본체 안에 늘어놓기
- 색상을 여러 개 섞어 복잡하게 만들기
- 경고 상태마다 다른 장식 규칙을 붙이기

## 10. Preferred First-pass Design

가장 추천하는 첫 구현안:

- neutral: white text only
- AX: amber text + `i.circle`
- IDLE: orange-red text + `i.circle` 또는 color-only fallback
- info click: small anchored popover (`AX` 우선)
- close affordance: hover 시 secondary element

## 11. Review Questions

디자인 리뷰 때 반드시 물어야 할 질문:

- 이게 아직도 mini처럼 느껴지는가?
- AX가 bug처럼 보이지 않고 “설정 필요”로 읽히는가?
- IDLE이 경고이되 공격적이지 않은가?
- info 버튼이 보이지만 과하게 존재감을 차지하지 않는가?

## 12. Bottom Line

- mini overlay는 정보량보다 해석 가능성이 중요하다.
- 따라서 상태 피드백의 핵심은 `더 많은 텍스트`가 아니라:
  - `적절한 색상`
  - `작은 info affordance`
  - `짧은 설명 popover`

의 조합이다.
