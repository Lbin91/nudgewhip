import Foundation

@MainActor
final class CloudKitDailyAggregateOutbox {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let appSupport = URL.applicationSupportDirectory
            self.fileURL = appSupport
                .appending(component: "cloudkit-daily-aggregate-outbox.json")
        }
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func pendingPayloads() throws -> [DashboardDayProjectionPayload] {
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([DashboardDayProjectionPayload].self, from: data)
            .sorted { lhs, rhs in
                if lhs.dayStart == rhs.dayStart {
                    return lhs.localDayKey < rhs.localDayKey
                }
                return lhs.dayStart < rhs.dayStart
            }
    }

    func upsert(_ payload: DashboardDayProjectionPayload) throws {
        var payloads = try pendingPayloads()
        payloads.removeAll { $0.macDeviceID == payload.macDeviceID && $0.localDayKey == payload.localDayKey }
        payloads.append(payload)
        try write(payloads)
    }

    func remove(macDeviceID: String, localDayKey: String) throws {
        var payloads = try pendingPayloads()
        payloads.removeAll { $0.macDeviceID == macDeviceID && $0.localDayKey == localDayKey }
        try write(payloads)
    }

    private func write(_ payloads: [DashboardDayProjectionPayload]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        if payloads.isEmpty {
            if FileManager.default.fileExists(atPath: fileURL.path()) {
                try FileManager.default.removeItem(at: fileURL)
            }
            return
        }

        let data = try encoder.encode(payloads)
        try data.write(to: fileURL, options: .atomic)
    }
}
