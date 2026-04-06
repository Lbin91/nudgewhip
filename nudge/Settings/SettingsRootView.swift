import AppKit
import SwiftUI

struct SettingsRootView: View {
    @Bindable var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.nudgeBgCanvas.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: NudgeSpacing.s5) {
                    VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
                        Text(localizedAppString("settings.header.title", defaultValue: "Settings"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.nudgeTextPrimary)
                        
                        Text(localizedAppString("settings.header.subtitle", defaultValue: "Adjust monitoring, schedule, alerts, and accessibility outside of onboarding."))
                            .font(.subheadline)
                            .foregroundStyle(Color.nudgeTextSecondary)
                    }
                    .padding(.horizontal, NudgeSpacing.s1)
                    
                    VStack(spacing: NudgeSpacing.s4) {
                        monitoringSection
                        scheduleSection
                        accessibilitySection
                        appSection
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.nudgeAlert)
                            .padding(.horizontal, NudgeSpacing.s2)
                    }
                }
                .padding(NudgeSpacing.s5)
                .frame(maxWidth: 800, alignment: .leading)
            }
        }
        .frame(minWidth: 620, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshPermission()
        }
    }
    
    private var monitoringSection: some View {
        SettingsSection(title: localizedAppString("settings.section.monitoring", defaultValue: "Monitoring"), systemImage: "timer") {
            VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
                VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.idle_threshold", defaultValue: "Idle threshold"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgeTextPrimary)
                    
                    HStack(spacing: NudgeSpacing.s2) {
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10s", defaultValue: "1m"), value: 60)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.3m", defaultValue: "3m"), value: 180)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.5m", defaultValue: "5m"), value: 300)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10m", defaultValue: "10m"), value: 600)
                    }
                }

                Divider()
                    .overlay(Color.nudgeStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.sound_theme", defaultValue: "Sound theme"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgeTextPrimary)

                    Picker("", selection: Binding(
                        get: { viewModel.soundThemeValue },
                        set: viewModel.updateSoundTheme
                    )) {
                        Text(localizedAppString("settings.section.monitoring.sound_theme.normal", defaultValue: "Normal")).tag(SoundTheme.normal)
                        Text(localizedAppString("settings.section.monitoring.sound_theme.whip", defaultValue: "Whip!")).tag(SoundTheme.whip)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()
                    .overlay(Color.nudgeStrokeDefault.opacity(0.5))

                Toggle(isOn: Binding(
                    get: { viewModel.countdownOverlayEnabledValue },
                    set: viewModel.updateCountdownOverlayEnabled
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.monitoring.overlay", defaultValue: "Show top countdown overlay"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.monitoring.overlay.desc", defaultValue: "Visual countdown when idle threshold is reached."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgeTextMuted)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
    }
    
    private var scheduleSection: some View {
        SettingsSection(title: localizedAppString("settings.section.schedule", defaultValue: "Schedule"), systemImage: "calendar.badge.clock") {
            VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
                Toggle(isOn: Binding(
                    get: { viewModel.scheduleEnabledValue },
                    set: viewModel.updateScheduleEnabled
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.schedule.enabled", defaultValue: "Enable focus hours"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.schedule.enabled.desc", defaultValue: "Only monitor activity during specific times."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgeTextMuted)
                    }
                }
                .toggleStyle(.checkbox)
                
                if viewModel.scheduleEnabledValue {
                    HStack(spacing: NudgeSpacing.s4) {
                        VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
                            Text(localizedAppString("settings.section.schedule.start", defaultValue: "Start time"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.nudgeTextMuted)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { viewModel.scheduleStartTimeValue },
                                    set: viewModel.updateScheduleStartTime
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        
                        VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
                            Text(localizedAppString("settings.section.schedule.end", defaultValue: "End time"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.nudgeTextMuted)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { viewModel.scheduleEndTimeValue },
                                    set: viewModel.updateScheduleEndTime
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                        }
                        
                        Spacer()
                    }
                    .padding(NudgeSpacing.s3)
                    .background(Color.nudgeBgSurfaceAlt.opacity(0.5), in: RoundedRectangle(cornerRadius: NudgeRadius.button))
                }
            }
        }
    }
    
    private var accessibilitySection: some View {
        SettingsSection(title: localizedAppString("settings.section.accessibility", defaultValue: "Accessibility"), systemImage: "hand.raised.fill") {
            VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
                HStack(spacing: NudgeSpacing.s3) {
                    Image(systemName: permissionStatusIcon)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(permissionStatusColor)
                        .frame(width: 32, height: 32)
                        .background(permissionStatusColor.opacity(0.12), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(permissionStatusText)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(permissionStatusColor)
                        
                        Text(localizedAppString("settings.section.accessibility.body", defaultValue: "Required for global idle detection."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgeTextMuted)
                    }
                    
                    Spacer()
                    
                    Button(localizedAppString("settings.section.accessibility.refresh", defaultValue: "Check again")) {
                        viewModel.refreshPermission()
                    }
                    .buttonStyle(.link)
                    .font(.caption.weight(.semibold))
                }
                .padding(NudgeSpacing.s3)
                .background(Color.nudgeBgSurfaceAlt.opacity(0.4), in: RoundedRectangle(cornerRadius: NudgeRadius.button))
                
                HStack(spacing: NudgeSpacing.s3) {
                    primaryButton(localizedAppString("settings.section.accessibility.request", defaultValue: "Request access"), action: viewModel.requestAccessibilityPermission)
                    
                    secondaryButton(localizedAppString("settings.section.accessibility.open", defaultValue: "Open System Settings"), action: { _ = viewModel.openAccessibilitySettings() })
                }
            }
        }
    }
    
    private var appSection: some View {
        SettingsSection(title: localizedAppString("settings.section.app", defaultValue: "App"), systemImage: "macwindow") {
            VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
                VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
                    Text(localizedAppString("settings.section.app.language", defaultValue: "Language"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgeTextPrimary)

                    Picker("", selection: Binding(
                        get: { viewModel.preferredLanguage },
                        set: viewModel.updatePreferredLanguage
                    )) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()
                    .overlay(Color.nudgeStrokeDefault.opacity(0.5))

                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: viewModel.updateLaunchAtLogin
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.app.launch_at_login", defaultValue: "Launch at login"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.app.launch_at_login.desc", defaultValue: "Automatically start NudgeWhip when you log in."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgeTextMuted)
                    }
                }
                .toggleStyle(.checkbox)
            }
        }
    }
    
    private func thresholdButton(title: String, value: Int) -> some View {
        let isSelected = viewModel.idleThresholdSecondsValue == value
        return Button {
            viewModel.updateIdleThreshold(value)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.nudgeFocus : Color.nudgeBgSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: NudgeRadius.button, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: NudgeRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : Color.nudgeTextPrimary)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, NudgeSpacing.s4)
                .padding(.vertical, 10)
                .background(Color.nudgeFocus, in: RoundedRectangle(cornerRadius: NudgeRadius.button))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nudgeTextPrimary)
                .padding(.horizontal, NudgeSpacing.s4)
                .padding(.vertical, 10)
                .background(Color.nudgeBgSurfaceAlt, in: RoundedRectangle(cornerRadius: NudgeRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: NudgeRadius.button)
                        .stroke(Color.nudgeStrokeDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var permissionStatusText: String {
        switch viewModel.permissionState {
        case .unknown:
            return localizedAppString("settings.section.accessibility.status.unknown", defaultValue: "Not checked")
        case .granted:
            return localizedAppString("settings.section.accessibility.status.granted", defaultValue: "Permission granted")
        case .denied:
            return localizedAppString("settings.section.accessibility.status.denied", defaultValue: "Permission needed")
        }
    }
    
    private var permissionStatusIcon: String {
        switch viewModel.permissionState {
        case .unknown:
            return "questionmark.circle.fill"
        case .granted:
            return "checkmark.seal.fill"
        case .denied:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var permissionStatusColor: Color {
        switch viewModel.permissionState {
        case .unknown:
            return Color.nudgeTextMuted
        case .granted:
            return Color.nudgeFocus
        case .denied:
            return Color.nudgeAlert
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
            HStack(spacing: NudgeSpacing.s2) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nudgeTextSecondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.nudgeTextPrimary)
            }
            
            content
        }
        .padding(NudgeSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nudgeBgSurface, in: RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous)
                .stroke(Color.nudgeStrokeDefault.opacity(0.8), lineWidth: 1)
        )
    }
}
