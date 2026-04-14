import SwiftUI

struct QuickControlsView: View {
    let menuBarViewModel: MenuBarViewModel
    let idleThresholdText: String
    let scheduleText: String
    let activePresetName: String
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>
    var onPresetSelected: ((SchedulePreset) -> Void)?

    init(
        menuBarViewModel: MenuBarViewModel,
        idleThresholdText: String,
        scheduleText: String,
        activePresetName: String = "",
        scheduleEnabled: Binding<Bool>,
        scheduleStartTime: Binding<Date>,
        scheduleEndTime: Binding<Date>,
        onPresetSelected: ((SchedulePreset) -> Void)? = nil
    ) {
        self.menuBarViewModel = menuBarViewModel
        self.idleThresholdText = idleThresholdText
        self.scheduleText = scheduleText
        self.activePresetName = activePresetName
        self.scheduleEnabled = scheduleEnabled
        self.scheduleStartTime = scheduleStartTime
        self.scheduleEndTime = scheduleEndTime
        self.onPresetSelected = onPresetSelected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("menu.dropdown.group.settings", defaultValue: "Settings"))
                .font(.caption)
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)
                .padding(.horizontal, NudgeWhipSpacing.s4)

            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
                if menuBarViewModel.shouldShowPermissionCTA {
                    permissionSection
                    Divider().overlay(Color.nudgewhipStrokeDefault)
                }

                settingsRows

                Divider().overlay(Color.nudgewhipStrokeDefault)

                presetRow

                Divider().overlay(Color.nudgewhipStrokeDefault)

                scheduleSection

                Divider().overlay(Color.nudgewhipStrokeDefault)

                actionButtons
            }
            .padding(NudgeWhipSpacing.s4)
            .background(Color.nudgewhipBgSurface)
            .clipShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeWhipRadius.card)
                    .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        }
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            Text(localizedAppString(
                "permission.accessibility.disclosure.primary",
                defaultValue: "Accessibility permission is used only to detect global input activity so NudgeWhip can identify idle periods and show local nudges."
            ))
            .font(.footnote)

            Text(localizedAppString(
                "permission.accessibility.disclosure.secondary",
                defaultValue: "NudgeWhip does not collect keystroke content, screen contents, files, messages, or browsing history."
            ))
            .font(.footnote)
            .foregroundStyle(Color.nudgewhipTextSecondary)

            HStack(spacing: NudgeWhipSpacing.s2) {
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
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            HStack {
                Text(localizedAppString("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                Spacer()
                Text(idleThresholdText)
                    .foregroundStyle(Color.nudgewhipTextPrimary)
            }

            HStack {
                Text(localizedAppString("menu.dropdown.label.schedule", defaultValue: "Schedule"))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                Spacer()
                Text(scheduleText)
                    .foregroundStyle(Color.nudgewhipTextPrimary)
            }
        }
        .font(.subheadline)
    }

    private var presetRow: some View {
        HStack {
            Text(localizedAppString("preset.schedule.active", defaultValue: "Schedule preset"))
                .foregroundStyle(Color.nudgewhipTextSecondary)
            Spacer()
            Text(activePresetName)
                .foregroundStyle(Color.nudgewhipTextPrimary)
        }
        .font(.subheadline)
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            Toggle(
                localizedAppString("menu.dropdown.schedule.enabled", defaultValue: "Use schedule"),
                isOn: scheduleEnabled
            )

            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                HStack {
                    Text(localizedAppString("menu.dropdown.schedule.start", defaultValue: "Start"))
                        .foregroundStyle(Color.nudgewhipTextSecondary)
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
                        .foregroundStyle(Color.nudgewhipTextSecondary)
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
        HStack(spacing: NudgeWhipSpacing.s2) {
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
