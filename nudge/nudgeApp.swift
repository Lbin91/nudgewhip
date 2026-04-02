// nudgeApp.swift
// Nudge 앱의 @main 진입점.
//
// MenuBarExtra로 메뉴바 아이콘과 드롭다운 UI를 구성한다.
// MenuBarViewModel로 아이콘 상태를 반영하고, NudgeModelContainer로 SwiftData를 주입한다.

import AppKit
import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    @State private var menuBarViewModel = NudgeAppController.shared.menuBarViewModel
    
    init() {
        NudgeAppController.shared.startup()
    }
    
    private var menuTitle: String {
        localizedAppString("app.menu.title", defaultValue: "Nudge")
    }
    
    private var quitTitle: String {
        localizedAppString("app.menu.action.quit", defaultValue: "Quit")
    }
    
    var body: some Scene {
        MenuBarExtra(menuTitle, image: "MenuBarIcon") {
            ContentView(menuBarViewModel: menuBarViewModel)
            
            Divider()
            
            Button(localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide")) {
                NudgeAppController.shared.presentOnboarding()
            }
            
            Divider()
            
            Button(quitTitle) {
                NSApplication.shared.terminate(nil)
            }
        }
        .modelContainer(NudgeModelContainer.shared)
    }
}
