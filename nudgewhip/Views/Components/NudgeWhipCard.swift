import SwiftUI

struct NudgeWhipCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(NudgeWhipSpacing.s4)
            .background(Color.nudgewhipBgSurface)
            .clipShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeWhipRadius.card)
                    .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func nudgewhipCard() -> some View {
        modifier(NudgeWhipCard())
    }
}
