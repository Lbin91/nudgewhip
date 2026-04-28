import SwiftUI

#if os(iOS)
struct StatsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    rangePicker
                    kpiStrip
                    placeholderChart
                    footnote
                }
                .padding()
            }
            .navigationTitle(String(localized: "ios.tab.stats"))
        }
    }

    private var rangePicker: some View {
        Picker(String(localized: "ios.stats.range_picker_label"), selection: .constant(0)) {
            Text(String(localized: "ios.stats.range.today")).tag(0)
            Text(String(localized: "ios.stats.range.7days")).tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var kpiStrip: some View {
        HStack(spacing: 12) {
            KPIMiniCard(label: String(localized: "ios.stats.kpi.total_focus"), value: "--")
            KPIMiniCard(label: String(localized: "ios.stats.kpi.avg_return"), value: "--")
            KPIMiniCard(label: String(localized: "ios.stats.kpi.longest_focus"), value: "--")
        }
    }

    private var placeholderChart: some View {
        VStack(spacing: 8) {
            Text(String(localized: "ios.stats.chart.focus_trend"))
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

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
