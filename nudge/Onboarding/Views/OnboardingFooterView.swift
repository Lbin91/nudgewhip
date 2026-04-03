import SwiftUI

struct OnboardingFooterView: View {
    let primaryTitle: String
    let primaryAction: () -> Void
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    let tertiaryTitle: String?
    let tertiaryAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.bottom, 4)
            
            Button(primaryTitle, action: primaryAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            
            if let secondaryTitle, let secondaryAction {
                Button(secondaryTitle, action: secondaryAction)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            
            if let tertiaryTitle, let tertiaryAction {
                Button(tertiaryTitle, action: tertiaryAction)
                    .buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }
}
