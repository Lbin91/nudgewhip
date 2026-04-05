# Nudge Localization Test Matrix

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `qa-integrator`
- Scope: KR/EN app + web localization QA for launch scope

## 1. Purpose

- 이 문서는 Nudge의 한국어/영어 현지화 품질을 릴리즈 게이트 수준에서 검증하기 위한 테스트 매트릭스다.
- 목표는 앱과 웹의 핵심 문구가 같은 의미, 같은 용어, 같은 권한/프라이버시 메시지를 유지하는지 확인하는 것이다.
- launch scope는 `docs/localization/translation-status.md` 기준을 따른다. 웹 i18n 범위는 `docs/web/i18n/README.md`가 작성된 후 해당 기준을 추가로 따른다.

## 2. Test Principles

- 사용자 노출 문자열은 하드코딩이 아니라 번역 키 기준으로 검증한다.
- KR/EN은 직역 일치가 아니라 의미 일치를 우선한다.
- 앱과 웹은 동일한 개념에 동일 용어를 사용한다.
- 화면 검증은 텍스트 길이, 줄바꿈, 버튼 폭, metadata 길이를 함께 본다.
- 3차 시스템 알림은 locale 매칭과 문구 길이를 별도 확인한다.

## 3. Matrix

| Surface | Locale | Scenario | Expected Result | Screenshot Requirement | Regression Risk | Owner |
|---|---|---|---|---|---|---|
| Menu bar core UI | KR | 상태, 카운트다운, 빠른 제어가 보이는 초기 드롭다운 표시 | 핵심 상태가 2줄 이내로 읽히고, 버튼이 잘리지 않으며, `Monitoring`/`휴식`/`알림` 문맥이 일관됨 | Required | 문자열 길이 증가로 인한 truncation | `swiftui-designer` |
| Menu bar core UI | EN | 상태, countdown, quick actions가 보이는 초기 드롭다운 표시 | 영문이 너무 길어도 의미가 유지되고 CTA가 줄바꿈 없이 배치됨 | Required | EN 문장 길이로 인한 layout break | `swiftui-designer` |
| Accessibility onboarding | KR | 권한 필요 사유를 보여주는 first-run 화면 | 손쉬운 사용 권한 이유, 수집하지 않는 데이터, 제한 모드 동작이 명확히 전달됨 | Required | 권한 거부율 증가, privacy confusion | `localization` + `macos-core` |
| Accessibility onboarding | EN | first-run permission screen | Accessibility rationale and limited mode remain clear and consistent with app disclosure | Required | meaning drift between app and website copy | `localization` + `macos-core` |
| Idle alert copy | KR | `idle_notice`, `gentle_warning`, `strong_warning` 노출 | 모든 단계가 과하게 위협적으로 보이지 않고, 동일 세션 내 반복 문구가 과도하지 않음 | Required | tone drift, repeated copy fatigue | `content-strategist` |
| Idle alert copy | EN | same alert ladder in English | sentence length remains short enough for alert overlays and notification copy | Required | truncation, overly literal translation | `localization` + `content-strategist` |
| Break suggestion | KR | 반복 오탐 감지 시 breakSuggestion 노출 | 휴식 제안 문구가 비난 톤 없이 표시되고, KR/EN 의미가 일치함 | Required | tone drift, missing copy | `content-strategist` + `localization` |
| Break suggestion | EN | repeated false-positive triggers breakSuggestion | break suggestion copy is neutral, short, and meaning-matched with KR | Required | literal translation, truncation | `content-strategist` + `localization` |
| Notification copy | KR | alert 단계에서 3차 시스템 알림이 표시된다 | title/body가 한국어로 표시되고 짧은 문구가 잘리지 않는다 | Optional for screenshot; notification QA required | wrong locale, long body copy | `content-strategist` + `qa-integrator` |
| Notification copy | EN | alert 단계에서 3차 시스템 알림이 표시된다 | English notification copy is selected and delivered content remains concise | Optional for screenshot; notification QA required | locale mismatch, duplicate delivery | `content-strategist` + `qa-integrator` |
| Upgrade / Pro copy | KR | Free/Pro 비교, 업그레이드 CTA 표시 | Free/Pro 명칭이 용어집과 일치하고, Pro 가치가 Mac+iPhone 루프로 이해됨 | Required | Pro value blur, pricing confusion | `marketing-strategist` |
| Upgrade / Pro copy | EN | Free/Pro comparison and upgrade CTA | terminology stays consistent with glossary and does not imply real-time guarantee | Required | unsupported sync promise | `marketing-strategist` |
| Privacy disclosure | KR | onboarding/settings/privacy section 표시 | 키 입력 내용, 화면 캡처, 브라우징 기록 미수집 문구가 앱 고지와 일치함 | Required | trust regression, compliance mismatch | `localization` + `macos-core` |
| Privacy disclosure | EN | onboarding/settings/privacy section 표시 | English disclosure matches KR meaning and avoids stronger claims than the app makes | Required | copy parity drift | `localization` + `macos-core` |
| Launch web hero | KR | hero, subhead, CTA, waitlist block 표시 | `attention recall tool` 포지셔닝과 CTA가 앱 카피와 같은 의미를 유지함 | Required | messaging split between web and app | `marketing-strategist` + `web-dev` |
| Launch web hero | EN | hero, subhead, CTA, waitlist block 표시 | English headline/subhead keep the same product promise and trust message | Required | headline divergence, CTA mismatch | `marketing-strategist` + `web-dev` |
| Launch web FAQ | KR | Accessibility, CloudKit, data handling FAQ 표시 | 앱 고지와 같은 의미로 답변되며, 오해를 줄이는 문장이 유지됨 | Required | privacy wording inconsistency | `localization` + `web-dev` |
| Launch web FAQ | EN | Accessibility, CloudKit, data handling FAQ 표시 | FAQ wording matches launch copy and avoids unsupported technical claims | Required | unsupported sync language | `localization` + `web-dev` |
| App Store metadata | KR | title, subtitle, description, privacy label 검토 | 번역이 짧고 정확하며, 앱 실제 동작보다 더 넓게 말하지 않음 | Required | store listing mismatch, truncation | `marketing-strategist` + `localization` |
| App Store metadata | EN | title, subtitle, description, privacy label 검토 | metadata follows glossary and fits store field limits | Required | metadata overflow, claim drift | `marketing-strategist` + `localization` |

