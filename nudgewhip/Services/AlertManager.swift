import AppKit
import SwiftUI
import UserNotifications

enum AlertVisualStyle: Equatable, Sendable {
    case perimeterPulse
    case gentleNudge
    case strongVisualNudge
}

struct AlertAccessibilityOptions: Equatable {
    var reduceMotion = false
    var increaseContrast = false
    var differentiateWithoutColor = false
    var reduceTransparency = false
}

struct AlertVisualConfiguration: Equatable {
    let animatePulse: Bool
    let animatesMessageEntrance: Bool
    let usesOpaqueSurface: Bool
    let showsStageBadge: Bool
    let borderWidth: CGFloat
    let activeOpacity: Double
    let idleOpacity: Double
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let backdropActiveOpacity: Double
    let backdropIdleOpacity: Double
    let dashPattern: [CGFloat]
}

func alertVisualConfiguration(
    for style: AlertVisualStyle,
    accessibility: AlertAccessibilityOptions
) -> AlertVisualConfiguration {
    let baseBorderWidth: CGFloat
    let baseActiveOpacity: Double
    let baseIdleOpacity: Double
    let baseShadowOpacity: Double
    let baseShadowRadius: CGFloat

    switch style {
    case .perimeterPulse:
        baseBorderWidth = 12
        baseActiveOpacity = 0.92
        baseIdleOpacity = 0.18
        baseShadowOpacity = 0.45
        baseShadowRadius = 14
    case .gentleNudge:
        baseBorderWidth = 14
        baseActiveOpacity = 0.95
        baseIdleOpacity = 0.22
        baseShadowOpacity = 0.55
        baseShadowRadius = 18
    case .strongVisualNudge:
        baseBorderWidth = 18
        baseActiveOpacity = 0.98
        baseIdleOpacity = 0.28
        baseShadowOpacity = 0.65
        baseShadowRadius = 24
    }

    let usesOpaqueSurface = accessibility.increaseContrast || accessibility.reduceTransparency
    let animatePulse = !accessibility.reduceMotion
    let animatesMessageEntrance = !accessibility.reduceMotion
    let showsStageBadge = accessibility.differentiateWithoutColor
    let dashPattern: [CGFloat]
    if accessibility.differentiateWithoutColor {
        switch style {
        case .perimeterPulse:
            dashPattern = [18, 12]
        case .gentleNudge:
            dashPattern = [8, 8]
        case .strongVisualNudge:
            dashPattern = []
        }
    } else {
        dashPattern = []
    }

    let borderWidth = baseBorderWidth + (accessibility.increaseContrast ? 2 : 0)
    let activeOpacity = accessibility.reduceMotion ? 1.0 : baseActiveOpacity
    let idleOpacity = accessibility.reduceMotion ? max(baseActiveOpacity - 0.12, 0.52) : baseIdleOpacity
    let shadowOpacity = accessibility.increaseContrast ? min(baseShadowOpacity + 0.12, 0.9) : baseShadowOpacity
    let shadowRadius = baseShadowRadius + (accessibility.increaseContrast ? 4 : 0)

    let backdropActiveOpacity: Double
    let backdropIdleOpacity: Double
    if style == .strongVisualNudge {
        backdropActiveOpacity = accessibility.increaseContrast ? 0.24 : 0.16
        backdropIdleOpacity = accessibility.reduceMotion || accessibility.increaseContrast ? 0.12 : 0.04
    } else {
        backdropActiveOpacity = 0
        backdropIdleOpacity = 0
    }

    return AlertVisualConfiguration(
        animatePulse: animatePulse,
        animatesMessageEntrance: animatesMessageEntrance,
        usesOpaqueSurface: usesOpaqueSurface,
        showsStageBadge: showsStageBadge,
        borderWidth: borderWidth,
        activeOpacity: activeOpacity,
        idleOpacity: idleOpacity,
        shadowOpacity: shadowOpacity,
        shadowRadius: shadowRadius,
        backdropActiveOpacity: backdropActiveOpacity,
        backdropIdleOpacity: backdropIdleOpacity,
        dashPattern: dashPattern
    )
}

