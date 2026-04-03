import SwiftUI

struct NudgePreviewOverlay: View {
    let style: AlertVisualStyle
    var onComplete: () -> Void
    
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
                
                let duration: TimeInterval = style == .perimeterPulse ? 2.0 : 3.0
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    onComplete()
                }
            }
        }
        .background(Color.clear)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var centerMessageView: some View {
        if showCenterMessage {
            VStack(spacing: 12) {
                Image(systemName: style == .gentleNudge ? "hand.wave.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 80, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)

                Text(alertMessage)
                    .font(.system(size: 32).bold())
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .multilineTextAlignment(.center)
            }
            .padding(40)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
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
        case .perimeterPulse, .gentleNudge: return .orange
        case .strongVisualNudge: return .red
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .perimeterPulse: return 12
        case .gentleNudge: return 14
        case .strongVisualNudge: return 18
        }
    }

    private var activeOpacity: Double {
        switch style {
        case .perimeterPulse: return 0.92
        case .gentleNudge: return 0.95
        case .strongVisualNudge: return 0.98
        }
    }

    private var idleOpacity: Double {
        switch style {
        case .perimeterPulse: return 0.18
        case .gentleNudge: return 0.22
        case .strongVisualNudge: return 0.28
        }
    }

    private var shadowOpacity: Double {
        switch style {
        case .perimeterPulse: return 0.45
        case .gentleNudge: return 0.55
        case .strongVisualNudge: return 0.65
        }
    }

    private var shadowRadius: CGFloat {
        switch style {
        case .perimeterPulse: return 14
        case .gentleNudge: return 18
        case .strongVisualNudge: return 24
        }
    }

    private var animation: Animation {
        switch style {
        case .perimeterPulse: return .easeInOut(duration: 0.85)
        case .gentleNudge: return .easeInOut(duration: 0.7)
        case .strongVisualNudge: return .easeInOut(duration: 0.55)
        }
    }
}
