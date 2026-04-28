import Foundation
import SwiftData

@Model
final class CachedMacState {
    var macDeviceID: String
    var state: String
    var stateChangedAt: Date
    var sequence: Int64
    var breakUntil: Date?
    var lastAlertAt: Date?
    var schemaVersion: Int64
    var fetchedAt: Date

    init(
        macDeviceID: String,
        state: String,
        stateChangedAt: Date,
        sequence: Int64,
        breakUntil: Date? = nil,
        lastAlertAt: Date? = nil,
        schemaVersion: Int64 = 1,
        fetchedAt: Date = Date()
    ) {
        self.macDeviceID = macDeviceID
        self.state = state
        self.stateChangedAt = stateChangedAt
        self.sequence = sequence
        self.breakUntil = breakUntil
        self.lastAlertAt = lastAlertAt
        self.schemaVersion = schemaVersion
        self.fetchedAt = fetchedAt
    }
}
