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
    var stageRawValue: String
    var emotionRawValue: String
    var experiencePoints: Int
    var level: Int
    var dailyStreak: Int
    var lastFocusSessionEndedAt: Date?
    var updatedAt: Date
    
    var stage: PetGrowthStage {
        get { PetGrowthStage(rawValue: stageRawValue) ?? .sprout }
        set { stageRawValue = newValue.rawValue }
    }
    
    var emotion: PetEmotion {
        get { PetEmotion(rawValue: emotionRawValue) ?? .sleep }
        set { emotionRawValue = newValue.rawValue }
    }
    
    init(
        stage: PetGrowthStage = .sprout,
        emotion: PetEmotion = .sleep,
        experiencePoints: Int = 0,
        level: Int = 1,
        dailyStreak: Int = 0,
        lastFocusSessionEndedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.stageRawValue = stage.rawValue
        self.emotionRawValue = emotion.rawValue
        self.experiencePoints = experiencePoints
        self.level = level
        self.dailyStreak = dailyStreak
        self.lastFocusSessionEndedAt = lastFocusSessionEndedAt
        self.updatedAt = updatedAt
    }
}
