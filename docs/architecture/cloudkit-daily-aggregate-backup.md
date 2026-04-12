# NudgeWhip CloudKit Daily Aggregate Backup Strategy

- Version: draft-1
- Last Updated: 2026-04-13
- Status: proposed
- Owner: product / engineering
- Scope: macOS local raw/session 데이터를 하루 단위 aggregate로 압축해 iCloud/CloudKit에 백업하는 전략

## 1. Purpose

- 이 문서는 NudgeWhip의 로컬 raw/session 데이터를 **하루 단위 aggregate**로 종합해 CloudKit에 백업할 때의 기준을 정의한다.
- 핵심 질문은 세 가지다.
  1. 하루 단위 기준을 `local day`로 할지 `UTC day`로 할지
  2. 어떤 데이터를 어떤 수준으로 aggregate 저장할지
  3. iCloud 백업이 `분석 warehouse`가 아니라 `읽기 최적화 + 복구 가능한 백업`으로 남게 하려면 어떤 계약이 필요한지

## 2. Current State

현재 구현 기준:

- source of truth는 **로컬 SwiftData**
- 저장 모델은 `UserSettings`, `FocusSession`, `AppUsageSegment`, 기타 파생 계산용 로컬 모델
- CloudKit / iCloud에는 아직 통계 데이터가 올라가지 않는다

즉, 지금은:

- **로컬에 raw/session truth가 있고**
- **CloudKit daily aggregate backup은 아직 미구현**

상태다.

## 3. Non-negotiable Principles

1. **로컬이 source of truth다**
2. **CloudKit은 raw event 저장소가 아니라 aggregate backup/read model 운반 계층이다**
3. **사용자에게 보이는 하루 기준과 저장 키 기준이 어긋나면 안 된다**
4. **privacy boundary를 넘는 원시 데이터는 올리지 않는다**
5. **iPhone/iPad/향후 companion 화면은 raw를 재구성하지 않고 projection을 소비한다**

## 4. The Core Decision: Local Day vs UTC Day

## 4.1 Option A — Local Day 기준

정의:

- 하루 키를 사용자의 계산 시점 timezone 기준으로 나눈다
- 예: `2026-04-13@Asia/Seoul`

장점:

- 사용자 mental model과 일치한다
- “오늘/어제/이번 주” 통계와 바로 연결된다
- iOS dashboard나 daily review에서 추가 변환 비용이 적다
- 현재 문서 체계(`localDayKey`, `timeZoneIdentifier`)와 이미 맞아 있다

단점:

- timezone 변경(여행/이주) 시 historical day 해석에 주의가 필요하다
- UTC 기준 analytics warehouse처럼 다루기엔 불편하다

## 4.2 Option B — UTC Day 기준

정의:

- 모든 집계를 UTC 00:00~24:00 기준으로 끊는다

장점:

- 서버/분산 처리 관점에서는 단순하다
- timezone 변경에도 저장 키는 흔들리지 않는다

단점:

- 사용자에게 보이는 “오늘”과 어긋난다
- 로컬 UI/통계에서 매번 local re-mapping이 필요하다
- cross-midnight session 체감과 사용자 기대에 더 어긋날 수 있다

## 4.3 Recommended Decision

**권장: Local Day를 primary partition으로 사용한다.**

즉:

- identity key는 `macDeviceID + localDayKey`
- `localDayKey` 예시: `2026-04-13@Asia/Seoul`
- `dayStart`는 해당 local day의 시작 `Date`
- `timeZoneIdentifier`는 projection 계산 기준 timezone

이유:

- NudgeWhip의 통계는 서버 중심 운영 데이터보다 **사용자 회고와 daily pattern 이해**가 더 중요하다
- 이 제품에서 하루는 “UTC 기준 하루”가 아니라 “사용자가 경험한 하루”에 가깝다
- 기존 `task-ios-dashboard-data-schema.md`와도 가장 잘 정렬된다

## 5. Recommended Hybrid Rule

Local Day를 기본 키로 쓰되, UTC 정보를 보조 필드로 남기는 전략이 가장 안정적이다.

권장 필드:

- `localDayKey`
- `dayStart`
- `timeZoneIdentifier`
- `updatedAt`
- `sourceWindowUTCStart` (optional)
- `sourceWindowUTCEnd` (optional)

이렇게 하면:

- 제품 UI는 local day 기준으로 단순하게 유지하고
- 나중에 timezone troubleshooting이나 백필(backfill) 분석이 필요할 때도 최소한의 UTC 힌트를 갖게 된다

## 6. Timezone Change Policy

