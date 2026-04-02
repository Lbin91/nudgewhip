import SwiftUI

struct PermissionStepView: View {
    let permissionState: AccessibilityPermissionState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PermissionStateBadge(permissionState: permissionState)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(localizedAppString(
                        "onboarding.permission.body.reason",
                        defaultValue: "Nudge uses this permission only to detect global input activity, identify idle moments, and show local nudges."
                    ))
                    
                    Divider()
                    
                    Text(localizedAppString(
                        "onboarding.permission.body.privacy",
                        defaultValue: "Nudge does not collect keystroke content, screen contents, files, messages, or browsing history."
                    ))
                    .foregroundStyle(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Label(localizedAppString(
                "onboarding.permission.body.limited",
                defaultValue: "If you do not allow it now, the app can still continue in limited mode."
            ), systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
