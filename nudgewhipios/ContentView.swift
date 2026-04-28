//
//  ContentView.swift
//  nudgewhipios
//
//  Created by Bongjin Lee on 4/16/26.
//

import SwiftUI

#if os(iOS)
struct CompanionTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(String(localized: "ios.tab.home"), systemImage: "house")
                }

            StatsView()
                .tabItem {
                    Label(String(localized: "ios.tab.stats"), systemImage: "chart.bar")
                }

            AlertsView()
                .tabItem {
                    Label(String(localized: "ios.tab.alerts"), systemImage: "bell")
                }

            SettingsView()
                .tabItem {
                    Label(String(localized: "ios.tab.settings"), systemImage: "gearshape")
                }
        }
    }
}
#endif

#Preview {
    CompanionTabView()
}
