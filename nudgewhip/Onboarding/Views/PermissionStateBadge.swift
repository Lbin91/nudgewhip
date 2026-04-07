import SwiftUI

struct PermissionStateBadge: View {
    let permissionState: AccessibilityPermissionState
    
    var body: some View {
        Label(titleText, systemImage: iconName)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.18), in: Capsule())
            .foregroundStyle(backgroundColor)
    }
    
    var titleText: String {
        switch permissionState {
        case .unknown:
            localizedAppString("onboarding.permission.state.unknown", defaultValue: "Not checked")
        case .granted:
            localizedAppString("onboarding.permission.state.granted", defaultValue: "Granted")
        case .denied:
            localizedAppString("onboarding.permission.state.denied", defaultValue: "Needed")
        }
    }
    
    private var iconName: String {
        switch permissionState {
        case .unknown:
            "questionmark.circle"
        case .granted:
            "checkmark.circle"
        case .denied:
            "hand.raised.slash"
        }
    }
    
    private var backgroundColor: Color {
        switch permissionState {
        case .unknown:
            .secondary
        case .granted:
            .green
        case .denied:
            .orange
        }
    }
}
