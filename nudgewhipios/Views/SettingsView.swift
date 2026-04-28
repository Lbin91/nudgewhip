import SwiftUI

#if os(iOS)
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                connectionSection
                proSection
                aboutSection
            }
            .navigationTitle(String(localized: "ios.tab.settings"))
        }
    }

    private var connectionSection: some View {
        Section {
            settingsRow(icon: "icloud", title: String(localized: "ios.settings.connection.icloud"), detail: String(localized: "ios.settings.connection.icloud.detail"), status: .warning)
            settingsRow(icon: "desktopcomputer", title: String(localized: "ios.settings.connection.mac"), detail: String(localized: "ios.settings.connection.mac.none"))
            settingsRow(icon: "arrow.triangle.2.circlepath", title: String(localized: "ios.settings.connection.last_sync"), detail: "--")
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
