import SwiftUI

struct CompletionLimitedStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeroView(
                systemImage: "hand.raised.slash.fill",
                accentColor: .orange,
                title: localizedAppString("onboarding.completion.limited.title", defaultValue: "Starting in limited mode"),
                message: localizedAppString("onboarding.completion.limited.subtitle", defaultValue: "You can continue now and grant permission later.")
            )
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.completion.limited.section.limitations", defaultValue: "What this limits")
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString("onboarding.completion.limited.body.primary", defaultValue: "Without Accessibility permission, NudgeWhip cannot detect global background input activity."))
                    Text(localizedAppString("onboarding.completion.limited.body.secondary", defaultValue: "That means idle detection and the automatic return loop will not work fully."))
                        .foregroundStyle(.secondary)
                    Text(localizedAppString("onboarding.completion.limited.body.tertiary", defaultValue: "You can allow the permission later from the menu or in Settings."))
                        .foregroundStyle(.secondary)
                }
            }

            OnboardingSectionCard(
                title: localizedAppString("onboarding.completion.limited.section.available", defaultValue: "What still works")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    completionBullet(localizedAppString("onboarding.completion.limited.available.menu", defaultValue: "The menu bar app still opens, shows status, and keeps your saved defaults."))
                    completionBullet(localizedAppString("onboarding.completion.limited.available.recovery", defaultValue: "You can reopen setup or go straight to System Settings any time to finish permission recovery."))
                }
            }

            OnboardingSectionCard(
                title: localizedAppString("onboarding.completion.limited.section.recovery", defaultValue: "Best next step")
            ) {
                Text(localizedAppString("onboarding.completion.limited.recovery.note", defaultValue: "If you allow Accessibility and come back, this screen will switch to the ready state automatically."))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func completionBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
                .padding(.top, 4)
            Text(text)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
