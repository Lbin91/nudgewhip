# Nudge Localization Language Guide

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `localization`

## 1. 목적

- Nudge 앱/웹/마케팅 텍스트의 다국어 운영 기준을 통일한다.
- 초기 `ko/en` 동시 지원을 안정적으로 릴리즈하고, 이후 언어 추가를 반복 가능한 프로세스로 만든다.

## 2. 적용 범위

- macOS 앱 UI
- iOS companion UI
- 시스템 권한 안내 문구
- 알림 및 TTS 핵심 메시지
- 결제/업그레이드 문구
- 랜딩 페이지 핵심 카피 및 프라이버시 문구

## 3. 초기 언어 정책

- 초기 지원 언어: `ko`, `en`
- 개발/폴백 기준 언어: `en`
- 미지원 locale 처리: 영어 fallback
- KR/EN 간 기능 격차 허용 금지 (핵심 플로우 기준)

## 4. 문자열 시스템 계약

- 앱 문자열 단일 소스는 `nudge/Localizable.xcstrings`
- 신규 `Localizable.strings` 생성 금지
- 사용자 노출 문자열 하드코딩 금지
- 모든 키는 `comment` 문맥 필수
- 수량형 문구는 String Catalog variation 사용

## 5. 키 네이밍 규칙

- 포맷: `{domain}.{surface}.{intent}`
- 예시:
- `menu.state.monitoring`
- `alert.idle.gentle_title`
- `permission.accessibility.cta_open_settings`
- `upgrade.pro.badge`
- `web.hero.subtitle`

## 6. 카피 소유권

- 앱 마이크로카피/알림 슬롯 원문: `content-strategist`
- 마케팅/웹 원문: `marketing-strategist`
- 번역 검수/용어집/키 품질 게이트: `localization`
- UI 반영/레이아웃 대응: `swiftui-designer`, `web-dev`

## 7. 문자열 추가 워크플로우

- Step 1: 기능 담당자가 사용자 노출 문구를 키 기반으로 제안한다.
- Step 2: `localization`이 키 네이밍과 문맥 코멘트를 검수한다.
- Step 3: 원문(ko/en)을 확정하고 `.xcstrings`에 등록한다.
- Step 4: UI 적용 후 KR/EN truncation과 래핑을 확인한다.
- Step 5: QA 게이트 통과 후 릴리즈 브랜치에 반영한다.

## 8. 신규 언어 추가 워크플로우

- Step 1: 언어 추가 제안서 작성 (시장 우선순위, 범위, 일정)
- Step 2: 지원 범위 확정 (앱/웹/마케팅 포함 표면 정의)
- Step 3: 용어집 확정 및 기존 키 coverage 점검
- Step 4: 번역 진행, 리뷰, 문맥 검수
- Step 5: 레이아웃/접근성/스크린샷 QA
- Step 6: 릴리즈 게이트 승인 후 언어 활성화

## 9. UI 레이아웃 규칙 (KR/EN)

- 버튼 고정 폭 지양, 콘텐츠 기반 폭 사용
- 2줄 래핑 허용을 기본값으로 설계
- 의미 전달이 깨지는 중간 말줄임 금지
- 텍스트 길이 차이 대응 여백 확보
- 누락 키 placeholder 노출 금지

## 10. QA 게이트

- Missing translation key: 0
- Hardcoded user-facing string: 0
- KR/EN truncation critical issue: 0
- KR/EN 핵심 화면 스크린샷 검수 완료
- 앱/웹 용어집 불일치 치명 이슈: 0
- TTS locale 매칭 확인 (ko/en)

## 11. 앱/웹 용어 일관성 원칙

- 동일 개념은 앱/웹에서 동일 번역 사용
- 제품 카테고리 (`attention recall tool`) 번역 고정
- Free/Pro 명칭 번역 고정
- 프라이버시 핵심 문구는 웹/앱 동일 의미로 유지

## 12. 운영 체크 커맨드

- 하드코딩 의심 문자열 탐색:
- `rg -n 'Text\\(\"[A-Za-z가-힣]' nudge`
- 번역 키 사용 점검:
- `rg -n 'String\\(localized:' nudge`
- 웹 i18n 키 점검:
- `rg -n 'i18n|locale|translation' docs/web`

