import SwiftUI

struct QuickControlsView: View {
    let menuBarViewModel: MenuBarViewModel
    let idleThresholdText: String
    let scheduleText: String
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s3) {
            Text(localizedAppString("menu.dropdown.group.settings", defaultValue: "Settings"))
                .font(.caption)
                .foregroundStyle(Color.nudgeTextMuted)
                .textCase(.uppercase)
                .padding(.horizontal, NudgeSpacing.s4)

            VStack(alignment: .leading, spacing: NudgeSpacing.s3) {
                if menuBarViewModel.shouldShowPermissionCTA {
                    permissionSection
                    Divider().overlay(Color.nudgeStrokeDefault)
                }

                settingsRows

                Divider().overlay(Color.nudgeStrokeDefault)

                scheduleSection

                Divider().overlay(Color.nudgeStrokeDefault)

                actionButtons
            }
            .padding(NudgeSpacing.s4)
            .background(Color.nudgeBgSurface)
            .clipShape(RoundedRectangle(cornerRadius: NudgeRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeRadius.card)
                    .stroke(Color.nudgeStrokeDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        }
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            Text(localizedAppString(
                "permission.accessibility.disclosure.primary",
                defaultValue: "Accessibility permission is used only to detect global input activity so Nudge can identify idle periods and show local nudges."
            ))
            .font(.footnote)

            Text(localizedAppString(
                "permission.accessibility.disclosure.secondary",
                defaultValue: "Nudge does not collect keystroke content, screen contents, files, messages, or browsing history."
            ))
            .font(.footnote)
            .foregroundStyle(Color.nudgeTextSecondary)

            HStack(spacing: NudgeSpacing.s2) {
                Button(localizedAppString("permission.accessibility.cta.request", defaultValue: "Request access")) {
                    menuBarViewModel.requestAccessibilityPermission()
                }

                Button(localizedAppString("permission.accessibility.cta.open_settings", defaultValue: "Open Settings")) {
                    _ = menuBarViewModel.openAccessibilitySettings()
                }
            }
        }
    }

    private var settingsRows: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            HStack {
                Text(localizedAppString("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"))
                    .foregroundStyle(Color.nudgeTextSecondary)
                Spacer()
                Text(idleThresholdText)
                    .foregroundStyle(Color.nudgeTextPrimary)
            }

            HStack {
                Text(localizedAppString("menu.dropdown.label.schedule", defaultValue: "Schedule"))
                    .foregroundStyle(Color.nudgeTextSecondary)
                Spacer()
                Text(scheduleText)
                    .foregroundStyle(Color.nudgeTextPrimary)
            }
        }
        .font(.subheadline)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            Toggle(
                localizedAppString("menu.dropdown.schedule.enabled", defaultValue: "Use schedule"),
                isOn: scheduleEnabled
            )

            VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
                HStack {
                    Text(localizedAppString("menu.dropdown.schedule.start", defaultValue: "Start"))
                        .foregroundStyle(Color.nudgeTextSecondary)
                        .font(.caption)
                    Spacer()
                    DatePicker(
                        "",
                        selection: scheduleStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .disabled(!scheduleEnabled.wrappedValue)
                }

                HStack {
                    Text(localizedAppString("menu.dropdown.schedule.end", defaultValue: "End"))
                        .foregroundStyle(Color.nudgeTextSecondary)
                        .font(.caption)
                    Spacer()
                    DatePicker(
                        "",
                        selection: scheduleEndTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .disabled(!scheduleEnabled.wrappedValue)
                }
            }
            .opacity(scheduleEnabled.wrappedValue ? 1.0 : 0.5)
        }
        .font(.subheadline)
    }

    private var actionButtons: some View {
        HStack(spacing: NudgeSpacing.s2) {
            Button(localizedAppString("menu.quick.action.refresh_permission", defaultValue: "Refresh permission")) {
                menuBarViewModel.refreshPermission()
            }

            Button(localizedAppString("menu.quick.action.reset_timer", defaultValue: "Reset timer")) {
                menuBarViewModel.resetIdleTimer()
            }
            .disabled(menuBarViewModel.runtimeState == .limitedNoAX)
        }
        .font(.subheadline)
    }
}
