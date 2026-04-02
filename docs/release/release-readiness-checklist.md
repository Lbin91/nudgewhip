# Nudge Release Readiness Checklist

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `qa-integrator`
- Scope: beta launch and Pro launch readiness gate

## 1. Purpose

- 이 문서는 Nudge를 beta 또는 Pro launch 하기 전에 반드시 확인해야 하는 릴리즈 게이트를 정의한다.
- 목적은 build, permissions, QA, localization, privacy, analytics, pricing copy, CloudKit/iOS gating, website/waitlist, support readiness, rollback/fallback를 한 장에서 검증하는 것이다.
- 문서의 기본 원칙은 `실제로 제공하는 것만 출시한다`이다.

## 2. Release Policy

- Beta launch는 macOS Free Open Beta 범위만 허용한다.
- Pro launch는 beta에서 검증된 core loop와 별도 gate를 통과한 기능만 허용한다.
- 실제 동작하지 않는 기능, 아직 계약이 잠기지 않은 copy, 검증되지 않은 sync 동작은 출시 기준에 포함하지 않는다.
- release blocker가 하나라도 남아 있으면 launch를 진행하지 않는다.

## 3. Readiness Checklist

### 3.1 Build and Packaging

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| macOS build succeeds on target scheme | [ ] | [ ] | `xcodebuild build` log | build failure is a blocker |
| Test target builds succeed | [ ] | [ ] | test compile log | missing test build is a blocker |
| `LSUIElement = YES` is preserved | [ ] | [ ] | project setting / app behavior | Dock icon regression is a blocker |
| App launches without crash on clean install | [ ] | [ ] | launch smoke test | launch crash is a blocker |
| Release configuration uses final bundle/version | [ ] | [ ] | build metadata | wrong versioning is a blocker |

### 3.2 Permissions

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Accessibility onboarding explains why permission is needed | [ ] | [ ] | onboarding screenshot / copy review | missing rationale is a blocker |
| Denied permission path enters limited mode | [ ] | [ ] | QA scenario | crash or dead-end is a blocker |
| Permission re-try path is available | [ ] | [ ] | QA scenario | no recovery path is a blocker |
| Limited mode is visibly labeled in UI | [ ] | [ ] | UI screenshot | hidden degraded state is a blocker |

### 3.3 Core QA

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Idle detection uses one-shot deadline timer behavior | [ ] | [ ] | unit/integration test | polling-based regression is a blocker |
| Idle threshold accuracy is within spec | [ ] | [ ] | timing test | threshold drift beyond spec is a blocker |
| Alert recovery occurs within spec | [ ] | [ ] | alert latency test | slow recovery is a blocker |
| Sleep/lock/user-switch transitions reset baseline | [ ] | [ ] | state transition test | stale idle accumulation is a blocker |
| Whitelist pause works only for `bundleIdentifier`-based matching | [ ] | [ ] | QA scenario | name-based matching is a blocker |
| Alert fatigue guardrails are active | [ ] | [ ] | rate-limit test | repeated alert spam is a blocker |

### 3.4 Localization

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Launch scope strings exist in `ko` and `en` | [ ] | [ ] | translation status review | missing launch-scope key is a blocker |
| No user-facing hardcoded strings remain in launch scope | [ ] | [ ] | string audit | hardcoded copy is a blocker |
| KR/EN screenshots reviewed for truncation | [ ] | [ ] | screenshot matrix | critical truncation is a blocker |
| TTS lines exist in both supported locales | [ ] | [ ] | copy review | unsupported TTS locale is a blocker |
| App and web terminology match glossary | [ ] | [ ] | glossary check | terminology drift is a blocker |

### 3.5 Privacy

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Accessibility/data disclosure copy matches app behavior | [ ] | [ ] | privacy review | mismatch between copy and behavior is a blocker |
| Keystroke content and screen content are not collected | [ ] | [ ] | implementation review / policy | any content capture claim is a blocker |
| CloudKit disclosure is limited to state-transition metadata | [ ] | [ ] | privacy copy review | broader sync claim is a blocker |
| App Store privacy label can be derived from disclosure | [ ] | [ ] | policy review | unsupported privacy label claim is a blocker |

### 3.6 Analytics

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Analytics are privacy-friendly and limited to launch KPIs | [ ] | [ ] | spec.md Section 12 + data collection audit | data collection creep is a blocker |
| No analytics event leaks sensitive content | [ ] | [ ] | event schema review | sensitive payload capture is a blocker |
| Waitlist and launch metrics are defined | [ ] | [ ] | spec.md Section 13 (launch web KPI) + waitlist metric definition | no metric definition is a blocker |

