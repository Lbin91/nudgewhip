# CloudKit Daily Aggregate Backup TODO

Source:
- `docs/architecture/cloudkit-daily-aggregate-backup.md`
- `docs/architecture/cloudkit-daily-aggregate-backup-implementation-todo.md`
- `docs/architecture/mac-daily-aggregate-service-design.md`

Current release focus:
- Keep local SwiftData as source of truth.
- Compute daily aggregates by **local timezone midnight**.
- Back up only daily aggregate projection to CloudKit private DB.
- Do not upload raw input timeline, window title, URL, or typed contents.

## 1. Test-first guardrails

- [x] Add payload/builder tests before implementation
- [x] Add at least one failure-first test for cross-midnight attribution
- [x] Add at least one failure-first test for hourly alert bucketing
- [x] Add Cloud writer mapping tests before writer implementation

## 2. Projection model foundation

- [x] Add `DashboardDayProjectionPayload`
- [x] Add deterministic `localDayKey` generation
- [x] Normalize duration/count fields to integer seconds / integer counts
- [x] Add schema version field and optional UTC source window fields

## 3. Mac-side aggregation builder

- [x] Add `DailyAggregateProjectionBuilder`
- [x] Build local-day interval from explicit timezone identifier
- [x] Reuse `FocusSession.focusDuration(overlapping:)` for duration math
- [x] Implement `completedSessionCount` as **session start-day attribution**
- [x] Implement `sessionsOver30mCount` from full session duration
- [x] Implement recovery metrics from `AlertingSegment`
- [x] Implement `hourlyAlertCounts` from `AlertingSegment.startedAt`

## 4. CloudKit writer

- [x] Add `CloudKitDailyAggregateBackupWriter`
- [x] Map payload to `DashboardDayProjection` record
- [x] Use deterministic `recordName = macDeviceID + \"__\" + localDayKey`
- [x] Target private DB + `NudgeWhipSync` zone
- [x] Serialize `hourlyAlertCounts` as `hourlyAlertCountsJSON`

## 5. Trigger wiring

- [x] Add stable `macDeviceID` provider
- [x] Recompute/write on session updates
- [x] Recompute/write on recovery completion
- [x] Recompute/finalize at local midnight boundary
- [x] Recompute on launch / foreground recovery path

## 6. Failure handling

- [x] Keep local projection calculation independent of CloudKit success
- [x] Coalesce same-day rewrites instead of append
- [x] Add retry path for transient CloudKit failure

## 7. Verification

- [x] Confirm failure-first tests fail for the right reason before implementation
- [x] Run targeted unit tests during implementation
- [x] Run `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'`
- [ ] Run `xcodebuild test -scheme nudgewhip -destination 'platform=macOS'`
  - unit tests (`-only-testing:nudgewhipTests`) passed
  - full suite hit UI automation flake once (`Timed out while enabling automation mode`)

## 8. Completion gate

- [x] Payload/builder/writer/trigger wiring all implemented
- [x] Failure-first tests now pass
- [ ] No new test regressions introduced
- [x] TODO reflects only current CloudKit daily backup work
