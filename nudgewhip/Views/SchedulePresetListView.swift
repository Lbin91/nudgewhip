import SwiftUI
import SwiftData

struct SchedulePresetListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SchedulePreset.sortOrder) private var presets: [SchedulePreset]
    @State private var showingEditor = false
    @State private var presetToEdit: SchedulePreset?

    let onPresetActivated: (SchedulePreset) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s4) {
            sectionEyebrow(
                localizedAppString("preset.schedule.list_title", defaultValue: "Schedule Presets")
            )

            if presets.isEmpty {
                emptyState
            } else {
                presetList
            }

            addPresetButton
        }
        .sheet(isPresented: $showingEditor) {
            presetToEdit = nil
        } content: {
            SchedulePresetEditorView(
                preset: presetToEdit,
                onSave: { name, start, end, weekdayOnly in
                    handleEditorSave(name: name, start: start, end: end, weekdayOnly: weekdayOnly)
                }
            )
        }
    }

    private var emptyState: some View {
        Text(localizedAppString("preset.schedule.empty", defaultValue: "No presets yet. Add one below."))
            .font(.subheadline)
            .foregroundStyle(Color.nudgewhipTextSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, NudgeWhipSpacing.s6)
    }

    private var presetList: some View {
        VStack(spacing: 0) {
            ForEach(presets) { preset in
                presetRow(preset)
                if preset.id != presets.last?.id {
                    Divider().overlay(Color.nudgewhipStrokeDefault)
                }
            }
        }
        .background(Color.nudgewhipBgSurface)
        .clipShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.card))
        .overlay(
            RoundedRectangle(cornerRadius: NudgeWhipRadius.card)
                .stroke(Color.nudgewhipStrokeDefault, lineWidth: 1)
        )
    }

    private func presetRow(_ preset: SchedulePreset) -> some View {
        Button {
            onPresetActivated(preset)
        } label: {
            HStack(spacing: NudgeWhipSpacing.s3) {
                Image(systemName: preset.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipFocus)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
                    Text(preset.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.nudgewhipTextPrimary)

                    HStack(spacing: NudgeWhipSpacing.s1) {
                        Text("\(preset.startTimeFormatted) – \(preset.endTimeFormatted)")
                        if preset.isWeekdayOnly {
                            Text("·")
                            Text(localizedAppString("preset.schedule.weekdays_only", defaultValue: "Weekdays"))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                }

                Spacer(minLength: 0)

                if preset.isActivePreset {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.nudgewhipFocus)
                }

                if !preset.isBuiltIn {
                    Button {
                        presetToEdit = preset
                        showingEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(Color.nudgewhipTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, NudgeWhipSpacing.s4)
            .padding(.vertical, NudgeWhipSpacing.s3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addPresetButton: some View {
        Button {
            presetToEdit = nil
            showingEditor = true
        } label: {
            HStack(spacing: NudgeWhipSpacing.s2) {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.semibold))
                Text(localizedAppString("preset.schedule.add", defaultValue: "New Preset"))
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.nudgewhipFocus)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NudgeWhipSpacing.s3)
            .background(
                Color.nudgewhipBgSurfaceAlt,
                in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.nudgewhipTextMuted)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, NudgeWhipSpacing.s1)
    }

    private func handleEditorSave(name: String, start: Int, end: Int, weekdayOnly: Bool) {
        if let existing = presetToEdit {
            existing.name = name
            existing.startSecondsFromMidnight = start
            existing.endSecondsFromMidnight = end
            existing.isWeekdayOnly = weekdayOnly
            existing.updatedAt = .now
        } else {
            let newPreset = SchedulePreset(
                name: name,
                startSecondsFromMidnight: start,
                endSecondsFromMidnight: end,
                isWeekdayOnly: weekdayOnly,
                isBuiltIn: false,
                sortOrder: presets.count
            )
            if let context = presets.first?.modelContext {
                context.insert(newPreset)
            }
        }
        presetToEdit = nil
    }
}
