import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                connectionSection
                proSection
                aboutSection
            }
            .navigationTitle("설정")
        }
    }

    private var connectionSection: some View {
        Section {
            settingsRow(icon: "icloud", title: "iCloud", detail: "연결 필요", status: .warning)
            settingsRow(icon: "desktopcomputer", title: "연결된 Mac", detail: "없음")
            settingsRow(icon: "arrow.triangle.2.circlepath", title: "마지막 동기화", detail: "--")
        } header: {
            Text("연결 상태")
        }
    }

    private var proSection: some View {
        Section {
            HStack {
                Image(systemName: "star")
                    .foregroundStyle(.yellow)
                Text("Pro 기능")
                Spacer()
                Text("비활성")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("구독")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("버전")
                Spacer()
                Text("0.1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("개인정보 처리방침")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("정보")
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

private enum StatusKind {
    case normal, warning
}

#Preview {
    SettingsView()
}
