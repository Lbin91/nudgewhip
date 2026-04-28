# Pet 콘텐츠 기획서

- Version: 1.1
- Created: 2026-04-28
- Updated: 2026-04-28 (리뷰 피드백 반영)
- Owner: content-strategist
- Scope: 펫 캐릭터 시각 자산, 감정 표현, 상호작용, 성장 스토리

---

## 1. 현재 상태 진단

### 1.1 있는 것
- `PetState` 모델: 5단계 성장 (egg → hatchling → juvenile → adult → elder)
- XP 시스템: 복귀 +5, 30분 세션 +10, 일일 활동 +2, streak 보너스 최대 +5
- `PetDetailView`: XP 프로그레스바, 성장 타임라인, 스탯 그리드, 리셋 (UI 자리는 있으나 탭 액션 미구현)
- `PetSummaryCard`: 메뉴바 드롭다운 요약 카드 (표시 전용, 인터랙션 없음)
- `PetProgressionService`: XP 적립 로직 (mood 계산 담당 서비스는 아직 없음)
- 대사 풀: focus_start, idle_notice, gentle_warning 등 11개 슬롯 × 3변형 (KR/EN)
- 캐릭터 디자인 브리프: "작은 악마" 컨셉, whip_devil 에셋 1개
- 펫 이름 변경: PetDetailView에 구현됨

### 1.2 없는 것 (핵심 갭)
- **감정 상태 시스템**: mood 필드, 전환 로직, 계산 서비스 전무
- **스프라이트/일러스트**: 현재 SF Symbols (egg.fill, bird.fill...)만 사용 — 캐릭터가 없음
- **성장 단계별 비주얼**: egg→elder 각 단계의 시각적 차이가 없음
- **스토리/세계관**: 펫이 왜 여기 있는지, 무엇을 원하는지에 대한 서사 없음
- **단계 전환 연출**: 진화/성장 애니메이션 없음
- **일일/주간 펫 리포트**: 펫 관점의 피드백 없음
- **커스터마이징**: 색상, 액세서리, 배경 등 개인화 요소 없음
- **상호작용**: 사용자가 펫과 할 수 있는 액션이 없음 (v1.1+)
- **콘텐츠 운영 규칙**: 대사 중복 방지, 쿨다운, 알림 과다 노출 방지 없음

---

## 2. 캐릭터 세계관

### 2.1 기본 설정
- **이름**: Whip (기본값, 사용자 변경 가능)
- **정체**: 생산성 요정 (작은 악마 형태)
- **등장 배경**: 사용자와 함께 성장하는 존재. 사용자가 집중할수록 Whip도 성장.
- **성격**: 도발적이지만 다정함. 가끔 짓궂지만 결국 응원하는 편.
- **목표**: 사용자를 "자신의 최고 버전"으로 이끄는 것

### 2.2 펫의 동기
- 사용자가 집중 → 펫이 행복해짐 (에너지 충전)
- 사용자가 방치 → 펫이 졸림/지루해함
- 사용자가 복귀 → 펫이 반가워함
- 펫의 궁극 목표: elder 단계에서 "완전한 생산성 수호자"로 진화

### 2.3 콘텐츠 톤 가드레일
- **금지**: 비난, 죄책감 유도, 실망 표현, 부정적 비교
- **worried/bored 대사**: 항상 회복 지향형으로 작성 ("다시 시작해보자!", "돌아오면 기분 좋을 거야")
- **장기 미사용자**: 비난 금지, 복귀 환영 메시지만 ("기다렸어! 이제부터 다시 시작하자")
- **복귀 유도**: 응원형 문장만 허용
- **알림 강도**: 에스컬레이션 단계와 무드 표현은 분리 — 무드가 worried라도 알림 텍스트는 부드럽게

---

## 3. 감정 시스템 (Pet Mood)

### 3.1 감정 상태 정의

