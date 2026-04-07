import Foundation

import SwiftData

import SwiftUI

enum PetHatchStage: String, Codable, CaseIterable, Sendable {
    case egg
    case cracking
    case hatched
}

enum PetCharacterType: String, Codable, CaseIterable, Sendable {
    case partyMask // Ringmaster
    case cowboy
    case devil
    case catwoman
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
        get { PetHatchStage(rawValue: hatchStageRawValue) ?? .hatched }
        set { hatchStageRawValue = newValue.rawValue }
    }

    var characterType: PetCharacterType {
        get { PetCharacterType(rawValue: characterTypeRawValue) ?? .partyMask }
        set { characterTypeRawValue = newValue.rawValue }
    }

    /// 다른 worktree에서 남은 species 기반 호출과의 호환 레이어
    var species: String {
        switch characterType {
        case .partyMask:
            return "ringmaster"
        case .cowboy:
            return "cowboy"
        case .devil:
            return "devil"
        case .catwoman:
            return "catwoman"
        case .rat:
            return "rat"
        case .ox:
            return "ox"
        case .tiger:
            return "tiger"
        case .rabbit:
            return "rabbit"
        }
    }

    var emotion: PetEmotion {
        get { PetEmotion(rawValue: emotionRawValue) ?? .sleep }
        set { emotionRawValue = newValue.rawValue }
    }
    init(
        hatchStage: PetHatchStage = .hatched,
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