struct CountdownOverlayAccessibilityConfiguration: Equatable {
    let backgroundOpacity: Double
    let strokeOpacity: Double
    let closeButtonBackgroundOpacity: Double
}

func countdownOverlayAccessibilityConfiguration(
    increaseContrast: Bool,
    reduceTransparency: Bool
) -> CountdownOverlayAccessibilityConfiguration {
    let prefersOpaqueSurface = increaseContrast || reduceTransparency
    return CountdownOverlayAccessibilityConfiguration(
        backgroundOpacity: prefersOpaqueSurface ? 0.9 : 0.68,
        strokeOpacity: prefersOpaqueSurface ? 0.24 : 0.08,
        closeButtonBackgroundOpacity: prefersOpaqueSurface ? 0.18 : 0.08
    )
}

@MainActor
protocol AlertManaging: AnyObject {
    func handle(snapshot: RuntimeSnapshot)
    func apply(settings: UserSettings)
    func update(species: String)
}

@MainActor
protocol AlertPresenting: AnyObject {
    func show(style: AlertVisualStyle, message: String?)
    func hide()
}

@MainActor
protocol NotificationNudgeManaging: AnyObject {
    func deliverThirdStageNudge(body: String)
    func clearPendingNudges()
}

@MainActor
protocol AlertSoundPlaying: AnyObject {
    func play(named soundName: String, repeatCount: Int, interval: TimeInterval)
    func stopAll()
}

@MainActor
final class AlertSoundPlayer: AlertSoundPlaying {
    private let customSoundDurationByName: [String: TimeInterval] = [
        "cowboy_step1": 1.92
    ]
    private var pendingWorkItems: [DispatchWorkItem] = []
    private var activeSounds: [ObjectIdentifier: NSSound] = [:]
    private var generation = 0

    func play(named soundName: String, repeatCount: Int, interval: TimeInterval) {
        cancelAllPlayback(advanceGeneration: false)
        generation += 1
        let playGeneration = generation
        guard repeatCount > 0 else { return }

        for index in 0..<repeatCount {
            let workItem = DispatchWorkItem { [weak self] in
                self?.playNow(named: soundName, generation: playGeneration)
            }
            pendingWorkItems.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval * Double(index)), execute: workItem)
        }
    }

    func stopAll() {
        cancelAllPlayback(advanceGeneration: true)
    }

    private func cancelAllPlayback(advanceGeneration: Bool) {
        if advanceGeneration {
            generation += 1
        }
        pendingWorkItems.forEach { $0.cancel() }
        pendingWorkItems.removeAll()

        for sound in activeSounds.values {
            sound.stop()
        }
        activeSounds.removeAll()
    }

    private func playNow(named soundName: String, generation: Int) {
        guard generation == self.generation else { return }
        guard let sound = makeSound(named: soundName) else { return }

        let soundIdentifier = ObjectIdentifier(sound)
        activeSounds[soundIdentifier] = sound
        sound.play()

        let cleanupDelay = max(sound.duration, customSoundDurationByName[soundName] ?? 0.5) + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + cleanupDelay) { [weak self, weak sound] in
            guard let self, let sound else { return }
            guard generation == self.generation else { return }
            self.activeSounds.removeValue(forKey: ObjectIdentifier(sound))
        }
    }

    private func makeSound(named soundName: String) -> NSSound? {
        if let namedSound = NSSound(named: soundName)?.copy() as? NSSound {
            return namedSound
        }

        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
            return NSSound(contentsOf: soundURL, byReference: false)
        }

        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3", subdirectory: "Sounds") {
            return NSSound(contentsOf: soundURL, byReference: false)
        }

        return nil
    }
}

