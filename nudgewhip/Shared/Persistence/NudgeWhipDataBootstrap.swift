// NudgeWhipDataBootstrap.swift
// 앱 최초 실행 시 기본 데이터를 시드하는 유틸리티.
//
// UserSettings와 PetState의 기본 인스턴스를 생성해
// 빈 SwiftData 저장소에 삽입한다.

import Foundation
import SwiftData

enum NudgeWhipDataBootstrap {
    @MainActor
    /// 빈 저장소에 기본 UserSettings와 PetState 삽입
    static func ensureDefaults(in context: ModelContext) throws {
        let settings = try context.fetch(FetchDescriptor<UserSettings>())
        if settings.isEmpty {
            context.insert(UserSettings())
        } else {
            for setting in settings where !setting.languageDefaultMigrationCompleted {
                if setting.preferredLocaleIdentifier == AppLanguage.english.rawValue {
                    setting.preferredLocaleIdentifier = nil
                }
                setting.languageDefaultMigrationCompleted = true
                setting.updatedAt = .now
            }
        }
        
        let petStates = try context.fetch(FetchDescriptor<PetState>())
        if petStates.isEmpty {
            context.insert(PetState(hatchStage: .hatched, characterType: .devil))
        } else {
            for petState in petStates {
                // Ensure devil is the default for now
                petState.hatchStage = .hatched
                petState.characterType = .devil
                petState.updatedAt = .now
            }
        }
        
        try context.save()
    }
}