| 무드 | 트리거 | 지속 시간 | 시각 표현 |
|------|--------|-----------|-----------|
| **happy** | 복귀 성공, streak 달성, 레벨업 | 30분~1시간 | 밝은 표정, 반짝이는 눈 |
| **sleepy** | 장기 방치 (30분+) | 복귀 시까지 | 졸린 눈, 하품 애니메이션 |
| **excited** | 세션 시작, XP 보너스 | 10분 | 펄쩍 뛰는 모습 |
| **worried** | idle_notice 발생 | 복귀 시까지 | 불안한 표정, 안절부절 |
| **proud** | 레벨업, daily streak 7일+ | 1시간 | 가슴 편 모습, 빛남 |
| **bored** | 활동 없는 날 3일+ | 활동 재개 시까지 | 멍한 표정, 하늘 보기 |

### 3.2 상태 전이표

| 이벤트 | 현재 상태 | → 다음 상태 | 우선순위 | 해제 조건 | UI 반영 위치 |
|--------|----------|------------|---------|----------|-------------|
| `recovery` | sleepy / worried / bored | **happy** | 1 (최고) | 30분 경과 → 기본 | SummaryCard, PetDetail |
| `session_30m_completed` | any | **proud** | 2 | 30분 경과 → 기본 | PetDetail |
| `streak_7d_achieved` | any | **proud** | 2 | 당일 종료 → 기본 | SummaryCard, PetDetail |
| `level_up` | any | **excited** | 3 | 10분 경과 → 기본 | PetDetail |
| `session_started` | 기본 | **excited** | 4 | 10분 경과 → 기본 | SummaryCard |
| `idle_started` (30분) | 기본 / happy / excited | **sleepy** | 5 | 복귀 시 | SummaryCard |
| `idle_notice` (에스컬레이션) | sleepy | **worried** | 5 | 복귀 시 | SummaryCard, 알림 |
| `multi_day_inactive` (3일+) | any | **bored** | 6 | 활동 재개 시 | SummaryCard, PetDetail |
| (시간 경과) | happy / excited / proud | **기본** | - | 자동 만료 | SummaryCard |

**우선순위 규칙**:
- 동시 충돌 시 높은 우선순위가 승리 (예: streak 달성일 + idle_notice → **proud** 우선)
- 복귀 이벤트는 모든 부정 상태를 즉시 happy로 전환
- 앱 재실행 시: `moodUpdatedAt` 기준으로 만료된 무드를 기본으로 복원

### 3.3 데이터 모델 확장
```
PetState에 추가:
- currentMoodRawValue: String (happy/sleepy/excited/worried/proud/bored/기본)
- moodUpdatedAt: Date
```

### 3.4 PetMoodService (v1 구현 대상)
- **입력 이벤트**: `recovery`, `session_started`, `session_30m_completed`, `idle_started`, `idle_notice`, `multi_day_inactive`, `streak_updated`, `level_up`
- **출력**: 현재 mood, 만료 시각, 우선순위
- **복원**: 앱 재실행 시 `moodUpdatedAt`과 현재 시각 비교 → 만료된 무드를 기본으로 복원
- **단일 계산 지점**: 모든 무드 전환은 이 서비스만 거쳐야 함

---

## 4. 상호작용 시스템 (v1.1+)

> v1에서는 제외. 에셋 없이 클릭 인터랙션은 메뉴바 앱에서 accidental tap 이슈가 크고,
> 체감 가치보다 구현 복잡도가 높음.

### 4.1 v1.1 상호작용

| 액션 | 방법 | 효과 | 쿨다운 | 일일 상한 |
|------|------|------|--------|----------|
| **쓰다듬기** | 펫 아이콘 클릭/터치 | happy 무드 전환, +1 XP | 5분 | 하루 5회 |
| **격려 받기** | 펫 길게 누르기 | 랜덤 응원 대사 출력 | 10분 | 없음 |

### 4.2 v1.2 상호작용
- 먹이주기: 세션 30분 완료 시 자동 (XP 보상, 펫 반응)
- 놀아주기: daily streak 달성 시 자동 (특수 애니메이션 + 보너스 XP)
- 배경 테마 선택
- 펫 액세서리 (모자, 날개 등 — 특정 업적 달성 시 해금)
- 펫 일기 (펫 관점 일일 요약)

