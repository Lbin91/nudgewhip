# Nudge Competitive Analysis

- Version: 0.2
- Last Updated: 2026-04-02
- Owner: `marketing-strategist`
- Scope: positioning against Forest, Freedom, RescueTime, ScreenZen/one sec, and Korean market tools

## 1. Positioning Summary

- Nudge는 차단 앱도, 순수 추적 앱도 아니다.
- 핵심 카테고리는 `attention recall tool`이다.
- 사용자가 딴짓을 시작한 순간 다시 돌아오게 만드는 것이 목적이다.

## 2. Competitor Profiles

### 2.1 Forest

- **가격:** $3.99 (iOS), 무료 (Android, 광고 포함), Chrome 확장 무료
- **플랫폼:** iOS, Android, Chrome 확장, Windows/Mac (데스크톱)
- **핵심 기능:** 뽀모도로 타이머, 나무 성장 게이미피케이션, 친구 챌린지, 집중 세션 히스토리
- **MAU 추정:** ~500만 (App Store 누적 다운로드 및 리뷰 패턴 기반 추정)
- **평점:** iOS 4.7/5, Android 4.5/5
- **비즈니스 모델:** 1회 구매 + 인앱 (코인으로 나무 종류 해금)
- **출처:** App Store 2026년 3월 기준, 공식 웹사이트 forestapp.cc
- **Nudge와의 겹침:** 타이머 완료 후 복귀 유도 UX, 게이미피케이션 (성장 보상)
- **Nudge와의 차이:** Forest는 사용자가 직접 타이머를 시작해야 하며, 집중 유지가 목적이다. 이탈 시 나무가 죽는 페널티 기반이다. Nudge는 이탈 자체를 자동 감지해 복귀를 유도하며, 시간 관리가 아니라 주의 관리에 집중한다.

### 2.2 Freedom

- **가격:** $8.99/월 또는 $39.99/년, 7일 무료 체험
- **플랫폼:** macOS, Windows, iOS, Android, Chrome 확장
- **핵심 기능:** 웹사이트/앱 차단, 세션 스케줄링, 락 모드 (세션 중 해제 불가), 디바이스 간 동기화 차단
- **MAU 추정:** ~100만 (구독 기반 생산성 도구 카테고리 추정)
- **평점:** macOS 4.2/5, iOS 4.1/5
- **비즈니스 모델:** 구독 (월간/연간)
- **출처:** App Store 2026년 3월 기준, 공식 웹사이트 freedom.to
- **Nudge와의 겹침:** 세션 관리, macOS 백그라운드 실행, 디바이스 간 연동
- **Nudge와의 차이:** Freedom은 접근 자체를 차단하는 억제 모델이다. 사용자가 미리 차단 목록을 설정해야 하고, 설정 없이는 아무 일도 일어나지 않는다. Nudge는 차단이 아니라 이탈 후 부드러운 복귀 유도를 제공하며, 사전 설정 없이도 자동으로 작동한다.

### 2.3 RescueTime

- **가격:** 무료 (기본), Pro $12/월 또는 $78/년
- **플랫폼:** macOS, Windows, Android, Linux
- **핵심 기능:** 자동 시간 추적, 생산성 점수, 상세 리포트, 목표 설정, FocusTime (차단 세션)
- **MAU 추정:** ~200만 (기업/개인 사용자 합산 추정)
- **평점:** macOS 4.0/5
- **비즈니스 모델:** 프리미엄 구독 (무료 기본 + Pro 유료)
- **출처:** App Store 2026년 3월 기준, 공식 웹사이트 rescuetime.com
- **Nudge와의 겹침:** 백그라운드 활동 감지, 일일 통계, 생산성 메트릭
- **Nudge와의 차이:** RescueTime은 관찰과 리포팅에 특화되어 있다. 무슨 일이 있었는지 알려주지만, 그 순간 개입하지는 않는다. Nudge는 측정이 아니라 실시간 개입과 회복에 집중하며, 이탈 감지 즉시 행동을 유도한다.

### 2.4 ScreenZen / one sec

