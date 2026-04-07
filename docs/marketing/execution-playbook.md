# Nudge Marketing Execution Playbook

- Version: 0.1
- Last Updated: 2026-04-07
- Owner: `marketing-strategist`
- Scope: Beta Launch Week 실행 체크리스트 및 8주차 액션 플랜

---

## 1. Purpose

이 문서는 `docs/marketing/launch-plan.md`의 전략을 **실행 가능한 태스크 단위**로 분해한다.
각 태스크는 상태(Status), 담당(Owner), 마감(Due), 산출물(Deliverable)을 가진다.

---

## 2. Status Legend

| 상태 | 의미 |
|------|------|
| `⬜ Not Started` | 아직 시작하지 않음 |
| `🟡 In Progress` | 작업 중 |
| `✅ Done` | 완료 — 산출물이 `docs/` 또는 코드에 반영됨 |
| `⏸️ Blocked` | 선행 작업 대기 중 |
| `❌ Skipped` | 전략적 판단으로 제외 |

---

## 3. Launch Week (Week 1) — Beta 공개 동시 실행

### 3.1 GitHub README 최적화

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 1.1.1 | 메뉴바 작동 GIF 녹화 (15초) | `visual-designer` | D-2 | ⬜ | `docs/assets/readme/nudge-demo.gif` |
| 1.1.2 | README에 "Why I built this" 섹션 추가 | `marketing-strategist` | D-2 | ⬜ | README.md 업데이트 |
| 1.1.3 | README에 Quick Start (3줄) 추가 | `macos-core` | D-2 | ⬜ | README.md `## Quick Start` 섹션 |
| 1.1.4 | README에 Star CTA 배지 추가 | `web-dev` | D-1 | ⬜ | README 상단 badge 영역 |
| 1.1.5 | CHANGELOG.md 템플릿 작성 | `qa-integrator` | D-1 | ⬜ | `CHANGELOG.md` |
| 1.1.6 | "Good first issue" 5개 이상 라벨링 | `macos-core` | D-0 | ⬜ | GitHub Issues 5개+ |

**검증 기준:**
- [ ] README를 처음 읽는 사람이 30초 안에 "무엇을 하는 앱인지" 이해할 것
- [ ] GIF가 autoplay되며 앱의 핵심 루프(아이콘 → idle → nudge → recovery)를 보여줄 것
- [ ] Quick Start 명령어 복사-붙여넣기로 빌드 성공할 것

### 3.2 Product Hunt 런칭

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 1.2.1 | PH 타이틀/태그라인/설명 초안 작성 | `marketing-strategist` | D-5 | ⬜ | `docs/marketing/ph-draft.md` |
| 1.2.2 | 지원 이미지 3장 준비 (스크린샷) | `visual-designer` | D-3 | ⬜ | `docs/assets/ph/` 하위 3장 |
| 1.2.3 | Maker Comment 초안 작성 | `marketing-strategist` | D-3 | ⬜ | `docs/marketing/ph-maker-comment.md` |
| 1.2.4 | Product Hunt 게시 예약 (화~목 12:01 AM PT) | `marketing-strategist` | D-1 | ⬜ | PH 스케줄 확인 |
| 1.2.5 | 런칭 당일 서포트 팀 대기 (댓글 응답) | `marketing-strategist` | D-0 | ⬜ | 2시간 내 첫 댓글 응답 |

**검증 기준:**
- [ ] Maker Comment에 개인 스토리 + 기술 스택 + 로컬 퍼스트 언급 포함
- [ ] 지원 이미지 3장이 서로 다른 가치(메뉴바 UI / 알림 작동 / 통계)를 보여줄 것
- [ ] 첫 4시간 내 50+ upvotes 목표

### 3.3 Hacker News "Show HN"

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 1.3.1 | Show HN 포스트 타이틀/URL 준비 | `marketing-strategist` | D-1 | ⬜ | `docs/marketing/hn-draft.md` |
| 1.3.2 | 첫 코멘트 (GitHub 링크 + 스토리) 작성 | `marketing-strategist` | D-1 | ⬜ | HN first comment draft |
| 1.3.3 | 게시 (Product Hunt와 같은 날 오전) | `marketing-strategist` | D-0 | ⬜ | HN 포스트 URL |