---

## 5. 성장 단계별 비주얼 & 스토리

### 5.1 단계 정의

| 단계 | XP | 비주얼 | 서사 |
|------|-----|--------|------|
| **Egg** (알) | 0 | 작은 알, 가끔 흔들림 | "의지의 알이 나타났다. 안에서 무언가 꿈틀거린다." |
| **Hatchling** (부화) | 50 | 작은 악마 새끼, 큰 눈 | "Whip이 태어났다! 세상이 궁금한 아기." |
| **Juvenile** (소년) | 150 | 조금 커진 악마, 작은 뿔 | "뿔이 자라기 시작했다. Whip이 당신의 리듬을 배운다." |
| **Adult** (성체) | 350 | 완전한 체형, 날개 돋음 | "Whip이 당신의 집중과 함께 성장했다. 든든한 파트너." |
| **Elder** (수호자) | 700 | 빛나는 오라, 왕관 | "전설의 생산성 수호자. 당신의 꾸준함이 만든 기적." |

### 5.2 단계 전환 연출 (v1.1+)
- 화면 중앙 펫 팝업 (2초)
- 빛나는 효과 + 파티클
- 진화 대사 (KR/EN 각 1개):
  - Egg → Hatchling: "드디어 세상 밖으로! 반가워!" / "Hello world! Nice to meet you!"
  - Hatchling → Juvenile: "뿔이 났다! 이제 진짜 시작이야." / "Horns! Now the real adventure begins."
  - Juvenile → Adult: "날개가 돋았어. 우리 함께 더 높이!" / "Wings! Let's go higher together!"
  - Adult → Elder: "당신 덕분에 여기까지 왔어. 고마워." / "I'm here because of you. Thank you."

### 5.3 성장 경제 시뮬레이션

하루 최대 XP 추정:
- 복귀 × 5회 = 25
- 30분 세션 × 3회 = 30
- 일일 활동 = 2
- streak 보너스 = 최대 5
- **하루 최대 약 62 XP**

| 사용 시나리오 | 일평균 XP | Elder(700) 도달 예상 |
|-------------|----------|---------------------|
| 경량 (1h/일) | ~20 | 약 35일 |
| 일반 (3h/일) | ~40 | 약 18일 |
- 집중 (6h/일) | ~60 | 약 12일 |

리셋 후 재성장: 동일 속도 (XP 획득률은 리셋과 무관).
장기 이용자 고갈 방지: Elder 달성 후 커스터마이징/일기로 유지 (v1.1+).

---

## 6. 스프라이트 에셋 계획

### 6.1 에셋 산정 (v1.1+)

성장 단계별 × 감정 상태별 조합:

| | happy | sleepy | excited | worried | proud | bored | 기본 | 합계 |
|---|---|---|---|---|---|---|---|---|
| **Egg** | - | - | - | - | - | - | 1 | **1** |
| **Hatchling** | 1 | 1 | 1 | 1 | - | 1 | 1 | **6** |
| **Juvenile** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | **7** |
| **Adult** | 1 | 1 | 1 | 1 | 1 | 1 | 1 | **7** |
| **Elder** | 1 | - | 1 | - | 1 | - | 1 | **4** |
| **합계** | | | | | | | | **25** |

- Egg는 감정 없음 (알 상태) → 기본 + 흔들림 애니메이션만
- Hatchling은 proud 표현 불가 (아직 자아가 약함)
- Elder는 sleepy/worried/bored 불가 (수호자는 항상 강인함)

**에셋 분류**:

| 분류 | 수량 | 비고 |
|------|------|------|
| 정적 스프라이트 | 25 | 위 표 기준 |
| 진화 연출 시퀀스 | 4 | 6프레임 × 4단계 전환 |
| 아이들 애니메이션 | 5 | 단계별 숨쉬기/깜빡임 (egg 제외) |
| **총 에셋** | **34** | |

