import AppKit
import SwiftUI

@MainActor
protocol AlertManaging: AnyObject {
    func handle(snapshot: RuntimeSnapshot)
}

@MainActor
protocol AlertPresenting: AnyObject {
    func showPerimeterPulse()
    func hidePerimeterPulse()
}

@MainActor
final class AlertManager: AlertManaging {
    private let presenter: AlertPresenting
    private(set) var isPerimeterPulseVisible = false
    
    init(presenter: AlertPresenting? = nil) {
        self.presenter = presenter ?? PerimeterPulsePresenter()
    }
    
    func handle(snapshot: RuntimeSnapshot) {
        if shouldShowPerimeterPulse(for: snapshot) {
            guard !isPerimeterPulseVisible else { return }
            presenter.showPerimeterPulse()
            isPerimeterPulseVisible = true
        } else if isPerimeterPulseVisible {
            presenter.hidePerimeterPulse()
            isPerimeterPulseVisible = false
        }
    }
    
    private func shouldShowPerimeterPulse(for snapshot: RuntimeSnapshot) -> Bool {
        guard snapshot.runtimeState == .alerting else { return false }
        
        switch snapshot.contentState {
        case .idleDetected, .gentleNudge, .strongNudge:
            return true
        case .focus, .recovery, .break, .remoteEscalation:
            return false
        }
    }
}

@MainActor
final class PerimeterPulsePresenter: AlertPresenting {
    private var panel: NSPanel?
    
    func showPerimeterPulse() {
        guard panel == nil, let screen = NSScreen.main else { return }
        
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
        panel.contentView = NSHostingView(rootView: PerimeterPulseView())
        panel.orderFrontRegardless()
        
        self.panel = panel
    }
    
    func hidePerimeterPulse() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
    }
}

private struct PerimeterPulseView: View {
    @State private var isActive = false
    
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .strokeBorder(Color.orange.opacity(isActive ? 0.92 : 0.18), lineWidth: 12)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .padding(6)
                .shadow(color: .orange.opacity(isActive ? 0.45 : 0.08), radius: 14)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                        isActive = true
                    }
                }
        }
        .background(Color.clear)
    }
}
