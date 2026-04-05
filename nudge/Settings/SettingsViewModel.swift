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
    private(set) var ttsEnabledValue: Bool
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
        self.idleThresholdSecondsValue = currentSettings?.idleThresholdSeconds ?? 300
        self.ttsEnabledValue = currentSettings?.ttsEnabled ?? true
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
    
    func updateTTS(_ enabled: Bool) {
        guard let settings else { return }
        settings.ttsEnabled = enabled
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
        ttsEnabledValue = resolvedSettings?.ttsEnabled ?? ttsEnabledValue
    }
}
