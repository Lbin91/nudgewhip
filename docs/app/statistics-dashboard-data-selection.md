# Statistics Dashboard Data Selection

- Version: draft-1
- Last Updated: 2026-04-12
- Status: active
- Owner: product / engineering

## 1. 목적

- 현재 NudgeWhip가 이미 수집하거나 파생 계산할 수 있는 정보를 코드 기준으로 정리한다.
- 그중 어떤 정보가 실제 사용자에게 도움이 되는지, 어떤 정보는 내부 운영용으로만 남겨야 하는지 판단한다.
- 통계 대시보드를 `감시 도구`가 아니라 `복귀 코치`로 느끼게 하는 정보 구조를 제안한다.

## 2. 판단 기준

### 2.1 타겟 사용자

`docs/app/spec.md` 기준 주요 타겟은 아래 두 그룹이다.

- 1차: Mac + iPhone을 함께 쓰는 지식노동자
  개발자, 디자이너, 창업자, 작가처럼 책상 앞에서 몰입 시간이 중요한 사용자
- 2차: 시험 준비/학습 사용자
  장시간 자리에 앉아 있지만 집중 흐름이 자주 끊기는 사용자

이 사용자들은 단순히 "얼마나 오래 일했는가"보다 아래 질문에 더 민감하다.

- 내가 오늘 실제로 다시 집중으로 복귀했는가
- 넛지가 너무 많았는가, 적절했는가
- 어느 시간대와 어떤 작업 맥락에서 흐름이 잘 이어졌는가
- 앱이 나를 감시하는 느낌 없이 도움이 되는가

### 2.2 대시보드 선정 원칙

- 행동 변화를 유도할 수 있는 정보만 올린다.
- 한눈에 이해되지 않는 raw 데이터는 올리지 않는다.
- 프라이버시 설명이 어려운 정보는 제외하거나 후순위로 둔다.
- 제품의 톤인 `recovery, not restriction`에 맞는 지표를 우선한다.
- 설정값, 내부 디버그 값, 식별자 같은 운영 정보는 대시보드가 아니라 설정/내부 로깅에 남긴다.

## 3. 현재 수집 중인 정보 목록

아래 목록은 현재 코드베이스 기준이다.

### 3.1 포커스 세션 데이터

Source:
`nudgewhip/Shared/Models/FocusSession.swift`
`nudgewhip/Services/SessionTracker.swift`

현재 저장 중인 정보:

- 세션 시작 시각 `startedAt`
- 세션 종료 시각 `endedAt`
- 세션 종료 사유 `endReason`
- 모니터링 활성 여부 `monitoringActive`
- 휴식 모드 여부 `breakMode`
- 화이트리스트에 의한 pause 여부 `whitelistedPause`
- 알림 발생 횟수 `alertCount`
- 복귀 횟수 `recoveryCount`
- 마지막 알림 시각 `lastAlertAt`
- 레코드 생성 시각 `createdAt`

이 데이터로 이미 계산 가능한 것:

- 총 집중 시간
- 완료 세션 수
- 최장 집중 블록
- 세션별 알림 밀도
- 종료 사유 분포

### 3.2 알림-복귀 구간 데이터

Source:
`nudgewhip/Shared/Models/AlertingSegment.swift`
`nudgewhip/Services/SessionTracker.swift`
`nudgewhip/Shared/Models/DailyStats.swift`

현재 저장 중인 정보:

- alerting 시작 시각 `startedAt`
- 복귀 시각 `recoveredAt`
- 해당 구간의 최대 에스컬레이션 단계 `maxEscalationStep`

이 데이터로 이미 계산 가능한 것:

- 복귀까지 걸린 시간
- 평균 복귀 시간
- 최장 복귀 시간
- recovered alert 수
- recovery rate

### 3.3 앱 사용 구간 데이터

Source:
`nudgewhip/Shared/Models/AppUsageSegment.swift`
`nudgewhip/Services/AppUsageTracker.swift`
`nudgewhip/Shared/Models/AppUsageSnapshot.swift`

현재 저장 중인 정보:

- 전면 앱 bundle identifier
- 앱 표시 이름 `localizedName`
- 프로세스 식별자 `processIdentifier`
- 앱 활성 시작 시각 `startedAt`
- 앱 비활성 전환 시각 `endedAt`
- 어떤 focus session에 속하는지 관계 정보

이 데이터로 이미 계산 가능한 것:

- 기간별 top apps
- primary app
- 앱별 집중 시간
- 앱별 전환 횟수 `transitionCount`

주의:

- window title, URL, typed content, terminal contents/history는 수집하지 않는다.
- 현재 앱 수준 측정은 `focus session 안에서 frontmost였던 앱` 기준이다.

### 3.4 파생 통계 스냅샷

Source:
`nudgewhip/Shared/Models/DailyStats.swift`
`nudgewhip/Views/StatisticsDashboardView.swift`
`nudgewhip/Services/MenuBarViewModel.swift`

