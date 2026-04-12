# Countdown Overlay Mini Mode TODO

Source:
- `docs/app/task-countdown-overlay-mini-and-positioning.md`
- `docs/app/task-countdown-overlay-mini-and-positioning-review.md`

Current release focus:
- Reduce countdown overlay fatigue without removing quick-glance value.
- Keep 4-corner positioning as the official product contract.
- Preserve the menu-presentation guard and do not treat MenuBarExtra hover/depth-menu tracking as activity.
- Track the mini hover close affordance as an active follow-up experiment.

## 1. Product and copy alignment

- [x] Reflect review decisions in the planning doc:
  - dynamic panel size by variant
  - `limitedNoAX`: mini shows `AX`, standard keeps threshold text
  - lightweight settings preview only
  - variant-based mouse event handling
  - no transition animation in this scope
- [x] Replace `top countdown overlay` / `Top overlay` copy with position-neutral `countdown overlay`
- [x] Update affected UI tests for the new copy

## 2. Overlay model and runtime wiring

- [x] Add `CountdownOverlayVariant` persistence to `UserSettings`
- [x] Expose overlay variant through `MenuBarViewModel` and `SettingsViewModel`
- [x] Observe `countdownOverlayVariant` in `CountdownOverlayController`
- [x] Switch panel size dynamically between standard and mini
- [x] Ship the baseline variant wiring and record the hover-affordance deviation separately

## 3. Overlay UI implementation

- [x] Keep the current standard overlay behavior intact
- [x] Implement mini overlay layout (`96x32` target) with reduced chrome
- [x] Show countdown-only or compact state tokens in mini mode
- [x] Keep standard `limitedNoAX` behavior and use `AX` only in mini mode

## 4. Settings and onboarding surfaces

- [x] Add `Standard | Mini` selector to Settings
- [x] Add a lightweight settings preview swatch for variant + position
- [x] Keep onboarding overlay control limited to on/off
- [x] Update completion summary wording to `Countdown overlay`

## 5. Verification

- [x] Add/update unit tests for dynamic panel sizing and corner positioning behavior where practical
- [x] Verify KR/EN copy after the rename
- [x] Run `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'`
- [x] Run `xcodebuild test -scheme nudgewhip -destination 'platform=macOS'`

## 6. Completion gate

- [x] All items above complete
- [x] TODO stays aligned with the shipped overlay scope only

## 7. Follow-up completed after ship decision

- [x] Add Dock magnify / multi-monitor visual QA matrix
- [x] Add mini hover affordance experiment and keep it documented as an experiment
- [x] Add fresh-install mini-default checklist
