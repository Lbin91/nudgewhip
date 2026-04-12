# NudgeWhip v0.2.0

First stabilization release.

This release keeps the macOS core loop intact while tightening the roughest edges from the initial beta.

## Highlights

- menu bar app with `LSUIElement` behavior
- Accessibility permission onboarding with limited-mode fallback
- one-shot idle deadline scheduling
- local visual nudge flow and system notification escalation
- schedule controls, countdown overlay positioning, and local daily summary stats
- Korean and English support

## Out Of Scope

- iOS companion app
- CloudKit sync
- Pro packaging
- expanded progression systems

## Verification

Verified during release prep:

- `xcodebuild build -scheme nudgewhip -project nudgewhip.xcodeproj -destination 'platform=macOS'`
- `xcodebuild analyze -scheme nudgewhip -project nudgewhip.xcodeproj -destination 'platform=macOS'`
- `xcodebuild test -scheme nudgewhip -project nudgewhip.xcodeproj -destination 'platform=macOS' -only-testing:nudgewhipTests`
- `xcodebuild test -scheme nudgewhip -project nudgewhip.xcodeproj -destination 'platform=macOS' -only-testing:nudgewhipUITests`
