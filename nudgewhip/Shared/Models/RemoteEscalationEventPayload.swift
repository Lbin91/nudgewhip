import Foundation

struct RemoteEscalationEventPayload: Equatable, Sendable, Codable {
    let macDeviceID: String
    let occurredAt: Date
    let escalationStep: Int
    let contentStateRawValue: String
    let wasRecoveredWithinWindow: Bool?
    let recoveredAt: Date?
    let schemaVersion: Int

    init(
        macDeviceID: String,
        occurredAt: Date,
        escalationStep: Int,
        contentStateRawValue: String,
        wasRecoveredWithinWindow: Bool? = nil,
        recoveredAt: Date? = nil,
        schemaVersion: Int = 1
    ) {
        self.macDeviceID = macDeviceID
        self.occurredAt = occurredAt
        self.escalationStep = escalationStep
        self.contentStateRawValue = contentStateRawValue
        self.wasRecoveredWithinWindow = wasRecoveredWithinWindow
        self.recoveredAt = recoveredAt
        self.schemaVersion = schemaVersion
    }
}