### 6.2 v1 대안: 에셋 없이 텍스트+SF Symbol로 대응
v1에서는 스프라이트 대신:
- `PetSummaryCard`: SF Symbol + mood 텍스트 배지 (예: "😊 행복함")
- `PetDetailView`: 현재 감정 한 줄 대사 + 최근 반응 로그
- 색상 코딩: happy=초록, sleepy=파랑, excited=주황, worried=빨강, proud=금색, bored=회색

### 6.3 스프라이트 사양
- 해상도: 128×128px (@1x), 256×256px (@2x), 384×384px (@3x)
- 포맷: PNG (투명 배경)
- 스타일: 심플한 2D 일러스트, 둥근 라인, 따뜻한 색감
- 색상 팔레트: 보라 (#7B5EA7), 주황 (#FF8C42), 크림 (#FFF5E4) 기반

### 6.4 애니메이션 프레임
- 각 감정 상태: 2프레임 (A/B 번갈아) + 정지 프레임
- 진화 연출: 6프레임 시퀀스
- 아이들 애니메이션: 4프레임 루프 (숨쉬기, 깜빡임)
- Reduce Motion 대응 필수 (정지 프레임만 표시)

---

## 7. 펫 대사 확장

### 7.1 펫 전용 대사 슬롯 (기존 dialogue-pool.md에 추가)

| 슬롯 | 상황 | 예시 (KR) |
|------|------|-----------|
| `pet_greeting` | 앱 시작 | "왔구나! 오늘도 같이 달려보자." |
| `pet_encourage` | 세션 15분 경과 | "좋아, 이대로만 가자!" |
| `pet_celebrate` | 레벨업 | "우와, 우리 더 강해졌어!" |
| `pet_miss` | 3일 미접속 복귀 | "보고 싶었어! 이제 다시 시작하자." |
| `pet_idle_reaction` | idle 상태 | "음... 뭔가 해야 하지 않아?" |
| `pet_recovery_happy` | 복귀 성공 | "돌아왔네! 역시 포기 안 해." |
| `pet_streak_proud` | 7일 streak | "일주일 연속! 우리 진짜 대단해." |
| `pet_bored` | 3일+ 미활동 | "...심심해. 같이 뭔가 하자." |
| `pet_evolution` | 단계 전환 | (5.2 진화 대사 참고) |

각 슬롯 KR/EN 각 3변형.

### 7.2 단계별 말투 변화
- **Egg**: 대사 없음 (...으로만 표현)
- **Hatchling**: 아기 말투 ("~야!", "~해?")
- **Juvenile**: 친근한 반말 ("~하자!", "~잖아")
- **Adult**: 담담한 파트너 톤 ("~할 때", "같이 가자")
- **Elder**: 지혜로운 톤 ("네가 만든 길이야", "계속 가면 돼")

### 7.3 대사 운영 규칙
- **랜덤 선택**: 각 슬롯 3변형 중 랜덤, 단 최근 1개 제외
- **중복 방지**: 동일 슬롯이 연속으로 노출되지 않도록 쿨다운 적용
- **알림 과다 방지**: 펫 대사는 메뉴바 드롭다운 내에만 표시, 시스템 알림과 분리
- **접근성**: 감정 상태는 색/표정 외에 항상 텍스트로도 전달
- **l10n key 네이밍**: `pet.dialogue.{slot}.{index}` (예: `pet.dialogue.recovery_happy.1`)
- **string key 규칙**: placeholder 없이 완성된 문장, stage별 톤은 번역 시 반영

---

## 8. 일일 펫 리포트 (v1.1+)

> v1에서는 제외. 메뉴바 앱에서 자동 노출은 흐름을 끊을 수 있음.
> v1.1에서 PetDetailView 내부 접을 수 있는 카드로 먼저 검증.

### 8.1 구성
펫 관점의 하루 요약. 매일 앱 첫 실행 시 또는 세션 종료 후 표시.

```
[Whip의 오늘]
🎯 오늘 집중: 3시간 24분
🔥 streak: 5일째!
📊 이번 주 평균보다 12% 더 집중
💬 "오늘 진짜 잘했어. 내일도 이 기세로 가자!"

[Whip의 상태]
😊 기분: 행복함
⭐ XP: 247 / 350 (Adult까지 103)
📅 함께한 지: 14일째
```

### 8.2 주간 펫 리포트
- 주간 집중 추이 그래프 (펫 표정과 함께)
- 이번 주 최고 순간
- 펫 성장 변화 (주 시작/끝 비교)
- 다음 주 목표 제안 (펫이 제안)

---

## 9. 커스터마이징 (v1.2+)

### 9.1 해금 가능한 아이템

| 아이템 | 해금 조건 | 타입 |
|--------|-----------|------|
| 금빛 왕관 | Elder 달성 | 머리 |
| 작은 날개 | 첫 복귀 성공 | 액세서리 |
| 빨간 망토 | 7일 streak | 의상 |
| 별 스티커 | 총 XP 500 | 장식 |
| 안경 | 총 100세션 완료 | 액세서리 |
| 요정 날개 | 총 1000 XP | 액세서리 |

### 9.2 배경 테마
- 기본: 보라빛 구름
- 해금: 30일 streak → 별이 빛나는 밤하늘
- 해금: Elder 달성 → 황금빛 성역

---

## 10. 구현 우선순위

### v1 — 데이터 모델 + mood 계산 + 텍스트 반영 (버전업 포함)
1. **PetState 데이터 모델 확장** — `currentMoodRawValue`, `moodUpdatedAt` 필드 추가
2. **PetMoodService 구현** — 상태 전이표 기반 무드 계산 (단일 계산 지점)
3. **기존 뷰에 텍스트+SF Symbol 반영** — PetSummaryCard에 mood 배지/한 줄 대사, PetDetailView에 감정 섹션
4. **펫 대사 슬롯 9개 추가** — KR/EN 각 3변형, 단계별 말투, 운영 규칙 적용
5. **저장/마이그레이션** — 기존 PetState 사용자 데이터에 신규 필드 기본값 채움

### v1.1 — 에셋 + 인터랙션
6. **스프라이트 에셋 34개** — 정적 25 + 진화 4 + 아이들 5
7. **단계 전환 연출** — 진화 애니메이션
8. **쓰다듬기/격려 인터랙션** — 클릭 + 쿨다운 + 일일 상한
9. **일일 펫 리포트** — PetDetailView 내부 카드 (강제 노출 아님)

### v1.2 — 개인화 + 심화
10. **커스터마이징** — 액세서리, 배경 테마
11. **주간 펫 리포트**
12. **펫 일기** — 펫 관점 일일 로그
13. **성공 지표 추적** — 복귀율, 7일 유지율, 펫 클릭률

---

## 11. 에셋 제작 가이드

### 11.1 AI 프롬프트 템플릿 (스프라이트 생성용)
```
Cute small demon character, [stage description], [mood expression],
simple 2D illustration, rounded lines, warm colors,
purple and orange palette, transparent background,
128x128px, chibi style, flat design, game asset
```

### 11.2 단계별 프롬프트 변수
- Egg: "small dark purple egg with tiny crack, glowing"
- Hatchling: "tiny purple demon baby, big round eyes, small stubby horns"
- Juvenile: "young purple demon, medium horns starting to grow, curious expression"
- Adult: "full-grown purple demon, curved horns, small wings, confident"
- Elder: "regal purple demon, golden crown, glowing aura, majestic wings"

### 11.3 감정별 프롬프트 변수
- happy: "bright smile, sparkling eyes"
- sleepy: "half-closed eyes, small yawn, Zzz"
- excited: "jumping pose, arms up, star eyes"
- worried: "furrowed brow, sweat drop, fidgeting"
- proud: "chest puffed out, confident grin, glowing"
- bored: "blank stare, slumped posture, sigh"
