// PetState.swift
// 가상 펫 상태를 관리하는 SwiftData 모델.
//
// 성장 단계, 경험치, 연속 활성 일수, 동반자 기간을 추적한다.

import Foundation
import SwiftData

enum PetGrowthStage: String, Codable, CaseIterable, Sendable {
    case egg
    case hatchling
    case juvenile
    case adult
    case elder

    var iconName: String {
        switch self {
        case .egg: return "egg.fill"
        case .hatchling: return "bird.fill"
        case .juvenile: return "bird.fill"
        case .adult: return "flame.fill"
        case .elder: return "star.fill"
        }
    }

    var displayName: String {
        switch self {
        case .egg:
            return localizedAppString("pet.stage.egg", defaultValue: "Egg")
        case .hatchling:
            return localizedAppString("pet.stage.hatchling", defaultValue: "Hatchling")
        case .juvenile:
            return localizedAppString("pet.stage.juvenile", defaultValue: "Juvenile")
        case .adult:
            return localizedAppString("pet.stage.adult", defaultValue: "Adult")
        case .elder:
            return localizedAppString("pet.stage.elder", defaultValue: "Elder")
        }
    }

    var xpThreshold: Int {
        PetProgressionConstants.stageThresholds.first(where: { $0.stage == self })?.xpRequired ?? 0
    }

    var nextStage: PetGrowthStage? {
        switch self {
        case .egg: return .hatchling
        case .hatchling: return .juvenile
        case .juvenile: return .adult
        case .adult: return .elder
        case .elder: return nil
        }
    }

    static func stage(for xp: Int) -> PetGrowthStage {
        let sorted = PetProgressionConstants.stageThresholds.sorted { $0.xpRequired > $1.xpRequired }
        for entry in sorted {
            if xp >= entry.xpRequired {
                return entry.stage
            }
        }
        return .egg
    }
}

@Model
final class PetState {
    var id: UUID
    var name: String
    var currentStageRawValue: String
    var experiencePoints: Int
    var totalRecoveryContributions: Int
    var consecutiveDaysActive: Int
    var lastActiveDate: Date?
    var companionDayCount: Int
    var companionStartDate: Date
    var createdAt: Date
    var updatedAt: Date

    var currentStage: PetGrowthStage {
        get { PetGrowthStage(rawValue: currentStageRawValue) ?? .egg }
        set { currentStageRawValue = newValue.rawValue }
    }

    var progressToNextStage: Double {
        guard let next = currentStage.nextStage else { return 1.0 }
        let currentThreshold = currentStage.xpThreshold
        let nextThreshold = next.xpThreshold
        let range = nextThreshold - currentThreshold
        guard range > 0 else { return 1.0 }
        return Double(experiencePoints - currentThreshold) / Double(range)
    }

    var xpToNextStage: Int? {
        guard let next = currentStage.nextStage else { return nil }
        return next.xpThreshold - experiencePoints
    }

    init(
        id: UUID = UUID(),
        name: String = "Whip",
        currentStage: PetGrowthStage = .egg,
        experiencePoints: Int = 0,
        totalRecoveryContributions: Int = 0,
        consecutiveDaysActive: Int = 0,
        lastActiveDate: Date? = nil,
        companionDayCount: Int = 0,
        companionStartDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.currentStageRawValue = currentStage.rawValue
        self.experiencePoints = experiencePoints
        self.totalRecoveryContributions = totalRecoveryContributions
        self.consecutiveDaysActive = consecutiveDaysActive
        self.lastActiveDate = lastActiveDate
        self.companionDayCount = companionDayCount
        self.companionStartDate = companionStartDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
