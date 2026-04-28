import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
@MainActor
@Observable
final class StatsViewModel {
    struct HourlyData: Identifiable {
        let id = UUID()
        let hour: Int
        let count: Int
    }

    private let modelContext: ModelContext
    let macDeviceID: String

    var selectedRange: Int = 0
    private(set) var projections: [CachedDayProjection] = []

    init(modelContext: ModelContext, macDeviceID: String) {
        self.modelContext = modelContext
        self.macDeviceID = macDeviceID
    }

    convenience init(macDeviceID: String) {
        self.init(modelContext: iOSModelContainer.shared.mainContext, macDeviceID: macDeviceID)
    }

    var totalFocusText: String {
        let total = projections.reduce(Int64(0)) { $0 + $1.totalFocusDurationSeconds }
        return formatDuration(seconds: total)
    }

    var avgReturnText: String {
        let totalSamples = projections.reduce(Int64(0)) { $0 + $1.recoverySampleCount }
        guard totalSamples > 0 else { return "--" }
        let totalDuration = projections.reduce(Int64(0)) { $0 + $1.recoveryDurationTotalSeconds }
        let avg = totalDuration / totalSamples
        return formatSeconds(seconds: avg)
    }

    var longestFocusText: String {
        guard !projections.isEmpty else { return "--" }
        let maxVal = projections.map(\.longestFocusDurationSeconds).max() ?? 0
        return formatDuration(seconds: maxVal)
    }

    var chartData: [HourlyData] {
        guard !projections.isEmpty else { return [] }
        if selectedRange == 0 {
            guard let today = projections.first else { return [] }
            return today.hourlyAlertCounts.enumerated().map { HourlyData(hour: $0.offset, count: $0.element) }
        }
        var aggregated = Array(repeating: 0, count: 24)
        for proj in projections {
            let counts = proj.hourlyAlertCounts
            for i in 0..<min(counts.count, 24) {
                aggregated[i] += counts[i]
            }
        }
        return aggregated.enumerated().map { HourlyData(hour: $0.offset, count: $0.element) }
    }

    var hasData: Bool {
        !projections.isEmpty
    }

    func reloadData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let datePart = formatter.string(from: Date.now)
        let localDayKey = "\(datePart)@\(TimeZone.current.identifier)"

        if selectedRange == 0 {
            let descriptor = FetchDescriptor<CachedDayProjection>(
                predicate: #Predicate {
                    $0.macDeviceID == macDeviceID && $0.localDayKey == localDayKey
                }
            )
            projections = (try? modelContext.fetch(descriptor)) ?? []
        } else {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now
            let descriptor = FetchDescriptor<CachedDayProjection>(
                predicate: #Predicate {
                    $0.macDeviceID == macDeviceID && $0.dayStart >= sevenDaysAgo
                },
                sortBy: [SortDescriptor(\.dayStart, order: .forward)]
            )
            projections = (try? modelContext.fetch(descriptor)) ?? []
        }
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        return f
    }()

    private static let secondsFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.minute, .second]
        f.unitsStyle = .abbreviated
        return f
    }()

    private func formatDuration(seconds: Int64) -> String {
        guard seconds > 0 else { return "--" }
        return Self.durationFormatter.string(from: TimeInterval(seconds)) ?? "--"
    }

    private func formatSeconds(seconds: Int64) -> String {
        guard seconds > 0 else { return "--" }
        return Self.secondsFormatter.string(from: TimeInterval(seconds)) ?? "--"
    }
}
#endif
