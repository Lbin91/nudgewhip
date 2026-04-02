import AppKit
import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    private var menuTitle: String {
        let localizedValue = NSLocalizedString("app.menu.title", comment: "")
        return localizedValue == "app.menu.title" ? "Nudge" : localizedValue
    }
    
    private var quitTitle: String {
        let localizedValue = NSLocalizedString("app.menu.action.quit", comment: "")
        return localizedValue == "app.menu.action.quit" ? "Quit" : localizedValue
    }
    
    var body: some Scene {
        MenuBarExtra(menuTitle, systemImage: "cursorarrow.and.square.on.square.dashed") {
            // 이 안에 메뉴바 아이콘을 클릭했을 때 나올 UI를 넣어주면 돼.
            ContentView()
            
            Divider()
            
            Button(quitTitle) {
                NSApplication.shared.terminate(nil)
            }
        }
        .modelContainer(NudgeModelContainer.shared)
    }
}
