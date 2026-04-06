import SwiftUI

struct StatusSummaryView: View {
    let menuBarViewModel: MenuBarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
            HStack(alignment: .top, spacing: NudgeSpacing.s4) {
                heroCopy
                Spacer(minLength: 0)
                petAnchor
            }

            HStack(spacing: NudgeSpacing.s2) {
                heroMetric(
                    label: localizedAppString("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"),
                    value: menuBarViewModel.idleThresholdText
                )

                heroMetric(
                    label: localizedAppString("menu.dropdown.label.schedule", defaultValue: "Schedule"),
                    value: menuBarViewModel.scheduleText
                )
            }
        }
        .padding(NudgeSpacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroBackground, in: RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous)
                .stroke(heroTone.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 14, y: 4)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            Text(contentStateTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(heroTone)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(heroTone.opacity(0.12), in: Capsule())

            Text(runtimeStateTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.nudgeTextPrimary)

            if let countdown = menuBarViewModel.countdownText() {
                VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
                    Text(localizedAppString("menu.status.label.next_check", defaultValue: "Next check"))
                        .font(.caption)
                        .foregroundStyle(Color.nudgeTextSecondary)

                    Text(countdown)
                        .font(.title.monospacedDigit().weight(.semibold))
                        .foregroundStyle(heroTone)
                }
            } else {
                Text(statusLine)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(heroTone)
                    .lineLimit(2)
            }

            Text(statusDetail)
                .font(.caption)
                .foregroundStyle(Color.nudgeTextSecondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var petAnchor: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            AnimatedASCIICharacterView(
                hatchStage: menuBarViewModel.petHatchStage,
                character: menuBarViewModel.petCharacter,
                emotion: menuBarViewModel.petEmotion,
                animate: false
            )

            Text(menuBarViewModel.petCharacterText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgeTextPrimary)
                .lineLimit(1)
        }
        .padding(NudgeSpacing.s3)
        .background(
            RoundedRectangle(cornerRadius: NudgeRadius.default, style: .continuous)
                .fill(Color.nudgeBgSurface.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: NudgeRadius.default, style: .continuous)
                .stroke(heroTone.opacity(0.18), lineWidth: 1)
        )
    }

    private func heroMetric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgeTextMuted)
                .textCase(.uppercase)

            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.nudgeTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, NudgeSpacing.s3)
        .padding(.vertical, 10)
        .background(Color.nudgeBgSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: NudgeRadius.default, style: .continuous))
    }

    private var heroBackground: LinearGradient {
        LinearGradient(
            colors: [
                heroTone.opacity(0.20),
                Color.nudgeBgSurface,
                Color.nudgeBgSurfaceAlt.opacity(0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var heroTone: Color {
        switch menuBarViewModel.contentState {
        case .focus:
            return Color.nudgeFocus
        case .idleDetected:
            return Color.nudgeFocus.opacity(0.78)
        case .gentleNudge:
            return Color.nudgeFocus
        case .strongNudge:
            return Color.nudgeAlert
        case .recovery:
            return Color.nudgeFocus
        case .break:
            return Color.nudgeRest
        case .remoteEscalation:
            return Color.nudgeAlert
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

    private var statusLine: String {
        if let countdown = menuBarViewModel.countdownText() {
            return countdown
        }

        switch menuBarViewModel.runtimeState {
        case .limitedNoAX:
            return localizedAppString("menu.status.value.runtime.limited_no_ax", defaultValue: "Limited mode")
        case .monitoring:
            return contentStateTitle
        case .pausedManual:
            return localizedAppString("menu.status.value.content.break", defaultValue: "Break")
        case .pausedWhitelist:
            return localizedAppString("menu.status.value.runtime.paused_whitelist", defaultValue: "Whitelist pause")
        case .alerting:
            return localizedAppString("menu.status.value.runtime.alerting", defaultValue: "Alerting")
        case .pausedSchedule:
            return menuBarViewModel.scheduleText
        case .suspendedSleepOrLock:
            return localizedAppString("menu.status.value.runtime.suspended", defaultValue: "Suspended")
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
            return localizedAppString("menu.dropdown.label.schedule", defaultValue: "Schedule") + ": " + menuBarViewModel.scheduleText
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
