//
//  nudgeTests.swift
//  nudgeTests
//
//  Created by Bongjin Lee on 4/2/26.
//

import Foundation
import AppKit
import SwiftData
import Testing
@testable import nudge

@MainActor
private final class TestEventMonitor: EventMonitoring {
    private(set) var isMonitoring = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var onActivity: (@MainActor () -> Void)?
    
    func start(onActivity: @escaping @MainActor () -> Void) {
        isMonitoring = true
        startCount += 1
        self.onActivity = onActivity
    }
    
    func stop() {
        isMonitoring = false
        stopCount += 1
        onActivity = nil
    }
    
    func emitActivity() {
        onActivity?()
    }
}

@MainActor
private final class TestLaunchAtLoginManager: LaunchAtLoginManaging {
    private(set) var isEnabled: Bool
    
    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }
    
    func setEnabled(_ enabled: Bool) throws {
        isEnabled = enabled
    }
}

@MainActor
private final class TestSystemLifecycleMonitor: SystemLifecycleMonitoring {
    private(set) var isMonitoring = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private var onEvent: (@MainActor (NudgeRuntimeEvent) -> Void)?
    
    func start(onEvent: @escaping @MainActor (NudgeRuntimeEvent) -> Void) {
        isMonitoring = true
        startCount += 1
        self.onEvent = onEvent
    }
    
    func stop() {
        isMonitoring = false
        stopCount += 1
        onEvent = nil
    }
    
    func emit(_ event: NudgeRuntimeEvent) {
        onEvent?(event)
    }
}

@MainActor
private final class TestFrontmostAppProvider: FrontmostAppProviding {
    private(set) var isMonitoring = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var currentBundleIdentifier: String?
    private var onBundleIdentifierChange: (@MainActor (String?) -> Void)?
    
    func start(onBundleIdentifierChange: @escaping @MainActor (String?) -> Void) {
        isMonitoring = true
        startCount += 1
        self.onBundleIdentifierChange = onBundleIdentifierChange
        onBundleIdentifierChange(currentBundleIdentifier)
    }
    
    func stop() {
        isMonitoring = false
        stopCount += 1
        onBundleIdentifierChange = nil
    }
    
    func emit(bundleIdentifier: String?) {
        currentBundleIdentifier = bundleIdentifier
        onBundleIdentifierChange?(bundleIdentifier)
    }
}

@MainActor
private final class TestAlertPresenter: AlertPresenting {
    private(set) var showCount = 0
    private(set) var hideCount = 0
    private(set) var shownStyles: [AlertVisualStyle] = []
    
    func show(style: AlertVisualStyle) {
        showCount += 1
        shownStyles.append(style)
    }
    
    func hide() {
        hideCount += 1
    }
}

@MainActor
private final class TrackingPanel: NSPanel {
    private(set) var orderFrontCount = 0
    private(set) var orderOutCount = 0
    private(set) var closeCount = 0
    
    override func orderFrontRegardless() {
        orderFrontCount += 1
        super.orderFrontRegardless()
    }
    
    override func orderOut(_ sender: Any?) {
        orderOutCount += 1
        super.orderOut(sender)
    }
    
    override func close() {
        closeCount += 1
        super.close()
    }
}

@MainActor
private final class TestNotificationNudgeManager: NotificationNudgeManaging {
    private(set) var deliverCount = 0
    private(set) var clearCount = 0
    
    func deliverThirdStageNudge() {
        deliverCount += 1
    }
    
    func clearPendingNudges() {
        clearCount += 1
    }
}

@MainActor
private final class TestOnboardingOpener {
    private(set) var callCount = 0
    
    func open() {
        callCount += 1
    }
}

@Suite(.serialized)
struct nudgeTests {

    @Test
    func dailyStatsDerivesOnlyEligibleFocusIntervals() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let dayStart = Date(timeIntervalSince1970: 1_775_088_000) // 2026-04-02 00:00:00 UTC
        let sessions = [
            FocusSession(
                startedAt: dayStart.addingTimeInterval(9 * 60 * 60),
                endedAt: dayStart.addingTimeInterval((10 * 60 + 30) * 60),
                alertCount: 2
            ),
            FocusSession(
                startedAt: dayStart.addingTimeInterval(11 * 60 * 60),
                endedAt: dayStart.addingTimeInterval(11 * 60 * 60 + 20 * 60),
                breakMode: true,
                alertCount: 9
            ),
            FocusSession(
                startedAt: dayStart.addingTimeInterval(-30 * 60),
                endedAt: dayStart.addingTimeInterval(15 * 60),
                alertCount: 1
            )
        ]
        
