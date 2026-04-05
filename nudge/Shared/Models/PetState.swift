// PetState.swift
// 가상 펫의 상태를 저장하는 SwiftData 모델.
//
// 성장 단계(sprout/buddy/guide), 감정, 경험치, 레벨, 일일 스트릭을 관리한다.
// 마지막 포커스 세션 종료 시각도 추적해 스트릭 계산에 사용한다.

import Foundation
import SwiftData

enum PetGrowthStage: String, Codable, CaseIterable, Sendable {
    case sprout
    case buddy
    case guide
}

enum PetEmotion: String, Codable, CaseIterable, Sendable {
    case happy
    case cheer
    case sleep
    case concern
}

@Model
final class PetState {
    var species: String
    var stageRawValue: String
    var emotionRawValue: String
    var experiencePoints: Int
    var level: Int
    var dailyStreak: Int
    var lastFocusSessionEndedAt: Date?
    var updatedAt: Date
    
    /// 성장 단계 로우 밸류 ↔ enum 편의 변환
    var stage: PetGrowthStage {
        get { PetGrowthStage(rawValue: stageRawValue) ?? .sprout }
        set { stageRawValue = newValue.rawValue }
    }
    
    /// 감정 상태 로우 밸류 ↔ enum 편의 변환
    var emotion: PetEmotion {
        get { PetEmotion(rawValue: emotionRawValue) ?? .sleep }
        set { emotionRawValue = newValue.rawValue }
    }
    
    /// 펫 상태 생성. 새싹 단계, 수면 감정으로 시작
    init(
        species: String = "default",
        stage: PetGrowthStage = .sprout,
        emotion: PetEmotion = .sleep,
        experiencePoints: Int = 0,
        level: Int = 1,
        dailyStreak: Int = 0,
        lastFocusSessionEndedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.species = species
        self.stageRawValue = stage.rawValue
        self.emotionRawValue = emotion.rawValue
        self.experiencePoints = experiencePoints
        self.level = level
        self.dailyStreak = dailyStreak
        self.lastFocusSessionEndedAt = lastFocusSessionEndedAt
        self.updatedAt = updatedAt
    }
}
