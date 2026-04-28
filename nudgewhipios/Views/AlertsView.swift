import SwiftUI

#if os(iOS)
struct AlertsView: View {
    @State private var viewModel = AlertsViewModel(macDeviceID: SyncOrchestrator.cachedMacDeviceID ?? "")
    @Environment(SyncOrchestrator.self) var sync

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasAlerts {
                    List {
                        ForEach(viewModel.groupedAlerts, id: \.0) { sectionDate, alerts in
                            Section {
                                ForEach(alerts, id: \.occurredAt) { alert in
                                    AlertRow(alert: alert, viewModel: viewModel)
                                }
                            } header: {
                                Text(sectionDate)
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Spacer()

                        Image(systemName: "bell.slash")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)

                        Text(String(localized: "ios.alerts.empty_title"))
                            .font(.headline)

                        Text(String(localized: "ios.alerts.empty_subtitle"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "ios.tab.alerts"))
            .task { viewModel.reloadData() }
            .onChange(of: sync.lastSyncAt) { viewModel.reloadData() }
            .refreshable { await sync.refresh(); viewModel.reloadData() }
        }
    }
}

private struct AlertRow: View {
    let alert: CachedRemoteEscalation
    let viewModel: AlertsViewModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.escalationIcon(step: alert.escalationStep))
                .font(.title3)
                .foregroundStyle(alert.wasRecoveredWithinWindow == true ? .green : .orange)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.escalationLabel(step: alert.escalationStep))
                    .font(.subheadline.weight(.medium))
                Text(viewModel.formatTime(alert.occurredAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if alert.wasRecoveredWithinWindow != nil {
                Image(systemName: viewModel.recoveryIcon(alert))
                    .foregroundStyle(alert.wasRecoveredWithinWindow == true ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}
#endif

#Preview {
    AlertsView()
}
