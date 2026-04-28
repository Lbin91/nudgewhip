import Foundation
import SwiftData

enum iOSModelContainer {
    static let shared: ModelContainer = {
        do {
            return try makeModelContainer(inMemory: false)
        } catch {
            fatalError("Failed to create iOS model container: \(error)")
        }
    }()

    @MainActor
    static let preview: ModelContainer = {
        do {
            let container = try makeModelContainer(inMemory: true)
            let context = container.mainContext
            let now = Date()

            let macState = CachedMacState(
                macDeviceID: "preview-mac",
                state: "monitoring",
                stateChangedAt: now,
                sequence: 1
            )
            context.insert(macState)

            let projection = CachedDayProjection(
                macDeviceID: "preview-mac",
                localDayKey: "2026-04-28@Asia/Seoul",
                dayStart: now,
                timeZoneIdentifier: "Asia/Seoul",
                updatedAt: now,
                schemaVersion: 1,
                totalFocusDurationSeconds: 14400,
                completedSessionCount: 4,
                alertCount: 2,
                longestFocusDurationSeconds: 7200,
                recoverySampleCount: 3,
                recoveryDurationTotalSeconds: 180,
                recoveryDurationMaxSeconds: 90,
                sessionsOver30mCount: 2,
                hourlyAlertCountsData: (try? JSONEncoder().encode(Array(repeating: 0, count: 24))) ?? Data()
            )
            context.insert(projection)

            let escalation = CachedRemoteEscalation(
                macDeviceID: "preview-mac",
                occurredAt: now.addingTimeInterval(-3600),
                escalationStep: 1,
                contentStateRawValue: "gentle_nudge"
            )
            context.insert(escalation)

            try context.save()
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()

    static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            CachedMacState.self,
            CachedDayProjection.self,
            CachedRemoteEscalation.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
