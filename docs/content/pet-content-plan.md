# Pet 콘텐츠 기획서

- Version: 1.0
- Created: 2026-04-28
- Owner: content-strategist
- Scope: 펫 캐릭터 시각 자산, 감정 표현, 상호작용, 성장 스토리

---

## 1. 현재 상태 진단

### 1.1 있는 것
- `PetState` 모델: 5단계 성장 (egg → hatchling → juvenile → adult → elder)
- XP 시스템: 복귀 +5, 30분 세션 +10, 일일 활동 +2, streak 보너스 최대 +5
- `PetDetailView`: XP 프로그레스바, 성장 타임라인, 스탯 그리드, 리셋
- `PetSummaryCard`: 메뉴바 드롭다운 요약 카드
- 대사 풀: focus_start, idle_notice, gentle_warning 등 11개 슬롯 × 3변형 (KR/EN)
- 캐릭터 디자인 브리프: "작은 악마" 컨셉, whip_devil 에셋 1개

### 1.2 없는 것 (핵심 갭)
- **스프라이트/일러스트**: 현재 SF Symbols (egg.fill, bird.fill...)만 사용 — 캐릭터가 없음
- **감정 상태**: 펫이 기분 좋음/나쁨/지루함 등을 표현하지 않음
- **상호작용**: 사용자가 펫과 할 수 있는 액션이 없음 (쓰다듬기, 먹이주기 등)
- **성장 단계별 비주얼**: egg→elder 각 단계의 시각적 차이가 없음
- **스토리/세계관**: 펫이 왜 여기 있는지, 무엇을 원하는지에 대한 서사 없음
- **단계 전환 연출**: 진화/성장 애니메이션 없음
- **일일/주간 펫 리포트": 펫 관점의 피드백 없음
- **커스터마이징**: 색상, 액세서리, 배경 등 개인화 요소 없음

---

## 2. 캐릭터 세계관

### 2.1 기본 설정
- **이름**: Whip (기본값, 사용자 변경 가능)
- **정체**: 생산성 요정 (작은 악마 형태)
- **등장 배경**: 사용자의 나태함을 먹고 사는 존재. 사용자가 집중할수록 Whip도 성장.
- **성격**: 도발적이지만 다정함. 가끔 짓궂지만 결국 응원하는 편.
- **목표**: 사용자를 "자신의 최고 버전"으로 이끄는 것

### 2.2 펫의 동기
- 사용자가 집중 → 펫이 행복해짐 (에너지 충전)
- 사용자가 방치 → 펫이 졸림/지루해함
- 사용자가 복귀 → 펫이 반가워함
- 펫의 궁극 목표: elder 단계에서 "완전한 생산성 수호자"로 진화

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

### 3.2 무드 전환 규칙
- 방치 → sleepy (30분) → worried (1시간+) → bored (3일+)
- 복귀 → happy (즉시, sleepy/worried에서 전환)
- 세션 30분 완료 → proud (30분간)
- 일일 streak 7일 달성 → proud (하루 종일)
- happy/proud는 자연스럽게 기본 상태로 복귀 (시간 경과)

### 3.3 데이터 모델 확장
```
PetState에 추가:
- currentMoodRawValue: String (happy/sleepy/excited/worried/proud/bored)
- moodUpdatedAt: Date
- lastInteractionAt: Date
```

---

## 4. 상호작용 시스템

### 4.1 1차 상호작용 (v1.0)

| 액션 | 방법 | 효과 | 쿨다운 |
|------|------|------|--------|
| **쓰다듬기** | 펫 아이콘 클릭/터치 | happy 무드 전환, +1 XP | 5분 |
| **격려 받기** | 펫 길게 누르기 | 랜덤 응원 대사 출력 | 10분 |
| **먹이주기** | 세션 30분 완료 시 자동 | XP 보상, 펫 반응 애니메이션 | 자동 |
| **놀아주기** | daily streak 달성 시 자동 | 펫 특수 애니메이션 + 보너스 XP | 자동 |

### 4.2 2차 상호작용 (v1.1 — 향후)
- 펫 이름 짓기/변경 (현재 구현됨)
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

### 5.2 단계 전환 연출
- 화면 중앙 펫 팝업 (2초)
- 빛나는 효과 + 파티클
- 진화 대사 (KR/EN 각 1개):
  - Egg → Hatchling: "드디어 세상 밖으로! 반가워!" / "Hello world! Nice to meet you!"
  - Hatchling → Juvenile: "뿔이 났다! 이제 진짜 시작이야." / "Horns! Now the real adventure begins."
  - Juvenile → Adult: "날개가 돋았어. 우리 함께 더 높이!" / "Wings! Let's go higher together!"
  - Adult → Elder: "당신 덕분에 여기까지 왔어. 고마워." / "I'm here because of you. Thank you."

