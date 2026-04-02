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
    
    /// IdleMonitor의 현재 런타임 상태
    var runtimeState: NudgeRuntimeState {
        idleMonitor.runtimeStateController.snapshot.runtimeState
    }
    
    /// IdleMonitor의 현재 콘텐츠 상태
    var contentState: NudgeContentState {
        idleMonitor.runtimeStateController.snapshot.contentState
    }
    
    /// 런타임 상태에 대응하는 SF Symbol 이름
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
        case .pausedSchedule:
            return "clock.badge"
        case .suspendedSleepOrLock:
            return "moon.zzz"
        }
    }
    
    /// 접근성 권한이 없을 때 CTA 표시 여부
    var shouldShowPermissionCTA: Bool {
        runtimeState == .limitedNoAX
    }
    
    /// 최초 1회만 실행. 권한 확인 후 모니터링 시작
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
    
    /// 권한 새로고침 후 필요 시 모니터링 시작
    func refreshPermission(at date: Date = .now) {
        idleMonitor.refreshPermission(at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    /// 시스템 프롬프트와 함께 권한 요청
    func requestAccessibilityPermission(at date: Date = .now) {
        refreshPermission(promptIfNeeded: true, at: date)
    }
    
    @discardableResult
    /// 시스템 환경설정 접근성 패널 열기
    func openAccessibilitySettings() -> Bool {
        idleMonitor.permissionManager.openAccessibilitySettings()
    }
    
    /// 유휴 타이머 수동 리셋
    func resetIdleTimer(at date: Date = .now) {
        idleMonitor.recordInput(at: date)
    }
    
    /// 내부: 프롬프트 옵션과 함께 권한 새로고침
    private func refreshPermission(promptIfNeeded: Bool, at date: Date) {
        idleMonitor.refreshPermission(promptIfNeeded: promptIfNeeded, at: date)
        
        if runtimeState == .monitoring, idleMonitor.lastInputAt == nil {
            idleMonitor.recordInput(at: date)
        }
    }
    
    /// 모니터링 중 다음 유휴 체크까지 카운트다운 문자열 반환
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
