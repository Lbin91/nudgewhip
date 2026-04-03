// MenuBarDropdownView.swift
// 메뉴바 드롭다운의 전체 레이아웃을 구성하는 뷰.
//
// StatusSummaryView, QuickControlsView, DailySummaryView를 수직으로 배치한다.
// 설정과 펫 상태에서 로컬라이즈된 표시 문자열을 계산해 하위 뷰에 전달한다.

import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    let settings: UserSettings?
    let petState: PetState?
    let whitelistCount: Int
    let todayStats: DailyStats
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)
            
            QuickControlsView(
                menuBarViewModel: menuBarViewModel,
                settings: settings,
                petPresentationText: petPresentationText,
                ttsStatusText: ttsStatusText,
                idleThresholdText: idleThresholdText,
                scheduleText: scheduleText,
                scheduleEnabled: scheduleEnabled,
                scheduleStartTime: scheduleStartTime,
                scheduleEndTime: scheduleEndTime
            )
            
            DailySummaryView(
                todayStats: todayStats,
                whitelistCount: whitelistCount,
                petStageText: localizedPetStage,
                petEmotionText: localizedPetEmotion
            )
        }
    }
    
    /// 설정값을 사람이 읽을 수 있는 시간 문자열로 변환
    private var idleThresholdText: String {
        guard let settings else { return localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable") }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = settings.idleThresholdSeconds >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: TimeInterval(settings.idleThresholdSeconds))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
    
    /// TTS 활성화 여부에 따른 표시 문자열
    private var ttsStatusText: String {
        settings?.ttsEnabled == true
            ? localizedAppString("menu.dropdown.value.enabled", defaultValue: "Enabled")
            : localizedAppString("menu.dropdown.value.disabled", defaultValue: "Disabled")
    }
    
    /// 펫 표시 모드(sprout/minimal) 로컬라이즈 문자열
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
    
    /// 스케줄 활성 상태 문자열
    private var scheduleText: String {
        guard let settings, settings.scheduleEnabled else {
            return localizedAppString("menu.dropdown.value.schedule.off", defaultValue: "Off")
        }
        let startMinutes = settings.scheduleStartSecondsFromMidnight / 60
        let endMinutes = settings.scheduleEndSecondsFromMidnight / 60
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        let startStr = formatter.string(from: TimeInterval(startMinutes * 60))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
        let endStr = formatter.string(from: TimeInterval(endMinutes * 60))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
        return "\(startStr) - \(endStr)"
    }
    
    /// 펫 성장 단계 로컬라이즈 문자열
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
    
    /// 펫 감정 상태 로컬라이즈 문자열
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
