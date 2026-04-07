import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    private let modelContext: ModelContext
    private let menuBarViewModel: MenuBarViewModel
    private let permissionManager: PermissionManager
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let onOpenOnboarding: () -> Void
    
    private(set) var permissionState: AccessibilityPermissionState
    private(set) var launchAtLoginEnabled: Bool
    private(set) var idleThresholdSecondsValue: Int
    private(set) var countdownOverlayEnabledValue: Bool
    private(set) var soundThemeValue: SoundTheme
    private(set) var preferredLanguage: AppLanguage
    private(set) var errorMessage: String?
    
    init(
        modelContext: ModelContext,
        menuBarViewModel: MenuBarViewModel,
        permissionManager: PermissionManager,
        launchAtLoginManager: LaunchAtLoginManaging,
        onOpenOnboarding: @escaping () -> Void
    ) {
        self.modelContext = modelContext
        self.menuBarViewModel = menuBarViewModel
        self.permissionManager = permissionManager
        self.launchAtLoginManager = launchAtLoginManager
        self.onOpenOnboarding = onOpenOnboarding
        self.permissionState = permissionManager.accessibilityPermissionState
        self.launchAtLoginEnabled = launchAtLoginManager.isEnabled
        try? NudgeDataBootstrap.ensureDefaults(in: modelContext)
        let currentSettings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
        self.idleThresholdSecondsValue = currentSettings?.idleThresholdSeconds ?? 180
        self.countdownOverlayEnabledValue = currentSettings?.countdownOverlayEnabled ?? true
        self.soundThemeValue = currentSettings?.soundTheme ?? .whip
        self.preferredLanguage = AppLanguage.resolve(currentSettings?.preferredLocaleIdentifier)
        AppLanguageStore.shared.refresh(from: currentSettings)
        menuBarViewModel.refreshMenuSnapshot()
    }
    
    var settings: UserSettings? {
        try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
    }
    
    var runtimeState: NudgeRuntimeState {
        menuBarViewModel.runtimeState
    }
    
    var scheduleEnabledValue: Bool {
        menuBarViewModel.scheduleEnabled
    }
    
    var scheduleStartTimeValue: Date {
        menuBarViewModel.scheduleStartTime
    }
    
    var scheduleEndTimeValue: Date {
        menuBarViewModel.scheduleEndTime
    }
    
    func refreshPermission() {
        permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: false)
        menuBarViewModel.refreshPermission()
        menuBarViewModel.refreshMenuSnapshot()
        refreshSettingsSnapshot()
    }
    
    func requestAccessibilityPermission() {
        permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: true)
        menuBarViewModel.requestAccessibilityPermission()
        menuBarViewModel.refreshMenuSnapshot()
        refreshSettingsSnapshot()
    }
    
    @discardableResult
    func openAccessibilitySettings() -> Bool {
        permissionManager.openAccessibilitySettings()
    }
    
    func openOnboarding() {
        onOpenOnboarding()
    }
    
    func resetIdleTimer() {
        menuBarViewModel.resetIdleTimer()
    }
    
    func updateIdleThreshold(_ value: Int) {
        idleThresholdSecondsValue = value
        guard let settings else { return }
        settings.idleThresholdSeconds = value
        settings.updatedAt = .now
        save(settings)
    }

    func updateCountdownOverlayEnabled(_ enabled: Bool) {
        countdownOverlayEnabledValue = enabled
        menuBarViewModel.updateCountdownOverlayEnabled(enabled)
        refreshSettingsSnapshot()
    }

    func updateSoundTheme(_ theme: SoundTheme) {
        soundThemeValue = theme
        guard let settings else { return }
        settings.soundTheme = theme
        settings.updatedAt = .now
        save(settings)
    }

    func updatePreferredLanguage(_ language: AppLanguage) {
        preferredLanguage = language
        AppLanguageStore.shared.apply(preferredLocaleIdentifier: language.rawValue)
        guard let settings else {
            menuBarViewModel.refreshMenuSnapshot()
            return
        }
        settings.preferredLocaleIdentifier = language.rawValue
        settings.updatedAt = .now
        save(settings)
    }
    
    func updateScheduleEnabled(_ enabled: Bool) {
        menuBarViewModel.updateScheduleEnabled(enabled)
    }
    
    func updateScheduleStartTime(_ date: Date) {
        menuBarViewModel.updateScheduleStartTime(date)
    }
    
    func updateScheduleEndTime(_ date: Date) {
        menuBarViewModel.updateScheduleEndTime(date)
    }
    
    func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = enabled
            errorMessage = nil
        } catch {
            launchAtLoginEnabled = launchAtLoginManager.isEnabled
            errorMessage = error.localizedDescription
        }
    }
    
    private func save(_ settings: UserSettings) {
        do {
            try modelContext.save()
            errorMessage = nil
            refreshSettingsSnapshot(from: settings)
            menuBarViewModel.apply(settings: settings)
            menuBarViewModel.refreshMenuSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func refreshSettingsSnapshot(from settings: UserSettings? = nil) {
        let resolvedSettings = settings ?? self.settings
        idleThresholdSecondsValue = resolvedSettings?.idleThresholdSeconds ?? idleThresholdSecondsValue
        countdownOverlayEnabledValue = resolvedSettings?.countdownOverlayEnabled ?? countdownOverlayEnabledValue
        soundThemeValue = resolvedSettings?.soundTheme ?? soundThemeValue
        preferredLanguage = AppLanguage.resolve(resolvedSettings?.preferredLocaleIdentifier)
    }
}
