# CloudKit Daily Aggregate Backup 문서 리뷰

- Version: 1
- Date: 2026-04-13
- Reviewer: code-review (Oracle 검증 포함)
- Verdict: **REVISE**
- 대상 문서:
  1. `cloudkit-daily-aggregate-backup.md` (전략, 517 lines)
  2. `cloudkit-daily-aggregate-backup-implementation-todo.md` (TODO, 269 lines)
  3. `mac-daily-aggregate-service-design.md` (서비스 설계, 317 lines)
- 교차 참조: `task-ios-dashboard-data-schema.md` (iOS dashboard schema)

## 1. 검증 방법

- 3종 문서 전문 독해
- 실제 코드베이스(SwiftData 모델, derive 로직, 서비스 계층) 교차 검증
- 문서 간 정합성 비교 (A↔B↔C↔D)
- Oracle 에이전트로 8개 질의에 대한 심층 분석

## 2. 코드베이스 검증 요약

| 항목 | 문서 기술 | 실제 코드 | 일치 |
|------|----------|----------|:----:|
| `DailyStats.derive()` 존재 | ✅ | `DailyStats.swift:50` — `static func derive(for:on:calendar:)` | ✅ |
| `StatisticsSnapshot.derive()` 존재 | ✅ | `DailyStats.swift:126` — 동일 파일 내 | ✅ |
| `FocusSession.focusDuration(overlapping:)` 존재 | ✅ | `FocusSession.swift:85` — `DateInterval` 교집합 | ✅ |
| `AlertingSegment` 필드 | startedAt, recoveredAt, duration | startedAt, recoveredAt ✅ / **duration은 computed property** | ⚠️ |
| CloudKit 코드 | (미구현 명시) | **Zero** — CKRecord/CKContainer 없음 | ✅ |
| `localDayKey` 포맷 | `2026-04-13@Asia/Seoul` | **존재하지 않음** — Date/DateInterval만 사용 | ✅ (신규) |
| `macDeviceID` 제공 | builder 입력 | **존재하지 않음** | ✅ (신규) |
| `sessionsOver30mCount` 계산 | builder에서 구현 예정 | **존재하지 않음** | ✅ (신규) |
| `hourlyAlertCounts` 계산 | builder에서 구현 예정 | **존재하지 않음**, 하지만 `AlertingSegment.startedAt`으로 계산 가능 | ⚠️ |
| `completedSessionCount` 귀속 | 세션 시작일 귀속 | **현재 코드는 overlap 기준** (focusDuration > 0인 세션 수) | ❌ |
| Cross-midnight 분할 | `focusDuration(overlapping:)` 재사용 | 동일 메서드 존재, 정확히 같은 방식 | ✅ |

## 3. 판정 근거

3종 문서는 **의도와 구조적으로 잘 설계**됨. 전략→TODO→서비스설계의 3단계 분리, local day 기준, upsert/overwrite, builder/writer 분리 모두 합리적.

그러나 **코드베이스 실제 truth와의 매핑이 불충분**한 부분이 있어 구현 착수 전 보강 필요.

## 4. P1 — 구현 전 수정 필요 (3건)

### P1-1. `hourlyAlertCounts` truth 진단 오류

**문서**: `mac-daily-aggregate-service-design.md` §7.6

> "현재 truth에 alert timestamp가 `lastAlertAt` 하나만으로 충분한지 점검 필요"

**실제 상황**: `SessionTracker.recordAlertStarted(at:)`가 `AlertingSegment`를 생성하므로, `alertCount == alertingSegments.count` (1:1 대응). 각 `AlertingSegment.startedAt`이 개별 alert 이벤트 타임스탬프 역할을 함. **truth는 충분함.**

**문제점**: 문서가 `lastAlertAt`의 부족함을 걱정하지만, 실제로는 `AlertingSegment.startedAt`을 명시적으로 지정하면 바로 해결됨.

**수정 제안**:

```markdown
### §7.6 Hourly Alert Counts

규칙:
- `FocusSession.alertingSegments[].startedAt`를 local timezone 기준 hour bucket으로 분류
- `session.alertCount == alertingSegments.count` 불변식으로 정합성 검증
- 항상 24칸 고정

참고:
- `session.alertCount`는 세그먼트 수와 1:1 (SessionTracker가 각 alerting episode마다 세그먼트 생성)
- 개별 alert timestamp truth는 `AlertingSegment.startedAt`에 이미 존재
```

---

### P1-2. `completedSessionCount` UI↔Backup 불일치 미명시

**문서**: `cloudkit-daily-aggregate-backup.md` §10, `cloudkit-daily-aggregate-backup-implementation-todo.md` §5, `mac-daily-aggregate-service-design.md` §7.3

**현재 코드** (`DailyStats.swift:61-77`):
```swift
let sessionsWithFocus = Array(zip(sessions, sessionFocusDurations))
    .filter { _, duration in duration > 0 }
completedSessionCount: sessionsWithFocus.count
```

→ overlap이 0보다 큰 **모든** 세션을 카운트. 자정을 넘나드는 세션은 **양쪽 날 모두**에서 카운트됨.

**문서 기술**: "세션 시작일 귀속" — 세션이 시작한 날에만 카운트.

