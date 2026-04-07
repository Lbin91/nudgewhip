import AppKit
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class SettingsViewModel {
    private static let githubProfileURL = URL(string: "https://github.com/Lbin91")!
    private static let githubRepositoryURL = URL(string: "https://github.com/Lbin91/nudgewhip")!

    private let modelContext: ModelContext
    private let menuBarViewModel: MenuBarViewModel
    private let permissionManager: PermissionManager
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let appUpdater: any AppUpdating
    private let onOpenOnboarding: () -> Void
    private let openExternalURL: (URL) -> Bool
    
    private(set) var permissionState: AccessibilityPermissionState
    private(set) var launchAtLoginEnabled: Bool
    private(set) var idleThresholdSecondsValue: Int
    private(set) var countdownOverlayEnabledValue: Bool
    private(set) var soundThemeValue: SoundTheme
    private(set) var preferredLanguage: AppLanguage
    private(set) var canCheckForUpdates: Bool
    private(set) var errorMessage: String?
    
    init(
        modelContext: ModelContext,
        menuBarViewModel: MenuBarViewModel,
        permissionManager: PermissionManager,
        launchAtLoginManager: LaunchAtLoginManaging,
        appUpdater: any AppUpdating,
        onOpenOnboarding: @escaping () -> Void,
        openExternalURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) }
    ) {
        self.modelContext = modelContext
        self.menuBarViewModel = menuBarViewModel
        self.permissionManager = permissionManager
        self.launchAtLoginManager = launchAtLoginManager
        self.appUpdater = appUpdater
        self.onOpenOnboarding = onOpenOnboarding
        self.openExternalURL = openExternalURL
        self.permissionState = permissionManager.accessibilityPermissionState
        self.launchAtLoginEnabled = launchAtLoginManager.isEnabled
        try? NudgeWhipDataBootstrap.ensureDefaults(in: modelContext)
        let currentSettings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
        self.idleThresholdSecondsValue = currentSettings?.idleThresholdSeconds ?? 180
        self.countdownOverlayEnabledValue = currentSettings?.countdownOverlayEnabled ?? true
        self.soundThemeValue = currentSettings?.soundTheme ?? .whip
        self.preferredLanguage = AppLanguage.resolve(currentSettings?.preferredLocaleIdentifier)
        self.canCheckForUpdates = appUpdater.canCheckForUpdates
        AppLanguageStore.shared.refresh(from: currentSettings)
        menuBarViewModel.refreshMenuSnapshot()

        self.appUpdater.onCanCheckForUpdatesChanged = { [weak self] canCheck in
            self?.canCheckForUpdates = canCheck
        }
    }
    
    var settings: UserSettings? {
        try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
    }
    
    var runtimeState: NudgeWhipRuntimeState {
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

    var isAppUpdaterConfigured: Bool {
        appUpdater.isConfigured
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

    @discardableResult
    func openGitHubProfile() -> Bool {
        openExternalLink(Self.githubProfileURL)
    }

    @discardableResult
    func openGitHubRepository() -> Bool {
        openExternalLink(Self.githubRepositoryURL)
    }
    
    func resetIdleTimer() {
        menuBarViewModel.resetIdleTimer()
    }

    func checkForUpdates() {
        guard appUpdater.isConfigured else {
            errorMessage = localizedAppString(
                "settings.section.app.updates.not_configured",
                defaultValue: "Sparkle is not configured yet. Set SUFeedURL and SUPublicEDKey for this build first."
            )
            return
        }

        appUpdater.checkForUpdates()
        errorMessage = nil
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

    @discardableResult
    private func openExternalLink(_ url: URL) -> Bool {
        let opened = openExternalURL(url)
        errorMessage = opened
            ? nil
            : localizedAppString("settings.section.app.github.error", defaultValue: "Could not open the GitHub link.")
        return opened
    }
}
