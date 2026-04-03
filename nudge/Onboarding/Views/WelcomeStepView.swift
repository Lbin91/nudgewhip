import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeroView(
                systemImage: "sparkles.rectangle.stack",
                accentColor: .accentColor,
                title: localizedAppString(
                    "onboarding.welcome.title",
                    defaultValue: "The moment attention drifts, Nudge brings you back"
                ),
                message: localizedAppString(
                    "onboarding.welcome.body",
                    defaultValue: "A menu bar app that detects idle moments and gently brings you back to work."
                )
            )
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.welcome.section.trust", defaultValue: "Privacy at a glance")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    trustRow(
                        text: localizedAppString(
                            "onboarding.welcome.bullet.keystrokes",
                            defaultValue: "Nudge does not collect keystroke content."
                        )
                    )
                    trustRow(
                        text: localizedAppString(
                            "onboarding.welcome.bullet.screen",
                            defaultValue: "Nudge does not collect screen contents or screenshots."
                        )
                    )
                }
            }
        }
    }
    
    private func trustRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
