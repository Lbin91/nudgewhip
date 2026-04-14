import AppKit
import SwiftUI

struct SettingsRootView: View {
    @Bindable var viewModel: SettingsViewModel
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            Color.nudgewhipBgCanvas.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s5) {
                    VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                        Text(localizedAppString("settings.header.title", defaultValue: "Settings"))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.nudgewhipTextPrimary)
                        
                        Text(localizedAppString("settings.header.subtitle", defaultValue: "Adjust monitoring, schedule, alerts, and accessibility outside of onboarding."))
                            .font(.subheadline)
                            .foregroundStyle(Color.nudgewhipTextSecondary)
                    }
                    .padding(.horizontal, NudgeWhipSpacing.s1)
                    
                    VStack(spacing: NudgeWhipSpacing.s4) {
                        monitoringSection
                        scheduleSection
                        recoveryReviewSection
                        petSection
                        accessibilitySection
                        appSection
                    }
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(Color.nudgewhipAlert)
                            .padding(.horizontal, NudgeWhipSpacing.s2)
                    }
                }
                .padding(NudgeWhipSpacing.s5)
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
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.idle_threshold", defaultValue: "Idle threshold"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                    
                    HStack(spacing: NudgeWhipSpacing.s2) {
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10s", defaultValue: "1m"), value: 60)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.3m", defaultValue: "3m"), value: 180)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.5m", defaultValue: "5m"), value: 300)
                        thresholdButton(title: localizedAppString("settings.section.monitoring.idle_threshold.10m", defaultValue: "10m"), value: 600)
                    }
                }

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.sound_theme", defaultValue: "Sound theme"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

                    Picker("", selection: Binding(
                        get: { viewModel.soundThemeValue },
                        set: viewModel.updateSoundTheme
                    )) {
                        Text(localizedAppString("settings.section.monitoring.sound_theme.whip", defaultValue: "Whip!")).tag(SoundTheme.whip)
                        Text(localizedAppString("settings.section.monitoring.sound_theme.normal", defaultValue: "Light")).tag(SoundTheme.normal)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                Toggle(isOn: Binding(
                    get: { viewModel.countdownOverlayEnabledValue },
                    set: viewModel.updateCountdownOverlayEnabled
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.monitoring.overlay", defaultValue: "Show countdown overlay"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.monitoring.overlay.desc", defaultValue: "Visual countdown when idle threshold is reached."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                }
                .toggleStyle(.checkbox)

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.overlay_variant", defaultValue: "Countdown overlay style"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

                    Text(localizedAppString("settings.section.monitoring.overlay_variant.desc", defaultValue: "Choose between the detailed standard overlay and the compact mini overlay."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)

                    Picker("", selection: Binding(
                        get: { viewModel.countdownOverlayVariantValue },
                        set: viewModel.updateCountdownOverlayVariant
                    )) {
                        Text(localizedAppString("settings.section.monitoring.overlay_variant.standard", defaultValue: "Standard"))
                            .tag(CountdownOverlayVariant.standard)
                        Text(localizedAppString("settings.section.monitoring.overlay_variant.mini", defaultValue: "Mini"))
                            .tag(CountdownOverlayVariant.mini)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.overlay_position", defaultValue: "Countdown overlay position"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

                    Text(localizedAppString("settings.section.monitoring.overlay_position.desc", defaultValue: "Pin the countdown overlay to one of the four screen corners."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NudgeWhipSpacing.s2) {
                        overlayPositionButton(
                            title: localizedAppString("settings.section.monitoring.overlay_position.top_left", defaultValue: "Top Left"),
                            position: .topLeft
                        )
                        overlayPositionButton(
                            title: localizedAppString("settings.section.monitoring.overlay_position.top_right", defaultValue: "Top Right"),
                            position: .topRight
                        )
                        overlayPositionButton(
                            title: localizedAppString("settings.section.monitoring.overlay_position.bottom_left", defaultValue: "Bottom Left"),
                            position: .bottomLeft
                        )
                        overlayPositionButton(
                            title: localizedAppString("settings.section.monitoring.overlay_position.bottom_right", defaultValue: "Bottom Right"),
                            position: .bottomRight
                        )
                    }
                }

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.monitoring.overlay_preview", defaultValue: "Overlay preview"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

                    Text(localizedAppString("settings.section.monitoring.overlay_preview.desc", defaultValue: "A lightweight preview of the selected overlay size and corner placement."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)

                    CountdownOverlayPreviewSwatch(
                        isEnabled: viewModel.countdownOverlayEnabledValue,
                        variant: viewModel.countdownOverlayVariantValue,
                        position: viewModel.countdownOverlayPositionValue
                    )
                }

            }
        }
    }
    
    private var scheduleSection: some View {
        SettingsSection(title: localizedAppString("settings.section.schedule", defaultValue: "Schedule"), systemImage: "calendar.badge.clock") {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                Toggle(isOn: Binding(
                    get: { viewModel.scheduleEnabledValue },
                    set: viewModel.updateScheduleEnabled
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.schedule.enabled", defaultValue: "Enable focus hours"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.schedule.enabled.desc", defaultValue: "Only monitor activity during specific times."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                }
                .toggleStyle(.checkbox)
                
                if viewModel.scheduleEnabledValue {
                    HStack(spacing: NudgeWhipSpacing.s4) {
                        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
                            Text(localizedAppString("settings.section.schedule.start", defaultValue: "Start time"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.nudgewhipTextMuted)
                            
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
                        
                        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
                            Text(localizedAppString("settings.section.schedule.end", defaultValue: "End time"))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.nudgewhipTextMuted)
                            
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
                    .padding(NudgeWhipSpacing.s3)
                    .background(Color.nudgewhipBgSurfaceAlt.opacity(0.5), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
                }

                Divider().overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("preset.schedule.manage", defaultValue: "Schedule Presets"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                    Text(localizedAppString("preset.schedule.manage.desc", defaultValue: "Create and switch between monitoring schedules."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)
                }

                secondaryButton(localizedAppString("preset.schedule.manage.button", defaultValue: "Manage Presets"), action: {
                    // Will be wired to open SchedulePresetListView in a sheet
                    // For now, placeholder
                })
            }
        }
    }

    private var recoveryReviewSection: some View {
        SettingsSection(title: localizedAppString("settings.section.recovery", defaultValue: "Recovery Review"), systemImage: "clock.arrow.circlepath") {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedAppString("settings.section.recovery.desc_title", defaultValue: "Understand your distraction patterns"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                    Text(localizedAppString("settings.section.recovery.desc", defaultValue: "See how quickly you recover from distractions and when they happen most."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)
                }

                secondaryButton(localizedAppString("recovery.review.open_button", defaultValue: "View Recovery Review"), action: {
                    // Will be wired to open RecoveryReviewView
                    // For now, placeholder
                })
            }
        }
    }

    private var petSection: some View {
        SettingsSection(title: localizedAppString("settings.section.pet", defaultValue: "Pet"), systemImage: "pawprint.fill") {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localizedAppString("settings.section.pet.desc_title", defaultValue: "Your focus companion"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                    Text(localizedAppString("settings.section.pet.desc", defaultValue: "A virtual pet that grows as you maintain focus. It never punishes — only rewards consistency."))
                        .font(.caption)
                        .foregroundStyle(Color.nudgewhipTextMuted)
                }

                secondaryButton(localizedAppString("settings.section.pet.open", defaultValue: "View Pet Status"), action: {
                    // Will be wired to open PetDetailView
                    // For now, placeholder
                })
            }
        }
    }

    private var accessibilitySection: some View {
        SettingsSection(title: localizedAppString("settings.section.accessibility", defaultValue: "Accessibility"), systemImage: "hand.raised.fill") {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                HStack(spacing: NudgeWhipSpacing.s3) {
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
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                    
                    Spacer()
                    
                    Button(localizedAppString("settings.section.accessibility.refresh", defaultValue: "Check again")) {
                        viewModel.refreshPermission()
                    }
                    .buttonStyle(.link)
                    .font(.caption.weight(.semibold))
                }
                .padding(NudgeWhipSpacing.s3)
                .background(Color.nudgewhipBgSurfaceAlt.opacity(0.4), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
                
                HStack(spacing: NudgeWhipSpacing.s3) {
                    primaryButton(localizedAppString("settings.section.accessibility.request", defaultValue: "Request access"), action: viewModel.requestAccessibilityPermission)
                    
                    secondaryButton(localizedAppString("settings.section.accessibility.open", defaultValue: "Open System Settings"), action: { _ = viewModel.openAccessibilitySettings() })
                }

                if viewModel.permissionState == .denied {
                    VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                        Text(localizedAppString("settings.section.accessibility.recovery.title", defaultValue: "Need a guided recovery path?"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.nudgewhipTextPrimary)

                        Text(localizedAppString("settings.section.accessibility.recovery.body", defaultValue: "Reopen the setup guide to review what limited mode means and where to grant Accessibility permission."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)

                        secondaryButton(localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide"), action: viewModel.openOnboarding)
                    }
                    .padding(NudgeWhipSpacing.s3)
                    .background(Color.nudgewhipAlert.opacity(0.06), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
                }
            }
        }
    }
    
    private var appSection: some View {
        SettingsSection(title: localizedAppString("settings.section.app", defaultValue: "App"), systemImage: "macwindow") {
            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
                    Text(localizedAppString("settings.section.app.language", defaultValue: "Language"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

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
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: viewModel.updateLaunchAtLogin
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.app.launch_at_login", defaultValue: "Launch at login"))
                            .font(.subheadline.weight(.medium))
                        Text(localizedAppString("settings.section.app.launch_at_login.desc", defaultValue: "Automatically start NudgeWhip when you log in."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                }
                .toggleStyle(.checkbox)

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.app.setup", defaultValue: "Setup guide"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.nudgewhipTextPrimary)

                        Text(localizedAppString("settings.section.app.setup.desc", defaultValue: "Reopen onboarding to review defaults, permissions, and limited-mode recovery steps."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }

                    HStack(spacing: NudgeWhipSpacing.s3) {
                        secondaryButton(localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide"), action: viewModel.openOnboarding)
                    }
                }

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.app.updates", defaultValue: "Updates"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.nudgewhipTextPrimary)

                        Text(localizedAppString("settings.section.app.updates.desc", defaultValue: "Check for new versions distributed through Sparkle."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }

                    HStack(spacing: NudgeWhipSpacing.s3) {
                        secondaryButton(localizedAppString("settings.section.app.updates.check", defaultValue: "Check for Updates…"), action: viewModel.checkForUpdates)
                            .disabled(!viewModel.canCheckForUpdates)
                            .opacity(viewModel.canCheckForUpdates ? 1 : 0.55)
                    }

                    if !viewModel.isAppUpdaterConfigured {
                        Text(localizedAppString("settings.section.app.updates.setup_hint", defaultValue: "This build does not have a Sparkle feed configured yet. Add SUFeedURL and SUPublicEDKey to enable update checks."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                }

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault.opacity(0.5))

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizedAppString("settings.section.app.github", defaultValue: "GitHub"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.nudgewhipTextPrimary)

                        Text(localizedAppString("settings.section.app.github.desc", defaultValue: "Open the creator profile or the project repository on GitHub."))
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }

                    HStack(spacing: NudgeWhipSpacing.s3) {
                        secondaryButton(localizedAppString("settings.section.app.github.profile", defaultValue: "@Lbin91"), action: { _ = viewModel.openGitHubProfile() })
                        secondaryButton(localizedAppString("settings.section.app.github.repo", defaultValue: "Project repo"), action: { _ = viewModel.openGitHubRepository() })
                    }
                }
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
                    isSelected ? Color.nudgewhipFocus : Color.nudgewhipBgSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : Color.nudgewhipTextPrimary)
    }

    private func overlayPositionButton(title: String, position: CountdownOverlayPosition) -> some View {
        let isSelected = viewModel.countdownOverlayPositionValue == position
        return Button {
            viewModel.updateCountdownOverlayPosition(position)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Color.nudgewhipFocus : Color.nudgewhipBgSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .white : Color.nudgewhipTextPrimary)
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, NudgeWhipSpacing.s4)
                .padding(.vertical, 10)
                .background(Color.nudgewhipFocus, in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .padding(.horizontal, NudgeWhipSpacing.s4)
                .padding(.vertical, 10)
                .background(Color.nudgewhipBgSurfaceAlt, in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: NudgeWhipRadius.button)
                        .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
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
            return Color.nudgewhipTextMuted
        case .granted:
            return Color.nudgewhipFocus
        case .denied:
            return Color.nudgewhipAlert
        }
    }
}

private struct CountdownOverlayPreviewSwatch: View {
    let isEnabled: Bool
    let variant: CountdownOverlayVariant
    let position: CountdownOverlayPosition

    var body: some View {
        ZStack(alignment: alignment(for: position)) {
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .fill(Color.nudgewhipBgSurfaceAlt.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                        .stroke(Color.nudgewhipStrokeDefault.opacity(0.75), lineWidth: 1)
                )

            Group {
                if isEnabled {
                    overlayChip
                } else {
                    disabledChip
                }
            }
            .padding(12)
        }
        .frame(height: 120)
    }

    private var overlayChip: some View {
        Group {
            switch variant {
            case .standard:
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.14), lineWidth: 1)
                    )
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("NUDGE")
                                .font(.system(size: 5, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.62))
                            Text("3m")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white)
                            Text(localizedAppString("settings.section.monitoring.overlay_preview.standard_hint", defaultValue: "Monitoring input"))
                                .font(.system(size: 5.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .frame(width: 82, height: 46)

            case .mini:
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.56))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .overlay {
                        Text("3m")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 24)
            }
        }
    }

    private var disabledChip: some View {
        Capsule(style: .continuous)
            .fill(Color.nudgewhipBgCanvas.opacity(0.95))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.nudgewhipStrokeDefault.opacity(0.8), lineWidth: 1)
            )
            .overlay {
                Text(localizedAppString("settings.section.monitoring.overlay_preview.off", defaultValue: "Off"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }
            .frame(width: 44, height: 24)
    }

    private func alignment(for position: CountdownOverlayPosition) -> Alignment {
        switch position {
        case .topLeft:
            return .topLeading
        case .topRight:
            return .topTrailing
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            HStack(spacing: NudgeWhipSpacing.s2) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.nudgewhipTextPrimary)
            }
            
            content
        }
        .padding(NudgeWhipSpacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nudgewhipBgSurface, in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .stroke(Color.nudgewhipStrokeDefault.opacity(0.8), lineWidth: 1)
        )
    }
}
