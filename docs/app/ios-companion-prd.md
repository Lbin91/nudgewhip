# Nudge iOS Companion PRD

- Version: draft-1
- Last Updated: 2026-04-03
- Status: proposed
- Owner: product

## 1. Purpose

- 이 문서는 macOS Nudge와 연동되는 iOS companion app의 제품 목적, MVP 범위, 심사 리스크, 구현 전제조건을 정의한다.
- 목표는 iOS 앱을 단순한 푸시 수신기가 아니라, 사용자가 실제로 열어볼 이유가 있는 companion product로 설계하는 것이다.
- 이 문서는 구현 명세가 아니라 제품 범위와 우선순위를 고정하는 PRD 초안이다.

## 2. Product Thesis

- iOS 앱의 역할은 `Mac 집중 상태 확인용 companion dashboard + 장기 미복귀 follow-up 채널`이다.
- iOS 앱은 macOS 앱의 source of truth를 복제하지 않는다. 최신 상태와 파생 통계를 읽기 좋게 보여주는 보조 경험을 제공한다.
- push는 제품의 중심이 아니라 보조 수단이다. 앱의 중심 효용은 `상태 확인`, `통계 확인`, `notification follow-up`의 조합에 있다.
- 포지셔닝 문구는 `Mac에서 흐름이 끊겼을 때, iPhone이 조용히 이어받아 알려주는 companion` 정도가 적절하다.

## 3. Why This Direction

### 3.1 What We Are Avoiding

- 푸시 수신만 가능한 앱
- 설정 링크만 있는 얇은 companion
- 실시간 보장을 약속하는 과장된 cross-device messaging

### 3.2 Why Dashboard + Long-Absence Push Works

- 사용자가 iPhone에서 앱을 열어볼 이유가 생긴다.
- macOS에서 이미 쌓이는 `DailyStats`, `FocusSession` 기반 데이터와 자연스럽게 연결된다.
- CloudKit의 best-effort 특성과도 맞는다. push 실패 시에도 foreground fetch로 최신 상태와 통계를 복구할 수 있다.
- App Store 심사에서 `native utility가 있는 companion app`으로 설명하기 쉬워진다.

## 4. Product Positioning

- category: `focus companion`
- core job: `지금 Mac이 어떤 상태인지 알고, 오늘/이번 주 흐름을 확인하고, 너무 오래 비웠을 때만 iPhone에서 부드럽게 복귀 안내를 받는다`
- primary user: Mac + iPhone을 함께 쓰는 기존 Nudge 사용자
- secondary user: 집중 패턴을 숫자로 확인하고 싶은 Pro 사용자

## 5. Product Principles

- iOS 앱은 독립적인 차단기나 집중 타이머가 아니다.
- 죄책감 유발보다 `상태 가시화`와 `짧은 복귀 신호`를 우선한다.
- 푸시는 드물고 명확해야 한다.
- iPhone에서 할 수 있는 일은 `확인`과 `가벼운 정리` 중심으로 제한한다.
- 데이터는 로컬 우선 철학을 유지하고, CloudKit은 상태 전달과 최소 통계 동기화에만 사용한다.

## 6. MVP Scope

### 6.1 Included

- 홈 화면
- 현재/최근 Mac 상태 스냅샷
- 오늘 요약 통계
- 주간 통계 화면
- 장기 미복귀 push 수신
- 최근 원격 알림 히스토리
- CloudKit 기반 동기화 상태 표시
- 권한/연결 상태 안내

### 6.2 Excluded

- iPhone에서 직접 idle detection 수행
- iPhone에서 Mac 제어 또는 세션 강제 종료
- iPhone 전용 집중 타이머
- 복잡한 편집 기능
- 펫 육성 메인 경험
- Apple Watch, Live Activity, widgets 초기 지원

## 7. User Value by Screen

### 7.1 Home

- 지금 Mac이 `monitoring`, `alerting`, `break`, `offline`, `limited` 중 무엇인지 즉시 보인다.
- 마지막 입력 시각 또는 마지막 상태 변경 시각을 보여준다.
- 오늘의 핵심 숫자 3~4개를 카드로 요약한다.
- `아직 돌아오지 않았음` 같은 장기 이탈 상태는 홈에서 가장 강하게 드러난다.

### 7.2 Stats

- 일별/주별로 패턴을 본다.
- 단순 총합보다 `복귀까지 걸린 시간`, `이탈 빈도`, `회복 추세`를 강조한다.
- 사용자는 “오늘 왜 흐름이 자주 끊겼는지”를 가볍게 해석할 수 있어야 한다.

### 7.3 Alerts

