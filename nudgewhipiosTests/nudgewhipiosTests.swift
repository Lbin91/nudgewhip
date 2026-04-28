import CloudKit
import Foundation
import SwiftData
import Testing
@testable import nudgewhipios

@MainActor
struct iOSModelContainerTests {

    @Test
    func makeContainerRegistersAllModels() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let macState = CachedMacState(
            macDeviceID: "test-mac",
            state: "monitoring",
            stateChangedAt: Date(),
            sequence: 1
        )
        context.insert(macState)

        let projection = CachedDayProjection(
            macDeviceID: "test-mac",
            localDayKey: "2026-04-28@Asia/Seoul",
            dayStart: Date(),
            timeZoneIdentifier: "Asia/Seoul",
            updatedAt: Date(),
            schemaVersion: 1,
            totalFocusDurationSeconds: 3600,
            completedSessionCount: 1,
            alertCount: 0,
            longestFocusDurationSeconds: 3600,
            recoverySampleCount: 0,
            recoveryDurationTotalSeconds: 0,
            recoveryDurationMaxSeconds: 0,
            sessionsOver30mCount: 0,
            hourlyAlertCountsData: Data("[]".utf8)
        )
        context.insert(projection)

        let escalation = CachedRemoteEscalation(
            macDeviceID: "test-mac",
            occurredAt: Date(),
            escalationStep: 1,
            contentStateRawValue: "gentle_nudge"
        )
        context.insert(escalation)

        try context.save()

        let macStates = try context.fetch(FetchDescriptor<CachedMacState>())
        let projections = try context.fetch(FetchDescriptor<CachedDayProjection>())
        let escalations = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())

        #expect(macStates.count == 1)
        #expect(projections.count == 1)
        #expect(escalations.count == 1)
    }

    @Test
    func previewContainerContainsSampleData() throws {
        let container = iOSModelContainer.preview
        let context = container.mainContext

        let macStates = try context.fetch(FetchDescriptor<CachedMacState>())
        let projections = try context.fetch(FetchDescriptor<CachedDayProjection>())
        let escalations = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())

        #expect(macStates.count == 1)
        #expect(projections.count == 1)
        #expect(escalations.count == 1)
        #expect(macStates.first?.state == "monitoring")
    }
}

@MainActor
struct CachedMacStateTests {

    @Test
    func upsertInsertsNewRecord() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let payload = MacStatePayload(
            macDeviceID: "mac-001",
            state: "monitoring",
            stateChangedAt: Date(),
            sequence: 1
        )

        let service = CloudKitCacheSyncService(
            container: nil,
            modelContext: context
        )
        service.performUpsertMacState(payload)
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedMacState>())
        #expect(results.count == 1)
        #expect(results.first?.state == "monitoring")
        #expect(results.first?.macDeviceID == "mac-001")
    }

    @Test
    func upsertReplacesExistingRecord() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let service = CloudKitCacheSyncService(
            container: nil,
            modelContext: context
        )

        service.performUpsertMacState(MacStatePayload(
            macDeviceID: "mac-001",
            state: "monitoring",
            stateChangedAt: Date(),
            sequence: 1
        ))
        try context.save()

        service.performUpsertMacState(MacStatePayload(
            macDeviceID: "mac-001",
            state: "alerting",
            stateChangedAt: Date(),
            sequence: 2
        ))
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedMacState>())
        #expect(results.count == 1)
        #expect(results.first?.state == "alerting")
        #expect(results.first?.sequence == 2)
    }
}

@MainActor
struct CachedDayProjectionTests {

