import SwiftData

enum NudgeDataBootstrap {
    @MainActor
    static func ensureDefaults(in context: ModelContext) throws {
        let settings = try context.fetch(FetchDescriptor<UserSettings>())
        if settings.isEmpty {
            context.insert(UserSettings())
        }
        
        let petStates = try context.fetch(FetchDescriptor<PetState>())
        if petStates.isEmpty {
            context.insert(PetState())
        }
        
        try context.save()
    }
}
