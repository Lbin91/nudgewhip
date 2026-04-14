import SwiftUI

struct RecoveryTimelineView: View {
    let events: [RecoveryEvent]

    private var displayedEvents: [RecoveryEvent] {
        Array(events.prefix(50))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s3) {
            Text(localizedAppString("recovery.review.timeline.title", defaultValue: "Recovery timeline"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
                .textCase(.uppercase)

            if events.isEmpty {
                Text(localizedAppString("recovery.review.timeline.empty", defaultValue: "No recovery events recorded yet."))
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextMuted)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                        timelineRow(event: event)
                        if index < displayedEvents.count - 1 {
                            Divider()
                                .background(Color.nudgewhipStrokeDefault.opacity(0.4))
                        }
                    }
                }

                if events.count > 50 {
                    Text(localizedAppString(
                        "recovery.review.timeline.more",
                        defaultValue: "Showing 50 of \(events.count) events"
                    ))
                    .font(.caption2)
                    .foregroundStyle(Color.nudgewhipTextMuted)
                    .padding(.top, NudgeWhipSpacing.s2)
                }
            }
        }
        .padding(NudgeWhipSpacing.s4)
        .background(Color.nudgewhipBgSurfaceAlt.opacity(0.72), in: RoundedRectangle(cornerRadius: NudgeWhipRadius.card, style: .continuous))
    }

    private func timelineRow(event: RecoveryEvent) -> some View {
        HStack(spacing: NudgeWhipSpacing.s3) {
            Text(localizedClockString(event.alertStartedAt))
                .font(.caption.monospacedDigit().weight(.medium))
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .frame(width: 52, alignment: .leading)

            escalationBadge(step: event.escalationStep)

            if let duration = event.recoveryDuration {
                Text(formattedDuration(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.nudgewhipFocus)
            } else {
                Text(localizedAppString("recovery.review.timeline.not_recovered", defaultValue: "Not recovered"))
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.nudgewhipTextMuted)
        }
        .padding(.vertical, NudgeWhipSpacing.s2)
    }

    private func escalationBadge(step: Int) -> some View {
        let color: Color = switch step {
        case 1: Color.nudgewhipFocus.opacity(0.6)
        case 2: Color.nudgewhipFocus
        default: Color.nudgewhipAlert
        }

        return Text("\(step)")
            .font(.system(size: 10, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(color, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        localizedDurationString(duration)
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}
