import CloudKit
import Foundation

enum RemoteEscalationEventWriterError: Error, Equatable {
    case notConfigured
}

@MainActor
final class RemoteEscalationEventWriter {
    static let recordType = "RemoteEscalationEvent"
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

    func record(for payload: RemoteEscalationEventPayload) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: "\(payload.macDeviceID)__\(Int(payload.occurredAt.timeIntervalSince1970))",
            zoneID: zoneID
        )
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["macDeviceID"] = payload.macDeviceID as CKRecordValue
        record["occurredAt"] = payload.occurredAt as CKRecordValue
        record["escalationStep"] = payload.escalationStep as CKRecordValue
        record["contentStateRawValue"] = payload.contentStateRawValue as CKRecordValue
        record["schemaVersion"] = payload.schemaVersion as CKRecordValue
        if let wasRecoveredWithinWindow = payload.wasRecoveredWithinWindow {
            record["wasRecoveredWithinWindow"] = wasRecoveredWithinWindow as CKRecordValue
        }
        if let recoveredAt = payload.recoveredAt {
            record["recoveredAt"] = recoveredAt as CKRecordValue
        }
        return record
    }

    func save(_ payload: RemoteEscalationEventPayload) async throws {
        try await ensureZoneExistsIfNeeded()
        try await save(record: record(for: payload))
    }

    private func ensureZoneExistsIfNeeded() async throws {
        guard let database else {
            throw RemoteEscalationEventWriterError.notConfigured
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
            throw RemoteEscalationEventWriterError.notConfigured
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
