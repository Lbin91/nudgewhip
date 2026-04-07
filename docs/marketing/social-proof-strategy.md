# Nudge Social Proof Strategy

- Version: 0.1
- Last Updated: 2026-04-07
- Owner: `marketing-strategist`
- Scope: testimonial 수집 → 검증 → 활용 → 랜딩 페이지 반영 파이프라인

---

## 1. Purpose

Nudge는 `attention recall tool`이라는 새로운 카테고리이므로, **사용자의 실제 경험담**이 가장 강력한 전환 도구다.
이 문서는 소셜 증명을 체계적으로 수집, 검증, 활용하는 파이프라인을 정의한다.

---

## 2. Social Proof 수집 채널

### 2.1 앱 내 피드백 (1차 채널 — 가장 높은 품질)

```
Daily Summary 화면
  └─ "How was your focus today?"
       ├─ 👍 (Good) → "이 경험을 공유해도 될까요?" 모달
       │    ├─ 동의 → 1줄 경험 입력 (선택) + 이메일 (선택)
       │    └─ 거절 → "감사합니다" (데이터만 저장)
       └─ 👎 (Not great) → "어떤 점이 불편했나요?" Issue 링크
```

**수집 데이터 구조:**
```json
{
  "type": "testimonial",
  "userId": "anonymous-hash",
  "date": "2026-04-07",
  "rating": "positive",
  "quote": "매일 오후 3시면 핸드폰을 보는데, 오늘 처음으로 바로 돌아왔어요",
  "email": "user@example.com",
  "consentToPublic": true,
  "metrics": {
    "sessionCount": 12,
    "recoveryCount": 8,
    "daysActive": 5
  }
}
```

**저장 위치:** `docs/testimonials/collected/`에 익명화 JSON 파일로 저장.

### 2.2 GitHub Issues/Discussions (2차 채널)

| 소스 | 활용 |
|------|------|
| Feature Request 코멘트 | "사용자가 원하는 것" 인용 |
| Bug Report 해결 후 코멘트 | "빠른 대응" 신뢰 형성 |
| Discussions 경험 공유 | 전체 인용 (동의 확인 후) |

### 2.3 외부 채널 (3차 채널)

| 소스 | 활용 |
|------|------|
| Product Hunt 코멘트 | PH 페이지에서 직접 인용 가능 |
| Reddit 댓글 | 스크린샷 + 링크 (Reddit 사용자명 익명화) |
| Hacker News 댓글 | HN은 실명/닉네임 공개이므로 직접 인용 가능 |
| 이메일 피드백 | 동의 확인 후 인용 |

---

## 3. Testimonial 검증 및 등급

### 3.1 등급 시스템

| 등급 | 기준 | 활용처 |
|------|------|--------|
| **⭐⭐⭐ Gold** | 실제 메트릭 데이터 첨부 + 공개 동의 + 구체적 경험 | 랜딩 페이지 Hero, PH 이미지 |
| **⭐⭐ Silver** | 공개 동의 + 구체적 경험 (메트릭 없음) | 랜딩 페이지 Testimonial 섹션, 이메일 |
| **⭐ Bronze** | 공개 동의 없음 (내부용) | 제품 개선, 내부 보고서 |
| **❌ Rejected** | 모욕적/관련없는 내용 | 폐기 |

### 3.2 검증 체크리스트

Gold 등급으로 승격하려면:
- [ ] 실제 사용 데이터가 SwiftData에 기록됨 (`recoveryCount > 0`)
- [ ] 공개 동의(`consentToPublic: true`)가 명시적임
- [ ] 인용문이 1~2문장으로 구체적임
- [ ] 스팸/봇 계정이 아님

---

## 4. Testimonial 활용 전략

### 4.1 랜딩 페이지 배치

