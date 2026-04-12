# Countdown Overlay Mini Mode TODO

Source:
- `docs/app/task-countdown-overlay-mini-and-positioning.md`
- `docs/app/task-countdown-overlay-mini-and-positioning-review.md`

Current release focus:
- Reduce countdown overlay fatigue without removing quick-glance value.
- Keep 4-corner positioning as the official product contract.
- Preserve the menu-presentation guard and do not treat MenuBarExtra hover/depth-menu tracking as activity.

## 1. Product and copy alignment

- [ ] Reflect review decisions in the planning doc:
  - dynamic panel size by variant
  - `limitedNoAX`: mini shows `AX`, standard keeps threshold text
  - lightweight settings preview only
  - variant-based mouse event handling
  - no transition animation in this scope
- [ ] Replace `top countdown overlay` / `Top overlay` copy with position-neutral `countdown overlay`
- [ ] Update affected UI tests for the new copy

## 2. Overlay model and runtime wiring

- [ ] Add `CountdownOverlayVariant` persistence to `UserSettings`
- [ ] Expose overlay variant through `MenuBarViewModel` and `SettingsViewModel`
- [ ] Observe `countdownOverlayVariant` in `CountdownOverlayController`
- [ ] Switch panel size dynamically between standard and mini
- [ ] Switch `ignoresMouseEvents` by variant (`standard = false`, `mini = true`)

## 3. Overlay UI implementation

- [ ] Keep the current standard overlay behavior intact
- [ ] Implement mini overlay layout (`96x32` target) with reduced chrome
- [ ] Show countdown-only or compact state tokens in mini mode
- [ ] Keep standard `limitedNoAX` behavior and use `AX` only in mini mode

## 4. Settings and onboarding surfaces

- [ ] Add `Standard | Mini` selector to Settings
- [ ] Add a lightweight settings preview swatch for variant + position
- [ ] Keep onboarding overlay control limited to on/off
- [ ] Update completion summary wording to `Countdown overlay`

## 5. Verification

- [ ] Add/update unit tests for dynamic panel sizing and corner positioning behavior where practical
- [ ] Verify KR/EN copy after the rename
- [ ] Run `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'`
- [ ] Run `xcodebuild test -scheme nudgewhip -destination 'platform=macOS'`

## 6. Completion gate

- [ ] All items above complete
- [ ] TODO stays aligned with the shipped overlay scope only
