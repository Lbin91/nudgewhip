import AppKit
import Combine
import Observation
import SwiftUI

@MainActor
final class CountdownOverlayController {
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
            let isEnabled = menuBarViewModel.countdownOverlayEnabled
            if isEnabled {
                _ = menuBarViewModel.countdownOverlayPosition
                _ = menuBarViewModel.countdownOverlayVariant
            }
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

        panel.ignoresMouseEvents = countdownOverlayIgnoresMouseEvents(
            for: menuBarViewModel.countdownOverlayVariant
        )
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
        let panelSize = countdownOverlayPanelSize(for: menuBarViewModel.countdownOverlayVariant)
        let origin = countdownOverlayOrigin(
            visibleFrame: visibleFrame,
            panelSize: panelSize,
            inset: Self.panelInset,
            position: menuBarViewModel.countdownOverlayPosition
        )
        panel.setFrame(CGRect(origin: origin, size: panelSize), display: false)
    }

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: countdownOverlayPanelSize(for: .standard)),
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

func countdownOverlayPanelSize(for variant: CountdownOverlayVariant) -> CGSize {
    switch variant {
    case .standard:
        return CGSize(width: 146, height: 72)
    case .mini:
        return CGSize(width: 96, height: 32)
    }
}

func countdownOverlayIgnoresMouseEvents(for variant: CountdownOverlayVariant) -> Bool {
    switch variant {
    case .standard:
        return false
    case .mini:
        return true
    }
}

func countdownOverlayOrigin(
    visibleFrame: CGRect,
    panelSize: CGSize,
    inset: CGFloat,
    position: CountdownOverlayPosition
) -> CGPoint {
    switch position {
    case .topLeft:
        return CGPoint(
            x: visibleFrame.minX + inset,
            y: visibleFrame.maxY - inset - panelSize.height
        )
    case .topRight:
        return CGPoint(
            x: visibleFrame.maxX - inset - panelSize.width,
            y: visibleFrame.maxY - inset - panelSize.height
        )
    case .bottomLeft:
        return CGPoint(
            x: visibleFrame.minX + inset,
            y: visibleFrame.minY + inset
        )
    case .bottomRight:
        return CGPoint(
            x: visibleFrame.maxX - inset - panelSize.width,
            y: visibleFrame.minY + inset
        )
    }
}

private struct CountdownOverlayView: View {
    let menuBarViewModel: MenuBarViewModel
    let onClose: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, tolerance: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            switch menuBarViewModel.countdownOverlayVariant {
            case .standard:
                standardOverlay
            case .mini:
                miniOverlay
            }
        }
        .onReceive(timer) { value in
            now = value
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(overlayAccessibilityLabel)
    }

    private var overlayConfiguration: CountdownOverlayAccessibilityConfiguration {
        countdownOverlayAccessibilityConfiguration(
            increaseContrast: colorSchemeContrast == .increased,
            reduceTransparency: reduceTransparency
        )
    }

    private var standardOverlay: some View {
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
                        .background(Color.white.opacity(overlayConfiguration.closeButtonBackgroundOpacity), in: Circle())
                }
                .buttonStyle(.plain)
            }

            Text(standardPrimaryText)
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
                .fill(Color.black.opacity(overlayConfiguration.backgroundOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(overlayConfiguration.strokeOpacity), lineWidth: 1)
        )
    }

    private var miniOverlay: some View {
        Text(miniPrimaryText)
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(miniBackgroundOpacity))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(miniStrokeOpacity), lineWidth: 1)
            )
    }

    private var standardPrimaryText: String {
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

    private var miniPrimaryText: String {
        if let countdown = menuBarViewModel.overlayCountdownText(now: now) {
            return countdown
        }

        switch menuBarViewModel.runtimeState {
        case .limitedNoAX:
            return "AX"
        case .monitoring:
            return menuBarViewModel.configuredIdleThresholdText
        case .pausedManual:
            return "PAUSE"
        case .pausedWhitelist:
            return "ALLOW"
        case .alerting:
            return "IDLE"
        case .pausedSchedule:
            return "SCHED"
        case .suspendedSleepOrLock:
            return "SLEEP"
        }
    }

    private var miniBackgroundOpacity: Double {
        max(0.42, overlayConfiguration.backgroundOpacity - 0.14)
    }

    private var miniStrokeOpacity: Double {
        max(0.06, overlayConfiguration.strokeOpacity - 0.03)
    }

    private var overlayAccessibilityLabel: String {
        if let countdown = menuBarViewModel.overlayCountdownText(now: now) {
            return "\(menuBarViewModel.overlayRuntimeStateText), \(countdown)"
        }

        return menuBarViewModel.overlayRuntimeStateText
    }
}
