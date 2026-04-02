import AppKit
import SwiftUI
import SwiftData

@main
struct NudgeApp: App {
    var body: some Scene {
        MenuBarExtra("Nudge", systemImage: "cursorarrow.and.square.on.square.dashed") {
            // 이 안에 메뉴바 아이콘을 클릭했을 때 나올 UI를 넣어주면 돼.
            ContentView()
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .modelContainer(NudgeModelContainer.shared)
    }
}
