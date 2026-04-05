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
    nonisolated static let monitoredEventTypes: [NSEvent.EventType] = [
        .mouseMoved,
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .leftMouseDragged,
        .rightMouseDragged,
        .otherMouseDragged,
        .scrollWheel,
        .keyDown
    ]
    
    private var eventMask: NSEvent.EventTypeMask {
        Self.monitoredEventTypes.reduce(into: []) { mask, type in
            mask.insert(NSEvent.EventTypeMask(rawValue: 1 << type.rawValue))
        }
    }
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    var isMonitoring: Bool {
        globalMonitor != nil || localMonitor != nil
    }
    
    func start(onActivity: @escaping @MainActor () -> Void) {
        guard !isMonitoring else { return }
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { event in
            Task { @MainActor in
                if Self.shouldTreatEventAsActivity(
                    eventType: event.type,
                    isAppActive: NSApp.isActive,
                    hasActiveWindow: self.hasActiveWindow,
                    isLocalEvent: false
                ) {
                    onActivity()
                }
            }
        }
        
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { event in
            if Self.shouldTreatEventAsActivity(
                eventType: event.type,
                isAppActive: NSApp.isActive,
                hasActiveWindow: self.hasActiveWindow,
                isLocalEvent: true
            ) {
                onActivity()
            }
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
    
    private var hasActiveWindow: Bool {
        NSApp.keyWindow != nil || NSApp.mainWindow != nil
    }
    
    nonisolated static func shouldTreatEventAsActivity(
        eventType: NSEvent.EventType,
        isAppActive: Bool,
        hasActiveWindow: Bool,
        isLocalEvent: Bool
    ) -> Bool {
        // Local events should be tied to our actual app windows only.
        if isLocalEvent && !hasActiveWindow {
            return false
        }
        
        return true
    }
}
