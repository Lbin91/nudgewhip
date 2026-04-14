// SchedulePreset.swift
// 스케줄 프리셋을 저장하는 SwiftData 모델.
//
// 평일 집중, 야간 모드 등 빌트인 프리셋과 사용자 정의 프리셋을 관리한다.
// 활성 프리셋은 UserSettings의 scheduleStart/End와 동기화된다.

import Foundation
import SwiftData

@Model
final class SchedulePreset {
    var id: UUID
    var name: String
    var iconName: String
    var startSecondsFromMidnight: Int
    var endSecondsFromMidnight: Int
    var isWeekdayOnly: Bool
    var isBuiltIn: Bool
    var sortOrder: Int
    var isActivePreset: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "clock",
        startSecondsFromMidnight: Int,
        endSecondsFromMidnight: Int,
        isWeekdayOnly: Bool = false,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0,
        isActivePreset: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.startSecondsFromMidnight = startSecondsFromMidnight
        self.endSecondsFromMidnight = endSecondsFromMidnight
        self.isWeekdayOnly = isWeekdayOnly
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.isActivePreset = isActivePreset
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Formatted start time string (HH:mm)
    var startTimeFormatted: String {
        formatSecondsFromMidnight(startSecondsFromMidnight)
    }

    /// Formatted end time string (HH:mm)
    var endTimeFormatted: String {
        formatSecondsFromMidnight(endSecondsFromMidnight)
    }

    /// Seed built-in presets if they don't exist. Call once on first launch.
    /// When existing schedule was enabled, the matching built-in preset becomes active
    /// with start/end migrated from current UserSettings values.
    static func seedBuiltInPresets(
        modelContext: ModelContext,
        existingSchedule: (enabled: Bool, start: Int, end: Int)
    ) {
        let descriptor = FetchDescriptor<SchedulePreset>(
            predicate: #Predicate { $0.isBuiltIn }
        )
        let existingBuiltIns = (try? modelContext.fetch(descriptor)) ?? []
        guard existingBuiltIns.isEmpty else { return }

        let builtInDefinitions: [(name: String, icon: String, start: Int, end: Int, weekday: Bool)] = [
            (
                localizedAppString("preset.builtin.weekday_focus", defaultValue: "Weekday Focus"),
                "sun.max", 32400, 61200, true
            ),
            (
                localizedAppString("preset.builtin.night_mode", defaultValue: "Night Mode"),
                "moon.fill", 79200, 21600, false
            ),
            (
                localizedAppString("preset.builtin.all_day", defaultValue: "All Day"),
                "clock.fill", 0, 86340, false
            )
        ]

        for (index, definition) in builtInDefinitions.enumerated() {
            let shouldActivate = existingSchedule.enabled

            let startToUse: Int
            let endToUse: Int
            if shouldActivate {
                startToUse = existingSchedule.start
                endToUse = existingSchedule.end
            } else {
                startToUse = definition.start
                endToUse = definition.end
            }

            let preset = SchedulePreset(
                name: definition.name,
                iconName: definition.icon,
                startSecondsFromMidnight: startToUse,
                endSecondsFromMidnight: endToUse,
                isWeekdayOnly: definition.weekday,
                isBuiltIn: true,
                sortOrder: index,
                isActivePreset: shouldActivate && index == 0
            )
            modelContext.insert(preset)
        }

        try? modelContext.save()
    }

    // MARK: - Private

    private func formatSecondsFromMidnight(_ totalSeconds: Int) -> String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}
