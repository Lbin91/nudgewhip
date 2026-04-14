import SwiftUI

struct SchedulePresetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let preset: SchedulePreset?
    let onSave: (_ name: String, _ start: Int, _ end: Int, _ weekdayOnly: Bool) -> Void

    @State private var name: String = ""
    @State private var startTime: Date = Calendar.current.startOfDay(for: .now).addingTimeInterval(32_400)
    @State private var endTime: Date = Calendar.current.startOfDay(for: .now).addingTimeInterval(61_200)
    @State private var isWeekdayOnly: Bool = false

    private var isEditingBuiltIn: Bool { preset?.isBuiltIn == true }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && secondsFromMidnight(for: startTime) != secondsFromMidnight(for: endTime) }

    var body: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s5) {
            Text(
                preset == nil
                    ? localizedAppString("preset.editor.title_new", defaultValue: "New Preset")
                    : localizedAppString("preset.editor.title_edit", defaultValue: "Edit Preset")
            )
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.nudgewhipTextPrimary)

            nameField
            timePickers
            weekdayToggle
            validationHint
            actionButtons
        }
        .padding(NudgeWhipSpacing.s5)
        .frame(width: 320)
        .onAppear {
            if let preset {
                name = preset.name
                startTime = dateFromSeconds(preset.startSecondsFromMidnight)
                endTime = dateFromSeconds(preset.endSecondsFromMidnight)
                isWeekdayOnly = preset.isWeekdayOnly
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s1) {
            Text(localizedAppString("preset.editor.name", defaultValue: "Name"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextSecondary)

            TextField(
                localizedAppString("preset.editor.name_placeholder", defaultValue: "Preset name"),
                text: $name
            )
            .textFieldStyle(.roundedBorder)
            .disabled(isEditingBuiltIn)
        }
    }

    private var timePickers: some View {
        VStack(alignment: .leading, spacing: NudgeWhipSpacing.s2) {
            HStack {
                Text(localizedAppString("preset.editor.start", defaultValue: "Start"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .disabled(isEditingBuiltIn)
            }

            HStack {
                Text(localizedAppString("preset.editor.end", defaultValue: "End"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.nudgewhipTextSecondary)
                Spacer()
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .disabled(isEditingBuiltIn)
            }
        }
    }

    private var weekdayToggle: some View {
        Toggle(
            localizedAppString("preset.editor.weekdays_only", defaultValue: "Weekdays only"),
            isOn: $isWeekdayOnly
        )
        .font(.subheadline)
        .disabled(isEditingBuiltIn)
    }

    @ViewBuilder
    private var validationHint: some View {
        if !name.trimmingCharacters(in: .whitespaces).isEmpty && !isValid {
            Text(localizedAppString("preset.editor.error_same_time", defaultValue: "Start and end times must differ"))
                .font(.caption)
                .foregroundStyle(Color.nudgewhipAlert)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button(localizedAppString("preset.editor.cancel", defaultValue: "Cancel")) {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button(localizedAppString("preset.editor.save", defaultValue: "Save")) {
                onSave(
                    name.trimmingCharacters(in: .whitespaces),
                    secondsFromMidnight(for: startTime),
                    secondsFromMidnight(for: endTime),
                    isWeekdayOnly
                )
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!isValid)
        }
    }

    private func secondsFromMidnight(for date: Date) -> Int {
        let calendar = Calendar.current
        return calendar.component(.hour, from: date) * 3600
            + calendar.component(.minute, from: date) * 60
    }

    private func dateFromSeconds(_ seconds: Int) -> Date {
        Calendar.current.startOfDay(for: .now).addingTimeInterval(TimeInterval(seconds))
    }
}
