// MenuBarViewModel.swift
// 메뉴바 UI 상태를 관리하는 뷰모델.
//
// IdleMonitor를 래핑해 런타임/콘텐츠 상태를 뷰에 노출한다.
// 메뉴바 아이콘 선택, 카운트다운 텍스트 생성, 권한 새로고침·타이머 리셋을 제공한다.

import Foundation
import Observation

@MainActor
@Observable
final class MenuBarViewModel {
    let idleMonitor: IdleMonitor
    private(set) var hasStarted = false
    
    init(idleMonitor: IdleMonitor? = nil) {
        self.idleMonitor = idleMonitor ?? IdleMonitor()
    }
    
    var runtimeState: NudgeRuntimeState {
        idleMonitor.runtimeStateController.snapshot.runtimeState
    }
    
    var contentState: NudgeContentState {
        idleMonitor.runtimeStateController.snapshot.contentState
    }
    
    var systemImageName: String {
        switch runtimeState {
        case .limitedNoAX:
            return "hand.raised.slash"
        case .monitoring:
            return "eye.circle"
        case .pausedManual:
            return "pause.circle"
        case .pausedWhitelist:
            return "checkmark.circle"
        case .alerting:
            return "exclamationmark.circle"
        case .suspendedSleepOrLock:
            return "moon.zzz"
        }
    }
    
    var shouldShowPermissionCTA: Bool {
        runtimeState == .limitedNoAX
    }
    
    func startIfNeeded(at date: Date = .now) {
        guard !hasStarted else { return }
        hasStarted = true
        
        if idleMonitor.permissionManager.accessibilityPermissionState == .unknown {
            idleMonitor.start(at: date)
        } else {
            idleMonitor.setAccessibilityPermission(idleMonitor.permissionManager.accessibilityPermissionState, at: date)
        }
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    func refreshPermission(at date: Date = .now) {
        idleMonitor.refreshPermission(at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    func requestAccessibilityPermission(at date: Date = .now) {
        refreshPermission(promptIfNeeded: true, at: date)
    }
    
    @discardableResult
    func openAccessibilitySettings() -> Bool {
        idleMonitor.permissionManager.openAccessibilitySettings()
    }
    
    func resetIdleTimer(at date: Date = .now) {
        idleMonitor.recordInput(at: date)
    }
    
    private func refreshPermission(promptIfNeeded: Bool, at date: Date) {
        idleMonitor.refreshPermission(promptIfNeeded: promptIfNeeded, at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    func countdownText(now: Date = .now) -> String? {
        guard runtimeState == .monitoring, let deadline = idleMonitor.idleDeadlineAt else {
            return nil
        }
        
        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded()))
        let hours = remaining / 3_600
        let minutes = (remaining % 3_600) / 60
        let seconds = remaining % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
