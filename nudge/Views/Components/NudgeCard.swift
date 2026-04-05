import SwiftUI

struct NudgeCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(NudgeSpacing.s4)
            .background(Color.nudgeBgSurface)
            .clipShape(RoundedRectangle(cornerRadius: NudgeRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeRadius.card)
                    .stroke(Color.nudgeStrokeDefault, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

extension View {
    func nudgeCard() -> some View {
        modifier(NudgeCard())
    }
}
