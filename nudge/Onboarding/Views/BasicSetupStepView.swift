import SwiftUI

struct BasicSetupStepView: View {
    @Binding var idleThresholdSeconds: Int
    @Binding var launchAtLoginEnabled: Bool
    @Binding var ttsEnabled: Bool
    @Binding var petPresentationMode: PetPresentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(localizedAppString("onboarding.setup.body", defaultValue: "You can change these later in Settings."))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString("onboarding.setup.idle_threshold.label", defaultValue: "Idle threshold"))
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.10s", defaultValue: "10 sec (Test)"), value: 10)
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.3m", defaultValue: "3 min"), value: 180)
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.5m", defaultValue: "5 min (Recommended)"), value: 300)
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.10m", defaultValue: "10 min"), value: 600)
                    }
                    
                    Divider()
                    
                    Toggle(localizedAppString("onboarding.setup.launch_at_login.label", defaultValue: "Launch at login"), isOn: $launchAtLoginEnabled)
                }
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(localizedAppString("onboarding.setup.tts.label", defaultValue: "Use voice nudges"), isOn: $ttsEnabled)
                    
                    Divider()
                    
                    Text(localizedAppString("onboarding.setup.visual_mode.label", defaultValue: "Visual mode"))
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        modeButton(title: localizedAppString("onboarding.setup.visual_mode.sprout", defaultValue: "Sprout"), mode: .sprout)
                        modeButton(title: localizedAppString("onboarding.setup.visual_mode.minimal", defaultValue: "Minimal"), mode: .minimal)
                    }
                }
            }
        }
    }
    
    private func thresholdButton(title: String, value: Int) -> some View {
        Button {
            idleThresholdSeconds = value
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(idleThresholdSeconds == value ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(idleThresholdSeconds == value ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
    
    private func modeButton(title: String, mode: PetPresentationMode) -> some View {
        Button {
            petPresentationMode = mode
        } label: {
            Text(title)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(petPresentationMode == mode ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(petPresentationMode == mode ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
        )
    }
}
