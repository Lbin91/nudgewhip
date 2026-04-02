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

typealias AccessibilityTrustCheck = @Sendable (_ promptIfNeeded: Bool) -> Bool
typealias AccessibilitySettingsOpener = @Sendable (_ url: URL) -> Bool

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
        self.accessibilityPermissionState = accessibilityPermissionState
        self.trustCheck = trustCheck
        self.settingsOpener = settingsOpener
    }
    
    var isAccessibilityGranted: Bool {
        accessibilityPermissionState == .granted
    }
    
    var accessibilitySettingsURL: URL {
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    }
    
    @discardableResult
    func refreshAccessibilityPermission(promptIfNeeded: Bool = false) -> AccessibilityPermissionState {
        let trusted = trustCheck(promptIfNeeded)
        accessibilityPermissionState = trusted ? .granted : .denied
        return accessibilityPermissionState
    }
    
    @discardableResult
    func openAccessibilitySettings() -> Bool {
        settingsOpener(accessibilitySettingsURL)
    }
    
    private static func defaultTrustCheck(promptIfNeeded: Bool) -> Bool {
        if promptIfNeeded {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        
        return AXIsProcessTrusted()
    }
    
    private static func defaultSettingsOpener(url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
