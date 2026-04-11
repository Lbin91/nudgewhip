import Foundation
import SwiftData

@Model
final class AppUsageSegment {
    var bundleIdentifier: String?
    var localizedName: String?
    var processIdentifier: Int32?
    var startedAt: Date
    var endedAt: Date?
    var createdAt: Date
    var focusSession: FocusSession?

    init(
        bundleIdentifier: String?,
        localizedName: String?,
        processIdentifier: Int32?,
        startedAt: Date,
        endedAt: Date? = nil,
        createdAt: Date = .now,
        focusSession: FocusSession? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.processIdentifier = processIdentifier
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.createdAt = createdAt
        self.focusSession = focusSession
    }
}
