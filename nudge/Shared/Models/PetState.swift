import Foundation

import SwiftData

import SwiftUI

enum PetHatchStage: String, Codable, CaseIterable, Sendable {
    case egg
    case cracking
    case hatched
}

enum PetCharacterType: String, Codable, CaseIterable, Sendable {
    case partyMask
    case rat
    case ox
    case tiger
    case rabbit
}
enum PetEmotion: String, Codable, CaseIterable, Sendable {
    case happy
    case cheer
    case sleep
    case concern
}
@Model
final class PetState {
    var hatchStageRawValue: String
    var characterTypeRawValue: String
    var emotionRawValue: String
    var experiencePoints: Int
    var level: Int
    var dailyStreak: Int
    var lastFocusSessionEndedAt: Date?
    var updatedAt: Date
    var hatchStage: PetHatchStage {
        get { PetHatchStage(rawValue: hatchStageRawValue) ?? .egg }
        set { hatchStageRawValue = newValue.rawValue }
    }
    var characterType: PetCharacterType {
        get { PetCharacterType(rawValue: characterTypeRawValue) ?? .partyMask }
        set { characterTypeRawValue = newValue.rawValue }
    }
    var emotion: PetEmotion {
        get { PetEmotion(rawValue: emotionRawValue) ?? .sleep }
        set { emotionRawValue = newValue.rawValue }
    }
    init(
        hatchStage: PetHatchStage = .egg,
        characterType: PetCharacterType = .partyMask,
        emotion: PetEmotion = .sleep,
        experiencePoints: Int = 0,
        level: Int = 1,
        dailyStreak: Int = 0,
        lastFocusSessionEndedAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.hatchStageRawValue = hatchStage.rawValue
        self.characterTypeRawValue = characterType.rawValue
        self.emotionRawValue = emotion.rawValue
        self.experiencePoints = experiencePoints
        self.level = level
        self.dailyStreak = dailyStreak
        self.updatedAt = updatedAt
    }
}
