import AppKit
import Combine
import Observation
import SwiftUI

@MainActor
final class CountdownOverlayController {
    private static let panelInset: CGFloat = 14

    private let menuBarViewModel: MenuBarViewModel
    private let panel: NSPanel
    private let feedbackPopover = NSPopover()
    private var observers: [NSObjectProtocol] = []
    private var presentedFeedbackKind: MiniOverlayAttentionKind?

    init(menuBarViewModel: MenuBarViewModel) {
        self.menuBarViewModel = menuBarViewModel
        self.panel = Self.makePanel()
        panel.contentView = NSHostingView(
            rootView: CountdownOverlayView(
                menuBarViewModel: menuBarViewModel,
                onClose: { [weak menuBarViewModel] in
                    menuBarViewModel?.updateCountdownOverlayEnabled(false)
                },
                onInfoTap: { [weak self] kind in
                    self?.toggleFeedbackPopover(for: kind)
                }
            )
        )
        feedbackPopover.behavior = .transient
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
            _ = menuBarViewModel.runtimeState
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
            feedbackPopover.performClose(nil)
            presentedFeedbackKind = nil
            panel.orderOut(nil)
            return
        }

        panel.ignoresMouseEvents = countdownOverlayIgnoresMouseEvents(
            for: menuBarViewModel.countdownOverlayVariant
        )
        positionPanel()
        syncFeedbackPopover()
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

    private func syncFeedbackPopover() {
        guard let presentedFeedbackKind else { return }
        guard presentedFeedbackKind == currentAttentionKind else {
            feedbackPopover.performClose(nil)
            self.presentedFeedbackKind = nil
            return
        }
    }

    private var currentAttentionKind: MiniOverlayAttentionKind? {
        guard menuBarViewModel.countdownOverlayEnabled,
              menuBarViewModel.countdownOverlayVariant == .mini else {
            return nil
        }
        return miniOverlayAttentionKind(for: menuBarViewModel.runtimeState)
    }

    private func toggleFeedbackPopover(for kind: MiniOverlayAttentionKind) {
        if feedbackPopover.isShown, presentedFeedbackKind == kind {
            feedbackPopover.performClose(nil)
            presentedFeedbackKind = nil
            return
        }

        showFeedbackPopover(for: kind)
    }

    private func showFeedbackPopover(for kind: MiniOverlayAttentionKind) {
        guard let contentView = panel.contentView else { return }

        feedbackPopover.contentSize = CGSize(width: 280, height: kind == .accessibilityNeeded ? 150 : 132)
        feedbackPopover.contentViewController = NSHostingController(
            rootView: CountdownOverlayFeedbackView(
                kind: kind,
                onPrimaryAction: { [weak self] in
                    self?.handlePrimaryAction(for: kind)
                },
                onDismiss: { [weak self] in
                    self?.feedbackPopover.performClose(nil)
                    self?.presentedFeedbackKind = nil
                }
            )
        )
        presentedFeedbackKind = kind

        let anchorRect = CGRect(
            x: max(0, contentView.bounds.maxX - 24),
            y: 0,
            width: 20,
            height: contentView.bounds.height
        )
        feedbackPopover.show(
            relativeTo: anchorRect,
            of: contentView,
            preferredEdge: preferredPopoverEdge
        )
    }

    private var preferredPopoverEdge: NSRectEdge {
        switch menuBarViewModel.countdownOverlayPosition {
        case .topLeft, .topRight:
            return .minY
        case .bottomLeft, .bottomRight:
            return .maxY
        }
    }

