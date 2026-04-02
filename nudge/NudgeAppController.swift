import Foundation

@MainActor
final class NudgeAppController {
    static let shared = NudgeAppController()
    
    let menuBarViewModel: MenuBarViewModel
    private let onboardingCoordinator: OnboardingCoordinator
    private var hasStarted = false
    
    private init() {
        let permissionManager = PermissionManager()
        let idleMonitor = IdleMonitor(permissionManager: permissionManager)
        let menuBarViewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        self.menuBarViewModel = menuBarViewModel
        
        onboardingCoordinator = OnboardingCoordinator(
            storage: OnboardingStorage.shared,
            modelContainer: NudgeModelContainer.shared,
            permissionManager: permissionManager,
            launchAtLoginManager: LaunchAtLoginManager()
        ) { [weak menuBarViewModel] in
            menuBarViewModel?.startIfNeeded()
            menuBarViewModel?.refreshPermission()
        }
    }
    
    func startup() {
        guard !hasStarted else { return }
        hasStarted = true
        
        DispatchQueue.main.async { [weak self] in
            self?.startFlow()
        }
    }
    
    func presentOnboarding() {
        onboardingCoordinator.present()
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
}
