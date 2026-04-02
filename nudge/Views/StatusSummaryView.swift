import SwiftUI

struct StatusSummaryView: View {
    let menuBarViewModel: MenuBarViewModel
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(runtimeStateTitle)
                            .font(.headline)
                        Text(contentStateTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: menuBarViewModel.systemImageName)
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                
                if let countdown = menuBarViewModel.countdownText(now: context.date) {
                    LabeledContent {
                        Text(countdown)
                            .monospacedDigit()
                    } label: {
                        Text(localizedAppString("menu.status.label.next_check", defaultValue: "Next check"))
                    }
                } else {
                    Text(statusDetail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var runtimeStateTitle: String {
        switch menuBarViewModel.runtimeState {
        case .limitedNoAX:
            return localizedAppString("menu.status.value.runtime.limited_no_ax", defaultValue: "Limited mode")
        case .monitoring:
            return localizedAppString("menu.status.value.runtime.monitoring", defaultValue: "Monitoring")
        case .pausedManual:
            return localizedAppString("menu.status.value.runtime.paused_manual", defaultValue: "Break mode")
        case .pausedWhitelist:
            return localizedAppString("menu.status.value.runtime.paused_whitelist", defaultValue: "Whitelist pause")
        case .alerting:
            return localizedAppString("menu.status.value.runtime.alerting", defaultValue: "Alerting")
        case .suspendedSleepOrLock:
            return localizedAppString("menu.status.value.runtime.suspended", defaultValue: "Suspended")
        }
    }
    
    private var contentStateTitle: String {
        switch menuBarViewModel.contentState {
        case .focus:
            return localizedAppString("menu.status.value.content.focus", defaultValue: "Focus")
        case .idleDetected:
            return localizedAppString("menu.status.value.content.idle_detected", defaultValue: "Idle detected")
        case .gentleNudge:
            return localizedAppString("menu.status.value.content.gentle_nudge", defaultValue: "Gentle nudge")
        case .strongNudge:
            return localizedAppString("menu.status.value.content.strong_nudge", defaultValue: "Strong nudge")
        case .recovery:
            return localizedAppString("menu.status.value.content.recovery", defaultValue: "Recovery")
        case .break:
            return localizedAppString("menu.status.value.content.break", defaultValue: "Break")
        case .remoteEscalation:
            return localizedAppString("menu.status.value.content.remote_escalation", defaultValue: "Remote escalation")
        }
    }
    
    private var statusDetail: String {
        switch menuBarViewModel.runtimeState {
        case .limitedNoAX:
            return localizedAppString(
                "menu.status.detail.limited_no_ax",
                defaultValue: "Accessibility permission is needed for active idle detection."
            )
        case .pausedManual:
            return localizedAppString(
                "menu.status.detail.paused_manual",
                defaultValue: "Manual pause is active, so idle alerts are stopped."
            )
        case .pausedWhitelist:
            return localizedAppString(
                "menu.status.detail.paused_whitelist",
                defaultValue: "A whitelisted app is frontmost, so monitoring is paused."
            )
        case .alerting:
            return localizedAppString(
                "menu.status.detail.alerting",
                defaultValue: "Nudge escalation is active until activity returns."
            )
        case .suspendedSleepOrLock:
            return localizedAppString(
                "menu.status.detail.suspended",
                defaultValue: "Monitoring is suspended while the Mac is asleep, locked, or switched away."
            )
        case .monitoring:
            return localizedAppString(
                "menu.status.detail.monitoring",
                defaultValue: "Idle countdown is running with the current threshold."
            )
        }
    }
}
