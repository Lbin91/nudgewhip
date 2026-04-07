import AppKit
import Foundation

@MainActor
protocol SystemLifecycleMonitoring: AnyObject {
    var isMonitoring: Bool { get }
    func start(onEvent: @escaping @MainActor (NudgeWhipRuntimeEvent) -> Void)
    func stop()
}

@MainActor
final class SystemLifecycleMonitor: SystemLifecycleMonitoring {
    private var observers: [NSObjectProtocol] = []
    private var isStarted = false
    
    private let workspaceNotificationCenter: NotificationCenter
    private let distributedNotificationCenter: DistributedNotificationCenter
    
    init(
        workspaceNotificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        distributedNotificationCenter: DistributedNotificationCenter = .default()
    ) {
        self.workspaceNotificationCenter = workspaceNotificationCenter
        self.distributedNotificationCenter = distributedNotificationCenter
    }
    
    var isMonitoring: Bool {
        isStarted
    }
    
    func start(onEvent: @escaping @MainActor (NudgeWhipRuntimeEvent) -> Void) {
        guard !isStarted else { return }
        isStarted = true
        
        observers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.sleepDetected)
                }
            }
        )
        
        observers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.wakeDetected)
                }
            }
        )
        
        observers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.fastUserSwitchingStarted)
                }
            }
        )
        
        observers.append(
            workspaceNotificationCenter.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.fastUserSwitchingEnded)
                }
            }
        )
        
        observers.append(
            distributedNotificationCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsLocked"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.screenLocked)
                }
            }
        )
        
        observers.append(
            distributedNotificationCenter.addObserver(
                forName: Notification.Name("com.apple.screenIsUnlocked"),
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor in
                    onEvent(.screenUnlocked)
                }
            }
        )
    }
    
    func stop() {
        guard isStarted else { return }
        isStarted = false
        
        for observer in observers {
            workspaceNotificationCenter.removeObserver(observer)
            distributedNotificationCenter.removeObserver(observer)
        }
        observers.removeAll()
    }
}