    @Test
    func upsertInsertsMultipleProjections() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<7 {
            let payload = DashboardDayProjectionPayload(
                macDeviceID: "mac-001",
                localDayKey: "2026-04-\(String(format: "%02d", 22 + i))@Asia/Seoul",
                dayStart: Date().addingTimeInterval(Double(-i * 86400)),
                timeZoneIdentifier: "Asia/Seoul",
                updatedAt: Date(),
                schemaVersion: 1,
                totalFocusDurationSeconds: Int64(3600 * (7 - i)),
                completedSessionCount: Int64(7 - i),
                alertCount: Int64(i),
                longestFocusDurationSeconds: Int64(3600),
                recoverySampleCount: 1,
                recoveryDurationTotalSeconds: 60,
                recoveryDurationMaxSeconds: 60,
                sessionsOver30mCount: 1,
                hourlyAlertCounts: Array(repeating: 0, count: 24),
                sourceWindowUTCStart: nil,
                sourceWindowUTCEnd: nil
            )
            service.performUpsertProjection(payload)
        }
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedDayProjection>())
        #expect(results.count == 7)
    }

    @Test
    func upsertUpdatesExistingLocalDayKey() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        let key = "2026-04-28@Asia/Seoul"
        let payload1 = makeProjectionPayload(localDayKey: key, totalFocus: 3600)
        service.performUpsertProjection(payload1)
        try context.save()

        let payload2 = makeProjectionPayload(localDayKey: key, totalFocus: 7200)
        service.performUpsertProjection(payload2)
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedDayProjection>())
        #expect(results.count == 1)
        #expect(results.first?.totalFocusDurationSeconds == 7200)
    }

    @Test
    func projectionsSortByDayStartDescending() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<3 {
            let payload = makeProjectionPayload(
                localDayKey: "day-\(i)",
                totalFocus: 3600,
                dayStartOffset: Double(-i * 86400)
            )
            service.performUpsertProjection(payload)
        }
        try context.save()

        var descriptor = FetchDescriptor<CachedDayProjection>(
            sortBy: [SortDescriptor(\.dayStart, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        #expect(results.count == 3)
        #expect(results.first?.localDayKey == "day-0")
    }

    @Test
    func hourlyAlertCountsDecodedFromData() throws {
        let counts = Array(repeating: 1, count: 24)
        let data = try JSONEncoder().encode(counts)

        let projection = CachedDayProjection(
            macDeviceID: "mac-001",
            localDayKey: "key",
            dayStart: Date(),
            timeZoneIdentifier: "Asia/Seoul",
            updatedAt: Date(),
            schemaVersion: 1,
            totalFocusDurationSeconds: 0,
            completedSessionCount: 0,
            alertCount: 0,
            longestFocusDurationSeconds: 0,
            recoverySampleCount: 0,
            recoveryDurationTotalSeconds: 0,
            recoveryDurationMaxSeconds: 0,
            sessionsOver30mCount: 0,
            hourlyAlertCountsData: data
        )

        #expect(projection.hourlyAlertCounts == counts)
    }

    @Test
    func hourlyAlertCountsFallbacksOnInvalidData() {
        let projection = CachedDayProjection(
            macDeviceID: "mac-001",
            localDayKey: "key",
            dayStart: Date(),
            timeZoneIdentifier: "Asia/Seoul",
            updatedAt: Date(),
            schemaVersion: 1,
            totalFocusDurationSeconds: 0,
            completedSessionCount: 0,
            alertCount: 0,
            longestFocusDurationSeconds: 0,
            recoverySampleCount: 0,
            recoveryDurationTotalSeconds: 0,
            recoveryDurationMaxSeconds: 0,
            sessionsOver30mCount: 0,
            hourlyAlertCountsData: Data("invalid json".utf8)
        )

        #expect(projection.hourlyAlertCounts == Array(repeating: 0, count: 24))
    }

    private func makeProjectionPayload(
        localDayKey: String,
        totalFocus: Int64,
        dayStartOffset: Double = 0
    ) -> DashboardDayProjectionPayload {
        DashboardDayProjectionPayload(
            macDeviceID: "mac-001",
            localDayKey: localDayKey,
            dayStart: Date().addingTimeInterval(dayStartOffset),
            timeZoneIdentifier: "Asia/Seoul",
            updatedAt: Date(),
            schemaVersion: 1,
            totalFocusDurationSeconds: totalFocus,
            completedSessionCount: 1,
            alertCount: 0,
            longestFocusDurationSeconds: totalFocus,
            recoverySampleCount: 0,
            recoveryDurationTotalSeconds: 0,
            recoveryDurationMaxSeconds: 0,
            sessionsOver30mCount: 0,
            hourlyAlertCounts: Array(repeating: 0, count: 24),
            sourceWindowUTCStart: nil,
            sourceWindowUTCEnd: nil
        )
    }
}

@MainActor
struct CachedRemoteEscalationTests {

    @Test
    func upsertInsertsNewEscalations() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<5 {
            let payload = RemoteEscalationEventPayload(
                macDeviceID: "mac-001",
                occurredAt: Date().addingTimeInterval(Double(-i) * 3600),
                escalationStep: i + 1,
                contentStateRawValue: "step_\(i)"
            )
            service.performUpsertEscalation(payload)
        }
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())
        #expect(results.count == 5)
    }

    @Test
    func upsertUpdatesRecoveryFields() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        let occurredAt = Date()

        let payload1 = RemoteEscalationEventPayload(
            macDeviceID: "mac-001",
            occurredAt: occurredAt,
            escalationStep: 1,
            contentStateRawValue: "gentle_nudge"
        )
        service.performUpsertEscalation(payload1)
        try context.save()

        let payload2 = RemoteEscalationEventPayload(
            macDeviceID: "mac-001",
            occurredAt: occurredAt,
            escalationStep: 1,
            contentStateRawValue: "gentle_nudge",
            wasRecoveredWithinWindow: true,
            recoveredAt: Date().addingTimeInterval(300)
        )
        service.performUpsertEscalation(payload2)
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())
        #expect(results.count == 1)
        #expect(results.first?.wasRecoveredWithinWindow == true)
        #expect(results.first?.recoveredAt != nil)
    }

    @Test
    func escalationsSortByOccurredAtDescending() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<3 {
            let payload = RemoteEscalationEventPayload(
                macDeviceID: "mac-001",
                occurredAt: Date().addingTimeInterval(Double(-i) * 3600),
                escalationStep: i + 1,
                contentStateRawValue: "step_\(i)"
            )
            service.performUpsertEscalation(payload)
        }
        try context.save()

        let descriptor = FetchDescriptor<CachedRemoteEscalation>(
            sortBy: [SortDescriptor(\.occurredAt, order: .reverse)]
        )
        let results = try context.fetch(descriptor)
        #expect(results.count == 3)
        #expect(results.first?.escalationStep == 1)
    }
}

