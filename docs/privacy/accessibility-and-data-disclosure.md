# Accessibility and Data Disclosure

- Version: 0.1
- Last Updated: 2026-04-02
- Owner: `localization` + `macos-core`
- Purpose: user-facing disclosure for Accessibility permission, data handling, and CloudKit behavior

## 1. Accessibility Permission Rationale

NudgeWhip needs Accessibility permission because macOS does not expose reliable global keyboard and mouse activity monitoring without it. The app uses that permission only to detect idle and active transitions, then trigger local nudges and state changes.

### User-facing rationale

- The app monitors system-wide input activity to detect when the user stops interacting with the Mac.
- The app does not need to read typed text, screen contents, or application data to perform this function.
- If Accessibility permission is denied, the app continues in a limited mode and clearly explains what is unavailable.

## 2. Data We Collect

- Timestamp of input activity transitions
- Idle duration and alert timing
- Focus session start/end timestamps
- Warning counts and session summary metrics
- User settings such as threshold, alerts, and pause state
- Whitelist app identifiers when enabled
- Local device state needed for sync metadata, such as sequence numbers and state change timestamps

## 3. Data We Do Not Collect

- Keystroke content
- Screen captures or screenshots
- Clipboard contents
- Browsing history
- File contents
- Email, messages, or app payloads
- Audio recordings
- Raw global input event logs beyond timing/count metadata

## 4. Storage and Sync Rules

- Local `SwiftData` is the source of truth for app state
- `UserDefaults` is used only for lightweight device-local flags
- CloudKit is used only for Pro sync behavior and state transfer metadata
- CloudKit is not used as a general-purpose user data warehouse
- Raw input events are not persisted; only summary timing and state transitions are stored

## 5. CloudKit Conditions

- CloudKit sync runs only when the user has Pro features enabled and iCloud is available
- CloudKit is best-effort, not a real-time guarantee
- Push updates are state-transition based, not continuous heartbeat tracking
- If iCloud is unavailable, the app stays in local-only mode and continues to work offline
- StoreKit entitlement and iCloud availability are treated as separate conditions

## 6. User-Facing Disclosure Copy

### KR

- `손쉬운 사용 권한은 전역 입력 활동을 감지해 무입력 상태를 파악하고, 로컬 넛지를 표시하기 위해서만 사용합니다.`
- `키 입력 내용, 화면 내용, 파일, 메시지, 브라우징 기록은 수집하지 않습니다.`
- `Pro 기능에서만 iCloud 동기화가 사용되며, 이 동기화는 상태 전이 메타데이터만 다룹니다.`
- `권한을 거부해도 앱은 제한 모드로 계속 실행됩니다.`

### EN

- `Accessibility permission is used only to detect global input activity so NudgeWhip can identify idle periods and show local nudges.`
- `NudgeWhip does not collect keystroke content, screen contents, files, messages, or browsing history.`
- `iCloud sync is used only for Pro features and only for state-transition metadata.`
- `If you deny the permission, the app continues to run in limited mode.`

## 7. Disclosure Placement

- First-run onboarding permission screen
- Settings privacy section
- App Store privacy details
- Launch website privacy section
- FAQ entry for permission and sync behavior

## 8. App Store and Privacy Policy Alignment Notes

- The App Store privacy label should describe collected metadata, not screen or text content
- The privacy policy should distinguish local-only functionality from Pro sync functionality
- The policy should state that Accessibility is required for system-wide input detection
- The policy should state that no keystroke content or screen capture is collected
- The policy should state that CloudKit sync is optional and tied to Pro features
- Marketing copy must not promise real-time sync or broader data collection than the app actually performs

## 9. Review Checklist

- The disclosure text matches the app behavior contract
- The wording is consistent with `docs/app/spec.md`
- The wording is consistent across KR and EN
- The App Store privacy label can be generated directly from this document without adding new claims
