//
//  nudgewhipTests.swift
//  nudgewhipTests
//
//  Created by Bongjin Lee on 4/2/26.
//

import Foundation
import AppKit
import SwiftData
import Testing
@testable import nudgewhip

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

private func appSnapshot(
    bundleIdentifier: String?,
    localizedName: String? = nil,
    processIdentifier: pid_t? = nil
) -> FrontmostAppSnapshot {
    FrontmostAppSnapshot(
        bundleIdentifier: bundleIdentifier,
        localizedName: localizedName,
        processIdentifier: processIdentifier
    )
}

@Test
func localizedDurationStringUsesSelectedAppLanguage() {
    let originalLocaleIdentifier = AppLanguageStore.shared.preferredLocaleIdentifier
    defer {
        AppLanguageStore.shared.apply(preferredLocaleIdentifier: originalLocaleIdentifier)
    }

    AppLanguageStore.shared.apply(preferredLocaleIdentifier: AppLanguage.english.rawValue)
    #expect(localizedDurationString(3_661) == "1h 1m")

    AppLanguageStore.shared.apply(preferredLocaleIdentifier: AppLanguage.korean.rawValue)
    #expect(localizedDurationString(3_661) == "1시간 1분")
}

@Test
func appLanguageFallsBackToSupportedSystemLanguage() {
    #expect(AppLanguage.resolve(nil, preferredLanguages: ["ko-KR"]) == .korean)
    #expect(AppLanguage.resolve(nil, preferredLanguages: ["en-US"]) == .english)
    #expect(AppLanguage.resolve(nil, preferredLanguages: ["ja-JP"]) == .english)
}

@Test
func alertVisualConfigurationDisablesPulseForReduceMotion() {
    let configuration = alertVisualConfiguration(
        for: .gentleNudge,
        accessibility: AlertAccessibilityOptions(reduceMotion: true)
    )

    #expect(!configuration.animatePulse)
    #expect(!configuration.animatesMessageEntrance)
    #expect(configuration.activeOpacity == 1.0)
    #expect(configuration.idleOpacity >= 0.52)
}

@Test
func alertVisualConfigurationAddsNonColorMarkersForDifferentiateWithoutColor() {
    let perimeterConfiguration = alertVisualConfiguration(
        for: .perimeterPulse,
        accessibility: AlertAccessibilityOptions(differentiateWithoutColor: true)
    )
    let gentleConfiguration = alertVisualConfiguration(
        for: .gentleNudge,
        accessibility: AlertAccessibilityOptions(differentiateWithoutColor: true)
    )

    #expect(perimeterConfiguration.showsStageBadge)
    #expect(perimeterConfiguration.dashPattern == [18, 12])
    #expect(gentleConfiguration.showsStageBadge)
    #expect(gentleConfiguration.dashPattern == [8, 8])
}

@Test
func alertVisualConfigurationStrengthensSurfaceForHighContrast() {
    let configuration = alertVisualConfiguration(
        for: .strongVisualNudge,
        accessibility: AlertAccessibilityOptions(increaseContrast: true, reduceTransparency: true)
    )

    #expect(configuration.usesOpaqueSurface)
    #expect(configuration.borderWidth == 20)
    #expect(configuration.shadowRadius == 28)
    #expect(configuration.backdropActiveOpacity == 0.24)
}

@Test
func countdownOverlayAccessibilityConfigurationStrengthensContrastWhenNeeded() {
    let baseline = countdownOverlayAccessibilityConfiguration(
        increaseContrast: false,
        reduceTransparency: false
    )
    let accessible = countdownOverlayAccessibilityConfiguration(
        increaseContrast: true,
        reduceTransparency: true
    )

    #expect(baseline.backgroundOpacity == 0.68)
    #expect(accessible.backgroundOpacity == 0.9)
    #expect(accessible.strokeOpacity == 0.24)
    #expect(accessible.closeButtonBackgroundOpacity == 0.18)
}

@Test
func countdownOverlayOriginPlacesPanelAtRequestedCorner() {
    let visibleFrame = CGRect(x: 100, y: 50, width: 1440, height: 900)
    let panelSize = CGSize(width: 146, height: 72)
    let inset: CGFloat = 14

    #expect(countdownOverlayOrigin(visibleFrame: visibleFrame, panelSize: panelSize, inset: inset, position: .topLeft) == CGPoint(x: 114, y: 864))
    #expect(countdownOverlayOrigin(visibleFrame: visibleFrame, panelSize: panelSize, inset: inset, position: .topRight) == CGPoint(x: 1380, y: 864))
    #expect(countdownOverlayOrigin(visibleFrame: visibleFrame, panelSize: panelSize, inset: inset, position: .bottomLeft) == CGPoint(x: 114, y: 64))
    #expect(countdownOverlayOrigin(visibleFrame: visibleFrame, panelSize: panelSize, inset: inset, position: .bottomRight) == CGPoint(x: 1380, y: 64))
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
    private var onEvent: (@MainActor (NudgeWhipRuntimeEvent) -> Void)?
    
    func start(onEvent: @escaping @MainActor (NudgeWhipRuntimeEvent) -> Void) {
        isMonitoring = true
        startCount += 1
        self.onEvent = onEvent
    }
    
    func stop() {
        isMonitoring = false
        stopCount += 1
        onEvent = nil
    }
    
    func emit(_ event: NudgeWhipRuntimeEvent) {
        onEvent?(event)
    }
}

@MainActor
private final class TestFrontmostAppProvider: FrontmostAppProviding {
    private(set) var isMonitoring = false
    private(set) var startCount = 0
    private(set) var stopCount = 0
    var currentApp: FrontmostAppSnapshot?
    private var onChange: (@MainActor (FrontmostAppSnapshot?) -> Void)?

