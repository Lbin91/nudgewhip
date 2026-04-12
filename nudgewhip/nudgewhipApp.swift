// nudgewhipApp.swift
// NudgeWhip 앱의 @main 진입점.
//
// MenuBarExtra로 메뉴바 아이콘과 드롭다운 UI를 구성한다.
// MenuBarViewModel로 아이콘 상태를 반영하고, NudgeWhipModelContainer로 SwiftData를 주입한다.

import AppKit
import SwiftUI
import SwiftData

@main
struct NudgeWhipApp: App {
    @State private var menuBarViewModel = NudgeWhipAppController.shared.menuBarViewModel
    
    init() {
        NudgeWhipAppController.shared.startup()
    }
    
    private var menuTitle: String {
        localizedAppString("app.menu.title", defaultValue: "NudgeWhip")
    }
    
    private var quitTitle: String {
        localizedAppString("app.menu.action.quit", defaultValue: "Quit")
    }
    
    var body: some Scene {
        // CRITICAL NON-REGRESSION:
        // This MenuBarExtra MUST stay in `.window` style, and pause actions MUST
        // stay inside the custom window content as plain buttons.
        //
        // Reverting this scene back to default menu tracking or reintroducing a
        // nested `Menu` for pause actions caused repeat regressions:
        // 1. hover invalidated the submenu,
        // 2. entering Pause flickered or dismissed the UI,
        // 3. countdown / redraw churn destabilized pause selection.
        //
        // If someone wants to change this again, they must prove full manual QA
        // for pause entry/hover/selection before touching this architecture.
        MenuBarExtra {
            ContentView(
                menuBarViewModel: menuBarViewModel,
                onOpenStatistics: { NudgeWhipAppController.shared.presentStatistics() },
                onOpenSettings: { NudgeWhipAppController.shared.presentSettings() },
                onOpenOnboarding: { NudgeWhipAppController.shared.presentOnboarding() },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        } label: {
            MenuBarExtraLabelView(
                menuBarViewModel: menuBarViewModel,
                accessibilityLabel: menuTitle
            )
        }
        .menuBarExtraStyle(.window)
        .modelContainer(NudgeWhipModelContainer.shared)
    }
}
