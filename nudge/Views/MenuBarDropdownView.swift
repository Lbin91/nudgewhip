import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    let settings: UserSettings?
    let petState: PetState?
    let whitelistCount: Int
    let todayStats: DailyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)
            
            QuickControlsView(
                menuBarViewModel: menuBarViewModel,
                settings: settings,
                petPresentationText: petPresentationText,
                ttsStatusText: ttsStatusText,
                idleThresholdText: idleThresholdText
            )
            
            DailySummaryView(
                todayStats: todayStats,
                whitelistCount: whitelistCount,
                petStageText: localizedPetStage,
                petEmotionText: localizedPetEmotion
            )
        }
    }
    
    private var idleThresholdText: String {
        guard let settings else { return localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable") }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = settings.idleThresholdSeconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(settings.idleThresholdSeconds))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
    
    private var ttsStatusText: String {
        settings?.ttsEnabled == true
            ? localizedAppString("menu.dropdown.value.enabled", defaultValue: "Enabled")
            : localizedAppString("menu.dropdown.value.disabled", defaultValue: "Disabled")
    }
    
    private var petPresentationText: String {
        guard let settings else {
            return localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
        }
        
        switch settings.petPresentationMode {
        case .sprout:
            return localizedAppString("menu.dropdown.value.pet_mode.sprout", defaultValue: "Sprout")
        case .minimal:
            return localizedAppString("menu.dropdown.value.pet_mode.minimal", defaultValue: "Minimal")
        }
    }
    
    private var localizedPetStage: String {
        guard let petState else {
            return localizedAppString("menu.dropdown.value.none", defaultValue: "None")
        }
        
        switch petState.stage {
        case .sprout:
            return localizedAppString("menu.dropdown.value.pet_stage.sprout", defaultValue: "Sprout")
        case .buddy:
            return localizedAppString("menu.dropdown.value.pet_stage.buddy", defaultValue: "Buddy")
        case .guide:
            return localizedAppString("menu.dropdown.value.pet_stage.guide", defaultValue: "Guide")
        }
    }
    
    private var localizedPetEmotion: String {
        guard let petState else {
            return localizedAppString("menu.dropdown.value.none", defaultValue: "None")
        }
        
        switch petState.emotion {
        case .happy:
            return localizedAppString("menu.dropdown.value.pet_emotion.happy", defaultValue: "Happy")
        case .cheer:
            return localizedAppString("menu.dropdown.value.pet_emotion.cheer", defaultValue: "Cheer")
        case .sleep:
            return localizedAppString("menu.dropdown.value.pet_emotion.sleep", defaultValue: "Sleep")
        case .concern:
            return localizedAppString("menu.dropdown.value.pet_emotion.concern", defaultValue: "Concern")
        }
    }
}