    func start(onChange: @escaping @MainActor (FrontmostAppSnapshot?) -> Void) {
        isMonitoring = true
        startCount += 1
        self.onChange = onChange
        onChange(currentApp)
    }

    func stop() {
        isMonitoring = false
        stopCount += 1
        onChange = nil
    }

    func emit(
        bundleIdentifier: String?,
        localizedName: String? = nil,
        processIdentifier: pid_t? = nil
    ) {
        let resolvedLocalizedName: String?
        if let localizedName {
            resolvedLocalizedName = localizedName
        } else {
            resolvedLocalizedName = bundleIdentifier.flatMap { bundleIdentifier in
                bundleIdentifier.split(separator: ".").last.map(String.init)
            }
        }

        let snapshot = FrontmostAppSnapshot(
            bundleIdentifier: bundleIdentifier,
            localizedName: resolvedLocalizedName,
            processIdentifier: processIdentifier
        )
        currentApp = snapshot
        onChange?(snapshot)
    }
}

@MainActor
private final class TestSessionTracker: SessionTracking {
    private(set) var isTracking = false
    private(set) var beginSessionCount = 0
    private(set) var endSessionCount = 0
    private(set) var alertStartedCount = 0
    private(set) var recoveryCount = 0

    func beginSession(at date: Date) {
        beginSessionCount += 1
        isTracking = true
    }

    func endSession(reason: FocusSessionEndReason, at date: Date) {
        guard isTracking else { return }
        endSessionCount += 1
        isTracking = false
    }

    func recordAlertStarted(at date: Date) {
        alertStartedCount += 1
    }

    func recordAlertEscalation(step: Int, at date: Date) {}

    func recordRecovery(at date: Date) {
        recoveryCount += 1
    }
}

@MainActor
private final class TestAlertPresenter: AlertPresenting {
    private(set) var showCount = 0
    private(set) var hideCount = 0
    private(set) var shownStyles: [AlertVisualStyle] = []
    private(set) var shownMessages: [String?] = []
    
    func show(style: AlertVisualStyle, message: String?) {
        showCount += 1
        shownStyles.append(style)
        shownMessages.append(message)
    }
    
    func hide() {
        hideCount += 1
    }
}

@MainActor
private final class TestAlertSoundPlayer: AlertSoundPlaying {
    struct PlayCall: Equatable {
        let soundName: String
        let repeatCount: Int
        let interval: TimeInterval
    }

    private(set) var playCalls: [PlayCall] = []
    private(set) var stopAllCount = 0

    func play(named soundName: String, repeatCount: Int, interval: TimeInterval) {
        playCalls.append(PlayCall(soundName: soundName, repeatCount: repeatCount, interval: interval))
    }

