import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
@MainActor
@Observable
final class SettingsViewModel {
    private let modelContext: ModelContext

    private(set) var macState: CachedMacState?
    private(set) var escalationCount: Int = 0
    private(set) var lastSyncAt: Date?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    convenience init() {
        self.init(modelContext: iOSModelContainer.shared.mainContext)
    }

    var iCloudStatus: StatusKind {
        macState != nil ? .normal : .warning
    }

    var iCloudDetailText: String {
        if macState != nil {
            return String(localized: "ios.settings.connection.connected")
        }
        return String(localized: "ios.settings.connection.icloud.detail")
    }

    var connectedMacText: String {
        if let state = macState {
            return state.macDeviceID
        }
        return String(localized: "ios.settings.connection.mac.none")
    }

    var lastSyncText: String {
        formatRelativeTime(lastSyncAt)
    }

    func reloadData(lastSyncAt: Date? = nil) {
        self.lastSyncAt = lastSyncAt

        let macDescriptor = FetchDescriptor<CachedMacState>()
        macState = try? modelContext.fetch(macDescriptor).first

        let escalationDescriptor = FetchDescriptor<CachedRemoteEscalation>()
        escalationCount = (try? modelContext.fetchCount(escalationDescriptor)) ?? 0
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private func formatRelativeTime(_ date: Date?) -> String {
        guard let date else { return "--" }
        let interval = Date.now.timeIntervalSince(date)
        if interval < 60 { return String(localized: "ios.sync.time.just_now") }
        return Self.relativeFormatter.localizedString(for: date, relativeTo: Date.now)
    }
}
#endif