struct AlertSoundPlan: Equatable, Sendable {
    let soundName: String
    let repeatCount: Int
    let repeatInterval: TimeInterval
}

private enum AlertCopySlot: Hashable {
    case gentleWarning
    case strongWarning
    case notificationLine
}

private struct AlertCopyVariant {
    let key: String
    let defaultValue: String
}

private func alertCopyVariants(for slot: AlertCopySlot) -> [AlertCopyVariant] {
    switch slot {
    case .gentleWarning:
        return [
            AlertCopyVariant(
                key: "alert.message.gentle_nudge.1",
                defaultValue: "The flow paused. Coming back now will be easy."
            ),
            AlertCopyVariant(
                key: "alert.message.gentle_nudge.2",
                defaultValue: "I'll hold the line a little longer. Let's start again."
            ),
            AlertCopyVariant(
                key: "alert.message.gentle_nudge.3",
                defaultValue: "A brief detour. You can find your way back from here."
            )
        ]
    case .strongWarning:
        return [
            AlertCopyVariant(
                key: "alert.message.strong_nudge.1",
                defaultValue: "You have not returned yet. It is not too late to come back now."
            ),
            AlertCopyVariant(
                key: "alert.message.strong_nudge.2",
                defaultValue: "The pause is getting longer. It is time to return to work."
            ),
            AlertCopyVariant(
                key: "alert.message.strong_nudge.3",
                defaultValue: "You have been away for a while. Now would be a good time to return."
            )
        ]
    case .notificationLine:
        return [
            AlertCopyVariant(
                key: "alert.notification.third_stage.body.1",
                defaultValue: "Let's restart now."
            ),
            AlertCopyVariant(
                key: "alert.notification.third_stage.body.2",
                defaultValue: "You can continue right here."
            ),
            AlertCopyVariant(
                key: "alert.notification.third_stage.body.3",
                defaultValue: "Shall we settle back in?"
            )
        ]
    }
}

func alertSoundPlan(for style: AlertVisualStyle, theme: SoundTheme) -> AlertSoundPlan {
    if theme == .whip {
        let repeatCount: Int
        switch style {
        case .perimeterPulse:
            repeatCount = 1
        case .gentleNudge:
            repeatCount = 2
        case .strongVisualNudge:
            repeatCount = 3
        }

        return AlertSoundPlan(soundName: "cowboy_step1", repeatCount: repeatCount, repeatInterval: 2.0)
    }

    let soundName: String
    switch style {
    case .perimeterPulse:
        soundName = "Tink"
    case .gentleNudge:
        soundName = "Hero"
    case .strongVisualNudge:
        soundName = "Sosumi"
    }

    return AlertSoundPlan(soundName: soundName, repeatCount: 1, repeatInterval: 0)
}

@MainActor
final class AlertManager: AlertManaging {
    private let presenter: AlertPresenting
    private let notificationNudgeManager: NotificationNudgeManaging
    private let soundPlayer: AlertSoundPlaying
    private let nowProvider: @MainActor () -> Date
    private(set) var activeStyle: AlertVisualStyle?
    private var lastDeliveredNotificationStep = 0
    private var visualAlertTimestamps: [Date] = []
    private var thirdStageNotificationTimestamps: [Date] = []
    private var alertsPerHourLimit = 6
    private var thirdStagePerHourLimit = 2
    private var currentSpecies: String = "default"
    private var currentSoundTheme: SoundTheme = .whip
    private var lastPresentedCopy: String?
    private var nextCopyIndexBySlot: [AlertCopySlot: Int] = [:]
    
    init(
        presenter: AlertPresenting? = nil,
        notificationNudgeManager: NotificationNudgeManaging? = nil,
        soundPlayer: AlertSoundPlaying? = nil,
        nowProvider: @escaping @MainActor () -> Date = { .now }
    ) {
        self.presenter = presenter ?? PerimeterPulsePresenter()
        self.notificationNudgeManager = notificationNudgeManager ?? NotificationNudgeManager()
        self.soundPlayer = soundPlayer ?? AlertSoundPlayer()
        self.nowProvider = nowProvider
    }
    
