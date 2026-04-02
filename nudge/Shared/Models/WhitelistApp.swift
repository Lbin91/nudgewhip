import Foundation
import SwiftData

@Model
final class WhitelistApp {
    var bundleIdentifier: String
    var displayName: String?
    var isEnabled: Bool
    var createdAt: Date
    
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
