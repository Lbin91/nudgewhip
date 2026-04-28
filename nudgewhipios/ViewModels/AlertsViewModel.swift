import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
@MainActor
@Observable
final class AlertsViewModel {
    private let modelContext: ModelContext
    let macDeviceID: String

    private(set) var alerts: [CachedRemoteEscalation] = []

    init(modelContext: ModelContext, macDeviceID: String) {
        self.modelContext = modelContext
        self.macDeviceID = macDeviceID
    }

    convenience init(macDeviceID: String) {
        self.init(modelContext: iOSModelContainer.shared.mainContext, macDeviceID: macDeviceID)
    }

    var hasAlerts: Bool {
        !alerts.isEmpty
    }

    var groupedAlerts: [(String, [CachedRemoteEscalation])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let todayKey = String(localized: "ios.alerts.section.today")
        let yesterdayKey = String(localized: "ios.alerts.section.yesterday")
        let olderKey = String(localized: "ios.alerts.section.older")

        var groups: [String: [CachedRemoteEscalation]] = [
            todayKey: [],
            yesterdayKey: [],
            olderKey: []
        ]

        for alert in alerts {
            let alertDay = calendar.startOfDay(for: alert.occurredAt)
            let daysBetween = calendar.dateComponents([.day], from: alertDay, to: today).day ?? 0

            let key: String
            switch daysBetween {
            case 0: key = todayKey
            case 1: key = yesterdayKey
            default: key = olderKey
            }

            groups[key, default: []].append(alert)
        }

        var result: [(String, [CachedRemoteEscalation])] = []
        for key in [todayKey, yesterdayKey, olderKey] {
            let items = groups[key] ?? []
            if !items.isEmpty {
                result.append((key, items))
            }
        }
        return result
    }

    func reloadData() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date.now) ?? Date.now

        var descriptor = FetchDescriptor<CachedRemoteEscalation>(
            predicate: #Predicate {
                $0.macDeviceID == macDeviceID && $0.occurredAt >= cutoff
            }
        )
        descriptor.sortBy = [SortDescriptor(\.occurredAt, order: .reverse)]

        alerts = (try? modelContext.fetch(descriptor)) ?? []
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func escalationIcon(step: Int) -> String {
        switch step {
        case 1: return "bell"
        case 2: return "bell.badge"
        default: return "bell.badge.waveform"
        }
    }

    func escalationLabel(step: Int) -> String {
        switch step {
        case 1: return String(localized: "ios.alerts.step.gentle")
        case 2: return String(localized: "ios.alerts.step.notification")
        default: return String(localized: "ios.alerts.step.escalation")
        }
    }

    func recoveryStatusText(_ escalation: CachedRemoteEscalation) -> String {
        if escalation.wasRecoveredWithinWindow == true { return String(localized: "ios.alerts.recovered") }
        if escalation.wasRecoveredWithinWindow == false { return String(localized: "ios.alerts.not_recovered") }
        return ""
    }

    func recoveryIcon(_ escalation: CachedRemoteEscalation) -> String {
        if escalation.wasRecoveredWithinWindow == true { return "checkmark.circle.fill" }
        if escalation.wasRecoveredWithinWindow == false { return "xmark.circle.fill" }
        return ""
    }
}
#endif
