import SwiftUI
import AppKit

struct NudgePreviewCard: View {
    @Binding var idleThresholdSeconds: Int
    @Binding var activePreviewStyle: AlertVisualStyle?
    @State private var previewSoundPlayer = AlertSoundPlayer()
    
    var body: some View {
        OnboardingSectionCard(
            title: localizedAppString("onboarding.preview.section_title", defaultValue: "Preview how nudges feel"),
            subtitle: nil
        ) {
            VStack(alignment: .leading, spacing: 16) {
                // Visual modes
                HStack(spacing: 8) {
                    previewButton(style: .perimeterPulse, title: localizedAppString("onboarding.preview.gentle.button", defaultValue: "Gentle\n(Step 1)"))
                    previewButton(style: .gentleNudge, title: localizedAppString("onboarding.preview.moderate.button", defaultValue: "Moderate\n(Step 2)"))
                    previewButton(style: .strongVisualNudge, title: localizedAppString("onboarding.preview.strong.button", defaultValue: "Strong\n(Step 3)"))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizedAppString("onboarding.preview.sound.title", defaultValue: "Compare sound themes"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        previewSoundButton(
                            title: localizedAppString("onboarding.preview.sound.whip.button", defaultValue: "Preview Whip!"),
                            theme: .whip
                        )
                        previewSoundButton(
                            title: localizedAppString("onboarding.preview.sound.normal.button", defaultValue: "Preview Light"),
                            theme: .normal
                        )
                    }
                }
                
                Divider()
                
                // Timeline
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("onboarding.preview.timeline.label", defaultValue: "Escalation timeline"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        timelineItem(
                            time: formatTime(0),
                            label: localizedAppString("onboarding.preview.timeline.idle", defaultValue: "Idle")
                        )
                        timelineArrow
                        timelineItem(time: formatTime(idleThresholdSeconds), label: localizedAppString("onboarding.preview.timeline.step1", defaultValue: "Step 1"))
                        timelineArrow
                        timelineItem(time: formatTime(idleThresholdSeconds + 30), label: localizedAppString("onboarding.preview.timeline.step2", defaultValue: "Step 2"))
                        timelineArrow
                        timelineItem(time: formatTime(idleThresholdSeconds + 60), label: localizedAppString("onboarding.preview.timeline.step3", defaultValue: "Step 3"))
                    }
                }
            }
        }
        .onDisappear {
            previewSoundPlayer.stopAll()
        }
    }
    
    private var timelineArrow: some View {
        Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.secondary)
    }
    
    private func previewButton(style: AlertVisualStyle, title: String) -> some View {
        let isPlaying = activePreviewStyle == style
        return Button {
            startPreview(style)
        } label: {
            Text(title)
                .multilineTextAlignment(.center)
                .font(.system(size: 11, weight: isPlaying ? .semibold : .regular))
                .foregroundStyle(isPlaying ? .white : .primary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isPlaying ? Color.accentColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(isPlaying ? Color.accentColor : Color.secondary.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(activePreviewStyle != nil)
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
    }
    
    private func timelineItem(time: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(time).font(.caption.monospacedDigit()).bold()
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds < 60 {
            return localizedAppString(
                "onboarding.preview.time.seconds",
                defaultValue: "{seconds}s"
            ).replacingOccurrences(of: "{seconds}", with: String(seconds))
        } else if seconds % 60 == 0 {
            return localizedAppString(
                "onboarding.preview.time.minutes",
                defaultValue: "{minutes}m"
            ).replacingOccurrences(of: "{minutes}", with: String(seconds / 60))
        } else {
            return localizedAppString(
                "onboarding.preview.time.minutes_seconds",
                defaultValue: "{minutes}m {seconds}s"
            )
            .replacingOccurrences(of: "{minutes}", with: String(seconds / 60))
            .replacingOccurrences(of: "{seconds}", with: String(seconds % 60))
        }
    }
    
    private func startPreview(_ style: AlertVisualStyle) {
        activePreviewStyle = style
    }

    private func previewSoundButton(title: String, theme: SoundTheme) -> some View {
        Button {
            playPreviewSound(theme: theme)
        } label: {
            Label(title, systemImage: "play.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 36)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    Color.nudgeBgSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(activePreviewStyle != nil)
    }
    
    private func playPreviewSound(theme: SoundTheme) {
        previewSoundPlayer.stopAll()
        let runtimePlan = alertSoundPlan(for: .strongVisualNudge, theme: theme)
        let previewPlan = AlertSoundPlan(
            soundName: runtimePlan.soundName,
            repeatCount: 1,
            repeatInterval: 0
        )
        previewSoundPlayer.play(
            named: previewPlan.soundName,
            repeatCount: previewPlan.repeatCount,
            interval: previewPlan.repeatInterval
        )
    }
}
