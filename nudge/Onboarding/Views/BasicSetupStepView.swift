import SwiftUI

struct BasicSetupStepView: View {
    @Binding var idleThresholdSeconds: Int
    @Binding var launchAtLoginEnabled: Bool
    @Binding var ttsEnabled: Bool
    @Binding var petPresentationMode: PetPresentationMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingSectionCard(
                title: localizedAppString("onboarding.setup.idle_threshold.label", defaultValue: "Idle threshold"),
                subtitle: localizedAppString("onboarding.setup.body", defaultValue: "You can change these later in Settings.")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        thresholdButton(
                            title: localizedAppString("onboarding.setup.idle_threshold.10s", defaultValue: "10 sec (Test)"),
                            subtitle: "테스트용",
                            value: 10
                        )
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.3m", defaultValue: "3 min"), subtitle: nil, value: 180)
                        thresholdButton(
                            title: localizedAppString("onboarding.setup.idle_threshold.5m", defaultValue: "5 min (Recommended)"),
                            subtitle: "기본 추천",
                            value: 300
                        )
                        thresholdButton(title: localizedAppString("onboarding.setup.idle_threshold.10m", defaultValue: "10 min"), subtitle: nil, value: 600)
                    }
                }
            }
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.setup.section.behavior", defaultValue: "How Nudge starts"),
                subtitle: localizedAppString("onboarding.setup.section.behavior.subtitle", defaultValue: "Choose whether Nudge opens automatically and whether voice nudges stay on.")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(localizedAppString("onboarding.setup.launch_at_login.label", defaultValue: "Launch at login"), isOn: $launchAtLoginEnabled)
                        .toggleStyle(.checkbox)
                    Toggle(localizedAppString("onboarding.setup.tts.label", defaultValue: "Use voice nudges"), isOn: $ttsEnabled)
                        .toggleStyle(.checkbox)
                }
            }
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.setup.visual_mode.label", defaultValue: "Visual mode"),
                subtitle: localizedAppString("onboarding.setup.visual_mode.subtitle", defaultValue: "Pick the presentation style that feels the least distracting.")
            ) {
                HStack(spacing: 10) {
                    modeButton(title: localizedAppString("onboarding.setup.visual_mode.sprout", defaultValue: "Sprout"), subtitle: "캐릭터와 함께", mode: .sprout)
                    modeButton(title: localizedAppString("onboarding.setup.visual_mode.minimal", defaultValue: "Minimal"), subtitle: "더 조용하게", mode: .minimal)
                }
            }
        }
    }
    
    private func thresholdButton(title: String, subtitle: String?, value: Int) -> some View {
        OnboardingSelectableCard(
            title: title,
            subtitle: subtitle,
            isSelected: idleThresholdSeconds == value
        ) {
            idleThresholdSeconds = value
        }
    }
    
    private func modeButton(title: String, subtitle: String?, mode: PetPresentationMode) -> some View {
        OnboardingSelectableCard(
            title: title,
            subtitle: subtitle,
            isSelected: petPresentationMode == mode
        ) {
            petPresentationMode = mode
        }
    }
}
