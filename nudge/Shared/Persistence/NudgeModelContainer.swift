import SwiftData

enum NudgeModelContainer {
    static let shared: ModelContainer = {
        do {
            return try makeModelContainer(inMemory: false)
        } catch {
            fatalError("Failed to create Nudge model container: \(error)")
        }
    }()
    
    @MainActor
    static let preview: ModelContainer = {
        do {
            let container = try makeModelContainer(inMemory: true)
            try NudgeDataBootstrap.ensureDefaults(in: container.mainContext)
            return container
        } catch {
            fatalError("Failed to create preview model container: \(error)")
        }
    }()
    
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
