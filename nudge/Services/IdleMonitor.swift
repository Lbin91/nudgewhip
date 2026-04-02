// IdleMonitor.swift
// 유휴 시간을 감지하고 단계별 알림 데드라인을 관리하는 코어 서비스.
//
// NSEvent 전역 모니터로 마지막 입력 시각을 추적하고,
// 유휴 임계값 도달 → 알림 에스컬레이션 → 쿨다운 사이클을 스케줄한다.
// 수동 일시정지, 화이트리스트 매칭, 시스템 이벤트(수면/잠금)도 처리한다.

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
    let lifecycleMonitor: any SystemLifecycleMonitoring
    let idleThreshold: TimeInterval
    let alertEscalationInterval: TimeInterval
    let cooldownDuration: TimeInterval
    
    private var idleDeadlineWorkItem: DispatchWorkItem?
    private var alertEscalationWorkItem: DispatchWorkItem?
    private var cooldownWorkItem: DispatchWorkItem?
    
    /// IdleMonitor 생성. 권한·상태·이벤트 모니터 주입 가능 (기본값 제공)
    init(
        permissionManager: PermissionManager? = nil,
        runtimeStateController: RuntimeStateController? = nil,
        eventMonitor: (any EventMonitoring)? = nil,
        lifecycleMonitor: (any SystemLifecycleMonitoring)? = nil,
        idleThreshold: TimeInterval = 300,
        alertEscalationInterval: TimeInterval = 30,
        cooldownDuration: TimeInterval = 60
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.runtimeStateController = runtimeStateController ?? RuntimeStateController()
        self.eventMonitor = eventMonitor ?? SystemEventMonitor()
        self.lifecycleMonitor = lifecycleMonitor ?? SystemLifecycleMonitor()
        self.idleThreshold = idleThreshold
        self.alertEscalationInterval = alertEscalationInterval
        self.cooldownDuration = cooldownDuration
    }
    
    /// 권한 확인 후 유휴 감시 시작
    func start(at date: Date = .now, promptForPermission: Bool = false) {
        refreshPermission(promptIfNeeded: promptForPermission, at: date)
        if runtimeStateController.snapshot.runtimeState == .monitoring {
            scheduleIdleDeadline(from: date)
        }
    }
    
    /// 접근성 권한 상태 재확인. 승인 시 모니터링 시작, 거부 시 정지
    func refreshPermission(promptIfNeeded: Bool = false, at date: Date = .now) {
        let permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: promptIfNeeded)
        runtimeStateController.handle(permissionState == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        
        if permissionState == .granted {
            startEventMonitoringIfNeeded()
            startLifecycleMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            stopLifecycleMonitoring()
            cancelAllDeadlines()
        }
    }
    
    /// 접근성 권한 상태를 직접 설정. 테스트/프리뷰에서 사용
    func setAccessibilityPermission(_ state: AccessibilityPermissionState, at date: Date = .now) {
        permissionManager.accessibilityPermissionState = state
        runtimeStateController.handle(state == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        
        if state == .granted {
            startEventMonitoringIfNeeded()
            startLifecycleMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            stopLifecycleMonitoring()
            cancelAllDeadlines()
        }
    }
    
    /// 사용자 입력 기록. 유휴 타이머 리셋, 알림 중이면 쿨다운 시작
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
    
    /// 수동 일시정지 토글. 활성 시 모든 데드라인 취소
    func setManualPause(_ enabled: Bool, at date: Date = .now) {
        runtimeStateController.handle(enabled ? .manualPauseEnabled : .manualPauseDisabled, at: date)
        
        if enabled {
            cancelAllDeadlines()
        } else {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    /// 화이트리스트 앱 매칭 상태 설정
    func setWhitelistMatched(_ matched: Bool, at date: Date = .now) {
        runtimeStateController.handle(matched ? .whitelistMatched : .whitelistUnmatched, at: date)
        
        if matched {
            cancelAllDeadlines()
        } else {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    /// 수면/잠금/사용자 전환 등 시스템 이벤트 처리
    func handleSystemEvent(_ event: NudgeRuntimeEvent, at date: Date = .now) {
        runtimeStateController.handle(event, at: date)
        
        switch event {
        case .sleepDetected, .screenLocked, .fastUserSwitchingStarted:
            cancelAllDeadlines()
        case .wakeDetected, .screenUnlocked, .fastUserSwitchingEnded:
            lastInputAt = date
            scheduleIdleDeadline(from: date)
        default:
            break
        }
    }
    
    /// 유휴 임계값 도달 시 호출. 알림 상태로 전환 후 에스컬레이션 시작
    func fireIdleDeadline(at date: Date = .now) {
        guard let idleDeadlineAt, date >= idleDeadlineAt else { return }
        runtimeStateController.handle(.idleDeadlineReached, at: date)
        self.idleDeadlineAt = nil
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    /// 알림 에스컬레이션 단계 진행 (idle → gentle → strong)
    func fireAlertEscalationDeadline(at date: Date = .now) {
        guard let alertEscalationDeadlineAt, date >= alertEscalationDeadlineAt else { return }
        runtimeStateController.handle(.alertEscalationDeadlineReached, at: date)
        self.alertEscalationDeadlineAt = nil
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    /// 쿨다운 종료. 복구 상태에서 포커스로 복귀
    func fireCooldownExpired(at date: Date = .now) {
        guard let cooldownDeadlineAt, date >= cooldownDeadlineAt else { return }
        runtimeStateController.handle(.cooldownExpired, at: date)
        self.cooldownDeadlineAt = nil
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
    }
    
    /// 유휴 데드라인 스케줄. 모니터링 상태에서만 동작
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
    
    /// 알림 에스컬레이션 타이머 취소
    private func cancelAlertEscalationDeadline() {
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        alertEscalationDeadlineAt = nil
    }
    
    /// 모든 예약된 데드라인(유휴/에스컬레이션/쿨다운) 취소
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
    
    /// 알림 에스컬레이션 타이머 스케줄
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
    
    /// 쿨다운 타이머 스케줄
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
    
    /// 전역 입력 이벤트 모니터 시작 (이미 실행 중이면 스킵)
    private func startEventMonitoringIfNeeded() {
        guard !eventMonitor.isMonitoring else { return }
        eventMonitor.start { [weak self] in
            self?.recordInput()
        }
    }
    
    /// 전역 입력 이벤트 모니터 정지
    private func stopEventMonitoring() {
        eventMonitor.stop()
    }
    
    /// 시스템 lifecycle 모니터 시작
    private func startLifecycleMonitoringIfNeeded() {
        guard !lifecycleMonitor.isMonitoring else { return }
        lifecycleMonitor.start { [weak self] event in
            self?.handleSystemEvent(event)
        }
    }
    
    /// 시스템 lifecycle 모니터 정지
    private func stopLifecycleMonitoring() {
        lifecycleMonitor.stop()
    }
}
