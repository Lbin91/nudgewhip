import CloudKit
import Foundation

enum MacStateCloudKitWriterError: Error, Equatable {
    case notConfigured
}

@MainActor
final class MacStateCloudKitWriter {
    static let recordType = "MacState"
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

    func record(for payload: MacStatePayload) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: payload.macDeviceID,
            zoneID: zoneID
        )
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["macDeviceID"] = payload.macDeviceID as CKRecordValue
        record["state"] = payload.state as CKRecordValue
        record["stateChangedAt"] = payload.stateChangedAt as CKRecordValue
        record["sequence"] = payload.sequence as CKRecordValue
        record["schemaVersion"] = payload.schemaVersion as CKRecordValue
        if let breakUntil = payload.breakUntil {
            record["breakUntil"] = breakUntil as CKRecordValue
        }
        if let lastAlertAt = payload.lastAlertAt {
            record["lastAlertAt"] = lastAlertAt as CKRecordValue
        }
        return record
    }

    func save(_ payload: MacStatePayload) async throws {
        try await ensureZoneExistsIfNeeded()
        try await save(record: record(for: payload))
    }

    private func ensureZoneExistsIfNeeded() async throws {
        guard let database else {
            throw MacStateCloudKitWriterError.notConfigured
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
            throw MacStateCloudKitWriterError.notConfigured
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
