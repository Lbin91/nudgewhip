import Foundation
import CoreGraphics

enum OnboardingStep: String, CaseIterable, Sendable {
    case welcome
    case permission
    case basicSetup
    case scheduleSetup
    case completionReady
    case completionLimited
    
    var progressIndex: Int {
        switch self {
        case .welcome: 1
        case .permission: 2
        case .basicSetup: 3
        case .scheduleSetup: 4
        case .completionReady, .completionLimited: 5
        }
    }
}

struct OnboardingDraft: Equatable, Sendable {
    var idleThresholdSeconds: Int
    var launchAtLoginEnabled: Bool
    var ttsEnabled: Bool
    var petPresentationMode: PetPresentationMode
    var scheduleEnabled: Bool
    var scheduleStartSecondsFromMidnight: Int
    var scheduleEndSecondsFromMidnight: Int
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
            return permissionState == .granted ? 560 : 640
        case .basicSetup:
            return 520
        case .scheduleSetup:
            return 560
        case .completionReady:
            return 560
        case .completionLimited:
            return 520
        }
    }
}
