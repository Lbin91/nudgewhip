# Nudge Web i18n

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `web-dev`
- Scope: launch website localization contract

## 1. Purpose

- 이 문서는 Nudge 랜딩/대기자/FAQ 페이지의 다국어 운영 기준을 정의한다.
- 초기 웹 런칭은 `ko/en` 동시 운영을 전제로 한다.

## 2. Locale Policy

- Supported locales: `ko`, `en`
- Fallback locale: `en`
- Locale selection: route-based (`/en/`, `/ko/`) — confirmed. See `route-map.md` for detection priority and routing rules.
- 미지원 언어는 영어로 보여준다

## 3. Content Ownership

| Surface | Owner | Notes |
|---|---|---|
| Hero and CTA | `marketing-strategist` | same core claim in both locales |
| Privacy and permission copy | `localization` + `content-strategist` | must match app disclosure meaning |
| Product feature copy | `marketing-strategist` + `content-strategist` | align with app terminology |
| Technical FAQ | `web-dev` + `localization` | no unsupported claims |

## 4. File Layout

- `docs/web/i18n/ko.md` — Korean landing page content skeleton
- `docs/web/i18n/en.md` — English landing page content skeleton
- `docs/web/i18n/route-map.md` — Multilingual routing map (route-based: `/en/`, `/ko/`)
- Glossary is shared with the app: `docs/localization/glossary.md` (separate file not created)

## 5. Key Structure

- 웹 문구 키는 앱과 같은 `domain.surface.intent` 스타일을 따른다
- 예시:
  - `web.hero.title`
  - `web.hero.subtitle`
  - `web.cta.waitlist`
  - `web.privacy.accessibility_reason`
  - `web.faq.sync_best_effort`

## 6. SEO and OG Rules

- title, description, og:title, og:description은 locale별로 관리한다
- canonical은 locale별 페이지를 정확히 가리킨다
- og:image는 locale에 따라 문구를 바꿀 수 있지만, 핵심 메시지는 동일해야 한다 (권장 크기: 1200x630)
- hreflang 또는 equivalent locale hints를 제공한다

## 7. Translation Workflow

1. 원문 확정
1. glossary 용어 잠금
1. locale별 초안 작성
1. 길이 차이에 따른 레이아웃 검증
1. metadata 점검
1. 최종 스크린샷 리뷰

## 8. QA Checklist

- 누락 번역 없음
- 하드코딩 사용자 노출 문자열 없음
- KR/EN 핵심 섹션 스크린샷 승인
- CTA 길이와 줄바꿈 문제 없음
- privacy copy가 앱 고지와 의미상 일치

## 9. Operating Rules

- 앱과 웹은 같은 용어집을 공유한다
- `attention recall tool`, `Free`, `Pro`, `best-effort near real-time`는 임의로 바꾸지 않는다
- 웹에서 지원하지 않는 언어를 무리하게 추가하지 않는다

