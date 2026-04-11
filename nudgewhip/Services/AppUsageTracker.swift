import Foundation
import SwiftData

@MainActor
final class AppUsageTracker {
    private let modelContext: ModelContext

    private(set) var isFocusWindowActive = false
    private var activeSnapshot: FrontmostAppSnapshot?
    private var activeSegment: AppUsageSegment?

    var onUsageUpdated: (@MainActor () -> Void)?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? NudgeWhipModelContainer.shared.mainContext
    }

    func resumeFocusWindow(at date: Date, currentApp: FrontmostAppSnapshot?) {
        isFocusWindowActive = true
        transition(to: currentApp, at: date)
    }

    func pauseFocusWindow(at date: Date) {
        isFocusWindowActive = false
        closeActiveSegment(at: date)
        activeSnapshot = nil
    }

    func handleFrontmostAppChange(_ snapshot: FrontmostAppSnapshot?, at date: Date) {
        guard isFocusWindowActive else { return }
        transition(to: snapshot, at: date)
    }

    private func transition(to snapshot: FrontmostAppSnapshot?, at date: Date) {
        let normalizedSnapshot = normalized(snapshot)
        guard activeSnapshot != normalizedSnapshot else { return }

        var didChange = closeActiveSegment(at: date)
        activeSnapshot = nil

        guard isFocusWindowActive, let normalizedSnapshot else {
            if didChange {
                notifyUsageUpdated()
            }
            return
        }

        guard let session = currentOpenFocusSession() else {
            if didChange {
                notifyUsageUpdated()
            }
            return
        }

        let segment = AppUsageSegment(
            bundleIdentifier: normalizedSnapshot.bundleIdentifier,
            localizedName: normalizedSnapshot.localizedName,
            processIdentifier: normalizedSnapshot.processIdentifier,
            startedAt: date,
            focusSession: session
        )
        modelContext.insert(segment)
        activeSegment = segment
        activeSnapshot = normalizedSnapshot
        didChange = true
        saveContext()

        if didChange {
            notifyUsageUpdated()
        }
    }

    @discardableResult
    private func closeActiveSegment(at date: Date) -> Bool {
        guard let activeSegment else { return false }
        if activeSegment.endedAt == nil {
            activeSegment.endedAt = max(activeSegment.startedAt, date)
        }
        self.activeSegment = nil
        saveContext()
        return true
    }

    private func currentOpenFocusSession() -> FocusSession? {
        let descriptor = FetchDescriptor<FocusSession>(
            predicate: #Predicate { session in
                session.endedAt == nil
            },
            sortBy: [SortDescriptor(\FocusSession.startedAt, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func normalized(_ snapshot: FrontmostAppSnapshot?) -> FrontmostAppSnapshot? {
        guard let snapshot else { return nil }

        let bundleIdentifier = snapshot.bundleIdentifier?.nilIfBlank
        let localizedName = snapshot.localizedName?.nilIfBlank
        let normalized = FrontmostAppSnapshot(
            bundleIdentifier: bundleIdentifier,
            localizedName: localizedName,
            processIdentifier: snapshot.processIdentifier
        )
        return normalized.hasIdentity ? normalized : nil
    }

    private func saveContext() {
        try? modelContext.save()
    }

    private func notifyUsageUpdated() {
        onUsageUpdated?()
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
