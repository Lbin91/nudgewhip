import AppKit
import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    @State private var menuBarViewModel = MenuBarViewModel()
    
    private var menuTitle: String {
        localizedAppString("app.menu.title", defaultValue: "Nudge")
    }
    
    private var quitTitle: String {
        localizedAppString("app.menu.action.quit", defaultValue: "Quit")
    }
    
    var body: some Scene {
        MenuBarExtra(menuTitle, systemImage: menuBarViewModel.systemImageName) {
            // 이 안에 메뉴바 아이콘을 클릭했을 때 나올 UI를 넣어주면 돼.
            ContentView(menuBarViewModel: menuBarViewModel)
            
            Divider()
            
            Button(quitTitle) {
                NSApplication.shared.terminate(nil)
            }
        }
        .modelContainer(NudgeModelContainer.shared)
    }
}