- **가격:** ScreenZen 무료 / Pro $4.99 (1회 구매), one sec $7.99/년
- **플랫폼:** iOS (ScreenZen), iOS/Android (one sec)
- **핵심 기능:** 앱 열기 전 의도적 일시정지 (딥브리딩, 의도 질문), 스크린타임 제한, 앱 사용 패턴 분석
- **MAU 추정:** 공개 데이터 부족, one sec가 App Store에서 꾸준히 순위권 유지
- **평점:** iOS 4.5~4.6/5 (one sec 기준)
- **비즈니스 모델:** 1회 구매 / 연간 구독
- **출처:** App Store 2026년 3월 기준, 공식 웹사이트 one-sec.app
- **Nudge와의 겹침:** 사용자 개입 유도, "마찰" 기반 접근으로 습관 변화 시도
- **Nudge와의 차이:** 모바일 전용이며, 특정 앱을 열려는 순간에만 작동한다. 데스크톱 오프라인 이탈(핸드폰을 보거나 딴짓)은 감지하지 못한다. Nudge는 macOS에서 입력이 멈춘 오프라인 이탈 자체를 감지하는 구조이며, 플랫폼이 다르다.

## 3. 한국 시장 생산성 도구

한국 시장에는 글로벌 경쟁사와 직접적으로 겹치지 않지만, 사용자의 "집중 시간" 예산을 두고 경쟁하는 로컬 도구들이 있다.

### 3.1 낭만특강

- **타입:** 스터디 타이머 / 스터디 캘린더
- **플랫폼:** iOS, Android
- **특징:** 감성적 UI (필름 카메라, 공책 디자인), 스터디 그룹 기능, D-day 관리, 공부 시간 기록
- **출처:** App Store 한국 2026년 3월 기준, 공식 웹사이트
- **Nudge와의 차이:** 수동 타이머 기반이며, 사용자가 직접 시작/종료해야 한다. 모바일 전용이며, 데스크톱 이탈 감지 기능이 없다. 계획과 기록에 특화되어 있고, 실시간 개입은 제공하지 않는다.

### 3.2 Studyplanner

- **타입:** 학업 플래너
- **플랫폼:** iOS, Android
- **특징:** 시간표 관리, 과제 추적, 시험 일정 관리, 학습량 시각화
- **출처:** App Store 한국 2026년 3월 기준
- **Nudge와의 차이:** 계획 수립과 관리에 집중한다. 실시간으로 사용자가 이탈했는지 감지하거나 복귀를 유도하는 기능이 없다. 플래너 범주이며 attention recall과는 다른 문제를 해결한다.

### 3.3 기타

- **열품타 (열정 품은 타이머):** 스터디 타이머 + 그룹 스터디 기능. 수동 시작, 모바일 전용. 한국 대학생/수험생 중심 사용자층.
- **아젠다 (Agenda):** 날짜 기반 노트 앱. 메모와 일정 관리에 특화. 집중 유도 기능 없음.
- **공통 한계:** 한국 로컬 생산성 도구들은 대부분 모바일 전용이며, 수동 타이머/플래너 범주에 속한다. 데스크톱에서 발생하는 오프라인 이탈을 감지하고 개입하는 도구는 현재 한국 시장에 사실상 없다. 이는 Nudge의 macOS-first 접근이 한국 시장에서도 명확한 차별점이 됨을 의미한다.

## 4. Feature Overlap Matrix

| 기능 | Nudge | Forest | Freedom | RescueTime | one sec |
|---|:---:|:---:|:---:|:---:|:---:|
| 실시간 이탈 감지 | O | X | X | 부분 | X |
| 자동 복귀 유도 | O | 부분 | X | X | X |
| 게이미피케이션 | O(Pro) | O | X | X | X |
| 앱/웹 차단 | X | X | O | X | O |
| 시간 추적/리포트 | O(Pro) | O | X | O | X |
| macOS 백그라운드 | O | X | O | O | X |
| iOS 연동 | O(Pro) | O | O | X | X |
| 가상 펫 | O(Pro) | O(나무) | X | X | X |
| 수동 시작 필요 | X | O | O | X | O |
| 프라이버시 로컬 우선 | O | O | O | X | O |

