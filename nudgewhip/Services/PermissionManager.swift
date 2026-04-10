// PermissionManager.swift
// macOS 접근성 권한 상태를 관리하는 매니저.
//
// AXIsProcessTrusted()로 권한을 확인하고, 필요 시 시스템 프롬프트를 띄운다.
// @Observable로 UI에 권한 상태 변화를 즉시 반영한다.

import ApplicationServices
import AppKit
import Observation

enum AccessibilityPermissionState: String, CaseIterable, Sendable {
    case unknown
    case granted
    case denied
}

typealias AccessibilityTrustCheck = @MainActor @Sendable (_ promptIfNeeded: Bool) -> Bool
typealias AccessibilitySettingsOpener = @MainActor @Sendable (_ url: URL) -> Bool

@MainActor
@Observable
final class PermissionManager {
    var accessibilityPermissionState: AccessibilityPermissionState
    
    private let trustCheck: AccessibilityTrustCheck
    private let settingsOpener: AccessibilitySettingsOpener
    
    init(
        accessibilityPermissionState: AccessibilityPermissionState = .unknown,
        trustCheck: @escaping AccessibilityTrustCheck = PermissionManager.defaultTrustCheck,
        settingsOpener: @escaping AccessibilitySettingsOpener = PermissionManager.defaultSettingsOpener
    ) {
        if accessibilityPermissionState == .unknown,
           let overriddenState = PermissionManager.defaultStateOverride() {
            self.accessibilityPermissionState = overriddenState
        } else {
            self.accessibilityPermissionState = accessibilityPermissionState
        }
        self.trustCheck = trustCheck
        self.settingsOpener = settingsOpener
    }
    
    /// 접근성 권한 승인 여부 편의 프로퍼티
    var isAccessibilityGranted: Bool {
        accessibilityPermissionState == .granted
    }
    
    /// 시스템 환경설정 접근성 패널 URL
    var accessibilitySettingsURL: URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    }
    
    @discardableResult
    /// 접근성 권한 상태 갱신. promptIfNeeded=true면 시스템 권한 프롬프트 표시
    func refreshAccessibilityPermission(promptIfNeeded: Bool = false) -> AccessibilityPermissionState {
        let trusted = trustCheck(promptIfNeeded)
        accessibilityPermissionState = trusted ? .granted : .denied
        return accessibilityPermissionState
    }
    
    @discardableResult
    /// 시스템 환경설정 접근성 패널 열기
    func openAccessibilitySettings() -> Bool {
        settingsOpener(accessibilitySettingsURL)
    }
    
    /// 기본 접근성 권한 확인 로직 (AXIsProcessTrusted 호출)
    private static func defaultTrustCheck(promptIfNeeded: Bool) -> Bool {
        if let override = defaultStateOverride() {
            return override == .granted
        }

        if promptIfNeeded {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        
        return AXIsProcessTrusted()
    }

    private static func defaultStateOverride() -> AccessibilityPermissionState? {
        switch testAccessibilityOverrideValue() {
        case "granted":
            return .granted
        case "denied":
            return .denied
        default:
            return nil
        }
    }

    private static func testAccessibilityOverrideValue() -> String? {
        ProcessInfo.processInfo.environment["NUDGE_TEST_ACCESSIBILITY"]?.lowercased()
    }
    
    /// 기본 설정 앱 열기 로직 (NSWorkspace.shared.open)
    private static func defaultSettingsOpener(url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
