# Nudge Character Design Brief

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `content-strategist`
- Scope: character concept, emotion states, growth stages, dialogue linkage, and asset handoff

## 1. Purpose

- 이 문서는 Nudge의 가상 펫 캐릭터가 어떤 역할을 하고 어떤 감정과 행동 언어를 가져야 하는지 정의한다.
- 목표는 `visual-designer`가 비주얼 에셋을 만들고, `swiftui-designer`가 화면과 애니메이션에 바로 연결할 수 있게 하는 것이다.
- 캐릭터는 장식이 아니라 `복귀 유도`와 `긍정 강화`를 담당하는 제품 구성요소다.

## 2. Character Concept

### 2.1 Core Concept

- Working concept: `작업 메이트(work buddy)` 타입의 작은 펫
- 역할: 사용자를 감시하는 존재가 아니라, 작업 흐름을 옆에서 지켜보며 부드럽게 돌아오게 하는 동료
- 인상: 작고 단순하며 친근하지만, 너무 유아적이지는 않다
- 정서 키워드: `다정함`, `경쾌함`, `신뢰감`, `짧은 응원`, `과장 없는 반응`

### 2.2 Personality Principles

- 사용자를 평가하지 않는다.
- 명령형보다 관찰형 문장을 선호한다.
- 짧게 반응하고, 길게 설명하지 않는다.
- 실패를 강조하지 않고 복귀를 강조한다.
- 귀엽지만 방해되지 않아야 한다.

### 2.3 Visual Direction

- 실루엣이 즉시 읽혀야 한다.
- 메뉴바 및 작은 UI에서도 구분되는 단순 형태여야 한다.
- 표정과 자세만으로 상태 차이가 보이게 설계한다.
- 디테일은 적고, 색과 형태 중심으로 인지되게 한다.

## 3. Emotional Model

### 3.1 Canonical Emotion States

| Emotion | Meaning | Usage |
|---|---|---|
| `happy` | 사용자가 잘 이어가고 있음 | 복귀 직후, streak reward |
| `concern` | 알림이 누적되었지만 공격적이면 안 됨 | 장기 무입력의 담백한 확인 |
| `cheer` | 다시 해보자는 응원 | `gentle_warning`, `recovery` |
| `sleep` | 휴식 또는 비활성 상태 | break mode, suspended state |

### 3.2 Expression Rules

- `happy`는 과한 들뜸보다 안정적인 만족감으로 표현한다.
- `concern`은 비난이 아니라 "조금 기다리며 확인하는" 느낌이어야 한다.
- `cheer`는 팔/몸짓/시선으로 응원을 전달한다.
- `sleep`은 단순하고 조용하게, UI를 어지럽히지 않는 범위에서 표현한다.

### 3.3 State-to-Emotion Mapping

spec.md Content State와 캐릭터 감정의 공식 매핑. 동일 감정이 연속되는 경우 강도(intensity)로 구분한다.

| Content State | Emotion | 강도 | 비고 |
|---|---|---|---|
| `Focus` | `happy` | 기본 | 집중 중 긍정 피드백 |
| `IdleDetected` | `cheer` | mild | 가벼운 응원으로 복귀 유도 |
| `GentleNudge` | `cheer` | active | 더 적극적 응원 |
| `StrongNudge` | `concern` | mild | 걱정보다 관찰에 가까운 응원 |
| `Recovery` | `happy` | strong | 복귀 축하 |
| `Break` | `sleep` | 기본 | 휴식 모드 |
| `RemoteEscalation` | `concern` | mild | 짧은 확인 신호 |

**강도 구분 원칙:**
- `mild`: 작은 몸짓, 짧은 시선 이동, 미세한 표정 변화
- `active`: 손짓, 앞을 바라보는 자세, 명확한 표정 변화
- `strong`: 밝은 미소, 짧은 박수 반응, 안정적 정지
- `기본`: 해당 감정의 표준 표현

## 4. Growth Stages

### 4.1 Stage Model

| Stage | Name | Intent | Visual Complexity |
|---|---|---|---|
| Stage 1 | `sprout` | 초기 친숙화 | 가장 단순한 실루엣 |
| Stage 2 | `buddy` | 일상적 동행 | 표정/포즈가 조금 더 풍부 |
| Stage 3 | `guide` | 안정적 지원감 | 성숙한 응원 표현, 과장 감소 |

### 4.2 Stage Rules

- 성장 단계는 보상 과열이 아니라 관계의 깊이로 느껴져야 한다.
- 레벨이 높아질수록 애니메이션이 화려해지는 것이 아니라 반응이 정교해진다.
- 기본 출시에서는 Stage 1과 2 중심으로 시작하고, Stage 3는 후속 확장 여지를 남긴다.

### 4.3 Unlock Signals

- `sprout` -> `buddy`: 누적 집중 또는 연속 복귀 달성
- `buddy` -> `guide`: 장기 streak 또는 일일 요약 목표 달성
- 단계 전환은 과한 축하보다 짧은 확인 문구와 함께 제공한다.

## 5. Free/Pro Pet Visibility

gamification-system.md의 Free/Pro 경계와 일치하는 캐릭터 가시성 정의.

| 항목 | Free | Pro |
|---|---|---|
| 성장 단계 | `sprout` 고정 | `sprout` → `buddy` → `guide` 성장 |
| 감정 표현 | `happy`, `cheer`, `sleep` (3가지) | `happy`, `cheer`, `concern`, `sleep` (4가지 전체) |
| `concern` 감정 | 사용하지 않음 | StrongNudge, RemoteEscalation에서 표현 |
| 커스텀 액세서리 | 없음 | 레벨/성장에 따른 액세서리 해금 |
| 펫 상세 화면 | 기본 상태만 표시 | 성장 이력, 액세서리, 상세 상태 |

