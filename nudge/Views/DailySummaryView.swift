import SwiftUI

struct DailySummaryView: View {
    let todayStats: DailyStats
    let whitelistCount: Int
    let petStageText: String
    let petEmotionText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent {
                        Text(formattedDuration(todayStats.totalFocusDuration))
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.focus_time", defaultValue: "Focus time"))
                    }
                    
                    LabeledContent {
                        Text("\(todayStats.completedSessionCount)")
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.completed_sessions", defaultValue: "Completed sessions"))
                    }
                    
                    LabeledContent {
                        Text("\(todayStats.alertCount)")
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.alerts", defaultValue: "Alerts"))
                    }
                }
            } label: {
                Text(localizedAppString("menu.dropdown.group.today", defaultValue: "Today"))
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    LabeledContent {
                        Text("\(whitelistCount)")
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.whitelist_apps", defaultValue: "Whitelist apps"))
                    }
                    
                    LabeledContent {
                        Text(petStageText)
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.pet_stage", defaultValue: "Pet stage"))
                    }
                    
                    LabeledContent {
                        Text(petEmotionText)
                    } label: {
                        Text(localizedAppString("menu.dropdown.label.pet_emotion", defaultValue: "Pet emotion"))
                    }
                }
            } label: {
                Text(localizedAppString("menu.dropdown.group.workspace", defaultValue: "Workspace"))
            }
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: max(duration, 0))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}
