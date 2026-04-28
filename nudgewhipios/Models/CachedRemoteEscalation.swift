import Foundation
import SwiftData

@Model
final class CachedRemoteEscalation {
    var macDeviceID: String
    var occurredAt: Date
    var escalationStep: Int
    var contentStateRawValue: String
    var wasRecoveredWithinWindow: Bool?
    var recoveredAt: Date?
    var schemaVersion: Int
    var fetchedAt: Date

    init(
        macDeviceID: String,
        occurredAt: Date,
        escalationStep: Int,
        contentStateRawValue: String,
        wasRecoveredWithinWindow: Bool? = nil,
        recoveredAt: Date? = nil,
        schemaVersion: Int = 1,
        fetchedAt: Date = Date()
    ) {
        self.macDeviceID = macDeviceID
        self.occurredAt = occurredAt
        self.escalationStep = escalationStep
        self.contentStateRawValue = contentStateRawValue
        self.wasRecoveredWithinWindow = wasRecoveredWithinWindow
        self.recoveredAt = recoveredAt
        self.schemaVersion = schemaVersion
        self.fetchedAt = fetchedAt
    }

    convenience init(from payload: RemoteEscalationEventPayload, fetchedAt: Date = Date()) {
        self.init(
            macDeviceID: payload.macDeviceID,
            occurredAt: payload.occurredAt,
            escalationStep: payload.escalationStep,
            contentStateRawValue: payload.contentStateRawValue,
            wasRecoveredWithinWindow: payload.wasRecoveredWithinWindow,
            recoveredAt: payload.recoveredAt,
            schemaVersion: payload.schemaVersion,
            fetchedAt: fetchedAt
        )
    }
}
