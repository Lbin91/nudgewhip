import Foundation
import SwiftData

enum FocusSessionEndReason: String, Codable, CaseIterable, Sendable {
    case completed
    case idleTimeout
    case manualPause
    case whitelistPause
    case suspended
}

@Model
final class FocusSession {
    var startedAt: Date
    var endedAt: Date?
    var monitoringActive: Bool
    var breakMode: Bool
    var whitelistedPause: Bool
    var alertCount: Int
    var ttsCount: Int
    var recoveryCount: Int
    var lastAlertAt: Date?
    var endReasonRawValue: String?
    var createdAt: Date
    
    var endReason: FocusSessionEndReason? {
        get {
            guard let endReasonRawValue else { return nil }
            return FocusSessionEndReason(rawValue: endReasonRawValue)
        }
        set {
            endReasonRawValue = newValue?.rawValue
        }
    }
    
    var duration: TimeInterval {
        guard let endedAt else { return 0 }
        return max(0, endedAt.timeIntervalSince(startedAt))
    }
    
    var contributesToFocusTotals: Bool {
        monitoringActive && !breakMode && !whitelistedPause && endedAt != nil
    }
    
    init(
        startedAt: Date,
        endedAt: Date? = nil,
        monitoringActive: Bool = true,
        breakMode: Bool = false,
        whitelistedPause: Bool = false,
        alertCount: Int = 0,
        ttsCount: Int = 0,
        recoveryCount: Int = 0,
        lastAlertAt: Date? = nil,
        endReason: FocusSessionEndReason? = nil,
        createdAt: Date = .now
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.monitoringActive = monitoringActive
        self.breakMode = breakMode
        self.whitelistedPause = whitelistedPause
        self.alertCount = alertCount
        self.ttsCount = ttsCount
        self.recoveryCount = recoveryCount
        self.lastAlertAt = lastAlertAt
        self.endReasonRawValue = endReason?.rawValue
        self.createdAt = createdAt
    }
    
    func focusDuration(overlapping interval: DateInterval) -> TimeInterval {
        guard contributesToFocusTotals, let endedAt else { return 0 }
        let safeEnd = max(startedAt, endedAt)
        let sessionInterval = DateInterval(start: startedAt, end: safeEnd)
        guard let overlap = sessionInterval.intersection(with: interval) else { return 0 }
        return overlap.duration
    }
}
