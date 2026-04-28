import CloudKit
import Foundation

enum CloudKitSubscriptionRegistrarError: Error, Equatable {
    case notConfigured
}

@MainActor
final class CloudKitSubscriptionRegistrar {
    static let zoneName = "NudgeWhipSync"
    static let macStateSubscriptionID = "macstate-changes"
    static let zoneSubscriptionID = "zone-changes"

    private let database: CKDatabase?
    private let zoneID: CKRecordZone.ID
    private var hasRegistered = false

    init(
        database: CKDatabase? = nil,
        zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "NudgeWhipSync", ownerName: CKCurrentUserDefaultName)
    ) {
        self.database = database
        self.zoneID = zoneID
    }

    /// Ensure the custom zone exists before registering subscriptions.
    func ensureZoneExists() async throws {
        guard let database else { throw CloudKitSubscriptionRegistrarError.notConfigured }
        let zone = CKRecordZone(zoneID: zoneID)
        _ = try await database.save(zone)
    }

    /// Register all required subscriptions (idempotent).
    func registerAll() async throws {
        guard let database else { throw CloudKitSubscriptionRegistrarError.notConfigured }
        guard !hasRegistered else { return }

        var subscriptions: [CKSubscription] = []

        // 1. CKQuerySubscription for MacState record changes
        let querySubscription = CKQuerySubscription(
            recordType: "MacState",
            predicate: NSPredicate(value: true),
            subscriptionID: CKSubscription.ID(stringLiteral: Self.macStateSubscriptionID),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate]
        )
        let queryNotificationInfo = CKSubscription.NotificationInfo()
        queryNotificationInfo.shouldSendContentAvailable = true
        querySubscription.notificationInfo = queryNotificationInfo
        subscriptions.append(querySubscription)

        // 2. CKDatabaseSubscription for zone-level changes
        let dbSubscription = CKDatabaseSubscription(subscriptionID: CKSubscription.ID(stringLiteral: Self.zoneSubscriptionID))
        let dbNotificationInfo = CKSubscription.NotificationInfo()
        dbNotificationInfo.shouldSendContentAvailable = true
        dbSubscription.notificationInfo = dbNotificationInfo
        subscriptions.append(dbSubscription)

        _ = try await database.modifySubscriptions(saving: subscriptions, deleting: [])

        hasRegistered = true
    }

    func resetRegistrationState() {
        hasRegistered = false
    }
}