### 3.7 Pricing Copy

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Free/Pro messaging matches approved packaging | [ ] | [ ] | copy review | inconsistent package naming is a blocker |
| Pricing copy does not claim unapproved pricing certainty | [ ] | [ ] | marketing review | false price certainty is a blocker |
| Pricing copy does not imply real-time guarantees | [ ] | [ ] | marketing/privacy review | real-time promise is a blocker |

- Free/Pro packaging의 source of truth는 `docs/app/spec.md` Section 4이다.

### 3.8 CloudKit and iOS Gating

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Beta can ship without CloudKit dependency | [ ] | [ ] | runtime behavior | CloudKit hard dependency is a blocker |
| Pro iOS follow-up uses best-effort sync only | [ ] | [ ] | sync contract review | real-time guarantee is a blocker |
| iCloud login and Pro entitlement are treated separately | [ ] | [ ] | architecture review | conflated gating is a blocker |
| Offline/local-only mode works when iCloud is unavailable | [ ] | [ ] | failure scenario test | no fallback is a blocker |
| Sync writes only on state transitions | [ ] | [ ] | log/test evidence | heartbeat sync is a blocker |

### 3.9 Website and Waitlist

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Launch website is live or staged | [ ] | [ ] | deploy link | missing launch page is a blocker |
| Waitlist form submits successfully | [ ] | [ ] | form test | broken form is a blocker |
| Hero, FAQ, privacy copy match launch narrative | [ ] | [ ] | copy review | messaging mismatch is a blocker |
| `/ko` and `/en` routes render correctly | [ ] | [ ] | locale QA | broken locale routing is a blocker |

### 3.10 Support Readiness

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Known issues list is prepared | [ ] | [ ] | release notes draft | no support notes is a blocker |
| Issue triage owner is assigned | [ ] | [ ] | owner list | no support owner is a blocker |
| Permission and privacy FAQ exists | [ ] | [ ] | help copy | missing FAQ coverage is a blocker |
| Feedback channel is ready | [ ] | [ ] | support contact / issue template | no feedback path is a blocker |

### 3.11 Rollback and Fallback

| Item | Beta | Pro | Evidence | Blocker Rule |
|---|---|---|---|---|
| Local-only mode is safe as fallback | [ ] | [ ] | failure scenario test | unsafe fallback is a blocker |
| CloudKit sync can be disabled without breaking core flow | [ ] | [ ] | feature flag / runtime path | no disable path is a blocker |
| Pro surfaces can be hidden or delayed if needed | [ ] | [ ] | rollout plan | no rollback path is a blocker |
| Release can be paused before public promotion | [ ] | [ ] | launch checklist / owner signoff | no hold mechanism is a blocker |

## 4. Release Blockers

- Build or packaging failure
- Accessibility permission flow regression
- Idle detection accuracy or alert recovery regression
- Localization gaps in launch-scope copy
- Privacy disclosure mismatch or unsupported privacy claims
- CloudKit/iOS behavior that implies real-time guarantees
- Pricing or packaging copy that does not match approved scope
- Waitlist or website route failure that blocks launch communication
- No support owner, no FAQ, or no feedback channel
- No rollback or fallback path for core launch flow

## 5. Launch Gate Criteria

### 5.1 Beta Launch Gate

- `build` = green
- `permissions` = green
- `QA` = green
- `localization` = green
- `privacy` = green
- `website/waitlist` = green or intentionally staged with verified fallback
- `support readiness` = green
- `rollback/fallback` = green
- `CloudKit/iOS gating` may remain off for beta

### 5.2 Pro Launch Gate

- All Beta gate items remain green
- `pricing copy` = green
- `CloudKit/iOS gating` = green
- `analytics` = green
- `Pro-only` copy and surfaces are verified against final packaging

## 6. Sign-Off

- Product owner confirms launch scope
- `qa-integrator`: 모든 release blocker 통과 확인 및 최종 서명
- `localization`: launch-scope string parity 및 KR/EN 스크린샷 검증
- `macos-core`: 권한 흐름, idle detection, 상태 전이 정상 확인
- `cloudkit-sync`: macOS/iOS sync 및 복구 동작 확인
- `data-architect`: 데이터 정합성 및 마이그레이션 안전성 확인
- `content-strategist`: 알림 문구, 톤, break suggestion 카피 검증
- `marketing-strategist`: 웹 카피, App Store 메타데이터, 가격 카피 검증

