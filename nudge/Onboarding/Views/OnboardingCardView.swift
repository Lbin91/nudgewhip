import SwiftUI

struct OnboardingCardView<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            content
        }
        .padding(28)
        .frame(maxWidth: 520, alignment: .leading)
        .background(
            Color(nsColor: .windowBackgroundColor),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.black.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 24, y: 14)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
}
