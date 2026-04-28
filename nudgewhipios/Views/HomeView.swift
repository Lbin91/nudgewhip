import SwiftUI

#if os(iOS)
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
            .navigationTitle(String(localized: "ios.home.nav_title"))
        }
    }

    private var heroStatusCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text(String(localized: "ios.home.status_unavailable"))
                .font(.headline)

            Text(String(localized: "ios.home.status_hint"))
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
            SummaryCard(title: String(localized: "ios.home.kpi.focus_time"), value: "--", icon: "clock")
            SummaryCard(title: String(localized: "ios.home.kpi.nudge_count"), value: "--", icon: "bell")
            SummaryCard(title: String(localized: "ios.home.kpi.completed_sessions"), value: "--", icon: "checkmark.circle")
            SummaryCard(title: String(localized: "ios.home.kpi.longest_focus"), value: "--", icon: "flame")
        }
    }

    private var syncHealthCard: some View {
        HStack {
            Image(systemName: "icloud.slash")
                .foregroundStyle(.secondary)
            Text(String(localized: "ios.home.sync_disconnected"))
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
#endif

#Preview {
    HomeView()
}
