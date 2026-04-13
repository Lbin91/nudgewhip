import Foundation

@MainActor
final class DailyAggregateProjectionCoordinator {
    private let builder: DailyAggregateProjectionBuilder
    private let writer: CloudKitDailyAggregateBackupWriter
    private let deviceIdentityProvider: DeviceIdentityProvider
    private let timeZoneProvider: @MainActor () -> String
    private let nowProvider: @MainActor () -> Date
    private var dayBoundaryWorkItem: DispatchWorkItem?
    private var pendingRetryDates: Set<Date> = []

    init(
        builder: DailyAggregateProjectionBuilder,
        writer: CloudKitDailyAggregateBackupWriter,
        deviceIdentityProvider: DeviceIdentityProvider,
        timeZoneProvider: @escaping @MainActor () -> String = { TimeZone.current.identifier },
        nowProvider: @escaping @MainActor () -> Date = { .now }
    ) {
        self.builder = builder
        self.writer = writer
        self.deviceIdentityProvider = deviceIdentityProvider
        self.timeZoneProvider = timeZoneProvider
        self.nowProvider = nowProvider
    }

    func start(at date: Date? = nil) {
        let resolvedDate = date ?? nowProvider()
        scheduleDayBoundary(from: resolvedDate)
        enqueueBackup(for: resolvedDate)
    }

    func handleSessionUpdated(at date: Date? = nil) {
        let resolvedDate = date ?? nowProvider()
        enqueueBackup(for: resolvedDate)
    }

    private func enqueueBackup(for referenceDate: Date) {
        Task { @MainActor in
            await flush(referenceDates: Array(pendingRetryDates) + [referenceDate])
        }
    }

    private func flush(referenceDates: [Date]) async {
        let macDeviceID = deviceIdentityProvider.macDeviceID()
        let timeZoneIdentifier = timeZoneProvider()
        pendingRetryDates.removeAll()

        for referenceDate in dedupedDayStarts(for: referenceDates, timeZoneIdentifier: timeZoneIdentifier) {
            do {
                let payload = try builder.buildDayProjection(
                    macDeviceID: macDeviceID,
                    referenceDate: referenceDate,
                    timeZoneIdentifier: timeZoneIdentifier,
                    updatedAt: nowProvider()
                )
                try await writer.save(payload)
            } catch {
                pendingRetryDates.insert(referenceDate)
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
