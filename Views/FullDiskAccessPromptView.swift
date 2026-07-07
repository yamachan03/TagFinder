import SwiftUI

struct FullDiskAccessPromptView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var language: LanguageManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(language.localized("Full Disk Access Required"))
                .font(.title2)
            Text(language.localized("FDA Description"))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
            HStack {
                Button(language.localized("Open System Settings")) {
                    FullDiskAccessChecker.openFullDiskAccessSettings()
                }
                Button(language.localized("Rescan")) {
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
