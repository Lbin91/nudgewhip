import SwiftUI

struct OnboardingHeaderView: View {
    let title: String
    let subtitle: String
    let progressText: String
    let showsBackButton: Bool
    let backAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if showsBackButton {
                    Button(action: backAction) {
                        Label(localizedAppString("onboarding.common.back", defaultValue: "Back"), systemImage: "chevron.left")
                    }
                    .buttonStyle(.link)
                } else {
                    Text(localizedAppString("app.menu.title", defaultValue: "Nudge"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.secondary.opacity(0.12), in: Capsule())
            }
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
