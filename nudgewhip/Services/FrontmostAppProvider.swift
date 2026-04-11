import AppKit
import Foundation

struct FrontmostAppSnapshot: Equatable, Sendable {
    let bundleIdentifier: String?
    let localizedName: String?
    let processIdentifier: pid_t?

    init(
        bundleIdentifier: String?,
        localizedName: String?,
        processIdentifier: pid_t?
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.processIdentifier = processIdentifier
    }

    init(application: NSRunningApplication?) {
        self.init(
            bundleIdentifier: application?.bundleIdentifier,
            localizedName: application?.localizedName,
            processIdentifier: application?.processIdentifier
        )
    }

    var hasIdentity: Bool {
        let hasBundleIdentifier = !(bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let hasLocalizedName = !(localizedName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        return hasBundleIdentifier || hasLocalizedName || processIdentifier != nil
    }
}

@MainActor
protocol FrontmostAppProviding: AnyObject {
    var isMonitoring: Bool { get }
    var currentApp: FrontmostAppSnapshot? { get }
    func start(onChange: @escaping @MainActor (FrontmostAppSnapshot?) -> Void)
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

    var currentApp: FrontmostAppSnapshot? {
        FrontmostAppSnapshot(application: workspace.frontmostApplication)
    }

    func start(onChange: @escaping @MainActor (FrontmostAppSnapshot?) -> Void) {
        guard observer == nil else { return }

        observer = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            Task { @MainActor in
                onChange(FrontmostAppSnapshot(application: application))
            }
        }

        onChange(currentApp)
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
