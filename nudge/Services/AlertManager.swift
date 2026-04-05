import AppKit
import SwiftUI
import UserNotifications

enum AlertVisualStyle: Equatable, Sendable {
    case perimeterPulse
    case gentleNudge
    case strongVisualNudge
}

@MainActor
protocol AlertManaging: AnyObject {
    func handle(snapshot: RuntimeSnapshot)
    func apply(settings: UserSettings)
}

@MainActor
protocol AlertPresenting: AnyObject {
    func show(style: AlertVisualStyle)
    func hide()
}

@MainActor
protocol NotificationNudgeManaging: AnyObject {
    func deliverThirdStageNudge()
    func clearPendingNudges()
}

@MainActor
final class AlertManager: AlertManaging {
    private let presenter: AlertPresenting
    private let notificationNudgeManager: NotificationNudgeManaging
    private let nowProvider: @MainActor () -> Date
    private(set) var activeStyle: AlertVisualStyle?
    private var lastDeliveredNotificationStep = 0
    private var visualAlertTimestamps: [Date] = []
    private var thirdStageNotificationTimestamps: [Date] = []
    private var alertsPerHourLimit = 6
    private var thirdStagePerHourLimit = 2
    
    init(
        presenter: AlertPresenting? = nil,
        notificationNudgeManager: NotificationNudgeManaging? = nil,
        nowProvider: @escaping @MainActor () -> Date = { .now }
    ) {
        self.presenter = presenter ?? PerimeterPulsePresenter()
        self.notificationNudgeManager = notificationNudgeManager ?? NotificationNudgeManager()
        self.nowProvider = nowProvider
    }
    
    func handle(snapshot: RuntimeSnapshot) {
        let now = nowProvider()
        pruneTimestamps(now: now)
        
        guard let nextStyle = visualStyle(for: snapshot) else {
            guard activeStyle != nil else { return }
            presenter.hide()
            notificationNudgeManager.clearPendingNudges()
            activeStyle = nil
            lastDeliveredNotificationStep = 0
            return
        }
        
        if activeStyle != nextStyle, canPresentVisualAlert {
            playSound(for: nextStyle)
            presenter.show(style: nextStyle)
            activeStyle = nextStyle
            visualAlertTimestamps.append(now)
        }
        
        if snapshot.alertEscalationStep >= 4,
           snapshot.alertEscalationStep > lastDeliveredNotificationStep,
           canPresentThirdStageNotification {
            notificationNudgeManager.deliverThirdStageNudge()
            thirdStageNotificationTimestamps.append(now)
            lastDeliveredNotificationStep = snapshot.alertEscalationStep
        }
    }
    
    func apply(settings: UserSettings) {
        alertsPerHourLimit = max(0, settings.alertsPerHourLimit)
        thirdStagePerHourLimit = max(0, settings.ttsPerHourLimit)
    }

    private func playSound(for style: AlertVisualStyle) {
        let soundName: String
        switch style {
        case .perimeterPulse: soundName = "Tink"
        case .gentleNudge: soundName = "Hero"
        case .strongVisualNudge: soundName = "Sosumi"
        }
        NSSound(named: soundName)?.play()
    }
    
    private func visualStyle(for snapshot: RuntimeSnapshot) -> AlertVisualStyle? {
        guard snapshot.runtimeState == .alerting else { return nil }
        
        switch snapshot.contentState {
        case .idleDetected:
            return .perimeterPulse
        case .gentleNudge:
            return .gentleNudge
        case .strongNudge:
            return .strongVisualNudge
        case .focus, .recovery, .break, .remoteEscalation:
            return nil
        }
    }
    
    private var canPresentVisualAlert: Bool {
        visualAlertTimestamps.count < alertsPerHourLimit
    }
    
    private var canPresentThirdStageNotification: Bool {
        thirdStageNotificationTimestamps.count < thirdStagePerHourLimit
    }
    
    private func pruneTimestamps(now: Date) {
        let cutoff = now.addingTimeInterval(-3600)
        visualAlertTimestamps.removeAll { $0 < cutoff }
        thirdStageNotificationTimestamps.removeAll { $0 < cutoff }
    }
}

@MainActor
final class NotificationNudgeManager: NotificationNudgeManaging {
    private let center: UNUserNotificationCenter
    private let identifier = "nudge.third-stage-notification"
    
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    func deliverThirdStageNudge() {
        Task {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await schedule()
            case .notDetermined:
                let granted = try? await center.requestAuthorization(options: [.alert, .sound])
                if granted == true {
                    await schedule()
                }
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }
    
    func clearPendingNudges() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    private func schedule() async {
        clearPendingNudges()
        
        let content = UNMutableNotificationContent()
        content.title = localizedAppString("app.menu.title", defaultValue: "NudgeWhip")
        content.body = localizedAppString(
            "alert.notification.third_stage.body",
            defaultValue: "You've been away for a while. Come back to your focus flow."
        )
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try? await center.add(request)
    }
}

@MainActor
final class PerimeterPulsePresenter: AlertPresenting {
    private let screenFramesProvider: @MainActor () -> [CGRect]
    private let panelFactory: @MainActor (CGRect) -> NSPanel
    private var panelsByFrameKey: [String: NSPanel] = [:]
    
