import SwiftUI

#if os(iOS)
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(SyncOrchestrator.self) var sync

    var body: some View {
        NavigationStack {
            List {
                connectionSection
                proSection
                aboutSection
            }
            .navigationTitle(String(localized: "ios.tab.settings"))
            .refreshable {
                await sync.refresh()
                viewModel.reloadData(lastSyncAt: sync.lastSyncAt)
            }
        }
        .task {
            viewModel.reloadData(lastSyncAt: sync.lastSyncAt)
        }
        .onChange(of: sync.lastSyncAt) {
            viewModel.reloadData(lastSyncAt: sync.lastSyncAt)
        }
    }

    private var connectionSection: some View {
        Section {
            settingsRow(icon: "icloud",
                        title: String(localized: "ios.settings.connection.icloud"),
                        detail: viewModel.iCloudDetailText,
                        status: viewModel.iCloudStatus)
            settingsRow(icon: "desktopcomputer",
                        title: String(localized: "ios.settings.connection.mac"),
                        detail: viewModel.connectedMacText)
            settingsRow(icon: "arrow.triangle.2.circlepath",
                        title: String(localized: "ios.settings.connection.last_sync"),
                        detail: viewModel.lastSyncText)
        } header: {
            Text(String(localized: "ios.settings.section.connection"))
        }
    }

    private var proSection: some View {
        Section {
            HStack {
                Image(systemName: "star")
                    .foregroundStyle(.yellow)
                Text(String(localized: "ios.settings.pro.features"))
                Spacer()
                Text(String(localized: "ios.settings.pro.inactive"))
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "ios.settings.section.subscription"))
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text(String(localized: "ios.settings.about.version"))
                Spacer()
                Text("0.1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text(String(localized: "ios.settings.about.privacy_policy"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String(localized: "ios.settings.section.about"))
        }
    }

    private func settingsRow(icon: String, title: String, detail: String, status: StatusKind = .normal) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(status == .warning ? .orange : .secondary)
            Text(title)
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}
#endif

#Preview {
    SettingsView()
}
