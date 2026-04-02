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
    let idleThreshold: TimeInterval
    let alertEscalationInterval: TimeInterval
    let cooldownDuration: TimeInterval
    
    init(
        permissionManager: PermissionManager? = nil,
        runtimeStateController: RuntimeStateController? = nil,
        idleThreshold: TimeInterval = 300,
        alertEscalationInterval: TimeInterval = 30,
        cooldownDuration: TimeInterval = 60
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.runtimeStateController = runtimeStateController ?? RuntimeStateController()
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
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            cancelAllDeadlines()
        }
    }
    
    func setAccessibilityPermission(_ state: AccessibilityPermissionState, at date: Date = .now) {
        permissionManager.accessibilityPermissionState = state
        runtimeStateController.handle(state == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        
        if state == .granted {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
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
            cooldownDeadlineAt = date.addingTimeInterval(cooldownDuration)
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
        alertEscalationDeadlineAt = date.addingTimeInterval(alertEscalationInterval)
    }
    
    func fireAlertEscalationDeadline(at date: Date = .now) {
        guard let alertEscalationDeadlineAt, date >= alertEscalationDeadlineAt else { return }
        runtimeStateController.handle(.alertEscalationDeadlineReached, at: date)
        self.alertEscalationDeadlineAt = date.addingTimeInterval(alertEscalationInterval)
    }
    
    func fireCooldownExpired(at date: Date = .now) {
        guard let cooldownDeadlineAt, date >= cooldownDeadlineAt else { return }
        runtimeStateController.handle(.cooldownExpired, at: date)
        self.cooldownDeadlineAt = nil
    }
    
    private func scheduleIdleDeadline(from date: Date) {
        guard runtimeStateController.snapshot.runtimeState == .monitoring else {
            idleDeadlineAt = nil
            return
        }
        
        idleDeadlineAt = date.addingTimeInterval(idleThreshold)
    }
    
    private func cancelAlertEscalationDeadline() {
        alertEscalationDeadlineAt = nil
    }
    
    private func cancelAllDeadlines() {
        idleDeadlineAt = nil
        alertEscalationDeadlineAt = nil
        cooldownDeadlineAt = nil
    }
}
