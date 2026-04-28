import Foundation
import SwiftData

@MainActor
protocol SessionTracking: AnyObject {
    var isTracking: Bool { get }
    func beginSession(at date: Date)
    func endSession(reason: FocusSessionEndReason, at date: Date)
    func recordAlertStarted(at date: Date)
    func recordAlertEscalation(step: Int, at date: Date)
    func recordRecovery(at date: Date)
}

@MainActor
final class SessionTracker: SessionTracking {
    private let modelContext: ModelContext
    private var activeSession: FocusSession?
    private var activeAlertingSegment: AlertingSegment?
    var onSessionUpdated: (@MainActor () -> Void)?

    var isTracking: Bool { activeSession != nil }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? NudgeWhipModelContainer.shared.mainContext
    }

    func beginSession(at date: Date) {
        if activeSession != nil {
            endSession(reason: .completed, at: date)
        }
        let session = FocusSession(startedAt: date)
        modelContext.insert(session)
        try? modelContext.save()
        activeSession = session
        onSessionUpdated?()
    }

    func endSession(reason: FocusSessionEndReason, at date: Date) {
        guard let session = activeSession else { return }
        closeOpenAlertingSegment(at: date)
        session.endedAt = date
        session.endReason = reason
        try? modelContext.save()
        activeSession = nil
        onSessionUpdated?()
    }

    func recordAlertStarted(at date: Date) {
        guard let session = activeSession else { return }
        session.alertCount += 1
        session.lastAlertAt = date
        let segment = AlertingSegment(startedAt: date, focusSession: session)
        modelContext.insert(segment)
        try? modelContext.save()
        activeAlertingSegment = segment
        onSessionUpdated?()
    }

    func recordAlertEscalation(step: Int, at date: Date) {
        guard let segment = activeAlertingSegment else { return }
        segment.maxEscalationStep = max(segment.maxEscalationStep, step)
        try? modelContext.save()
    }

    func recordRecovery(at date: Date) {
        guard let session = activeSession else { return }
        session.recoveryCount += 1
        if let segment = activeAlertingSegment {
            segment.recoveredAt = date
            activeAlertingSegment = nil
        }
        try? modelContext.save()
        onSessionUpdated?()
    }

    private func closeOpenAlertingSegment(at date: Date) {
        guard let segment = activeAlertingSegment else { return }
        if segment.recoveredAt == nil {
            segment.recoveredAt = date
        }
        activeAlertingSegment = nil
    }
}
