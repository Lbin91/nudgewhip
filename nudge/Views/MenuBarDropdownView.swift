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
            utilityActions
        }
        .padding(NudgeSpacing.s3)
        .frame(width: NudgeLayout.popoverWidth)
    }

    // CRITICAL NON-REGRESSION:
    // Pause actions MUST remain plain buttons inside the window-style popover.
    // Do NOT wrap these actions in a nested SwiftUI `Menu` or move them back to
    // default NSMenu tracking. That exact path repeatedly caused hover invalidation,
    // submenu dismissal, and broken pause entry from the menu bar popover.
    private var pauseControls: some View {
        VStack(alignment: .leading, spacing: NudgeSpacing.s3) {
            Text(localizedAppString("menu.action.pause", defaultValue: "Pause NudgeWhip"))
                .font(.caption)
                .foregroundStyle(Color.nudgeTextMuted)
                .textCase(.uppercase)

            if menuBarViewModel.isManualPauseActive {
                filledActionButton(
                    title: localizedAppString("menu.action.pause.resume", defaultValue: "Resume NudgeWhip"),
                    tint: .nudgeFocus,
                    action: { menuBarViewModel.resumeFromManualPause() }
                )
            } else {
                filledActionButton(
                    title: localizedAppString("menu.action.pause.until_resumed", defaultValue: "Until resumed"),
                    tint: .nudgeAlert,
                    action: { menuBarViewModel.pauseUntilResumed() }
                )

                HStack(spacing: NudgeSpacing.s2) {
                    compactPauseButton(
                        title: localizedAppString("menu.action.pause.10m", defaultValue: "10 min"),
                        action: { menuBarViewModel.pauseForMinutes(10) }
                    )
                    compactPauseButton(
                        title: localizedAppString("menu.action.pause.30m", defaultValue: "30 min"),
                        action: { menuBarViewModel.pauseForMinutes(30) }
                    )
                    compactPauseButton(
                        title: localizedAppString("menu.action.pause.60m", defaultValue: "60 min"),
                        action: { menuBarViewModel.pauseForMinutes(60) }
                    )
                }
            }
        }
        .nudgeCard()
    }

    private var utilityActions: some View {
        VStack(spacing: NudgeSpacing.s2) {
            filledActionButton(
                title: localizedAppString("menu.action.open_settings", defaultValue: "Settings"),
                tint: .nudgeBgSurfaceAlt,
                foreground: .nudgeTextPrimary,
                action: onOpenSettings
            )

            filledActionButton(
                title: localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide"),
                tint: .nudgeBgSurfaceAlt,
                foreground: .nudgeTextPrimary,
                action: onOpenOnboarding
            )

            filledActionButton(
                title: localizedAppString("app.menu.action.quit", defaultValue: "Quit"),
                tint: .nudgeBgSurfaceAlt,
                foreground: .nudgeTextPrimary,
                action: onQuit
            )
        }
    }

    private func compactPauseButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(Color.nudgeBgSurfaceAlt, in: RoundedRectangle(cornerRadius: NudgeRadius.button))
        .foregroundStyle(Color.nudgeTextPrimary)
    }

    private func filledActionButton(
        title: String,
        tint: Color,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .background(tint, in: RoundedRectangle(cornerRadius: NudgeRadius.button))
        .foregroundStyle(foreground)
    }
}
