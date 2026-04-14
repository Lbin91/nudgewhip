import SwiftUI

struct PetSummaryCard: View {
    let petState: PetState
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: NudgeWhipSpacing.s3) {
                Image(systemName: petState.currentStage.iconName)
                    .font(.title3)
                    .foregroundStyle(Color.nudgewhipFocus)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(petState.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                    Text(
                        localizedAppString(
                            "pet.summary.subtitle",
                            defaultValue: "\(petState.currentStage.displayName) · \(petState.experiencePoints) XP"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextMuted)
                }

                Spacer()

                ProgressView(value: petState.progressToNextStage)
                    .frame(width: 40)
            }
            .padding(NudgeWhipSpacing.s3)
            .background(Color.nudgewhipBgSurfaceAlt.opacity(0.5), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default))
        }
        .buttonStyle(.plain)
    }
}
