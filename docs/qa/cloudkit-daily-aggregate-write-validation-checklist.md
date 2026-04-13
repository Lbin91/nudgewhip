# CloudKit Daily Aggregate Write Validation Checklist

- Version: draft-1
- Last Updated: 2026-04-13
- Owner: engineering / QA
- Scope: 실기기에서 DashboardDayProjection CloudKit write 경로 검증

## 1. Purpose

- 이 문서는 local-day daily aggregate backup이 실제 iCloud/CloudKit 환경에서 정상 동작하는지 검증하기 위한 수동 체크리스트다.
- 목표는 코드 레벨 unit/build 성공과 별도로, 실제 계정/네트워크/zone/record write가 기대대로 되는지 확인하는 것이다.

## 2. Preconditions

- macOS 기기 1대 이상
- iCloud 로그인 완료
- 대상 앱 build가 CloudKit entitlements/container 설정을 포함
- Debug/QA build에서 로그 확인 가능
- `DashboardDayProjection`가 생성될 수 있도록 최소 1개 이상의 session/recovery 데이터 존재

## 3. Validation Axes

필수 축:

- iCloud 로그인 상태
- private database 접근 가능 여부
- custom zone `NudgeWhipSync`
- 같은 day upsert overwrite
- local-day 기준 키 생성
- launch/foreground retry

권장 추가 축:

- 네트워크 on/off
- 날짜 경계 직전/직후
- timezone이 다른 시스템 환경

## 4. Step-by-step Checklist

### 4.1 Baseline account / container

- [ ] iCloud에 로그인된 상태다
- [ ] 앱이 CloudKit container entitlement를 가진 빌드다
- [ ] 첫 실행 시 CloudKit permission/connection error가 즉시 발생하지 않는다

### 4.2 Zone initialization

- [ ] 첫 write 시 `NudgeWhipSync` zone이 생성된다
- [ ] 같은 앱 재실행 후 zone 재생성이 반복되지 않는다

### 4.3 First daily projection write

- [ ] focus session 또는 recovery가 발생한 뒤 daily projection write가 수행된다
- [ ] record type은 `DashboardDayProjection`이다
- [ ] record name이 `macDeviceID__localDayKey` 규칙을 따른다
- [ ] `localDayKey`가 local timezone 기준 날짜와 일치한다

### 4.4 Same-day overwrite semantics

- [ ] 같은 날 추가 세션/alert가 생긴 뒤 동일 record가 overwrite/upsert 된다
- [ ] 같은 날 record가 중복 append되지 않는다
- [ ] `updatedAt`이 최신 계산 시각으로 갱신된다

### 4.5 Data field sanity

- [ ] `totalFocusDurationSeconds` 값이 로컬 체감과 크게 어긋나지 않는다
- [ ] `completedSessionCount`가 시작일 귀속 규칙대로 계산된다
- [ ] `hourlyAlertCountsJSON`이 24칸 구조를 유지한다
- [ ] recovery 관련 필드가 alertingSegments 기반 값과 일치한다

### 4.6 Retry behavior

- [ ] 네트워크 끊김 상태에서 write 실패 후 앱이 크래시하지 않는다
- [ ] 네트워크 복구 후 다음 trigger/foreground에서 재시도된다
- [ ] retry 후 중복 record append 없이 같은 day record가 갱신된다

### 4.7 Day boundary behavior

- [ ] 자정 직전 day의 projection이 마지막으로 flush 된다
- [ ] 자정 이후 새 `localDayKey` record로 전환된다
- [ ] 전일 record가 뒤늦게 잘못 덮어써지지 않는다

## 5. Failure Signatures

- zone 생성 실패
- private DB 접근 실패
- 동일 day에 record가 여러 개 생김
- `localDayKey`가 local timezone과 다름
- retry 후 write 누락 또는 중복 append
- 자정 이후에도 전일 key를 계속 사용

## 6. Evidence to Capture

- CloudKit Dashboard screenshot (record type / zone)
- recordName 예시
- 주요 field 값 screenshot 또는 로그
- 네트워크 off/on 재현 기록
- 날짜 경계 테스트 시각 메모

## 7. Result Template

각 검증 세션마다 아래를 남긴다:

- Build / Commit
- macOS version
- iCloud login state
- Network condition
- Local timezone
- Trigger used
- Result: `pass / fail / follow-up`
- Evidence link
- Notes

## 8. Exit Criteria

- baseline account/container pass
- zone initialization pass
- first write / same-day overwrite pass
- retry behavior 최소 1회 확인
- local-day key가 실제 timezone과 일치함을 확인
