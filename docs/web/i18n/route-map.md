# Nudge Web i18n Route Map

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `web-dev`
- Locale strategy: route-based (`/en/`, `/ko/`)

## 1. Route Structure

```
/                → 301 redirect to detected locale (default: /en/)
/en/             → English landing page
/en/#waitlist    → English waitlist section
/en/#faq         → English FAQ section
/ko/             → Korean landing page
/ko/#waitlist    → Korean waitlist section
/ko/#faq         → Korean FAQ section
```

### Route Rules

- Root path (`/`) never serves content directly. It always redirects.
- Each locale has its own route prefix. No sub-path shared between locales.
- Anchor links (`#waitlist`, `#faq`) are section-based, consistent across locales.
- Static assets (images, CSS, JS) are shared and not duplicated per locale.

## 2. Default Locale Detection Priority

Detection runs once on first visit. After explicit selection, preference is stored.

| Priority | Signal | Implementation |
|---|---|---|
| 1 | Stored user preference | `localStorage.setItem('nudge-locale', locale)` |
| 2 | `Accept-Language` header | Parse primary language tag from browser headers |
| 3 | Explicit route (`/ko/`, `/en/`) | Route param takes precedence over header |
| 4 | Fallback | `/en/` |

### Detection Logic (pseudocode)

```javascript
function resolveLocale(request) {
  // 1. Explicit route wins
  const routeLocale = matchRoute(request.path); // '/ko/' → 'ko', '/en/' → 'en'
  if (routeLocale) {
    return routeLocale;
  }

  // 2. Stored preference
  const stored = readCookie(request, 'nudge-locale');
  if (stored && SUPPORTED_LOCALES.includes(stored)) {
    return stored;
  }

  // 3. Accept-Language header
  const browserLocale = parseAcceptLanguage(request.headers['accept-language']);
  if (SUPPORTED_LOCALES.includes(browserLocale)) {
    return browserLocale;
  }

  // 4. Fallback
  return 'en';
}
```

## 3. hreflang Implementation

Every page must include `hreflang` alternate links for all supported locales, including `x-default`.

### Pattern

```html
<!-- On /en/ page -->
<link rel="alternate" hreflang="en" href="https://nudge.app/en/" />
<link rel="alternate" hreflang="ko" href="https://nudge.app/ko/" />
<link rel="alternate" hreflang="x-default" href="https://nudge.app/en/" />

<!-- On /ko/ page -->
<link rel="alternate" hreflang="en" href="https://nudge.app/en/" />
<link rel="alternate" hreflang="ko" href="https://nudge.app/ko/" />
<link rel="alternate" hreflang="x-default" href="https://nudge.app/en/" />
```

### Rules

- `x-default` always points to `/en/` (fallback locale).
- Every locale page lists ALL supported locales, including itself.
- hreflang URLs must be absolute with full domain.
- Do not include hreflang for unsupported locales.

## 4. Canonical URL Rules

```html
<!-- On /en/ page -->
<link rel="canonical" href="https://nudge.app/en/" />

<!-- On /ko/ page -->
<link rel="canonical" href="https://nudge.app/ko/" />
```

### Rules

- Canonical must match the exact locale route, not the root.
- Root (`/`) never has a canonical. It redirects.
- Query parameters (e.g., UTM tags) are excluded from canonical.
- Trailing slash is required: `/en/` not `/en`.

## 5. Locale Switcher

- Visible locale toggle in page header/footer.
- Switching locale navigates to the corresponding route (full page navigation, not client-side swap).
- Current locale is visually indicated.
- After switching, store preference via cookie/localStorage.

### Markup Example

```html
<nav aria-label="Language">
  <a href="/en/" hreflang="en" lang="en">EN</a>
  <span aria-current="true">KO</span>
</nav>
```

## 6. Sitemap

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <url>
    <loc>https://nudge.app/en/</loc>
    <xhtml:link rel="alternate" hreflang="ko" href="https://nudge.app/ko/" />
    <xhtml:link rel="alternate" hreflang="en" href="https://nudge.app/en/" />
    <xhtml:link rel="alternate" hreflang="x-default" href="https://nudge.app/en/" />
  </url>
  <url>
    <loc>https://nudge.app/ko/</loc>
    <xhtml:link rel="alternate" hreflang="en" href="https://nudge.app/en/" />
    <xhtml:link rel="alternate" hreflang="ko" href="https://nudge.app/ko/" />
    <xhtml:link rel="alternate" hreflang="x-default" href="https://nudge.app/en/" />
  </url>
</urlset>
```

## 7. Adding a New Locale

When adding a new locale (e.g., `ja`):

1. Add route `/ja/` to routing config.
2. Create `docs/web/i18n/ja.md` with translated content.
3. Update hreflang links on ALL existing locale pages.
4. Update sitemap with new `<url>` entry.
5. Add `ja` to `SUPPORTED_LOCALES` array.
6. Run QA checklist from `docs/web/i18n/README.md` Section 8.
