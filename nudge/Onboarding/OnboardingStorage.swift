import Foundation

@MainActor
protocol OnboardingStoring: AnyObject {
    var requiredVersion: Int { get }
    var shouldPresentOnboarding: Bool { get }
    var resumeStep: OnboardingStep? { get }
    var savedDraft: OnboardingDraft? { get }
    func saveDraft(_ draft: OnboardingDraft)
    func saveResumeStep(_ step: OnboardingStep?)
    func markCompleted()
    func reset()
}

@MainActor
final class OnboardingStorage: OnboardingStoring {
    static let shared = OnboardingStorage()
    
    private enum Keys {
        static let completed = "onboarding.completed"
        static let version = "onboarding.version"
        static let resumeStep = "onboarding.resume_step"
        static let idleThreshold = "onboarding.draft.idle_threshold"
        static let launchAtLogin = "onboarding.draft.launch_at_login"
        static let ttsEnabled = "onboarding.draft.tts_enabled"
        static let petMode = "onboarding.draft.pet_mode"
        static let hasDraft = "onboarding.draft.has_value"
    }
    
    private let defaults: UserDefaults
    let requiredVersion: Int
    
    init(defaults: UserDefaults = .standard, requiredVersion: Int = 1) {
        self.defaults = defaults
        self.requiredVersion = requiredVersion
    }
    
    var shouldPresentOnboarding: Bool {
        !defaults.bool(forKey: Keys.completed) || defaults.integer(forKey: Keys.version) < requiredVersion
    }
    
    var resumeStep: OnboardingStep? {
        guard let rawValue = defaults.string(forKey: Keys.resumeStep) else { return nil }
        return OnboardingStep(rawValue: rawValue)
    }
    
    var savedDraft: OnboardingDraft? {
        guard defaults.bool(forKey: Keys.hasDraft) else { return nil }
        return OnboardingDraft(
            idleThresholdSeconds: defaults.integer(forKey: Keys.idleThreshold),
            launchAtLoginEnabled: defaults.bool(forKey: Keys.launchAtLogin),
            ttsEnabled: defaults.bool(forKey: Keys.ttsEnabled),
            petPresentationMode: PetPresentationMode(rawValue: defaults.string(forKey: Keys.petMode) ?? "") ?? .sprout
        )
    }
    
    func saveDraft(_ draft: OnboardingDraft) {
        defaults.set(true, forKey: Keys.hasDraft)
        defaults.set(draft.idleThresholdSeconds, forKey: Keys.idleThreshold)
        defaults.set(draft.launchAtLoginEnabled, forKey: Keys.launchAtLogin)
        defaults.set(draft.ttsEnabled, forKey: Keys.ttsEnabled)
        defaults.set(draft.petPresentationMode.rawValue, forKey: Keys.petMode)
    }
    
    func saveResumeStep(_ step: OnboardingStep?) {
        defaults.set(step?.rawValue, forKey: Keys.resumeStep)
    }
    
    func markCompleted() {
        defaults.set(true, forKey: Keys.completed)
        defaults.set(requiredVersion, forKey: Keys.version)
        clearDraft()
    }
    
    func reset() {
        defaults.set(false, forKey: Keys.completed)
        defaults.removeObject(forKey: Keys.version)
        clearDraft()
    }
    
    private func clearDraft() {
        defaults.removeObject(forKey: Keys.resumeStep)
        defaults.removeObject(forKey: Keys.idleThreshold)
        defaults.removeObject(forKey: Keys.launchAtLogin)
        defaults.removeObject(forKey: Keys.ttsEnabled)
        defaults.removeObject(forKey: Keys.petMode)
        defaults.set(false, forKey: Keys.hasDraft)
    }
}
