import AppKit
import Foundation

@MainActor
protocol EventMonitoring: AnyObject {
    var isMonitoring: Bool { get }
    func start(onActivity: @escaping @MainActor () -> Void)
    func stop()
}

@MainActor
final class SystemEventMonitor: EventMonitoring {
    private let eventMask: NSEvent.EventTypeMask = [
        .mouseMoved,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .scrollWheel,
        .keyDown
    ]
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    var isMonitoring: Bool {
        globalMonitor != nil || localMonitor != nil
    }
    
    func start(onActivity: @escaping @MainActor () -> Void) {
        guard !isMonitoring else { return }
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { _ in
            Task { @MainActor in
                onActivity()
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { event in
            onActivity()
            return event
        }
    }
    
    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }
    
    deinit {
        globalMonitor.map(NSEvent.removeMonitor)
        localMonitor.map(NSEvent.removeMonitor)
    }
}
