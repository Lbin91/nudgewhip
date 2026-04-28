<p align="center">
  <img src="docs/assets/readme/whip-devil-mark.png" alt="NudgeWhip whip devil mark" width="180" />
</p>

<p align="center">
  <a href="LICENSE">
    <img alt="MIT License" src="https://img.shields.io/badge/license-MIT-3DA639?style=for-the-badge&logo=license">
  </a>
  <a href="docs/release/v0.4.0.md">
    <img alt="v0.4.0" src="https://img.shields.io/badge/release-v0.4.0-E35D3D?style=for-the-badge">
  </a>
  <img alt="macOS 15+" src="https://img.shields.io/badge/platform-macOS%2015%2B-111827?style=for-the-badge&logo=apple">
  <img alt="SwiftUI + AppKit" src="https://img.shields.io/badge/stack-SwiftUI%20%2B%20AppKit-F97316?style=for-the-badge&logo=swift&logoColor=white">
  <img alt="Local First" src="https://img.shields.io/badge/privacy-local--first-0F766E?style=for-the-badge">
</p>

<h1 align="center">NudgeWhip</h1>

<p align="center">
  <strong>A sharp little devil for drifting attention.</strong>
</p>

<p align="center">
  NudgeWhip is a privacy-first macOS menu bar companion for serious desktop work.<br />
  It catches the moment attention slips, then snaps you back before a short drift becomes a lost hour.
</p>

<p align="center">
  <img src="docs/assets/readme/nudgewhip-alert-preview.gif" alt="NudgeWhip alert demo" width="720" />
</p>

## Download

NudgeWhip is distributed through the notarized DMG attached to the GitHub release.

- GitHub Release: [v0.4.0](https://github.com/Lbin91/nudgewhip/releases/tag/v0.4.0)
- Asset: `NudgeWhip-0.4.0-1.dmg`
- Platform: macOS 15 or later

<p align="center">
  <a href="docs/release/v0.4.0.md"><strong>Release Notes</strong></a>
  ·
  <a href="docs/privacy/accessibility-and-data-disclosure.md"><strong>Privacy</strong></a>
  ·
  <a href="https://github.com/Lbin91/nudgewhip/issues"><strong>Issues</strong></a>
  ·
  <a href="https://github.com/Lbin91/nudgewhip/releases"><strong>Releases</strong></a>
</p>

## Why NudgeWhip

Most focus tools drift toward one of two extremes:

- they politely whisper and get ignored
- they escalate into blockers and create friction

NudgeWhip sits in the middle.

It is an `attention recall tool`: a local intervention layer for people whose work already lives inside demanding Mac workflows. The core idea is simple:

- drifting is normal
- recovery is the moment that matters
- the intervention should be immediate, clear, and local

## Release Status

`v0.4.0` adds the iOS companion app and CloudKit real-time sync.

Current release lane:

- `macOS + iOS companion`
- `source-first GitHub release`
- `Free core loop only`

Not in scope for `v0.4.0`:

- Push notifications (CKQuerySubscription + APNs)
- Pet mood system implementation
- StoreKit / Pro packaging
- Recovery Review dashboard
- Schedule presets

## What Ships In `v0.4.0`

- **iOS companion app** with live CloudKit sync for Mac focus state
- **CloudKit real-time pipeline** — MacState and RemoteEscalationEvent written to iCloud Private Database on every state change
- **Multi-Mac isolation** — correctly handles multiple Macs sharing one iCloud account
- **Full Korean (한국어) localization** for both macOS and iOS
- menu bar app with `LSUIElement` behavior and no Dock icon
- Accessibility permission onboarding with visible limited-mode fallback
- global idle detection from keyboard and mouse activity
- one-shot idle deadlines instead of noisy polling
- local visual nudges with system notification escalation
- runtime status and countdown in the dropdown
- manual pause controls and schedule controls
- local daily summary stats with trend charts
- settings window and launch-at-login toggle
- CloudKit daily aggregate backup for cross-device data continuity

## Onboarding

<p align="center">
  <img src="docs/assets/readme/nudgewhip-launch-screen.png" alt="NudgeWhip onboarding surface" width="400" />
</p>

## In The Menu Bar

<p align="center">
  <img src="docs/assets/readme/nudgewhip-menubar.png" alt="NudgeWhip menu bar dropdown" width="400" />
</p>

<p align="center">
  <em>The little devil lives in the menu bar and steps in when attention starts to slide.</em>
</p>

## What Makes It Different

### Local-first

NudgeWhip is designed around the Mac itself, not around a cloud dashboard. CloudKit is a backup layer, not the source of truth.

### Privacy-first

Accessibility permission is used only to detect global input activity. NudgeWhip does **not** read typed text, capture your screen, inspect browsing history, or collect message content.

### Recovery-first

This is not a punishment machine. It is an intervention layer designed to shorten the distance between distraction and return.

## Privacy At A Glance

NudgeWhip draws a hard line:

- it uses global input activity only
- it does not inspect typed text or screen contents
- it does not store raw input logs
- it stores summary data locally
- it keeps local app state in `SwiftData`
- CloudKit sync uses Private Database only — data stays in the user's iCloud

Full disclosure: [docs/privacy/accessibility-and-data-disclosure.md](docs/privacy/accessibility-and-data-disclosure.md)

## Build And Verify

Requirements:

- macOS `15.0+`
- Xcode `17+`

Build the app:

```bash
xcodebuild build -scheme nudgewhip -destination 'platform=macOS'
```

Run static analysis:

```bash
xcodebuild analyze -scheme nudgewhip -destination 'platform=macOS'
```

Run unit and runtime tests:

```bash
xcodebuild test -scheme nudgewhip -destination 'platform=macOS' -only-testing:nudgewhipTests
```

Run UI tests:

```bash
xcodebuild test -scheme nudgewhip -destination 'platform=macOS' -only-testing:nudgewhipUITests
```

Note:

- menu bar agent UI tests are more timing-sensitive than standard foreground app UI tests

## Technical Shape

Core stack:

- `SwiftUI` for menu bar, onboarding, and settings UI
- `AppKit` for global event monitoring and alert/panel coordination
- `SwiftData` for local persistence
- `CloudKit` for cross-device state sync (Private Database only)

At a high level:

1. NudgeWhip records the last observed activity timestamp.
2. It schedules a one-shot idle deadline.
3. When the deadline is reached, it starts a local nudge flow.
4. When activity returns, it resets the timer and records local summary data.
5. State changes are written to CloudKit for the iOS companion to read.

## Repository Layout

```text
nudgewhip/
├── nudgewhip/              # macOS app source
├── nudgewhipios/           # iOS companion app source
├── nudgewhipTests/         # unit and runtime tests
├── nudgewhipUITests/       # UI tests
└── docs/                   # product, architecture, privacy, QA, and release docs
```

## Documentation Map

- [docs/release/v0.4.0.md](docs/release/v0.4.0.md): v0.4.0 release notes
- [docs/release/v0.3.0.md](docs/release/v0.3.0.md): v0.3.0 release notes
- [docs/release/v0.2.0.md](docs/release/v0.2.0.md): v0.2.0 release notes
- [docs/app/v0.3-feature-direction.md](docs/app/v0.3-feature-direction.md): next-version feature direction
- [docs/privacy/accessibility-and-data-disclosure.md](docs/privacy/accessibility-and-data-disclosure.md): permission and data disclosure

## Beta Reality

This repository is not a concept dump.

It is an active public-beta / portfolio-stage product:

- the core loop is real
- the app builds and runs
- the release process is documented
- the surface area is still tightening

## License

This project is licensed under the [MIT License](LICENSE).