timezone 변경은 “과거 데이터를 새 timezone으로 다시 재배치할지”가 핵심이다.

### Recommended

- **이미 계산된 historical day projection은 계산 당시 local timezone 기준을 유지한다**
- timezone이 바뀌면 **그 이후 생성되는 새 day projection부터 새 timezone을 사용한다**

예:

- 2026-04-13 서울에서 사용 → `2026-04-13@Asia/Seoul`
- 2026-04-14 도쿄로 이동 후 사용 → `2026-04-14@Asia/Tokyo`

즉, 과거를 재작성하지 않는다.

이 정책의 장점:

- overwrite/recompute 혼란이 줄어든다
- 이미 표시된 하루 통계가 뒤늦게 바뀌지 않는다
- CloudKit upsert 계약이 단순해진다

비고:

- 장기적으로 “사용자의 현재 timezone 기준으로 historical day를 다시 보기”가 필요해지면, 이는 **뷰 레벨 해석 기능**으로 다루고 저장 키는 유지하는 편이 안전하다

## 7. What To Back Up

하루 단위 aggregate backup은 raw를 올리는 게 아니라, 로컬 truth를 **제품 의미가 있는 요약치**로 압축해 저장해야 한다.

## 7.1 Must-have v1 Fields

권장 record type:

- `DashboardDayProjection` 또는 별도 `DailyAggregateBackup`

권장 필드:

- `macDeviceID`
- `localDayKey`
- `dayStart`
- `timeZoneIdentifier`
- `updatedAt`
- `schemaVersion`
- `totalFocusDurationSeconds`
- `completedSessionCount`
- `alertCount`
- `longestFocusDurationSeconds`
- `recoverySampleCount`
- `recoveryDurationTotalSeconds`
- `recoveryDurationMaxSeconds`
- `sessionsOver30mCount`
- `hourlyAlertCounts[24]`

이 조합이면:

- 오늘/주간 회고
- recovery metric
- 시간대별 패턴

까지 대부분 설명 가능하다.

## 7.2 Recommended v1.1 / Optional Fields

- `remoteEscalationSentCount`
- `remoteEscalationRecoveredWithinWindowCount`
- `focusStartCount`
- `pauseManualCount`
- `pauseScheduleCount`

이 값들은 iOS companion이나 장기 패턴 설명에 도움이 되지만, 1차 구현 범위를 키울 수 있으므로 optional로 둔다.

## 7.3 Deliberately Excluded

다음은 하루 backup에도 올리지 않는 편이 맞다.

- exact input event timeline
- raw mouse/keyboard timeline
- window title
- URL / browser domain
- typed text / terminal contents
- exact app switch sequence

이건 privacy boundary와 제품 포지셔닝을 지나치게 흔들 수 있다.

## 8. App-level Rollup Policy

사용자가 “오늘 어떤 앱에서 집중했는지”를 cross-device로 보고 싶을 수도 있다. 하지만 app-level 백업은 조심스럽게 다뤄야 한다.

### Recommended

1차 daily backup 본체에는 app-level 상세를 넣지 않는다.

이유:

- 통계 백업의 핵심은 daily rhythm과 recovery pattern
- app breakdown은 민감도와 용량이 더 높다
- 현재도 app usage는 로컬에서만 더 안전하게 해석 가능하다

필요 시 후속 옵션:

- `TopAppsDayProjection`
- top N app summary만 저장
- 앱 이름보다 `bundleIdentifier + totalDuration + transitionCount` 수준으로 제한

즉, app-level backup은 **별도 projection**으로 분리하는 편이 낫다.

## 9. How To Aggregate

## 9.1 Ownership

- Mac이 계산한다
- CloudKit은 운반/백업한다
- iOS는 표시한다

즉:

- aggregate 계산 책임은 **macOS app/service layer**
- iOS는 projection을 조합하지 않고 소비만 한다

## 9.2 Update Timing

권장 트리거:

- focus session 종료 시
- alert/recovery 이벤트 종료 시
- 자정 경계 진입 시 이전 day finalize
- 앱 종료/백그라운드 전 flush
- 앱 재실행 시 local truth 기준 재계산 가능 경로 유지

## 9.3 Upsert Rule

하루 aggregate record는 append-only가 아니라 **upsert/overwrite 가능한 projection**이어야 한다.

즉:

- 같은 `macDeviceID + localDayKey`에 대해
- 더 최신 계산 결과가 오면 record를 덮어쓴다

권장 필드:

- `updatedAt`
- `sequence` 또는 `projectionVersion` (optional)

## 10. Cross-midnight Session Rule

이 부분은 이미 기존 문서와 일치시켜야 한다.