@MainActor
struct RetentionTrimmingTests {

    @Test
    func trimRemovesExpiredProjections() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<40 {
            let dayStart = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let payload = DashboardDayProjectionPayload(
                macDeviceID: "mac-001",
                localDayKey: "day-\(i)",
                dayStart: dayStart,
                timeZoneIdentifier: "Asia/Seoul",
                updatedAt: Date(),
                schemaVersion: 1,
                totalFocusDurationSeconds: 3600,
                completedSessionCount: 1,
                alertCount: 0,
                longestFocusDurationSeconds: 3600,
                recoverySampleCount: 0,
                recoveryDurationTotalSeconds: 0,
                recoveryDurationMaxSeconds: 0,
                sessionsOver30mCount: 0,
                hourlyAlertCounts: Array(repeating: 0, count: 24),
                sourceWindowUTCStart: nil,
                sourceWindowUTCEnd: nil
            )
            service.performUpsertProjection(payload)
        }
        try context.save()

        let before = try context.fetch(FetchDescriptor<CachedDayProjection>())
        #expect(before.count == 40)

        try service.trimExpiredCache()

        let after = try context.fetch(FetchDescriptor<CachedDayProjection>())
        #expect(after.count <= 35)
        #expect(after.count >= 34)
    }

    @Test
    func trimRemovesExpiredEscalations() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let service = CloudKitCacheSyncService(container: nil, modelContext: context)

        for i in 0..<35 {
            let occurredAt = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
            let payload = RemoteEscalationEventPayload(
                macDeviceID: "mac-001",
                occurredAt: occurredAt,
                escalationStep: 1,
                contentStateRawValue: "test"
            )
            service.performUpsertEscalation(payload)
        }
        try context.save()

        let before = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())
        #expect(before.count == 35)

        try service.trimExpiredCache()

        let after = try context.fetch(FetchDescriptor<CachedRemoteEscalation>())
        #expect(after.count <= 30)
        #expect(after.count >= 29)
    }
}

@MainActor
struct CloudKitSyncServiceErrorTests {

    @Test
    func syncMacStatePreservesCacheWhenNoCloudKitRecords() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let existing = CachedMacState(
            macDeviceID: "mac-001",
            state: "monitoring",
            stateChangedAt: Date(),
            sequence: 1
        )
        context.insert(existing)
        try context.save()

        let fetchedAt = existing.fetchedAt

        let results = try context.fetch(FetchDescriptor<CachedMacState>())
        #expect(results.count == 1)
        #expect(results.first?.state == "monitoring")
        #expect(results.first?.fetchedAt == fetchedAt)
    }

    @Test
    func syncRecentProjectionsPreservesEmptyCache() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let results = try context.fetch(FetchDescriptor<CachedDayProjection>())
        #expect(results.isEmpty)
    }

    @Test
    func syncAllDoesNotDeleteExistingCache() throws {
        let container = try iOSModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let macState = CachedMacState(
            macDeviceID: "mac-001",
            state: "alerting",
            stateChangedAt: Date(),
            sequence: 5
        )
        context.insert(macState)
        try context.save()

        let results = try context.fetch(FetchDescriptor<CachedMacState>())
        #expect(results.count == 1)
        #expect(results.first?.state == "alerting")
    }
}
