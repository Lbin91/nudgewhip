import AppKit
import Foundation
import SwiftData

@MainActor
final class NudgeWhipAppController {
    @MainActor static let shared = NudgeWhipAppController()
    
    let menuBarViewModel: MenuBarViewModel
    let appUpdater: AppUpdater
    private let alertManager: AlertManager
    private let onboardingCoordinator: OnboardingCoordinator
    private let statisticsCoordinator: StatisticsCoordinator
    private let settingsCoordinator: SettingsCoordinator
    private let dailyAggregateProjectionCoordinator: DailyAggregateProjectionCoordinator?
    private var hasStarted = false
    private let countdownOverlayController: CountdownOverlayController?
    
    private init() {
        let permissionManager = PermissionManager()
        let appUpdater = AppUpdater()
        self.appUpdater = appUpdater
        let alertManager = AlertManager()
        self.alertManager = alertManager
        let modelContext = NudgeWhipModelContainer.shared.mainContext
        let sessionTracker = SessionTracker(modelContext: modelContext)
        let appUsageTracker = AppUsageTracker(modelContext: modelContext)
        let dailyAggregateProjectionCoordinator: DailyAggregateProjectionCoordinator?
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            alertManager: alertManager,
            sessionTracker: sessionTracker,
            appUsageTracker: appUsageTracker
        )
        let menuBarViewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
           let cloudKitContainer = CloudKitConfiguration.makeContainer() {
            dailyAggregateProjectionCoordinator = DailyAggregateProjectionCoordinator(
                builder: DailyAggregateProjectionBuilder(modelContext: modelContext),
                writer: CloudKitDailyAggregateBackupWriter(container: cloudKitContainer),
                deviceIdentityProvider: DeviceIdentityProvider()
            )
        } else {
            dailyAggregateProjectionCoordinator = nil
        }
        sessionTracker.onSessionUpdated = { [weak menuBarViewModel, weak dailyAggregateProjectionCoordinator] in
            menuBarViewModel?.refreshMenuSnapshot()
            dailyAggregateProjectionCoordinator?.handleSessionUpdated()
        }
        appUsageTracker.onUsageUpdated = { [weak menuBarViewModel] in
            menuBarViewModel?.refreshMenuSnapshot()
        }
        self.menuBarViewModel = menuBarViewModel
        self.dailyAggregateProjectionCoordinator = dailyAggregateProjectionCoordinator
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            self.countdownOverlayController = CountdownOverlayController(menuBarViewModel: menuBarViewModel)
        } else {
            self.countdownOverlayController = nil
        }
        
        let onboardingCoordinator = OnboardingCoordinator(
            storage: OnboardingStorage.shared,
            modelContainer: NudgeWhipModelContainer.shared,
            permissionManager: permissionManager,
            launchAtLoginManager: LaunchAtLoginManager()
        ) {
            if let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first {
                menuBarViewModel.apply(settings: settings)
            }
            if let whitelistApps = try? modelContext.fetch(FetchDescriptor<WhitelistApp>()) {
                menuBarViewModel.apply(whitelistApps: whitelistApps)
            }
            menuBarViewModel.startIfNeeded()
            menuBarViewModel.refreshPermission()
        }
        self.onboardingCoordinator = onboardingCoordinator

        self.statisticsCoordinator = StatisticsCoordinator(
            menuBarViewModel: menuBarViewModel
        )

        self.settingsCoordinator = SettingsCoordinator(
            modelContainer: NudgeWhipModelContainer.shared,
            menuBarViewModel: menuBarViewModel,
            permissionManager: permissionManager,
            launchAtLoginManager: LaunchAtLoginManager(),
            appUpdater: appUpdater
        ) {
            DispatchQueue.main.async {
                onboardingCoordinator.present(startAtWelcome: true)
            }
        }
    }
    
    func startup() {
        guard !hasStarted else { return }
        hasStarted = true
        
        resetOnboardingIfFirstLaunch()
        try? NudgeWhipDataBootstrap.ensureDefaults(in: NudgeWhipModelContainer.shared.mainContext)
        syncPersistedRuntimeState()

        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
            self?.dailyAggregateProjectionCoordinator?.start()
            self?.countdownOverlayController?.showIfNeeded()
        }
    }
    
    private func resetOnboardingIfFirstLaunch() {
        let context = NudgeWhipModelContainer.shared.mainContext
        let hasExistingSettings: Bool = {
            (try? context.fetch(FetchDescriptor<UserSettings>()).first) != nil
        }()
        
        let forceReset = ProcessInfo.processInfo.environment["NUDGE_RESET_ON_LAUNCH"] == "1"
        
        guard forceReset || !hasExistingSettings else { return }
        OnboardingStorage.shared.reset()
    }
    
    func presentOnboarding() {
        let coordinator = onboardingCoordinator
        DispatchQueue.main.async {
            coordinator.present(startAtWelcome: true)
        }
    }
    
    func presentSettings() {
        let coordinator = settingsCoordinator
        DispatchQueue.main.async {
            coordinator.present()
        }
    }

    func presentStatistics() {
        let coordinator = statisticsCoordinator
        DispatchQueue.main.async {
            coordinator.present()
        }
    }
    
    private func startFlow() {
        let isRunningUnderTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let forcesOnboardingInUITests = ProcessInfo.processInfo.environment["NUDGE_UI_TEST_ONBOARDING"] == "1"

        guard !isRunningUnderTests || forcesOnboardingInUITests else {
            menuBarViewModel.startIfNeeded()
            return
        }

        if onboardingCoordinator.shouldPresentOnboarding {
            onboardingCoordinator.present()
        } else {
            menuBarViewModel.startIfNeeded()
        }
    }
    
    private func syncPersistedRuntimeState() {
        let settings = try? NudgeWhipModelContainer.shared.mainContext.fetch(FetchDescriptor<UserSettings>()).first
        AppLanguageStore.shared.refresh(from: settings)
        menuBarViewModel.refreshMenuSnapshot()
    }
}
