import Foundation

struct DashboardDayProjectionPayload: Equatable, Sendable, Codable {
    let macDeviceID: String
    let localDayKey: String
    let dayStart: Date
    let timeZoneIdentifier: String
    let updatedAt: Date
    let schemaVersion: Int64
    let totalFocusDurationSeconds: Int64
    let completedSessionCount: Int64
    let alertCount: Int64
    let longestFocusDurationSeconds: Int64
    let recoverySampleCount: Int64
    let recoveryDurationTotalSeconds: Int64
    let recoveryDurationMaxSeconds: Int64
    let sessionsOver30mCount: Int64
    let hourlyAlertCounts: [Int]
    let sourceWindowUTCStart: Date?
    let sourceWindowUTCEnd: Date?

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
        hourlyAlertCounts: [Int],
        sourceWindowUTCStart: Date?,
        sourceWindowUTCEnd: Date?
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
        self.hourlyAlertCounts = hourlyAlertCounts
        self.sourceWindowUTCStart = sourceWindowUTCStart
        self.sourceWindowUTCEnd = sourceWindowUTCEnd
    }
}