권장 재사용 규칙:

- `completedSessionCount`: 세션 시작일 귀속
- `totalFocusDuration`: day overlap 기준으로 초 단위 분할
- `sessionsOver30mCount`: 세션 전체 duration 기준 판단, 시작일 귀속
- `alertCount`: 이벤트 발생 시각 기준 귀속
- `hourlyAlertCounts`: alert 발생 시각 기준 시간 bin 귀속

즉:

- **duration metric은 분할**
- **count metric은 명시 규칙으로 귀속**

이 원칙이 문서/코드/CloudKit schema에서 모두 같아야 한다.

## 11. Record Identity Recommendation

권장 identity:

- `recordType`: `DashboardDayProjection`
- `recordName`: `macDeviceID + localDayKey`

예:

- `mac-1234__2026-04-13@Asia/Seoul`

장점:

- overwrite/upsert 간단
- iOS 최근 7일 fetch도 단순
- 중복 생성 방지 쉬움

## 12. CloudKit Storage Contract

권장:

- database: `private database`
- zone: `NudgeWhipSync`

이유:

- per-user 개인 통계 데이터
- cross-device companion sync 목적
- shared/public analytics DB처럼 취급하면 안 됨

## 13. Suggested Initial Scope

가장 현실적인 1차 범위:

- local day 기준 `DashboardDayProjection`
- core daily metrics만 백업
- overwrite/upsert
- 최근 35~400일 범위 보관 정책은 후속 결정
- app-level top apps backup은 제외

즉, “하루 회고 복구 가능한 백업”까지 먼저 잠그고, 세부 analytics는 나중에 확장한다.

## 14. Open Questions

아직 결정이 필요한 것:

1. retention을 35일 / 180일 / 400일 중 어디로 둘지
2. `remoteEscalation*`를 1차에 넣을지
3. app-level summary backup을 완전히 제외할지, top N만 둘지
4. timezone 변경 후 historical projection을 절대 재작성하지 않을지

## 15. CloudKit Schema Draft v1

이 섹션은 실제 구현 시 바로 record type / field 이름을 만들 수 있도록 naming을 구체화한 초안이다.

### 15.1 Recommended Record Types

권장 record type:

- `DashboardDayProjection`
- 후속 optional:
  - `RemoteEscalationEvent`
  - `TopAppsDayProjection`

이번 문서의 1차 범위는 **`DashboardDayProjection` 단일 record**다.

### 15.2 `DashboardDayProjection` Identity

- `recordType`: `DashboardDayProjection`
- `recordName`: `"{macDeviceID}__{localDayKey}"`

예:

- `mac-1234__2026-04-13@Asia/Seoul`

규칙:

- `recordName`은 deterministic 해야 한다
- 같은 day projection은 append가 아니라 overwrite/upsert 대상이다
- `localDayKey`는 human-readable string을 유지한다

### 15.3 Required Fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `macDeviceID` | String | Yes | Mac 기기 식별자 |
| `localDayKey` | String | Yes | 예: `2026-04-13@Asia/Seoul` |
| `dayStart` | Date | Yes | local day start |
| `timeZoneIdentifier` | String | Yes | 예: `Asia/Seoul` |
| `updatedAt` | Date | Yes | projection 마지막 계산 시각 |
| `schemaVersion` | Int64 | Yes | projection schema version |
| `totalFocusDurationSeconds` | Int64 | Yes | 하루 총 집중 시간(초) |
| `completedSessionCount` | Int64 | Yes | 세션 시작일 귀속 기준 |
| `alertCount` | Int64 | Yes | alert 발생 시각 귀속 기준 |
| `longestFocusDurationSeconds` | Int64 | Yes | 하루 기준 최장 집중 세션 |
| `recoverySampleCount` | Int64 | Yes | recovery sample 수 |
| `recoveryDurationTotalSeconds` | Int64 | Yes | recovery 총합 |
| `recoveryDurationMaxSeconds` | Int64 | Yes | recovery 최댓값 |
| `sessionsOver30mCount` | Int64 | Yes | 세션 전체 duration 기준 |
| `hourlyAlertCounts` | String / Bytes | Yes | 24개 int 배열의 직렬화 표현 |

### 15.4 Optional Fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `sourceWindowUTCStart` | Date | No | aggregation source 시작 UTC |
| `sourceWindowUTCEnd` | Date | No | aggregation source 종료 UTC |
| `projectionVersion` | Int64 | No | overwrite/version 추적 |
| `remoteEscalationSentCount` | Int64 | No | 후속 단계 |
| `remoteEscalationRecoveredWithinWindowCount` | Int64 | No | 후속 단계 |
| `focusStartCount` | Int64 | No | 후속 단계 |
| `pauseManualCount` | Int64 | No | 후속 단계 |
| `pauseScheduleCount` | Int64 | No | 후속 단계 |

