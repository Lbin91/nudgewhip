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
        static let countdownOverlayEnabled = "onboarding.draft.countdown_overlay_enabled"
        static let preferredLanguage = "onboarding.draft.preferred_language"
        static let scheduleEnabled = "onboarding.draft.schedule_enabled"
        static let scheduleStart = "onboarding.draft.schedule_start"
        static let scheduleEnd = "onboarding.draft.schedule_end"
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
            countdownOverlayEnabled: defaults.object(forKey: Keys.countdownOverlayEnabled) as? Bool ?? true,
            preferredLanguage: AppLanguage(rawValue: defaults.string(forKey: Keys.preferredLanguage) ?? "") ?? .english,
            scheduleEnabled: defaults.bool(forKey: Keys.scheduleEnabled),
            scheduleStartSecondsFromMidnight: defaults.object(forKey: Keys.scheduleStart) as? Int ?? 32_400,
            scheduleEndSecondsFromMidnight: defaults.object(forKey: Keys.scheduleEnd) as? Int ?? 61_200
        )
    }
    
    func saveDraft(_ draft: OnboardingDraft) {
        defaults.set(true, forKey: Keys.hasDraft)
        defaults.set(draft.idleThresholdSeconds, forKey: Keys.idleThreshold)
        defaults.set(draft.launchAtLoginEnabled, forKey: Keys.launchAtLogin)
        defaults.set(draft.countdownOverlayEnabled, forKey: Keys.countdownOverlayEnabled)
        defaults.set(draft.preferredLanguage.rawValue, forKey: Keys.preferredLanguage)
        defaults.set(draft.scheduleEnabled, forKey: Keys.scheduleEnabled)
        defaults.set(draft.scheduleStartSecondsFromMidnight, forKey: Keys.scheduleStart)
        defaults.set(draft.scheduleEndSecondsFromMidnight, forKey: Keys.scheduleEnd)
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
        defaults.removeObject(forKey: Keys.countdownOverlayEnabled)
        defaults.removeObject(forKey: Keys.preferredLanguage)
        defaults.removeObject(forKey: Keys.scheduleEnabled)
        defaults.removeObject(forKey: Keys.scheduleStart)
        defaults.removeObject(forKey: Keys.scheduleEnd)
        defaults.set(false, forKey: Keys.hasDraft)
    }
}