- 최근 iOS follow-up 알림 기록을 확인한다.
- 알림을 놓쳤더라도 앱 안에서 이유와 시각을 다시 볼 수 있다.
- push는 단발성 알림이 아니라 alert history의 엔트리로 남는다.

### 7.4 Settings / Status

- iCloud 미로그인, 알림 비허용, Mac 미연결, Pro 비활성 같은 상태를 이해하기 쉽게 보여준다.
- 사용자가 고쳐야 할 문제를 앱 안에서 진단할 수 있어야 한다.

## 8. Information Architecture

- Tab 1: `Home`
- Tab 2: `Stats`
- Tab 3: `Alerts`
- Tab 4: `Settings`

초기 IA 원칙:

- Home은 요약과 상태 중심
- Stats는 설명 가능한 숫자 중심
- Alerts는 follow-up 기록 중심
- Settings는 문제 해결 중심

## 9. MVP Functional Spec

### 9.1 Home

- 상태 배지: `Monitoring`, `Alerting`, `Break`, `Needs Attention`, `Mac Setup Needed`, `Offline`
- 보조 문구: 마지막 상태 변경 시각
- 오프라인 감지 규칙: 마지막 동기화(상태 업데이트) 후 일정 시간(예: 1시간) 이상 지나면 Mac 전원을 껐거나 네트워크 연결이 끊긴 것으로 간주해 `Offline` (혹은 연결 단절) 상태로 강제 전환하여 표시
- 요약 카드:
- 오늘 집중 시간
- 오늘 이탈 횟수
- 평균 복귀 시간
- 현재 streak 또는 오늘 완료 세션 수

### 9.2 Stats

- 시간 범위: `Today`, `Last 7 Days`
- 지표:
- total focus duration
- alert count
- recovery count
- average recovery time
- longest focus duration
- completed session count
- 시각화:
- 일별 바 차트 1개
- 복귀 시간 추이 또는 이탈 횟수 추이 1개

### 9.3 Alerts

- 원격 에스컬레이션 기록 리스트
- 각 항목에 발생 시각, 당시 Mac 상태, 짧은 문구 표시
- 읽음/안 읽음 정도의 가벼운 로컬 상태는 허용

### 9.4 Settings

- 알림 권한 상태
- iCloud 연결 상태
- 마지막 동기화 시각
- 연결된 Mac 기기 이름 또는 식별용 라벨
- Pro 활성화 상태
- privacy/data explanation entry

## 10. Notification Policy

- iOS push는 `장기 미복귀`일 때만 보낸다.
- Step 1, 2, 3 로컬 넛지는 macOS가 책임진다.
- iOS는 Step 4 `RemoteEscalation`만 다룬다.
- 알림 문구는 짧고 비판적이지 않아야 한다.
- 알림 빈도는 매우 보수적으로 제한한다.

권장 조건:

- macOS가 이미 local escalation을 충분히 수행했을 것
- 최근 일정 시간 내 동일한 remote escalation이 없을 것
- 사용자가 break/manual pause 상태가 아닐 것
- limited/no-AX 상태는 push 대상이 아닐 것
- Mac 절전(Sleep) 모드 예외 보완: 장기 미복귀 도중 Mac이 자동 절전 모드에 진입하면 CloudKit 상태 업데이트가 불가능해져 푸시가 발송되지 않을 수 있음. 이를 우회하기 위해 Mac 잠자기 전 선제적 Record 생성이나, iOS 자체 타임아웃 기반 로컬 알림 폴백(Fallback) 로직을 구상할 것

## 11. Standalone Value and Review Risk

### 11.1 Core Risk

- iOS companion은 본질적으로 Mac 앱과 연결될 때 가장 큰 가치를 가진다.
- 따라서 심사에서 `다른 앱이 없으면 거의 쓸모없다`는 인상을 주면 4.2.3 또는 minimum functionality 맥락의 리스크가 생길 수 있다.

### 11.2 Mitigation

- 앱의 중심을 push 수신이 아니라 native dashboard 경험으로 둔다.
- 홈, 통계, 알림 히스토리, 연결 상태 진단까지 포함해 `앱 안에서 확인할 일`을 만든다.
- 첫 실행 시 샘플 화면 또는 demo data preview를 제공해 앱 구조를 이해시킨다.
- App Store 설명에서는 `real-time alert app`이 아니라 `Mac focus companion with dashboard and follow-up notifications`로 표현한다.
- push가 실패해도 앱을 열면 최신 상태를 복구할 수 있다는 점을 제품 구조로 보장한다.

### 11.3 Honest Limit

