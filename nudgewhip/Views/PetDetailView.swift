import SwiftUI

struct PetDetailView: View {
    let petState: PetState
    let onReset: () -> Void

    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showResetConfirmation = false

    private let columns = [
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2),
        GridItem(.flexible(), spacing: NudgeWhipSpacing.s2)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            headerSection
            xpProgressSection
            growthTimelineSection
            statsGridSection
            resetSection
        }
    }

    private var headerSection: some View {
        HStack(spacing: NudgeWhipSpacing.s3) {
            Image(systemName: petState.currentStage.iconName)
                .font(.system(size: 40))
                .foregroundStyle(Color.nudgewhipFocus)
                .frame(width: 56, height: 56)
                .background(Color.nudgewhipFocus.opacity(0.1), in: Circle())

            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
                if isEditingName {
                    TextField(
                        localizedAppString("pet.detail.name_placeholder", defaultValue: "Pet name"),
                        text: $editedName
                    )
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextPrimary)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        commitNameEdit()
                    }
                } else {
                    Text(petState.name)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextPrimary)
                        .onTapGesture {
                            editedName = petState.name
                            isEditingName = true
                        }
                }

                Text(petState.currentStage.displayName)
                    .font(.subheadline)
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }
        }
    }

    private var xpProgressSection: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            if let nextStage = petState.currentStage.nextStage,
               let xpRemaining = petState.xpToNextStage {
                Text(
                    localizedAppString(
                        "pet.detail.next_stage",
                        defaultValue: "Next: \(nextStage.displayName) (\(xpRemaining) XP)"
                    )
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextSecondary)
            } else {
                Text(localizedAppString("pet.detail.max_stage", defaultValue: "Maximum stage reached"))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.nudgewhipAccent)
            }

            ProgressView(value: petState.progressToNextStage)
                .tint(Color.nudgewhipFocus)

            Text("\(petState.experiencePoints) XP")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextMuted)
        }
        .padding(NudgeWhipSpacing.s4)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default, style: .continuous))
    }

    private var growthTimelineSection: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("pet.detail.growth_timeline", defaultValue: "Growth Timeline"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            ForEach(PetGrowthStage.allCases, id: \.self) { stage in
                growthTimelineRow(stage: stage)
            }
        }
    }

    private func growthTimelineRow(stage: PetGrowthStage) -> some View {
        let isCurrent = stage == petState.currentStage
        let isUnlocked = petState.experiencePoints >= stage.xpThreshold
        let nextThreshold = stage.nextStage?.xpThreshold ?? stage.xpThreshold

        return HStack(spacing: NudgeWhipSpacing.s3) {
            Image(systemName: stage.iconName)
                .font(.subheadline.weight(isUnlocked ? .bold : .regular))
                .foregroundStyle(isUnlocked ? Color.nudgewhipFocus : Color.nudgewhipTextMuted)
                .frame(width: 20)

            Text(stage.displayName)
                .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(isUnlocked ? Color.nudgewhipTextPrimary : Color.nudgewhipTextMuted)

            Spacer()

            if stage == .elder {
                Text("\(stage.xpThreshold)+")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.nudgewhipTextMuted)
            } else {
                Text("\(stage.xpThreshold)–\(nextThreshold)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }

            if isCurrent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipFocus)
            } else if isUnlocked {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipFocus)
            }
        }
        .padding(.vertical, NudgeWhipSpacing.s1)
    }

    private var statsGridSection: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("pet.detail.stats", defaultValue: "Stats"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            LazyVGrid(columns: columns, spacing: NudgeWhipSpacing.s2) {
                statCard(
                    value: "\(petState.totalRecoveryContributions)",
                    label: localizedAppString("pet.detail.stat.recoveries", defaultValue: "Total Recoveries")
                )
                statCard(
                    value: "\(petState.companionDayCount)",
                    label: localizedAppString("pet.detail.stat.active_days", defaultValue: "Active Days")
                )
                statCard(
                    value: companionSinceText,
                    label: localizedAppString("pet.detail.stat.companion_since", defaultValue: "Companion Since")
                )
                statCard(
                    value: "\(petState.experiencePoints)",
                    label: localizedAppString("pet.detail.stat.total_xp", defaultValue: "Total XP")
                )
            }
        }
    }

    private var resetSection: some View {
        Button {
            showResetConfirmation = true
        } label: {
            HStack(spacing: NudgeWhipSpacing.s2) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                Text(localizedAppString("pet.detail.reset", defaultValue: "Reset Pet"))
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.nudgewhipAlert)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NudgeWhipSpacing.s3)
            .background(Color.nudgewhipAlert.opacity(0.08), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button))
        }
        .buttonStyle(.plain)
        .alert(
            localizedAppString("pet.detail.reset_confirm.title", defaultValue: "Reset Pet?"),
            isPresented: $showResetConfirmation
        ) {
            Button(
                localizedAppString("pet.detail.reset_confirm.cancel", defaultValue: "Cancel"),
                role: .cancel
            ) {}
            Button(
                localizedAppString("pet.detail.reset_confirm.confirm", defaultValue: "Reset"),
                role: .destructive
            ) {
                onReset()
            }
        } message: {
            Text(localizedAppString(
                "pet.detail.reset_confirm.message",
                defaultValue: "This will reset all pet progress. This cannot be undone."
            ))
        }
    }

    private var companionSinceText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: petState.companionStartDate)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .lineLimit(2)

            Text(value)
                .font(.headline.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NudgeWhipSpacing.s3)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.default, style: .continuous))
    }

    private func commitNameEdit() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            petState.name = trimmed
            petState.updatedAt = .now
        }
        isEditingName = false
    }
}
