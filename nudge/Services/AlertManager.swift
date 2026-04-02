import AppKit
import SwiftUI

enum AlertVisualStyle: Equatable, Sendable {
    case perimeterPulse
    case strongVisualNudge
}

@MainActor
protocol AlertManaging: AnyObject {
    func handle(snapshot: RuntimeSnapshot)
}

@MainActor
protocol AlertPresenting: AnyObject {
    func show(style: AlertVisualStyle)
    func hide()
}

@MainActor
final class AlertManager: AlertManaging {
    private let presenter: AlertPresenting
    private(set) var activeStyle: AlertVisualStyle?
    
    init(presenter: AlertPresenting? = nil) {
        self.presenter = presenter ?? PerimeterPulsePresenter()
    }
    
    func handle(snapshot: RuntimeSnapshot) {
        guard let nextStyle = visualStyle(for: snapshot) else {
            guard activeStyle != nil else { return }
            presenter.hide()
            activeStyle = nil
            return
        }
        
        guard activeStyle != nextStyle else { return }
        presenter.show(style: nextStyle)
        activeStyle = nextStyle
    }
    
    private func visualStyle(for snapshot: RuntimeSnapshot) -> AlertVisualStyle? {
        guard snapshot.runtimeState == .alerting else { return nil }
        
        switch snapshot.contentState {
        case .idleDetected, .gentleNudge:
            return .perimeterPulse
        case .strongNudge:
            return .strongVisualNudge
        case .focus, .recovery, .break, .remoteEscalation:
            return nil
        }
    }
}

@MainActor
final class PerimeterPulsePresenter: AlertPresenting {
    private var panel: NSPanel?
    
    func show(style: AlertVisualStyle) {
        guard let screen = NSScreen.main else { return }
        
        let panel = panel ?? makePanel(for: screen)
        panel.contentView = NSHostingView(rootView: AlertOverlayView(style: style))
        panel.orderFrontRegardless()
        self.panel = panel
    }
    
    func hide() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }
    
    private func makePanel(for screen: NSScreen) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
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
}

private struct AlertOverlayView: View {
    let style: AlertVisualStyle
    @State private var isActive = false
    
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
                    .padding(style == .perimeterPulse ? 6 : 0)
                    .shadow(color: borderColor.opacity(isActive ? shadowOpacity : 0.08), radius: shadowRadius)
            }
            .onAppear {
                withAnimation(animation.repeatForever(autoreverses: true)) {
                    isActive = true
                }
            }
        }
        .background(Color.clear)
    }
    
    private var borderColor: Color {
        style == .perimeterPulse ? .orange : .red
    }
    
    private var borderWidth: CGFloat {
        style == .perimeterPulse ? 12 : 18
    }
    
    private var activeOpacity: Double {
        style == .perimeterPulse ? 0.92 : 0.98
    }
    
    private var idleOpacity: Double {
        style == .perimeterPulse ? 0.18 : 0.28
    }
    
    private var shadowOpacity: Double {
        style == .perimeterPulse ? 0.45 : 0.65
    }
    
    private var shadowRadius: CGFloat {
        style == .perimeterPulse ? 14 : 24
    }
    
    private var animation: Animation {
        style == .perimeterPulse ? .easeInOut(duration: 0.85) : .easeInOut(duration: 0.55)
    }
}
