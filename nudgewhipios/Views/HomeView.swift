import SwiftData
import SwiftUI

#if os(iOS)
struct HomeView: View {
    @State private var viewModel = HomeViewModel(macDeviceID: SyncOrchestrator.cachedMacDeviceID ?? "")
    @Environment(SyncOrchestrator.self) var sync

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
            .refreshable {
                await sync.refresh()
                viewModel.reloadData()
            }
            .navigationTitle(String(localized: "ios.home.nav_title"))
            .task {
                viewModel.reloadData()
            }
            .onChange(of: sync.lastSyncAt) {
                viewModel.reloadData()
            }
        }
    }

    private var heroStatusCard: some View {
        VStack(spacing: 8) {
            if viewModel.macState != nil {
                Image(systemName: viewModel.macStateIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text(viewModel.macStateText)
                    .font(.headline)

                Text(viewModel.macState!.stateChangedAt, style: .relative)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var todaySummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryCard(title: String(localized: "ios.home.kpi.focus_time"), value: viewModel.focusTimeText, icon: "clock")
            SummaryCard(title: String(localized: "ios.home.kpi.nudge_count"), value: viewModel.nudgeCountText, icon: "bell")
            SummaryCard(title: String(localized: "ios.home.kpi.completed_sessions"), value: viewModel.completedSessionsText, icon: "checkmark.circle")
            SummaryCard(title: String(localized: "ios.home.kpi.longest_focus"), value: viewModel.longestFocusText, icon: "flame")
        }
    }

    private var syncHealthCard: some View {
        HStack {
            if sync.isSyncing {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundStyle(.secondary)
                Text(String(localized: "ios.sync.status.syncing"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if sync.lastSyncAt != nil {
                Image(systemName: "icloud.circle")
                    .foregroundStyle(.secondary)
                Text(String(localized: "ios.sync.status.connected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.secondary)
                Text(String(localized: "ios.home.sync_disconnected"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
        .modelContainer(iOSModelContainer.preview)
        .environment(SyncOrchestrator())
}
