import SwiftUI

struct QuickControlsView: View {
    let menuBarViewModel: MenuBarViewModel
    let settings: UserSettings?
    let petPresentationText: String
    let ttsStatusText: String
    let idleThresholdText: String
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
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
                    Text(petPresentationText)
                } label: {
                    Text(localizedAppString("menu.dropdown.label.pet_mode", defaultValue: "Pet mode"))
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
