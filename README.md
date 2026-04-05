<p align="center">
  <img src="docs/assets/readme/nudge-launch-screen.png" alt="NudgeWhip launch screen" width="1200" />
</p>

<p align="center">
  <a href="docs/release/v0.1.0.md">
    <img alt="v0.1.0 Public Beta" src="https://img.shields.io/badge/release-v0.1.0%20public%20beta-E35D3D?style=for-the-badge">
  </a>
  <img alt="macOS 15+" src="https://img.shields.io/badge/platform-macOS%2015%2B-111827?style=for-the-badge&logo=apple">
  <img alt="SwiftUI + AppKit" src="https://img.shields.io/badge/stack-SwiftUI%20%2B%20AppKit-F97316?style=for-the-badge&logo=swift&logoColor=white">
  <img alt="Local First" src="https://img.shields.io/badge/privacy-local--first-0F766E?style=for-the-badge">
</p>

<h1 align="center">NudgeWhip</h1>

<p align="center">
  <strong>Sharper than a reminder. Lighter than a blocker.</strong>
</p>

<p align="center">
  NudgeWhip is a privacy-first macOS menu bar app for serious desktop work.<br />
  It catches the quiet moment when your hands stop moving, your attention slips, and your work starts to drift, then pulls you back before a short pause turns into a lost hour.
</p>

<p align="center">
  <a href="docs/release/v0.1.0.md"><strong>Release Notes</strong></a>
  ·
  <a href="docs/privacy/accessibility-and-data-disclosure.md"><strong>Privacy</strong></a>
  ·
  <a href="https://github.com/Lbin91/nudge/issues"><strong>Issues</strong></a>
  ·
  <a href="https://github.com/Lbin91/nudge/releases"><strong>Releases</strong></a>
</p>

## Why NudgeWhip

Most focus tools do one of two things:

- they politely whisper and get ignored
- they turn into full-blown blockers and create friction

NudgeWhip sits in the middle.

It is built as a crisp recovery tool for people who already spend their day inside demanding Mac workflows: developers, designers, writers, founders, researchers, and anyone whose job depends on getting back into flow fast.

The idea is simple:

- drifting is normal
- recovery is the moment that matters
- the intervention should be immediate, clear, and local

## What You Get In `v0.1.0`

This public beta already includes a real working core loop:

- menu bar app with no Dock icon
- Accessibility permission onboarding
- visible limited mode when permission is denied
- global idle detection from keyboard and mouse activity
- one-shot idle deadlines instead of noisy polling
- local visual nudges
- optional voice nudges
- runtime status and countdown in the dropdown
- schedule controls
- local daily summary stats
- settings window
- launch at login
- Korean and English strings

## Screenshot

<p align="center">
  <img src="docs/assets/readme/nudge-launch-screen.png" alt="NudgeWhip macOS launch surface" width="1100" />
</p>

<p align="center">
  <em>Current beta launch surface captured from the UI test run.</em>
</p>

## What Makes It Different

### Local-first

NudgeWhip is designed around the Mac itself, not around a cloud dashboard.

### Privacy-first

Accessibility permission is used only to detect global input activity. NudgeWhip does **not** read typed text, capture your screen, inspect browsing history, or collect message content.

### Recovery-first

This is not a punishment machine. It is an intervention layer designed to shorten the distance between distraction and return.

## Current Product Scope

### In the public beta

- menu bar runtime status
- Accessibility permission setup
- local idle detection
- local alert flow
- schedule-based pause windows
- daily stats
- local settings

### Planned next

- iPhone companion flow
- CloudKit sync
- richer exception handling
- more advanced whitelist and break behavior
- expanded feedback systems

Future scope is intentionally kept separate from the current beta promise.

## Privacy Notes

NudgeWhip draws a hard line:

- it uses global input activity
- it does not inspect content
- it stores summary data locally
- it avoids raw input logging

Full disclosure: [docs/privacy/accessibility-and-data-disclosure.md](docs/privacy/accessibility-and-data-disclosure.md)

## Build From Source

Current install path is source-first.

```bash
xcodebuild build -scheme nudge -destination 'platform=macOS'
```

Run the full suite:

```bash
xcodebuild test -scheme nudge -destination 'platform=macOS'
```

Run only UI tests:

```bash
xcodebuild test -scheme nudge -destination 'platform=macOS' -only-testing:nudgeUITests
```

## Requirements

- macOS `15.0+`
- Xcode `17+`

## Technical Shape

Core stack:

- `SwiftUI` for menu bar and settings UI
- `AppKit` for global event monitoring and alert/panel coordination
- `SwiftData` for local persistence

At a high level:

1. NudgeWhip records the last observed activity timestamp.
2. It schedules a one-shot idle deadline.
3. When the deadline is reached, it starts a local nudge flow.
4. When activity returns, it resets the timer and records local summary data.

## Repository Layout

```text
nudge/
├── nudge/                  # app source
├── nudgeTests/             # unit and runtime tests
├── nudgeUITests/           # UI tests
└── docs/                   # product, architecture, privacy, and release notes
```

## Beta Reality

This repository is not a concept dump.

It is an active public-beta / portfolio-stage product:

- the core loop is real
- the app builds and runs
- the design direction is intentional
- the surface area is still tightening

## License

License selection is not finalized yet for the public release branch.