## 4. Coverage Rules

- Copy parity: same meaning, same claim, same product category across KR/EN.
- Truncation: titles, CTA, permission text, and FAQ answers must fit within the target layout without mid-word clipping.
- Fallback: missing locale must fall back to English, but placeholder text must never be visible.
- Plural/variation: quantity-sensitive strings must use String Catalog variation or locale-safe wording.
- Notification locale: visible notification copy must match the active app locale.
- Metadata parity: App Store, launch website, and in-app privacy copy must match on meaning.
- Permission/privacy wording consistency: Accessibility and data disclosure language must be identical in intent across all surfaces.

## 5. Scenario Checklist

### 5.1 Copy Parity

- Verify the same feature is described with the same intent on app, web, and store surfaces.
- Verify `attention recall tool`, `Free`, `Pro`, and `best-effort near real-time` remain glossary-consistent.
- Verify `no keystroke content`, `no screen capture`, and `Accessibility permission` remain aligned.
- Verify `break_suggestion` copy remains neutral and consistent between notification surface and String Catalog.

### 5.2 Truncation

- Verify menu bar popover text at narrow width.
- Verify hero headline and CTA at mobile widths.
- Verify permission and privacy copy at two-line wrap limits.
- Verify App Store metadata field lengths.

### 5.3 Fallback and Missing Keys

- Verify unsupported locale falls back to EN.
- Verify no placeholder tokens, key names, or empty labels appear in UI.
- Verify web i18n route fallback resolves to the canonical locale page.

### 5.4 Plural and Variation

- Verify count-based text uses catalog variation instead of ad hoc string concatenation.
- Verify repeated alert phrases rotate across approved variants.
- Verify streak and summary text remain natural in both locales.

### 5.5 Notification Locale

- Verify KR alert path shows Korean notification copy.
- Verify EN alert path shows English notification copy.
- Verify pending notifications are cleared on input recovery.

### 5.6 Metadata and Trust

- Verify App Store copy does not promise real-time sync.
- Verify web metadata matches launch copy and privacy copy.
- Verify privacy wording does not imply screen or text capture.

## 6. Release Gate

- Missing translation keys: 0
- User-facing hardcoded strings in launch scope: 0
- Critical KR/EN truncation regressions: 0
- Privacy wording mismatches: 0
- Notification locale mismatches: 0
- App Store/web metadata drift: 0

## 7. Notes for Execution

- Run screenshot review for both locales on primary launch surfaces before release branch cut.
- Re-run this matrix whenever copy, metadata, or layout changes land.
- Treat glossary changes as a required regression trigger for localization QA.
