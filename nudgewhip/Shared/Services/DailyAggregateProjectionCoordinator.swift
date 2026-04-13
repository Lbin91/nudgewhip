import Foundation

@MainActor
final class DailyAggregateProjectionCoordinator {
    private let builder: DailyAggregateProjectionBuilder
    private let writer: CloudKitDailyAggregateBackupWriter
    private let outbox: CloudKitDailyAggregateOutbox
    private let deviceIdentityProvider: DeviceIdentityProvider
    private let timeZoneProvider: @MainActor () -> String
    private let nowProvider: @MainActor () -> Date
    private var dayBoundaryWorkItem: DispatchWorkItem?

    init(
        builder: DailyAggregateProjectionBuilder,
        writer: CloudKitDailyAggregateBackupWriter,
        outbox: CloudKitDailyAggregateOutbox? = nil,
        deviceIdentityProvider: DeviceIdentityProvider,
        timeZoneProvider: @escaping @MainActor () -> String = { TimeZone.current.identifier },
        nowProvider: @escaping @MainActor () -> Date = { .now }
    ) {
        self.builder = builder
        self.writer = writer
        self.outbox = outbox ?? CloudKitDailyAggregateOutbox()
        self.deviceIdentityProvider = deviceIdentityProvider
        self.timeZoneProvider = timeZoneProvider
        self.nowProvider = nowProvider
    }

    func start(at date: Date? = nil) {
        let resolvedDate = date ?? nowProvider()
        scheduleDayBoundary(from: resolvedDate)
        Task { @MainActor in
            await flushOutbox()
        }
        enqueueBackup(for: resolvedDate)
    }

    func handleSessionUpdated(at date: Date? = nil) {
        let resolvedDate = date ?? nowProvider()
        enqueueBackup(for: resolvedDate)
    }

    private func enqueueBackup(for referenceDate: Date) {
        Task { @MainActor in
            await rebuildAndQueue(referenceDates: [referenceDate])
            await flushOutbox()
        }
    }

    private func rebuildAndQueue(referenceDates: [Date]) async {
        let macDeviceID = deviceIdentityProvider.macDeviceID()
        let timeZoneIdentifier = timeZoneProvider()

        for referenceDate in dedupedDayStarts(for: referenceDates, timeZoneIdentifier: timeZoneIdentifier) {
            do {
                let payload = try builder.buildDayProjection(
                    macDeviceID: macDeviceID,
                    referenceDate: referenceDate,
                    timeZoneIdentifier: timeZoneIdentifier,
                    updatedAt: nowProvider()
                )
                try outbox.upsert(payload)
            } catch {
                continue
            }
        }
    }

    private func flushOutbox() async {
        let payloads = (try? outbox.pendingPayloads()) ?? []
        for payload in payloads {
            do {
                try await writer.save(payload)
                try outbox.remove(macDeviceID: payload.macDeviceID, localDayKey: payload.localDayKey)
            } catch {
                continue
            }
        }
    }

    private func scheduleDayBoundary(from date: Date) {
        dayBoundaryWorkItem?.cancel()
        guard let timeZone = TimeZone(identifier: timeZoneProvider()) else { return }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        guard let todayInterval = calendar.dateInterval(of: .day, for: date) else { return }
        let nextBoundary = todayInterval.end
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let currentDate = self.nowProvider()
            self.enqueueBackup(for: nextBoundary.addingTimeInterval(-1))
            self.enqueueBackup(for: currentDate)
            self.scheduleDayBoundary(from: currentDate)
        }
        dayBoundaryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0, nextBoundary.timeIntervalSince(date)), execute: workItem)
    }

    private func dedupedDayStarts(for referenceDates: [Date], timeZoneIdentifier: String) -> [Date] {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else { return referenceDates }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var seen = Set<Date>()
        return referenceDates.compactMap { date in
            let dayStart = calendar.startOfDay(for: date)
            if seen.insert(dayStart).inserted {
                return dayStart
            }
            return nil
        }
    }
}