```
┌─────────────────────────────────────────┐
│  Hero: "The moment attention drifts..." │
│  [CTA] [GitHub]                         │
├─────────────────────────────────────────┤
│  How it works (3 steps)                 │
├─────────────────────────────────────────┤
│  ⭐⭐⭐ "Gold testimonial 1"            │  ← Hero 바로 아래
│     — 이름, 역할 (예: "Sarah, Developer")│
├─────────────────────────────────────────┤
│  Features                               │
├─────────────────────────────────────────┤
│  ⭐⭐ 3개 testimonial 카드 (그리드)     │  ← Features 아래
├─────────────────────────────────────────┤
│  Privacy & Local-first                  │
├─────────────────────────────────────────┤
│  "Join X users who reclaimed focus"     │  ← 누적 사용자 수
│  [CTA]                                  │
└─────────────────────────────────────────┘
```

### 4.2 Product Hunt 활용

| 위치 | 내용 |
|------|------|
| PH 갤러리 이미지 4번째 | Gold testimonial 카드 |
| Maker Comment | "Beta期间 X명의 사용자가 Y번 복귀에 성공했습니다" |
| 첫 댓글 업데이트 | Gold testimonial 1개 인용 |

### 4.3 이메일 시퀀스 활용

| 이메일 | Testimonial 활용 |
|--------|-----------------|
| Waitlist Confirmation | "Early users say: [Silver testimonial]" |
| Early Access Invite | Gold testimonial + 메트릭 |
| Pro Launch | "X users upgraded to Pro because: [Gold testimonial]" |
| Re-engagement | "Users who returned after a break say: [Silver testimonial]" |

### 4.4 소셜 미디어 활용

| 플랫폼 | 포맷 |
|--------|------|
| X (Twitter) | Testimonial 카드 이미지 + "What our users say" |
| LinkedIn | Gold testimonial + "Why attention recall matters" 스토리 |
| Reddit | "Beta 기간 가장 인상적인 사용자 피드백 TOP 3" |

---

## 5. Testimonial 수집 UX 상세

### 5.1 👍 클릭 시 모달 흐름

```
Step 1: "Glad to hear that! 🎉"
        "Would you be willing to share your experience?"
        [Sure!] [Maybe later]

Step 2: "In one sentence, what did Nudge help you with?"
        [________________________________]
        (예시: "It caught me scrolling Twitter at 3pm")
        [Continue] [Skip]

Step 3: "Can we share your quote publicly?"
        "We'll show your first name and role (e.g., 'Jin, Developer')"
        [Yes, share it] [No, keep it private]

Step 4: "Want to stay updated on Nudge?"
        [Email (optional)] [No thanks]
        [Done!]
```

**디자인 원칙:**
- 전체 흐름 15초 이내 완료
- Step 2, 3, 4 모두 Skip 가능
- 거부 시에도 👍 데이터는 저장 (내부 메트릭용)

### 5.2 타이밍 전략

| 조건 | 트리거 | 이유 |
|------|--------|------|
| 첫 복귀 성공 후 3번째 세션 | 모달 표시 | 경험이 충분히 쌓인 시점 |
| 7일 연속 사용 | 모달 표시 | Habit 형성 사용자 |
| Daily Summary에서 👍 3회 연속 | 모달 표시 | 긍정 경험 반복 |
| Pro 업그레이드 직후 | 모달 표시 | 전환 동기 파악 |

**금지 조건:**
- ❌ 첫 실행 당일 (경험 없음)
- ❌ 권한 거부 직후 (부정적 감정)
- ❌ 알림 오탐 신고 직후 (불만 상태)
- ❌ 24시간 내 이미 표시됨 (피로도)

---

## 6. 누적 소셜 증명 지표

### 6.1 랜딩 페이지 동적 표시

```
"Join 1,247 users who reclaimed their focus"
"4,832 idle moments caught this week"
"89% of users return within 30 seconds of a nudge"
```

**데이터 소스:**
- 사용자 수: 익명화된 활성 세션 수 (SwiftData 집계, 서버 전송 시)
- idle moments: 전역 집계 (옵트인 사용자만)
- 복귀율: `recoveryCount / alertCount` 평균

**주의:** 실제 데이터만 표시. 추정치나 과장은 금지.

### 6.2 Beta期间 목표

