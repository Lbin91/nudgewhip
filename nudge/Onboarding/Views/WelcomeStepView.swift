import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label {
                Text(localizedAppString(
                    "onboarding.welcome.title",
                    defaultValue: "The moment attention drifts, Nudge brings you back"
                ))
                .font(.title3.weight(.semibold))
            } icon: {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }
            
            Text(localizedAppString(
                "onboarding.welcome.body",
                defaultValue: "A menu bar app that detects idle moments and gently brings you back to work."
            ))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 10) {
                    Label(localizedAppString("onboarding.welcome.bullet.keystrokes", defaultValue: "Nudge does not collect keystroke content."), systemImage: "checkmark.seal")
                    Label(localizedAppString("onboarding.welcome.bullet.screen", defaultValue: "Nudge does not collect screen contents or screenshots."), systemImage: "checkmark.seal")
                }
                .font(.body)
            }
        }
    }
}
