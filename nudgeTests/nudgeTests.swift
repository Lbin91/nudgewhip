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

}