---

## 6. 스프라이트 에셋 계획

### 6.1 최소 요구 에셋 (v1.0)

성장 단계별 × 감정 상태별 조합:

| | happy | sleepy | excited | worried | proud | bored | 기본 |
|---|---|---|---|---|---|---|---|
| **Egg** | - | - | - | - | - | - | 알 (흔들림) |
| **Hatchling** | O | O | O | O | - | O | O |
| **Juvenile** | O | O | O | O | O | O | O |
| **Adult** | O | O | O | O | O | O | O |
| **Elder** | O | - | O | - | O | - | O |

- Egg는 감정 없음 (알 상태) → 기본 + 흔들림 애니메이션만
- Hatchling은 proud 표현 불가 (아직 자아가 약함)
- Elder는 sleepy/worried/bored 불가 (수호자는 항상 강인함)

**총 스프라이트 수**: 1 (egg) + 5 (hatchling) + 6 (juvenile) + 6 (adult) + 3 (elder) + 진화 연출 4 = **25개**

### 6.2 스프라이트 사양
- 해상도: 128×128px (@1x), 256×256px (@2x), 384×384px (@3x)
- 포맷: PNG (투명 배경)
- 스타일: 심플한 2D 일러스트, 둥근 라인, 따뜻한 색감
- 색상 팔레트: 보라 (#7B5EA7), 주황 (#FF8C42), 크림 (#FFF5E4) 기반

### 6.3 애니메이션 프레임
- 각 감정 상태: 2프레임 (A/B 번갈아) + 정지 프레임
- 진화 연출: 6프레임 시퀀스
- 아이들 애니메이션: 4프레임 루프 (숨쉬기, 깜빡임)

---

## 7. 펫 대사 확장

### 7.1 펫 전용 대사 슬롯 (기존 dialogue-pool.md에 추가)

| 슬롯 | 상황 | 예시 (KR) |
|------|------|-----------|
| `pet_greeting` | 앱 시작 | "왔구나! 오늘도 같이 달려보자." |
| `pet_encourage` | 세션 15분 경과 | "좋아, 이대로만 가자!" |
| `pet_celebrate` | 레벨업 | "우와, 우리 더 강해졌어!" |
| `pet_miss` | 3일 미접속 복귀 | "보고 싶었어... 이제 괜찮아?" |
| `pet_idle_reaction` | idle 상태 | "음... 뭔가 해야 하지 않아?" |
| `pet_recovery_happy` | 복귀 성공 | "돌아왔네! 역시 포기 안 해." |
| `pet_streak_proud` | 7일 streak | "일주일 연속! 우리 진짜 대단해." |
| `pet_bored` | 3일+ 미활동 | "...심심해. 같이 뭔가 하자." |
| `pet_evolution` | 단계 전환 | (5.2 진화 대사 참고) |
| `pet_pat` | 쓰다듬기 | "킥킥, 간지러워!" / "더 쓰다듬어 줘~" |

각 슬롯 KR/EN 각 3변형.

### 7.2 단계별 말투 변화
- **Egg**: 대사 없음 (...으로만 표현)
- **Hatchling**: 아기 말투 ("~야!", "~해?")
- **Juvenile**: 친근한 반말 ("~하자!", "~잖아")
- **Adult**: 담담한 파트너 톤 ("~할 때", "같이 가자")
- **Elder**: 지혜로운 톤 ("네가 만든 길이야", "계속 가면 돼")

---

## 8. 일일 펫 리포트

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

## 9. 커스터마이징 (v1.1)

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

### Phase 1 (v1.0 — 버전업 포함)
1. **감정 시스템 데이터 모델** — PetState에 mood 필드 추가
2. **기본 무드 전환 로직** — 방치/복귀/세션 완료에 따른 무드 변경
3. **펫 대사 슬롯 10개 추가** — KR/EN 각 3변형, 단계별 말투
4. **쓰다듬기 상호작용** — 클릭으로 happy 전환 + XP
5. **일일 펫 리포트** — 첫 실행 시 펫 관점 요약

### Phase 2 (v1.1 — 후속)
6. **스프라이트 에셋 25개** — 디자이너/AI 작업
7. **단계 전환 연출** — 진화 애니메이션
8. **커스터마이징** — 액세서리, 배경 테마
9. **주간 펫 리포트**
10. **펫 일기** — 펫 관점 일일 로그

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
