//
//  ContentView.swift
//  nudge
//
//  Created by Bongjin Lee on 4/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsCollection: [UserSettings]
    @Query private var petStates: [PetState]
    @Query private var whitelistApps: [WhitelistApp]
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var focusSessions: [FocusSession]
    
    let menuBarViewModel: MenuBarViewModel
    
    private var settings: UserSettings? {
        settingsCollection.first
    }
    
    private var petState: PetState? {
        petStates.first
    }
    
    private var todayStats: DailyStats {
        DailyStats.derive(for: focusSessions, on: .now)
    }

    var body: some View {
        MenuBarDropdownView(
            menuBarViewModel: menuBarViewModel,
            settings: settings,
            petState: petState,
            whitelistCount: whitelistApps.count,
            todayStats: todayStats
        )
        .padding(16)
        .frame(width: 320)
        .task {
            try? NudgeDataBootstrap.ensureDefaults(in: modelContext)
            menuBarViewModel.startIfNeeded()
        }
    }
}

#Preview {
    ContentView(menuBarViewModel: MenuBarViewModel())
        .modelContainer(NudgeModelContainer.preview)
}