**검증 기준:**
- [ ] 타이틀이 `Show HN:`으로 시작하며 제품명 + 한 줄 설명 포함
- [ ] 첫 코멘트에 "does not collect keystroke content" 명시
- [ ] 게시 후 1시간 내 첫 댓글 응답 준비

### 3.4 Reddit 동시 게시

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 1.4.1 | r/macapps 포스트 작성 | `marketing-strategist` | D-2 | ⬜ | Reddit post draft |
| 1.4.2 | r/productivity 포스트 작성 (스토리텔링 버전) | `marketing-strategist` | D-2 | ⬜ | Reddit post draft |
| 1.4.3 | r/selfhosted 포스트 작성 (프라이버시 버전) | `marketing-strategist` | D-2 | ⬜ | Reddit post draft |
| 1.4.4 | r/opensource 포스트 작성 (기술 스택 버전) | `macos-core` | D-2 | ⬜ | Reddit post draft |
| 1.4.5 | 각 서브레딧 규칙 확인 (자기홍보 허용 여부) | `marketing-strategist` | D-3 | ⬜ | 규칙 확인 체크리스트 |

**검증 기준:**
- [ ] 4개 포스트가 서로 다른 각도지만 같은 GitHub/랜딩 페이지로 유도
- [ ] 각 서브레딧의 자기홍보 규칙 위반하지 않음
- [ ] 게시 간격 30분 이상 (스팸 필터 회피)

### 3.5 앱 내 피드백 시스템

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 1.5.1 | Daily Summary 하단 👍/👎 버튼 UI | `swiftui-designer` | D-3 | ⬜ | UI 컴포넌트 |
| 1.5.2 | 👍 클릭 시 testimonial 수집 모달 | `swiftui-designer` | D-2 | ⬜ | 모달 뷰 + 로직 |
| 1.5.3 | 👎 클릭 시 Issue 템플릿 연결 | `qa-integrator` | D-2 | ⬜ | GitHub Issue 링크 |
| 1.5.4 | 수집된 testimonial 저장 구조 | `data-architect` | D-2 | ⬜ | SwiftData 모델 또는 JSON |

---

## 4. Beta期间 (Week 2~8) — 주간 실행 루틴

### 4.1 주간 루틴 (매주 반복)

| 태스크 | Owner | 소요시간 | 비고 |
|--------|-------|:-------:|------|
| GitHub Issues 응답 (48시간 내) | `macos-core` | 1h/주 | `good first issue` 우선 |
| Reddit/PH/HN 댓글 모니터링 | `marketing-strategist` | 30m/주 | 부정 댓글 2시간 내 응답 |
| 주간 메트릭 리포트 작성 | `marketing-strategist` | 1h/금 | 아래 §6 템플릿 사용 |
| 브런치/벨로그 글 1편 (격주) | `content-strategist` | 3h/2주 | §4.2 참조 |

### 4.2 콘텐츠 마케팅 일정

| 주차 | 채널 | 주제 | Owner | Status |
|:---:|------|------|-------|--------|
| W2 | 브런치 | "당신의 집중이 깨지는 순간을 감지한다는 것" | `content-strategist` | ⬜ |
| W3 | 벨로그 | "SwiftUI 메뉴바 앱 개발기 — LSUIElement + NSEvent" | `macos-core` | ⬜ |
| W4 | 브런치 | "Forest는 나무를 심고, Nudge는 당신을 데려온다" | `content-strategist` | ⬜ |
| W5 | 벨로그 | "SwiftData로 로컬 퍼스트 앱 만들기" | `data-architect` | ⬜ |
| W6 | 브런치 | "왜 저는 차단 앱 대신 '복귀' 앱을 만들었을까" | `content-strategist` | ⬜ |
| W7 | 벨로그 | "NSEvent 전역 모니터와 Accessibility 권한의 진실" | `macos-core` | ⬜ |
| W8 | 브런치 | "Beta 8주간의 데이터 — 사람들은 얼마나 자주 딴짓할까" | `marketing-strategist` | ⬜ |

### 4.3 GitHub 스타 성장 액션

| # | 액션 | Owner | Due | Status |
|---|------|-------|-----|--------|
| 4.3.1 | 관련 오픈소스 20개 프로젝트 스타 | `marketing-strategist` | W2 | ⬜ |
| 4.3.2 | Awesome-macOS, Awesome-Swift PR | `macos-core` | W3 | ⬜ |
| 4.3.3 | Discussions에 "Feature Request" 템플릿 | `qa-integrator` | W2 | ⬜ |
| 4.3.4 | Weekly Changelog Discussions 게시 | `qa-integrator` | 매주 금 | ⬜ |

