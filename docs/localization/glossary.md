# Nudge Glossary (KR/EN)

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `localization`

## 용어 기준

- 아래 표의 `Canonical KO`를 기본 번역으로 사용한다.
- 마케팅/앱/웹 카피는 같은 개념을 다른 번역으로 혼용하지 않는다.

| Domain | Canonical EN | Canonical KO | Notes |
|---|---|---|---|
| Product | Nudge | 넛지 | 제품명은 고유명사로 유지 |
| Product | attention recall tool | 집중 복귀 도구 | 카테고리 고정 번역 |
| Product | menu bar app | 메뉴바 앱 | 상태바 앱 표현과 혼용 금지 |
| State | monitoring | 모니터링 | `active` 대신 UI 기본 문구 |
| State | idle | 무입력 상태 | 사용자 비난 표현 금지 |
| State | alerting | 알림 진행 중 | 단계형 알림 상태 |
| State | recovery | 복귀 | 복귀 성공 상태 |
| State | break mode | 휴식 모드 | 수동 일시중지 상태 |
| State | whitelist pause | 화이트리스트 일시중지 | 자동 일시중지 상태 |
| Alert | gentle nudge | 가벼운 넛지 | 1차 알림 단계 |
| Alert | strong nudge | 강한 넛지 | 2차 이상 알림 단계 |
| Alert | remote escalation | 원격 에스컬레이션 | iOS 연동 단계 |
| Alert | perimeter pulse | 테두리 펄스 알림 | 기본 시각 알림 |
| Alert | grayscale mode | 흑백 모드 | 고강도 옵션 |
| Data | focus session | 집중 세션 | 통계 원천 단위 |
| Data | daily stats | 일일 통계 | 파생 집계 |
| Data | streak | 연속 집중 | 게이미피케이션 지표 |
| Premium | Free | Free | 플랜명 영문 유지 |
| Premium | Pro | Pro | 플랜명 영문 유지 |
| Premium | upgrade to Pro | Pro 업그레이드 | CTA 표준 문구 |
| Premium | lifetime purchase | 평생 이용권 | 가격/결제 문서용 |
| Permission | Accessibility permission | 손쉬운 사용 권한 | macOS 공식 용어 우선 |
| Privacy | no keystroke content collection | 키 입력 내용 수집 없음 | 핵심 신뢰 문구 |
| Privacy | no screen capture | 화면 캡처 없음 | 핵심 신뢰 문구 |
| Sync | CloudKit sync | CloudKit 동기화 | 서버리스 표현과 함께 사용 |
| Sync | best-effort near real-time | 준실시간(보장 없음) | 보장형 표현 금지 |

## 금지 번역 예시

- `attention recall tool`을 `집중력 관리 앱`, `생산성 앱`으로 임의 변경 금지
- `break mode`를 `쉬는 시간`, `중지 모드`로 혼용 금지
- `whitelist`를 `허용 목록`, `예외 앱 목록`으로 혼용 금지
- `best-effort near real-time`을 `즉시`, `실시간 보장`으로 번역 금지

## 업데이트 규칙

- 신규 핵심 용어가 생기면 PR에서 본 문서를 함께 업데이트한다.
- 용어 변경 시 앱/웹/마케팅 카피 동시 점검을 릴리즈 게이트에 포함한다.