현재 계산 중인 정보:

- 오늘 요약 `today`
- 이번 주 요약 `thisWeek`
- 최근 7일 요약 `last7Days`
- 총 집중 시간
- 알림 수
- recovery rate
- 최장 집중 시간
- 완료 세션 수
- recovered alert 수
- 평균 복귀 시간
- top apps

즉, 통계 대시보드의 핵심 뼈대는 이미 존재한다.

### 3.5 설정 데이터

Source:
`nudgewhip/Shared/Models/UserSettings.swift`
`nudgewhip/Shared/Models/WhitelistApp.swift`

현재 저장 중인 정보:

- idle threshold
- gentle / strong alert lead time
- 시간당 alert 제한
- notification nudge 제한
- break suggestion 사용 여부
- Pro 잠금 해제 여부
- 언어 설정
- 펫 표시 모드
- countdown overlay on/off 및 위치
- schedule 사용 여부와 시작/종료 시각
- whitelist 앱 목록

이 데이터는 제품 동작에 중요하지만, 대부분은 통계 대시보드용 정보가 아니다.

### 3.6 펫/보상 데이터

Source:
`nudgewhip/Shared/Models/PetState.swift`

현재 저장 중인 정보:

- 펫 부화 단계
- 캐릭터 타입
- 감정 상태
- 경험치
- 레벨
- 일일 streak
- 마지막 focus session 종료 시각

이 정보는 동기부여 시스템에는 중요하지만, 통계 대시보드의 중심이 되면 제품이 가볍게 보일 수 있다.

## 4. 대시보드 관점의 사용자 가치 평가

### 4.1 바로 노출할 가치가 높은 정보

#### 총 집중 시간

- 사용자가 가장 빠르게 이해할 수 있는 기본 지표다.
- 지식노동자와 학습자 모두에게 공통 가치가 있다.
- 단독 지표로는 부족하지만 대시보드 첫 줄에는 필요하다.

#### 완료 세션 수

- "한 번에 오래 버텼는가"만이 아니라 "복귀 루프를 여러 번 완성했는가"를 보여준다.
- 긴 집중 블록이 어려운 사용자에게도 성취감을 준다.

#### 최장 집중 블록

- 오늘 가장 잘 됐던 흐름의 길이를 보여준다.
- 사용자가 자신의 최적 리듬을 느끼기 쉽다.

#### 알림 횟수

- 넛지가 과한지 적절한지 판단하게 해주는 안전 지표다.
- 단, 단독 성과 지표로 두면 죄책감을 만들 수 있으므로 recovery 지표와 같이 보여야 한다.

#### recovery rate

- NudgeWhip의 제품 철학과 가장 맞는 핵심 지표다.
- "얼마나 자주 흔들렸는가"보다 "얼마나 다시 돌아왔는가"를 보여준다.

#### 평균 복귀 시간

- 넛지 이후 흐름 복귀까지 걸리는 시간을 보여준다.
- 타겟 사용자에게 매우 실용적이다.
- 알림 횟수보다 행동 변화 해석에 더 도움이 된다.

#### 기간별 추이

- 오늘, 이번 주, 최근 7일 비교는 과거 회고와 현재 조정을 동시에 가능하게 한다.
- 절대값보다 패턴 인식에 도움이 된다.

#### top apps

- 앱이 사용자를 감시하지 않으면서도 작업 맥락을 설명해 주는 좋은 지표다.
- 특히 개발자, 디자이너, 작가에게 "어떤 툴에서 몰입이 이어졌는가"를 보여주는 가치가 있다.

### 4.2 보조 지표로는 유효하지만 전면 배치는 불필요한 정보

#### recovered alert 수

- recovery rate를 구성하는 근거로는 좋다.
- 다만 메인 KPI로 두면 숫자 설명력이 약하다.

#### 최장 복귀 시간

- 이상치나 나쁜 날을 보여주는 데는 유용하다.
- 상단 KPI에 두기보다는 detail card나 코칭 문구의 근거로 쓰는 편이 낫다.

#### 앱 전환 횟수

- 멀티태스킹 성향이나 컨텍스트 스위칭을 읽는 데 도움이 될 수 있다.
- 하지만 현재 단계에서는 해석 비용이 높다.
- `top apps` 카드의 보조 텍스트 정도가 적절하다.

#### 종료 사유 분포

- pause가 많은지, whitelist가 자주 개입하는지 보는 데는 유용하다.
- 그러나 제품 초기 대시보드에서는 운영 정보처럼 느껴질 가능성이 높다.

### 4.3 수집 중이어도 대시보드 비노출이 맞는 정보

#### raw timestamp와 식별자

- `lastAlertAt`, `createdAt`, `processIdentifier`, raw `bundleIdentifier`는 내부 계산 근거다.
- 사용자에게 직접 보여줄 가치가 거의 없다.

#### 세부 설정값

