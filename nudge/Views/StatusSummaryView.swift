import SwiftUI

struct StatusSummaryView: View {
    let menuBarViewModel: MenuBarViewModel

    var body: some View {
        HStack(spacing: NudgeSpacing.s4) {
            AnimatedASCIICharacterView(
                hatchStage: menuBarViewModel.petHatchStage,
                character: menuBarViewModel.petCharacter,
                emotion: menuBarViewModel.petEmotion,
                animate: false
            )

            VStack(alignment: .leading, spacing: NudgeSpacing.s1) {
                Text(menuBarViewModel.petCharacterText)
                    .font(.headline)
                    .foregroundStyle(Color.nudgeTextPrimary)

                Text(localizedAppString("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"))
                    .font(.caption)
                    .foregroundStyle(Color.nudgeTextSecondary)

                Text(menuBarViewModel.idleThresholdText)
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Color.nudgeFocus)
            }

            Spacer(minLength: 0)
        }
        .padding(NudgeSpacing.s4)
        .nudgeCard()
    }
}