**문제점**: 이 규칙이 DailyStats와 Cloud backup 간에 **다른 값을 생성**한다는 점이 세 문서 어디에도 명시되지 않음. Doc C §7.3은 "현재 DailyStats.derive()는 이 점이 정확히 일치하지 않을 수 있으므로"라고 언급하지만, 결과적으로 **숫자가 달라진다**는 점을 명확히 해야 함.

**수정 제안** — 3개 문서 모두에 추가:

```markdown
> ⚠️ **UI↔Backup 수치 불일치 안내**
>
> `completedSessionCount`의 귀속 규칙이 UI 통계와 Cloud backup에서 다름:
> - **UI (DailyStats)**: `focusDuration(overlapping:) > 0`인 세션 수 (overlap 기준)
> - **Backup (Builder)**: `calendar.isDate(session.startedAt, inSameDayAs: referenceDate)` (시작일 기준)
>
> 자정을 넘나드는 세션의 경우, UI는 양쪽 날 모두에서 1로 카운트하지만
> backup은 시작일에만 1로 카운트함.
> 이 불일치는 의도적임 (backup은 deterministic start-day attribution 유지).
```

---

### P1-3. Doc A ↔ Doc D 스키마 타입 불일치

| 필드 | Doc A §15.3 (전략) | Doc D §7.4 (iOS schema) | 해결 |
|------|---------------------|-------------------------|------|
| `schemaVersion` | `Int64` | `Int` | → `Int64` |
| duration 필드명 | `totalFocusDurationSeconds` | `totalFocusDuration` ("Double or Int seconds") | → `totalFocusDurationSeconds` (Int64) |

**수정 제안**: Doc D가 Doc A를 canonical type source로 명시 참조. 또는 Doc D §7.4를 Doc A §15.3 타입으로 업데이트.

```markdown
// Doc D §7.4에 추가:
> CloudKit field type은 `cloudkit-daily-aggregate-backup.md` §15.3을 canonical source로 참조.
```

## 5. P2 — 권장 사항 (3건)

### P2-1. `focusDuration(overlapping:)` 재사용 시 count 필터 혼동 위험

**문서**: `cloudkit-daily-aggregate-backup-implementation-todo.md` §5 Step 2

`focusDuration(overlapping:)` 재사용과 `completedSessionCount` 시작일 귀속이 나란히 기술되어 있어, 개발자가 DailyStats.derive() 패턴을 그대로 복사할 위험.

**권장**: WARNING 주석 추가:

```markdown
> ⚠️ `completedSessionCount`는 `focusDuration(overlapping:) > 0` 필터로 계산하지 않음.
> `calendar.isDate(session.startedAt, inSameDayAs:)` 기준으로 별도 필터링 필요.
```

---

### P2-2. TimeZone fallback 비결정성

**문서**: `mac-daily-aggregate-service-design.md` §7.1

```swift
calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
```

malformed identifier 시 `?? .current`가 기기 timezone에 의존 → 비결정적.

**권장**: throw 또는 `?? .gmt`로 변경:

```swift
guard let tz = TimeZone(identifier: timeZoneIdentifier) else {
    throw ProjectionError.invalidTimeZoneIdentifier(timeZoneIdentifier)
}
calendar.timeZone = tz
```

---

### P2-3. `AlertingSegment.duration` computed property 명시

**문서**: `mac-daily-aggregate-service-design.md` §7.5

`AlertingSegment.duration`은 stored field가 아닌 computed property (`recoveredAt.timeIntervalSince(startedAt)`). CloudKit snapshot 시점에는 정확한 값을 제공하므로 기능적 문제는 없으나, 문서에 명시되어 있지 않음.

**권장**: §7.5에 1줄 추가:

```markdown
> `AlertingSegment.duration`은 computed property (`recoveredAt - startedAt`).
> CloudKit 저장 시 snapshot 값을 저장하므로 계산 시점 기준으로 안전함.
```

## 6. 긍정적 평가

| 항목 | 평가 |
|------|------|
| Local Day vs UTC Day 의사결정 | ✅ 제품 mental model과 정확히 정렬 |
| Builder/Writer/Coordinator 3계층 분리 | ✅ 책임 분리 명확 |
| Timezone 변경 시 과거 재작성 금지 | ✅ 실용적이고 안전한 정책 |
| Privacy boundary (raw 미업로드) | ✅ 명확하고 일관됨 |
| Additive schema 진화 원칙 | ✅ CloudKit best practice 부합 |
| Cross-midnight 규칙 (duration 분할 / count 귀속 분리) | ✅ 원칙 자체는 정확 |
| Deterministic builder 설계 | ✅ explicit timezone injection으로 달성 가능 |
| Open questions 명시 | ✅ 미결정 사항을 숨기지 않음 |
| 3단계 문서 구조 (전략→TODO→서비스) | ✅ 구현자가 바로 착수 가능한 수준 |

## 7. 수정 후 재검토 항목

P1 3건 수정 후 다시 검토 필요:

- [ ] §7.6 hourlyAlertCounts truth 매핑 명시
- [ ] completedSessionCount UI↔Backup 불일치 사전 고지
- [ ] Doc A ↔ Doc D 타입 정합

## 8. 결론

3종 문서는 **구조와 의도가 견고**하며, 구현 착수의 기준 문서로 적합한 수준.
그러나 코드베이스 실제 truth(특히 `AlertingSegment.startedAt`, `completedSessionCount` overlap 기반 카운트)와의 매핑이 P1 수준에서 불충분.
**P1 3건 수정 후 APPROVED 전환 예상.**