    func handle(snapshot: RuntimeSnapshot) {
        let now = nowProvider()
        pruneTimestamps(now: now)
        
        guard let nextStyle = visualStyle(for: snapshot) else {
            guard activeStyle != nil else { return }
            presenter.hide()
            soundPlayer.stopAll()
            notificationNudgeManager.clearPendingNudges()
            activeStyle = nil
            lastDeliveredNotificationStep = 0
            return
        }
        
        if activeStyle != nextStyle && canPresentVisualAlert {
            let soundPlan = alertSoundPlan(for: nextStyle, theme: currentSoundTheme)
            let message = nextCopyMessage(for: nextStyle)
            soundPlayer.play(
                named: soundPlan.soundName,
                repeatCount: soundPlan.repeatCount,
                interval: soundPlan.repeatInterval
            )
            presenter.show(style: nextStyle, message: message)
            activeStyle = nextStyle
            visualAlertTimestamps.append(now)
        }
        
        if snapshot.alertEscalationStep >= 4,
           lastDeliveredNotificationStep < 4,
           canPresentThirdStageNotification {
            notificationNudgeManager.deliverThirdStageNudge(body: nextCopyMessage(for: .notificationLine))
            thirdStageNotificationTimestamps.append(now)
            lastDeliveredNotificationStep = 4
        }
    }
    
    func apply(settings: UserSettings) {
        alertsPerHourLimit = max(0, settings.alertsPerHourLimit)
        thirdStagePerHourLimit = max(0, settings.notificationNudgePerHourLimit)
        currentSoundTheme = settings.soundTheme
    }

    func update(species: String) {
        self.currentSpecies = species
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

    private func nextCopyMessage(for style: AlertVisualStyle) -> String? {
        let slot: AlertCopySlot?
        switch style {
        case .perimeterPulse:
            slot = nil
        case .gentleNudge:
            slot = .gentleWarning
        case .strongVisualNudge:
            slot = .strongWarning
        }

        guard let slot else { return nil }
        return nextCopyMessage(for: slot)
    }

    private func nextCopyMessage(for slot: AlertCopySlot) -> String {
        let variants = alertCopyVariants(for: slot)
        guard !variants.isEmpty else { return "" }

        let localizedVariants = variants.map { localizedAppString($0.key, defaultValue: $0.defaultValue) }
        let startIndex = (nextCopyIndexBySlot[slot] ?? 0) % localizedVariants.count

        let selectedIndex = (0..<localizedVariants.count)
            .map { (startIndex + $0) % localizedVariants.count }
            .first { localizedVariants[$0] != lastPresentedCopy }
            ?? startIndex

        let message = localizedVariants[selectedIndex]
        nextCopyIndexBySlot[slot] = (selectedIndex + 1) % localizedVariants.count
        lastPresentedCopy = message
        return message
    }
}

@MainActor
final class NotificationNudgeManager: NotificationNudgeManaging {
    private let center: UNUserNotificationCenter
    private let identifier = "nudgewhip.third-stage-notification"
    
    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }
    
