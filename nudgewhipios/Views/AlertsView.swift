import SwiftUI

#if os(iOS)
struct AlertsView: View {
    var body: some View {
        NavigationStack {
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
            .navigationTitle(String(localized: "ios.tab.alerts"))
        }
    }
}
#endif

#Preview {
    AlertsView()
}
