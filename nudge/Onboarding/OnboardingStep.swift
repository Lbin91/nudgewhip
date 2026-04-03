import Foundation
import CoreGraphics

enum OnboardingStep: String, CaseIterable, Sendable {
    case welcome
    case permission
    case basicSetup
    case completionReady
    case completionLimited
    
    var progressIndex: Int {
        switch self {
        case .welcome: 1
        case .permission: 2
        case .basicSetup: 3
        case .completionReady, .completionLimited: 4
        }
    }
}

struct OnboardingDraft: Equatable, Sendable {
    var idleThresholdSeconds: Int
    var launchAtLoginEnabled: Bool
    var ttsEnabled: Bool
    var petPresentationMode: PetPresentationMode
}

enum OnboardingWindowMetrics {
    static let contentWidth: CGFloat = 560
    
    static func contentHeight(
        for step: OnboardingStep,
        permissionState: AccessibilityPermissionState
    ) -> CGFloat {
        switch step {
        case .welcome:
            return 460
        case .permission:
            return permissionState == .granted ? 540 : 590
        case .basicSetup:
            return 660
        case .completionReady:
            return 560
        case .completionLimited:
            return 520
        }
    }
}
