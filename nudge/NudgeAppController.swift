import AppKit
import Foundation
import SwiftData

@MainActor
final class NudgeAppController {
    @MainActor static let shared = NudgeAppController()
    
    let menuBarViewModel: MenuBarViewModel
    private let alertManager: AlertManager
    private let onboardingCoordinator: OnboardingCoordinator
    private let settingsCoordinator: SettingsCoordinator
    private var hasStarted = false
    private let countdownOverlayController: CountdownOverlayController?
    
    private init() {
        let permissionManager = PermissionManager()
        let alertManager = AlertManager()
        self.alertManager = alertManager
        let sessionTracker = SessionTracker()
        let idleMonitor = IdleMonitor(permissionManager: permissionManager, alertManager: alertManager, sessionTracker: sessionTracker)
        let menuBarViewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        sessionTracker.onSessionUpdated = { [weak menuBarViewModel] in
            menuBarViewModel?.refreshMenuSnapshot()
        }
        self.menuBarViewModel = menuBarViewModel
        let modelContext = NudgeModelContainer.shared.mainContext
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            self.countdownOverlayController = CountdownOverlayController(menuBarViewModel: menuBarViewModel)
        } else {
            self.countdownOverlayController = nil
        }
        
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
            if let petState = try? modelContext.fetch(FetchDescriptor<PetState>()).first {
                alertManager.update(species: petState.species)
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
        
        resetOnboardingIfFirstLaunch()
        try? NudgeDataBootstrap.ensureDefaults(in: NudgeModelContainer.shared.mainContext)
        syncPersistedRuntimeState()
        
        // 캐릭터 정보 업데이트
        if let petState = try? NudgeModelContainer.shared.mainContext.fetch(FetchDescriptor<PetState>()).first {
            alertManager.update(species: petState.species)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
            self?.countdownOverlayController?.showIfNeeded()
        }
    }
    
    private func resetOnboardingIfFirstLaunch() {
        let context = NudgeModelContainer.shared.mainContext
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
        let settings = try? NudgeModelContainer.shared.mainContext.fetch(FetchDescriptor<UserSettings>()).first
        AppLanguageStore.shared.refresh(from: settings)
        menuBarViewModel.refreshMenuSnapshot()
    }
}
