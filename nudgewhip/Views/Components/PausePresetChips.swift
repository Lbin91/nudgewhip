import SwiftUI

struct PausePresetChip: Identifiable {
    let id = UUID()
    let durationMinutes: Int?
    let label: String

    static let presets: [PausePresetChip] = [
        PausePresetChip(durationMinutes: 15, label: "15m"),
        PausePresetChip(durationMinutes: 30, label: "30m"),
        PausePresetChip(durationMinutes: 60, label: "1h"),
        PausePresetChip(durationMinutes: 120, label: "2h"),
        PausePresetChip(
            durationMinutes: nil,
            label: localizedAppString("preset.pause.custom", defaultValue: "Custom")
        )
    ]
}

struct PausePresetChips: View {
    let onSelect: (Int?) -> Void

    @State private var customMinutes: String = "30"
    @State private var showCustomSheet: Bool = false

    var body: some View {
        HStack(spacing: NudgeWhipSpacing.s2) {
            ForEach(PausePresetChip.presets) { chip in
                Button(chip.label) {
                    if let duration = chip.durationMinutes {
                        onSelect(duration)
                    } else {
                        showCustomSheet = true
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.nudgewhipTextPrimary)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Color.nudgewhipBgSurfaceAlt,
                    in: RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous)
                )
                .contentShape(RoundedRectangle(cornerRadius: NudgeWhipRadius.button, style: .continuous))
            }
        }
        .sheet(isPresented: $showCustomSheet) {
            customDurationSheet
        }
    }

    private var customDurationSheet: some View {
        VStack(spacing: NudgeWhipSpacing.s4) {
            Text(localizedAppString("preset.pause.custom_title", defaultValue: "Custom Pause"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.nudgewhipTextPrimary)

            HStack(spacing: NudgeWhipSpacing.s3) {
                TextField(
                    localizedAppString("preset.pause.custom_minutes", defaultValue: "Minutes"),
                    text: $customMinutes
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)

                Stepper(
                    localizedAppString("preset.pause.custom_minutes", defaultValue: "Minutes"),
                    value: Binding(
                        get: { Int(customMinutes) ?? 30 },
                        set: { customMinutes = String($0) }
                    ),
                    in: 1...480,
                    step: 5
                )
                .labelsHidden()
            }

            HStack {
                Button(localizedAppString("preset.editor.cancel", defaultValue: "Cancel")) {
                    showCustomSheet = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(localizedAppString("preset.pause.start", defaultValue: "Pause")) {
                    if let minutes = Int(customMinutes), minutes > 0 {
                        onSelect(minutes)
                    }
                    showCustomSheet = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(Int(customMinutes) == nil)
            }
        }
        .padding(NudgeWhipSpacing.s5)
        .frame(width: 280)
    }
}