        let stats = DailyStats.derive(for: sessions, on: dayStart.addingTimeInterval(12 * 60 * 60), calendar: calendar)
        
        #expect(stats.dayStart == dayStart)
        #expect(stats.totalFocusDuration == 6_300)
        #expect(stats.alertCount == 3)
        #expect(stats.longestFocusDuration == 5_400)
        #expect(stats.completedSessionCount == 2)
    }
    
    @MainActor
    @Test
    func bootstrapCreatesSingleDefaultSettingsAndPetState() throws {
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        
        try NudgeDataBootstrap.ensureDefaults(in: context)
        try NudgeDataBootstrap.ensureDefaults(in: context)
        
        let settings = try context.fetch(FetchDescriptor<UserSettings>())
        let petStates = try context.fetch(FetchDescriptor<PetState>())
        
        #expect(settings.count == 1)
        #expect(settings.first?.petPresentationMode == .sprout)
        #expect(settings.first?.countdownOverlayEnabled == true)
        #expect(settings.first?.preferredLocaleIdentifier == AppLanguage.english.rawValue)
        #expect(petStates.count == 1)
        #expect(petStates.first?.stage == .sprout)
        #expect(petStates.first?.emotion == .sleep)
    }
    
    @Test
    func runtimeReducerHonorsPriorityRulesAndRecoveryFlow() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        var snapshot = RuntimeSnapshot()
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .accessibilityGranted, at: baseDate)
        #expect(snapshot.runtimeState == .monitoring)
        #expect(snapshot.contentState == .focus)
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .idleDeadlineReached, at: baseDate.addingTimeInterval(300))
        #expect(snapshot.runtimeState == .alerting)
        #expect(snapshot.contentState == .idleDetected)
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .manualPauseEnabled, at: baseDate.addingTimeInterval(301))
        #expect(snapshot.runtimeState == .pausedManual)
        #expect(snapshot.contentState == .break)
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .manualPauseDisabled, at: baseDate.addingTimeInterval(302))
        #expect(snapshot.runtimeState == .monitoring)
        #expect(snapshot.contentState == .focus)
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .idleDeadlineReached, at: baseDate.addingTimeInterval(600))
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .userActivityDetected, at: baseDate.addingTimeInterval(601))
        #expect(snapshot.runtimeState == .monitoring)
        #expect(snapshot.contentState == .recovery)
        
        snapshot = RuntimeStateReducer.reduce(snapshot, event: .cooldownExpired, at: baseDate.addingTimeInterval(661))
        #expect(snapshot.contentState == .focus)
    }
    
    @MainActor
    @Test
    func idleMonitorUsesOneShotDeadlinesForIdleAlertAndCooldown() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let lifecycleMonitor = TestSystemLifecycleMonitor()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            lifecycleMonitor: lifecycleMonitor,
            idleThreshold: 300,
            alertEscalationInterval: 30,
            cooldownDuration: 60
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        #expect(eventMonitor.isMonitoring)
        idleMonitor.recordInput(at: baseDate)
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(300))
        
        idleMonitor.fireIdleDeadline(at: baseDate.addingTimeInterval(300))
        #expect(runtimeController.snapshot.runtimeState == .alerting)
        #expect(runtimeController.snapshot.contentState == .idleDetected)
        #expect(idleMonitor.alertEscalationDeadlineAt == baseDate.addingTimeInterval(330))
        
        idleMonitor.fireAlertEscalationDeadline(at: baseDate.addingTimeInterval(330))
        #expect(runtimeController.snapshot.contentState == .gentleNudge)
        #expect(idleMonitor.alertEscalationDeadlineAt == baseDate.addingTimeInterval(360))
        
        idleMonitor.recordInput(at: baseDate.addingTimeInterval(331))
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(runtimeController.snapshot.contentState == .recovery)
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(631))
        #expect(idleMonitor.cooldownDeadlineAt == baseDate.addingTimeInterval(391))
        
        idleMonitor.fireCooldownExpired(at: baseDate.addingTimeInterval(391))
        #expect(runtimeController.snapshot.contentState == .focus)
    }
    
    @MainActor
    @Test
    func idleMonitorResumesTimedManualPauseWithFreshBaseline() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        idleMonitor.setManualPause(true, until: baseDate.addingTimeInterval(600), at: baseDate.addingTimeInterval(5))
        
        #expect(runtimeController.snapshot.manualPauseEnabled)
        #expect(runtimeController.snapshot.runtimeState == .pausedManual)
        #expect(idleMonitor.idleDeadlineAt == nil)
        #expect(idleMonitor.manualPauseUntil == baseDate.addingTimeInterval(600))
        
        idleMonitor.fireManualPauseResume(at: baseDate.addingTimeInterval(600))
        
        #expect(!runtimeController.snapshot.manualPauseEnabled)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(idleMonitor.lastInputAt == baseDate.addingTimeInterval(600))
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(900))
        #expect(idleMonitor.manualPauseUntil == nil)
    }
    
    @MainActor
    @Test
    func idleMonitorStartsAndStopsRealInputMonitoringWithPermissionState() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .unknown)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let lifecycleMonitor = TestSystemLifecycleMonitor()
        let frontmostAppProvider = TestFrontmostAppProvider()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            lifecycleMonitor: lifecycleMonitor,
            frontmostAppProvider: frontmostAppProvider,
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        #expect(eventMonitor.startCount == 1)
        #expect(lifecycleMonitor.startCount == 1)
        #expect(frontmostAppProvider.startCount == 1)
        #expect(eventMonitor.isMonitoring)
        #expect(lifecycleMonitor.isMonitoring)
        #expect(frontmostAppProvider.isMonitoring)
        
        eventMonitor.emitActivity()
        #expect(idleMonitor.lastInputAt != nil)
        #expect(idleMonitor.idleDeadlineAt != nil)
        
        idleMonitor.setAccessibilityPermission(.denied, at: baseDate.addingTimeInterval(1))
        #expect(eventMonitor.stopCount == 1)
        #expect(lifecycleMonitor.stopCount == 1)
        #expect(frontmostAppProvider.stopCount == 1)
        #expect(!eventMonitor.isMonitoring)
        #expect(!lifecycleMonitor.isMonitoring)
        #expect(!frontmostAppProvider.isMonitoring)
        #expect(runtimeController.snapshot.runtimeState == .limitedNoAX)
    }
    
    @MainActor
    @Test
    func idleMonitorIgnoresObservedActivityWhileMenuIsPresented() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        let originalDeadline = idleMonitor.idleDeadlineAt
        
        idleMonitor.setMenuPresentationActive(true)
        idleMonitor.handleObservedActivity(at: baseDate.addingTimeInterval(1), isAppActive: true)
        
        #expect(idleMonitor.lastInputAt == baseDate)
        #expect(idleMonitor.idleDeadlineAt == originalDeadline)
        
        idleMonitor.handleObservedActivity(at: baseDate.addingTimeInterval(2), isAppActive: false)
        
        #expect(idleMonitor.lastInputAt != baseDate)
        #expect(idleMonitor.idleDeadlineAt != originalDeadline)
    }
    
    @MainActor
    @Test
    func permissionManagerSupportsPromptAndSettingsCTAInjection() {
        var didPrompt = false
        var openedURL: URL?
        let permissionManager = PermissionManager(
            trustCheck: { promptIfNeeded in
                didPrompt = promptIfNeeded
                return true
            },
            settingsOpener: { url in
                openedURL = url
                return true
            }
        )
        
        let permissionState = permissionManager.refreshAccessibilityPermission(promptIfNeeded: true)
        let didOpenSettings = permissionManager.openAccessibilitySettings()
        
        #expect(didPrompt)
        #expect(permissionState == .granted)
        #expect(didOpenSettings)
        #expect(openedURL == permissionManager.accessibilitySettingsURL)
    }
    
    @Test
    func systemEventMonitorIgnoresMenuBarTrackingEventsWithoutWindow() {
        #expect(
            SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .mouseMoved,
                isAppActive: true,
                hasActiveWindow: false,
                isLocalEvent: false
            )
        )
        #expect(
            !SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .leftMouseDown,
                isAppActive: true,
                hasActiveWindow: false,
                isLocalEvent: true
            )
        )
        #expect(
            SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .mouseMoved,
                isAppActive: false,
                hasActiveWindow: false,
                isLocalEvent: false
            )
        )
        #expect(
            SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .keyDown,
                isAppActive: true,
                hasActiveWindow: true,
                isLocalEvent: true
            )
        )
    }
    
    @Test
    func systemEventMonitorIncludesDraggedPointerEvents() {
        #expect(SystemEventMonitor.monitoredEventTypes.contains(.leftMouseDragged))
        #expect(SystemEventMonitor.monitoredEventTypes.contains(.rightMouseDragged))
        #expect(SystemEventMonitor.monitoredEventTypes.contains(.otherMouseDragged))
    }
    
    @MainActor
    @Test
    func menuBarViewModelReflectsRuntimeIconAndCountdown() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            idleThreshold: 300
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        
        viewModel.startIfNeeded(at: baseDate)
        
        #expect(viewModel.systemImageName == "eye.circle")
        #expect(viewModel.countdownText(now: baseDate) != nil)
        
        idleMonitor.fireIdleDeadline(at: baseDate.addingTimeInterval(300))
        #expect(viewModel.systemImageName == "exclamationmark.circle")
        #expect(viewModel.countdownText(now: baseDate.addingTimeInterval(300)) == nil)
    }

    @MainActor
    @Test
    func menuBarViewModelFormatsConfiguredIdleThresholdForDebugOverlay() {
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 180
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)

        #expect(viewModel.configuredIdleThresholdText == "03:00")
        #expect(viewModel.overlayRuntimeStateText == "Accessibility required")
        #expect(viewModel.overlayCountdownText(now: Date(timeIntervalSince1970: 0)) == nil)
    }
    
    @MainActor
    @Test
    func menuBarViewModelReflectsManualPauseMenuState() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider()
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        
        viewModel.startIfNeeded(at: baseDate)
        #expect(!viewModel.isManualPauseActive)
        
        viewModel.pauseForMinutes(10, at: baseDate.addingTimeInterval(1))
        #expect(viewModel.isManualPauseActive)
        
        viewModel.resumeFromManualPause(at: baseDate.addingTimeInterval(2))
        #expect(!viewModel.isManualPauseActive)
    }
    
    @MainActor
    @Test
    func menuBarViewModelTracksMenuPresentationGuardState() {
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider()
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)
        
        #expect(!viewModel.idleMonitor.isMenuPresentationActive)
        
        viewModel.setMenuPresentationActive(true)
        #expect(viewModel.idleMonitor.isMenuPresentationActive)
        
        viewModel.setMenuPresentationActive(false)
        #expect(!viewModel.idleMonitor.isMenuPresentationActive)
    }
    
    @MainActor
    @Test
    func menuBarViewModelBuildsStaticMenuSnapshotFromSwiftData() throws {
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeDataBootstrap.ensureDefaults(in: context)
        
        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        settings.idleThresholdSeconds = 600
        settings.scheduleEnabled = true
        settings.scheduleStartSecondsFromMidnight = 32_400
        settings.scheduleEndSecondsFromMidnight = 61_200
        settings.petPresentationMode = .minimal
        
        let petState = try #require(try context.fetch(FetchDescriptor<PetState>()).first)
        petState.stage = .buddy
        petState.emotion = .happy
        
        context.insert(WhitelistApp(bundleIdentifier: "com.apple.dt.Xcode"))
        context.insert(
            FocusSession(
                startedAt: Date(timeIntervalSince1970: 1_775_088_000),
                endedAt: Date(timeIntervalSince1970: 1_775_091_600),
                alertCount: 2
            )
        )
        try context.save()
        
        let viewModel = MenuBarViewModel(
            idleMonitor: IdleMonitor(
                permissionManager: PermissionManager(accessibilityPermissionState: .granted),
                runtimeStateController: RuntimeStateController(),
                eventMonitor: TestEventMonitor(),
                lifecycleMonitor: TestSystemLifecycleMonitor(),
                frontmostAppProvider: TestFrontmostAppProvider()
            ),
            modelContext: context
        )
        
        viewModel.refreshMenuSnapshot(now: Date(timeIntervalSince1970: 1_775_091_600))
        
        #expect(viewModel.idleThresholdText.contains("10"))
        #expect(viewModel.scheduleEnabled)
        #expect(viewModel.whitelistCount == 1)
        #expect(viewModel.todayStats.alertCount == 2)
    }

    @MainActor
    @Test
    func menuBarViewModelRefreshSnapshotAppliesPersistedIdleThresholdBeforeMonitoringStarts() throws {
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeDataBootstrap.ensureDefaults(in: context)

        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        settings.idleThresholdSeconds = 180
        try context.save()

        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider()
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor, modelContext: context)

        viewModel.refreshMenuSnapshot(now: baseDate)
        viewModel.startIfNeeded(at: baseDate)

        #expect(viewModel.configuredIdleThresholdText == "03:00")
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(180))
    }

    @MainActor
    @Test
    func menuBarViewModelUsesMinutesThenSecondsForOverlayCountdown() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 180
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)

        viewModel.startIfNeeded(at: baseDate)

        #expect(viewModel.overlayCountdownText(now: baseDate) == "3m")
        #expect(viewModel.overlayCountdownText(now: baseDate.addingTimeInterval(121)) == "59s")
    }
    
    @MainActor
    @Test
    func settingsViewModelPersistsSettingsAndLaunchAtLogin() throws {
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeDataBootstrap.ensureDefaults(in: context)
        
        let menuBarViewModel = MenuBarViewModel(
            idleMonitor: IdleMonitor(
                permissionManager: PermissionManager(accessibilityPermissionState: .granted),
                runtimeStateController: RuntimeStateController(),
                eventMonitor: TestEventMonitor(),
                lifecycleMonitor: TestSystemLifecycleMonitor(),
                frontmostAppProvider: TestFrontmostAppProvider()
            ),
            modelContext: context
        )
        let opener = TestOnboardingOpener()
        let launchAtLoginManager = TestLaunchAtLoginManager()
        let viewModel = SettingsViewModel(
            modelContext: context,
            menuBarViewModel: menuBarViewModel,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: launchAtLoginManager,
            onOpenOnboarding: opener.open
        )
        
        viewModel.updateIdleThreshold(600)
        viewModel.updateCountdownOverlayEnabled(false)
        viewModel.updateScheduleEnabled(true)
        viewModel.updateLaunchAtLogin(true)
        viewModel.openOnboarding()

        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(settings.idleThresholdSeconds == 600)
        #expect(settings.countdownOverlayEnabled == false)
        #expect(settings.scheduleEnabled)
        #expect(launchAtLoginManager.isEnabled)
        #expect(opener.callCount == 1)
        #expect(viewModel.idleThresholdSecondsValue == 600)
        #expect(viewModel.countdownOverlayEnabledValue == false)
    }
    
    @MainActor
    @Test
    func menuBarViewModelRejectsSameStartAndEndScheduleTimes() throws {
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeDataBootstrap.ensureDefaults(in: context)
        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        
        let viewModel = MenuBarViewModel(
            idleMonitor: IdleMonitor(
                permissionManager: PermissionManager(accessibilityPermissionState: .granted),
                runtimeStateController: RuntimeStateController(),
                eventMonitor: TestEventMonitor(),
                lifecycleMonitor: TestSystemLifecycleMonitor(),
                frontmostAppProvider: TestFrontmostAppProvider()
            ),
            modelContext: context
        )
        
        let originalStart = settings.scheduleStartSecondsFromMidnight
        let originalEnd = settings.scheduleEndSecondsFromMidnight
        let startDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(originalStart))
        let endDate = Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(originalEnd))
        
        viewModel.updateScheduleStartTime(endDate)
        viewModel.updateScheduleEndTime(startDate)
        
        #expect(settings.scheduleStartSecondsFromMidnight == originalStart)
        #expect(settings.scheduleEndSecondsFromMidnight == originalEnd)
    }
    
    @MainActor
    @Test
    func idleMonitorSuspendsAndResumesAcrossSystemLifecycleEvents() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let lifecycleMonitor = TestSystemLifecycleMonitor()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            lifecycleMonitor: lifecycleMonitor,
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(300))
        
        lifecycleMonitor.emit(.sleepDetected)
        #expect(runtimeController.snapshot.runtimeState == .suspendedSleepOrLock)
        #expect(idleMonitor.idleDeadlineAt == nil)
        
        lifecycleMonitor.emit(.wakeDetected)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(idleMonitor.idleDeadlineAt != nil)
        
        lifecycleMonitor.emit(.screenLocked)
        #expect(runtimeController.snapshot.runtimeState == .suspendedSleepOrLock)
        
        lifecycleMonitor.emit(.screenUnlocked)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        
        lifecycleMonitor.emit(.fastUserSwitchingStarted)
        #expect(runtimeController.snapshot.runtimeState == .suspendedSleepOrLock)
        
        lifecycleMonitor.emit(.fastUserSwitchingEnded)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
    }
    
    @MainActor
    @Test
    func idleMonitorAppliesUserSettingsThresholdToRuntimeDeadline() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let settings = UserSettings(idleThresholdSeconds: 10)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor()
        )
        
        idleMonitor.applySettings(settings, at: baseDate)
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(10))
    }
    
    @MainActor
    @Test
    func idleMonitorResumesImmediatelyWhenScheduleIsTurnedOff() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            scheduleEnabled: true,
            scheduleStart: 32_400,
            scheduleEnd: 61_200
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.checkSchedule(at: baseDate.addingTimeInterval(70_000))
        #expect(runtimeController.snapshot.runtimeState == .pausedSchedule)
        
        let updatedSettings = UserSettings(
            scheduleEnabled: false,
            scheduleStartSecondsFromMidnight: 32_400,
            scheduleEndSecondsFromMidnight: 61_200
        )
        idleMonitor.applySettings(updatedSettings, at: baseDate.addingTimeInterval(70_001))
        
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(idleMonitor.lastInputAt == baseDate.addingTimeInterval(70_001))
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(70_301))
    }
    
    @MainActor
    @Test
    func idleMonitorResetsBaselineWhenScheduleWindowReopens() {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_775_088_000))
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300,
            scheduleEnabled: true,
            scheduleStart: 32_400,
            scheduleEnd: 61_200
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        idleMonitor.checkSchedule(at: baseDate.addingTimeInterval(70_000))
        #expect(runtimeController.snapshot.runtimeState == .pausedSchedule)
        
        let resumeDate = baseDate.addingTimeInterval(86_400 + 33_000)
        idleMonitor.checkSchedule(at: resumeDate)
        
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(idleMonitor.lastInputAt == resumeDate)
        #expect(idleMonitor.idleDeadlineAt == resumeDate.addingTimeInterval(300))
    }
    
    @MainActor
    @Test
    func alertManagerShowsAndHidesPerimeterPulseAcrossAlertLifecycle() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )
        
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .idleDetected,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                suspended: false,
                lastInputAt: nil
            )
        )
        #expect(presenter.showCount == 1)
        #expect(presenter.shownStyles == [.perimeterPulse])
        
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .strongNudge,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                suspended: false,
                lastInputAt: nil
            )
        )
        #expect(presenter.showCount == 2)
        #expect(presenter.shownStyles == [.perimeterPulse, .strongVisualNudge])
        #expect(notificationManager.deliverCount == 0)
        
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .strongNudge,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 4,
                lastInputAt: nil
            )
        )
        #expect(notificationManager.deliverCount == 1)
        
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .monitoring,
                contentState: .recovery,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                lastInputAt: nil
            )
        )
        #expect(presenter.hideCount == 1)
        #expect(notificationManager.clearCount == 1)
    }
    
    @MainActor
    @Test
    func alertManagerRespectsHourlyAlertAndNotificationLimits() {
        var currentTime = Date(timeIntervalSince1970: 1_775_088_000)
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager,
            nowProvider: { currentTime }
        )
        alertManager.apply(
            settings: UserSettings(
                alertsPerHourLimit: 2,
                notificationNudgePerHourLimit: 1
            )
        )
        
        let idleSnapshot = RuntimeSnapshot(
            runtimeState: .alerting,
            contentState: .idleDetected,
            accessibilityGranted: true,
            manualPauseEnabled: false,
            whitelistMatched: false,
            schedulePaused: false,
            suspended: false,
            alertEscalationStep: 1,
            lastInputAt: nil
        )
        
        alertManager.handle(snapshot: idleSnapshot)
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .monitoring,
                contentState: .recovery,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 0,
                lastInputAt: nil
            )
        )
        currentTime.addTimeInterval(10)
        alertManager.handle(snapshot: idleSnapshot)
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .monitoring,
                contentState: .recovery,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 0,
                lastInputAt: nil
            )
        )
        currentTime.addTimeInterval(10)
        alertManager.handle(snapshot: idleSnapshot)
        
        #expect(presenter.showCount == 2)
        
        let notificationSnapshot = RuntimeSnapshot(
            runtimeState: .alerting,
            contentState: .strongNudge,
            accessibilityGranted: true,
            manualPauseEnabled: false,
            whitelistMatched: false,
            schedulePaused: false,
            suspended: false,
            alertEscalationStep: 4,
            lastInputAt: nil
        )
        alertManager.handle(snapshot: notificationSnapshot)
        currentTime.addTimeInterval(30)
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .strongNudge,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 5,
                lastInputAt: nil
            )
        )
        
        #expect(notificationManager.deliverCount == 1)
    }
    
    @MainActor
    @Test
    func perimeterPulsePresenterShowsAndHidesPanelsAcrossAllScreens() {
        let frames: [CGRect] = [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        ]
        var createdPanels: [TrackingPanel] = []
        let presenter = PerimeterPulsePresenter(
            screenFramesProvider: { frames },
            panelFactory: { frame in
                let panel = TrackingPanel(
                    contentRect: frame,
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered,
                    defer: false
                )
                createdPanels.append(panel)
                return panel
            }
        )
        
        presenter.show(style: .perimeterPulse)
        #expect(createdPanels.count == 2)
        #expect(createdPanels.allSatisfy { $0.orderFrontCount == 1 })
        
        presenter.show(style: .strongVisualNudge)
        #expect(createdPanels.count == 2)
        #expect(createdPanels.allSatisfy { $0.orderFrontCount == 2 })
        
        presenter.hide()
        #expect(createdPanels.allSatisfy { $0.orderOutCount == 1 })
        #expect(createdPanels.allSatisfy { $0.closeCount == 1 })
    }
    
    @MainActor
    @Test
    func idleMonitorPausesWhileWhitelistedFrontmostAppIsActive() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .granted)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let lifecycleMonitor = TestSystemLifecycleMonitor()
        let frontmostAppProvider = TestFrontmostAppProvider()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            lifecycleMonitor: lifecycleMonitor,
            frontmostAppProvider: frontmostAppProvider,
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(300))
        
        idleMonitor.applyWhitelistApps(
            [
                WhitelistApp(bundleIdentifier: "com.apple.dt.Xcode"),
                WhitelistApp(bundleIdentifier: "com.apple.Safari", isEnabled: false)
            ],
            at: baseDate.addingTimeInterval(1)
        )
        
        frontmostAppProvider.emit(bundleIdentifier: "com.apple.dt.Xcode")
        #expect(runtimeController.snapshot.runtimeState == .pausedWhitelist)
        #expect(runtimeController.snapshot.whitelistMatched)
        #expect(idleMonitor.idleDeadlineAt == nil)
        
        frontmostAppProvider.emit(bundleIdentifier: "com.apple.finder")
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
        #expect(!runtimeController.snapshot.whitelistMatched)
        #expect(idleMonitor.idleDeadlineAt != nil)
    }
    
    @MainActor
    @Test
    func onboardingStorageTracksCompletionResumeAndDraft() {
        let defaults = UserDefaults(suiteName: "nudgeTests.onboarding.storage.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults, requiredVersion: 2)
        
        #expect(storage.shouldPresentOnboarding)
        #expect(storage.resumeStep == nil)
        #expect(storage.savedDraft == nil)
        
        let draft = OnboardingDraft(
            idleThresholdSeconds: 600,
            launchAtLoginEnabled: true,
            countdownOverlayEnabled: false,
            preferredLanguage: .korean,
            petPresentationMode: .minimal,
            scheduleEnabled: true,
            scheduleStartSecondsFromMidnight: 32_400,
            scheduleEndSecondsFromMidnight: 61_200
        )
        storage.saveDraft(draft)
        storage.saveResumeStep(.basicSetup)
        
        #expect(storage.savedDraft == draft)
        #expect(storage.resumeStep == .basicSetup)
        
        storage.markCompleted()
        
        #expect(!storage.shouldPresentOnboarding)
        #expect(storage.resumeStep == nil)
        #expect(storage.savedDraft == nil)
    }
    
    @MainActor
    @Test
    func onboardingViewModelPersistsSelectionsAndTransitions() throws {
        let defaults = UserDefaults(suiteName: "nudgeTests.onboarding.viewmodel.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let permissionManager = PermissionManager(
            accessibilityPermissionState: .granted,
            trustCheck: { _ in true },
            settingsOpener: { _ in true }
        )
        let launchAtLoginManager = TestLaunchAtLoginManager()
        var didFinish = false
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: container,
            permissionManager: permissionManager,
            launchAtLoginManager: launchAtLoginManager
        ) {
            didFinish = true
        }
        
        viewModel.continueFromWelcome()
        viewModel.requestPermission()
        #expect(viewModel.step == .basicSetup)
        
        viewModel.idleThresholdSeconds = 600
        viewModel.countdownOverlayEnabled = false
        viewModel.preferredLanguage = .korean
        viewModel.launchAtLoginEnabled = true
        viewModel.continueFromBasicSetup()
        #expect(viewModel.step == .scheduleSetup)
        
        viewModel.scheduleEnabled = true
        viewModel.scheduleStartSecondsFromMidnight = 32_400
        viewModel.scheduleEndSecondsFromMidnight = 61_200
        viewModel.continueFromScheduleSetup()
        #expect(viewModel.step == .completionReady)
        
        viewModel.finish()
        #expect(didFinish)
        #expect(launchAtLoginManager.isEnabled)
        
        let settings = try container.mainContext.fetch(FetchDescriptor<UserSettings>())
        #expect(settings.first?.idleThresholdSeconds == 600)
        #expect(settings.first?.countdownOverlayEnabled == false)
        #expect(settings.first?.preferredLocaleIdentifier == AppLanguage.korean.rawValue)
        #expect(settings.first?.scheduleEnabled == true)
        #expect(settings.first?.scheduleStartSecondsFromMidnight == 32_400)
        #expect(settings.first?.scheduleEndSecondsFromMidnight == 61_200)
        #expect(!storage.shouldPresentOnboarding)
    }
    
    @MainActor
    @Test
    func onboardingViewModelPreservesDraftOnBasicSetupWindowClose() throws {
        let defaults = UserDefaults(suiteName: "nudgeTests.onboarding.close.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let container = try NudgeModelContainer.makeModelContainer(inMemory: true)
        let permissionManager = PermissionManager(
            accessibilityPermissionState: .granted,
            trustCheck: { _ in true },
            settingsOpener: { _ in true }
        )
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: container,
            permissionManager: permissionManager,
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}
        
        viewModel.continueFromWelcome()
        viewModel.requestPermission()
        viewModel.idleThresholdSeconds = 180
        
        let shouldStartApp = viewModel.handleWindowClose()
        
        #expect(shouldStartApp)
        #expect(storage.resumeStep == .basicSetup)
        #expect(storage.savedDraft?.idleThresholdSeconds == 180)
        #expect(storage.savedDraft?.preferredLanguage == .english)
        #expect(storage.shouldPresentOnboarding)
    }
    
    @MainActor
    @Test
    func onboardingViewModelCanRestartManualReentryFromWelcome() {
        let defaults = UserDefaults(suiteName: "nudgeTests.onboarding.restart.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: NudgeModelContainer.preview,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}
        
        viewModel.continueFromWelcome()
        viewModel.continueFromPermission()
        #expect(viewModel.step == .basicSetup)
        
        viewModel.restartFromWelcome()
        
        #expect(viewModel.step == .welcome)
        #expect(storage.resumeStep == .welcome)
    }
    
    @Test
    func onboardingWindowMetricsClampOversizedHeightsToVisibleFrame() {
        #expect(OnboardingWindowMetrics.clampedContentHeight(560, visibleFrameHeight: 900) == 560)
        #expect(OnboardingWindowMetrics.clampedContentHeight(1200, visibleFrameHeight: 900) == 640)
        #expect(OnboardingWindowMetrics.clampedContentHeight(1200, visibleFrameHeight: 520) == 460)
    }
    
    @MainActor
    @Test
    func onboardingViewModelExposesStepSpecificPreferredHeights() {
        let deniedDefaults = UserDefaults(suiteName: "nudgeTests.onboarding.heights.denied.\(UUID().uuidString)")!
        let deniedStorage = OnboardingStorage(defaults: deniedDefaults)
        deniedStorage.saveResumeStep(.permission)
        let deniedViewModel = OnboardingViewModel(
            storage: deniedStorage,
            modelContainer: NudgeModelContainer.preview,
            permissionManager: PermissionManager(accessibilityPermissionState: .denied),
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}
        
        #expect(deniedViewModel.preferredContentHeight == 640)
        
        let grantedDefaults = UserDefaults(suiteName: "nudgeTests.onboarding.heights.granted.\(UUID().uuidString)")!
        let grantedStorage = OnboardingStorage(defaults: grantedDefaults)
        grantedStorage.saveResumeStep(.permission)
        let grantedViewModel = OnboardingViewModel(
            storage: grantedStorage,
            modelContainer: NudgeModelContainer.preview,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}
        
        #expect(grantedViewModel.preferredContentHeight == 560)
        grantedViewModel.continueFromPermission()
        #expect(grantedViewModel.preferredContentHeight == 620)
        grantedViewModel.handleDidBecomeActive()
        #expect(grantedViewModel.step == .basicSetup)
        grantedViewModel.continueFromBasicSetup()
        #expect(grantedViewModel.preferredContentHeight == 560)
    }

}
