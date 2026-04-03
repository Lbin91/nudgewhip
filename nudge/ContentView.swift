// ContentView.swift
// 메뉴바 드롭다운의 최상위 뷰.
//
// SwiftData 쿼리로 설정·펫·세션 데이터를 읽어 MenuBarDropdownView에 전달한다.
// 메뉴가 열릴 때는 순수 렌더링만 수행하고, runtime 동기화는 AppController/사용자 액션 경로에서 처리한다.

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
            todayStats: todayStats,
            scheduleEnabled: scheduleEnabledBinding,
            scheduleStartTime: scheduleStartTimeBinding,
            scheduleEndTime: scheduleEndTimeBinding
        )
        .padding(16)
        .frame(width: 320)
    }
    
    private var scheduleEnabledBinding: Binding<Bool> {
        Binding(
            get: { settings?.scheduleEnabled ?? false },
            set: { newValue in
                updateSettings { settings in
                    settings.scheduleEnabled = newValue
                    settings.updatedAt = .now
                }
            }
        )
    }
    
    private var scheduleStartTimeBinding: Binding<Date> {
        Binding(
            get: {
                dateFromSeconds(settings?.scheduleStartSecondsFromMidnight ?? 32_400)
            },
            set: { newValue in
                updateSettings { settings in
                    settings.scheduleStartSecondsFromMidnight = secondsFromMidnight(for: newValue)
                    settings.updatedAt = .now
                }
            }
        )
    }
    
    private var scheduleEndTimeBinding: Binding<Date> {
        Binding(
            get: {
                dateFromSeconds(settings?.scheduleEndSecondsFromMidnight ?? 61_200)
            },
            set: { newValue in
                updateSettings { settings in
                    settings.scheduleEndSecondsFromMidnight = secondsFromMidnight(for: newValue)
                    settings.updatedAt = .now
                }
            }
        )
    }
    
    private func updateSettings(_ update: (UserSettings) -> Void) {
        guard let settings else { return }
        update(settings)
        try? modelContext.save()
        menuBarViewModel.apply(settings: settings)
    }
    
    private func dateFromSeconds(_ seconds: Int) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        return startOfDay.addingTimeInterval(TimeInterval(seconds))
    }
    
    private func secondsFromMidnight(for date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 3600
            + calendar.component(.minute, from: date) * 60
    }
}

#Preview {
    ContentView(menuBarViewModel: MenuBarViewModel())
        .modelContainer(NudgeModelContainer.preview)
}