    func stopAll() {
        stopAllCount += 1
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
    private(set) var deliveredBodies: [String] = []
    
    func deliverThirdStageNudge(body: String) {
        deliverCount += 1
        deliveredBodies.append(body)
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

@MainActor
private final class TestExternalURLOpener {
    private(set) var openedURLs: [URL] = []
    var returnValue = true

    func open(_ url: URL) -> Bool {
        openedURLs.append(url)
        return returnValue
    }
}

@MainActor
private final class TestAppUpdater: AppUpdating {
    private(set) var canCheckForUpdates: Bool
    private(set) var isConfigured: Bool
    private(set) var checkForUpdatesCallCount = 0
    var onCanCheckForUpdatesChanged: (@MainActor (Bool) -> Void)?

    init(canCheckForUpdates: Bool = false, isConfigured: Bool = false) {
        self.canCheckForUpdates = canCheckForUpdates
        self.isConfigured = isConfigured
    }

    func checkForUpdates() {
        checkForUpdatesCallCount += 1
    }

    func setCanCheckForUpdates(_ canCheckForUpdates: Bool) {
        self.canCheckForUpdates = canCheckForUpdates
        onCanCheckForUpdatesChanged?(canCheckForUpdates)
    }
}

@Suite(.serialized)
struct nudgewhipTests {

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

    @Test
    func dailyStatsDerivesRecoveryMetrics() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let dayStart = Date(timeIntervalSince1970: 1_775_088_000) // 2026-04-02 00:00:00 UTC
        let session = FocusSession(
            startedAt: dayStart.addingTimeInterval(9 * 60 * 60),
            endedAt: dayStart.addingTimeInterval(11 * 60 * 60),
            alertCount: 2
        )
        session.alertingSegments = [
            AlertingSegment(
                startedAt: dayStart.addingTimeInterval(9 * 60 * 60 + 10 * 60),
                recoveredAt: dayStart.addingTimeInterval(9 * 60 * 60 + 14 * 60),
                focusSession: session
            ),
            AlertingSegment(
                startedAt: dayStart.addingTimeInterval(10 * 60 * 60 + 5 * 60),
                recoveredAt: dayStart.addingTimeInterval(10 * 60 * 60 + 12 * 60),
                focusSession: session
            )
        ]

        let stats = DailyStats.derive(for: [session], on: dayStart.addingTimeInterval(12 * 60 * 60), calendar: calendar)

        #expect(stats.recoverySampleCount == 2)
        #expect(stats.recoveryDurationTotal == 660)
        #expect(stats.recoveryDurationMax == 420)
        #expect(stats.averageRecoveryDuration == 330)
        #expect(stats.recoveryRate == 1)
    }

    @Test
    func statisticsSnapshotAggregatesCurrentWeekAndTrailingSevenDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2

        let referenceDate = Date(timeIntervalSince1970: 1_775_606_400) // 2026-04-08 00:00:00 UTC
        let monday = Date(timeIntervalSince1970: 1_775_433_600) // 2026-04-06 00:00:00 UTC
        let sessions = [
            FocusSession(
                startedAt: monday.addingTimeInterval(9 * 60 * 60),
                endedAt: monday.addingTimeInterval(10 * 60 * 60),
                alertCount: 1
            ),
            FocusSession(
                startedAt: monday.addingTimeInterval(24 * 60 * 60 + 13 * 60 * 60),
                endedAt: monday.addingTimeInterval(24 * 60 * 60 + 15 * 60 * 60),
                alertCount: 2
            ),
            FocusSession(
                startedAt: monday.addingTimeInterval(2 * 24 * 60 * 60 + 8 * 60 * 60),
                endedAt: monday.addingTimeInterval(2 * 24 * 60 * 60 + 11 * 60 * 60),
                alertCount: 1
            ),
            FocusSession(
                startedAt: monday.addingTimeInterval(-4 * 24 * 60 * 60 + 7 * 60 * 60),
                endedAt: monday.addingTimeInterval(-4 * 24 * 60 * 60 + 8 * 60 * 60),
                alertCount: 3
            )
        ]

        let snapshot = StatisticsSnapshot.derive(for: sessions, on: referenceDate, calendar: calendar)

        #expect(snapshot.today.dayStart == calendar.startOfDay(for: referenceDate))
        #expect(snapshot.thisWeek.days.count == 7)
        #expect(snapshot.last7Days.days.count == 7)
        #expect(snapshot.thisWeek.totalFocusDuration == 21_600)
        #expect(snapshot.thisWeek.alertCount == 4)
        #expect(snapshot.last7Days.totalFocusDuration == 25_200)
        #expect(snapshot.last7Days.alertCount == 7)
    }

    @Test
    func appUsageSnapshotAggregatesDurationsTransitionsAndFallbackLabels() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let dayStart = Date(timeIntervalSince1970: 1_775_088_000)
        let referenceDate = dayStart.addingTimeInterval(18 * 60 * 60)
        let session = FocusSession(
            startedAt: dayStart.addingTimeInterval(9 * 60 * 60),
            endedAt: dayStart.addingTimeInterval(14 * 60 * 60)
        )
        session.appUsageSegments = [
            AppUsageSegment(
                bundleIdentifier: "com.apple.dt.Xcode",
                localizedName: "Xcode",
                processIdentifier: 11,
                startedAt: dayStart.addingTimeInterval(9 * 60 * 60),
                endedAt: dayStart.addingTimeInterval(10 * 60 * 60),
                focusSession: session
            ),
            AppUsageSegment(
                bundleIdentifier: "com.apple.dt.Xcode",
                localizedName: "Xcode",
                processIdentifier: 12,
                startedAt: dayStart.addingTimeInterval(10 * 60 * 60 + 30 * 60),
                endedAt: dayStart.addingTimeInterval(12 * 60 * 60 + 30 * 60),
                focusSession: session
            ),
            AppUsageSegment(
                bundleIdentifier: "com.apple.Safari",
                localizedName: "Safari",
                processIdentifier: 21,
                startedAt: dayStart.addingTimeInterval(12 * 60 * 60 + 30 * 60),
                endedAt: dayStart.addingTimeInterval(13 * 60 * 60 + 30 * 60),
                focusSession: session
            ),
            AppUsageSegment(
                bundleIdentifier: nil,
                localizedName: nil,
                processIdentifier: nil,
                startedAt: dayStart.addingTimeInterval(13 * 60 * 60 + 30 * 60),
                endedAt: dayStart.addingTimeInterval(13 * 60 * 60 + 45 * 60),
                focusSession: session
            )
        ]

        let snapshot = AppUsageSnapshot.derive(for: [session], on: referenceDate, calendar: calendar)

        #expect(snapshot.todayTopApps.count == 3)
        #expect(snapshot.todayTopApps[0].localizedName == "Xcode")
        #expect(snapshot.todayTopApps[0].duration == 10_800)
        #expect(snapshot.todayTopApps[0].transitionCount == 2)
        #expect(snapshot.todayTopApps[1].localizedName == "Safari")
        #expect(snapshot.todayTopApps[1].duration == 3_600)
        #expect(snapshot.todayTopApps[2].localizedName == "Unknown App")
        #expect(snapshot.todayPrimaryApp?.localizedName == "Xcode")
    }

