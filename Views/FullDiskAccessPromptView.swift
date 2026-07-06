import SwiftUI

struct FullDiskAccessPromptView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("フルディスクアクセスが必要です")
                .font(.title2)
            Text("TagFinderがすべてのボリューム（外付けドライブ含む）のFinderタグを検索するには、システム設定でフルディスクアクセスを許可してください。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
            HStack {
                Button("システム設定を開く") {
                    FullDiskAccessChecker.openFullDiskAccessSettings()
                }
                Button("再スキャン") {
                    appState.refreshTags()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(minWidth: 420, minHeight: 300)
    }
}
