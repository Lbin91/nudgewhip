import SwiftUI

struct CompletionReadyStepView: View {
    let idleThresholdText: String
    let scheduleText: String
    let launchAtLoginText: String
    let ttsText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeroView(
                systemImage: "checkmark.circle.fill",
                accentColor: .green,
                title: localizedAppString("onboarding.completion.ready.title", defaultValue: "Nudge is ready to monitor"),
                message: localizedAppString("onboarding.completion.ready.body", defaultValue: "You can now check status and countdown from the menu bar.")
            )
            
            OnboardingSectionCard(title: localizedAppString("onboarding.completion.ready.header", defaultValue: "Ready to go")) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        summaryRow(localizedAppString("onboarding.completion.ready.summary.idle_threshold", defaultValue: "Idle threshold"), idleThresholdText)
                        summaryRow(localizedAppString("onboarding.completion.ready.summary.schedule", defaultValue: "Schedule"), scheduleText)
                        summaryRow(localizedAppString("onboarding.completion.ready.summary.launch_at_login", defaultValue: "Launch at login"), launchAtLoginText)
                        summaryRow(localizedAppString("onboarding.completion.ready.summary.tts", defaultValue: "Voice nudges"), ttsText)
                    }
                }
            }
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.completion.ready.section.next", defaultValue: "What happens next")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    completionBullet(localizedAppString("onboarding.completion.ready.next.menu", defaultValue: "Check your status and countdown from the menu bar icon."))
                    completionBullet(localizedAppString("onboarding.completion.ready.next.settings", defaultValue: "You can reopen setup and change these defaults later from the menu."))
                }
            }
        }
    }
    
    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(.secondary)
            Text("-")
                .foregroundStyle(.tertiary)
            Text(value)
                .foregroundStyle(.primary)
        }
        .font(.body)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func completionBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.green)
                .padding(.top, 4)
            Text(text)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
