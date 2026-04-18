//
//  ContentView.swift
//  nudgewhipios
//
//  Created by Bongjin Lee on 4/16/26.
//

import SwiftUI

struct CompanionTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house")
                }

            StatsView()
                .tabItem {
                    Label("통계", systemImage: "chart.bar")
                }

            AlertsView()
                .tabItem {
                    Label("알림", systemImage: "bell")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    CompanionTabView()
}
