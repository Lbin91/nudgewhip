// ContentView.swift
// 메뉴바 드롭다운의 최상위 뷰.
//
// SwiftData 쿼리로 설정·펫·세션 데이터를 읽어 MenuBarDropdownView에 전달한다.
// .task에서 초기 데이터 시딩과 모니터링 시작을 트리거한다.

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsCollection: [UserSettings]
    @Query private var petStates: [PetState]
    @Query private var whitelistApps: [WhitelistApp]
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var focusSessions: [FocusSession]
    
    let menuBarViewModel: MenuBarViewModel
    
    /// 첫 번째 UserSettings 인스턴스
    private var settings: UserSettings? {
        settingsCollection.first
    }
    
    /// 첫 번째 PetState 인스턴스
    private var petState: PetState? {
        petStates.first
    }
    
    /// 오늘 날짜의 포커스 통계 집계
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
