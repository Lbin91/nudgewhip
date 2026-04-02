import Foundation
import Observation

@MainActor
@Observable
final class IdleMonitor {
    private(set) var lastInputAt: Date?
    private(set) var idleDeadlineAt: Date?
    private(set) var alertEscalationDeadlineAt: Date?
    private(set) var cooldownDeadlineAt: Date?
    
    let permissionManager: PermissionManager
    let runtimeStateController: RuntimeStateController
    let eventMonitor: any EventMonitoring
    let idleThreshold: TimeInterval
    let alertEscalationInterval: TimeInterval
    let cooldownDuration: TimeInterval
    
    private var idleDeadlineWorkItem: DispatchWorkItem?
    private var alertEscalationWorkItem: DispatchWorkItem?
    private var cooldownWorkItem: DispatchWorkItem?
    
    init(
        permissionManager: PermissionManager? = nil,
        runtimeStateController: RuntimeStateController? = nil,
        eventMonitor: (any EventMonitoring)? = nil,
        idleThreshold: TimeInterval = 300,
        alertEscalationInterval: TimeInterval = 30,
        cooldownDuration: TimeInterval = 60
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.runtimeStateController = runtimeStateController ?? RuntimeStateController()
        self.eventMonitor = eventMonitor ?? SystemEventMonitor()
        self.idleThreshold = idleThreshold
        self.alertEscalationInterval = alertEscalationInterval
        self.cooldownDuration = cooldownDuration
    }
    
    func start(at date: Date = .now, promptForPermission: Bool = false) {
        refreshPermission(promptIfNeeded: promptForPermission, at: date)
        if runtimeStateController.snapshot.runtimeState == .monitoring {
            scheduleIdleDeadline(from: date)
        }
    }
    
    func refreshPermission(promptIfNeeded: Bool = false, at date: Date = .now) {
        let permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: promptIfNeeded)
        runtimeStateController.handle(permissionState == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        
        if permissionState == .granted {
            startEventMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            cancelAllDeadlines()
        }
    }
    
    func setAccessibilityPermission(_ state: AccessibilityPermissionState, at date: Date = .now) {
        permissionManager.accessibilityPermissionState = state
        runtimeStateController.handle(state == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        
        if state == .granted {
            startEventMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            cancelAllDeadlines()
        }
    }
    
    func recordInput(at date: Date = .now) {
        let wasAlerting = runtimeStateController.snapshot.runtimeState == .alerting
        
        lastInputAt = date
        runtimeStateController.handle(.userActivityDetected, at: date)
        scheduleIdleDeadline(from: date)
        cancelAlertEscalationDeadline()
        
        if wasAlerting {
            scheduleCooldown(from: date)
        }
    }
    
    func setManualPause(_ enabled: Bool, at date: Date = .now) {
        runtimeStateController.handle(enabled ? .manualPauseEnabled : .manualPauseDisabled, at: date)
        
        if enabled {
            cancelAllDeadlines()
        } else {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    func setWhitelistMatched(_ matched: Bool, at date: Date = .now) {
        runtimeStateController.handle(matched ? .whitelistMatched : .whitelistUnmatched, at: date)
        
        if matched {
            cancelAllDeadlines()
        } else {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    func handleSystemEvent(_ event: NudgeRuntimeEvent, at date: Date = .now) {
        runtimeStateController.handle(event, at: date)
        
        switch event {
        case .sleepDetected, .screenLocked, .fastUserSwitchingStarted:
            cancelAllDeadlines()
        case .wakeDetected, .screenUnlocked, .fastUserSwitchingEnded:
            scheduleIdleDeadline(from: lastInputAt ?? date)
        default:
            break
        }
    }
    
    func fireIdleDeadline(at date: Date = .now) {
        guard let idleDeadlineAt, date >= idleDeadlineAt else { return }
        runtimeStateController.handle(.idleDeadlineReached, at: date)
        self.idleDeadlineAt = nil
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    func fireAlertEscalationDeadline(at date: Date = .now) {
        guard let alertEscalationDeadlineAt, date >= alertEscalationDeadlineAt else { return }
        runtimeStateController.handle(.alertEscalationDeadlineReached, at: date)
        self.alertEscalationDeadlineAt = nil
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    func fireCooldownExpired(at date: Date = .now) {
        guard let cooldownDeadlineAt, date >= cooldownDeadlineAt else { return }
        runtimeStateController.handle(.cooldownExpired, at: date)
        self.cooldownDeadlineAt = nil
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
    }
    
    private func scheduleIdleDeadline(from date: Date) {
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        
        guard runtimeStateController.snapshot.runtimeState == .monitoring else {
            idleDeadlineAt = nil
            return
        }
        
        idleDeadlineAt = date.addingTimeInterval(idleThreshold)
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fireIdleDeadline(at: .now)
            }
        }
        idleDeadlineWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + idleThreshold, execute: workItem)
    }
    
    private func cancelAlertEscalationDeadline() {
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        alertEscalationDeadlineAt = nil
    }
    
    private func cancelAllDeadlines() {
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
        idleDeadlineAt = nil
        alertEscalationDeadlineAt = nil
        cooldownDeadlineAt = nil
    }
    
    private func scheduleAlertEscalation(from date: Date) {
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        alertEscalationDeadlineAt = date.addingTimeInterval(alertEscalationInterval)
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fireAlertEscalationDeadline(at: .now)
            }
        }
        alertEscalationWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + alertEscalationInterval, execute: workItem)
    }
    
    private func scheduleCooldown(from date: Date) {
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
        cooldownDeadlineAt = date.addingTimeInterval(cooldownDuration)
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fireCooldownExpired(at: .now)
            }
        }
        cooldownWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + cooldownDuration, execute: workItem)
    }
    
    private func startEventMonitoringIfNeeded() {
        guard !eventMonitor.isMonitoring else { return }
        eventMonitor.start { [weak self] in
            self?.recordInput()
        }
    }
    
    private func stopEventMonitoring() {
        eventMonitor.stop()
    }
}
