import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    let onOpenSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s4) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)
            pauseControls
            DailySummaryView(
                todayStats: menuBarViewModel.todayStats,
                whitelistCount: menuBarViewModel.whitelistCount
            )
            utilityActions
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // CRITICAL NON-REGRESSION:
    // Pause actions MUST remain plain buttons inside the window-style popover.
    // Do NOT wrap these actions in a nested SwiftUI `Menu` or move them back to
    // default NSMenu tracking. That exact path repeatedly caused hover invalidation,
    // submenu dismissal, and broken pause entry from the menu bar popover.
    private var pauseControls: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s3) {
            sectionEyebrow(localizedAppString("menu.action.pause", defaultValue: "Pause NudgeWhip"))

            HStack(spacing: NudgeSpacing.s2) {
                if menuBarViewModel.isManualPauseActive {
                    primaryActionButton(
                        title: localizedAppString("menu.action.pause.resume", defaultValue: "Resume NudgeWhip"),
                        systemImage: "play.fill",
                        tint: .nudgeFocus,
                        action: { menuBarViewModel.resumeFromManualPause() }
                    )
                } else {
                    compactPauseButton(
                        title: "",
                        systemImage: "pause.fill",
                        action: { menuBarViewModel.pauseUntilResumed() }
                    )
                    compactPauseButton(
                        title: "10m",
                        action: { menuBarViewModel.pauseForMinutes(10) }
                    )
                    compactPauseButton(
                        title: "30m",
                        action: { menuBarViewModel.pauseForMinutes(30) }
                    )
                    compactPauseButton(
                        title: "60m",
                        action: { menuBarViewModel.pauseForMinutes(60) }
                    )
                }
            }
        }
        .padding(NudgeSpacing.s4)
        .background(
            Color.nudgeBgSurface,
            in: RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NudgeRadius.card, style: .continuous)
                .stroke(Color.nudgeStrokeStrong.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }

    private var utilityActions: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s2) {
            VStack(alignment: .leading, spacing: 0) {
                utilityRowButton(
                    title: localizedAppString("menu.action.open_settings", defaultValue: "Settings"),
                    systemImage: "gearshape",
                    action: onOpenSettings
                )

                Divider()
                    .overlay(Color.nudgeStrokeDefault)

                utilityRowButton(
                    title: localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide"),
                    systemImage: "questionmark.circle",
                    action: onOpenOnboarding
                )

                Divider()
                    .overlay(Color.nudgeStrokeDefault)

                utilityRowButton(
                    title: localizedAppString("app.menu.action.quit", defaultValue: "Quit"),
                    systemImage: "power",
                    action: onQuit
                )
            }
            .background(Color.nudgeBgSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: NudgeRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeRadius.card)
                    .stroke(Color.nudgeStrokeDefault, lineWidth: 1)
            )
        }
    }

    private func compactPauseButton(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeSpacing.s1) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.bold))
                }
                if !title.isEmpty {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
        }
        .buttonStyle(.plain)
        .background(
            Color.nudgeBgSurfaceAlt,
            in: RoundedRectangle(cornerRadius: NudgeRadius.button, style: .continuous)
        )
        .foregroundStyle(Color.nudgeTextPrimary)
    }

    private func primaryActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeSpacing.s2) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))

                Text(title)
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, NudgeSpacing.s4)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .background(tint, in: RoundedRectangle(cornerRadius: NudgeRadius.button, style: .continuous))
        .foregroundStyle(foreground)
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.nudgeTextMuted)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, NudgeSpacing.s1)
    }

    private func utilityRowButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeSpacing.s3) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgeTextSecondary)
                    .frame(width: 16)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.nudgeTextPrimary)

                Spacer(minLength: 0)

                if systemImage != "power" {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.nudgeTextMuted)
                }
            }
            .padding(.horizontal, NudgeSpacing.s4)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
