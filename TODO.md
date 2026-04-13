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

- [ ] Add payload/builder tests before implementation
- [ ] Add at least one failure-first test for cross-midnight attribution
- [ ] Add at least one failure-first test for hourly alert bucketing
- [ ] Add Cloud writer mapping tests before writer implementation

## 2. Projection model foundation

- [ ] Add `DashboardDayProjectionPayload`
- [ ] Add deterministic `localDayKey` generation
- [ ] Normalize duration/count fields to integer seconds / integer counts
- [ ] Add schema version field and optional UTC source window fields

## 3. Mac-side aggregation builder

- [ ] Add `DailyAggregateProjectionBuilder`
- [ ] Build local-day interval from explicit timezone identifier
- [ ] Reuse `FocusSession.focusDuration(overlapping:)` for duration math
- [ ] Implement `completedSessionCount` as **session start-day attribution**
- [ ] Implement `sessionsOver30mCount` from full session duration
- [ ] Implement recovery metrics from `AlertingSegment`
- [ ] Implement `hourlyAlertCounts` from `AlertingSegment.startedAt`

## 4. CloudKit writer

- [ ] Add `CloudKitDailyAggregateBackupWriter`
- [ ] Map payload to `DashboardDayProjection` record
- [ ] Use deterministic `recordName = macDeviceID + \"__\" + localDayKey`
- [ ] Target private DB + `NudgeWhipSync` zone
- [ ] Serialize `hourlyAlertCounts` as `hourlyAlertCountsJSON`

## 5. Trigger wiring

- [ ] Add stable `macDeviceID` provider
- [ ] Recompute/write on session updates
- [ ] Recompute/write on recovery completion
- [ ] Recompute/finalize at local midnight boundary
- [ ] Recompute on launch / foreground recovery path

## 6. Failure handling

- [ ] Keep local projection calculation independent of CloudKit success
- [ ] Coalesce same-day rewrites instead of append
- [ ] Add retry path for transient CloudKit failure

## 7. Verification

- [ ] Confirm failure-first tests fail for the right reason before implementation
- [ ] Run targeted unit tests during implementation
- [ ] Run `xcodebuild build -scheme nudgewhip -destination 'platform=macOS'`
- [ ] Run `xcodebuild test -scheme nudgewhip -destination 'platform=macOS'`

## 8. Completion gate

- [ ] Payload/builder/writer/trigger wiring all implemented
- [ ] Failure-first tests now pass
- [ ] No new test regressions introduced
- [ ] TODO reflects only current CloudKit daily backup work
