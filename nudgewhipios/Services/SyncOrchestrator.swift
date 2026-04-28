#if os(iOS)
import CloudKit
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SyncOrchestrator {

    private(set) var isSyncing: Bool = false
    private(set) var lastSyncAt: Date?
    private(set) var lastSyncError: String?
    var macDeviceID: String?

    private let syncService: CloudKitCacheSyncService
    nonisolated(unsafe) private var foregroundObserver: NSObjectProtocol?
    nonisolated(unsafe) private var dayChangeObserver: NSObjectProtocol?

    private static let macDeviceIDKey = "nudgewhip.ios.cached_mac_device_id"

    static var cachedMacDeviceID: String? {
        UserDefaults.standard.string(forKey: macDeviceIDKey)
    }

    init(modelContext: ModelContext) {
        self.syncService = CloudKitCacheSyncService(modelContext: modelContext)
        startObservers()
    }

    convenience init() {
        self.init(modelContext: iOSModelContainer.shared.mainContext)
    }

    deinit {
        if let foregroundObserver {
            NotificationCenter.default.removeObserver(foregroundObserver)
        }
        if let dayChangeObserver {
            NotificationCenter.default.removeObserver(dayChangeObserver)
        }
    }

    // MARK: - Public

    func triggerSync() async {
        guard !isSyncing else { return }
        isSyncing = true

        if macDeviceID == nil {
            await resolveMacDeviceID()
        }

        guard let macDeviceID else {
            lastSyncError = "Mac device ID not found"
            isSyncing = false
            return
        }

        do {
            try await syncService.syncAll(macDeviceID: macDeviceID)
            lastSyncAt = Date()
            lastSyncError = nil
        } catch {
            lastSyncError = error.localizedDescription
        }

        isSyncing = false
    }

    func refresh() async {
        await triggerSync()
    }

    // MARK: - Private

    private func resolveMacDeviceID() async {
        if let cached = UserDefaults.standard.string(forKey: Self.macDeviceIDKey) {
            macDeviceID = cached
            return
        }

        guard let discovered = try? await syncService.discoverMacDeviceID() else {
            return
        }

        UserDefaults.standard.set(discovered, forKey: Self.macDeviceIDKey)
        macDeviceID = discovered
    }

    private func startObservers() {
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.triggerSync()
            }
        }

        dayChangeObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.triggerSync()
            }
        }
    }
}
#endif