- idle threshold, alert lead, 시간당 제한, overlay 위치 등은 설정 화면의 정보다.
- 대시보드에 올리면 회고보다 설정 페이지처럼 보이게 된다.

#### whitelist 목록

- 기능적으로 중요하지만 통계 대시보드의 핵심 질문과는 거리가 있다.
- 설정 또는 관리 화면에 두는 편이 맞다.

#### 펫 레벨 / 경험치 / 부화 상태

- 리텐션 장치로는 의미가 있다.
- 하지만 통계 대시보드 중심부에 두면 제품의 seriousness가 약해진다.
- 별도 `Pet` 섹션이나 요약 위젯으로 분리하는 편이 낫다.

## 5. 추천 대시보드 정보 구조

### 5.1 핵심 원칙

- 첫 화면은 `오늘 내가 다시 돌아왔는가`에 답해야 한다.
- 두 번째 레이어는 `언제/어떤 맥락에서 잘 됐는가`를 보여줘야 한다.
- 세 번째 레이어만 설정 또는 게임화 정보로 확장한다.

### 5.2 추천 KPI 세트

상단 KPI strip 후보:

- 총 집중 시간
- 완료 세션 수
- recovery rate
- 최장 집중 블록

선정 이유:

- 네 지표가 함께 있을 때 `양`, `반복`, `복귀`, `몰입 품질`을 동시에 설명한다.
- 알림 수를 상단 KPI에서 빼면 죄책감 유발 가능성을 줄일 수 있다.
- 알림 수는 recovery loop 카드 안에서 문맥과 함께 보여주는 편이 더 적절하다.

### 5.3 추천 상세 섹션

#### Focus Trend

- 기간별 일자 막대 차트
- 보여줄 값: 일별 총 집중 시간
- 목적: 주간 흐름 변화 확인

#### Recovery Loop

- 보여줄 값:
  alertCount
  recoverySampleCount
  averageRecoveryDuration
- 목적:
  넛지가 단순히 많이 울리는지, 실제로 복귀를 돕는지 판단

#### Top Apps During Focus

- 보여줄 값:
  top 3 apps
  primary app
  각 앱의 집중 시간
  필요하면 보조로 transitionCount
- 목적:
  사용자가 자신의 몰입 맥락을 부드럽게 회상하게 함

### 5.4 추천 비노출 또는 후순위 항목

- raw alert timeline
- 분 단위 상세 로그
- distraction score 같은 단일 점수
- 감정 유발형 랭킹
- 앱 카테고리 기반 원인 추정
- 브라우저/문서/터미널 내부 내용

## 6. 실제 화면 추천안

현재 구현 방향과 가장 잘 맞는 기본 구성은 아래다.

1. 상단: KPI strip
   총 집중 시간 / 완료 세션 수 / recovery rate / 최장 집중 블록
2. 중단: Focus Trend
   오늘, 이번 주, 최근 7일 전환 가능
3. 하단 1: Recovery Loop
   alerts / recovered alerts / avg recovery
4. 하단 2: Top Apps
   privacy-safe explanatory card

이 구조의 장점:

- 이미 계산 중인 `StatisticsSnapshot`과 `AppUsageSnapshot`으로 대부분 충족된다.
- 제품 메시지인 `복귀`를 중심에 둔다.
- 프라이버시 고지와 충돌하지 않는다.

## 7. 향후 확장 후보

현재 저장 데이터 기준 또는 작은 모델 확장으로 다음을 검토할 수 있다.

- `sessionsOver30mCount`
  긴 몰입 유지 여부를 더 명확히 보여줌
- `hourlyAlertCounts`
  어떤 시간대에 흐름이 자주 깨지는지 확인 가능
- `endReason` 기반 회고 카드
  수동 pause와 whitelist pause가 많으면 설정 조정 유도 가능

단, 아래 원칙은 유지해야 한다.

- 대시보드는 원인 추정 엔진이 아니다.
- 사용자를 평가하거나 감시하는 문법을 쓰지 않는다.
- raw log를 보여주는 방향으로 가지 않는다.

## 8. 최종 제안

현재 수집 중인 정보 중, 통계 대시보드에 우선 채택해야 할 정보는 아래다.

- 총 집중 시간
- 완료 세션 수
- 최장 집중 블록
- recovery rate
- 평균 복귀 시간
- 알림 횟수
- 기간별 집중 추이
- top apps during focus

반대로, 현재 수집 중이어도 통계 대시보드 전면에 두지 말아야 할 정보는 아래다.

- raw timestamp
- process / bundle 식별자
- 상세 설정값
- whitelist 목록
- 펫 레벨/경험치
- minute-by-minute 로그

정리하면, NudgeWhip의 대시보드는 `얼마나 감시했는가`를 보여주는 화면이 아니라 `사용자가 얼마나 다시 흐름으로 돌아왔는가`를 보여주는 화면이어야 한다. 현재 코드베이스는 이미 그 방향의 핵심 지표를 계산할 수 있는 상태이며, 제품적으로도 그 선택이 가장 타당하다.
