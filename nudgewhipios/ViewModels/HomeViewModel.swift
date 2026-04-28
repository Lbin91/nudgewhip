import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
@MainActor
@Observable
final class HomeViewModel {
    private let modelContext: ModelContext

    private(set) var macState: CachedMacState?
    private(set) var todayProjection: CachedDayProjection?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    convenience init() {
        self.init(modelContext: iOSModelContainer.shared.mainContext)
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
        case "monitoring": return "eye.circle"
        case "pausedManual": return "pause.circle"
        case "alerting": return "exclamationmark.circle"
        case "pausedSchedule": return "clock.badge"
        case "suspendedSleepOrLock": return "moon.zzz"
        case "limitedNoAx": return "hand.raised.slash"
        default: return "desktopcomputer"
        }
    }

    var macStateText: String {
        guard let state = macState else {
            return String(localized: "ios.home.status_unavailable")
        }
        switch state.state {
        case "monitoring":
            return String(localized: "ios.home.mac_state.monitoring")
        case "pausedManual":
            return String(localized: "ios.home.mac_state.paused")
        case "alerting":
            return String(localized: "ios.home.mac_state.alerting")
        case "pausedSchedule":
            return String(localized: "ios.home.mac_state.paused")
        case "suspendedSleepOrLock":
            return String(localized: "ios.home.mac_state.offline")
        case "limitedNoAx":
            return String(localized: "ios.home.mac_state.offline")
        default:
            return state.state
        }
    }

    var isMacOnline: Bool {
        guard let state = macState else { return false }
        return Date.now.timeIntervalSince(state.stateChangedAt) < 300
    }

    func reloadData() {
        let macDescriptor = FetchDescriptor<CachedMacState>()
        macState = try? modelContext.fetch(macDescriptor).first

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: Date.now)
        let localDayKey = "\(datePart)@\(TimeZone.current.identifier)"

        let dayDescriptor = FetchDescriptor<CachedDayProjection>(
            predicate: #Predicate { $0.localDayKey == localDayKey }
        )
        todayProjection = try? modelContext.fetch(dayDescriptor).first
    }

    private func formatDuration(seconds: Int64) -> String {
        guard seconds > 0 else { return "--" }
        let hrs = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60

        if hrs > 0 {
            return mins > 0 ? "\(hrs)h \(mins)m" : "\(hrs)h"
        }
        if mins > 0 {
            return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
        }
        return "\(secs)s"
    }
}
#endif
