import SwiftUI

struct CompletionLimitedStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(localizedAppString("onboarding.completion.limited.title", defaultValue: "Starting in limited mode"), systemImage: "hand.raised.slash.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 10) {
                Text(localizedAppString("onboarding.completion.limited.body.primary", defaultValue: "Without Accessibility permission, Nudge cannot detect global background input activity."))
                Text(localizedAppString("onboarding.completion.limited.body.secondary", defaultValue: "That means idle detection and the automatic return loop will not work fully."))
                    .foregroundStyle(.secondary)
                Text(localizedAppString("onboarding.completion.limited.body.tertiary", defaultValue: "You can allow the permission later from the menu or in Settings."))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
