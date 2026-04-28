import Foundation
import SwiftData

@Model
final class CachedDayProjection {
    var macDeviceID: String
    var localDayKey: String
    var dayStart: Date
    var timeZoneIdentifier: String
    var updatedAt: Date
    var schemaVersion: Int64
    var totalFocusDurationSeconds: Int64
    var completedSessionCount: Int64
    var alertCount: Int64
    var longestFocusDurationSeconds: Int64
    var recoverySampleCount: Int64
    var recoveryDurationTotalSeconds: Int64
    var recoveryDurationMaxSeconds: Int64
    var sessionsOver30mCount: Int64
    var hourlyAlertCountsData: Data
    var fetchedAt: Date

    init(
        macDeviceID: String,
        localDayKey: String,
        dayStart: Date,
        timeZoneIdentifier: String,
        updatedAt: Date,
        schemaVersion: Int64,
        totalFocusDurationSeconds: Int64,
        completedSessionCount: Int64,
        alertCount: Int64,
        longestFocusDurationSeconds: Int64,
        recoverySampleCount: Int64,
        recoveryDurationTotalSeconds: Int64,
        recoveryDurationMaxSeconds: Int64,
        sessionsOver30mCount: Int64,
        hourlyAlertCountsData: Data,
        fetchedAt: Date = Date()
    ) {
        self.macDeviceID = macDeviceID
        self.localDayKey = localDayKey
        self.dayStart = dayStart
        self.timeZoneIdentifier = timeZoneIdentifier
        self.updatedAt = updatedAt
        self.schemaVersion = schemaVersion
        self.totalFocusDurationSeconds = totalFocusDurationSeconds
        self.completedSessionCount = completedSessionCount
        self.alertCount = alertCount
        self.longestFocusDurationSeconds = longestFocusDurationSeconds
        self.recoverySampleCount = recoverySampleCount
        self.recoveryDurationTotalSeconds = recoveryDurationTotalSeconds
        self.recoveryDurationMaxSeconds = recoveryDurationMaxSeconds
        self.sessionsOver30mCount = sessionsOver30mCount
        self.hourlyAlertCountsData = hourlyAlertCountsData
        self.fetchedAt = fetchedAt
    }

    var hourlyAlertCounts: [Int] {
        guard let decoded = try? JSONDecoder().decode([Int].self, from: hourlyAlertCountsData) else {
            return Array(repeating: 0, count: 24)
        }
        return decoded
    }

    convenience init(from payload: DashboardDayProjectionPayload, fetchedAt: Date = Date()) {
        let hourlyData = (try? JSONEncoder().encode(payload.hourlyAlertCounts)) ?? Data("[]".utf8)
        self.init(
            macDeviceID: payload.macDeviceID,
            localDayKey: payload.localDayKey,
            dayStart: payload.dayStart,
            timeZoneIdentifier: payload.timeZoneIdentifier,
            updatedAt: payload.updatedAt,
            schemaVersion: payload.schemaVersion,
            totalFocusDurationSeconds: payload.totalFocusDurationSeconds,
            completedSessionCount: payload.completedSessionCount,
            alertCount: payload.alertCount,
            longestFocusDurationSeconds: payload.longestFocusDurationSeconds,
            recoverySampleCount: payload.recoverySampleCount,
            recoveryDurationTotalSeconds: payload.recoveryDurationTotalSeconds,
            recoveryDurationMaxSeconds: payload.recoveryDurationMaxSeconds,
            sessionsOver30mCount: payload.sessionsOver30mCount,
            hourlyAlertCountsData: hourlyData,
            fetchedAt: fetchedAt
        )
    }
}
