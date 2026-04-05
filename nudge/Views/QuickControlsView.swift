// QuickControlsView.swift
// 유휴 임계값·TTS·펫 모드 설정 표시 및 액션 버튼.
//
// GroupBox로 설정 값을 보여주고, 권한 새로고침·타이머 리셋 버튼을 제공한다.
// 접근성 권한이 없으면 타이머 리셋 버튼이 비활성화된다.

import SwiftUI

struct QuickControlsView: View {
    let menuBarViewModel: MenuBarViewModel
    let ttsStatusText: String
    let idleThresholdText: String
    let scheduleText: String
    var scheduleEnabled: Binding<Bool>
    var scheduleStartTime: Binding<Date>
    var scheduleEndTime: Binding<Date>
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if menuBarViewModel.shouldShowPermissionCTA {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localizedAppString(
                            "permission.accessibility.disclosure.primary",
                            defaultValue: "Accessibility permission is used only to detect global input activity so NudgeWhip can identify idle periods and show local nudges."
                        ))
                        .font(.footnote)
                        
                        Text(localizedAppString(
                            "permission.accessibility.disclosure.secondary",
                            defaultValue: "NudgeWhip does not collect keystroke content, screen contents, files, messages, or browsing history."
                        ))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        
                        HStack {
                            Button(localizedAppString("permission.accessibility.cta.request", defaultValue: "Request access")) {
                                menuBarViewModel.requestAccessibilityPermission()
                            }
                            
                            Button(localizedAppString("permission.accessibility.cta.open_settings", defaultValue: "Open Settings")) {
                                _ = menuBarViewModel.openAccessibilitySettings()
                            }
                        }
                    }
                    
                    Divider()
                }
                
                LabeledContent {
                    Text(idleThresholdText)
                } label: {
                    Text(localizedAppString("menu.dropdown.label.idle_threshold", defaultValue: "Idle threshold"))
                }
                
                LabeledContent {
                    Text(ttsStatusText)
                } label: {
                    Text(localizedAppString("menu.dropdown.label.tts", defaultValue: "TTS"))
                }
                
                LabeledContent {
                    Text(scheduleText)
                } label: {
                    Text(localizedAppString("menu.dropdown.label.schedule", defaultValue: "Schedule"))
                }
                
                Toggle(
                    localizedAppString("menu.dropdown.schedule.enabled", defaultValue: "Use schedule"),
                    isOn: scheduleEnabled
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(localizedAppString("menu.dropdown.schedule.start", defaultValue: "Start"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: scheduleStartTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .disabled(!scheduleEnabled.wrappedValue)
                    }
                    
                    HStack {
                        Text(localizedAppString("menu.dropdown.schedule.end", defaultValue: "End"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: scheduleEndTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .disabled(!scheduleEnabled.wrappedValue)
                    }
                }
                
                HStack {
                    Button(localizedAppString("menu.quick.action.refresh_permission", defaultValue: "Refresh permission")) {
                        menuBarViewModel.refreshPermission()
                    }
                    
                    Button(localizedAppString("menu.quick.action.reset_timer", defaultValue: "Reset timer")) {
                        menuBarViewModel.resetIdleTimer()
                    }
                    .disabled(menuBarViewModel.runtimeState == .limitedNoAX)
                }
            }
        } label: {
            Text(localizedAppString("menu.dropdown.group.settings", defaultValue: "Settings"))
        }
    }
}
