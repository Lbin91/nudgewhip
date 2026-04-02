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
                Text(localized("app.menu.title", defaultValue: "Nudge"))
                    .font(.headline)
                Text(localized("menu.dropdown.subtitle.bootstrap", defaultValue: "Localized menu bar bootstrap"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    labeledValue(localized("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"), value: idleThresholdText)
                    labeledValue(localized("menu.dropdown.label.tts", defaultValue: "TTS"), value: ttsStatusText)
                    labeledValue(localized("menu.dropdown.label.pet_mode", defaultValue: "Pet mode"), value: petPresentationText)
                }
            } label: {
                Text(localized("menu.dropdown.group.settings", defaultValue: "Settings"))
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    labeledValue(localized("menu.dropdown.label.focus_time", defaultValue: "Focus time"), value: formattedDuration(todayStats.totalFocusDuration))
                    labeledValue(localized("menu.dropdown.label.completed_sessions", defaultValue: "Completed sessions"), value: "\(todayStats.completedSessionCount)")
                    labeledValue(localized("menu.dropdown.label.alerts", defaultValue: "Alerts"), value: "\(todayStats.alertCount)")
                }
            } label: {
                Text(localized("menu.dropdown.group.today", defaultValue: "Today"))
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    labeledValue(localized("menu.dropdown.label.whitelist_apps", defaultValue: "Whitelist apps"), value: "\(whitelistApps.count)")
                    labeledValue(localized("menu.dropdown.label.pet_stage", defaultValue: "Pet stage"), value: localizedPetStage)
                    labeledValue(localized("menu.dropdown.label.pet_emotion", defaultValue: "Pet emotion"), value: localizedPetEmotion)
                }
            } label: {
                Text(localized("menu.dropdown.group.workspace", defaultValue: "Workspace"))
            }
        }
        .padding(16)
        .frame(width: 320)
        .task {
            try? NudgeDataBootstrap.ensureDefaults(in: modelContext)
        }
    }
    
    private var idleThresholdText: String {
        guard let settings else { return localized("menu.dropdown.value.unavailable", defaultValue: "Unavailable") }
        return formattedDuration(TimeInterval(settings.idleThresholdSeconds))
    }
    
    private var ttsStatusText: String {
        settings?.ttsEnabled == true
            ? localized("menu.dropdown.value.enabled", defaultValue: "Enabled")
            : localized("menu.dropdown.value.disabled", defaultValue: "Disabled")
    }
    
    private var petPresentationText: String {
        guard let settings else {
            return localized("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
        }
        
        switch settings.petPresentationMode {
        case .sprout:
            return localized("menu.dropdown.value.pet_mode.sprout", defaultValue: "Sprout")
        case .minimal:
            return localized("menu.dropdown.value.pet_mode.minimal", defaultValue: "Minimal")
        }
    }
    
    private var localizedPetStage: String {
        guard let petState else {
            return localized("menu.dropdown.value.none", defaultValue: "None")
        }
        
        switch petState.stage {
        case .sprout:
            return localized("menu.dropdown.value.pet_stage.sprout", defaultValue: "Sprout")
        case .buddy:
            return localized("menu.dropdown.value.pet_stage.buddy", defaultValue: "Buddy")
        case .guide:
            return localized("menu.dropdown.value.pet_stage.guide", defaultValue: "Guide")
        }
    }
    
    private var localizedPetEmotion: String {
        guard let petState else {
            return localized("menu.dropdown.value.none", defaultValue: "None")
        }
        
        switch petState.emotion {
        case .happy:
            return localized("menu.dropdown.value.pet_emotion.happy", defaultValue: "Happy")
        case .cheer:
            return localized("menu.dropdown.value.pet_emotion.cheer", defaultValue: "Cheer")
        case .sleep:
            return localized("menu.dropdown.value.pet_emotion.sleep", defaultValue: "Sleep")
        case .concern:
            return localized("menu.dropdown.value.pet_emotion.concern", defaultValue: "Concern")
        }
    }
    
    private func localized(_ key: String, defaultValue: String) -> String {
        let localizedValue = NSLocalizedString(key, comment: "")
        return localizedValue == key ? defaultValue : localizedValue
    }
    
    @ViewBuilder
    private func labeledValue(_ label: String, value: String) -> some View {
        LabeledContent {
            Text(value)
        } label: {
            Text(label)
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: max(duration, 0))
            ?? localized("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}

#Preview {
    ContentView()
        .modelContainer(NudgeModelContainer.preview)
}
