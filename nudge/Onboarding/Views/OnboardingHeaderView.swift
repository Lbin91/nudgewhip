import SwiftUI

struct OnboardingHeaderView: View {
    let title: String
    let subtitle: String
    let progressText: String
    let showsBackButton: Bool
    let backAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                if showsBackButton {
                    Button(action: backAction) {
                        Label(localizedAppString("onboarding.common.back", defaultValue: "Back"), systemImage: "chevron.left")
                    }
                    .buttonStyle(.link)
                } else {
                    Text(localizedAppString("app.menu.title", defaultValue: "Nudge"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
                
                Spacer()
                
                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }
            
            Text(title)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
