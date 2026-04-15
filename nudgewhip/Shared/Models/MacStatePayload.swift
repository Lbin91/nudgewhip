import Foundation

struct MacStatePayload: Equatable, Sendable, Codable {
    let macDeviceID: String
    let state: String
    let stateChangedAt: Date
    let sequence: Int64
    let breakUntil: Date?
    let lastAlertAt: Date?
    let schemaVersion: Int64

    init(
        macDeviceID: String,
        state: String,
        stateChangedAt: Date,
        sequence: Int64,
        breakUntil: Date? = nil,
        lastAlertAt: Date? = nil,
        schemaVersion: Int64 = 1
    ) {
        self.macDeviceID = macDeviceID
        self.state = state
        self.stateChangedAt = stateChangedAt
        self.sequence = sequence
        self.breakUntil = breakUntil
        self.lastAlertAt = lastAlertAt
        self.schemaVersion = schemaVersion
    }
}
