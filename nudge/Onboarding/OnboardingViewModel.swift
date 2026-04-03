import Foundation
import Observation
import SwiftData
import CoreGraphics

@MainActor
@Observable
final class OnboardingViewModel {
    let permissionManager: PermissionManager
    
    private let storage: OnboardingStoring
    private let modelContainer: ModelContainer
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let onFinishRequested: () -> Void
    
    var step: OnboardingStep
    var permissionState: AccessibilityPermissionState
    var idleThresholdSeconds: Int {
        didSet { persistDraft() }
    }
    var launchAtLoginEnabled: Bool {
        didSet { persistDraft() }
    }
    var ttsEnabled: Bool {
        didSet { persistDraft() }
    }
    var petPresentationMode: PetPresentationMode {
        didSet { persistDraft() }
    }
    var scheduleEnabled: Bool {
        didSet { persistDraft() }
    }
    var scheduleStartSecondsFromMidnight: Int {
        didSet { persistDraft() }
    }
    var scheduleEndSecondsFromMidnight: Int {
        didSet { persistDraft() }
    }
    var errorMessage: String?
    
    init(
        storage: OnboardingStoring,
        modelContainer: ModelContainer,
        permissionManager: PermissionManager,
        launchAtLoginManager: LaunchAtLoginManaging,
        onFinishRequested: @escaping () -> Void
    ) {
        self.storage = storage
        self.modelContainer = modelContainer
        self.permissionManager = permissionManager
        self.launchAtLoginManager = launchAtLoginManager
        self.onFinishRequested = onFinishRequested
        
        let initialDraft = Self.makeInitialDraft(
            storage: storage,
            modelContainer: modelContainer,
            launchAtLoginManager: launchAtLoginManager
        )
        self.step = storage.resumeStep ?? .welcome
        self.permissionState = permissionManager.accessibilityPermissionState
        self.idleThresholdSeconds = initialDraft.idleThresholdSeconds
        self.launchAtLoginEnabled = initialDraft.launchAtLoginEnabled
        self.ttsEnabled = initialDraft.ttsEnabled
        self.petPresentationMode = initialDraft.petPresentationMode
        self.scheduleEnabled = initialDraft.scheduleEnabled
        self.scheduleStartSecondsFromMidnight = initialDraft.scheduleStartSecondsFromMidnight
        self.scheduleEndSecondsFromMidnight = initialDraft.scheduleEndSecondsFromMidnight
        
        persistDraft()
    }
    
    var showsBackButton: Bool {
        step == .permission || step == .basicSetup || step == .scheduleSetup
    }
    
    var progressText: String {
        "\(step.progressIndex)/5"
    }
    
    var preferredContentHeight: CGFloat {
        OnboardingWindowMetrics.contentHeight(for: step, permissionState: permissionState)
    }
    
    func goBack() {
        switch step {
        case .permission:
            step = .welcome
        case .basicSetup:
            step = .permission
        case .scheduleSetup:
            step = .basicSetup
        default:
            return
        }
        storage.saveResumeStep(step)
    }
    
    func continueFromWelcome() {
        step = .permission
        storage.saveResumeStep(step)
    }
    
    func requestPermission() {
        refreshPermission(promptIfNeeded: true)
    }
    
    @discardableResult
    func openAccessibilitySettings() -> Bool {
        permissionManager.openAccessibilitySettings()
    }
    
    func handleDidBecomeActive() {
        refreshPermission(promptIfNeeded: false)
    }
    
    func setUpLater() {
        step = .completionLimited
        storage.saveResumeStep(step)
    }
    
    func continueFromPermission() {
        step = .basicSetup
        storage.saveResumeStep(step)
    }
    
    func continueFromBasicSetup() {
        step = .scheduleSetup
        storage.saveResumeStep(step)
    }
    
    func continueFromScheduleSetup() {
        step = permissionManager.isAccessibilityGranted ? .completionReady : .completionLimited
        storage.saveResumeStep(step)
    }
    
    func retryPermission() {
        step = .permission
        storage.saveResumeStep(step)
        requestPermission()
    }
    
    func finish() {
        errorMessage = nil
        
        do {
            try persistSelections()
            storage.markCompleted()
            onFinishRequested()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func handleWindowClose() -> Bool {
        switch step {
        case .welcome, .permission:
            storage.markCompleted()
            return true
        case .basicSetup, .scheduleSetup:
            storage.saveResumeStep(step)
            return true
        case .completionReady, .completionLimited:
            do {
                try persistSelections()
                storage.markCompleted()
            } catch {
                errorMessage = error.localizedDescription
            }
            return true
        }
    }
    
    private func refreshPermission(promptIfNeeded: Bool) {
        permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: promptIfNeeded)
        if permissionManager.isAccessibilityGranted, step == .permission {
            step = .basicSetup
            storage.saveResumeStep(step)
        }
    }
    
    private func persistSelections() throws {
        let context = modelContainer.mainContext
        try NudgeDataBootstrap.ensureDefaults(in: context)
        
        if let settings = try context.fetch(FetchDescriptor<UserSettings>()).first {
            settings.idleThresholdSeconds = idleThresholdSeconds
            settings.ttsEnabled = ttsEnabled
            settings.petPresentationMode = petPresentationMode
            settings.scheduleEnabled = scheduleEnabled
            settings.scheduleStartSecondsFromMidnight = scheduleStartSecondsFromMidnight
            settings.scheduleEndSecondsFromMidnight = scheduleEndSecondsFromMidnight
            settings.updatedAt = .now
        }
        
        try launchAtLoginManager.setEnabled(launchAtLoginEnabled)
        try context.save()
    }
    
    private func persistDraft() {
        storage.saveDraft(
            OnboardingDraft(
                idleThresholdSeconds: idleThresholdSeconds,
                launchAtLoginEnabled: launchAtLoginEnabled,
                ttsEnabled: ttsEnabled,
                petPresentationMode: petPresentationMode,
                scheduleEnabled: scheduleEnabled,
                scheduleStartSecondsFromMidnight: scheduleStartSecondsFromMidnight,
                scheduleEndSecondsFromMidnight: scheduleEndSecondsFromMidnight
            )
        )
    }
    
    private static func makeInitialDraft(
        storage: OnboardingStoring,
        modelContainer: ModelContainer,
        launchAtLoginManager: LaunchAtLoginManaging
    ) -> OnboardingDraft {
        if let savedDraft = storage.savedDraft {
            return savedDraft
        }
        
        let context = modelContainer.mainContext
        try? NudgeDataBootstrap.ensureDefaults(in: context)
        let settings = try? context.fetch(FetchDescriptor<UserSettings>()).first
        
        return OnboardingDraft(
            idleThresholdSeconds: settings?.idleThresholdSeconds ?? 300,
            launchAtLoginEnabled: storage.shouldPresentOnboarding ? true : launchAtLoginManager.isEnabled,
            ttsEnabled: settings?.ttsEnabled ?? true,
            petPresentationMode: settings?.petPresentationMode ?? .sprout,
            scheduleEnabled: settings?.scheduleEnabled ?? false,
            scheduleStartSecondsFromMidnight: settings?.scheduleStartSecondsFromMidnight ?? 32_400,
            scheduleEndSecondsFromMidnight: settings?.scheduleEndSecondsFromMidnight ?? 61_200
        )
    }
}
