// WhitelistApp.swift
// 모니터링 예외 앱을 저장하는 SwiftData 모델.
//
// 사용자가 지정한 앱(bundleIdentifier)이 활성화되면
// 유휴 감시를 일시 정지하는 허용 목록 역할을 한다.

import Foundation
import SwiftData

@Model
final class WhitelistApp {
    var bundleIdentifier: String
    var displayName: String?
    var isEnabled: Bool
    var createdAt: Date
    
    /// 화이트리스트 앱 생성. 기본적으로 활성화 상태
    init(
        bundleIdentifier: String,
        displayName: String? = nil,
        isEnabled: Bool = true,
        createdAt: Date = .now
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.displayName = displayName
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}
