import CloudKit
import Foundation

enum CloudKitDailyAggregateBackupWriterError: Error, Equatable {
    case notConfigured
}

@MainActor
final class CloudKitDailyAggregateBackupWriter {
    static let recordType = "DashboardDayProjection"
    static let zoneName = "NudgeWhipSync"

    private let database: CKDatabase?
    private let zoneID: CKRecordZone.ID
    private var hasEnsuredZone = false

    init(
        container: CKContainer? = nil,
        database: CKDatabase? = nil,
        zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "NudgeWhipSync", ownerName: CKCurrentUserDefaultName)
    ) {
        self.database = database ?? container?.privateCloudDatabase
        self.zoneID = zoneID
    }

    func record(for payload: DashboardDayProjectionPayload) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(payload.macDeviceID)__\(payload.localDayKey)",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["macDeviceID"] = payload.macDeviceID as CKRecordValue
        record["localDayKey"] = payload.localDayKey as CKRecordValue
        record["dayStart"] = payload.dayStart as CKRecordValue
        record["timeZoneIdentifier"] = payload.timeZoneIdentifier as CKRecordValue
        record["updatedAt"] = payload.updatedAt as CKRecordValue
        record["schemaVersion"] = payload.schemaVersion as CKRecordValue
        record["totalFocusDurationSeconds"] = payload.totalFocusDurationSeconds as CKRecordValue
        record["completedSessionCount"] = payload.completedSessionCount as CKRecordValue
        record["alertCount"] = payload.alertCount as CKRecordValue
        record["longestFocusDurationSeconds"] = payload.longestFocusDurationSeconds as CKRecordValue
        record["recoverySampleCount"] = payload.recoverySampleCount as CKRecordValue
        record["recoveryDurationTotalSeconds"] = payload.recoveryDurationTotalSeconds as CKRecordValue
        record["recoveryDurationMaxSeconds"] = payload.recoveryDurationMaxSeconds as CKRecordValue
        record["sessionsOver30mCount"] = payload.sessionsOver30mCount as CKRecordValue
        record["hourlyAlertCountsJSON"] = Self.hourlyAlertCountsJSONString(from: payload.hourlyAlertCounts) as CKRecordValue
        if let sourceWindowUTCStart = payload.sourceWindowUTCStart {
            record["sourceWindowUTCStart"] = sourceWindowUTCStart as CKRecordValue
        }
        if let sourceWindowUTCEnd = payload.sourceWindowUTCEnd {
            record["sourceWindowUTCEnd"] = sourceWindowUTCEnd as CKRecordValue
        }
        return record
    }

    func save(_ payload: DashboardDayProjectionPayload) async throws {
        try await ensureZoneExistsIfNeeded()
        try await save(record: record(for: payload))
    }

    static func hourlyAlertCountsJSONString(from hourlyAlertCounts: [Int]) -> String {
        let data = (try? JSONEncoder().encode(hourlyAlertCounts)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func ensureZoneExistsIfNeeded() async throws {
        guard let database else {
            throw CloudKitDailyAggregateBackupWriterError.notConfigured
        }
        guard !hasEnsuredZone else { return }

        let zone = CKRecordZone(zoneID: zoneID)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
            operation.modifyRecordZonesCompletionBlock = { _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
            database.add(operation)
        }

        hasEnsuredZone = true
    }

    private func save(record: CKRecord) async throws {
        guard let database else {
            throw CloudKitDailyAggregateBackupWriterError.notConfigured
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.save(record) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
