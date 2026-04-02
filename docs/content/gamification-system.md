# Nudge Gamification System

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `content-strategist`
- Scope: focus progress, streak, rewards, anti-gaming contract

## 1. Purpose

- 이 문서는 Nudge의 보상 구조를 정의한다.
- 목표는 사용자의 집중을 과도하게 자극하지 않으면서 꾸준함을 강화하는 것이다.
- 게이미피케이션은 핵심 기능이 아니라 `복귀와 지속`을 돕는 보조 시스템이다.

## 2. Design Principles

- 보상은 즉시 이해 가능해야 한다.
- 보상은 과도한 중독성보다 건강한 습관 형성을 우선한다.
- 사용자가 보상을 조작해서 점수를 부풀리기 어렵게 설계한다.
- 일일 요약은 성과와 개선점을 함께 보여준다.

## 3. Reward Model

### 3.1 XP Rules

- `focus minute`마다 XP를 부여한다.
- 집중 세션이 알림 없이 유지될수록 XP 가중치를 약간 높일 수 있다.
- 복귀 성공은 소량의 보너스 XP를 준다.
- 휴식 모드 시간은 XP 산정에서 제외한다.
- 화이트리스트 일시중지는 XP에 반영하지 않는다.

### 3.2 Level Rules

- 레벨은 누적 XP 기반으로 상승한다.
- 레벨업은 시각적 보상과 짧은 문구만 제공한다.
- 레벨업 효과는 과도한 애니메이션보다 명확한 피드백이 우선이다.
- 레벨은 초반에 빠르게, 이후에는 점진적으로 느려질 수 있다.

### 3.3 Streak Rules

- `streak`은 연속 집중 일수 또는 연속 무알림 세션으로 정의할 수 있다.
- 이 문서에서는 `daily streak`와 `session streak`을 분리할 수 있게 설계한다.
- streak는 깨졌을 때 처벌보다 복귀 동기를 제공해야 한다.
- streak 복구는 가능하지만, 무한 리셋 조작은 허용하지 않는다.

### 3.4 Reward Surfaces

- 메뉴바 요약
- 드롭다운 내 펫 상태
- 일일 통계 카드
- 연속 집중 알림

## 4. Suggested Metrics

### 4.1 Session Metrics

- 집중 세션 길이
- 알림 발생 횟수
- 복귀 성공 횟수
- 무알림 세션 수
- 최고 연속 집중 시간

### 4.2 Daily Metrics

- 일일 총 집중 시간
- 일일 경고 횟수
- 일일 복귀 성공률
- 일일 streak 유지 여부
- 오늘의 성장 요약

## 5. Anti-Gaming Rules

- 키 입력 내용을 점수로 사용하지 않는다.
- 매우 짧은 세션 반복으로 XP를 무한 적립하지 못하게 최소 세션 길이를 둘 수 있다.
- 동일 패턴의 강제 시작/종료를 반복해 streak를 조작하지 못하게 한다.
- 휴식 모드와 whitelist pause는 보상 계산에서 분리한다.
- idle detector를 우회해도 보상상 이득이 생기지 않도록 session boundary를 엄격히 관리한다.

## 6. Daily Summary Contract

- 일일 요약은 하루 종료 시점 또는 다음 실행 시점에 표시할 수 있다.
- 요약에는 성공한 점과 다음에 개선할 점을 같이 보여준다.
- 요약 문구는 죄책감을 유발하지 않는다.
- 요약 데이터는 raw input이 아니라 session aggregate를 사용한다.

### 6.1 Summary Fields

- 오늘의 총 집중 시간
- 알림 발생 횟수
- 가장 긴 집중 구간
- streak 상태
- 펫 성장 상태

## 7. Pet and Reward Link

- 펫은 보상 시각화 계층이다.
- 펫 레벨과 XP는 연동될 수 있지만, 핵심 진실 원천은 XP 규칙이다.
- 펫 상태는 `PetState`에서 관리하고, 보상 계산 로직과 분리한다.

## 8. Data Dependencies

- `FocusSession`은 XP와 streak의 원천 데이터가 된다.
- `DailyStats`는 일일 요약 집계에 사용된다.
- `PetState`는 레벨과 성장 표현에 사용된다.
- `UserSettings`는 XP 계산의 일부 옵션, 예를 들어 알림 허용/휴식 모드 정책과 연결된다.

## 9. Implementation Constraints

- 계산은 session 종료 시 재계산 가능해야 한다.
- 보상 계산은 deterministic 해야 한다.
- 로컬 저장소가 source of truth이며, 서버 동기화는 보상 계산의 전제 조건이 아니다.
- 보상 변경 시 기존 세션 데이터에 대한 마이그레이션 가능성을 고려한다.

## 10. UX Constraints

- 보상 문구는 짧아야 한다.
- 복귀 직후에는 강한 축하보다 안정적인 피드백이 우선이다.
- 사용자가 보상을 보려고 작업을 멈추게 해서는 안 된다.
- 게이미피케이션 UI는 메뉴바와 분리된 상세 화면에서 더 많이 보여줄 수 있다.
