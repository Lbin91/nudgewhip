import AppKit
import Foundation
import SwiftData

@MainActor
final class NudgeAppController {
    @MainActor static let shared = NudgeAppController()
    
    let menuBarViewModel: MenuBarViewModel
    private let onboardingCoordinator: OnboardingCoordinator
    private var hasStarted = false
    private var didRegisterActivationObserver = false
    
    private init() {
        let permissionManager = PermissionManager()
        let alertManager = AlertManager()
        let idleMonitor = IdleMonitor(permissionManager: permissionManager, alertManager: alertManager)
        let menuBarViewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        self.menuBarViewModel = menuBarViewModel
        
        onboardingCoordinator = OnboardingCoordinator(
            storage: OnboardingStorage.shared,
            modelContainer: NudgeModelContainer.shared,
            permissionManager: permissionManager,
            launchAtLoginManager: LaunchAtLoginManager()
        ) { [weak menuBarViewModel] in
            if let settings = try? NudgeModelContainer.shared.mainContext.fetch(FetchDescriptor<UserSettings>()).first {
                menuBarViewModel?.apply(settings: settings)
            }
            menuBarViewModel?.startIfNeeded()
            menuBarViewModel?.refreshPermission()
        }
    }
    
    func startup() {
        guard !hasStarted else { return }
        hasStarted = true
        try? NudgeDataBootstrap.ensureDefaults(in: NudgeModelContainer.shared.mainContext)
        if let settings = try? NudgeModelContainer.shared.mainContext.fetch(FetchDescriptor<UserSettings>()).first {
            menuBarViewModel.apply(settings: settings)
        }
        registerActivationObserverIfNeeded()
        
        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
        }
    }
    
    func presentOnboarding() {
        let coordinator = onboardingCoordinator
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
    
    private func registerActivationObserverIfNeeded() {
        guard !didRegisterActivationObserver else { return }
        didRegisterActivationObserver = true
        
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak menuBarViewModel] _ in
            menuBarViewModel?.refreshPermission()
        }
    }
}
