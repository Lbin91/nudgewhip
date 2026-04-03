import SwiftUI

struct PermissionStepView: View {
    let permissionState: AccessibilityPermissionState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingHeroView(
                systemImage: permissionState == .granted ? "checkmark.circle.fill" : "hand.raised.fill",
                accentColor: permissionState == .granted ? .green : .orange,
                title: PermissionStateBadge(permissionState: permissionState).titleText,
                message: localizedAppString(
                    "onboarding.permission.body.reason",
                    defaultValue: "Nudge uses this permission only to detect global input activity, identify idle moments, and show local nudges."
                )
            )
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.permission.section.reason", defaultValue: "Why Nudge needs this")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString(
                        "onboarding.permission.body.reason",
                        defaultValue: "Nudge uses this permission only to detect global input activity, identify idle moments, and show local nudges."
                    ))
                    .foregroundStyle(.primary)
                }
            }
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.permission.section.privacy", defaultValue: "What Nudge does not collect")
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(localizedAppString(
                        "onboarding.permission.body.privacy",
                        defaultValue: "Nudge does not collect keystroke content, screen contents, files, messages, or browsing history."
                    ))
                    .foregroundStyle(.primary)
                }
            }
            
            if permissionState == .granted {
                OnboardingSectionCard(
                    title: localizedAppString("onboarding.permission.section.granted", defaultValue: "You're ready for the next step")
                ) {
                    Text(localizedAppString(
                        "onboarding.permission.body.granted",
                        defaultValue: "Accessibility permission is already enabled. Continue to choose the defaults for your first sessions."
                    ))
                    .foregroundStyle(.primary)
                }
            } else {
                Label(localizedAppString(
                    "onboarding.permission.body.limited",
                    defaultValue: "If you do not allow it now, the app can still continue in limited mode."
                ), systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
    }
}
