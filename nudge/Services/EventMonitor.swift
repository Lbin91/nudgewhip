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
    nonisolated static let menuTrackingSuppressionInterval: TimeInterval = 0.1

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
    private var lastMenuTrackingLocalEventAt: TimeInterval?
    
    var isMonitoring: Bool {
        globalMonitor != nil || localMonitor != nil
    }
    
    func start(onActivity: @escaping @MainActor () -> Void) {
        guard !isMonitoring else { return }
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { event in
            Task { @MainActor in
                let now = ProcessInfo.processInfo.systemUptime
                if Self.shouldSuppressGlobalMenuTrackingDuplicate(
                    eventType: event.type,
                    now: now,
                    lastMenuTrackingLocalEventAt: self.lastMenuTrackingLocalEventAt
                ) {
                    return
                }

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
            if !self.hasActiveWindow {
                self.lastMenuTrackingLocalEventAt = ProcessInfo.processInfo.systemUptime
                return event
            }

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

        lastMenuTrackingLocalEventAt = nil
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

    nonisolated static func shouldSuppressGlobalMenuTrackingDuplicate(
        eventType: NSEvent.EventType,
        now: TimeInterval,
        lastMenuTrackingLocalEventAt: TimeInterval?
    ) -> Bool {
        guard let lastMenuTrackingLocalEventAt else { return false }
        guard monitoredEventTypes.contains(eventType) else { return false }
        return (now - lastMenuTrackingLocalEventAt) <= menuTrackingSuppressionInterval
    }
}
