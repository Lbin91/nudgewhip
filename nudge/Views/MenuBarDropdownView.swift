// MenuBarDropdownView.swift
// 메뉴바 드롭다운의 전체 레이아웃을 구성하는 뷰.
//
// StatusSummaryView, QuickControlsView, DailySummaryView를 수직으로 배치한다.
// 설정과 펫 상태에서 로컬라이즈된 표시 문자열을 계산해 하위 뷰에 전달한다.

import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)
            
            QuickControlsView(
                menuBarViewModel: menuBarViewModel,
                petPresentationText: menuBarViewModel.petPresentationText,
                ttsStatusText: menuBarViewModel.ttsStatusText,
                idleThresholdText: menuBarViewModel.idleThresholdText,
                scheduleText: menuBarViewModel.scheduleText,
                scheduleEnabled: scheduleEnabled,
                scheduleStartTime: scheduleStartTime,
                scheduleEndTime: scheduleEndTime
            )
            
            DailySummaryView(
                todayStats: menuBarViewModel.todayStats,
                whitelistCount: menuBarViewModel.whitelistCount,
                petStageText: menuBarViewModel.petStageText,
                petEmotionText: menuBarViewModel.petEmotionText
            )
        }
    }
}
