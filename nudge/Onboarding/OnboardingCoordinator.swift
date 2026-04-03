import AppKit
import SwiftData
import SwiftUI

@MainActor
final class OnboardingCoordinator: NSObject, NSWindowDelegate {
    private let storage: OnboardingStoring
    private let modelContainer: ModelContainer
    private let permissionManager: PermissionManager
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let onFinish: () -> Void
    
    private var onboardingWindow: NSWindow?
    private var viewModel: OnboardingViewModel?
    private var shouldHandleWindowClose = true
    
    init(
        storage: OnboardingStoring,
        modelContainer: ModelContainer,
        permissionManager: PermissionManager,
        launchAtLoginManager: LaunchAtLoginManaging,
        onFinish: @escaping () -> Void
    ) {
        self.storage = storage
        self.modelContainer = modelContainer
        self.permissionManager = permissionManager
        self.launchAtLoginManager = launchAtLoginManager
        self.onFinish = onFinish
    }
    
    var shouldPresentOnboarding: Bool {
        storage.shouldPresentOnboarding
    }
    
    func present() {
        if let onboardingWindow {
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: modelContainer,
            permissionManager: permissionManager,
            launchAtLoginManager: launchAtLoginManager
        ) { [weak self] in
            self?.dismissAndFinish()
        }
        self.viewModel = viewModel
        
        let rootView = OnboardingRootView(viewModel: viewModel)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = localizedAppString("onboarding.common.window_title", defaultValue: "Nudge Setup")
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self
        window.contentView = NSHostingView(rootView: rootView)
        
        shouldHandleWindowClose = true
        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard shouldHandleWindowClose else {
            onboardingWindow = nil
            viewModel = nil
            return
        }
        
        let shouldStartApp = viewModel?.handleWindowClose() ?? false
        onboardingWindow = nil
        viewModel = nil
        
        if shouldStartApp {
            onFinish()
        }
    }
    
    private func dismissAndFinish() {
        shouldHandleWindowClose = false
        onboardingWindow?.close()
        onboardingWindow = nil
        viewModel = nil
        onFinish()
    }
}
