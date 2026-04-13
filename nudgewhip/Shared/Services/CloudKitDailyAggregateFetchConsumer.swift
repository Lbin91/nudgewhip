import CloudKit
import Foundation

enum CloudKitDailyAggregateFetchConsumerError: Error, Equatable {
    case missingField(String)
    case invalidField(String)
    case invalidHourlyAlertCountsJSON
}

typealias DashboardDayProjectionQueryLoader = @MainActor @Sendable (_ query: CKQuery, _ zoneID: CKRecordZone.ID, _ limit: Int) async throws -> [CKRecord]
typealias DashboardDayProjectionRecordLoader = @MainActor @Sendable (_ recordID: CKRecord.ID) async throws -> CKRecord?

@MainActor
final class CloudKitDailyAggregateFetchConsumer {
    private let database: CKDatabase
    private let zoneID: CKRecordZone.ID
    private let queryLoader: DashboardDayProjectionQueryLoader
    private let recordLoader: DashboardDayProjectionRecordLoader

    init(
        container: CKContainer = .default(),
        database: CKDatabase? = nil,
        zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "NudgeWhipSync", ownerName: CKCurrentUserDefaultName),
        queryLoader: DashboardDayProjectionQueryLoader? = nil,
        recordLoader: DashboardDayProjectionRecordLoader? = nil
    ) {
        let resolvedDatabase = database ?? container.privateCloudDatabase
        self.database = resolvedDatabase
        self.zoneID = zoneID
        self.queryLoader = queryLoader ?? { query, zoneID, limit in
            try await CloudKitDailyAggregateFetchConsumer.defaultQueryLoader(
                database: resolvedDatabase,
                query: query,
                zoneID: zoneID,
                limit: limit
            )
        }
        self.recordLoader = recordLoader ?? { recordID in
            try await CloudKitDailyAggregateFetchConsumer.defaultRecordLoader(
                database: resolvedDatabase,
                recordID: recordID
            )
        }
    }

    func payload(from record: CKRecord) throws -> DashboardDayProjectionPayload {
        let macDeviceID = try requiredString("macDeviceID", from: record)
        let localDayKey = try requiredString("localDayKey", from: record)
        let dayStart = try requiredDate("dayStart", from: record)
        let timeZoneIdentifier = try requiredString("timeZoneIdentifier", from: record)
        let updatedAt = try requiredDate("updatedAt", from: record)
        let schemaVersion = try requiredInt64("schemaVersion", from: record)
        let totalFocusDurationSeconds = try requiredInt64("totalFocusDurationSeconds", from: record)
        let completedSessionCount = try requiredInt64("completedSessionCount", from: record)
        let alertCount = try requiredInt64("alertCount", from: record)
        let longestFocusDurationSeconds = try requiredInt64("longestFocusDurationSeconds", from: record)
        let recoverySampleCount = try requiredInt64("recoverySampleCount", from: record)
        let recoveryDurationTotalSeconds = try requiredInt64("recoveryDurationTotalSeconds", from: record)
        let recoveryDurationMaxSeconds = try requiredInt64("recoveryDurationMaxSeconds", from: record)
        let sessionsOver30mCount = try requiredInt64("sessionsOver30mCount", from: record)
        let hourlyAlertCountsJSON = try requiredString("hourlyAlertCountsJSON", from: record)
        let hourlyAlertCounts = try decodeHourlyAlertCounts(from: hourlyAlertCountsJSON)

        return DashboardDayProjectionPayload(
            macDeviceID: macDeviceID,
            localDayKey: localDayKey,
            dayStart: dayStart,
            timeZoneIdentifier: timeZoneIdentifier,
            updatedAt: updatedAt,
            schemaVersion: schemaVersion,
            totalFocusDurationSeconds: totalFocusDurationSeconds,
            completedSessionCount: completedSessionCount,
            alertCount: alertCount,
            longestFocusDurationSeconds: longestFocusDurationSeconds,
            recoverySampleCount: recoverySampleCount,
            recoveryDurationTotalSeconds: recoveryDurationTotalSeconds,
            recoveryDurationMaxSeconds: recoveryDurationMaxSeconds,
            sessionsOver30mCount: sessionsOver30mCount,
            hourlyAlertCounts: hourlyAlertCounts,
            sourceWindowUTCStart: record["sourceWindowUTCStart"] as? Date,
            sourceWindowUTCEnd: record["sourceWindowUTCEnd"] as? Date
        )
    }

    func fetchRecentProjections(macDeviceID: String, limit: Int = 7) async throws -> [DashboardDayProjectionPayload] {
        let query = CKQuery(
            recordType: CloudKitDailyAggregateBackupWriter.recordType,
            predicate: NSPredicate(format: "macDeviceID == %@", macDeviceID)
        )
        query.sortDescriptors = [NSSortDescriptor(key: "dayStart", ascending: false)]
        let records = try await queryLoader(query, zoneID, limit)
        return try records.map(payload(from:))
    }

    func fetchProjection(macDeviceID: String, localDayKey: String) async throws -> DashboardDayProjectionPayload? {
        let recordID = CKRecord.ID(recordName: "\(macDeviceID)__\(localDayKey)", zoneID: zoneID)
        guard let record = try await recordLoader(recordID) else { return nil }
        return try payload(from: record)
    }

    private func requiredString(_ key: String, from record: CKRecord) throws -> String {
        guard let value = record[key] else {
            throw CloudKitDailyAggregateFetchConsumerError.missingField(key)
        }
        guard let string = value as? String else {
            throw CloudKitDailyAggregateFetchConsumerError.invalidField(key)
        }
        return string
    }

    private func requiredDate(_ key: String, from record: CKRecord) throws -> Date {
        guard let value = record[key] else {
            throw CloudKitDailyAggregateFetchConsumerError.missingField(key)
        }
        guard let date = value as? Date else {
            throw CloudKitDailyAggregateFetchConsumerError.invalidField(key)
        }
        return date
    }

    private func requiredInt64(_ key: String, from record: CKRecord) throws -> Int64 {
        guard let value = record[key] else {
            throw CloudKitDailyAggregateFetchConsumerError.missingField(key)
        }
        if let int64 = value as? Int64 {
            return int64
        }
        if let intValue = value as? Int {
            return Int64(intValue)
        }
        if let number = value as? NSNumber {
            return number.int64Value
        }
        throw CloudKitDailyAggregateFetchConsumerError.invalidField(key)
    }

    private func decodeHourlyAlertCounts(from json: String) throws -> [Int] {
        guard let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([Int].self, from: data),
              decoded.count == 24 else {
            throw CloudKitDailyAggregateFetchConsumerError.invalidHourlyAlertCountsJSON
        }
        return decoded
    }

    private static func defaultQueryLoader(
        database: CKDatabase,
        query: CKQuery,
        zoneID: CKRecordZone.ID,
        limit: Int
    ) async throws -> [CKRecord] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[CKRecord], Error>) in
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

    private static func defaultRecordLoader(database: CKDatabase, recordID: CKRecord.ID) async throws -> CKRecord? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CKRecord?, Error>) in
            database.fetch(withRecordID: recordID) { record, error in
                if let error {
                    if let ckError = error as? CKError, ckError.code == .unknownItem {
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(returning: record)
                }
            }
        }
    }
}
