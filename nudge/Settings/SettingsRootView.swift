import AppKit
import SwiftUI

struct SettingsRootView: View {
    @Bindable var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
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
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 560, minHeight: 620)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshPermission()
        }
    }
    
    private var monitoringSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text(localizedAppString("settings.section.monitoring.idle_threshold", defaultValue: "Idle threshold"))
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10s", defaultValue: "10 sec"), value: 10)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.3m", defaultValue: "3 min"), value: 180)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.5m", defaultValue: "5 min"), value: 300)
                    thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10m", defaultValue: "10 min"), value: 600)
                }
                
                Toggle(
                    localizedAppString("settings.section.monitoring.tts", defaultValue: "Use voice nudges"),
                    isOn: Binding(
                        get: { viewModel.settings?.ttsEnabled ?? false },
                        set: viewModel.updateTTS
                    )
                )
            }
        } label: {
            Text(localizedAppString("settings.section.monitoring", defaultValue: "Monitoring"))
        }
    }
    
    private var scheduleSection: some View {
        GroupBox {
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
        } label: {
            Text(localizedAppString("settings.section.schedule", defaultValue: "Schedule"))
        }
    }
    
    private var accessibilitySection: some View {
        GroupBox {
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
        } label: {
            Text(localizedAppString("settings.section.accessibility", defaultValue: "Accessibility"))
        }
    }
    
    private var appSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(
                    localizedAppString("settings.section.app.launch_at_login", defaultValue: "Launch at login"),
                    isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: viewModel.updateLaunchAtLogin
                    )
                )
                
                HStack {
                    Button(localizedAppString("settings.section.app.open_onboarding", defaultValue: "Open setup guide")) {
                        viewModel.openOnboarding()
                    }
                    
                    Button(localizedAppString("settings.section.app.reset_idle_timer", defaultValue: "Reset idle timer")) {
                        viewModel.resetIdleTimer()
                    }
                    .disabled(viewModel.runtimeState == .limitedNoAX)
                }
            }
        } label: {
            Text(localizedAppString("settings.section.app", defaultValue: "App"))
        }
    }
    
    private func thresholdButton(title: String, value: Int) -> some View {
        Button {
            viewModel.updateIdleThreshold(value)
        } label: {
            Text(title)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.bordered)
        .tint(viewModel.settings?.idleThresholdSeconds == value ? .accentColor : .secondary)
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
