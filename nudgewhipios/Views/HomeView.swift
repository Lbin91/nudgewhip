import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    heroStatusCard
                    todaySummaryGrid
                    syncHealthCard
                }
                .padding()
            }
            .navigationTitle("NudgeWhip")
        }
    }

    private var heroStatusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Mac 상태를 확인할 수 없습니다")
                .font(.headline)

            Text("Mac에서 NudgeWhip을 실행하면 여기에 상태가 표시됩니다")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var todaySummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(title: "집중 시간", value: "--", icon: "clock")
            SummaryCard(title: "알림 횟수", value: "--", icon: "bell")
            SummaryCard(title: "완료 세션", value: "--", icon: "checkmark.circle")
            SummaryCard(title: "최장 집중", value: "--", icon: "flame")
        }
    }

    private var syncHealthCard: some View {
        HStack {
            Image(systemName: "icloud.slash")
                .foregroundStyle(.secondary)
            Text("Mac과 연결되지 않음")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
}
