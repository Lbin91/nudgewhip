//
//  nudgeTests.swift
//  nudgeTests
//
//  Created by Bongjin Lee on 4/2/26.
//

import Foundation
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
                alertCount: 2,
                ttsCount: 1
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
        #expect(stats.ttsCount == 1)
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
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
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
    func idleMonitorStartsAndStopsRealInputMonitoringWithPermissionState() {
        let baseDate = Date(timeIntervalSince1970: 1_775_088_000)
        let permissionManager = PermissionManager(accessibilityPermissionState: .unknown)
        let runtimeController = RuntimeStateController()
        let eventMonitor = TestEventMonitor()
        let idleMonitor = IdleMonitor(
            permissionManager: permissionManager,
            runtimeStateController: runtimeController,
            eventMonitor: eventMonitor,
            idleThreshold: 300
        )
        
        idleMonitor.setAccessibilityPermission(.granted, at: baseDate)
        #expect(eventMonitor.startCount == 1)
        #expect(eventMonitor.isMonitoring)
        
        eventMonitor.emitActivity()
        #expect(idleMonitor.lastInputAt != nil)
        #expect(idleMonitor.idleDeadlineAt != nil)
        
        idleMonitor.setAccessibilityPermission(.denied, at: baseDate.addingTimeInterval(1))
        #expect(eventMonitor.stopCount == 1)
        #expect(!eventMonitor.isMonitoring)
        #expect(runtimeController.snapshot.runtimeState == .limitedNoAX)
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

}