- 그래도 이 앱은 Mac Nudge 사용자에게 최적화된 companion이다.
- 따라서 완전 독립형 생산성 앱처럼 보이게 과장하지 않는다.
- 심사 대응은 `독립 앱` 주장보다 `유의미한 native companion utility` 증명에 집중한다.

## 12. Data Model Direction

### 12.1 Reuse from Existing Mac Models

- `DailyStats`
- `FocusSession` 기반 파생 집계
- runtime state summary
- remote escalation event summary

### 12.2 iOS Needs

- iOS는 raw event를 저장할 필요가 없다.
- iOS는 아래 수준의 read model이면 충분하다.
- current state snapshot
- daily summary snapshot
- 7-day aggregate snapshot
- remote alert history
- sync health metadata

### 12.3 Sync Principle

- Mac SwiftData가 source of truth다.
- CloudKit은 전달 계층이다.
- iOS는 읽기 최적화된 projection을 소비한다.
- push 미수신 시 foreground fetch로 정합성을 회복해야 한다.

## 13. Pairing and Onboarding

- 첫 실행 시 `Mac용 Nudge와 연결`을 메인 흐름으로 둔다.
- 온보딩에서 다음을 설명한다.
- iOS 앱이 하는 일
- 어떤 데이터가 동기화되는지
- 실시간 보장이 아니라 best-effort라는 점
- 알림 권한이 필요한 이유

온보딩 완료 조건:

- iCloud 사용 가능 여부 확인
- 알림 권한 요청 또는 보류
- 연결된 Mac 감지 또는 후속 안내 제공

## 14. Monetization Fit

- 기본 원칙은 `Pro를 산 Mac 사용자에게 companion 가치가 확장된다`는 구조다.
- 후보안 A: iOS 앱은 무료 다운로드, Pro entitlement이 있으면 full companion 활성화
- 후보안 B: iOS 앱은 무료 다운로드, 읽기 전용 일부 공개 + Pro에서 remote alerts/advanced stats 활성화

현재 추천:

- 후보안 B
- 이유: 앱 다운로드 장벽은 낮추고, 앱 자체 효용도 일부 보여주며, 유료 가치도 유지할 수 있다.

## 15. Recommended Packaging

- Free:
- 연결 상태 확인
- 제한된 홈 상태 표시
- 최근 1일 요약 또는 샘플 통계

- Pro:
- 장기 미복귀 iOS push
- 전체 주간 통계
- 알림 히스토리
- 상세 recovery metrics

패키징 원칙:

- Free iOS도 완전히 빈 껍데기처럼 보이면 안 된다.
- 하지만 핵심 cross-device follow-up과 상세 리포트는 Pro 차별점으로 남긴다.

## 16. UX Tone

- 긴급 경보처럼 느껴지지 않아야 한다.
- “딴짓 감시”보다 “흐름 복귀 보조”로 느껴져야 한다.
- 홈은 차분한 상태 가시화, 알림은 짧은 리마인드, 통계는 약한 코칭 톤을 유지한다.

예시 문구 방향:

- `Mac에서 입력이 잠시 멈췄어요.`
- `아직 복귀하지 않았어요. 필요하면 흐름을 다시 시작해보세요.`
- `오늘은 복귀가 빨랐어요. 흐름이 잘 이어지고 있어요.`

## 17. Success Metrics

- iOS 앱 설치 후 7일 내 재방문율
- Home 화면 조회 빈도
- Stats 화면 조회율
- RemoteEscalation 수신 후 Mac 복귀율
- iOS 연동 기능이 있는 Pro 전환율
- 알림 off 전환율과 uninstall rate

## 18. Open Questions

- iOS에서 streak를 전면에 둘지, 보조 지표로 둘지
- Free iOS에서 어디까지 통계를 보여줄지
- 알림 히스토리를 CloudKit record로 둘지, iOS 로컬 inbox로 둘지
- Mac 미연결 상태에서 보여줄 demo mode 수준
- iPhone 홈 화면 위젯을 Phase 2에 넣을지, 이후로 미룰지

## 19. Recommendation

- 현재 방향은 `통계 대시보드 + 장기 미복귀 push`로 고정하는 것이 맞다.
- 단, 실제 제품 정의는 `push 앱`이 아니라 `focus companion app`이어야 한다.
- iOS MVP의 중심 화면은 `Home + Stats`이고, push는 그 위에 얹히는 follow-up 채널이어야 한다.
- 이후 구현 단계에서는 이 문서를 기준으로 `iOS IA`, `CloudKit projection schema`, `Free/Pro entitlement split` 문서를 추가로 분리한다.
