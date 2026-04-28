import Charts
import SwiftUI

#if os(iOS)
struct StatsView: View {
    @State private var viewModel = StatsViewModel()
    @Environment(SyncOrchestrator.self) var sync

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    rangePicker
                    kpiStrip
                    chartSection
                    footnote
                }
                .padding()
            }
            .navigationTitle(String(localized: "ios.tab.stats"))
            .task { viewModel.reloadData() }
            .onChange(of: sync.lastSyncAt) { viewModel.reloadData() }
            .refreshable { await sync.refresh(); viewModel.reloadData() }
        }
    }

    private var rangePicker: some View {
        Picker(String(localized: "ios.stats.range_picker_label"), selection: $viewModel.selectedRange) {
            Text(String(localized: "ios.stats.range.today")).tag(0)
            Text(String(localized: "ios.stats.range.7days")).tag(1)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedRange) { viewModel.reloadData() }
    }

    private var kpiStrip: some View {
        HStack(spacing: 12) {
            KPIMiniCard(label: String(localized: "ios.stats.kpi.total_focus"), value: viewModel.totalFocusText)
            KPIMiniCard(label: String(localized: "ios.stats.kpi.avg_return"), value: viewModel.avgReturnText)
            KPIMiniCard(label: String(localized: "ios.stats.kpi.longest_focus"), value: viewModel.longestFocusText)
        }
    }

    private var chartSection: some View {
        VStack(spacing: 8) {
            Text(String(localized: "ios.stats.chart.focus_trend"))
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.hasData {
                Chart(viewModel.chartData) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Alerts", item.count)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) {
                        AxisValueLabel()
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .frame(height: 160)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "chart.bar")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text(String(localized: "ios.stats.chart.placeholder"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    private var footnote: some View {
        Text(String(localized: "ios.stats.footnote"))
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct KPIMiniCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
#endif

#Preview {
    StatsView()
}
