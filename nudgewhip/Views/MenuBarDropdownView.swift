import SwiftUI

struct MenuBarDropdownView: View {
    let menuBarViewModel: MenuBarViewModel
    let onOpenStatistics: () -> Void
    let onOpenSettings: () -> Void
    let onOpenOnboarding: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            StatusSummaryView(menuBarViewModel: menuBarViewModel)
            if menuBarViewModel.shouldShowBreakSuggestion {
                breakSuggestionCard
            }
            pauseControls
            DailySummaryView(
                todayStats: menuBarViewModel.todayStats
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
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            sectionEyebrow(localizedAppString("menu.action.pause", defaultValue: "Pause NudgeWhip"))

            HStack(spacing: NudgeWhipSpacing.s2) {
                if menuBarViewModel.isManualPauseActive {
                    primaryActionButton(
                        title: localizedAppString("menu.action.pause.resume", defaultValue: "Resume NudgeWhip"),
                        systemImage: "play.fill",
                        tint: .nudgewhipFocus,
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
        .padding(NudgeWhipSpacing.s4)
        .background(
            Color.nudgewhipBgSurface,
            in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .stroke(Color.nudgewhipStrokeStrong.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }

    private var breakSuggestionCard: some View {
        HStack(alignment: .top, spacing: NudgeWhipSpacing.s3) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipAccent)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
                sectionEyebrow(localizedAppString("menu.break_suggestion.eyebrow", defaultValue: "Suggestion"))

                Text(menuBarViewModel.breakSuggestionTitleText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextPrimary)

                Text(menuBarViewModel.breakSuggestionBodyText)
                    .font(.footnote)
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: NudgeWhipSpacing.s2) {
                    compactPauseButton(
                        title: localizedAppString(
                            "menu.break_suggestion.action.more_idle_time",
                            defaultValue: "More idle time"
                        ),
                        action: { menuBarViewModel.relaxBreakSuggestionSensitivity() }
                    )
                    compactPauseButton(
                        title: localizedAppString(
                            "menu.break_suggestion.action.soften_alerts",
                            defaultValue: "Softer alerts"
                        ),
                        action: { menuBarViewModel.softenBreakSuggestionAlerts() }
                    )
                }

                Button {
                    menuBarViewModel.acknowledgeBreakSuggestion()
                    onOpenOnboarding()
                } label: {
                    Text(localizedAppString(
                        "menu.break_suggestion.action.open_guide",
                        defaultValue: "Open setup guide"
                    ))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipFocus)
                }
                .buttonStyle(.plain)

                Text(localizedAppString(
                    "menu.break_suggestion.note",
                    defaultValue: "These actions only tune alerts and do not start break mode."
                ))
                .font(.caption)
                .foregroundStyle(Color.nudgewhipTextMuted)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(NudgeWhipSpacing.s4)
        .background(
            Color.nudgewhipBgSurface,
            in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous)
                .stroke(Color.nudgewhipAccent.opacity(0.5), lineWidth: 1)
        )
    }

    private var utilityActions: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            VStack(alignment: .leading, spacing: 0) {
                utilityRowButton(
                    title: localizedAppString("settings.section.statistics", defaultValue: "Statistics"),
                    systemImage: "chart.bar.xaxis",
                    action: onOpenStatistics
                )

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault)

                utilityRowButton(
                    title: localizedAppString("menu.action.open_settings", defaultValue: "Settings"),
                    systemImage: "gearshape",
                    action: onOpenSettings
                )

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault)

                utilityRowButton(
                    title: localizedAppString("menu.action.open_onboarding", defaultValue: "Open setup guide"),
                    systemImage: "questionmark.circle",
                    action: onOpenOnboarding
                )

                Divider()
                    .overlay(Color.nudgewhipStrokeDefault)

                utilityRowButton(
                    title: localizedAppString("app.menu.action.quit", defaultValue: "Quit"),
                    systemImage: "power",
                    action: onQuit
                )
            }
            .background(Color.nudgewhipBgSurface.opacity(0.88), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: NudgeWhipRadius.card)
                    .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
            )
        }
    }

    private func compactPauseButton(
        title: String,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeWhipSpacing.s1) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.bold))
                }
                if !title.isEmpty {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Color.nudgewhipBgSurfaceAlt,
                in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.nudgewhipTextPrimary)
    }

    private func primaryActionButton(
        title: String,
        systemImage: String,
        tint: Color,
        foreground: Color = .white,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeWhipSpacing.s2) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))

                Text(title)
                    .font(.headline.weight(.semibold))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, NudgeWhipSpacing.s4)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(tint, in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.nudgewhipTextMuted)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, NudgeWhipSpacing.s1)
    }

    private func utilityRowButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NudgeWhipSpacing.s3) {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                    .frame(width: 16)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.nudgewhipTextPrimary)

                Spacer(minLength: 0)

                if systemImage != "power" {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.nudgewhipTextMuted)
                }
            }
            .padding(.horizontal, NudgeWhipSpacing.s4)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
