#if DEBUG
import AppKit
import Combine
import SwiftUI

@MainActor
final class DebugIdleTimerOverlayController {
    private static let panelSize = CGSize(width: 190, height: 92)
    private static let panelInset: CGFloat = 16

    private let menuBarViewModel: MenuBarViewModel
    private let panel: NSPanel
    private var observers: [NSObjectProtocol] = []

    init(menuBarViewModel: MenuBarViewModel) {
        self.menuBarViewModel = menuBarViewModel
        self.panel = Self.makePanel()
        panel.contentView = NSHostingView(
            rootView: DebugIdleTimerOverlayView(menuBarViewModel: menuBarViewModel)
        )
        registerObservers()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func show() {
        positionPanel()
        panel.orderFrontRegardless()
    }

    private func registerObservers() {
        let center = NotificationCenter.default
        observers.append(
            center.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.positionPanel()
                }
            }
        )
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        let visibleFrame = screen.visibleFrame
        let origin = CGPoint(
            x: visibleFrame.minX + Self.panelInset,
            y: visibleFrame.maxY - Self.panelInset - Self.panelSize.height
        )
        let frame = CGRect(origin: origin, size: Self.panelSize)
        panel.setFrame(frame, display: false)
    }

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }
}

private struct DebugIdleTimerOverlayView: View {
    let menuBarViewModel: MenuBarViewModel

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DEBUG TIMER")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.82))

            Text(primaryText)
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text(menuBarViewModel.debugRuntimeStateText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.74))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .onReceive(timer) { value in
            now = value
        }
    }

    private var primaryText: String {
        if let countdown = menuBarViewModel.countdownText(now: now) {
            return countdown
        }

        switch menuBarViewModel.runtimeState {
        case .alerting:
            return "IDLE"
        case .pausedManual:
            return "PAUSE"
        case .pausedWhitelist:
            return "ALLOW"
        case .pausedSchedule:
            return "SCHED"
        case .suspendedSleepOrLock:
            return "SLEEP"
        case .limitedNoAX, .monitoring:
            return menuBarViewModel.configuredIdleThresholdText
        }
    }
}
#endif
