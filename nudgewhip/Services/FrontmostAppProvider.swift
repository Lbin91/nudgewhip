import AppKit
import Foundation

@MainActor
protocol FrontmostAppProviding: AnyObject {
    var isMonitoring: Bool { get }
    var currentBundleIdentifier: String? { get }
    func start(onBundleIdentifierChange: @escaping @MainActor (String?) -> Void)
    func stop()
}

@MainActor
final class FrontmostAppProvider: FrontmostAppProviding {
    private let workspace: NSWorkspace
    private let notificationCenter: NotificationCenter
    private var observer: NSObjectProtocol?
    
    init(
        workspace: NSWorkspace = .shared,
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter
    ) {
        self.workspace = workspace
        self.notificationCenter = notificationCenter
    }
    
    var isMonitoring: Bool {
        observer != nil
    }
    
    var currentBundleIdentifier: String? {
        workspace.frontmostApplication?.bundleIdentifier
    }
    
    func start(onBundleIdentifierChange: @escaping @MainActor (String?) -> Void) {
        guard observer == nil else { return }
        
        observer = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            Task { @MainActor in
                onBundleIdentifierChange(application?.bundleIdentifier)
            }
        }
        
        onBundleIdentifierChange(currentBundleIdentifier)
    }
    
    func stop() {
        guard let observer else { return }
        notificationCenter.removeObserver(observer)
        self.observer = nil
    }
    
    deinit {
        if let observer {
            notificationCenter.removeObserver(observer)
        }
    }
}
