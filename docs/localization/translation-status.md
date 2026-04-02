# Nudge Translation Status

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `localization`
- Scope: release-gate document for initial `ko/en` launch

## 1. Translation Policy

- Initial supported languages: `ko`, `en`
- Technical fallback locale: `en`
- Release criterion: every user-facing string in launch scope exists in both `ko` and `en`
- Missing key policy: zero missing keys on launch scope
- Hardcoded string policy: zero user-facing hardcoded strings on launch scope
- Canonical terminology source: `docs/localization/glossary.md`
- String source of truth: `nudge/Localizable.xcstrings`

## 2. Launch Scope Definition

- macOS app core UI
- Accessibility onboarding and permission messaging
- Idle alert copy and TTS short lines
- Upgrade / pricing copy
- Privacy / trust copy
- Launch web hero, FAQ, and privacy copy

## 3. Status Matrix

| Language | Scope | Status | Gate | Owner | Blocker | Next Step |
|---|---|---|---|---|---|---|
| `ko` | Launch scope, app + web core copy | Locked as launch copy | 100% key coverage in `.xcstrings`; KR screenshots reviewed; no truncation regressions | `localization` + `content-strategist` | Missing final product strings from content/marketing surfaces | Fill remaining source strings, then run KR screenshot review |
| `en` | Launch scope, app + web core copy | Locked as technical fallback and launch copy | 100% key coverage in `.xcstrings`; EN screenshots reviewed; no placeholder text | `localization` + `marketing-strategist` | Terminology drift vs. KR source copy | Normalize glossary terms, then verify EN UI and web copy parity |

## 4. Surface Coverage

| Surface | KO | EN | Notes |
|---|---|---|---|
| Menu bar core UI | Required | Required | Includes state, timer, and quick actions |
| Permission onboarding | Required | Required | Must explain why Accessibility is needed |
| Idle alert copy | Required | Required | Includes gentle/strong nudge variants |
| TTS short lines | Required | Required | Short, natural, and locale-aware |
| Upgrade / Pro copy | Required | Required | Free/Pro terminology must match glossary |
| Privacy disclosure | Required | Required | Must be identical in meaning across locales |
| Launch web hero / FAQ | Required | Required | Same product position, localized phrasing |

## 5. Gate Rules

- Gate 1: String coverage complete for launch scope
- Gate 2: Glossary terms locked and consistent across app/web
- Gate 3: KR/EN truncation review passed
- Gate 4: No placeholder fallback text visible in UI
- Gate 5: No user-facing hardcoded strings in launch scope
- Gate 6: Release candidate screenshots approved for both locales

## 6. Ownership and Handoff

- `content-strategist`: app microcopy and notification wording source
- `marketing-strategist`: launch/web copy source
- `localization`: key governance, translation QA, glossary enforcement
- `swiftui-designer`: layout fit and truncation fixes
- `web-dev`: web locale wiring and copy integration

## 7. Blockers and Risks

- Content copy still being finalized in separate docs
- Layout may change when longer EN strings land in UI
- Pro-only wording must not leak into Free UI
- TTS lines may need last-mile brevity adjustments after implementation

## 8. Next Steps

- Freeze launch-scope keys in `.xcstrings`
- Fill any missing KR/EN entries once content docs are finalized
- Run locale-by-locale UI review before release branch cut
