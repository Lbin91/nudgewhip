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
        
        let rootView = OnboardingRootView(viewModel: viewModel) { [weak self] preferredHeight in
            self?.resizeWindow(toContentHeight: preferredHeight)
        }
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: OnboardingWindowMetrics.contentWidth,
                height: viewModel.preferredContentHeight
            ),
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
        resizeWindow(toContentHeight: viewModel.preferredContentHeight, animated: false)
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
    
    private func resizeWindow(toContentHeight height: CGFloat, animated: Bool = true) {
        guard let onboardingWindow else { return }
        
        let targetContentRect = NSRect(
            x: 0,
            y: 0,
            width: OnboardingWindowMetrics.contentWidth,
            height: height
        )
        let targetFrame = onboardingWindow.frameRect(forContentRect: targetContentRect)
        var newFrame = onboardingWindow.frame
        newFrame.origin.y += newFrame.height - targetFrame.height
        newFrame.size = targetFrame.size
        onboardingWindow.setFrame(newFrame, display: true, animate: animated)
    }
}