## 16. Field Naming Convention

권장 원칙:

- duration은 전부 `...Seconds`
- count는 전부 `...Count`
- bool은 `is...` / `was...`
- key/identifier는 의미를 직접 드러내는 이름 유지

권장 예:

- `totalFocusDurationSeconds`
- `recoveryDurationTotalSeconds`
- `completedSessionCount`
- `timeZoneIdentifier`

비권장 예:

- `focusDuration` (단위 불명확)
- `recoveryTotal` (의미 불명확)
- `tz` (축약 과함)

## 17. Array / Structured Field Encoding

CloudKit 필드는 복잡한 배열/중첩 구조를 다룰 때 구현 편차가 생길 수 있다. 1차 범위에서는 단순하고 forward-compatible 한 encoding을 권장한다.

### Recommended for `hourlyAlertCounts`

옵션:

1. `[Int]`를 그대로 저장
2. JSON string으로 저장
3. `Bytes`/asset-like blob으로 저장

### Recommendation

**1차는 JSON string 저장**을 권장한다.

예:

- field name: `hourlyAlertCountsJSON`
- value: `"[0,1,0,0,2,...]"` (항상 24칸)

이유:

- schema evolution이 단순하다
- CK field 타입 충돌 리스크가 낮다
- 디버깅이 쉽다

단, 만약 현재 코드베이스에서 `[Int]` 저장이 이미 일관되게 쓰이고 있고 CloudKit wrapper에서 안정적이면 직접 배열 저장도 가능하다. 이 경우에도 **항상 24칸 고정** 규칙은 유지해야 한다.

## 18. Example Record Draft

예시:

```json
{
  "recordType": "DashboardDayProjection",
  "recordName": "mac-1234__2026-04-13@Asia/Seoul",
  "fields": {
    "macDeviceID": "mac-1234",
    "localDayKey": "2026-04-13@Asia/Seoul",
    "dayStart": "2026-04-12T15:00:00Z",
    "timeZoneIdentifier": "Asia/Seoul",
    "updatedAt": "2026-04-13T14:58:31Z",
    "schemaVersion": 1,
    "totalFocusDurationSeconds": 14220,
    "completedSessionCount": 6,
    "alertCount": 5,
    "longestFocusDurationSeconds": 4080,
    "recoverySampleCount": 4,
    "recoveryDurationTotalSeconds": 510,
    "recoveryDurationMaxSeconds": 220,
    "sessionsOver30mCount": 3,
    "hourlyAlertCountsJSON": "[0,0,0,0,0,0,1,0,0,1,1,0,0,0,1,0,1,0,0,0,0,0,0,0]",
    "sourceWindowUTCStart": "2026-04-12T15:00:00Z",
    "sourceWindowUTCEnd": "2026-04-13T14:59:59Z"
  }
}
```

## 19. Versioning and Migration Rule

권장:

- `schemaVersion = 1`부터 시작
- 새 필드는 optional-first
- 기존 필드 rename은 최대한 피하고, 필요하면 새 필드 추가 후 reader fallback 유지

즉:

- additive schema 진화
- destructive rename/move는 지양

## 20. Implementation-ready Recommendation

실제 구현 1차는 아래 조합이 가장 안전하다.

- `DashboardDayProjection`
- `recordName = macDeviceID + "__" + localDayKey`
- duration/count 중심 core field
- `hourlyAlertCountsJSON`
- optional UTC source window
- overwrite/upsert

이렇게 하면:

- 로컬 일간 통계를 그대로 CloudKit backup/read model로 옮길 수 있고
- iOS/companion에서도 동일 projection을 바로 소비할 수 있다.

## 21. Recommended Decision Summary

### Final Recommendation

- **하루 기준은 local day**
- **키는 `macDeviceID + localDayKey`**
- **CloudKit에는 raw가 아니라 daily aggregate projection만 저장**
- **UTC는 보조 추적 필드로만 남긴다**
- **app-level backup은 1차 범위에서 제외**

## 22. Bottom Line

- 이 제품에서 하루 통계 백업의 기준은 서버 편의보다 **사용자가 경험한 하루**에 맞아야 한다.
- 따라서 UTC-only보다 `local day + timezone identifier + optional UTC window` 조합이 가장 적절하다.
- 첫 구현은 `로컬 raw/session → 하루 projection → CloudKit private DB upsert backup` 구조로 가는 것이 가장 안전하다.
