import SwiftUI

struct StatusSummaryView: View {
    let menuBarViewModel: MenuBarViewModel

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.nudgeFocus.opacity(0.15), Color.nudgeAccent.opacity(0.08)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: NudgeRadius.card, topTrailingRadius: NudgeRadius.card))

            HStack(spacing: NudgeSpacing.s3) {
                CircularGaugeView(
                    progress: gaugeProgress,
                    tint: gaugeColor
                )

                VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
                    Text(runtimeStateTitle)
                        .font(.headline)
                        .foregroundStyle(Color.nudgeTextPrimary)

                    Text(contentStateTitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.nudgeTextSecondary)

                    if let countdown = menuBarViewModel.countdownText() {
                        Text(countdown)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(gaugeColor)
                    } else {
                        Text(statusDetail)
                            .font(.caption)
                            .foregroundStyle(Color.nudgeTextMuted)
                            .lineLimit(2)
                    }
                }

                Spacer()

                AnimatedASCIICharacterView(
                    hatchStage: .egg,
                    character: .partyMask,
                    emotion: .happy
                )
            }
            .padding(NudgeSpacing.s4)
        }
        .nudgeCard()
    }

    private var gaugeProgress: Double {
        switch menuBarViewModel.runtimeState {
        case .monitoring: return menuBarViewModel.countdownText() != nil ? 0.4 : 0.0
        case .alerting: return 1.0
        case .pausedManual, .pausedSchedule, .pausedWhitelist, .suspendedSleepOrLock: return 0.0
        case .limitedNoAX: return 0.0
        }
    }

    private var gaugeColor: Color {
        switch menuBarViewModel.contentState {
        case .focus: Color.nudgeFocus
        case .idleDetected: Color.nudgeFocus.opacity(0.6)
        case .gentleNudge: Color.nudgeFocus
        case .strongNudge: Color.nudgeAlert
        case .recovery: Color.nudgeFocus
        case .break: Color.nudgeRest
        case .remoteEscalation: Color.nudgeAlert
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
        case .pausedSchedule:
            return localizedAppString("menu.status.value.runtime.paused_schedule", defaultValue: "Waiting for schedule")
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
                defaultValue: "NudgeWhip escalation is active until activity returns."
            )
        case .pausedSchedule:
            return localizedAppString(
                "menu.status.detail.paused_schedule",
                defaultValue: "Outside the active schedule. Monitoring will resume at the scheduled time."
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
