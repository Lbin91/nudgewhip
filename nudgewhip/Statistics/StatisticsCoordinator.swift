import AppKit
import SwiftUI

@MainActor
final class StatisticsCoordinator: NSObject, NSWindowDelegate {
    private let menuBarViewModel: MenuBarViewModel

    private var statisticsWindow: NSWindow?

    init(menuBarViewModel: MenuBarViewModel) {
        self.menuBarViewModel = menuBarViewModel
    }

    func present() {
        if let statisticsWindow {
            statisticsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = StatisticsWindowView(menuBarViewModel: menuBarViewModel)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = localizedAppString("settings.section.statistics", defaultValue: "Statistics")
        window.isReleasedWhenClosed = false
        window.center()
        window.delegate = self
        window.contentView = NSHostingView(rootView: rootView)

        statisticsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        statisticsWindow = nil
    }
}

private struct StatisticsWindowView: View {
    let menuBarViewModel: MenuBarViewModel

    var body: some View {
        ZStack {
            Color.nudgewhipBgCanvas.ignoresSafeArea()

            ScrollView {
                StatisticsDashboardView(
                    snapshot: menuBarViewModel.statisticsSnapshot,
                    appUsageSnapshot: menuBarViewModel.appUsageSnapshot
                )
                .padding(NudgeWhipSpacing.s5)
                .frame(maxWidth: 860, alignment: .leading)
            }
        }
        .frame(minWidth: 720, minHeight: 620)
    }
}
