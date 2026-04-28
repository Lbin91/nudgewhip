//
//  nudgewhipiosApp.swift
//  nudgewhipios
//
//  Created by Bongjin Lee on 4/16/26.
//

import SwiftUI
import SwiftData

@main
struct NudgeWhipCompanionApp: App {
    @State private var syncOrchestrator = SyncOrchestrator()

    var body: some Scene {
        WindowGroup {
            CompanionTabView()
                .environment(syncOrchestrator)
        }
        .modelContainer(iOSModelContainer.shared)
    }
}
