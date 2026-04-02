// NudgeModelContainer.swift
// SwiftData ModelContainer 팩토리.
//
// 모델 스키마(UserSettings, WhitelistApp, FocusSession, PetState)를 등록하고
// 실제 저장소(shared)와 메모리 프리뷰(preview) 컨테이너를 제공한다.

import SwiftData

enum NudgeModelContainer {
    /// 실제 디스크 저장소용 싱글톤 컨테이너
    static let shared: ModelContainer = {
        do {
            return try makeModelContainer(inMemory: false)
        } catch {
            fatalError("Failed to create Nudge model container: \(error)")
        }
    }()
    
    @MainActor
    /// SwiftUI 프리뷰용 메모리 컨테이너 (기본 데이터 포함)
    static let preview: ModelContainer = {
        do {
            let container = try makeModelContainer(inMemory: true)
            try NudgeDataBootstrap.ensureDefaults(in: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()
    
    /// 스키마 등록 후 ModelContainer 생성. inMemory=true면 디스크에 저장하지 않음
    static func makeModelContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema([
            UserSettings.self,
            WhitelistApp.self,
            FocusSession.self,
            PetState.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
