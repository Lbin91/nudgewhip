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
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Nudge")
                    .font(.headline)
                Text("SwiftData-backed menu bar bootstrap")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            GroupBox("Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Idle threshold", value: idleThresholdText)
                    LabeledContent("TTS", value: ttsStatusText)
                    LabeledContent("Pet mode", value: petPresentationText)
                }
            }
            
            GroupBox("Today") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Focus time", value: formattedDuration(todayStats.totalFocusDuration))
                    LabeledContent("Completed sessions", value: "\(todayStats.completedSessionCount)")
                    LabeledContent("Alerts", value: "\(todayStats.alertCount)")
                }
            }
            
            GroupBox("Workspace") {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent("Whitelist apps", value: "\(whitelistApps.count)")
                    LabeledContent("Pet stage", value: petState?.stage.rawValue.capitalized ?? "None")
                    LabeledContent("Pet emotion", value: petState?.emotion.rawValue.capitalized ?? "None")
                }
            }
        }
        .padding(16)
        .frame(width: 320)
        .task {
            try? NudgeDataBootstrap.ensureDefaults(in: modelContext)
        }
    }
    
    private var idleThresholdText: String {
        guard let settings else { return "Unavailable" }
        return formattedDuration(TimeInterval(settings.idleThresholdSeconds))
    }
    
    private var ttsStatusText: String {
        settings?.ttsEnabled == true ? "Enabled" : "Disabled"
    }
    
    private var petPresentationText: String {
        settings?.petPresentationMode.rawValue.capitalized ?? "Unavailable"
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes == 0 {
            return "\(seconds)s"
        }
        
        if seconds == 0 {
            return "\(minutes)m"
        }
        
        return "\(minutes)m \(seconds)s"
    }
}

#Preview {
    ContentView()
        .modelContainer(NudgeModelContainer.preview)
}
