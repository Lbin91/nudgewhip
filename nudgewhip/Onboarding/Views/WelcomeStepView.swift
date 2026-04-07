import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            welcomeHero
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.welcome.section.trust", defaultValue: "Privacy at a glance")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    trustRow(
                        text: localizedAppString(
                            "onboarding.welcome.bullet.keystrokes",
                            defaultValue: "NudgeWhip does not collect keystroke content."
                        )
                    )
                    trustRow(
                        text: localizedAppString(
                            "onboarding.welcome.bullet.screen",
                            defaultValue: "NudgeWhip does not collect screen contents or screenshots."
                        )
                    )
                }
            }
        }
    }

    private var welcomeHero: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(localizedAppString("onboarding.welcome.title", defaultValue: "The moment attention drifts, NudgeWhip brings you back"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(localizedAppString("onboarding.welcome.body", defaultValue: "A menu bar app that detects idle moments and gently brings you back to work."))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                Image("whip_devil")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84, height: 84)
                    .accessibilityLabel("Whip devil character")
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.16), lineWidth: 1)
        )
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
