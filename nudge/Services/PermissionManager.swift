import ApplicationServices
import Observation

enum AccessibilityPermissionState: String, CaseIterable, Sendable {
    case unknown
    case granted
    case denied
}

@MainActor
@Observable
final class PermissionManager {
    var accessibilityPermissionState: AccessibilityPermissionState
    
    init(accessibilityPermissionState: AccessibilityPermissionState = .unknown) {
        self.accessibilityPermissionState = accessibilityPermissionState
    }
    
    var isAccessibilityGranted: Bool {
        accessibilityPermissionState == .granted
    }
    
    @discardableResult
    func refreshAccessibilityPermission(promptIfNeeded: Bool = false) -> AccessibilityPermissionState {
        let trusted: Bool
        
        if promptIfNeeded {
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let options = [promptKey: true] as CFDictionary
            trusted = AXIsProcessTrustedWithOptions(options)
        } else {
            trusted = AXIsProcessTrusted()
        }
        
        accessibilityPermissionState = trusted ? .granted : .denied
        return accessibilityPermissionState
    }
}
