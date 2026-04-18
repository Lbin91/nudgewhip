import SwiftUI

struct AlertsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "bell.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("원격 알림이 없습니다")
                    .font(.headline)

                Text("Mac에서 장기 미복귀 시 iOS로 알림이 표시됩니다")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("알림")
        }
    }
}

#Preview {
    AlertsView()
}
