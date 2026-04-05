import AppKit
import SwiftUI

struct SettingsRootView: View {
    @Bindable var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(localizedAppString("settings.header.title", defaultValue: "Settings"))
                    .font(.system(size: 28, weight: .bold))
                
                Text(localizedAppString("settings.header.subtitle", defaultValue: "Adjust monitoring, schedule, alerts, and accessibility outside of onboarding."))
                    .foregroundStyle(.secondary)
                
                monitoringSection
                scheduleSection
                accessibilitySection
                appSection
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 560, minHeight: 540)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshPermission()
        }
    }
    
    private var monitoringSection: some View {
        SettingsSection(title: localizedAppString("settings.section.monitoring", defaultValue: "Monitoring")) {
            VStack(alignment: .leading, spacing: 12) {
                Text(localizedAppString("settings.section.monitoring.idle_threshold", defaultValue: "Idle threshold"))
                    .font(.headline)
                
                HStack(spacing: 8) {
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10s", defaultValue: "10 sec"), value: 10)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.3m", defaultValue: "3 min"), value: 180)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.5m", defaultValue: "5 min"), value: 300)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10m", defaultValue: "10 min"), value: 600)
                }
                
                Toggle(
                    localizedAppString("settings.section.monitoring.tts", defaultValue: "Use voice nudges"),
                    isOn: Binding(
                        get: { viewModel.ttsEnabledValue },
                        set: viewModel.updateTTS
                    )
                )

                Toggle(
                    localizedAppString("settings.section.monitoring.overlay", defaultValue: "Show top countdown overlay"),
                    isOn: Binding(
                        get: { viewModel.countdownOverlayEnabledValue },
                        set: viewModel.updateCountdownOverlayEnabled
                    )
                )
            }
        }
    }
    
    private var scheduleSection: some View {
        SettingsSection(title: localizedAppString("settings.section.schedule", defaultValue: "Schedule")) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    localizedAppString("settings.section.schedule.enabled", defaultValue: "Use schedule"),
                    isOn: Binding(
                        get: { viewModel.scheduleEnabledValue },
                        set: viewModel.updateScheduleEnabled
                    )
                )
                
                HStack {
                    Text(localizedAppString("settings.section.schedule.start", defaultValue: "Start"))
                        .foregroundStyle(.secondary)
                    Spacer()
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
                    .disabled(!viewModel.scheduleEnabledValue)
                }
                
                HStack {
                    Text(localizedAppString("settings.section.schedule.end", defaultValue: "End"))
                        .foregroundStyle(.secondary)
                    Spacer()
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
                    .disabled(!viewModel.scheduleEnabledValue)
                }
            }
        }
    }
    
    private var accessibilitySection: some View {
        SettingsSection(title: localizedAppString("settings.section.accessibility", defaultValue: "Accessibility")) {
            VStack(alignment: .leading, spacing: 12) {
                Label(permissionStatusText, systemImage: permissionStatusIcon)
                    .font(.headline)
                    .foregroundStyle(permissionStatusColor)
                
                Text(localizedAppString("settings.section.accessibility.body", defaultValue: "Accessibility permission is required for global idle detection outside of the app window."))
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button(localizedAppString("settings.section.accessibility.request", defaultValue: "Request access")) {
                        viewModel.requestAccessibilityPermission()
                    }
                    
                    Button(localizedAppString("settings.section.accessibility.open", defaultValue: "Open Settings")) {
                        _ = viewModel.openAccessibilitySettings()
                    }
                    
                    Button(localizedAppString("settings.section.accessibility.refresh", defaultValue: "Refresh")) {
                        viewModel.refreshPermission()
                    }
                }
            }
        }
    }
    
    private var appSection: some View {
        SettingsSection(title: localizedAppString("settings.section.app", defaultValue: "App"), showsDivider: false) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizedAppString("settings.section.app.language", defaultValue: "Language"))
                        .foregroundStyle(.secondary)

                    Picker(
                        localizedAppString("settings.section.app.language", defaultValue: "Language"),
                        selection: Binding(
                            get: { viewModel.preferredLanguage },
                            set: viewModel.updatePreferredLanguage
                        )
                    ) {
                        ForEach(AppLanguage.allCases, id: \.rawValue) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Toggle(
                    localizedAppString("settings.section.app.launch_at_login", defaultValue: "Launch at login"),
                    isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: viewModel.updateLaunchAtLogin
                    )
                )
            }
        }
    }
    
    private func thresholdButton(title: String, value: Int) -> some View {
        let isSelected = viewModel.idleThresholdSecondsValue == value
        return Button {
            viewModel.updateIdleThreshold(value)
        } label: {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
    
    private var permissionStatusText: String {
        switch viewModel.permissionState {
        case .unknown:
            return localizedAppString("settings.section.accessibility.status.unknown", defaultValue: "Not checked")
        case .granted:
            return localizedAppString("settings.section.accessibility.status.granted", defaultValue: "Granted")
        case .denied:
            return localizedAppString("settings.section.accessibility.status.denied", defaultValue: "Needed")
        }
    }
    
    private var permissionStatusIcon: String {
        switch viewModel.permissionState {
        case .unknown:
            return "questionmark.circle"
        case .granted:
            return "checkmark.circle.fill"
        case .denied:
            return "hand.raised.fill"
        }
    }
    
    private var permissionStatusColor: Color {
        switch viewModel.permissionState {
        case .unknown:
            return .secondary
        case .granted:
            return .green
        case .denied:
            return .orange
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let showsDivider: Bool
    @ViewBuilder let content: Content
    
    init(title: String, showsDivider: Bool = true, @ViewBuilder content: () -> Content) {
        self.title = title
        self.showsDivider = showsDivider
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content
            
            if showsDivider {
                Divider()
                    .padding(.top, 4)
            }
        }
    }
}
