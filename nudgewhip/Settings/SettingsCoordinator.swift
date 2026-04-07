import AppKit
import SwiftUI
import SwiftData

@MainActor
final class SettingsCoordinator: NSObject, NSWindowDelegate {
    private let modelContainer: ModelContainer
    private let menuBarViewModel: MenuBarViewModel
    private let permissionManager: PermissionManager
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let appUpdater: any AppUpdating
    private let onOpenOnboarding: () -> Void
    
    private var settingsWindow: NSWindow?
    
    init(
        modelContainer: ModelContainer,
        menuBarViewModel: MenuBarViewModel,
        permissionManager: PermissionManager,
        launchAtLoginManager: LaunchAtLoginManaging,
        appUpdater: any AppUpdating,
        onOpenOnboarding: @escaping () -> Void
    ) {
        self.modelContainer = modelContainer
        self.menuBarViewModel = menuBarViewModel
        self.permissionManager = permissionManager
        self.launchAtLoginManager = launchAtLoginManager
        self.appUpdater = appUpdater
        self.onOpenOnboarding = onOpenOnboarding
    }
    
    func present() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let viewModel = SettingsViewModel(
            modelContext: modelContainer.mainContext,
            menuBarViewModel: menuBarViewModel,
            permissionManager: permissionManager,
            launchAtLoginManager: launchAtLoginManager,
            appUpdater: appUpdater,
            onOpenOnboarding: onOpenOnboarding
        )
        let rootView = SettingsRootView(viewModel: viewModel)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = localizedAppString("settings.window.title", defaultValue: "Settings")
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self
        window.contentView = NSHostingView(rootView: rootView)
        
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
