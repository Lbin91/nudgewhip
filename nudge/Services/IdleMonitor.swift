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
    private(set) var manualPauseUntil: Date?
    private(set) var isMenuPresentationActive = false
    
    let permissionManager: PermissionManager
    let runtimeStateController: RuntimeStateController
    let eventMonitor: any EventMonitoring
    let lifecycleMonitor: any SystemLifecycleMonitoring
    let frontmostAppProvider: any FrontmostAppProviding
    let alertManager: (any AlertManaging)?
    private(set) var idleThreshold: TimeInterval
    let alertEscalationInterval: TimeInterval
    let cooldownDuration: TimeInterval
    private(set) var scheduleEnabled: Bool
    private(set) var scheduleStart: TimeInterval
    private(set) var scheduleEnd: TimeInterval
    private(set) var whitelistedBundleIdentifiers: Set<String> = []
    
    private var idleDeadlineWorkItem: DispatchWorkItem?
    private var alertEscalationWorkItem: DispatchWorkItem?
    private var cooldownWorkItem: DispatchWorkItem?
    private var scheduleBoundaryWorkItem: DispatchWorkItem?
    private var manualPauseResumeWorkItem: DispatchWorkItem?
    
    /// IdleMonitor 생성. 권한·상태·이벤트 모니터 주입 가능 (기본값 제공)
    init(
        permissionManager: PermissionManager? = nil,
        runtimeStateController: RuntimeStateController? = nil,
        eventMonitor: (any EventMonitoring)? = nil,
        lifecycleMonitor: (any SystemLifecycleMonitoring)? = nil,
        frontmostAppProvider: (any FrontmostAppProviding)? = nil,
        alertManager: (any AlertManaging)? = nil,
        idleThreshold: TimeInterval = 300,
        alertEscalationInterval: TimeInterval = 30,
        cooldownDuration: TimeInterval = 60,
        scheduleEnabled: Bool = false,
        scheduleStart: TimeInterval = 32400,
        scheduleEnd: TimeInterval = 61200
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.runtimeStateController = runtimeStateController ?? RuntimeStateController()
        self.eventMonitor = eventMonitor ?? SystemEventMonitor()
        self.lifecycleMonitor = lifecycleMonitor ?? SystemLifecycleMonitor()
        self.frontmostAppProvider = frontmostAppProvider ?? FrontmostAppProvider()
        self.alertManager = alertManager
        self.idleThreshold = idleThreshold
        self.alertEscalationInterval = alertEscalationInterval
        self.cooldownDuration = cooldownDuration
        self.scheduleEnabled = scheduleEnabled
        self.scheduleStart = scheduleStart
        self.scheduleEnd = scheduleEnd
    }
    
    /// 저장된 사용자 설정을 runtime monitor에 반영
    func applySettings(_ settings: UserSettings, at date: Date = .now) {
        let oldThreshold = idleThreshold
        let oldScheduleEnabled = scheduleEnabled
        idleThreshold = TimeInterval(settings.idleThresholdSeconds)
        scheduleEnabled = settings.scheduleEnabled
        scheduleStart = TimeInterval(settings.scheduleStartSecondsFromMidnight)
        scheduleEnd = TimeInterval(settings.scheduleEndSecondsFromMidnight)
        alertManager?.apply(settings: settings)

        checkSchedule(at: date)

        // threshold가 실제로 변경된 경우에만 deadline 재스케줄.
        // 변경 없이 재호출되면 delay=0으로 즉시 fireIdleDeadline이 트리거되어
        // 드롭다운 렌더링과 충돌하며 메인 스레드가 블로킹된다.
        if runtimeStateController.snapshot.runtimeState == .monitoring,
           abs(oldThreshold - idleThreshold) > 0.001 || idleDeadlineAt == nil || oldScheduleEnabled != scheduleEnabled {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    /// 저장된 화이트리스트 앱 목록을 runtime monitor에 반영
    func applyWhitelistApps(_ apps: [WhitelistApp], at date: Date = .now) {
        whitelistedBundleIdentifiers = Set(
            apps
                .filter(\.isEnabled)
                .map(\.bundleIdentifier)
        )
        updateWhitelistMatch(for: frontmostAppProvider.currentBundleIdentifier, at: date)
    }
    
    /// 권한 확인 후 유휴 감시 시작
    /// 권한 확인 후 유휴 감시 시작
    func start(at date: Date = .now, promptForPermission: Bool = false) {
        refreshPermission(promptIfNeeded: promptForPermission, at: date)
        checkSchedule(at: date)
        if runtimeStateController.snapshot.runtimeState == .monitoring {
            scheduleIdleDeadline(from: date)
        }
    }
    
    /// 접근성 권한 상태 재확인. 승인 시 모니터링 시작, 거부 시 정지
    func refreshPermission(promptIfNeeded: Bool = false, at date: Date = .now) {
        let permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: promptIfNeeded)
        runtimeStateController.handle(permissionState == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        scheduleAlertSync()
        
        if permissionState == .granted {
            startEventMonitoringIfNeeded()
            startLifecycleMonitoringIfNeeded()
            startFrontmostAppMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            stopLifecycleMonitoring()
            stopFrontmostAppMonitoring()
            cancelMonitoringDeadlines()
        }
    }
    
    /// 접근성 권한 상태를 직접 설정. 테스트/프리뷰에서 사용
    func setAccessibilityPermission(_ state: AccessibilityPermissionState, at date: Date = .now) {
        permissionManager.accessibilityPermissionState = state
        runtimeStateController.handle(state == .granted ? .accessibilityGranted : .accessibilityDenied, at: date)
        scheduleAlertSync()
        
        if state == .granted {
            startEventMonitoringIfNeeded()
            startLifecycleMonitoringIfNeeded()
            startFrontmostAppMonitoringIfNeeded()
            scheduleIdleDeadline(from: lastInputAt ?? date)
        } else {
            stopEventMonitoring()
            stopLifecycleMonitoring()
            stopFrontmostAppMonitoring()
            cancelMonitoringDeadlines()
        }
    }
    
    /// 사용자 입력 기록. 유휴 타이머 리셋, 알림 중이면 쿨다운 시작
    func recordInput(at date: Date = .now) {
        let wasAlerting = runtimeStateController.snapshot.runtimeState == .alerting
        
        lastInputAt = date
        runtimeStateController.handle(.userActivityDetected, at: date)
        scheduleAlertSync()
        scheduleIdleDeadline(from: date)
        cancelAlertEscalationDeadline()
        
        if wasAlerting {
            scheduleCooldown(from: date)
        }
    }
    
    /// Event monitor에서 들어온 활동을 처리한다. 메뉴바 메뉴가 열려 있을 때는 무시한다.
    func handleObservedActivity(at date: Date = .now) {
        guard !isMenuPresentationActive else { return }
        recordInput(at: date)
    }
    
    /// 메뉴바 드롭다운이 열려 있는 동안 event monitor 기반 activity 처리를 잠시 멈춘다.
    /// MenuBarExtra depth-menu hover가 observed activity로 해석되면 submenu가 흔들릴 수 있다.
    func setMenuPresentationActive(_ active: Bool) {
        isMenuPresentationActive = active
    }
    
    /// 수동 일시정지 토글. 활성 시 모든 모니터링 데드라인을 취소하고, 필요 시 자동 해제 시각을 예약
    func setManualPause(_ enabled: Bool, until pauseUntil: Date? = nil, at date: Date = .now) {
        runtimeStateController.handle(enabled ? .manualPauseEnabled : .manualPauseDisabled, at: date)
        
        if enabled {
            manualPauseUntil = pauseUntil
            scheduleManualPauseResumeIfNeeded(from: date)
            cancelMonitoringDeadlines()
        } else {
            cancelManualPauseResume()
            manualPauseUntil = nil
            lastInputAt = date
            checkSchedule(at: date)
            scheduleIdleDeadline(from: date)
        }
        
        scheduleAlertSync()
    }
    
    /// 화이트리스트 앱 매칭 상태 설정
    func setWhitelistMatched(_ matched: Bool, at date: Date = .now) {
        runtimeStateController.handle(matched ? .whitelistMatched : .whitelistUnmatched, at: date)
        scheduleAlertSync()
        
        if matched {
            cancelMonitoringDeadlines()
        } else {
            scheduleIdleDeadline(from: lastInputAt ?? date)
        }
    }
    
    /// 수면/잠금/사용자 전환 등 시스템 이벤트 처리
    func handleSystemEvent(_ event: NudgeRuntimeEvent, at date: Date = .now) {
        runtimeStateController.handle(event, at: date)
        scheduleAlertSync()
        
        switch event {
        case .sleepDetected, .screenLocked, .fastUserSwitchingStarted:
            cancelMonitoringDeadlines()
        case .wakeDetected, .screenUnlocked, .fastUserSwitchingEnded:
            lastInputAt = date
            checkSchedule(at: date)
            scheduleIdleDeadline(from: date)
        default:
            break
        }
    }
    
    /// 유휴 임계값 도달 시 호출. 알림 상태로 전환 후 에스컬레이션 시작
    func fireIdleDeadline(at date: Date = .now) {
        guard let idleDeadlineAt, date >= idleDeadlineAt else { return }
        runtimeStateController.handle(.idleDeadlineReached, at: date)
        scheduleAlertSync()
        self.idleDeadlineAt = nil
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    /// 알림 에스컬레이션 단계 진행 (idle → gentle → strong)
    func fireAlertEscalationDeadline(at date: Date = .now) {
        guard let alertEscalationDeadlineAt, date >= alertEscalationDeadlineAt else { return }
        runtimeStateController.handle(.alertEscalationDeadlineReached, at: date)
        scheduleAlertSync()
        self.alertEscalationDeadlineAt = nil
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        scheduleAlertEscalation(from: date)
    }
    
    /// 쿨다운 종료. 복구 상태에서 포커스로 복귀
    func fireCooldownExpired(at date: Date = .now) {
        guard let cooldownDeadlineAt, date >= cooldownDeadlineAt else { return }
        runtimeStateController.handle(.cooldownExpired, at: date)
        scheduleAlertSync()
        self.cooldownDeadlineAt = nil
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
    }
    
    /// 예약된 수동 일시정지 자동 해제를 처리
    func fireManualPauseResume(at date: Date = .now) {
        guard let manualPauseUntil, date >= manualPauseUntil else { return }
        setManualPause(false, at: date)
    }
    
    /// 현재 시간이 스케줄 윈도우 내인지 확인하고 상태 전이
    func checkSchedule(at date: Date = .now) {
        guard scheduleEnabled else {
            if runtimeStateController.snapshot.schedulePaused {
                runtimeStateController.handle(.scheduleWindowExited, at: date)
                lastInputAt = date
                scheduleAlertSync()
                scheduleIdleDeadline(from: date)
            }
            scheduleBoundaryWorkItem?.cancel()
            scheduleBoundaryWorkItem = nil
            return
        }
        let secondsFromMidnight: TimeInterval = TimeInterval(
            Calendar.current.component(.hour, from: date) * 3600
            + Calendar.current.component(.minute, from: date) * 60
            + Calendar.current.component(.second, from: date)
        )
        
        let inWindow: Bool
        if scheduleStart <= scheduleEnd {
            inWindow = secondsFromMidnight >= scheduleStart && secondsFromMidnight < scheduleEnd
        } else {
            // 자정을 넘나드는 스케줄 (예: 22:00 - 06:00)
            inWindow = secondsFromMidnight >= scheduleStart || secondsFromMidnight < scheduleEnd
        }
        
        let snapshot = runtimeStateController.snapshot
        if inWindow && snapshot.schedulePaused {
            runtimeStateController.handle(.scheduleWindowExited, at: date)
            lastInputAt = date
            scheduleAlertSync()
            scheduleIdleDeadline(from: date)
        } else if !inWindow && !snapshot.schedulePaused {
            runtimeStateController.handle(.scheduleWindowEntered, at: date)
            scheduleAlertSync()
            cancelMonitoringDeadlines()
        }
        
        scheduleNextBoundary(from: date)
    }
    
    /// 다음 스케줄 경계 시각에 타이머 예약
    private func scheduleNextBoundary(from date: Date) {
        scheduleBoundaryWorkItem?.cancel()
        scheduleBoundaryWorkItem = nil
        guard scheduleEnabled else { return }
        
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: date)
        let secondsFromMidnight = date.timeIntervalSince(todayStart)
        
        let nextStartOffset = scheduleStart > secondsFromMidnight ? scheduleStart : scheduleStart + 86400
        let nextEndOffset = scheduleEnd > secondsFromMidnight ? scheduleEnd : scheduleEnd + 86400
        let nextBoundaryOffset = min(nextStartOffset, nextEndOffset)
        let delay = max(1, nextBoundaryOffset - secondsFromMidnight)
        
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.checkSchedule(at: .now)
            }
        }
        scheduleBoundaryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
        let delay = max(0, idleDeadlineAt?.timeIntervalSinceNow ?? idleThreshold)
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fireIdleDeadline(at: .now)
            }
        }
        idleDeadlineWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    /// 알림 에스컬레이션 타이머 취소
    private func cancelAlertEscalationDeadline() {
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        alertEscalationDeadlineAt = nil
    }
    
    /// 모든 예약된 모니터링 데드라인(유휴/에스컬레이션/쿨다운/스케줄) 취소
    private func cancelMonitoringDeadlines() {
        idleDeadlineWorkItem?.cancel()
        idleDeadlineWorkItem = nil
        alertEscalationWorkItem?.cancel()
        alertEscalationWorkItem = nil
        cooldownWorkItem?.cancel()
        cooldownWorkItem = nil
        scheduleBoundaryWorkItem?.cancel()
        scheduleBoundaryWorkItem = nil
        idleDeadlineAt = nil
        alertEscalationDeadlineAt = nil
        cooldownDeadlineAt = nil
    }
    
    /// 예약된 수동 일시정지 자동 해제 타이머 취소
    private func cancelManualPauseResume() {
        manualPauseResumeWorkItem?.cancel()
        manualPauseResumeWorkItem = nil
    }
    
    /// timed manual pause라면 자동 해제 시각에 맞춰 타이머 예약
    private func scheduleManualPauseResumeIfNeeded(from date: Date) {
        cancelManualPauseResume()
        guard let manualPauseUntil else { return }
        
        let delay = max(0, manualPauseUntil.timeIntervalSince(date))
        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.fireManualPauseResume(at: .now)
            }
        }
        manualPauseResumeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
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
            self?.handleObservedActivity()
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
    
    /// frontmost app 변경 모니터 시작
    private func startFrontmostAppMonitoringIfNeeded() {
        guard !frontmostAppProvider.isMonitoring else { return }
        frontmostAppProvider.start { [weak self] bundleIdentifier in
            self?.updateWhitelistMatch(for: bundleIdentifier)
        }
    }
    
    /// frontmost app 변경 모니터 정지
    private func stopFrontmostAppMonitoring() {
        frontmostAppProvider.stop()
    }
    
    /// 현재 frontmost app이 화이트리스트에 포함되는지 평가
    private func updateWhitelistMatch(for bundleIdentifier: String?, at date: Date = .now) {
        let matched = bundleIdentifier.map { whitelistedBundleIdentifiers.contains($0) } ?? false
        setWhitelistMatched(matched, at: date)
    }
    
    /// alert side effects는 이벤트 핸들러에서 바로 무겁게 수행하지 않도록 비동기로 동기화
    private func scheduleAlertSync() {
        let snapshot = runtimeStateController.snapshot
        Task { @MainActor [alertManager] in
            alertManager?.handle(snapshot: snapshot)
        }
    }
}