- **O**: 해당 기능 제공
- **부분**: 제한적 또는 간접적으로만 제공
- **X**: 미제공
- **(Pro)**: Pro 플랜에서만 제공

**핵심 인사이트:** Nudge만이 "실시간 이탈 감지 + 자동 복귀 유도"를 동시에 제공한다. Forest는 타이머 완료 후 간접적 복귀 유도만 있고, RescueTime은 감지만 하고 개입은 없다. 이 조합이 Nudge의 고유한 포지셔닝 근거다.

## 5. Differentiators

- `Idle-to-recovery` 루프를 제품의 중심에 둔다
- macOS menu bar에서 즉시 보이는 상태와 복귀 행동을 제공한다
- Accessibility 권한 이유와 수집 범위를 명확하게 설명한다
- Free/Pro 차이를 `Mac only` vs `Mac + iPhone` 복귀 루프로 분리한다
- 펫과 게이미피케이션은 보조 레이어로만 사용한다
- 수동 시작 없이 자동으로 작동한다 (Forest, Freedom과의 핵심 차이)
- 입력 내용, 화면 내용을 수집하지 않는 로컬 우선 구조다 (RescueTime과의 핵심 차이)

## 6. Messaging Differences

| Theme | Nudge | Competitor Typical Pattern |
|---|---|---|
| Core promise | 딴짓이 시작되면 다시 돌아오게 한다 | 집중을 유지하게 한다 |
| User feeling | 죄책감 없이 부드럽게 복귀 | 차단, 통제, 기록 |
| Data story | 로컬 퍼스트, 최소 metadata | 활동 추적, 리포트 중심 |
| Platform story | macOS menu bar first | cross-platform generic |
| Premium story | Mac + iPhone 복귀 루프 | 더 많은 차단/리포트 |
| Trigger story | 자동 감지, 설정 불필요 | 수동 시작, 사전 설정 필요 |

## 7. Strategic Guardrails

### 7.1 원칙

- 경쟁사 비교는 기능 수가 아니라 사용자 경험의 차이로 말한다
- `blocking`, `tracking`, `reporting`보다 `recalling`을 우선한다
- 커뮤니케이션은 제품이 실제로 하는 일만 설명한다

### 7.2 허용 표현

| 표현 | 이유 |
|---|---|
| "차단 대신 복귀" | Nudge의 핵심 철학을 정확히 설명 |
| "감시 대신 동행" | 프라이버시 접근 방식 차이 표현 |
| "자동으로 감지하는 주의 관리 도구" | 기능적 차이를 사실적으로 설명 |
| "이탈 후 복귀에 집중합니다" | 포지셔닝을 명확히 하는 표현 |
| "설정 없이도 작동합니다" | 수동 시작 필요 없음이라는 실제 차이 설명 |

### 7.3 금지 표현

| 표현 | 이유 |
|---|---|
| "Forest보다 나은 집중 앱" | 직접 비교 우위 주장은 신뢰를 해친다 |
| "Freedom을 대체합니다" | 카테고리가 다르다. 대체가 아니라 보완 관계다 |
| "RescueTime보다 정확한 추적" | Nudge는 추적 도구가 아니다. 비교 기준 자체가 틀리다 |
| "모든 생산성 앱을 하나로" | 과도한 범위 주장, 실제 기능과 불일치 |
| "최고의 집중 도구" | 검증되지 않은 우위 주장 |

## 8. Risks and Competitive Response

### 8.1 General Risks

| Risk | Mitigation |
|---|---|
| 시장에서 `productivity app`으로 뭉뚱그려질 수 있다 | `attention recall tool`을 반복 사용한다 |
| Forest와 기능 비교로만 보일 수 있다 | `복귀`를 중심 메시지로 고정한다 |
| RescueTime처럼 추적 앱으로 오해될 수 있다 | 수집하지 않는 데이터와 로컬 우선 구조를 전면에 둔다 |
| Freedom처럼 강한 차단 도구로 기대될 수 있다 | Nudge는 차단이 아니라 부드러운 넛지라고 명시한다 |

### 8.2 Risks by Launch Stage with Competitive Response

#### 8.2.1 Prelaunch

