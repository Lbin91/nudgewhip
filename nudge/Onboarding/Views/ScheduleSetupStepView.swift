import SwiftUI

struct ScheduleSetupStepView: View {
    @Binding var scheduleEnabled: Bool
    @Binding var scheduleStartTime: Date
    @Binding var scheduleEndTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingSectionCard(
                title: localizedAppString("onboarding.schedule.title", defaultValue: "모니터링 시간 정하기"),
                subtitle: localizedAppString("onboarding.schedule.body", defaultValue: "업무 시간에만 넛지를 받고 싶다면 시작/종료 시간을 정해둘 수 있어요.")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(
                        localizedAppString("onboarding.schedule.enabled", defaultValue: "시간대 사용"),
                        isOn: $scheduleEnabled
                    )
                    .toggleStyle(.checkbox)
                    
                    HStack {
                        Text(localizedAppString("onboarding.schedule.start", defaultValue: "시작"))
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
                        Text(localizedAppString("onboarding.schedule.end", defaultValue: "종료"))
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
                title: localizedAppString("onboarding.schedule.helper.title", defaultValue: "이렇게 동작해요")
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    helperRow(localizedAppString("onboarding.schedule.helper.outside", defaultValue: "설정한 시간대 밖에서는 monitoring과 alert가 자동으로 멈춥니다."))
                    helperRow(localizedAppString("onboarding.schedule.helper.inside", defaultValue: "시간대 안으로 다시 들어오면 현재 시각 기준으로 안전하게 다시 시작합니다."))
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
