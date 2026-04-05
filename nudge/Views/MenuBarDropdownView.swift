import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)

            QuickControlsView(
                menuBarViewModel: menuBarViewModel,
                idleThresholdText: menuBarViewModel.idleThresholdText,
                scheduleText: menuBarViewModel.scheduleText,
                scheduleEnabled: scheduleEnabled,
                scheduleStartTime: scheduleStartTime,
                scheduleEndTime: scheduleEndTime
            )

            DailySummaryView(
                todayStats: menuBarViewModel.todayStats,
                whitelistCount: menuBarViewModel.whitelistCount
            )
        }
        .padding(NudgeSpacing.s3)
        .frame(width: NudgeLayout.popoverWidth)
    }
}
