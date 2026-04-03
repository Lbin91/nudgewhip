# Onboarding Screenshot Review — 2026-04-03

- Reviewer: Codex
- Basis:
  - Desktop screenshots captured on 2026-04-03
  - `docs/app/first-install-onboarding-plan.md`
  - `docs/app/onboarding-refinement-plan.md`
- Scope: first-pass visual QA findings from the current macOS onboarding implementation

## 1. Reviewed Screens

Observed screenshots:

1. Welcome
2. Accessibility permission
3. Completion / Ready

The screenshots indicate the current layout direction is functional, but several visual and structural issues remain before the onboarding feels product-grade.

## 2. High-level findings

### 2.1 Too much unused vertical space

- The onboarding card sits in the upper area of the window, while a large blank area remains below.
- The window feels much taller than the actual information density requires.
- Completion screens show this most clearly.

### 2.2 CTA anchoring is weak

- Primary buttons feel visually detached from the main content block.
- In the completion screen, the CTA appears to float rather than conclude the section naturally.
- The action hierarchy is understandable, but not yet visually confident.

### 2.3 Summary block alignment is still slightly awkward

- The ready/completion summary reads more like a temporary debug/info box than a polished “final confirmation” section.
- Labels and values are understandable, but the block does not feel intentionally designed.

### 2.4 Permission screen hierarchy is better, but still text-heavy

- The permission screen communicates the right information.
- However, the body still relies heavily on stacked paragraphs.
- The “why” and “what we do not collect” sections should feel more explicitly separated.

### 2.5 Welcome screen is clear, but still sparse

- The welcome screen now reads much better than before.
- Even so, the left-heavy text stack and empty lower half make the screen feel unfinished.

## 3. Screen-specific findings

## 3.1 Welcome

### What works
- Title is large and easy to scan.
- “We do not collect …” bullets are readable.
- Primary CTA is obvious.

### What still feels off
- The content cluster ends too early vertically.
- The card does not feel visually balanced within the window.
- There is no strong visual anchor between headline/body/bullets.

### Refinement recommendation
- Slightly reduce overall window height or vertically rebalance content.
- Give the bullet block a clearer section identity.
- Consider a subtle icon/illustration or status-strip to add structure without clutter.

## 3.2 Permission

### What works
- State badge is visible.
- CTA set is complete: request / open settings / later.
- Copy is trust-first and understandable.

### What still feels off
- The explanatory text still reads like one long slab.
- The “later” action is visually separated, but the hierarchy between request/open-settings could be stronger when permission is denied.

### Refinement recommendation
- Separate:
  - why permission is needed
  - what is not collected
  - what happens if skipped
- Increase the visual distinction of the primary recovery action in denied cases.

## 3.3 Completion / Ready

### What works
- “준비 완료” is clear.
- Green success line communicates the state well.
- The CTA label is understandable.

### What still feels off
- The completion summary box feels too small compared to the whitespace around it.
- The success message and summary are visually disconnected.
- “메뉴바에서 시작” is centered visually, but the relationship between summary and CTA is weak.

### Refinement recommendation
- Treat the completion section as one structured success block:
  - success title
  - short reassurance
  - settings summary
  - final CTA
- Reduce the sense that the CTA is floating below an unrelated block.

## 4. Primary product risks from the screenshots

1. Users may read the onboarding as “working but temporary” rather than polished.
2. Completion screens may not strongly reinforce what happens next.
3. Permission explanations may still feel heavier than necessary.

## 5. Recommended follow-up polish tasks

Priority order:

1. Rebalance onboarding window height vs card content height
2. Tighten CTA placement and footer anchoring
3. Refine completion summary block styling
4. Split permission copy into clearer sub-sections
5. Add final visual polish to welcome screen density

## 6. Acceptance criteria for the next polish pass

- The onboarding window should not feel significantly taller than the information it contains.
- Primary CTA should visually conclude each screen, not appear detached from it.
- Completion screens should read as intentional “success states,” not generic forms.
- Permission screen should be scannable in distinct conceptual blocks.
- Welcome, Permission, and Completion should feel like one coherent product system.

## 7. Notes for implementation

- This review is visual and screenshot-based, not an interaction audit.
- Use this document together with:
  - `docs/app/onboarding-refinement-plan.md`
  - `docs/app/first-install-onboarding-wireflow-and-copy.md`
- Do not change copy meaning during polish unless localization/privacy docs are updated first.
