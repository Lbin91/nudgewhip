import CloudKit
import Foundation
import SwiftData

@MainActor
final class CloudKitCacheSyncService {
    static let zoneName = "NudgeWhipSync"

    private let container: CKContainer?
    private let database: CKDatabase?
    private let zoneID: CKRecordZone.ID
    private let modelContext: ModelContext
    private let projectionConsumer: CloudKitDailyAggregateFetchConsumer

    init(
        container: CKContainer? = nil,
        modelContext: ModelContext,
        zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "NudgeWhipSync", ownerName: CKCurrentUserDefaultName)
    ) {
        let resolvedContainer = container ?? CloudKitConfiguration.makeContainer()
        self.container = resolvedContainer
        self.database = resolvedContainer?.privateCloudDatabase
        self.zoneID = zoneID
        self.modelContext = modelContext
        self.projectionConsumer = CloudKitDailyAggregateFetchConsumer(
            container: resolvedContainer,
            zoneID: zoneID
        )
    }

    static func makeForTesting(modelContext: ModelContext) -> CloudKitCacheSyncService {
        CloudKitCacheSyncService(
            container: CKContainer(identifier: "iCloud.dummy.testing"),
            modelContext: modelContext
        )
    }

    func syncAll(macDeviceID: String) async throws {
        try await syncMacState(macDeviceID: macDeviceID)
        try await syncRecentProjections(macDeviceID: macDeviceID)
        try await syncRecentEscalations(macDeviceID: macDeviceID)
        try trimExpiredCache()
    }

    // MARK: - MacState Sync

    func syncMacState(macDeviceID: String) async throws {
        guard database != nil else { return }

        let query = CKQuery(
            recordType: "MacState",
            predicate: NSPredicate(format: "macDeviceID == %@", macDeviceID)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: false)]

        let records = try await performQuery(query, limit: 1)
        guard let record = records.first else { return }

        let payload = try macStatePayload(from: record)
        upsertMacState(payload)
        try modelContext.save()
    }

    // MARK: - Projection Sync

    func syncRecentProjections(macDeviceID: String, days: Int = 7) async throws {
        guard database != nil else { return }
        let payloads = try await projectionConsumer.fetchRecentProjections(
            macDeviceID: macDeviceID,
            limit: days
        )
        for payload in payloads {
            upsertProjection(payload)
        }
        try modelContext.save()
    }

    // MARK: - Escalation Sync

    func syncRecentEscalations(macDeviceID: String, days: Int = 30) async throws {
        guard database != nil else { return }

        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let query = CKQuery(
            recordType: "RemoteEscalationEvent",
            predicate: NSPredicate(format: "macDeviceID == %@ AND occurredAt > %@", macDeviceID, cutoff as NSDate)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "occurredAt", ascending: false)]

        let records = try await performQuery(query, limit: 100)
        for record in records {
            if let payload = try? escalationPayload(from: record) {
                upsertEscalation(payload)
            }
        }
        try modelContext.save()
    }

    // MARK: - Retention Trimming

    func trimExpiredCache() throws {
        let now = Date()

        let projectionCutoff = Calendar.current.date(byAdding: .day, value: -35, to: now) ?? now
        let projectionDescriptor = FetchDescriptor<CachedDayProjection>(
            predicate: #Predicate { $0.dayStart < projectionCutoff }
        )
        let expiredProjections = try modelContext.fetch(projectionDescriptor)
        for projection in expiredProjections {
            modelContext.delete(projection)
        }

        let escalationCutoff = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let escalationDescriptor = FetchDescriptor<CachedRemoteEscalation>(
            predicate: #Predicate { $0.occurredAt < escalationCutoff }
        )
        let expiredEscalations = try modelContext.fetch(escalationDescriptor)
        for escalation in expiredEscalations {
            modelContext.delete(escalation)
        }

        try modelContext.save()
    }

    // MARK: - Upsert

    func performUpsertMacState(_ payload: MacStatePayload) {
        upsertMacState(payload)
    }

    func performUpsertProjection(_ payload: DashboardDayProjectionPayload) {
        upsertProjection(payload)
    }

    func performUpsertEscalation(_ payload: RemoteEscalationEventPayload) {
        upsertEscalation(payload)
    }

    func testMacStatePayload(from record: CKRecord) throws -> MacStatePayload {
        try macStatePayload(from: record)
    }

    private func upsertMacState(_ payload: MacStatePayload) {
        let descriptor = FetchDescriptor<CachedMacState>(
            predicate: #Predicate { $0.macDeviceID == payload.macDeviceID }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.state = payload.state
            existing.stateChangedAt = payload.stateChangedAt
            existing.sequence = payload.sequence
            existing.breakUntil = payload.breakUntil
            existing.lastAlertAt = payload.lastAlertAt
            existing.schemaVersion = payload.schemaVersion
            existing.fetchedAt = Date()
            return
        }
        let cached = CachedMacState(
            macDeviceID: payload.macDeviceID,
            state: payload.state,
            stateChangedAt: payload.stateChangedAt,
            sequence: payload.sequence,
            breakUntil: payload.breakUntil,
            lastAlertAt: payload.lastAlertAt,
            schemaVersion: payload.schemaVersion
        )
        modelContext.insert(cached)
    }

    private func upsertProjection(_ payload: DashboardDayProjectionPayload) {
        let descriptor = FetchDescriptor<CachedDayProjection>(
            predicate: #Predicate {
                $0.macDeviceID == payload.macDeviceID && $0.localDayKey == payload.localDayKey
            }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.macDeviceID = payload.macDeviceID
            existing.dayStart = payload.dayStart
            existing.timeZoneIdentifier = payload.timeZoneIdentifier
            existing.updatedAt = payload.updatedAt
            existing.schemaVersion = payload.schemaVersion
            existing.totalFocusDurationSeconds = payload.totalFocusDurationSeconds
            existing.completedSessionCount = payload.completedSessionCount
            existing.alertCount = payload.alertCount
            existing.longestFocusDurationSeconds = payload.longestFocusDurationSeconds
            existing.recoverySampleCount = payload.recoverySampleCount
            existing.recoveryDurationTotalSeconds = payload.recoveryDurationTotalSeconds
            existing.recoveryDurationMaxSeconds = payload.recoveryDurationMaxSeconds
            existing.sessionsOver30mCount = payload.sessionsOver30mCount
            existing.hourlyAlertCountsData = (try? JSONEncoder().encode(payload.hourlyAlertCounts)) ?? Data()
            existing.fetchedAt = Date()
            return
        }
        let cached = CachedDayProjection(from: payload)
        modelContext.insert(cached)
    }

    private func upsertEscalation(_ payload: RemoteEscalationEventPayload) {
        let descriptor = FetchDescriptor<CachedRemoteEscalation>(
            predicate: #Predicate {
                $0.macDeviceID == payload.macDeviceID && $0.occurredAt == payload.occurredAt
            }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.wasRecoveredWithinWindow = payload.wasRecoveredWithinWindow
            existing.recoveredAt = payload.recoveredAt
            existing.fetchedAt = Date()
            return
        }
        let cached = CachedRemoteEscalation(from: payload)
        modelContext.insert(cached)
    }

    // MARK: - Device Discovery

    func discoverMacDeviceID() async throws -> String? {
        guard database != nil else { return nil }
        let query = CKQuery(
            recordType: "MacState",
            predicate: NSPredicate(value: true)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "sequence", ascending: false)]
        let records = try await performQuery(query, limit: 1)
        return records.first?["macDeviceID"] as? String
    }

    // MARK: - CloudKit Fetch

    private func performQuery(_ query: CKQuery, limit: Int) async throws -> [CKRecord] {
        guard let database else { return [] }
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
            var results: [CKRecord] = []
            let operation = CKQueryOperation(query: query)
            operation.zoneID = zoneID
            operation.resultsLimit = limit
            operation.recordMatchedBlock = { _, result in
                if case let .success(record) = result {
                    results.append(record)
                }
            }
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: results)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
            database.add(operation)
        }
    }

    // MARK: - Record → Payload

    private func macStatePayload(from record: CKRecord) throws -> MacStatePayload {
        guard let macDeviceID = record["macDeviceID"] as? String,
              let state = record["state"] as? String,
              let stateChangedAt = record["stateChangedAt"] as? Date
        else {
            throw CloudKitCacheSyncServiceError.invalidRecord
        }
        return MacStatePayload(
            macDeviceID: macDeviceID,
            state: state,
            stateChangedAt: stateChangedAt,
            sequence: (record["sequence"] as? NSNumber)?.int64Value ?? 0,
            breakUntil: record["breakUntil"] as? Date,
            lastAlertAt: record["lastAlertAt"] as? Date,
            schemaVersion: (record["schemaVersion"] as? NSNumber)?.int64Value ?? 1
        )
    }

    private func escalationPayload(from record: CKRecord) throws -> RemoteEscalationEventPayload {
        guard let macDeviceID = record["macDeviceID"] as? String,
              let occurredAt = record["occurredAt"] as? Date,
              let escalationStep = record["escalationStep"] as? Int,
              let contentStateRawValue = record["contentStateRawValue"] as? String
        else {
            throw CloudKitCacheSyncServiceError.invalidRecord
        }
        return RemoteEscalationEventPayload(
            macDeviceID: macDeviceID,
            occurredAt: occurredAt,
            escalationStep: escalationStep,
            contentStateRawValue: contentStateRawValue,
            wasRecoveredWithinWindow: record["wasRecoveredWithinWindow"] as? Bool,
            recoveredAt: record["recoveredAt"] as? Date,
            schemaVersion: (record["schemaVersion"] as? NSNumber)?.intValue ?? 1
        )
    }
}

enum CloudKitCacheSyncServiceError: Error, Equatable {
    case invalidRecord
}
