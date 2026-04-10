import SwiftUI

struct NudgeWhipPreviewOverlay: View {
    let style: AlertVisualStyle
    var onComplete: () -> Void

    @State private var isActive = false
    @State private var showCenterMessage = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

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

                // "Preview" badge — runtime alert과 구분
                VStack {
                    HStack {
                        Spacer()
                        Text(String(localized: "preview.badge", defaultValue: "Preview"))
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(previewBadgeBackground, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(visualConfiguration.usesOpaqueSurface ? 0.34 : 0.14), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .padding(.top, 16)
                            .padding(.trailing, 16)
                    }
                    Spacer()
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
            .background(messageSurface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(visualConfiguration.usesOpaqueSurface ? 0.34 : 0.14), lineWidth: 1)
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
        switch style {
        case .perimeterPulse:
            return ""
        case .gentleNudge:
            return localizedAppString("alert.message.gentle_nudge", defaultValue: "Let's refocus 💡")
        case .strongVisualNudge:
            return localizedAppString("alert.message.strong_nudge", defaultValue: "Come back now! ⚡")
        }
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

    private var messageSurface: AnyShapeStyle {
        if visualConfiguration.usesOpaqueSurface {
            return AnyShapeStyle(Color.black.opacity(0.9))
        }
        return AnyShapeStyle(.ultraThinMaterial)
    }

    private var previewBadgeBackground: AnyShapeStyle {
        if visualConfiguration.usesOpaqueSurface {
            return AnyShapeStyle(Color.black.opacity(0.88))
        }
        return AnyShapeStyle(.ultraThinMaterial)
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
        case .perimeterPulse, .gentleNudge: return .orange
        case .strongVisualNudge: return .red
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