    func deliverThirdStageNudge(body: String) {
        Task {
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await schedule(body: body)
            case .notDetermined:
                let granted = try? await center.requestAuthorization(options: [.alert, .sound])
                if granted == true {
                    await schedule(body: body)
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
    
    private func schedule(body: String) async {
        clearPendingNudges()
        
        let content = UNMutableNotificationContent()
        content.title = localizedAppString("app.menu.title", defaultValue: "NudgeWhip")
        content.body = body
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
    
    func show(style: AlertVisualStyle, message: String?) {
        let frames = screenFramesProvider()
        guard !frames.isEmpty else { return }
        
        var nextPanelsByFrameKey: [String: NSPanel] = [:]
        for frame in frames {
            let key = Self.frameKey(for: frame)
            let panel = panelsByFrameKey[key] ?? panelFactory(frame)
            panel.setFrame(frame, display: false)
            panel.contentView = NSHostingView(rootView: AlertOverlayView(style: style, message: message))
            panel.orderFrontRegardless()
            nextPanelsByFrameKey[key] = panel
        }
        
        let staleKeys = Set(panelsByFrameKey.keys).subtracting(nextPanelsByFrameKey.keys)
        for staleKey in staleKeys {
            panelsByFrameKey[staleKey]?.close()
        }
        
        panelsByFrameKey = nextPanelsByFrameKey
    }
    
    func hide() {
        for panel in panelsByFrameKey.values {
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
    let message: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @State private var isActive = false
    @State private var showCenterMessage = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if style == .strongVisualNudge {
                    Color.black.opacity(isActive ? visualConfiguration.backdropActiveOpacity : visualConfiguration.backdropIdleOpacity)
                        .ignoresSafeArea()
                }

                Rectangle()
                    .strokeBorder(
                        borderColor.opacity(isActive ? visualConfiguration.activeOpacity : visualConfiguration.idleOpacity),
                        style: StrokeStyle(lineWidth: visualConfiguration.borderWidth, dash: visualConfiguration.dashPattern)
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .padding(style == .strongVisualNudge ? 0 : 6)
                    .shadow(
                        color: borderColor.opacity(isActive ? visualConfiguration.shadowOpacity : 0.08),
                        radius: visualConfiguration.shadowRadius
                    )

                if style != .perimeterPulse {
                    centerMessageView
                }

                if visualConfiguration.showsStageBadge {
                    stageBadge
                }
            }
            .onAppear {
                if visualConfiguration.animatePulse {
                    withAnimation(animation.repeatForever(autoreverses: true)) {
                        isActive = true
                    }
                } else {
                    isActive = true
                }
                if style != .perimeterPulse {
                    if visualConfiguration.animatesMessageEntrance {
                        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                            showCenterMessage = true
                        }
                    } else {
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
            .background(messageSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(visualConfiguration.usesOpaqueSurface ? 0.34 : 0.12), lineWidth: 1)
            )
            .transition(
                visualConfiguration.animatesMessageEntrance
                ? .scale.combined(with: .opacity)
                : .opacity
            )
        }
    }

    private var stageBadge: some View {
        VStack {
            HStack {
                Text(stageBadgeText)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(visualConfiguration.usesOpaqueSurface ? Color.black.opacity(0.88) : Color.black.opacity(0.56))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(visualConfiguration.usesOpaqueSurface ? 0.34 : 0.14), lineWidth: 1)
                    )
                    .padding(.top, 16)
                    .padding(.leading, 16)
                Spacer()
            }
            Spacer()
        }
    }

    private var alertMessage: String {
        message ?? ""
    }

    private var stageBadgeText: String {
        switch style {
        case .perimeterPulse:
            return localizedAppString("alert.badge.perimeter", defaultValue: "Idle detected")
        case .gentleNudge:
            return localizedAppString("alert.badge.gentle", defaultValue: "Gentle nudge")
        case .strongVisualNudge:
            return localizedAppString("alert.badge.strong", defaultValue: "Strong alert")
        }
    }

    @ViewBuilder
    private var messageSurface: some View {
        if visualConfiguration.usesOpaqueSurface {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        }
    }

    private var visualConfiguration: AlertVisualConfiguration {
        alertVisualConfiguration(
            for: style,
            accessibility: AlertAccessibilityOptions(
                reduceMotion: reduceMotion,
                increaseContrast: colorSchemeContrast == .increased,
                differentiateWithoutColor: differentiateWithoutColor,
                reduceTransparency: reduceTransparency
            )
        )
    }

    private var borderColor: Color {
        switch style {
        case .perimeterPulse, .gentleNudge: .orange
        case .strongVisualNudge: .red
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