**설계 원칙:**
- Free 사용자에게도 캐릭터는 보이지만, `concern` 감정이 없으므로 StrongNudge에서도 `cheer`(active)로만 대응한다.
- Pro 사용자의 `concern` 감정은 비난이 아닌 관찰/응원 혼합 톤으로 유지한다 (3.2 Expression Rules 참조).
- Free에서 Pro 전환 시 즉시 `concern` 감정과 성장 시스템이 활성화된다.
- 펫 레이어는 선택 사항이며, 미니멀 모드에서는 추상형 시각 넛지로 대체할 수 있다.

## 6. Dialogue Slot Linkage

### 6.1 Slot Mapping

| Slot | Character Behavior |
|---|---|
| `focus_start` | 작업 시작을 응원하는 첫 반응 |
| `idle_notice` | 멈춤을 발견하고 조용히 시선만 보냄 |
| `gentle_warning` | 몸짓을 사용한 가벼운 재호출 |
| `strong_warning` | 더 분명한 자세로 복귀를 유도 |
| `tts_line` | 짧은 음성 메시지에 맞는 리액션만 제공 |
| `recovery` | 즉시 밝아지고 안정적인 표정으로 전환 |
| `break_ack` | 휴식을 승인하는 조용한 표정 |
| `streak_reward` | 조용한 박수나 미소 |
| `level_up` | 작은 성장 연출, 과한 폭발 이펙트 금지 |
| `remote_escalation` | 다른 기기 알림을 암시하는 연결 반응 |

### 6.2 Timing Rules

- 캐릭터 리액션은 알림 텍스트보다 먼저 길게 설명하지 않는다.
- 대사와 애니메이션은 1:1이 아니라 `짧은 반응 + 한 줄 카피` 구조를 기본으로 한다.
- 동일 슬롯 내 반복은 되도록 표정 변주로 풀고, 문구 재사용은 줄인다.

## 7. Prohibitions

- 감시자, 교관, 처벌자처럼 보이는 연출 금지
- 울거나 죄책감을 유발하는 과도한 연출 금지
- 작업 흐름을 끊는 과한 점프 스케어나 하드 코미디 금지
- 화려한 이펙트로 UI를 가리는 연출 금지
- 너무 아기자기한 유아풍 스타일로만 고정되는 것 금지
- 사용자 행동을 비난하거나 평가하는 표정 금지

## 8. Asset Handoff

### 8.1 Deliverables for Visual Designer

- 캐릭터 기본 실루엣
- Stage 1~3별 포즈 가이드
- emotion state별 표정 시트
- 메뉴바 축약형 아이콘/실루엣
- 기본 색상 팔레트와 경계선 처리 기준

### 8.2 Deliverables for SwiftUI Designer

- 상태별 애니메이션 트리거 목록
- 캐릭터 표시 크기별 대응 규칙
- idle / warning / recovery / break 전환 타이밍
- 메뉴바 드롭다운용 정적 버전과 overlay용 동적 버전
- Reduce Motion 대응 대체 동작

### 8.3 File Format Guidance

- 기본 비주얼 산출물은 SVG 또는 PDF 벡터 우선
- 애니메이션은 SwiftUI native 또는 Lottie 중 하나를 명시해야 한다
- 모든 파일은 상태명과 stage명을 포함한 규칙적 네이밍을 사용한다

## 9. Animation Cues

### 9.1 Motion Principles

- 작은 움직임이 우선이다.
- 상태 전환은 0.2~0.6초 범위의 짧은 리액션을 기본으로 한다.
- 반복 루프는 단순하고 피로감이 없어야 한다.
- 사용자를 압박하는 흔들림이나 급격한 확대는 피한다.

### 9.2 Suggested Motions

- `focus_start`: 가볍게 고개를 들고 자리 잡기
- `idle_notice`: 시선 이동 또는 작은 귀/몸짓 변화
- `gentle_warning`: 한 번의 손짓 또는 앞을 바라보는 자세
- `strong_warning`: 더 또렷한 자세, 약한 펄스와 함께 강조
- `recovery`: 빠른 미소 + 안정적인 정지
- `break_ack`: 앉거나 쉬는 자세로 전환
- `streak_reward`: 짧은 박수 또는 반짝임 1회
- `level_up`: 짧은 성장 연출 후 정지

### 9.3 Accessibility Motion Rule

- `Reduce Motion`이 켜져 있으면 캐릭터는 정적 상태 또는 미세한 opacity 변화만 사용한다.
- 초당 반복되는 루프는 접근성 옵션과 충돌하지 않도록 제한한다.

## 10. Localization Notes

- 캐릭터 이름은 아직 고정하지 않는다. 이름을 먼저 고정하면 번역과 브랜드 조정이 경직될 수 있다.
- 대사는 `dialogue-pool.md`의 canonical line을 우선 사용한다.
- KR/EN 텍스트 길이 차이를 고려해 표정이 의미를 대신할 수 있어야 한다.
- 이름이 필요한 경우에도 한국어/영어에서 발음과 길이 부담이 크지 않아야 한다.
- 지나치게 의인화된 말투보다 짧고 명확한 반응이 더 중요하다.
- 신규 언어 추가 시 표정과 동작이 문구보다 먼저 의미를 전달해야 한다.

## 11. Open Questions

- 캐릭터를 완전한 동물형으로 갈지, 약간의 기계적 요소를 섞을지
- Stage 3를 초기 릴리즈에 포함할지 후속 업데이트로 둘지
- 메뉴바에서는 얼굴만 보일지, 실루엣형 아이콘만 보일지
- 캐릭터 이름을 브랜드명과 분리한 고유명사로 둘지
