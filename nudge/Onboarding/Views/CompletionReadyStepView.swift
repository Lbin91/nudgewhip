import SwiftUI

struct CompletionReadyStepView: View {
    let idleThresholdText: String
    let launchAtLoginText: String
    let ttsText: String
    let visualModeText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label(localizedAppString("onboarding.completion.ready.title", defaultValue: "Nudge is ready to monitor"), systemImage: "checkmark.circle.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.green)
                    
                    Text(localizedAppString("onboarding.completion.ready.body", defaultValue: "You can now check status and countdown from the menu bar."))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent(localizedAppString("onboarding.completion.ready.summary.idle_threshold", defaultValue: "Idle threshold"), value: idleThresholdText)
                        LabeledContent(localizedAppString("onboarding.completion.ready.summary.launch_at_login", defaultValue: "Launch at login"), value: launchAtLoginText)
                        LabeledContent(localizedAppString("onboarding.completion.ready.summary.tts", defaultValue: "Voice nudges"), value: ttsText)
                        LabeledContent(localizedAppString("onboarding.completion.ready.summary.visual_mode", defaultValue: "Visual mode"), value: visualModeText)
                    }
                }
            }
        }
    }
}