    private func handlePrimaryAction(for kind: MiniOverlayAttentionKind) {
        switch kind {
        case .accessibilityNeeded:
            _ = menuBarViewModel.openAccessibilitySettings()
        case .idleDetected:
            break
        }
        feedbackPopover.performClose(nil)
        presentedFeedbackKind = nil
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

enum MiniOverlayAttentionKind: String, Sendable {
    case accessibilityNeeded
    case idleDetected
}

private enum MiniOverlayVisualRole: Sendable {
    case neutral(text: String)
    case attention(text: String, kind: MiniOverlayAttentionKind)

    var text: String {
        switch self {
        case let .neutral(text), let .attention(text, _):
            return text
        }
    }

    var attentionKind: MiniOverlayAttentionKind? {
        switch self {
        case .neutral:
            return nil
        case let .attention(_, kind):
            return kind
        }
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
        return false
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

func miniOverlayAttentionKind(for runtimeState: NudgeWhipRuntimeState) -> MiniOverlayAttentionKind? {
    switch runtimeState {
    case .limitedNoAX:
        return .accessibilityNeeded
    case .alerting:
        return .idleDetected
    default:
        return nil
    }
}

private struct CountdownOverlayView: View {
    let menuBarViewModel: MenuBarViewModel
    let onClose: () -> Void
    let onInfoTap: (MiniOverlayAttentionKind) -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var now = Date()
    @State private var isHoveringMini = false
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
        let visualRole = miniVisualRole

        return ZStack {
            Text(visualRole.text)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(miniForegroundColor(for: visualRole))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 10)
                .padding(.trailing, visualRole.attentionKind == nil ? 10 : 28)

            if let attentionKind = visualRole.attentionKind {
                Button(action: { onInfoTap(attentionKind) }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(miniForegroundColor(for: visualRole).opacity(0.92))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 6)
                .accessibilityLabel(infoButtonAccessibilityLabel(for: attentionKind))
            } else if isHoveringMini {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .frame(width: 14, height: 14)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
            }
        }
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(miniBackgroundOpacity))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(miniStrokeOpacity), lineWidth: 1)
        )
        .onHover { hovering in
            isHoveringMini = hovering
        }
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

    private var miniVisualRole: MiniOverlayVisualRole {
        if let countdown = menuBarViewModel.overlayCountdownText(now: now) {
            return .neutral(text: countdown)
        }

        switch menuBarViewModel.runtimeState {
        case .limitedNoAX:
            return .attention(text: "AX", kind: .accessibilityNeeded)
        case .monitoring:
            return .neutral(text: menuBarViewModel.configuredIdleThresholdText)
        case .pausedManual:
            return .neutral(text: "PAUSE")
        case .pausedWhitelist:
            return .neutral(text: "ALLOW")
        case .alerting:
            return .attention(text: "IDLE", kind: .idleDetected)
        case .pausedSchedule:
            return .neutral(text: "SCHED")
        case .suspendedSleepOrLock:
            return .neutral(text: "SLEEP")
        }
    }

    private func miniForegroundColor(for visualRole: MiniOverlayVisualRole) -> Color {
        switch visualRole.attentionKind {
        case .accessibilityNeeded:
            return Color.nudgewhipAccent
        case .idleDetected:
            return Color.nudgewhipAlert
        case nil:
            return .white
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

    private func infoButtonAccessibilityLabel(for kind: MiniOverlayAttentionKind) -> String {
        switch kind {
        case .accessibilityNeeded:
            return localizedAppString(
                "overlay.mini.feedback.accessibility.info_label",
                defaultValue: "Learn why Accessibility access is needed"
            )
        case .idleDetected:
            return localizedAppString(
                "overlay.mini.feedback.idle.info_label",
                defaultValue: "Learn why the idle warning is showing"
            )
        }
    }
}

private struct CountdownOverlayFeedbackView: View {
    let kind: MiniOverlayAttentionKind
    let onPrimaryAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(bodyText)
                .font(.subheadline)
                .foregroundStyle(Color.nudgewhipTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                if let primaryButtonTitle {
                    Button(primaryButtonTitle, action: onPrimaryAction)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }

                Button(closeButtonTitle, action: onDismiss)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
        .background(Color.nudgewhipBgSurface)
    }

    private var title: String {
        switch kind {
        case .accessibilityNeeded:
            return localizedAppString(
                "overlay.mini.feedback.accessibility.title",
                defaultValue: "Accessibility access is needed"
            )
        case .idleDetected:
            return localizedAppString(
                "overlay.mini.feedback.idle.title",
                defaultValue: "Idle input detected"
            )
        }
    }

    private var bodyText: String {
        switch kind {
        case .accessibilityNeeded:
            return localizedAppString(
                "overlay.mini.feedback.accessibility.body",
                defaultValue: "NudgeWhip needs Accessibility access to detect idle input reliably. Enable it in System Settings to restore normal monitoring."
            )
        case .idleDetected:
            return localizedAppString(
                "overlay.mini.feedback.idle.body",
                defaultValue: "There has been no input for your configured threshold, so NudgeWhip is showing a nudge. It clears automatically when activity resumes."
            )
        }
    }

    private var primaryButtonTitle: String? {
        switch kind {
        case .accessibilityNeeded:
            return localizedAppString(
                "overlay.mini.feedback.accessibility.primary",
                defaultValue: "Open Settings"
            )
        case .idleDetected:
            return nil
        }
    }

    private var closeButtonTitle: String {
        localizedAppString("overlay.mini.feedback.close", defaultValue: "Close")
    }
}
