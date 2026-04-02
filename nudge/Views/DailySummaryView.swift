// DailySummaryView.swift
// 오늘의 포커스 통계와 워크스페이스 정보를 표시하는 뷰.
//
// Today 그룹: 총 포커스 시간, 완료 세션 수, 알림 횟수.
// Workspace 그룹: 화이트리스트 앱 수, 펫 단계, 펫 감정.

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
    
    /// TimeInterval을 "1h 23m" 형식의 읽기 쉬운 문자열로 포맷
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = [.pad]
        return formatter.string(from: max(duration, 0))
            ?? localizedAppString("menu.dropdown.value.unavailable", defaultValue: "Unavailable")
    }
}
