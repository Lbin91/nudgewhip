# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Nudge (넛지)** — macOS menu bar utility that detects user inactivity (idle/offline distraction) and gently nudges them back to work via visual alerts, notification follow-ups, and a virtual pet system. Future iOS companion app for cross-device push notifications.

## Build & Development Commands

```bash
# Build (macOS target)
xcodebuild build -scheme nudge -destination 'platform=macOS'

# Run tests
xcodebuild test -scheme nudge -destination 'platform=macOS'

# Run single test file
xcodebuild test -scheme nudge -destination 'platform=macOS' -only-testing:nudgeTests/NudgeTests

# Run UI tests
xcodebuild test -scheme nudge -destination 'platform=macOS' -only-testing:nudgeUITests
```

## Architecture

**Hybrid SwiftUI + AppKit** approach for macOS menu bar app:

- **SwiftUI** (`MenuBarExtra`): All UI — dropdown view, settings, pet animations, stats dashboard. Requires macOS 15.0+.
- **AppKit** (`NSEvent`): Core idle detection logic — `addGlobalMonitorForEvents(matching:handler:)` hooks global mouse/keyboard events from background.
- **SwiftData**: Local persistence for settings, focus sessions, pet state, daily stats.
- **CloudKit** (planned): Serverless sync between macOS and iOS via `CKQuerySubscription` + APNs push. Private Database only.

### Key Technical Constraints

- **LSUIElement = YES** in build settings — app runs as background agent, no Dock icon.
- **Accessibility permission required** — `AXIsProcessTrusted()` must pass before global event monitoring works. App must gracefully degrade without it.
- **Main Thread required** for all NSEvent monitor registration — use `@MainActor`.
- **Shared module** (`nudge/Shared/`): Business logic and data models shared between macOS and iOS targets. Currently single-target; multi-target structure planned.

### Data Flow

```
NSEvent global monitor → Idle timer countdown → Threshold reached → Alert triggered
                                                           ↓
                                              CloudKit record update → iOS push (Pro)
User activity detected ← Alert dismissed ← Reset timer
```

## Project Structure

```
nudge/
├── nudgeApp.swift          # @main entry, MenuBarExtra setup
├── ContentView.swift       # Menu bar dropdown view (placeholder)
├── Item.swift              # SwiftData @Model (placeholder, will be replaced)
├── Assets.xcassets/        # App icons and colors
├── Services/               # (planned) IdleMonitor, PermissionManager, AlertManager, CloudKitManager
├── Views/                  # (planned) SwiftUI views for menu bar, alerts, pet, stats
└── Shared/                 # (planned) Cross-platform models and services for macOS + iOS
nudgeTests/                 # Unit tests (XCTestCase)
nudgeUITests/               # UI tests
docs/
└── app/spec.md             # Full PRD with feature specs and tech stack details
```

## Agent Team (Harness) — Multi-Tool Compatible

10-agent team for coordinated development. Agent definitions in `.claude/agents/`.

### Claude Code에서 실행

`/nudge-develop` 스킬로 전체 파이프라인 자동 실행.

### 다른 도구(Codex, OpenCode, Cursor 등)에서 실행

스킬 시스템이 없는 환경에서는 아래 절차를 수동으로 따른다. 각 에이전트의 상세 정의는 `.claude/agents/{name}.md`를 읽어 역할과 원칙을 파악한다.

**에이전트 목록:**

| 에이전트 | 역할 | 핵심 산출물 |
|---------|------|------------|
| `data-architect` | SwiftData 모델 & 상태 관리 | `nudge/Shared/Models/*.swift` |
| `macos-core` | AppKit NSEvent 전역 감지, 권한 | `nudge/Services/IdleMonitor.swift`, `PermissionManager.swift` |
| `swiftui-designer` | MenuBarExtra UI, 알림 오버레이, 펫 | `nudge/Views/*.swift`, `Services/AlertManager.swift` |
| `cloudkit-sync` | CloudKit 동기화, iOS 푸시 | `nudge/Shared/Services/CloudKitManager.swift` |
| `qa-integrator` | XCTest, 통합 검증 | `nudgeTests/*.swift`, `nudgeUITests/*.swift` |
| `marketing-strategist` | 런칭 전략, 카피, 경쟁 분석 | `docs/marketing/*.md` |
| `content-strategist` | 알림 종류, 캐릭터 설정, 게이미피케이션 | `docs/content/*.md` |
| `visual-designer` | 캐릭터 디자인, 아이콘, 컬러 시스템 | `docs/design/*.md` |
| `localization` | 다국어 현지화 (i18n/l10n), String Catalog | `nudge/Localizable.xcstrings`, `docs/localization/*.md` |
| `web-dev` | 사전 홍보 랜딩 페이지 | `docs/web/*` |

**실행 순서 (의존성 기반):**

```
Phase 1 (병렬):
  [data-architect]     → SwiftData 모델 설계 (의존성 없음, 가장 먼저)
  [marketing-strategist] → 마케팅 전략 수립
  [content-strategist]   → 캐릭터/알림 콘텐츠 기획

Phase 2 (Phase 1 완료 후, 병렬):
  [macos-core]         → Idle Detection + 권한 관리 (data-architect 완료 후)
  [visual-designer]    → 캐릭터/비주얼 디자인 (content-strategist 완료 후)
  [marketing-strategist] → 카피 작성 (전략 수립 완료 후)

Phase 3 (Phase 2 완료 후, 병렬):
  [swiftui-designer]   → MenuBarExtra UI + 알림 시스템 (macos-core + visual-designer 완료 후)
  [cloudkit-sync]      → CloudKit 동기화 (data-architect + macos-core 완료 후)
  [localization]       → String Catalog 다국어 현지화 (content + marketing 카피 완료 후)
  [web-dev]            → 랜딩 페이지 (카피 + 디자인 + 현지화 완료 후)

Phase 4 (Phase 3 완료 후):
  [qa-integrator]      → 단위 테스트 → 통합 테스트 → 최종 검증
```

**부분 실행:** 전체가 아닌 특정 작업만 필요하면 해당 에이전트의 `.claude/agents/{name}.md`를 읽고 그 에이전트의 역할 범위 내에서만 작업한다.

## Commit Language

Commit messages are written in **Korean** (한국어). Format: `type: 설명` (feat/fix/refactor/docs/chore/test).

## Current State

Early stage — Xcode project template with `MenuBarExtra` configured. `Item.swift` is a placeholder SwiftData model that will be replaced with actual domain models (`FocusSession`, `UserSettings`, `PetState`, `DailyStats`).

## 작업완료 시
작업이 완료되면 아래의 shell 스크립트를 동작 시킨다.
~/Documents/Project/bots/.claude_done.sh
