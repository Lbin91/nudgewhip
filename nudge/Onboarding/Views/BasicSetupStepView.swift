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
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedAppString("onboarding.setup.idle_threshold.label", defaultValue: "Idle threshold"))
                    .font(.headline)
                Picker("", selection: $idleThresholdSeconds) {
                    Text(localizedAppString("onboarding.setup.idle_threshold.3m", defaultValue: "3 min")).tag(180)
                    Text(localizedAppString("onboarding.setup.idle_threshold.5m", defaultValue: "5 min (Recommended)")).tag(300)
                    Text(localizedAppString("onboarding.setup.idle_threshold.10m", defaultValue: "10 min")).tag(600)
                }
                .pickerStyle(.segmented)
            }
            
            Toggle(localizedAppString("onboarding.setup.launch_at_login.label", defaultValue: "Launch at login"), isOn: $launchAtLoginEnabled)
            Toggle(localizedAppString("onboarding.setup.tts.label", defaultValue: "Use voice nudges"), isOn: $ttsEnabled)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedAppString("onboarding.setup.visual_mode.label", defaultValue: "Visual mode"))
                    .font(.headline)
                Picker("", selection: $petPresentationMode) {
                    Text(localizedAppString("onboarding.setup.visual_mode.sprout", defaultValue: "Sprout")).tag(PetPresentationMode.sprout)
                    Text(localizedAppString("onboarding.setup.visual_mode.minimal", defaultValue: "Minimal")).tag(PetPresentationMode.minimal)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}