| 지표 | 목표 | 최소 |
|------|------|------|
| Testimonial 수집 수 | 50개 | 20개 |
| Gold 등급 | 10개 | 5개 |
| 수집 전환율 (👍 → 공개 동의) | >30% | >15% |
| 랜딩 페이지 반영 Gold | 3개 | 1개 |

---

## 7. Testimonial 파일 구조

```
docs/testimonials/
├── collected/              # 원본 수집 데이터 (익명화 JSON)
│   ├── 2026-04-07_001.json
│   ├── 2026-04-07_002.json
│   └── ...
├── verified/               # 검증 완료 (등급 부여)
│   ├── gold/
│   │   ├── 001-sarah-dev.md
│   │   └── ...
│   ├── silver/
│   │   └── ...
│   └── bronze/
│       └── ...
├── landing-page/           # 랜딩 페이지에 반영된 것
│   └── current-featured.md
└── INDEX.md                # 전체 인덱스 + 통계
```

### 7.1 Verified Testimonial 템플릿

```markdown
---
id: 001
grade: gold
date: 2026-04-07
source: in-app
consentToPublic: true
---

> "매일 오후 3시면 핸드폰을 보는데, 오늘 처음으로 바로 돌아왔어요. 
> 메뉴바에서 countdown이 보이니까 '아, 또 시작했구나' 하고 바로 알겠더라고요."

**User:** Jin, Backend Developer (Seoul)
**Metrics:**
- Days active: 12
- Sessions: 47
- Recoveries: 31 (66%)
- Alerts per day: 2.3

**Why it works:**
- 구체적인 상황 (오후 3시, 핸드폰)
- 제품 작동 메커니즘 언급 (countdown)
- 긍정적 결과 ("바로 돌아왔어요")
```

---

## 8. Negative Feedback 처리

### 8.1 👎 클릭 시 흐름

```
"Sorry to hear that. Help us improve:"
[Too many nudges]
[False positives]
[Permission issue]
[Something else]
[Submit feedback] → GitHub Issue 템플릿으로 연결
```

### 8.2 부정 피드백 대응 SLA

| 유형 | 응답 시간 | 대응 |
|------|---------|------|
| Too many nudges | 48시간 | alertsPerHourLimit 조정 안내 |
| False positives | 24시간 | whitelist/일시정지 기능 안내 + 버그 리포트 |
| Permission issue | 24시간 | 온보딩 개선 백로그 등록 |
| Something else | 72시간 | 내용 확인 후 분류 |

### 8.3 부정 피드백 → 긍정 전환

부정 피드백을 해결한 후 1주일 뒤에 재접촉:
```
"Hi! We fixed the issue you reported about [X]. 
Would you mind giving Nudge another try? 
Your feedback directly shaped this improvement."
```

해결 후 👍로 전환한 사례는 **Gold testimonial**로 승격 가능:
> "처음엔 알림이 너무 많아서 불편했는데, 개발팀이 바로 수정해줬어요. 이제 완벽합니다."

---

## 9. 운영 규칙

### 9.1 허용

- ✅ 실제 사용자의 실제 인용문
- ✅ 메트릭 데이터와 함께 표시
- ✅ 익명화 (first name + role only)
- ✅ 부정적 경험 → 해결 과정 포함
- ✅ KR/EN 동시 표기 (글로벌 사용자)

### 9.2 금지

- ❌ AI 생성 testimonial
- ❌ 팀원/지인 작성 (conflict of interest)
- ❌ 과장된 결과 ("생산성이 300% 증가")
- ❌ 동의 없이 공개
- ❌ 유료 대가 제공 후 작성
- ❌ 경쟁사 비하 포함

---

## 10. Definition of Done

소셜 증명 시스템이 "완료"되려면:

- [ ] 앱 내 👍/👎 피드백 UI 배포됨
- [ ] Testimonial 수집 모달 구현됨
- [ ] `docs/testimonials/` 디렉토리 구조 생성됨
- [ ] INDEX.md 템플릿 작성됨
- [ ] Gold testimonial 1개 이상 수집됨
- [ ] 랜딩 페이지 testimonial 섹션 디자인 시안 완료
- [ ] 부정 피드백 GitHub Issue 템플릿 연동됨
