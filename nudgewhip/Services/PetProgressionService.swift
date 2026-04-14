// PetProgressionService.swift
// 펫 성장 시스템의 XP 보상, 연속 활성 스트릭, 단계 전환을 관리하는 서비스.

import Foundation
import SwiftData

@MainActor
final class PetProgressionService {
    private let modelContext: ModelContext

    var onStageUp: ((PetGrowthStage) -> Void)?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? NudgeWhipModelContainer.shared.mainContext
    }

    func fetchPetState() -> PetState {
        let descriptor = FetchDescriptor<PetState>(sortBy: [SortDescriptor(\.createdAt)])
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let newPet = PetState()
        modelContext.insert(newPet)
        try? modelContext.save()
        return newPet
    }

    @discardableResult
    func awardRecoveryXP() -> Int {
        let petState = fetchPetState()
        petState.experiencePoints += PetProgressionConstants.xpPerRecovery
        petState.totalRecoveryContributions += 1
        petState.updatedAt = .now
        checkStageTransition(petState: petState)
        try? modelContext.save()
        return petState.experiencePoints
    }

    @discardableResult
    func awardSessionXP(duration: TimeInterval) -> Int {
        guard duration >= PetProgressionConstants.sessionDurationThresholdSeconds else { return 0 }
        let petState = fetchPetState()
        petState.experiencePoints += PetProgressionConstants.xpPerSession30Min
        petState.updatedAt = .now
        checkStageTransition(petState: petState)
        try? modelContext.save()
        return petState.experiencePoints
    }

    @discardableResult
    func checkDailyActiveBonus() -> Int {
        let petState = fetchPetState()
        let today = Calendar.current.startOfDay(for: .now)

        guard petState.lastActiveDate != Calendar.current.startOfDay(for: petState.lastActiveDate ?? .distantPast) || petState.lastActiveDate == nil else {
            return 0
        }

        let lastActiveDay = petState.lastActiveDate.map { Calendar.current.startOfDay(for: $0) }

        if let lastActiveDay {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            if daysBetween == 1 {
                petState.consecutiveDaysActive += 1
            } else if daysBetween > 1 {
                petState.consecutiveDaysActive = 1
            }
        } else {
            petState.consecutiveDaysActive = 1
        }

        let streakBonus = min(petState.consecutiveDaysActive, PetProgressionConstants.maxStreakBonus)
        let bonusXP = PetProgressionConstants.xpPerDailyActive + streakBonus
        petState.experiencePoints += bonusXP
        petState.lastActiveDate = today
        petState.companionDayCount += 1
        petState.updatedAt = .now
        checkStageTransition(petState: petState)
        try? modelContext.save()
        return bonusXP
    }

    func updateStreak() {
        let petState = fetchPetState()
        let today = Calendar.current.startOfDay(for: .now)
        let lastActiveDay = petState.lastActiveDate.map { Calendar.current.startOfDay(for: $0) }

        if let lastActiveDay {
            let daysBetween = Calendar.current.dateComponents([.day], from: lastActiveDay, to: today).day ?? 0
            if daysBetween > 1 {
                petState.consecutiveDaysActive = 1
            }
        }
        petState.updatedAt = .now
        try? modelContext.save()
    }

    private func checkStageTransition(petState: PetState) {
        let newStage = PetGrowthStage.stage(for: petState.experiencePoints)
        guard newStage != petState.currentStage else { return }
        petState.currentStage = newStage
        petState.updatedAt = .now
        onStageUp?(newStage)
    }

    func resetPet() {
        let petState = fetchPetState()
        petState.currentStage = .egg
        petState.experiencePoints = 0
        petState.totalRecoveryContributions = 0
        petState.consecutiveDaysActive = 0
        petState.lastActiveDate = nil
        petState.companionDayCount = 0
        petState.companionStartDate = .now
        petState.updatedAt = .now
        try? modelContext.save()
    }
}