| Risk | 경쟁사 X는... | Nudge는... | Response |
|---|---|---|---|
| 메시지 혼선 | Forest는 "나무를 심어 집중"으로 명확한 한 줄이 있다 | 아직 카테고리 인지도가 없다 | "이탈 감지, 복귀 유도" 한 줄을 모든 터치포인트에 고정 |
| 기능 나열 과다 | Freedom은 차단 기능 목록이 길지만 하나의 목적(차단)으로 수렴한다 | 기능이 다양해 보이면 핵심이 흐려진다 | idle-to-recovery 루프만 설명하고 나머지는 보조로 포지셔닝 |
| 프라이버시 설명 부족 | RescueTime은 활동 추적이 핵심이라 프라이버시 우려가 자연스럽다 | Nudge는 로컬 우선이지만, Accessibility 권한이 새로운 우려다 | 권한이 왜 필요한지, 무엇을 수집하지 않는지를 온보딩에서 즉시 설명 |

#### 8.2.2 Beta

| Risk | 경쟁사 X는... | Nudge는... | Response |
|---|---|---|---|
| 오탐으로 인한 반감 | Forest는 수동 시작이라 오탐이 발생하지 않는다 | 자동 감지 기반이라 오탐 가능성이 있다 | Fatigue guardrails (시간당 알림 제한, 반복 오탐 시 휴식 제안)를 강조 |
| 권한 거부로 인한 이탈 | Freedom은 Accessibility 권한 없이도 차단이 작동한다 | Nudge는 Accessibility 없이는 핵심 기능이 제한된다 | limitedNoAX 모드에서도 유용한 기능(수동 통계 등)을 제공하고, 권한 재요청 UX를 부드럽게 설계 |
| Free/Pro 가치 차이 불명확 | Forest는 1회 구매로 전 기능 사용이 가능하다 | Nudge Free와 Pro의 차이가 복귀 루프 범위로 나뉜다 | Free로 핵심 idle-to-recovery를 체험하게 하고, Pro는 "iPhone 복귀 루프 + 예외 처리 + 누적 보상"으로 명확한 추가 가치 제시 |

#### 8.2.3 Pro Launch

| Risk | 경쟁사 X는... | Nudge는... | Response |
|---|---|---|---|
| iOS 연동 기대치 과대 | Forest는 iOS-Android 간 실시간 연동이 자연스럽다 | CloudKit은 best-effort 동기화이며 실시간 보장이 아니다 | "실시간 푸시"라는 표현을 절대 사용하지 않고, "상태 전이 기반 보조 채널"로 정확히 설명 |
| 실시간 보장 오해 | Freedom은 차단이 즉시 적용되는 것이 핵심이다 | Nudge의 감지는 입력 멈춤 기반이며 약간의 지연이 있다 | "즉각 감지" 대신 "임계시간 기반 감지"로 설정하고, 타이밍 SLA를 명확히 공개 |
| 펫/보상에 대한 과도한 기대 | Forest의 나무 성장은 핵심 루프 자체이다 | Nudge의 펫은 보조 레이어다 | 펫을 마케팅 전면에 내세우지 않고, "복귀가 먼저, 보상은 그다음" 메시지를 유지 |

## 9. Data Sources

| 경쟁사 | 출처 | 기준일 |
|---|---|---|
| Forest | App Store, 공식 웹사이트 forestapp.cc | 2026년 3월 |
| Freedom | App Store, 공식 웹사이트 freedom.to | 2026년 3월 |
| RescueTime | App Store, 공식 웹사이트 rescuetime.com | 2026년 3월 |
| ScreenZen / one sec | App Store, 공식 웹사이트 one-sec.app | 2026년 3월 |
| 낭만특강 | App Store 한국 | 2026년 3월 |
| Studyplanner | App Store 한국 | 2026년 3월 |
| 열품타, 아젠다 | App Store 한국 | 2026년 3월 |

- MAU 추정치는 공식 공개 데이터가 아니며, App Store 순위, 리뷰 수, 카테고리 추세를 기반으로 한 추정값이다. 정확한 수치는 각사 공시에 따른다.
- 가격 및 평점은 기준일 현재 기준이며, 변동될 수 있다.
