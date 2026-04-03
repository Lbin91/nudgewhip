import AppKit
import Foundation
import SwiftData

@MainActor
final class NudgeAppController {
    @MainActor static let shared = NudgeAppController()
    
    let menuBarViewModel: MenuBarViewModel
    private let onboardingCoordinator: OnboardingCoordinator
    private let settingsCoordinator: SettingsCoordinator
    private var hasStarted = false
    
    private init() {
        let permissionManager = PermissionManager()
        let alertManager = AlertManager()
        let idleMonitor = IdleMonitor(permissionManager: permissionManager, alertManager: alertManager)
        let menuBarViewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        self.menuBarViewModel = menuBarViewModel
        let modelContext = NudgeModelContainer.shared.mainContext
        
        let onboardingCoordinator = OnboardingCoordinator(
            storage: OnboardingStorage.shared,
            modelContainer: NudgeModelContainer.shared,
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
        
        self.settingsCoordinator = SettingsCoordinator(
            modelContainer: NudgeModelContainer.shared,
            menuBarViewModel: menuBarViewModel,
            permissionManager: permissionManager,
            launchAtLoginManager: LaunchAtLoginManager()
        ) {
            DispatchQueue.main.async {
                onboardingCoordinator.present(startAtWelcome: true)
            }
        }
    }
    
    func startup() {
        guard !hasStarted else { return }
        hasStarted = true
        try? NudgeDataBootstrap.ensureDefaults(in: NudgeModelContainer.shared.mainContext)
        syncPersistedRuntimeState()
        
        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
        }
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
    
    private func startFlow() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else {
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
        menuBarViewModel.refreshMenuSnapshot()
    }
}
