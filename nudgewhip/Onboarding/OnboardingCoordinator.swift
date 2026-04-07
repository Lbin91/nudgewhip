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
    private var lastAppliedContentHeight: CGFloat?
    
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
    
    func present(startAtWelcome: Bool = false) {
        if let onboardingWindow {
            if startAtWelcome {
                viewModel?.restartFromWelcome()
                resizeWindow(toContentHeight: viewModel?.preferredContentHeight ?? OnboardingWindowMetrics.minimumContentHeight, animated: false)
            }
            onboardingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        if startAtWelcome {
            storage.saveResumeStep(.welcome)
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
        let initialHeight = clampedContentHeight(for: viewModel.preferredContentHeight)
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: OnboardingWindowMetrics.contentWidth,
                height: initialHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = localizedAppString("onboarding.common.window_title", defaultValue: "NudgeWhip Setup")
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: OnboardingWindowMetrics.contentWidth, height: OnboardingWindowMetrics.minimumContentHeight)
        window.contentMaxSize = NSSize(width: OnboardingWindowMetrics.contentWidth, height: clampedContentHeight(for: OnboardingWindowMetrics.maximumContentHeight))
        window.center()
        window.delegate = self
        window.contentView = NSHostingView(rootView: rootView)
        
        shouldHandleWindowClose = true
        onboardingWindow = window
        lastAppliedContentHeight = initialHeight
        resizeWindow(toContentHeight: initialHeight, animated: false)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        guard shouldHandleWindowClose else {
            onboardingWindow = nil
            viewModel = nil
            lastAppliedContentHeight = nil
            return
        }
        
        let shouldStartApp = viewModel?.handleWindowClose() ?? false
        onboardingWindow = nil
        viewModel = nil
        lastAppliedContentHeight = nil
        
        if shouldStartApp {
            onFinish()
        }
    }
    
    private func dismissAndFinish() {
        shouldHandleWindowClose = false
        onboardingWindow?.close()
        onboardingWindow = nil
        viewModel = nil
        lastAppliedContentHeight = nil
        onFinish()
    }
    
    private func resizeWindow(toContentHeight height: CGFloat, animated: Bool = true) {
        guard let onboardingWindow else { return }
        
        let clampedHeight = clampedContentHeight(for: height)
        if let lastAppliedContentHeight, abs(lastAppliedContentHeight - clampedHeight) < 0.5 {
            return
        }
        lastAppliedContentHeight = clampedHeight
        
        let targetContentRect = NSRect(
            x: 0,
            y: 0,
            width: OnboardingWindowMetrics.contentWidth,
            height: clampedHeight
        )
        let targetFrame = onboardingWindow.frameRect(forContentRect: targetContentRect)
        var newFrame = onboardingWindow.frame
        newFrame.origin.y += newFrame.height - targetFrame.height
        newFrame.size = targetFrame.size
        onboardingWindow.setFrame(newFrame, display: true, animate: animated)
    }
    
    private func clampedContentHeight(for height: CGFloat) -> CGFloat {
        OnboardingWindowMetrics.clampedContentHeight(height, visibleFrameHeight: onboardingWindow?.screen?.visibleFrame.height ?? NSScreen.main?.visibleFrame.height)
    }
}