    @MainActor
    @Test
    func appUsageTrackerDedupesRepeatedSnapshotsAndClosesSegments() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let sessionTracker = SessionTracker(modelContext: context)
        let tracker = AppUsageTracker(modelContext: context)
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)

        sessionTracker.beginSession(at: baseDate)
        tracker.resumeFocusWindow(
            at: baseDate,
            currentApp: appSnapshot(
                bundleIdentifier: "com.apple.dt.Xcode",
                localizedName: "Xcode",
                processIdentifier: 11
            )
        )
        tracker.handleFrontmostAppChange(
            appSnapshot(
                bundleIdentifier: "com.apple.dt.Xcode",
                localizedName: "Xcode",
                processIdentifier: 11
            ),
            at: baseDate.addingTimeInterval(60)
        )
        tracker.handleFrontmostAppChange(
            appSnapshot(
                bundleIdentifier: "com.apple.Safari",
                localizedName: "Safari",
                processIdentifier: 21
            ),
            at: baseDate.addingTimeInterval(120)
        )
        tracker.pauseFocusWindow(at: baseDate.addingTimeInterval(180))

        let segments = try context.fetch(
            FetchDescriptor<AppUsageSegment>(
                sortBy: [SortDescriptor(\AppUsageSegment.startedAt)]
            )
        )

        #expect(segments.count == 2)
        #expect(segments[0].bundleIdentifier == "com.apple.dt.Xcode")
        #expect(segments[0].startedAt == baseDate)
        #expect(segments[0].endedAt == baseDate.addingTimeInterval(120))
        #expect(segments[1].bundleIdentifier == "com.apple.Safari")
        #expect(segments[1].startedAt == baseDate.addingTimeInterval(120))
        #expect(segments[1].endedAt == baseDate.addingTimeInterval(180))
    }

    @MainActor
    @Test
    func idleMonitorIgnoresMenuSelfActivationForAppUsageTracking() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let frontmostAppProvider = TestFrontmostAppProvider()
        frontmostAppProvider.currentApp = appSnapshot(
            bundleIdentifier: "com.apple.dt.Xcode",
            localizedName: "Xcode",
            processIdentifier: 11
        )
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: frontmostAppProvider,
            sessionTracker: SessionTracker(modelContext: context),
            appUsageTracker: AppUsageTracker(modelContext: context),
            ownBundleIdentifier: "dev.nudgewhip.app"
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.setMenuPresentationActive(true)
        frontmostAppProvider.emit(
            bundleIdentifier: "dev.nudgewhip.app",
            localizedName: "NudgeWhip",
            processIdentifier: 99
        )
        idleMonitor.setMenuPresentationActive(false)
        frontmostAppProvider.emit(
            bundleIdentifier: "com.apple.Safari",
            localizedName: "Safari",
            processIdentifier: 21
        )
        idleMonitor.setManualPause(true, at: baseDate.addingTimeInterval(120))

        let segments = try context.fetch(
            FetchDescriptor<AppUsageSegment>(
                sortBy: [SortDescriptor(\AppUsageSegment.startedAt)]
            )
        )

        #expect(segments.count == 2)
        #expect(segments.allSatisfy { $0.bundleIdentifier != "dev.nudgewhip.app" })
        #expect(segments[0].bundleIdentifier == "com.apple.dt.Xcode")
        #expect(segments[0].endedAt != nil)
        #expect(segments[1].bundleIdentifier == "com.apple.Safari")
        #expect(segments[1].endedAt != nil)
    }

    @MainActor
    @Test
    func idleMonitorClosesOpenAppUsageSegmentWhenWhitelistMatchStarts() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let frontmostAppProvider = TestFrontmostAppProvider()
        frontmostAppProvider.currentApp = appSnapshot(
            bundleIdentifier: "com.apple.dt.Xcode",
            localizedName: "Xcode",
            processIdentifier: 11
        )
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: frontmostAppProvider,
            sessionTracker: SessionTracker(modelContext: context),
            appUsageTracker: AppUsageTracker(modelContext: context)
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.applyWhitelistApps(
            [WhitelistApp(bundleIdentifier: "com.apple.Safari")],
            at: baseDate.addingTimeInterval(10)
        )
        frontmostAppProvider.emit(
            bundleIdentifier: "com.apple.Safari",
            localizedName: "Safari",
            processIdentifier: 21
        )

        let segments = try context.fetch(
            FetchDescriptor<AppUsageSegment>(
                sortBy: [SortDescriptor(\AppUsageSegment.startedAt)]
            )
        )

        #expect(segments.count == 1)
        #expect(segments[0].bundleIdentifier == "com.apple.dt.Xcode")
        #expect(segments[0].endedAt != nil)
    }
    
    @MainActor
    @Test
    func bootstrapCreatesSingleDefaultSettingsAndPetState() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)
        
        let settings = try context.fetch(FetchDescriptor<UserSettings>())
        let petStates = try context.fetch(FetchDescriptor<PetState>())
        
        #expect(settings.count == 1)
        #expect(settings.first?.petPresentationMode == .sprout)
        #expect(settings.first?.countdownOverlayEnabled == true)
        #expect(settings.first?.countdownOverlayPosition == .topLeft)
        #expect(settings.first?.soundTheme == .whip)
        #expect(settings.first?.preferredLocaleIdentifier == nil)
        #expect(settings.first?.languageDefaultMigrationCompleted == true)
        #expect(petStates.count == 1)
        #expect(petStates.first?.hatchStage == .hatched)
        #expect(petStates.first?.characterType == .devil)
        #expect(petStates.first?.emotion == .sleep)
    }

    @MainActor
    @Test
    func bootstrapMigratesLegacyEnglishDefaultLanguageToSystemFollowing() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext

        let legacySettings = UserSettings(
            preferredLocaleIdentifier: AppLanguage.english.rawValue,
            languageDefaultMigrationCompleted: false
        )
        context.insert(legacySettings)
        try context.save()

        try NudgeWhipDataBootstrap.ensureDefaults(in: context)

        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(settings.preferredLocaleIdentifier == nil)
        #expect(settings.languageDefaultMigrationCompleted)
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
    func runtimeStateControllerCapsTransitionLogGrowth() {
        let controller = RuntimeStateController()

        for index in 0..<1_200 {
            controller.handle(.userActivityDetected, at: Date(timeIntervalSince1970: TimeInterval(index)))
        }

        #expect(controller.transitionLog.count == 700)
        #expect(controller.transitionLog.first?.occurredAt == Date(timeIntervalSince1970: 500))
        #expect(controller.transitionLog.last?.occurredAt == Date(timeIntervalSince1970: 1_199))
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
    func idleMonitorShowsBreakSuggestionAfterRepeatedAlertRecoveries() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300,
            alertEscalationInterval: 30,
            cooldownDuration: 60,
            breakSuggestionTriggerCount: 3
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)

        var cycleBase = baseDate
        for _ in 0..<3 {
            idleMonitor.fireIdleDeadline(at: cycleBase.addingTimeInterval(300))
            idleMonitor.recordInput(at: cycleBase.addingTimeInterval(301))
            cycleBase = cycleBase.addingTimeInterval(301)
        }

        #expect(idleMonitor.alertRecoveryCountInCurrentSession == 3)
        #expect(idleMonitor.shouldSuggestBreak)
    }

    @MainActor
    @Test
    func idleMonitorRespectsDisabledBreakSuggestionSetting() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300,
            breakSuggestionTriggerCount: 2
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.applySettings(
            UserSettings(
                breakSuggestionEnabled: false
            ),
            at: baseDate
        )
        idleMonitor.recordInput(at: baseDate)

        var cycleBase = baseDate
        for _ in 0..<2 {
            idleMonitor.fireIdleDeadline(at: cycleBase.addingTimeInterval(300))
            idleMonitor.recordInput(at: cycleBase.addingTimeInterval(301))
            cycleBase = cycleBase.addingTimeInterval(301)
        }

        #expect(idleMonitor.alertRecoveryCountInCurrentSession == 2)
        #expect(!idleMonitor.shouldSuggestBreak)
    }

    @MainActor
    @Test
    func idleMonitorClearsBreakSuggestionWhenMonitoringSessionResets() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300,
            breakSuggestionTriggerCount: 2
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)

        var cycleBase = baseDate
        for _ in 0..<2 {
            idleMonitor.fireIdleDeadline(at: cycleBase.addingTimeInterval(300))
            idleMonitor.recordInput(at: cycleBase.addingTimeInterval(301))
            cycleBase = cycleBase.addingTimeInterval(301)
        }

        #expect(idleMonitor.shouldSuggestBreak)

        idleMonitor.setManualPause(true, at: cycleBase.addingTimeInterval(1))

        #expect(!idleMonitor.shouldSuggestBreak)
        #expect(idleMonitor.alertRecoveryCountInCurrentSession == 0)
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
    func idleMonitorDefersHeavyProcessingForObservedEventMonitorActivity() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300
        )

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        let originalDeadline = idleMonitor.idleDeadlineAt

        idleMonitor.handleObservedActivityFromEventMonitor(at: baseDate.addingTimeInterval(10), isAppActive: false)

        #expect(idleMonitor.lastInputAt == baseDate.addingTimeInterval(10))
        #expect(idleMonitor.idleDeadlineAt == originalDeadline)

        idleMonitor.flushPendingObservedActivityForTesting()

        #expect(idleMonitor.idleDeadlineAt == baseDate.addingTimeInterval(310))
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

    @Test
    func systemEventMonitorSuppressesRecentGlobalDuplicatesFromMenuTracking() {
        let now = 100.0
        let lastLocalEventAt = now - 0.05

        #expect(
            SystemEventMonitor.shouldSuppressGlobalMenuTrackingDuplicate(
                eventType: .mouseMoved,
                now: now,
                lastMenuTrackingLocalEventAt: lastLocalEventAt
            )
        )
        #expect(
            !SystemEventMonitor.shouldSuppressGlobalMenuTrackingDuplicate(
                eventType: .mouseMoved,
                now: now,
                lastMenuTrackingLocalEventAt: now - 1.0
            )
        )
        #expect(
            !SystemEventMonitor.shouldSuppressGlobalMenuTrackingDuplicate(
                eventType: .flagsChanged,
                now: now,
                lastMenuTrackingLocalEventAt: lastLocalEventAt
            )
        )
    }

    @Test
    func systemEventMonitorSkipsGlobalEventsWhenAppWindowIsActive() {
        #expect(
            !SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .keyDown,
                isAppActive: true,
                hasActiveWindow: true,
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
        #expect(
            SystemEventMonitor.shouldTreatEventAsActivity(
                eventType: .keyDown,
                isAppActive: false,
                hasActiveWindow: false,
                isLocalEvent: false
            )
        )
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
    func menuBarViewModelReflectsObservedRecoveryActivityAfterDeferredProcessing() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let eventMonitor = TestEventMonitor()
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: eventMonitor,
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)

        viewModel.startIfNeeded(at: baseDate)
        idleMonitor.recordInput(at: baseDate)
        idleMonitor.fireIdleDeadline(at: baseDate.addingTimeInterval(300))

        #expect(viewModel.systemImageName == "exclamationmark.circle")

        eventMonitor.emitActivity()
        idleMonitor.flushPendingObservedActivityForTesting()

        #expect(viewModel.systemImageName == "eye.circle")
    }

    @MainActor
    @Test
    func menuBarViewModelReflectsBreakSuggestionState() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 300,
            breakSuggestionTriggerCount: 2
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor)

        viewModel.startIfNeeded(at: baseDate)
        idleMonitor.recordInput(at: baseDate)

        var cycleBase = baseDate
        for _ in 0..<2 {
            idleMonitor.fireIdleDeadline(at: cycleBase.addingTimeInterval(300))
            idleMonitor.recordInput(at: cycleBase.addingTimeInterval(301))
            cycleBase = cycleBase.addingTimeInterval(301)
        }

        #expect(viewModel.shouldShowBreakSuggestion)
        #expect(!viewModel.breakSuggestionTitleText.isEmpty)
        #expect(!viewModel.breakSuggestionBodyText.isEmpty)
    }

    @MainActor
    @Test
    func menuBarViewModelBreakSuggestionActionsTuneSettingsWithoutStartingBreakMode() throws {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        let settings = UserSettings(
            idleThresholdSeconds: 180,
            alertsPerHourLimit: 6,
            notificationNudgePerHourLimit: 2
        )
        context.insert(settings)
        try context.save()

        let idleMonitor = IdleMonitor(
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            runtimeStateController: RuntimeStateController(),
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: TestFrontmostAppProvider(),
            idleThreshold: 180,
            breakSuggestionTriggerCount: 2
        )
        let viewModel = MenuBarViewModel(idleMonitor: idleMonitor, modelContext: context)

        func triggerBreakSuggestion(startingAt date: Date, idleThreshold: TimeInterval) {
            idleMonitor.recordInput(at: date)
            var cycleBase = date
            for _ in 0..<2 {
                idleMonitor.fireIdleDeadline(at: cycleBase.addingTimeInterval(idleThreshold))
                idleMonitor.recordInput(at: cycleBase.addingTimeInterval(idleThreshold + 1))
                cycleBase = cycleBase.addingTimeInterval(idleThreshold + 1)
            }
        }

        viewModel.startIfNeeded(at: baseDate)
        triggerBreakSuggestion(startingAt: baseDate, idleThreshold: 180)
        #expect(viewModel.shouldShowBreakSuggestion)

        viewModel.relaxBreakSuggestionSensitivity(at: baseDate.addingTimeInterval(1_000))

        let afterSensitivity = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(afterSensitivity.idleThresholdSeconds == 240)
        #expect(!viewModel.shouldShowBreakSuggestion)
        #expect(!viewModel.isManualPauseActive)
        #expect(viewModel.runtimeState == .monitoring)

        triggerBreakSuggestion(startingAt: baseDate.addingTimeInterval(2_000), idleThreshold: 240)
        #expect(viewModel.shouldShowBreakSuggestion)

        viewModel.softenBreakSuggestionAlerts(at: baseDate.addingTimeInterval(3_000))

        let afterAlertSoftening = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(afterAlertSoftening.alertsPerHourLimit == 5)
        #expect(afterAlertSoftening.notificationNudgePerHourLimit == 1)
        #expect(!viewModel.shouldShowBreakSuggestion)
        #expect(!viewModel.isManualPauseActive)
        #expect(viewModel.runtimeState == .monitoring)
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
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)
        
        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        settings.idleThresholdSeconds = 600
        settings.scheduleEnabled = true
        settings.scheduleStartSecondsFromMidnight = 32_400
        settings.scheduleEndSecondsFromMidnight = 61_200
        settings.countdownOverlayPosition = .bottomRight
        settings.petPresentationMode = .minimal
        
        let petState = try #require(try context.fetch(FetchDescriptor<PetState>()).first)
        petState.hatchStage = .hatched
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
        #expect(viewModel.countdownOverlayPosition == .bottomRight)
        #expect(viewModel.whitelistCount == 1)
        #expect(viewModel.todayStats.alertCount == 2)
        #expect(viewModel.petPresentationMode == .minimal)
        #expect(viewModel.petHatchStage == .hatched)
        #expect(viewModel.petCharacter == .devil)
        #expect(viewModel.petEmotion == .happy)
    }

    @MainActor
    @Test
    func menuBarViewModelRefreshSnapshotAppliesPersistedIdleThresholdBeforeMonitoringStarts() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)

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
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)
        
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
        let appUpdater = TestAppUpdater()
        let viewModel = SettingsViewModel(
            modelContext: context,
            menuBarViewModel: menuBarViewModel,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: launchAtLoginManager,
            appUpdater: appUpdater,
            onOpenOnboarding: opener.open
        )
        
        viewModel.updateIdleThreshold(600)
        viewModel.updateCountdownOverlayEnabled(false)
        viewModel.updateCountdownOverlayPosition(.bottomRight)
        viewModel.updateScheduleEnabled(true)
        viewModel.updateLaunchAtLogin(true)
        viewModel.openOnboarding()

        let settings = try #require(try context.fetch(FetchDescriptor<UserSettings>()).first)
        #expect(settings.idleThresholdSeconds == 600)
        #expect(settings.countdownOverlayEnabled == false)
        #expect(settings.countdownOverlayPosition == .bottomRight)
        #expect(settings.scheduleEnabled)
        #expect(launchAtLoginManager.isEnabled)
        #expect(opener.callCount == 1)
        #expect(viewModel.idleThresholdSecondsValue == 600)
        #expect(viewModel.countdownOverlayEnabledValue == false)
        #expect(viewModel.countdownOverlayPositionValue == .bottomRight)
        #expect(menuBarViewModel.countdownOverlayPosition == .bottomRight)

        viewModel.updatePetPresentationMode(.minimal)

        #expect(settings.petPresentationMode == .minimal)
        #expect(viewModel.petPresentationModeValue == .minimal)
        #expect(menuBarViewModel.petPresentationMode == .minimal)
    }

    @MainActor
    @Test
    func settingsViewModelOpensGitHubProfileAndRepositoryLinks() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)

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
        let externalURLOpener = TestExternalURLOpener()
        let appUpdater = TestAppUpdater()
        let viewModel = SettingsViewModel(
            modelContext: context,
            menuBarViewModel: menuBarViewModel,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: TestLaunchAtLoginManager(),
            appUpdater: appUpdater,
            onOpenOnboarding: opener.open,
            openExternalURL: externalURLOpener.open
        )

        #expect(viewModel.openGitHubProfile())
        #expect(viewModel.openGitHubRepository())
        #expect(externalURLOpener.openedURLs == [
            URL(string: "https://github.com/Lbin91")!,
            URL(string: "https://github.com/Lbin91/nudgewhip")!
        ])
    }

    @MainActor
    @Test
    func settingsViewModelTriggersSparkleUpdateCheckWhenConfigured() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)

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
        let appUpdater = TestAppUpdater(canCheckForUpdates: true, isConfigured: true)
        let viewModel = SettingsViewModel(
            modelContext: context,
            menuBarViewModel: menuBarViewModel,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: TestLaunchAtLoginManager(),
            appUpdater: appUpdater,
            onOpenOnboarding: {}
        )

        viewModel.checkForUpdates()

        #expect(appUpdater.checkForUpdatesCallCount == 1)
        #expect(viewModel.canCheckForUpdates)
        #expect(viewModel.errorMessage == nil)
    }

    @MainActor
    @Test
    func settingsViewModelReportsWhenSparkleIsNotConfigured() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)

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
        let appUpdater = TestAppUpdater(canCheckForUpdates: false, isConfigured: false)
        let viewModel = SettingsViewModel(
            modelContext: context,
            menuBarViewModel: menuBarViewModel,
            permissionManager: PermissionManager(accessibilityPermissionState: .granted),
            launchAtLoginManager: TestLaunchAtLoginManager(),
            appUpdater: appUpdater,
            onOpenOnboarding: {}
        )

        viewModel.checkForUpdates()

        #expect(appUpdater.checkForUpdatesCallCount == 0)
        #expect(viewModel.errorMessage?.contains("Sparkle") == true)
    }
    
    @MainActor
    @Test
    func menuBarViewModelRejectsSameStartAndEndScheduleTimes() throws {
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
        let context = container.mainContext
        try NudgeWhipDataBootstrap.ensureDefaults(in: context)
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
            idleThresholdSeconds: 300,
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
    func alertManagerDeliversThirdStageNotificationOnlyOncePerAlertCycle() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )

        let stepFourSnapshot = RuntimeSnapshot(
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
        let stepFiveSnapshot = RuntimeSnapshot(
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

        alertManager.handle(snapshot: stepFourSnapshot)
        alertManager.handle(snapshot: stepFiveSnapshot)

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
                alertEscalationStep: 0,
                lastInputAt: nil
            )
        )
        alertManager.handle(snapshot: stepFourSnapshot)

        #expect(notificationManager.deliverCount == 2)
    }

    @MainActor
    @Test
    func alertManagerRotatesStrongWarningCopyAcrossAlertCycles() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )

        let strongSnapshot = RuntimeSnapshot(
            runtimeState: .alerting,
            contentState: .strongNudge,
            accessibilityGranted: true,
            manualPauseEnabled: false,
            whitelistMatched: false,
            schedulePaused: false,
            suspended: false,
            alertEscalationStep: 3,
            lastInputAt: nil
        )
        let recoverySnapshot = RuntimeSnapshot(
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

        for _ in 0..<4 {
            alertManager.handle(snapshot: strongSnapshot)
            alertManager.handle(snapshot: recoverySnapshot)
        }

        let shownMessages = presenter.shownMessages.compactMap { $0 }
        #expect(shownMessages.count == 4)
        #expect(Set(shownMessages).count == 3)
        #expect(zip(shownMessages, shownMessages.dropFirst()).allSatisfy { pair in
            pair.0 != pair.1
        })
    }

    @MainActor
    @Test
    func alertManagerClearsPendingNotificationsWhenRecoveringFromThirdStageAlert() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )

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

        #expect(notificationManager.deliverCount == 1)
        #expect(notificationManager.clearCount == 1)
    }

    @MainActor
    @Test
    func alertManagerRotatesThirdStageNotificationCopyAcrossAlertCycles() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )
        alertManager.apply(
            settings: UserSettings(
                alertsPerHourLimit: 8,
                notificationNudgePerHourLimit: 4
            )
        )

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
        let recoverySnapshot = RuntimeSnapshot(
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

        for _ in 0..<4 {
            alertManager.handle(snapshot: notificationSnapshot)
            alertManager.handle(snapshot: recoverySnapshot)
        }

        #expect(notificationManager.deliverCount == 4)
        #expect(Set(notificationManager.deliveredBodies).count == 3)
        #expect(zip(notificationManager.deliveredBodies, notificationManager.deliveredBodies.dropFirst()).allSatisfy { pair in
            pair.0 != pair.1
        })
    }

    @MainActor
    @Test
    func alertManagerKeepsRemoteEscalationStateInactiveInFreeRuntime() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager
        )

        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .remoteEscalation,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 10,
                lastInputAt: nil
            )
        )

        #expect(presenter.showCount == 0)
        #expect(notificationManager.deliverCount == 0)
        #expect(notificationManager.clearCount == 0)
    }

    @MainActor
    @Test
    func alertManagerUsesStableWhipRepeatPlanByVisualStage() {
        let presenter = TestAlertPresenter()
        let notificationManager = TestNotificationNudgeManager()
        let soundPlayer = TestAlertSoundPlayer()
        let alertManager = AlertManager(
            presenter: presenter,
            notificationNudgeManager: notificationManager,
            soundPlayer: soundPlayer
        )
        alertManager.apply(settings: UserSettings(soundTheme: .whip))

        alertManager.handle(
            snapshot: RuntimeSnapshot(
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
        )
        alertManager.handle(
            snapshot: RuntimeSnapshot(
                runtimeState: .alerting,
                contentState: .gentleNudge,
                accessibilityGranted: true,
                manualPauseEnabled: false,
                whitelistMatched: false,
                schedulePaused: false,
                suspended: false,
                alertEscalationStep: 2,
                lastInputAt: nil
            )
        )
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

        #expect(soundPlayer.playCalls == [
            .init(soundName: "cowboy_step1", repeatCount: 1, interval: 2.0),
            .init(soundName: "cowboy_step1", repeatCount: 2, interval: 2.0),
            .init(soundName: "cowboy_step1", repeatCount: 3, interval: 2.0)
        ])
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
        
        presenter.show(style: .perimeterPulse, message: nil)
        #expect(createdPanels.count == 2)
        #expect(createdPanels.allSatisfy { $0.orderFrontCount == 1 })
        
        presenter.show(style: .strongVisualNudge, message: "Test message")
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
    func idleMonitorDoesNotStartSessionFromUnchangedUnmatchedWhitelistState() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .denied)
        let runtimeController = RuntimeStateController()
        let sessionTracker = TestSessionTracker()
        let frontmostAppProvider = TestFrontmostAppProvider()
        frontmostAppProvider.currentApp = appSnapshot(
            bundleIdentifier: "com.apple.finder",
            localizedName: "Finder"
        )
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: TestEventMonitor(),
            lifecycleMonitor: TestSystemLifecycleMonitor(),
            frontmostAppProvider: frontmostAppProvider,
            sessionTracker: sessionTracker
        )

        idleMonitor.applyWhitelistApps([], at: baseDate)
        #expect(sessionTracker.beginSessionCount == 0)
        #expect(runtimeController.snapshot.runtimeState == .limitedNoAX)

        idleMonitor.setAccessibilityPermission(.granted, at: baseDate.addingTimeInterval(1))
        #expect(sessionTracker.beginSessionCount == 1)

        idleMonitor.applyWhitelistApps([], at: baseDate.addingTimeInterval(2))
        #expect(sessionTracker.beginSessionCount == 1)
        #expect(runtimeController.snapshot.runtimeState == .monitoring)
    }
    
    @MainActor
    @Test
    func onboardingStorageTracksCompletionResumeAndDraft() {
        let defaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.storage.\(UUID().uuidString)")!
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
        let defaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.viewmodel.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
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
        viewModel.petPresentationMode = .minimal
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
        #expect(settings.first?.petPresentationMode == .minimal)
        #expect(settings.first?.scheduleEnabled == true)
        #expect(settings.first?.scheduleStartSecondsFromMidnight == 32_400)
        #expect(settings.first?.scheduleEndSecondsFromMidnight == 61_200)
        #expect(!storage.shouldPresentOnboarding)
    }
    
    @MainActor
    @Test
    func onboardingViewModelPreservesDraftOnBasicSetupWindowClose() throws {
        let defaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.close.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let container = try NudgeWhipModelContainer.makeModelContainer(inMemory: true)
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
        #expect(storage.savedDraft?.preferredLanguage == AppLanguage.resolve(nil))
        #expect(storage.shouldPresentOnboarding)
    }
    
    @MainActor
    @Test
    func onboardingViewModelCanRestartManualReentryFromWelcome() {
        let defaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.restart.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: NudgeWhipModelContainer.preview,
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

    @MainActor
    @Test
    func onboardingViewModelPromotesLimitedCompletionAfterPermissionRecovery() {
        let defaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.permission-recovery.\(UUID().uuidString)")!
        let storage = OnboardingStorage(defaults: defaults)
        var isGranted = false
        let permissionManager = PermissionManager(
            accessibilityPermissionState: .denied,
            trustCheck: { _ in isGranted },
            settingsOpener: { _ in true }
        )
        let viewModel = OnboardingViewModel(
            storage: storage,
            modelContainer: NudgeWhipModelContainer.preview,
            permissionManager: permissionManager,
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}

        viewModel.continueFromWelcome()
        viewModel.setUpLater()
        #expect(viewModel.step == .completionLimited)

        isGranted = true
        viewModel.handleDidBecomeActive()

        #expect(viewModel.permissionState == .granted)
        #expect(viewModel.step == .completionReady)
        #expect(storage.resumeStep == .completionReady)
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
        let welcomeDefaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.heights.welcome.\(UUID().uuidString)")!
        let welcomeStorage = OnboardingStorage(defaults: welcomeDefaults)
        let welcomeViewModel = OnboardingViewModel(
            storage: welcomeStorage,
            modelContainer: NudgeWhipModelContainer.preview,
            permissionManager: PermissionManager(accessibilityPermissionState: .unknown),
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}

        #expect(welcomeViewModel.preferredContentHeight == 520)

        let deniedDefaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.heights.denied.\(UUID().uuidString)")!
        let deniedStorage = OnboardingStorage(defaults: deniedDefaults)
        deniedStorage.saveResumeStep(.permission)
        let deniedViewModel = OnboardingViewModel(
            storage: deniedStorage,
            modelContainer: NudgeWhipModelContainer.preview,
            permissionManager: PermissionManager(accessibilityPermissionState: .denied),
            launchAtLoginManager: TestLaunchAtLoginManager()
        ) {}
        
        #expect(deniedViewModel.preferredContentHeight == 640)
        
        let grantedDefaults = UserDefaults(suiteName: "nudgewhipTests.onboarding.heights.granted.\(UUID().uuidString)")!
        let grantedStorage = OnboardingStorage(defaults: grantedDefaults)
        grantedStorage.saveResumeStep(.permission)
        let grantedViewModel = OnboardingViewModel(
            storage: grantedStorage,
            modelContainer: NudgeWhipModelContainer.preview,
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
