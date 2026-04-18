import SwiftUI

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
            .navigationTitle("통계")
        }
    }

    private var rangePicker: some View {
        Picker("기간", selection: .constant(0)) {
            Text("오늘").tag(0)
            Text("최근 7일").tag(1)
        }
        .pickerStyle(.segmented)
    }

    private var kpiStrip: some View {
        HStack(spacing: 12) {
            KPIMiniCard(label: "총 집중", value: "--")
            KPIMiniCard(label: "평균 복귀", value: "--")
            KPIMiniCard(label: "최장 집중", value: "--")
        }
    }

    private var placeholderChart: some View {
        VStack(spacing: 8) {
            Text("집중 시간 추이")
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
                        Text("Mac 연결 후 데이터가 표시됩니다")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }

    private var footnote: some View {
        Text("이 데이터는 Mac에서 계산된 요약치입니다.")
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

#Preview {
    StatsView()
}