---

## 5. Pro Launch 준비 (Week 7~8)

### 5.1 Fake-Door 테스트

| # | 태스크 | Owner | Due | Status | Deliverable |
|---|--------|-------|-----|--------|-------------|
| 5.1.1 | 랜딩 페이지 Pro 섹션 디자인 | `visual-designer` | W6 | ⬜ | 디자인 시안 |
| 5.1.2 | "Upgrade to Pro" 버튼 + Coming Soon 모달 | `web-dev` | W7 | ⬜ | 랜딩 페이지 업데이트 |
| 5.1.3 | 이메일 수집 폼 연동 | `web-dev` | W7 | ⬜ | waitlist DB 연결 |
| 5.1.4 | Van Westendorp 가격 설문 설계 | `marketing-strategist` | W7 | ⬜ | 설문 폼 |
| 5.1.5 | Beta 사용자에게 가격 설문 이메일 발송 | `marketing-strategist` | W8 | ⬜ | 이메일 발송 + 응답률 |

### 5.2 Pro Launch 채널 준비

| # | 태스크 | Owner | Due | Status |
|---|--------|-------|-----|--------|
| 5.2.1 | Pro 런칭 Product Hunt 재게시 | `marketing-strategist` | W9 | ⬜ |
| 5.2.2 | Beta → Pro 업그레이드 이메일 시퀀스 | `marketing-strategist` | W8 | ⬜ |
| 5.2.3 | Testimonial 기반 랜딩 페이지 업데이트 | `web-dev` | W8 | ⬜ |
| 5.2.4 | Pro 기능 소개 영상 (30초) | `visual-designer` | W8 | ⬜ |

---

## 6. 주간 메트릭 리포트 템플릿

매주 금요일 아래 양식으로 기록. `docs/marketing/weekly-reports/`에 `YYYY-WXX.md`로 저장.

```markdown
# Nudge Weekly Report — Week XX (YYYY-MM-DD)

## Acquisition
- Landing page visits: ___
- Waitlist signups: ___ (conversion: ___%)
- GitHub stars: ___ (▲/▼ ___)
- Top traffic source: ___

## Activation
- New installs: ___
- Accessibility granted: ___ (___%)
- First recovery completed: ___ (___%)

## Retention
- D7 active: ___ (___%)
- D30 active: ___ (___%)
- Sessions per user: ___
- Alerts per active day: ___

## Feedback
- 👍 count: ___
- 👎 count: ___
- Testimonials collected: ___
- Issues opened: ___ (closed: ___)

## Key Learnings
-

## Next Week Focus
-
```

---

## 7. Risk Register

| Risk | Impact | Likelihood | Mitigation | Owner |
|------|:------:|:----------:|------------|-------|
| Product Hunt 1위 실패 | 중 | 중 | HN + Reddit 동시 게시로 분산 | `marketing-strategist` |
| Reddit 자기홍보 밴 | 높 | 낮 | §3.4 규칙 확인 필수 | `marketing-strategist` |
| Accessibility 권한 거부율 >50% | 높 | 중 | limitedNoAX 모드 가치 강화 (§3.5) | `macos-core` |
| Beta期间 critical bug | 높 | 낮 | `qa-integrator` 주간 테스트 | `qa-integrator` |
| 한국 콘텐츠 노출 부족 | 중 | 중 | 브런치 + 벨로그 + 커뮤니티 동시 게시 | `content-strategist` |
| testimonial 수집률 <5% | 중 | 중 | 👍 클릭 시 friction 최소화 | `swiftui-designer` |

---

## 8. Definition of Done

Launch Week 실행이 "완료"되려면 다음을 모두 충족해야 한다:

- [ ] README에 GIF + Why I built this + Quick Start 반영됨
- [ ] Product Hunt 게시 완료, 첫 4시간 50+ upvotes
- [ ] Show HN 게시 완료, 첫 댓글 5+
- [ ] Reddit 4개 서브레딧 게시 완료, 밴 없음
- [ ] 앱 내 👍/👎 피드백 UI 배포됨
- [ ] 주간 메트릭 리포트 1차 작성됨
- [ ] GitHub "Good first issue" 5개 이상 라벨링됨
