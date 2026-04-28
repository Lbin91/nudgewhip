import Foundation
import SwiftData
import SwiftUI

/// macOS RuntimeStateController.NudgeWhipRuntimeState.rawValue 와 동일한 상수
enum MacRuntimeState {
    static let limitedNoAX = "limitedNoAX"
    static let monitoring = "monitoring"
    static let pausedManual = "pausedManual"
    static let pausedWhitelist = "pausedWhitelist"
    static let alerting = "alerting"
    static let pausedSchedule = "pausedSchedule"
    static let suspendedSleepOrLock = "suspendedSleepOrLock"
}

#if os(iOS)
@MainActor
@Observable
final class HomeViewModel {
    private let modelContext: ModelContext
    let macDeviceID: String

    private(set) var macState: CachedMacState?
    private(set) var todayProjection: CachedDayProjection?

    init(modelContext: ModelContext, macDeviceID: String) {
        self.modelContext = modelContext
        self.macDeviceID = macDeviceID
    }

    convenience init(macDeviceID: String) {
        self.init(modelContext: iOSModelContainer.shared.mainContext, macDeviceID: macDeviceID)
    }

    var focusTimeText: String {
        guard let proj = todayProjection else { return "--" }
        return formatDuration(seconds: proj.totalFocusDurationSeconds)
    }

    var nudgeCountText: String {
        guard let proj = todayProjection else { return "--" }
        return proj.alertCount > 0 ? "\(proj.alertCount)" : "--"
    }

    var completedSessionsText: String {
        guard let proj = todayProjection else { return "--" }
        return proj.completedSessionCount > 0 ? "\(proj.completedSessionCount)" : "--"
    }

    var longestFocusText: String {
        guard let proj = todayProjection else { return "--" }
        return formatDuration(seconds: proj.longestFocusDurationSeconds)
    }

    var macStateIcon: String {
        guard let state = macState else { return "desktopcomputer" }
        switch state.state {
        case MacRuntimeState.monitoring: return "eye.circle"
        case MacRuntimeState.pausedManual: return "pause.circle"
        case MacRuntimeState.alerting: return "exclamationmark.circle"
        case MacRuntimeState.pausedSchedule: return "clock.badge"
        case MacRuntimeState.suspendedSleepOrLock: return "moon.zzz"
        case MacRuntimeState.limitedNoAX: return "hand.raised.slash"
        default: return "desktopcomputer"
        }
    }

    var macStateText: String {
        guard let state = macState else {
            return String(localized: "ios.home.status_unavailable")
        }
        switch state.state {
        case MacRuntimeState.monitoring:
            return String(localized: "ios.home.mac_state.monitoring")
        case MacRuntimeState.pausedManual:
            return String(localized: "ios.home.mac_state.paused")
        case MacRuntimeState.alerting:
            return String(localized: "ios.home.mac_state.alerting")
        case MacRuntimeState.pausedSchedule:
            return String(localized: "ios.home.mac_state.paused")
        case MacRuntimeState.suspendedSleepOrLock:
            return String(localized: "ios.home.mac_state.offline")
        case MacRuntimeState.limitedNoAX:
            return String(localized: "ios.home.mac_state.offline")
        default:
            return String(localized: "ios.home.mac_state.unknown")
        }
    }

    var isMacOnline: Bool {
        guard let state = macState else { return false }
        return Date.now.timeIntervalSince(state.stateChangedAt) < 300
    }

    func reloadData() {
        let macDescriptor = FetchDescriptor<CachedMacState>(
            predicate: #Predicate { $0.macDeviceID == macDeviceID }
        )
        macState = try? modelContext.fetch(macDescriptor).first

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: Date.now)
        let localDayKey = "\(datePart)@\(TimeZone.current.identifier)"

        let dayDescriptor = FetchDescriptor<CachedDayProjection>(
            predicate: #Predicate {
                $0.macDeviceID == macDeviceID && $0.localDayKey == localDayKey
            }
        )
        todayProjection = try? modelContext.fetch(dayDescriptor).first
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute, .second]
        f.unitsStyle = .abbreviated
        return f
    }()

    private func formatDuration(seconds: Int64) -> String {
        guard seconds > 0 else { return "--" }
        return Self.durationFormatter.string(from: TimeInterval(seconds)) ?? "--"
    }
}
#endif
