import Foundation

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