    init(
        screenFramesProvider: @escaping @MainActor () -> [CGRect] = {
            NSScreen.screens.map(\.frame)
        },
        panelFactory: @escaping @MainActor (CGRect) -> NSPanel = { frame in
            makeAlertPanel(contentRect: frame)
        }
    ) {
        self.screenFramesProvider = screenFramesProvider
        self.panelFactory = panelFactory
    }
    
    func show(style: AlertVisualStyle) {
        let frames = screenFramesProvider()
        guard !frames.isEmpty else { return }
        
        var nextPanelsByFrameKey: [String: NSPanel] = [:]
        for frame in frames {
            let key = Self.frameKey(for: frame)
            let panel = panelsByFrameKey[key] ?? panelFactory(frame)
            panel.setFrame(frame, display: false)
            panel.contentView = NSHostingView(rootView: AlertOverlayView(style: style))
            panel.orderFrontRegardless()
            nextPanelsByFrameKey[key] = panel
        }
        
        let staleKeys = Set(panelsByFrameKey.keys).subtracting(nextPanelsByFrameKey.keys)
        for staleKey in staleKeys {
            panelsByFrameKey[staleKey]?.orderOut(nil)
            panelsByFrameKey[staleKey]?.close()
        }
        
        panelsByFrameKey = nextPanelsByFrameKey
    }
    
    func hide() {
        for panel in panelsByFrameKey.values {
            panel.orderOut(nil)
            panel.close()
        }
        panelsByFrameKey.removeAll()
    }
    
    private static func frameKey(for frame: CGRect) -> String {
        "\(frame.origin.x),\(frame.origin.y),\(frame.size.width),\(frame.size.height)"
    }
}

@MainActor
private func makeAlertPanel(contentRect: CGRect) -> NSPanel {
        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
}

private struct AlertOverlayView: View {
    let style: AlertVisualStyle
    @State private var isActive = false
    @State private var showCenterMessage = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if style == .strongVisualNudge {
                    Color.black.opacity(isActive ? 0.16 : 0.04)
                        .ignoresSafeArea()
                }

                Rectangle()
                    .strokeBorder(borderColor.opacity(isActive ? activeOpacity : idleOpacity), lineWidth: borderWidth)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(style == .strongVisualNudge ? 0 : 6)
                    .shadow(color: borderColor.opacity(isActive ? shadowOpacity : 0.08), radius: shadowRadius)

                if style != .perimeterPulse {
                    centerMessageView
                }
            }
            .onAppear {
                withAnimation(animation.repeatForever(autoreverses: true)) {
                    isActive = true
                }
                if style != .perimeterPulse {
                    withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                        showCenterMessage = true
                    }
                }
            }
        }
        .background(Color.clear)
    }

    @ViewBuilder
    private var centerMessageView: some View {
        if showCenterMessage {
            VStack(spacing: 12) {
                Image(systemName: style == .gentleNudge ? "hand.wave.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)

                Text(alertMessage)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var alertMessage: String {
        switch style {
        case .perimeterPulse:
            return ""
        case .gentleNudge:
            return localizedAppString("alert.message.gentle_nudge", defaultValue: "Let's refocus 💡")
        case .strongVisualNudge:
            return localizedAppString("alert.message.strong_nudge", defaultValue: "Come back now! ⚡")
        }
    }

    private var borderColor: Color {
        switch style {
        case .perimeterPulse, .gentleNudge: .orange
        case .strongVisualNudge: .red
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .perimeterPulse: 12
        case .gentleNudge: 14
        case .strongVisualNudge: 18
        }
    }

    private var activeOpacity: Double {
        switch style {
        case .perimeterPulse: 0.92
        case .gentleNudge: 0.95
        case .strongVisualNudge: 0.98
        }
    }

    private var idleOpacity: Double {
        switch style {
        case .perimeterPulse: 0.18
        case .gentleNudge: 0.22
        case .strongVisualNudge: 0.28
        }
    }

    private var shadowOpacity: Double {
        switch style {
        case .perimeterPulse: 0.45
        case .gentleNudge: 0.55
        case .strongVisualNudge: 0.65
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .perimeterPulse: 14
        case .gentleNudge: 18
        case .strongVisualNudge: 24
        }
    }

    private var animation: Animation {
        switch style {
        case .perimeterPulse: .easeInOut(duration: 0.85)
        case .gentleNudge: .easeInOut(duration: 0.7)
        case .strongVisualNudge: .easeInOut(duration: 0.55)
        }
    }
}
