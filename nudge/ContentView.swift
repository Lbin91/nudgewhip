// ContentView.swift
// 메뉴바 드롭다운의 최상위 뷰.
//
// 메뉴바 드롭다운의 렌더링 전용 엔트리.
// 데이터는 MenuBarViewModel이 미리 계산한 스냅샷을 사용한다.

import SwiftUI

struct ContentView: View {
    let menuBarViewModel: MenuBarViewModel

    var body: some View {
        MenuBarDropdownView(
            menuBarViewModel: menuBarViewModel,
            scheduleEnabled: scheduleEnabledBinding,
            scheduleStartTime: scheduleStartTimeBinding,
            scheduleEndTime: scheduleEndTimeBinding
        )
        .padding(16)
        .frame(width: 320)
    }
    
    private var scheduleEnabledBinding: Binding<Bool> {
        Binding(
            get: { menuBarViewModel.scheduleEnabled },
            set: { menuBarViewModel.updateScheduleEnabled($0) }
        )
    }
    
    private var scheduleStartTimeBinding: Binding<Date> {
        Binding(
            get: { menuBarViewModel.scheduleStartTime },
            set: { menuBarViewModel.updateScheduleStartTime($0) }
        )
    }
    
    private var scheduleEndTimeBinding: Binding<Date> {
        Binding(
            get: { menuBarViewModel.scheduleEndTime },
            set: { menuBarViewModel.updateScheduleEndTime($0) }
        )
    }
}

#Preview {
    ContentView(menuBarViewModel: MenuBarViewModel())
}
