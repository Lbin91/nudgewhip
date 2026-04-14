// PetProgressionConstants.swift
// 펫 성장 시스템의 XP 보상, 세션 기준, 성장 단계 임계값 상수.

import Foundation

enum PetProgressionConstants {
    // MARK: - XP Rewards

    static let xpPerRecovery: Int = 5
    static let xpPerSession30Min: Int = 10
    static let xpPerDailyActive: Int = 2
    static let maxStreakBonus: Int = 5  // min(consecutiveDays, 5)

    // MARK: - Session Duration Threshold

    static let sessionDurationThresholdSeconds: TimeInterval = 1800  // 30 minutes

    // MARK: - Growth Stage Thresholds

    static let stageThresholds: [(stage: PetGrowthStage, xpRequired: Int)] = [
        (.egg, 0),
        (.hatchling, 50),
        (.juvenile, 150),
        (.adult, 350),
        (.elder, 700)
    ]
}
