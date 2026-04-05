import SwiftUI

struct ScheduleSetupStepView: View {
    @Binding var scheduleEnabled: Bool
    @Binding var scheduleStartTime: Date
    @Binding var scheduleEndTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingSectionCard(
                title: localizedAppString("onboarding.schedule.title", defaultValue: "Choose your monitoring hours"),
                subtitle: localizedAppString("onboarding.schedule.body", defaultValue: "If you want nudges only during work hours, choose your start and end times.")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(
                        localizedAppString("onboarding.schedule.enabled", defaultValue: "Use schedule"),
                        isOn: $scheduleEnabled
                    )
                    .toggleStyle(.checkbox)
                    
                    HStack {
                        Text(localizedAppString("onboarding.schedule.start", defaultValue: "Start"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $scheduleStartTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .disabled(!scheduleEnabled)
                    }
                    
                    HStack {
                        Text(localizedAppString("onboarding.schedule.end", defaultValue: "End"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $scheduleEndTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .disabled(!scheduleEnabled)
                    }
                }
            }
            
            OnboardingSectionCard(
                title: localizedAppString("onboarding.schedule.helper.title", defaultValue: "How this works")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    helperRow(localizedAppString("onboarding.schedule.helper.outside", defaultValue: "Outside the selected hours, monitoring and nudges automatically pause."))
                    helperRow(localizedAppString("onboarding.schedule.helper.inside", defaultValue: "When you re-enter the schedule window, Nudge safely resumes from the current time."))
                }
            }
        }
    }
    
    private func helperRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            Text(text)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
