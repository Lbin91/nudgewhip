import AppKit
import Combine
import Observation
import SwiftUI

@MainActor
final class CountdownOverlayController {
    private static let panelSize = CGSize(width: 146, height: 72)
    private static let panelInset: CGFloat = 14

    private let menuBarViewModel: MenuBarViewModel
    private let panel: NSPanel
    private var observers: [NSObjectProtocol] = []

    init(menuBarViewModel: MenuBarViewModel) {
        self.menuBarViewModel = menuBarViewModel
        self.panel = Self.makePanel()
        panel.contentView = NSHostingView(
            rootView: CountdownOverlayView(
                menuBarViewModel: menuBarViewModel,
                onClose: { [weak menuBarViewModel] in
                    menuBarViewModel?.updateCountdownOverlayEnabled(false)
                }
            )
        )
        registerObservers()
        observeVisibility()
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func showIfNeeded() {
        updateVisibility()
    }

    private func observeVisibility() {
        withObservationTracking {
            _ = menuBarViewModel.countdownOverlayEnabled
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateVisibility()
                self?.observeVisibility()
            }
        }
    }

    private func updateVisibility() {
        guard menuBarViewModel.countdownOverlayEnabled else {
            panel.orderOut(nil)
            return
        }

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
                    self?.updateVisibility()
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
        panel.setFrame(CGRect(origin: origin, size: Self.panelSize), display: false)
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
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        return panel
    }
}

private struct CountdownOverlayView: View {
    let menuBarViewModel: MenuBarViewModel
    let onClose: () -> Void

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 6) {
                Text("NUDGE")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))

                Spacer(minLength: 0)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .frame(width: 14, height: 14)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }

            Text(primaryText)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)

            Text(menuBarViewModel.overlayRuntimeStateText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.66))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.68))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onReceive(timer) { value in
            now = value
        }
    }

    private var primaryText: String {
        if let countdown = menuBarViewModel.overlayCountdownText(now: now) {
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
