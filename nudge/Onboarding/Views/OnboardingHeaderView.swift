import SwiftUI

struct OnboardingHeaderView: View {
    let title: String
    let subtitle: String
    let progressText: String
    let showsBackButton: Bool
    let backAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if showsBackButton {
                    Button(action: backAction) {
                        Label(localizedAppString("onboarding.common.back", defaultValue: "Back"), systemImage: "chevron.left")
                    }
                    .buttonStyle(.link)
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
                .font(.largeTitle.bold())
            
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
