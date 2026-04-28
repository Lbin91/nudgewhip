# TODO — 버전업 전 남은 작업

> 마지막 업데이트: 2026-04-28

---

## macOS

### 필수
- [ ] **CloudKit Schema Production 배포** — 개발 환경에서 생성한 schema(MacState, RemoteEscalationEvent, DashboardDayProjection)를 CloudKit Dashboard에서 production으로 승격
- [ ] **버전 번호 업데이트** — Xcode 프로젝트 `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION` 업데이트
- [ ] **macOS 앱 샌드박스/엔타이틀먼트 검토** — App Sandbox, iCloud, CloudKit entitlements 최종 확인
- [ ] **Release note 작성** — `docs/release/` 에 다음 버전 릴리즈 노트 작성

### 개선
- [ ] **l10n P2 항목**
  - `StatsView` 차트 축 라벨 "Hour" / "Alerts" 현지화
  - `SettingsView` 버전 번호 `Bundle.main` 연동
  - `SyncOrchestrator` 에러 문자열 현지화
- [ ] **테스트 보강** — `MacStateCloudKitWriter` 통합 테스트, `RuntimeStateController.saveMacState()` 단위 테스트 추가
- [ ] **전체 테스트 스위트 실행** — `xcodebuild test -scheme nudgewhip -destination 'platform=macOS'` 통과 확인

---

## iOS

### 필수
- [ ] **MacState 실시간 상태 바인딩 검증** — macOS에서 CloudKit에 MacState 데이터가 실제로 올라가는지 확인 (CloudKit Dashboard 또는 iOS 앱에서)
- [ ] **실기기 CloudKit 권한 테스트** — 실제 iPhone에서 iCloud 계정 연동, CloudKit Private Database 접근 확인
- [ ] **알림 콘텐츠 기획 구체화**
  - 에스컬레이션 단계별 타입 분류 (warning / info / achievement)
  - 단계별 UI 컴포넌트 (아이콘, 색상, 심각도 표시)
  - 알림 타이틀/메시지 l10n 키 설계
- [ ] **CachedRemoteEscalation 필드 확장 검토** — 현재 escalationStep + contentStateRawValue만 있음. 타이틀/메시지 필요 여부 결정
- [ ] **알림 탭 빈 상태 / 실데이터 UI 검증** — AlertsView empty state, 실제 에스컬레이션 데이터 표시 확인
- [ ] **SettingsView 동기화 상태 실시간 반영** — SyncOrchestrator lastSyncAt, lastSyncError UI 바인딩 확인

### 개선
- [ ] **l10n P2 항목**
  - `StatsView` 차트 축 라벨 현지화
  - `SettingsView` 버전 번호 `Bundle.main` 연동
- [ ] **SF Symbol 중앙 관리** — macOS/iOS 간 SF Symbol 이름 일관성 보장 (공통 enum 또는 상수)

---

## 공통

### 필수
- [ ] **CloudKit Subscription 테스트** — macOS → iOS 실시간 동기화 동작 확인 (CKQuerySubscription + APNs silent push)
- [ ] **CloudKit Dashboard production schema 승격** — MacState, RemoteEscalationEvent, DashboardDayProjection 레코드 타입
- [ ] **TestFlight 빌드 & 배포 준비** — App Store Connect 아카이브, TestFlight 내부 테스트 그룹 설정

### 개선
- [ ] **E2E 테스트 시나리오** — macOS 유휴 → CloudKit 기록 → iOS 표시 전체 흐름 수동 테스트
- [ ] **에러 모니터링** — CloudKit 할당량 초과, 네트워크 오류 등 사용자 경험 저하 시나리오 대응

---

## 이전 완료 작업 (참고용)

<details>
<summary>CloudKit Daily Aggregate Backup (완료)</summary>

- [x] Payload/builder/writer/trigger wiring 모두 구현 완료
- [x] Shared `CloudKitDailyAggregateFetchConsumer` 구현
- [x] Failure-first 테스트 통과
- [x] disk-backed outbox 재시도 큐 구현

</details>

<details>
<summary>P0+P1 l10n 현지화 (완료)</summary>

- [x] macOS xcstrings 9개 키 한국어 번역 추가
- [x] macOS 하드코딩 Text() 4건 → String(format: String(localized:)) 교체
- [x] macOS 접근성 라벨 2건 현지화
- [x] iOS SettingsViewModel → RelativeDateTimeFormatter
- [x] iOS HomeViewModel/StatsViewModel → DateComponentsFormatter
- [x] iOS AlertsViewModel dead code 제거 + timeStyle 로케일 대응
- [x] macOS IdleMonitor → RemoteEscalationEventWriter CloudKit 연결
- [x] macOS RuntimeStateController → MacStateCloudKitWriter CloudKit 연결
- [x] iOS 앱 아이콘 macOS AppIcon 복사 적용

</details>
